import 'package:dio/dio.dart';
import '../core/services/dio_client.dart';
import '../core/constants/api_constants.dart';
import '../models/tournament.dart';
import '../models/enums.dart';

class TournamentService {
  final dio = DioClient().dio;

  // Get all tournaments with optional filters
  Future<List<Tournament>> getTournaments({
    TournamentType? type,
    TournamentStatus? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (type != null) {
        queryParams['type'] = type.index;
      }
      if (status != null) {
        queryParams['status'] = status.index;
      }

      final response = await dio.get(
        ApiConstants.getTournaments,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      print('📦 Tournaments response: ${response.data}');

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => Tournament.fromJson(json)).toList();
      }

      throw Exception(response.data['message'] ?? 'Failed to load tournaments');
    } on DioException catch (e) {
      print('💥 Error loading tournaments: ${e.response?.data}');
      throw _handleError(e);
    } catch (e) {
      print('💥 Unexpected error: $e');
      throw Exception('Error loading tournaments: $e');
    }
  }

  // Get tournament by ID
  Future<Tournament> getTournamentById(int id) async {
    try {
      final response = await dio.get('${ApiConstants.getTournaments}/$id');

      print('📦 Tournament detail response: ${response.data}');

      if (response.data['success'] == true) {
        return Tournament.fromJson(response.data['data']);
      }

      throw Exception(response.data['message'] ?? 'Failed to load tournament');
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Error loading tournament: $e');
    }
  }

  // Create tournament
  Future<Tournament> createTournament(CreateTournamentRequest request) async {
    try {
      final response = await dio.post(
        ApiConstants.getTournaments,
        data: request.toJson(),
      );

      if (response.data['success'] == true) {
        return Tournament.fromJson(response.data['data']);
      }

      throw Exception(
        response.data['message'] ?? 'Failed to create tournament',
      );
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Error creating tournament: $e');
    }
  }

  // Join tournament
  Future<void> joinTournament(int tournamentId) async {
    try {
      final response = await dio.post(
        '${ApiConstants.getTournaments}/$tournamentId/join',
      );

      if (response.data['success'] != true) {
        throw Exception(
          response.data['message'] ?? 'Failed to join tournament',
        );
      }
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Error joining tournament: $e');
    }
  }

  // Leave tournament
  Future<void> leaveTournament(int tournamentId) async {
    try {
      final response = await dio.post(
        '${ApiConstants.getTournaments}/$tournamentId/leave',
      );

      if (response.data['success'] != true) {
        throw Exception(
          response.data['message'] ?? 'Failed to leave tournament',
        );
      }
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      throw Exception('Error leaving tournament: $e');
    }
  }

  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      }
      if (data is Map && data.containsKey('title')) {
        return data['title'];
      }
      return 'Lỗi: ${error.response!.statusMessage}';
    } else {
      return 'Không thể kết nối đến server';
    }
  }
}
