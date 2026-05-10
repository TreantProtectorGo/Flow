import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/statistics_provider.dart';
import '../widgets/stats_goal_card.dart';
import '../widgets/stats_streak_card.dart';
import '../widgets/stats_heatmap.dart';
import '../widgets/stats_time_of_day_chart.dart';
import '../l10n/app_localizations.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // 每次進入統計頁面時重新載入最新資料
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(statisticsProvider.notifier).loadStatistics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final stats = ref.watch(statisticsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Tab Bar
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: l10n.todayStats),
                Tab(text: l10n.weekStats),
                Tab(text: l10n.monthStats),
              ],
            ),

            // Content
            Expanded(
              child: stats.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTodayView(context, theme, stats.state, l10n),
                        _buildWeekView(context, theme, stats.state, l10n),
                        _buildMonthView(context, theme, stats.state, l10n),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayView(
    BuildContext context,
    ThemeData theme,
    StatisticsState stats,
    AppLocalizations l10n,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Streak days card
          StatsStreakCard(
            streakDays: stats.streakDays,
            todayCompleted: stats.todayCompleted,
          ),

          const SizedBox(height: 20),

          // Daily goal progress
          StatsGoalCard(
            title: l10n.todayGoal,
            current: stats.todayCompleted,
            goal: stats.dailyGoal,
            icon: Icons.today,
            color: theme.colorScheme.primary,
          ),

          const SizedBox(height: 20),

          // Today overview card
          _buildSummaryCard(
            theme: theme,
            title: l10n.todayOverview,
            stats: [
              _StatItem(
                icon: Icons.timer,
                label: l10n.completedPomodoros,
                value: '${stats.todayCompleted}',
                color: theme.colorScheme.primary,
              ),
              _StatItem(
                icon: Icons.schedule,
                label: l10n.focusTime,
                value: l10n.minutes(stats.todayFocusMinutes),
                color: theme.colorScheme.secondary,
              ),
              _StatItem(
                icon: Icons.task_alt,
                label: l10n.completedTasks,
                value: '${stats.todayCompletedTasks}',
                color: theme.colorScheme.tertiary,
              ),
              _StatItem(
                icon: Icons.percent,
                label: l10n.completionRate,
                value: '${stats.todayCompletionRate.toStringAsFixed(0)}%',
                color: _completionRateColor(
                  stats.todayCompletionRate,
                  theme.colorScheme,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Today time distribution
          _buildChartCard(
            theme: theme,
            title: l10n.todayTimeDistribution,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(
                height: 220,
                child: stats.todayCompleted > 0
                    ? PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: stats.todayCompleted.toDouble(),
                              title:
                                  '${l10n.completed}\n${stats.todayCompleted}',
                              color: theme.colorScheme.primary,
                              radius: 80,
                              titleStyle: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                            if (stats.todayIncomplete > 0)
                              PieChartSectionData(
                                value: stats.todayIncomplete.toDouble(),
                                title:
                                    '${l10n.incomplete}\n${stats.todayIncomplete}',
                                color: theme.colorScheme.errorContainer,
                                radius: 70,
                                titleStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                              ),
                          ],
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                        ),
                      )
                    : _buildEmptyState(l10n.noPomodoros, theme),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWeekView(
    BuildContext context,
    ThemeData theme,
    StatisticsState stats,
    AppLocalizations l10n,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // This week overview
          _buildSummaryCard(
            theme: theme,
            title: l10n.thisWeekOverview,
            stats: [
              _StatItem(
                icon: Icons.timer,
                label: l10n.completedPomodoros,
                value: '${stats.weekCompleted}',
                color: theme.colorScheme.primary,
              ),
              _StatItem(
                icon: Icons.schedule,
                label: l10n.focusTime,
                value: l10n.hours(
                  (stats.weekFocusMinutes / 60).toStringAsFixed(1),
                ),
                color: theme.colorScheme.secondary,
              ),
              _StatItem(
                icon: Icons.local_fire_department,
                label: l10n.streakDays,
                value: '${stats.streakDays}',
                color: theme.colorScheme.tertiary,
              ),
              _StatItem(
                icon: Icons.trending_up,
                label: l10n.dailyAverage,
                value: (stats.weekCompleted / 7).toStringAsFixed(1),
                color: theme.colorScheme.tertiary,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Weekly goal progress
          StatsGoalCard(
            title: l10n.thisWeekGoal,
            current: stats.weekCompleted,
            goal: stats.weeklyGoal,
            icon: Icons.calendar_today,
            color: theme.colorScheme.secondary,
          ),

          const SizedBox(height: 20),

          // Best focus time analysis
          _buildChartCard(
            theme: theme,
            title: l10n.bestFocusTime,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StatsTimeOfDayChart(data: stats.timeOfDayStats),
            ),
          ),

          const SizedBox(height: 20),

          // This week trend chart
          _buildChartCard(
            theme: theme,
            title: l10n.thisWeekTrend,
            child: SizedBox(
              height: 250,
              child: stats.weeklyData.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(right: 20, top: 20),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY:
                              (stats.weeklyData.values.reduce(
                                        (a, b) => a > b ? a : b,
                                      ) +
                                      2)
                                  .toDouble(),
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final day = stats.weeklyData.keys.elementAt(
                                  group.x.toInt(),
                                );
                                return BarTooltipItem(
                                  '$day\n${l10n.pomodoroCount(rod.toY.toInt())}',
                                  TextStyle(
                                    color: theme.colorScheme.onInverseSurface,
                                  ),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= 0 &&
                                      value.toInt() < stats.weeklyData.length) {
                                    final day = stats.weeklyData.keys.elementAt(
                                      value.toInt(),
                                    );
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        day,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: theme.textTheme.bodySmall,
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 2,
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(
                            stats.weeklyData.length,
                            (index) => BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: stats.weeklyData.values
                                      .elementAt(index)
                                      .toDouble(),
                                  color: theme.colorScheme.primary,
                                  width: 30,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : _buildEmptyState(l10n.noWeekStats, theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthView(
    BuildContext context,
    ThemeData theme,
    StatisticsState stats,
    AppLocalizations l10n,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // This month overview
          _buildSummaryCard(
            theme: theme,
            title: l10n.thisMonthOverview,
            stats: [
              _StatItem(
                icon: Icons.timer,
                label: l10n.completedPomodoros,
                value: '${stats.monthCompleted}',
                color: theme.colorScheme.primary,
              ),
              _StatItem(
                icon: Icons.schedule,
                label: l10n.focusTime,
                value: l10n.hours(
                  (stats.monthFocusMinutes / 60).toStringAsFixed(1),
                ),
                color: theme.colorScheme.secondary,
              ),
              _StatItem(
                icon: Icons.calendar_today,
                label: l10n.workDays,
                value: '${stats.monthActiveDays}',
                color: theme.colorScheme.tertiary,
              ),
              _StatItem(
                icon: Icons.star,
                label: l10n.bestDay,
                value: '${stats.monthBestDay}',
                color: theme.colorScheme.tertiary,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Monthly heatmap
          _buildChartCard(
            theme: theme,
            title: l10n.monthlyHeatmap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StatsHeatmap(
                data: stats.heatmapData,
                baseColor: theme.colorScheme.primary,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // This month trend
          _buildChartCard(
            theme: theme,
            title: l10n.thisMonthTrend,
            child: SizedBox(
              height: 250,
              child: stats.monthlyData.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(right: 10, top: 20),
                      child: LineChart(
                        LineChartData(
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  return LineTooltipItem(
                                    l10n.pomodoroCount(spot.y.toInt()),
                                    TextStyle(
                                      color: theme.colorScheme.onInverseSurface,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                          ),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 5,
                                getTitlesWidget: (value, meta) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      value.toInt().toString(),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: theme.textTheme.bodySmall,
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: stats.monthlyData.entries
                                  .map(
                                    (e) => FlSpot(
                                      e.key.toDouble(),
                                      e.value.toDouble(),
                                    ),
                                  )
                                  .toList(),
                              isCurved: true,
                              color: theme.colorScheme.primary,
                              barWidth: 3,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _buildEmptyState(l10n.noMonthStats, theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required ThemeData theme,
    required String title,
    required List<_StatItem> stats,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: stats
                  .map((stat) => _buildStatItem(stat, theme))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(_StatItem stat, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: stat.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(stat.icon, color: stat.color, size: 22),
          const SizedBox(height: 6),
          Text(
            stat.value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: stat.color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            stat.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required ThemeData theme,
    required String title,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

Color _completionRateColor(double rate, ColorScheme colorScheme) {
  if (rate >= 70) {
    return colorScheme.primary;
  }
  if (rate >= 40) {
    return colorScheme.tertiary;
  }
  return colorScheme.error;
}
