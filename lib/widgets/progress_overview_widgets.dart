import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:rize/helpers/date_helpers.dart';
import 'package:rize/helpers/progress_formatters.dart';
import 'package:rize/helpers/progress_statistics.dart';
import 'package:rize/helpers/rize_style_helpers.dart';

class ProgressHero extends StatelessWidget {
  const ProgressHero({
    super.key,
    required this.currentStreak,
    required this.bestStreak,
    required this.level,
    required this.levelProgress,
    required this.activeDaysThisMonth,
  });

  final int currentStreak;
  final int bestStreak;
  final String level;
  final double levelProgress;
  final int activeDaysThisMonth;

  @override
  Widget build(BuildContext context) {
    final double progress = levelProgress.clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      decoration: rizeCardDecoration(accentColor: rizeCyan, radius: 28),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -70,
              right: -35,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      rizeCyan.withOpacity(0.20),
                      rizeBlue.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool compact = constraints.maxWidth < 560;

                  final Widget streak = Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[rizeCyan, rizeBlue],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: rizeBlue.withOpacity(0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.white,
                          size: 33,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '$currentStreak-Tage-Serie',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.6,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentStreak == 0
                                  ? 'Starte heute Deine nächste Serie.'
                                  : 'Bleib dran – Dein Rekord liegt bei $bestStreak Tagen.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.66),
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  final Widget levelBlock = Container(
                    width: compact ? double.infinity : 260,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.07),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'AKTUELLES LEVEL',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.48),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    level,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${(progress * 100).round()}%',
                              style: const TextStyle(
                                color: rizeCyan,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 7,
                            backgroundColor: Colors.white.withOpacity(0.09),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              rizeCyan,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$activeDaysThisMonth aktive Tage in diesem Monat',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.58),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );

                  if (compact) {
                    return Column(
                      children: <Widget>[
                        streak,
                        const SizedBox(height: 20),
                        levelBlock,
                      ],
                    );
                  }

                  return Row(
                    children: <Widget>[
                      Expanded(child: streak),
                      const SizedBox(width: 22),
                      levelBlock,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MetricItem {
  const MetricItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class MetricGrid extends StatelessWidget {
  const MetricGrid({super.key, required this.items});

  final List<MetricItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth >= 760 ? 4 : 2;
        const double gap = 12;
        final double width =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items
              .map(
                (MetricItem item) => SizedBox(
                  width: width,
                  child: _MetricCard(item: item),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.item});

  final MetricItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 122),
      padding: const EdgeInsets.all(16),
      decoration: rizeCardDecoration(radius: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: rizeCyan.withOpacity(0.13),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(item.icon, color: rizeCyan, size: 20),
          ),
          const SizedBox(height: 15),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.58),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressChartCard extends StatelessWidget {
  const ProgressChartCard({
    super.key,
    required this.impactPoints,
    required this.scorePoints,
    required this.currentScore,
    required this.lastImpact,
  });

  final List<ProgressPoint> impactPoints;
  final List<ProgressPoint> scorePoints;
  final double? currentScore;
  final DayImpact? lastImpact;

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> impactSpots = _spots(impactPoints);
    final List<FlSpot> scoreSpots = _spots(scorePoints);
    final List<double> values = <double>[
      ...impactSpots.map((FlSpot spot) => spot.y),
      ...scoreSpots.map((FlSpot spot) => spot.y),
    ];
    final _ChartRange range = _chartRange(values);
    final Color impactColor = rizeImpactColor(lastImpact?.score ?? 0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: rizeCardDecoration(accentColor: rizeBlue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Score-Entwicklung',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Deine letzten 30 Tage',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.56),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (currentScore != null)
                _ScoreBadge(
                  label: 'RIZE-Score',
                  value: formatScore(currentScore!),
                  color: rizeCyan,
                ),
            ],
          ),
          if (lastImpact != null) ...<Widget>[
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                _LegendDot(label: 'RIZE-Score', color: rizeCyan),
                const SizedBox(width: 14),
                _LegendDot(label: 'Workout-Impact', color: impactColor),
                const Spacer(),
                Text(
                  'Letzter Impact ${formatScore(lastImpact!.score)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.54),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            height: 245,
            child: values.isEmpty
                ? const _EmptyChart()
                : LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: math.max(0, impactPoints.length - 1).toDouble(),
                      minY: range.min,
                      maxY: range.max,
                      clipData: const FlClipData.all(),
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        horizontalInterval: range.interval,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: Colors.white.withOpacity(0.065),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBorderRadius: BorderRadius.circular(12),
                          getTooltipItems: (List<LineBarSpot> spots) => spots
                              .map(
                                (LineBarSpot spot) => LineTooltipItem(
                                  formatScore(spot.y),
                                  TextStyle(
                                    color: spot.barIndex == 0
                                        ? rizeCyan
                                        : impactColor,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 38,
                            interval: range.interval,
                            getTitlesWidget: (double value, TitleMeta meta) =>
                                Text(
                              formatScore(value, decimals: 1),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.46),
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: 9,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              final int index = value.round();
                              if (index < 0 || index >= impactPoints.length) {
                                return const SizedBox.shrink();
                              }
                              final DateTime date = impactPoints[index].date;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '${date.day}.${date.month}.',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.46),
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: <LineChartBarData>[
                        LineChartBarData(
                          spots: scoreSpots,
                          isCurved: true,
                          curveSmoothness: 0.22,
                          barWidth: 3,
                          color: rizeCyan,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                rizeCyan.withOpacity(0.25),
                                rizeCyan.withOpacity(0),
                              ],
                            ),
                          ),
                        ),
                        LineChartBarData(
                          spots: impactSpots,
                          isCurved: false,
                          barWidth: 0,
                          color: impactColor,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (_, __, ___, ____) =>
                                FlDotCirclePainter(
                              radius: 4,
                              color: impactColor,
                              strokeWidth: 2,
                              strokeColor: const Color(0xFF164C91),
                            ),
                          ),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 350),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class ActivityCalendarCard extends StatelessWidget {
  const ActivityCalendarCard({
    super.key,
    required this.month,
    required this.activeDays,
  });

  final DateTime month;
  final Set<int> activeDays;

  static const List<String> _weekdays = <String>[
    'Mo',
    'Di',
    'Mi',
    'Do',
    'Fr',
    'Sa',
    'So',
  ];

  @override
  Widget build(BuildContext context) {
    final int leading = leadingCalendarCells(month);
    final int dayCount = daysInMonth(month);
    final int totalCells = ((leading + dayCount + 6) ~/ 7) * 7;
    final DateTime now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: rizeCardDecoration(accentColor: rizeCyan),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Aktivität im ${_monthLabel(month)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Jeder aktive Tag bringt Dich Deinem Ziel näher.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.56),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: rizeCyan.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${activeDays.length} Tage',
                  style: const TextStyle(
                    color: rizeCyan,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: _weekdays
                .map(
                  (String day) => Expanded(
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.46),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            itemCount: totalCells,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 7,
              crossAxisSpacing: 7,
            ),
            itemBuilder: (BuildContext context, int index) {
              final int day = index - leading + 1;
              if (day < 1 || day > dayCount) {
                return const SizedBox.shrink();
              }

              final bool active = activeDays.contains(day);
              final bool isToday = now.year == month.year &&
                  now.month == month.month &&
                  now.day == day;

              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: active
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[rizeCyan, rizeBlue],
                        )
                      : null,
                  color: active ? null : Colors.white.withOpacity(0.045),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: isToday
                        ? rizeCyan
                        : active
                            ? Colors.white.withOpacity(0.2)
                            : Colors.white.withOpacity(0.04),
                    width: isToday ? 1.5 : 1,
                  ),
                  boxShadow: active
                      ? <BoxShadow>[
                          BoxShadow(
                            color: rizeBlue.withOpacity(0.22),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: active
                        ? Colors.white
                        : Colors.white.withOpacity(0.58),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ProgressErrorState extends StatelessWidget {
  const ProgressErrorState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          padding: const EdgeInsets.all(20),
          decoration: rizeCardDecoration(accentColor: rizeRed),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.cloud_off_rounded, color: rizeRed, size: 38),
              const SizedBox(height: 12),
              const Text(
                'Daten konnten nicht geladen werden',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.56)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProgressLoadingState extends StatelessWidget {
  const ProgressLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: rizeCyan),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.54),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.show_chart_rounded,
            color: Colors.white.withOpacity(0.45),
            size: 34,
          ),
          const SizedBox(height: 8),
          Text(
            'Noch nicht genügend Daten',
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}

List<FlSpot> _spots(List<ProgressPoint> points) => points
    .where((ProgressPoint point) => point.value != null)
    .map(
      (ProgressPoint point) =>
          FlSpot(point.index.toDouble(), point.value!),
    )
    .toList(growable: false);

_ChartRange _chartRange(List<double> values) {
  if (values.isEmpty) {
    return const _ChartRange(min: 0, max: 1, interval: 0.25);
  }

  double min = values.reduce(math.min);
  double max = values.reduce(math.max);
  double span = max - min;
  if (span.abs() < 0.0001) {
    span = math.max(max.abs() * 0.2, 0.2);
  }

  final double padding = span * 0.16;
  min = math.max(0, min - padding);
  max += padding;

  return _ChartRange(
    min: min,
    max: max,
    interval: math.max((max - min) / 4, 0.01),
  );
}

class _ChartRange {
  const _ChartRange({
    required this.min,
    required this.max,
    required this.interval,
  });

  final double min;
  final double max;
  final double interval;
}

String _monthLabel(DateTime month) {
  const List<String> names = <String>[
    'Januar',
    'Februar',
    'März',
    'April',
    'Mai',
    'Juni',
    'Juli',
    'August',
    'September',
    'Oktober',
    'November',
    'Dezember',
  ];
  return names[month.month - 1];
}
