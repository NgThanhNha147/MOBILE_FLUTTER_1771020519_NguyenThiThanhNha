import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_theme.dart';
import '../../models/enums.dart';
import '../../models/tournament.dart';
import '../../providers/tournament_provider.dart';
import 'widgets/tournament_card.dart';
import 'widgets/create_tournament_dialog.dart';

class TournamentsScreen extends ConsumerStatefulWidget {
  const TournamentsScreen({super.key});

  @override
  ConsumerState<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends ConsumerState<TournamentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _typeTabController;
  TournamentType _selectedType = TournamentType.official;
  TournamentStatus _selectedStatus = TournamentStatus.open;

  final List<TournamentType> _types = [
    TournamentType.official,
    TournamentType.challenge1v1,
    TournamentType.teamBattle,
    TournamentType.miniGame,
  ];

  @override
  void initState() {
    super.initState();
    _typeTabController = TabController(length: _types.length, vsync: this);
    _typeTabController.addListener(() {
      if (!_typeTabController.indexIsChanging) {
        setState(() {
          _selectedType = _types[_typeTabController.index];
        });
      }
    });
  }

  @override
  void dispose() {
    _typeTabController.dispose();
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
          
          // Header with Create button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🏆 Giải đấu & Kèo',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentOrange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getTypeDescription(_selectedType),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Show Create button only for Challenge1v1 and TeamBattle
                if (_selectedType == TournamentType.challenge1v1 ||
                    _selectedType == TournamentType.teamBattle)
                  ElevatedButton.icon(
                    onPressed: () => _showCreateDialog(),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Tạo mới'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Type Tabs (4 loại giải)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _typeTabController,
              indicator: BoxDecoration(
                color: AppTheme.accentOrange,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[700],
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(text: _getTypeShortName(TournamentType.official)),
                Tab(text: _getTypeShortName(TournamentType.challenge1v1)),
                Tab(text: _getTypeShortName(TournamentType.teamBattle)),
                Tab(text: _getTypeShortName(TournamentType.miniGame)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Status Filter Chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildStatusChip(TournamentStatus.open, '🟢 Mở đăng ký'),
                const SizedBox(width: 8),
                _buildStatusChip(TournamentStatus.ongoing, '🔴 Đang diễn ra'),
                const SizedBox(width: 8),
                _buildStatusChip(TournamentStatus.finished, '⚫ Đã kết thúc'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tournament List
          Expanded(
            child: _buildTournamentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(TournamentStatus status, String label) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedStatus = status;
          });
        }
      },
      backgroundColor: Colors.white,
      selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryBlue,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryBlue : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildTournamentList() {
    final tournamentsAsync = ref.watch(
      filteredTournamentsProvider((
        type: _selectedType,
        status: _selectedStatus,
      )),
    );

    return tournamentsAsync.when(
      data: (tournaments) {
        if (tournaments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Chưa có giải đấu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getEmptyMessage(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_selectedType == TournamentType.challenge1v1 ||
                    _selectedType == TournamentType.teamBattle)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: ElevatedButton.icon(
                      onPressed: () => _showCreateDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Tạo giải đấu mới'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(filteredTournamentsProvider((
              type: _selectedType,
              status: _selectedStatus,
            )));
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: tournaments.length,
            itemBuilder: (context, index) {
              final tournament = tournaments[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TournamentCard(
                  tournament: _tournamentToMap(tournament),
                  onTap: () => context.push('/tournaments/${tournament.id}'),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Lỗi tải dữ liệu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(filteredTournamentsProvider((
                  type: _selectedType,
                  status: _selectedStatus,
                )));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _tournamentToMap(Tournament tournament) {
    return {
      'id': tournament.id,
      'name': tournament.name,
      'description': tournament.description,
      'type': tournament.type,
      'status': tournament.status,
      'startDate': tournament.startDate,
      'endDate': tournament.endDate,
      'format': tournament.format,
      'maxParticipants': tournament.maxParticipants,
      'currentParticipants': tournament.participants.length,
      'entryFee': tournament.entryFee,
      'prizePool': tournament.prizePool,
      'creatorName': tournament.creatorName ?? 'Admin',
    };
  }

  String _getTypeShortName(TournamentType type) {
    switch (type) {
      case TournamentType.official:
        return 'Giải đấu';
      case TournamentType.challenge1v1:
        return 'Kèo 1v1';
      case TournamentType.teamBattle:
        return 'Đấu Team';
      case TournamentType.miniGame:
        return 'Mini Game';
    }
  }

  String _getTypeDescription(TournamentType type) {
    switch (type) {
      case TournamentType.official:
        return 'Giải đấu chính thức do CLB tổ chức';
      case TournamentType.challenge1v1:
        return 'Thách đấu 1v1 - Tự tạo và tham gia';
      case TournamentType.teamBattle:
        return 'Đấu đội - Tự tạo và tham gia';
      case TournamentType.miniGame:
        return 'Mini game cuối tuần - 12 người, lệ phí 50k';
    }
  }

  String _getEmptyMessage() {
    switch (_selectedStatus) {
      case TournamentStatus.open:
        return 'Chưa có giải đấu nào đang mở đăng ký';
      case TournamentStatus.ongoing:
        return 'Chưa có giải đấu nào đang diễn ra';
      case TournamentStatus.finished:
        return 'Chưa có giải đấu nào đã kết thúc';
      default:
        return 'Chưa có giải đấu';
    }
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateTournamentDialog(
        initialType: _selectedType,
      ),
    );
  }
}

// Provider for filtered tournaments
final filteredTournamentsProvider = FutureProvider.family<List<Tournament>,
    ({TournamentType type, TournamentStatus status})>((ref, filters) async {
  final service = ref.watch(tournamentServiceProvider);
  return await service.getTournaments(
    type: filters.type,
    status: filters.status,
  );
});
