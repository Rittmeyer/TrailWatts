import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/rider_profile.dart';
import '../l10n/domain_labels.dart';
import '../models/zone.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// One zone table, shown in absolute values and editable in place.
///
/// The rider edits each zone's lower bound; the upper bound is always the
/// next zone's lower bound minus one, so the table cannot develop a gap or
/// an overlap. Z1 starts at zero and is not editable. The top zone is
/// open-ended.
///
/// While [bounds] is null the table is the generic percentage table derived
/// from the anchor, and is labeled as an estimate. Switching to manual
/// editing seeds the fields from those generic values so the rider starts
/// from something sensible (Constitution Article II - manual entry wins).
class ZoneTableEditor extends StatefulWidget {
  final ZoneTable table;

  /// Rider-entered lower bounds, or null when the generic table is in use.
  final List<int>? bounds;

  /// The generic table made concrete, used for display and as the seed for
  /// manual editing. Null when the anchor needed is unknown.
  final List<int>? derivedBounds;

  final String unit;

  /// Shown under the table when the generic values still need review.
  final bool provisional;

  /// Emits the new bounds, or null when the rider reverts to generic.
  final ValueChanged<List<int>?> onChanged;

  /// Reports whether what is currently typed is a usable table.
  final ValueChanged<bool>? onValidityChanged;

  const ZoneTableEditor({
    super.key,
    required this.table,
    required this.bounds,
    required this.derivedBounds,
    required this.unit,
    required this.onChanged,
    this.onValidityChanged,
    this.provisional = false,
  });

  @override
  State<ZoneTableEditor> createState() => _ZoneTableEditorState();
}

class _ZoneTableEditorState extends State<ZoneTableEditor> {
  List<TextEditingController> _controllers = const [];

  bool get _isCustom => widget.bounds != null;

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  /// Set when the anchor (FTP / LTHR / HR max) moved after the rider had
  /// already edited this table by hand. Their numbers are kept - they typed
  /// them on purpose - but the table no longer follows the new anchor, and
  /// saying so beats silently leaving it stale.
  bool _anchorMovedSinceEdit = false;

  @override
  void didUpdateWidget(ZoneTableEditor old) {
    super.didUpdateWidget(old);

    final scaleChanged = old.table.scale != widget.table.scale;
    final modeChanged = (old.bounds == null) != (widget.bounds == null);
    final derivedChanged =
        !_sameValues(old.derivedBounds, widget.derivedBounds);

    if (scaleChanged || modeChanged) {
      if (modeChanged) _anchorMovedSinceEdit = false;
      _syncControllers();
      return;
    }

    if (widget.bounds == null) {
      // Generic table: it is derived from the anchor, so it must track it.
      if (derivedChanged) _syncControllers();
      return;
    }

    // Custom table. Re-sync only when the new bounds came from outside this
    // widget (a "recalculate" tap); the echo of the rider's own typing would
    // otherwise rebuild the field and drop the caret mid-edit.
    if (!_sameValues(widget.bounds, _read())) {
      _syncControllers();
      _anchorMovedSinceEdit = false;
    } else if (derivedChanged) {
      _anchorMovedSinceEdit = true;
    }
  }

