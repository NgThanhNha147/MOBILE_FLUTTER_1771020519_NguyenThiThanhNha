import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/constants/app_theme.dart';
import '../../models/tournament.dart';
import '../../models/enums.dart';

class MatchDetailScreen extends ConsumerStatefulWidget {
  final TournamentMatch match;
  final String tournamentName;

  const MatchDetailScreen({
    super.key,
    required this.match,
    required this.tournamentName,
  });

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Tổng quan', 'Thống kê', 'Lịch sử'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Chi tiết trận đấu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              _showNotificationDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tinh nang chia se dang phat trien'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.accentOrange.withOpacity(0.1),
              AppTheme.primaryPurple.withOpacity(0.1),
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 100),

            // Match Header
            _buildMatchHeader(),

            const SizedBox(height: 16),

            // Tabs
            GlassCard(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.zero,
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryPurple,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppTheme.accentOrange,
                indicatorWeight: 3,
                tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildStatsTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildMatchHeader() {
    final isDoubles = widget.match.team1Player2Id != null;
    final hasResult =
        widget.match.team1Score != null && widget.match.team2Score != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        gradientColors: [
          AppTheme.accentOrange.withOpacity(0.2),
          AppTheme.primaryPurple.withOpacity(0.2),
        ],
        child: Column(
          children: [
            // Tournament name and round
            Text(
              widget.tournamentName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryPurple,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              widget.match.round ?? 'Vòng đấu',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),

            // Match Score Display
            Row(
              children: [
                // Team 1
                Expanded(
                  child: Column(
                    children: [
                      _buildPlayerAvatar(
                        widget.match.team1Player1Name ?? 'Player 1',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.match.team1Player1Name ?? 'Player 1',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: widget.match.winningSide == WinningSide.team1
                              ? AppTheme.accentOrange
                              : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isDoubles &&
                          widget.match.team1Player2Name != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.match.team1Player2Name!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Score
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        hasResult ? '${widget.match.team1Score}' : '-',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: widget.match.winningSide == WinningSide.team1
                              ? AppTheme.accentOrange
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        ':',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w300,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        hasResult ? '${widget.match.team2Score}' : '-',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: widget.match.winningSide == WinningSide.team2
                              ? AppTheme.accentOrange
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                // Team 2
                Expanded(
                  child: Column(
                    children: [
                      _buildPlayerAvatar(
                        widget.match.team2Player1Name ?? 'Player 2',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.match.team2Player1Name ?? 'Player 2',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: widget.match.winningSide == WinningSide.team2
                              ? AppTheme.accentOrange
                              : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isDoubles &&
                          widget.match.team2Player2Name != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.match.team2Player2Name!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Match Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoChip(
                  Icons.calendar_today,
                  DateFormat('dd/MM/yyyy').format(widget.match.scheduledTime),
                ),
                _buildInfoChip(
                  Icons.access_time,
                  DateFormat('HH:mm').format(widget.match.scheduledTime),
                ),
                if (widget.match.courtName != null)
                  _buildInfoChip(Icons.sports_tennis, widget.match.courtName!),
              ],
            ),

            const SizedBox(height: 12),

            // Status Badge
            _buildStatusBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerAvatar(String name) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryPurple.withOpacity(0.8),
            AppTheme.accentOrange.withOpacity(0.8),
          ],
        ),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryPurple),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (widget.match.status) {
      case MatchStatus.scheduled:
        statusColor = Colors.blue;
        statusText = 'Đã lên lịch';
        statusIcon = Icons.schedule;
        break;
      case MatchStatus.inProgress:
        statusColor = Colors.green;
        statusText = 'Đang diễn ra';
        statusIcon = Icons.play_circle_outline;
        break;
      case MatchStatus.finished:
        statusColor = AppTheme.accentOrange;
        statusText = 'Đã hoàn thành';
        statusIcon = Icons.check_circle_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 18, color: statusColor),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Match Details
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thông tin trận đấu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryPurple,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Giải đấu', widget.tournamentName),
                _buildDetailRow('Vòng đấu', widget.match.round ?? '-'),
                _buildDetailRow('Sân', widget.match.courtName ?? '-'),
                _buildDetailRow(
                  'Thời gian',
                  DateFormat(
                    'dd/MM/yyyy HH:mm',
                  ).format(widget.match.scheduledTime),
                ),
                _buildDetailRow(
                  'Loại',
                  widget.match.team1Player2Id != null ? 'Đánh đôi' : 'Đánh đơn',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Team 1 Details
          _buildTeamDetailsCard(
            'Đội 1',
            widget.match.team1Player1Name ?? 'Player 1',
            widget.match.team1Player2Name,
            widget.match.team1Score,
            widget.match.winningSide == WinningSide.team1,
          ),

          const SizedBox(height: 16),

          // Team 2 Details
          _buildTeamDetailsCard(
            'Đội 2',
            widget.match.team2Player1Name ?? 'Player 2',
            widget.match.team2Player2Name,
            widget.match.team2Score,
            widget.match.winningSide == WinningSide.team2,
          ),

          const SizedBox(height: 16),

          // Match Notes (if any)
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.notes,
                      color: AppTheme.primaryPurple,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Ghi chú',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Chưa có ghi chú cho trận đấu này.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamDetailsCard(
    String teamLabel,
    String player1Name,
    String? player2Name,
    int? score,
    bool isWinner,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      gradientColors: isWinner
          ? [
              AppTheme.accentOrange.withOpacity(0.1),
              AppTheme.accentOrange.withOpacity(0.05),
            ]
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                teamLabel,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isWinner
                      ? AppTheme.accentOrange
                      : AppTheme.primaryPurple,
                ),
              ),
              const Spacer(),
              if (isWinner)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.emoji_events, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Chiến thắng',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Divider(height: 24),
          _buildDetailRow('Vận động viên 1', player1Name),
          if (player2Name != null)
            _buildDetailRow('Vận động viên 2', player2Name),
          _buildDetailRow('Điểm số', score != null ? '$score' : '-'),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    // Mock statistics data
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thống kê trận đấu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryPurple,
                  ),
                ),
                const SizedBox(height: 20),
                _buildStatRow('Tổng số điểm', '21', '19'),
                _buildStatRow('Ace', '3', '2'),
                _buildStatRow('Lỗi kỹ thuật', '5', '7'),
                _buildStatRow('Smash thành công', '8', '6'),
                _buildStatRow('Thời gian thi đấu', '45 phút', '45 phút'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String team1Value, String team2Value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  team1Value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Container(width: 2, height: 20, color: Colors.grey[300]),
              Expanded(
                child: Text(
                  team2Value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    // Mock head-to-head history
    final mockHistory = [
      {
        'date': '15/01/2026',
        'tournament': 'Giải CLB Tháng 1',
        'score1': 21,
        'score2': 18,
        'winner': 1,
      },
      {
        'date': '28/12/2025',
        'tournament': 'Giải Cuối Năm',
        'score1': 19,
        'score2': 21,
        'winner': 2,
      },
      {
        'date': '10/11/2025',
        'tournament': 'Giải Mùa Thu',
        'score1': 21,
        'score2': 16,
        'winner': 1,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lịch sử đối đầu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryPurple,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildHistoryStat('2', 'Thắng', Colors.green),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    _buildHistoryStat('1', 'Thua', Colors.red),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    _buildHistoryStat('3', 'Tổng', AppTheme.primaryPurple),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...mockHistory.map((match) => _buildHistoryCard(match)),
        ],
      ),
    );
  }

  Widget _buildHistoryStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> match) {
    final isTeam1Winner = match['winner'] == 1;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                match['date'],
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  match['tournament'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.match.team1Player1Name ?? 'Player 1',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isTeam1Winner
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isTeam1Winner
                        ? AppTheme.accentOrange
                        : Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${match['score1']} - ${match['score2']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  widget.match.team2Player1Name ?? 'Player 2',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: !isTeam1Winner
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: !isTeam1Winner
                        ? AppTheme.accentOrange
                        : Colors.black87,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildBottomActions() {
    if (widget.match.status == MatchStatus.scheduled) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _showCancelMatchDialog();
                },
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Hủy trận'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showRescheduleDialog();
                },
                icon: const Icon(Icons.edit_calendar),
                label: const Text('Đổi lịch'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return null;
  }

  void _showNotificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông báo trận đấu'),
        content: const Text(
          'Bạn có muốn nhận thông báo khi trận đấu này sắp diễn ra?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã bật thông báo cho trận đấu này'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }

  void _showCancelMatchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy trận đấu'),
        content: const Text(
          'Bạn có chắc chắn muốn hủy trận đấu này? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Trận đấu đã được hủy'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hủy trận'),
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi lịch trận đấu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Chức năng đổi lịch đang được phát triển.'),
            const SizedBox(height: 16),
            Text(
              'Hiện tại: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.match.scheduledTime)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
