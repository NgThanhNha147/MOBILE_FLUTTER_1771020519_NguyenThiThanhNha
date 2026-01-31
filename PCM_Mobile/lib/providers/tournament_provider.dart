import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tournament.dart';
import '../services/tournament_service.dart';

// Tournament Service Provider
final tournamentServiceProvider = Provider<TournamentService>((ref) {
  return TournamentService();
});

// Tournaments List Provider
final tournamentsProvider = FutureProvider<List<Tournament>>((ref) async {
  final service = ref.watch(tournamentServiceProvider);
  return await service.getTournaments();
});

// Single Tournament Provider
final tournamentProvider = FutureProvider.family<Tournament, int>((ref, id) async {
  final service = ref.watch(tournamentServiceProvider);
  return await service.getTournamentById(id);
});

// Tournament State Notifier for mutations
class TournamentNotifier extends StateNotifier<AsyncValue<List<Tournament>>> {
  final TournamentService _service;

  TournamentNotifier(this._service) : super(const AsyncValue.loading()) {
    loadTournaments();
  }

  Future<void> loadTournaments() async {
    state = const AsyncValue.loading();
    try {
      final tournaments = await _service.getTournaments();
      state = AsyncValue.data(tournaments);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createTournament(CreateTournamentRequest request) async {
    try {
      await _service.createTournament(request);
      await loadTournaments(); // Reload list
    } catch (e) {
      rethrow;
    }
  }

  Future<void> joinTournament(int tournamentId) async {
    try {
      await _service.joinTournament(tournamentId);
      await loadTournaments(); // Reload list
    } catch (e) {
      rethrow;
    }
  }

  Future<void> leaveTournament(int tournamentId) async {
    try {
      await _service.leaveTournament(tournamentId);
      await loadTournaments(); // Reload list
    } catch (e) {
      rethrow;
    }
  }
}

final tournamentNotifierProvider =
    StateNotifierProvider<TournamentNotifier, AsyncValue<List<Tournament>>>((ref) {
  final service = ref.watch(tournamentServiceProvider);
  return TournamentNotifier(service);
});