  static bool _sameValues(List<int>? a, List<int>? b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _syncControllers() {
    for (final c in _controllers) {
      c.dispose();
    }
    final values = widget.bounds ?? widget.derivedBounds ?? const [];
    _controllers = [
      for (final v in values) TextEditingController(text: '$v'),
    ];
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<int>? _read() {
    final parsed = <int>[];
    for (final c in _controllers) {
      final v = int.tryParse(c.text.trim());
      if (v == null) return null;
      parsed.add(v);
    }
    return parsed;
  }

  void _commit() {
    final parsed = _read();
    final valid =
        parsed != null && isValidZoneBounds(parsed, widget.table.scale);
    widget.onValidityChanged?.call(valid);
    if (parsed != null) widget.onChanged(parsed);
    setState(() {}); // refresh the derived upper bounds
  }

  /// Upper bound shown for a row, using the same rule as the stored model
  /// (upperBoundFrom) but applied to what is currently typed, so the label
  /// tracks the field while it is being edited.
  String _upperLabel(int rowIndex) {
    final parsed = _read();
    if (parsed == null) return '?';
    final upper = upperBoundFrom(parsed, rowIndex + 1);
    return upper == null ? '' : '$upper';
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final zones = widget.table.zones;
    final parsed = _read();
    final valid =
        parsed != null && isValidZoneBounds(parsed, widget.table.scale);

    if (_controllers.length != zones.length) {
      return Text(t.zoneTableNeedsAnchor,
          style: AppTextStyles.label.copyWith(fontSize: 9));
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(8),
        // The table used to be paper on paper, which drew no edge at all: a
        // list of loose numbers rather than a table.
        border: Border.all(
            color: valid ? AppColors.line : AppColors.warnText, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: _isCustom ? AppColors.greenBg : AppColors.warnBg,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  _isCustom ? t.zoneTableCustom : t.zoneTableGeneric,
                  style: AppTextStyles.label.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: _isCustom ? AppColors.greenText : AppColors.warnText,
                  ),
                ),
              ),
              const Spacer(),
              if (_isCustom)
                _TinyButton(
                  label: t.zoneTableRestoreDefault,
                  onTap: () {
                    widget.onValidityChanged?.call(true);
                    widget.onChanged(null);
                  },
                )
              else if (widget.derivedBounds != null)
                _TinyButton(
                  label: t.zoneTableEditBounds,
                  onTap: () =>
                      widget.onChanged(List<int>.from(widget.derivedBounds!)),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Column headings. Without them the two numbers on each row were
          // unexplained, and the unit was repeated on every line instead of
          // being said once.
          Row(
            children: [
              const SizedBox(width: _dotColumn + _codeColumn),
              Expanded(child: _ColumnHead(t.zoneTableColumnZone)),
              SizedBox(
                width: _valueColumn,
                child: _ColumnHead('${t.zoneTableColumnFrom} (${widget.unit})',
                    alignRight: true),
              ),
              const SizedBox(width: _gap),
              SizedBox(
                width: _valueColumn,
                child: _ColumnHead('${t.zoneTableColumnTo} (${widget.unit})',
                    alignRight: true),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1, thickness: 1, color: AppColors.line),
          ),

          for (var i = 0; i < zones.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    margin: const EdgeInsets.only(right: _dotColumn - 9),
                    decoration: BoxDecoration(
                        color: zones[i].color, shape: BoxShape.circle),
                  ),
                  SizedBox(
                    width: _codeColumn,
                    child: Text(zones[i].code,
                        style: AppTextStyles.numeric.copyWith(fontSize: 11)),
                  ),
                  Expanded(
                    child: Text(zones[i].label(t),
                        style: AppTextStyles.label
                            .copyWith(fontSize: 11.5, color: AppColors.ink)),
                  ),
                  SizedBox(
                    width: _valueColumn,
                    // Z1 always starts at zero, so its lower bound is not a
                    // choice anyone gets to make.
                    child: _isCustom && i > 0
                        ? TextField(
                            controller: _controllers[i],
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            textAlign: TextAlign.right,
                            style: AppTextStyles.numeric.copyWith(fontSize: 11),
                            decoration: const InputDecoration(
                              isDense: true,
                              fillColor: AppColors.white,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 6),
                            ),
                            onChanged: (_) => _commit(),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(right: 7),
                            child: Text(_controllers[i].text,
                                textAlign: TextAlign.right,
                                style: AppTextStyles.numeric
                                    .copyWith(fontSize: 11)),
                          ),
                  ),
                  const SizedBox(width: _gap),
                  SizedBox(
                    width: _valueColumn,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: Text(
                        // The top zone has no ceiling; "+" says that in the
                        // same column instead of breaking the alignment.
                        i == zones.length - 1 ? '+' : _upperLabel(i),
                        textAlign: TextAlign.right,
                        style: AppTextStyles.numeric.copyWith(fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_anchorMovedSinceEdit && widget.derivedBounds != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.zoneTableAnchorMoved,
                    style: AppTextStyles.label
                        .copyWith(fontSize: 10, color: AppColors.warnText),
                  ),
                ),
                const SizedBox(width: 8),
                _TinyButton(
                  label: t.zoneTableRecalculate,
                  onTap: () {
                    widget.onValidityChanged?.call(true);
                    widget.onChanged(List<int>.from(widget.derivedBounds!));
                  },
                ),
              ],
            ),
          ],
          if (!valid) ...[
            const SizedBox(height: 8),
            Text(
              t.zoneTableInvalid,
              style: AppTextStyles.label
                  .copyWith(fontSize: 10, color: AppColors.warnText),
            ),
          ],
          if (!_isCustom && widget.provisional) ...[
            const SizedBox(height: 8),
            Text(
              t.zoneTableProvisional,
              style: AppTextStyles.label.copyWith(fontSize: 10, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

/// One numeric column width, shared by the heading and every row, so the
/// figures line up in a column instead of drifting with their own text.
const _dotColumn = 17.0;
const _codeColumn = 24.0;
const _valueColumn = 62.0;
const _gap = 8.0;

class _ColumnHead extends StatelessWidget {
  final String text;
  final bool alignRight;

  const _ColumnHead(this.text, {this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: alignRight ? TextAlign.right : TextAlign.left,
      style: AppTextStyles.label.copyWith(
        fontSize: 8.5,
        letterSpacing: 0.7,
        fontWeight: FontWeight.w700,
        color: AppColors.inkSoft,
      ),
    );
  }
}

class _TinyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TinyButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(label,
          style: AppTextStyles.label.copyWith(
              fontSize: 9,
              color: AppColors.primary,
              fontWeight: FontWeight.w700)),
    );
  }
}
