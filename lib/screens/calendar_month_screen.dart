import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../models/zone.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/calendar_day_detail.dart';
import '../widgets/segmented_control.dart';
import '../widgets/zone_pill.dart';
import 'calendar_demo_data.dart';

const _monthNamesFull = [
  'Janeiro',
  'Fevereiro',
  'Marco',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];
const _dowSingleLetters = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

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
                Text(
                    '${_monthNamesFull[_focusedDay.month - 1]} ${_focusedDay.year}',
                    style: AppTextStyles.screenSubtitle),
                const SizedBox(height: 14),
                SegmentedControl(
                  options: const ['Semana', 'Mes'],
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
                      demoCalendarEntries.containsKey(normalizeDay(day))
                          ? const [true]
                          : const [],
                  calendarBuilders: CalendarBuilders(
                    dowBuilder: (context, day) => Center(
                      child: Text(_dowSingleLetters[day.weekday - 1],
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
                Wrap(
                  spacing: 6,
                  children: Zone.values.map((z) => ZonePill(zone: z)).toList(),
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
