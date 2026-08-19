import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/calendar_day_detail.dart';
import '../widgets/segmented_control.dart';
import 'calendar_demo_data.dart';

const _weekdayLabels = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB', 'DOM'];
const _monthNames = [
  'Janeiro', 'Fevereiro', 'Marco', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

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
    final monday = _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final rangeLabel = monday.month == sunday.month
        ? '${monday.day} - ${sunday.day} de ${_monthNames[monday.month - 1].toLowerCase()}'
        : '${monday.day} de ${_monthNames[monday.month - 1].toLowerCase()} - '
            '${sunday.day} de ${_monthNames[sunday.month - 1].toLowerCase()}';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Calendario',
                  style: AppTextStyles.screenTitle.copyWith(fontSize: 24)),
              const SizedBox(height: 4),
              Text(rangeLabel, style: AppTextStyles.screenSubtitle),
              const SizedBox(height: 14),
              SegmentedControl(
                options: const ['Semana', 'Mes'],
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
                headerVisible: false,
                daysOfWeekHeight: 22,
                rowHeight: 58,
                selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                onDaySelected: (selected, focused) => setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                }),
                eventLoader: (day) =>
                    demoCalendarEntries.containsKey(normalizeDay(day))
                        ? const [true]
                        : const [],
                calendarBuilders: CalendarBuilders(
                  dowBuilder: (context, day) => Center(
                    child: Text(_weekdayLabels[day.weekday - 1],
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
                  entry: demoCalendarEntries[normalizeDay(_selectedDay)]),
            ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const TrailwattBottomNav(currentIndex: 1),
    );
  }
}
