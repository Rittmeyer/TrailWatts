import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../l10n/domain_labels.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../services/rider_profile_store.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/calendar_day_detail.dart';
import '../widgets/segmented_control.dart';
import 'calendar_demo_data.dart';

/// Port of screen 08c - "Calendario, mes". Same day-detail panel as the
/// week view (08a/08b) appears below the grid on tap - plan or result,
/// same taxonomy either way.
class CalendarMonthScreen extends StatefulWidget {
  const CalendarMonthScreen({super.key});

  @override
  State<CalendarMonthScreen> createState() => _CalendarMonthScreenState();
}

class _CalendarMonthScreenState extends State<CalendarMonthScreen> {
  DateTime _focusedDay = DateTime(2026, 7, 20);
  DateTime _selectedDay = DateTime(2026, 7, 20);

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    final locale = Localizations.localeOf(context).toString();
    return Scaffold(
      body: SafeArea(
        // Rebuilds when the rider saves a profile, so the day panel names
        // the zone on the table they actually chose.
        child: ListenableBuilder(
          listenable: RiderProfileStore.instance,
          builder: (context, _) {
            final store = RiderProfileStore.instance;
            final entries = demoCalendarEntriesFor(store.profile);
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
                    Text(DateFormat.yMMMM(locale).format(_focusedDay),
                        style: AppTextStyles.screenSubtitle),
                    const SizedBox(height: 14),
                    SegmentedControl(
                      options: [t.calendarWeek, t.calendarMonth],
                      selectedIndex: 1,
                      onChanged: (i) {
                        if (i == 0) {
                          Navigator.of(context)
                              .pushReplacementNamed('/calendar/week');
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TableCalendar<bool>(
                      firstDay: DateTime(2020),
                      lastDay: DateTime(2030),
                      focusedDay: _focusedDay,
                      currentDay: DateTime(2026, 7, 20),
                      calendarFormat: CalendarFormat.month,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      locale: locale,
                      headerVisible: false,
                      daysOfWeekHeight: 20,
                      rowHeight: 42,
                      selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                      onDaySelected: (selected, focused) => setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                      }),
                      onPageChanged: (focused) =>
                          setState(() => _focusedDay = focused),
                      eventLoader: (day) =>
                          entries.containsKey(normalizeDay(day))
                              ? const [true]
                              : const [],
                      calendarBuilders: CalendarBuilders(
                        dowBuilder: (context, day) => Center(
                          child: Text(
                              DateFormat.E(locale).format(day)[0].toUpperCase(),
                              style: AppTextStyles.label.copyWith(fontSize: 9)),
                        ),
                      ),
                      calendarStyle: const CalendarStyle(
                        outsideDaysVisible: true,
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
                    // No zone legend here on purpose: the calendar is a
                    // month of days, not one effort. The zone belongs to the
                    // individual workout, and the day panel below names it.
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
