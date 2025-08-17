import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/habit_provider.dart';
import '../models/habit.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  String _selectedPeriod = 'week';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('统计')),
      body: Column(
        children: [
          // 时间周期选择器
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ['week', 'month', 'year'].map((period) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton(
                    onPressed: () => setState(() => _selectedPeriod = period),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedPeriod == period ? Colors.blue : null,
                    ),
                    child: Text(period == 'week' ? '周' : period == 'month' ? '月' : '年'),
                  ),
                );
              }).toList(),
            ),
          ),

          // 统计图表区域
          Expanded(
            child: _buildCharts(),
          ),
        ],
      ),
    );
  }

  Widget _buildCharts() {
    final habitProvider = Provider.of<HabitProvider>(context);
    final habits = habitProvider.habits;

    if (habits.isEmpty) {
      return const Center(child: Text('暂无习惯数据'));
    }

    return Column(
      children: [
        // 折线图 - 习惯趋势
        Expanded(
          child: LineChart(
            LineChartData(
              titlesData: FlTitlesData(show: true),
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: true),
              lineBarsData: habits.map((habit) {
                return LineChartBarData(
                  spots: _generateTrendData(habit),
                  isCurved: true,
                  color: Colors.blue,
                );
              }).toList(),
            ),
          ),
        ),

        // 饼图 - 习惯占比
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: _generatePieSections(habits),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
      ],
    );
  }

  List<FlSpot> _generateTrendData(Habit habit) {
    // 生成模拟数据
    return List.generate(7, (i) => FlSpot(i.toDouble(), (i * 2).toDouble())).toList();
  }

  List<PieChartSectionData> _generatePieSections(List<Habit> habits) {
    // 生成模拟数据
    const colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];
    return habits.asMap().entries.map((entry) {
      final index = entry.key;
      final habit = entry.value;
      return PieChartSectionData(
        value: (index + 1) * 10.0,
        color: colors[index % colors.length],
        title: habit.name,
      );
    }).toList();
  }
}