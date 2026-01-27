import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/constants/app_theme.dart';

class TournamentsScreen extends ConsumerStatefulWidget {
  const TournamentsScreen({super.key});

  @override
  ConsumerState<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends ConsumerState<TournamentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Mở đăng ký', 'Đang diễn ra', 'Đã kết thúc'];

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
    return Container(
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
          const SizedBox(height: 80),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Giải đấu',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentOrange,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tham gia các giải đấu hấp dẫn',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GlassCard(
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[700],
                tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTournamentList(context, 0),
                _buildTournamentList(context, 1),
                _buildTournamentList(context, 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentList(BuildContext context, int statusFilter) {
    final tournaments = _getMockTournaments();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: tournaments.length,
      itemBuilder: (context, index) {
        final t = tournaments[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            onTap: () => context.push('/tournaments/${t['id']}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Hero(
                      tag: 'tournament_${t['id']}',
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.accentOrange, AppTheme.secondaryPink],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.emoji_events, color: Colors.white, size: 30),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(DateFormat('dd/MM/yyyy').format(t['startDate']), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.successGreen),
                      ),
                      child: const Text('Mở đăng ký', style: TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoChip(Icons.people, '${t['participants']}/16'),
                    _buildInfoChip(Icons.payments, '${t['prize']} VNĐ'),
                    _buildInfoChip(Icons.sports_tennis, t['format']),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryBlue),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getMockTournaments() {
    return [
      {
        'id': 1,
        'name': 'Giải Pickleball Mùa Xuân 2024',
        'startDate': DateTime.now().add(const Duration(days: 7)),
        'participants': 12,
        'prize': '5.000.000',
        'format': 'Đơn',
      },
      {
        'id': 2,
        'name': 'Tournament VIP Platinum',
        'startDate': DateTime.now().add(const Duration(days: 14)),
        'participants': 8,
        'prize': '10.000.000',
        'format': 'Đôi',
      },
    ];
  }
}

class TournamentDetailScreen extends ConsumerWidget {
  final int tournamentId;
  
  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Chi tiết giải đấu'),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
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
            colors: [AppTheme.accentOrange.withOpacity(0.1), AppTheme.primaryPurple.withOpacity(0.1)],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 100),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Hero(
                  tag: 'tournament_$tournamentId',
                  child: GlassCard(
                    padding: const EdgeInsets.all(32),
                    gradientColors: [AppTheme.accentOrange.withOpacity(0.2), AppTheme.secondaryPink.withOpacity(0.2)],
                    child: const Icon(Icons.emoji_events, size: 100, color: Colors.white),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Giải Pickleball Mùa Xuân 2024', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildInfoRow('Giải thưởng:', '5.000.000 VNĐ'),
                          _buildInfoRow('Thành viên:', '12/16'),
                          _buildInfoRow('Bắt đầu:', DateFormat('dd/MM/yyyy').format(DateTime.now().add(const Duration(days: 7)))),
                          _buildInfoRow('Thể thức:', 'Đơn - Loại trực tiếp'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    GlassButton(
                      text: 'Tham gia giải đấu',
                      icon: Icons.login,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tính năng đang phát triển'), behavior: SnackBarBehavior.floating),
                        );
                      },
                      gradientColors: const [AppTheme.accentOrange, AppTheme.secondaryPink],
                      height: 56,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}
