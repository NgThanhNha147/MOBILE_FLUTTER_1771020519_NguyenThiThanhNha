import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_theme.dart';
import '../../models/enums.dart';
import '../../models/tournament.dart';
import '../../providers/tournament_provider.dart';

class TournamentDetailScreen extends ConsumerStatefulWidget {
  final int tournamentId;

  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<TournamentDetailScreen> createState() =>
      _TournamentDetailScreenState();
}

class _TournamentDetailScreenState
    extends ConsumerState<TournamentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isJoining = false;
  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tournamentAsync = ref.watch(tournamentProvider(widget.tournamentId));

    return tournamentAsync.when(
      data: (tournament) => _buildContent(tournament),
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Chi tiết giải đấu')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Chi tiết giải đấu')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Lỗi: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.refresh(tournamentProvider(widget.tournamentId)),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Tournament tournament) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tournament.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.refresh(tournamentProvider(widget.tournamentId)),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Thông tin', icon: Icon(Icons.info_outline, size: 20)),
            Tab(text: 'Danh sách', icon: Icon(Icons.people_outline, size: 20)),
            Tab(
                text: 'Lịch thi đấu',
                icon: Icon(Icons.calendar_month, size: 20)),
            Tab(text: 'Kết quả', icon: Icon(Icons.emoji_events, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(tournament),
          _buildParticipantsTab(tournament),
          _buildScheduleTab(tournament),
          _buildResultsTab(tournament),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(tournament),
    );
  }

  Widget _buildInfoTab(Tournament tournament) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          _buildStatusBadge(tournament),
          const SizedBox(height: 16),

          // Main info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    Icons.category,
                    'Loại giải',
                    _formatTournamentType(tournament.type),
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    Icons.format_list_numbered,
                    'Thể thức',
                    _formatTournamentFormat(tournament.format),
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    Icons.people,
                    'Số người',
                    '${tournament.participants.length}/${tournament.maxParticipants}',
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    Icons.attach_money,
                    'Lệ phí',
                    '${NumberFormat('#,###').format(tournament.entryFee)}đ',
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    Icons.emoji_events,
                    'Giải thưởng',
                    '${NumberFormat('#,###').format(tournament.prizePool)}đ',
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    Icons.person,
                    'Người tạo',
                    tournament.creatorName ?? 'Không rõ',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Schedule card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📅 Lịch thi đấu',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.schedule,
                    'Bắt đầu',
                    DateFormat('dd/MM/yyyy HH:mm').format(tournament.startDate),
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    Icons.event,
                    'Kết thúc',
                    DateFormat('dd/MM/yyyy HH:mm').format(tournament.endDate),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Description card
          if (tournament.description != null &&
              tournament.description!.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📝 Mô tả',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tournament.description!,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildParticipantsTab(Tournament tournament) {
    if (tournament.participants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có người tham gia',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tournament.participants.length,
      itemBuilder: (context, index) {
        final participant = tournament.participants[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryBlue,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              participant.memberName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: participant.teamName != null
                ? Text(participant.teamName!)
                : null,
            trailing: participant.id == 1 // TODO: Check if current user
                ? const Icon(Icons.person, color: AppTheme.primaryBlue)
                : null,
          ),
        );
      },
    );
  }

  Widget _buildScheduleTab(Tournament tournament) {
    if (tournament.matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month_outlined,
                size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Lịch thi đấu chưa được công bố',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Sẽ được cập nhật sau khi bốc thăm',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tournament.matches.length,
      itemBuilder: (context, index) {
        final match = tournament.matches[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trận ${index + 1} - ${_formatMatchRound(match.round ?? '')}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        match.team1Player1Name ?? 'TBD',
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Text(' vs ', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Text(
                        match.team2Player1Name ?? 'TBD',
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                if (match.scheduledTime != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.access_time, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM HH:mm').format(match.scheduledTime),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultsTab(Tournament tournament) {
    final finishedMatches =
        tournament.matches.where((m) => m.winningSide != null).toList();

    if (finishedMatches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có kết quả',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Các trận đấu chưa diễn ra',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: finishedMatches.length,
      itemBuilder: (context, index) {
        final match = finishedMatches[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatMatchRound(match.round ?? ''),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            match.team1Player1Name ?? 'TBD',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: match.winningSide == WinningSide.team1
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (match.winningSide == WinningSide.team1)
                            const Icon(Icons.emoji_events,
                                color: Colors.amber, size: 20),
                        ],
                      ),
                    ),
                    const Text(' - ', style: TextStyle(fontSize: 18)),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            match.team2Player1Name ?? 'TBD',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: match.winningSide == WinningSide.team2
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (match.winningSide == WinningSide.team2)
                            const Icon(Icons.emoji_events,
                                color: Colors.amber, size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(Tournament tournament) {
    Color color;
    IconData icon;
    String text;

    switch (tournament.status) {
      case TournamentStatus.open:
        color = Colors.green;
        icon = Icons.check_circle;
        text = 'Đang mở đăng ký';
        break;
      case TournamentStatus.registering:
        color = Colors.blue;
        icon = Icons.people;
        text = 'Đang đăng ký';
        break;
      case TournamentStatus.drawCompleted:
        color = Colors.orange;
        icon = Icons.shuffle;
        text = 'Đã bốc thăm';
        break;
      case TournamentStatus.ongoing:
        color = AppTheme.accentOrange;
        icon = Icons.sports_tennis;
        text = 'Đang diễn ra';
        break;
      case TournamentStatus.finished:
        color = Colors.grey;
        icon = Icons.flag;
        text = 'Đã kết thúc';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget? _buildBottomActions(Tournament tournament) {
    // Don't show actions for finished tournaments
    if (tournament.status == TournamentStatus.finished) return null;

    // TODO: Implement proper join check
    final isJoined = false;
    final isFull =
        tournament.participants.length >= tournament.maxParticipants;
    final canJoin =
        tournament.status == TournamentStatus.open && !isFull && !isJoined;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (canJoin)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isJoining ? null : () => _handleJoin(tournament),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: _isJoining
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.login),
                  label: Text(
                    _isJoining ? 'Đang tham gia...' : 'Tham gia',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else if (isJoined)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _isLeaving ? null : () => _handleLeave(tournament),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: _isLeaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.red,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.logout),
                  label: Text(
                    _isLeaving ? 'Đang rời...' : 'Rời giải',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isFull ? 'Đã đủ người' : 'Đã đóng đăng ký',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleJoin(Tournament tournament) async {
    setState(() => _isJoining = true);

    try {
      await ref
          .read(tournamentNotifierProvider.notifier)
          .joinTournament(tournament.id);

      // Refresh tournament detail
      ref.refresh(tournamentProvider(widget.tournamentId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tham gia giải đấu thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  Future<void> _handleLeave(Tournament tournament) async {
    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận rời giải'),
        content:
            const Text('Bạn có chắc muốn rời khỏi giải đấu này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Rời giải'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLeaving = true);

    try {
      await ref
          .read(tournamentNotifierProvider.notifier)
          .leaveTournament(tournament.id);

      // Refresh tournament detail
      ref.refresh(tournamentProvider(widget.tournamentId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã rời giải đấu'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLeaving = false);
      }
    }
  }

  String _formatTournamentType(TournamentType type) {
    switch (type) {
      case TournamentType.official:
        return 'Giải chính thức';
      case TournamentType.challenge1v1:
        return 'Kèo 1v1';
      case TournamentType.teamBattle:
        return 'Đấu Team';
      case TournamentType.miniGame:
        return 'Mini Game';
    }
  }

  String _formatTournamentFormat(TournamentFormat format) {
    switch (format) {
      case TournamentFormat.knockout:
        return 'Loại trực tiếp';
      case TournamentFormat.roundRobin:
        return 'Vòng tròn';
      case TournamentFormat.hybrid:
        return 'Kết hợp';
    }
  }

  String _formatMatchRound(String round) {
    switch (round.toLowerCase()) {
      case 'final':
        return 'Chung kết';
      case 'semifinal':
        return 'Bán kết';
      case 'quarterfinal':
        return 'Tứ kết';
      default:
        return 'Vòng $round';
    }
  }
}
