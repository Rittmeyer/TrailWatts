import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../l10n/domain_labels.dart';
import '../services/rider_profile_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/calendar_day_detail.dart';
import '../widgets/segmented_control.dart';
import 'calendar_demo_data.dart';

/// Port of screens 08a/08b - "Calendario, semana". The current day comes
/// pre-selected; the panel below the strip shows the plan if the day
/// hasn't been ridden yet, or the completed summary if it has.
class CalendarWeekScreen extends StatefulWidget {
  const CalendarWeekScreen({super.key});

  @override
  State<CalendarWeekScreen> createState() => _CalendarWeekScreenState();
}

class _CalendarWeekScreenState extends State<CalendarWeekScreen> {
  DateTime _focusedDay = DateTime(2026, 7, 20);
  DateTime _selectedDay = DateTime(2026, 7, 20);

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final locale = Localizations.localeOf(context).toString();
    final monday =
        _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    // "20 - 26 de julho" / "20 – July 26", per the locale's own conventions.
    final rangeLabel = monday.month == sunday.month
        ? '${DateFormat.d(locale).format(monday)} - '
            '${DateFormat.MMMMd(locale).format(sunday)}'
        : '${DateFormat.MMMMd(locale).format(monday)} - '
            '${DateFormat.MMMMd(locale).format(sunday)}';

    return Scaffold(
      body: SafeArea(
        // Rebuilds when the rider saves a profile, so the zones on this
        // screen follow the table they actually chose.
        child: ListenableBuilder(
          listenable: RiderProfileStore.instance,
          builder: (context, _) {
            final entries =
                demoCalendarEntriesFor(RiderProfileStore.instance.profile);
            return Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.calendarTitle,
                        style:
                            AppTextStyles.screenTitle.copyWith(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(rangeLabel, style: AppTextStyles.screenSubtitle),
                    const SizedBox(height: 14),
                    SegmentedControl(
                      options: [t.calendarWeek, t.calendarMonth],
                      selectedIndex: 0,
                      onChanged: (i) {
                        if (i == 1) {
                          Navigator.of(context)
                              .pushReplacementNamed('/calendar/month');
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TableCalendar<bool>(
                      firstDay: DateTime(2020),
                      lastDay: DateTime(2030),
                      focusedDay: _focusedDay,
                      currentDay: DateTime(2026, 7, 20),
                      calendarFormat: CalendarFormat.week,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      locale: locale,
                      headerVisible: false,
                      daysOfWeekHeight: 22,
                      rowHeight: 58,
                      selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                      onDaySelected: (selected, focused) => setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                      }),
                      eventLoader: (day) =>
                          entries.containsKey(normalizeDay(day))
                              ? const [true]
                              : const [],
                      calendarBuilders: CalendarBuilders(
                        dowBuilder: (context, day) => Center(
                          child: Text(
                              DateFormat.E(locale).format(day).toUpperCase(),
                              style: AppTextStyles.label.copyWith(fontSize: 9)),
                        ),
                      ),
                      calendarStyle: const CalendarStyle(
                        outsideDaysVisible: false,
                        todayDecoration: BoxDecoration(
                            color: AppColors.paper, shape: BoxShape.circle),
                        todayTextStyle: TextStyle(
                            color: AppColors.ink, fontWeight: FontWeight.w700),
                        selectedDecoration: BoxDecoration(
                            color: AppColors.accent, shape: BoxShape.circle),
                        markerDecoration: BoxDecoration(
                            color: AppColors.primary, shape: BoxShape.circle),
                        markersAlignment: Alignment.bottomCenter,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CalendarDayDetail(
                        entry: entries[normalizeDay(_selectedDay)]),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const TrailwattBottomNav(currentIndex: 1),
    );
  }
}
