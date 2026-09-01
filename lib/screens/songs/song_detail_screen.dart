import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../database/database_helper.dart';
import '../../repositories/song_repository.dart';
import '../../services/analytics_service.dart';

class SongDetailScreen extends StatefulWidget {
  final int songId;
  final String title;
  final String artist;
  final int peakRank;
  final int weeksOnChart;
  final int chartScore;

  const SongDetailScreen({
    super.key,
    required this.songId,
    required this.title,
    required this.artist,
    required this.peakRank,
    required this.weeksOnChart,
    required this.chartScore,
  });

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  late Future<List<Map<String, dynamic>>> _chartHistory;

  @override
  void initState() {
    super.initState();
    _chartHistory = _loadChartHistory();
  }

  Future<List<Map<String, dynamic>>> _loadChartHistory() async {
    final db = await DatabaseHelper.instance.database;
    final repository = SongRepository(db);

    return repository.getSongChartHistory(widget.songId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Song Details'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _chartHistory,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load chart history.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final history = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ============================================================
              // SONG HEADER
              // ============================================================

              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                widget.artist,
                style: Theme.of(context).textTheme.titleMedium,
              ),

              const SizedBox(height: 24),

              // ============================================================
              // BASIC STATS
              // ============================================================

              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Peak Rank',
                      value: '#${widget.peakRank}',
                      icon: Icons.emoji_events_outlined,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _StatCard(
                      label: 'Weeks',
                      value: '${widget.weeksOnChart}',
                      icon: Icons.calendar_month_outlined,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _StatCard(
                label: 'ChartLens Score',
                value: '${widget.chartScore}',
                icon: Icons.analytics_outlined,
              ),

              const SizedBox(height: 32),

              // ============================================================
              // BILLBOARD SECTION
              // ============================================================

              const Text(
                'Billboard Hot 100',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                '${history.length} chart entries',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 16),

              // ============================================================
              // CHART TRAJECTORY
              // ============================================================

              _ChartCard(
                history: history,
              ),

              const SizedBox(height: 28),

              // ============================================================
              // ANALYTICS
              // ============================================================

              _AnalyticsSection(
                history: history,
              ),

              const SizedBox(height: 28),

              // ============================================================
              // WEEKLY HISTORY
              // ============================================================

              const Text(
                'Weekly History',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              _ChartHistoryList(
                history: history,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ==========================================================================
// STAT CARD
// ==========================================================================

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),

                  const SizedBox(height: 3),

                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// CHART CARD
// ==========================================================================

class _ChartCard extends StatelessWidget {
  final List<Map<String, dynamic>> history;

  const _ChartCard({
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    final spots = <FlSpot>[];

    for (int i = 0; i < history.length; i++) {
      final rank = (history[i]['rank'] as num?)?.toDouble();

      if (rank != null) {
        // Convert Billboard rank:
        //
        // #1   -> 100
        // #50  -> 51
        // #100 -> 1
        //
        // This makes better rankings appear higher
        // on the graph.
        spots.add(
          FlSpot(
            i.toDouble(),
            101 - rank,
          ),
        );
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          12,
          20,
          20,
          12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chart Trajectory',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              'Lower rank means better chart performance.',
              style: Theme.of(context).textTheme.bodySmall,
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 260,
              child: LineChart(
                LineChartData(
                  // ========================================================
                  // AXES
                  // ========================================================

                  minY: 1,
                  maxY: 100,

                  minX: 0,
                  maxX: spots.length > 1
                      ? (spots.length - 1).toDouble()
                      : 1,

                  // ========================================================
                  // GRID
                  // ========================================================

                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                  ),

                  // ========================================================
                  // BORDER
                  // ========================================================

                  borderData: FlBorderData(
                    show: false,
                  ),

                  // ========================================================
                  // TOUCH / TOOLTIP
                  // ========================================================

                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.round();

                          if (index < 0 || index >= history.length) {
                            return null;
                          }

                          final rank = history[index]['rank'];

                          return LineTooltipItem(
                            'Week ${index + 1}\nRank #$rank',
                            const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),

                  // ========================================================
                  // TITLES
                  // ========================================================

                  titlesData: FlTitlesData(
                    // TOP
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),

                    // RIGHT
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),

                    // BOTTOM
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 25,
                        getTitlesWidget: (value, meta) {
                          final index = value.round();

                          if (index < 0 || index >= history.length) {
                            return const SizedBox.shrink();
                          }

                          final dateString =
                              history[index]['chart_date']?.toString() ?? '';

                          final date = DateTime.tryParse(dateString);

                          if (date == null) {
                            return const SizedBox.shrink();
                          }

                          const months = [
                            'Jan',
                            'Feb',
                            'Mar',
                            'Apr',
                            'May',
                            'Jun',
                            'Jul',
                            'Aug',
                            'Sep',
                            'Oct',
                            'Nov',
                            'Dec',
                          ];

                          final label =
                              "${months[date.month - 1]} '${date.year.toString().substring(2)}";

                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // LEFT
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        interval: 20,
                        getTitlesWidget: (value, meta) {
                          final rank = 101 - value.toInt();

                          if (rank < 1 || rank > 100) {
                            return const SizedBox.shrink();
                          }

                          return Text(
                            '#$rank',
                            style: const TextStyle(
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // ========================================================
                  // LINE
                  // ========================================================

                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 3,

                      dotData: const FlDotData(
                        show: false,
                      ),

                      belowBarData: BarAreaData(
                        show: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// ANALYTICS SECTION
// ==========================================================================

class _AnalyticsSection extends StatelessWidget {
  final List<Map<String, dynamic>> history;

  const _AnalyticsSection({
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    final ranks = history
        .map((entry) => entry['rank'] as int)
        .toList();

    final averageRank =
        AnalyticsService.calculateAverageRank(ranks);

    final biggestClimb =
        AnalyticsService.calculateBiggestClimb(history);

    final biggestDrop =
        AnalyticsService.calculateBiggestDrop(history);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chart Analytics',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Insights calculated from weekly chart performance.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),

        const SizedBox(height: 16),

        // ROW 1
        Row(
          children: [
            Expanded(
              child: _AnalyticsCard(
                icon: Icons.show_chart,
                label: 'Average Rank',
                value: averageRank.toStringAsFixed(1),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _AnalyticsCard(
                icon: Icons.trending_up,
                label: 'Biggest Climb',
                value: '+$biggestClimb',
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ROW 2
        Row(
          children: [
            Expanded(
              child: _AnalyticsCard(
                icon: Icons.trending_down,
                label: 'Biggest Drop',
                value: biggestDrop == 0
                    ? '0'
                    : '$biggestDrop',
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _AnalyticsCard(
                icon: Icons.calendar_today,
                label: 'Weeks Tracked',
                value: '${history.length}',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ==========================================================================
// ANALYTICS CARD
// ==========================================================================

class _AnalyticsCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AnalyticsCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),

            const SizedBox(height: 12),

            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),

            const SizedBox(height: 4),

            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// WEEKLY HISTORY
// ==========================================================================

class _ChartHistoryList extends StatelessWidget {
  final List<Map<String, dynamic>> history;

  const _ChartHistoryList({
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No chart history available.',
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: history.asMap().entries.map((entry) {
          final index = entry.key;
          final week = entry.value;

          final date =
              week['chart_date']?.toString() ?? '-';

          final rank =
              week['rank']?.toString() ?? '-';

          final lastWeek =
              week['last_week_rank']?.toString() ?? '-';

          final peak =
              week['peak_rank']?.toString() ?? '-';

          final weeks =
              week['weeks_on_chart']?.toString() ?? '-';

          return ListTile(
            dense: true,

            leading: CircleAvatar(
              radius: 16,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
            ),

            title: Text(date),

            subtitle: Text(
              'Previous: #$lastWeek • '
              'Peak: #$peak • '
              'Weeks: $weeks',
            ),

            trailing: Text(
              '#$rank',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}