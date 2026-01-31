import 'package:flutter/material.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../core/constants/app_theme.dart';
import '../../../models/enums.dart';
import 'package:intl/intl.dart';

class TournamentCard extends StatelessWidget {
  final Map<String, dynamic> tournament;
  final VoidCallback onTap;

  const TournamentCard({
    super.key,
    required this.tournament,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final type = tournament['type'] as TournamentType;
    final status = tournament['status'] as TournamentStatus;
    final currentParticipants = tournament['currentParticipants'] as int;
    final maxParticipants = tournament['maxParticipants'] as int;
    final prizePool = tournament['prizePool'] as double;
    final entryFee = tournament['entryFee'] as double;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildTypeIcon(type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tournament['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tournament['description'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        tournament['description'],
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                Icons.people,
                '$currentParticipants/$maxParticipants',
                AppTheme.primaryBlue,
              ),
              if (prizePool > 0)
                _buildInfoChip(
                  Icons.emoji_events,
                  _formatMoney(prizePool),
                  AppTheme.accentOrange,
                ),
              if (entryFee > 0)
                _buildInfoChip(
                  Icons.payments,
                  _formatMoney(entryFee),
                  AppTheme.successGreen,
                ),
              _buildInfoChip(
                Icons.calendar_today,
                DateFormat('dd/MM HH:mm').format(tournament['startDate']),
                Colors.purple,
              ),
            ],
          ),
          if (tournament['creatorName'] != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Tạo bởi: ${tournament['creatorName']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypeIcon(TournamentType type) {
    IconData icon;
    List<Color> colors;
    switch (type) {
      case TournamentType.official:
        icon = Icons.emoji_events;
        colors = [AppTheme.accentOrange, AppTheme.secondaryPink];
        break;
      case TournamentType.challenge1v1:
        icon = Icons.sports_kabaddi;
        colors = [Colors.red, Colors.deepOrange];
        break;
      case TournamentType.teamBattle:
        icon = Icons.groups;
        colors = [AppTheme.primaryBlue, AppTheme.secondaryTeal];
        break;
      case TournamentType.miniGame:
        icon = Icons.sports_esports;
        colors = [Colors.purple, Colors.deepPurple];
        break;
    }
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }

  Widget _buildStatusBadge(TournamentStatus status) {
    Color color;
    String text;
    switch (status) {
      case TournamentStatus.open:
      case TournamentStatus.registering:
        color = AppTheme.successGreen;
        text = 'Mở';
        break;
      case TournamentStatus.ongoing:
        color = AppTheme.primaryBlue;
        text = 'Live';
        break;
      case TournamentStatus.finished:
        color = Colors.grey;
        text = 'Kết thúc';
        break;
      default:
        color = Colors.grey;
        text = 'N/A';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMoney(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}tr';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}k';
    return amount.toStringAsFixed(0);
  }
}
