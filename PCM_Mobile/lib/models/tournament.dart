import 'enums.dart';

/// Tournament Model
class Tournament {
  final int id;
  final String name;
  final String? description;
  final TournamentType type;
  final DateTime startDate;
  final DateTime endDate;
  final TournamentFormat format;
  final TournamentStatus status;
  final int maxParticipants;
  final double entryFee;
  final double prizePool;
  final int? creatorId;
  final String? creatorName;
  final Map<String, dynamic>? settings;
  final List<TournamentParticipant> participants;
  final List<TournamentMatch> matches;

  Tournament({
    required this.id,
    required this.name,
    this.description,
    this.type = TournamentType.official,
    required this.startDate,
    required this.endDate,
    required this.format,
    this.status = TournamentStatus.open,
    this.maxParticipants = 16,
    this.entryFee = 0.0,
    this.prizePool = 0.0,
    this.creatorId,
    this.creatorName,
    this.settings,
    this.participants = const [],
    this.matches = const [],
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: json['type'] is int
          ? TournamentType.values[json['type'] as int]
          : TournamentType.values.firstWhere(
              (e) => e.toString().split('.').last == json['type'],
              orElse: () => TournamentType.official,
            ),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      format: json['format'] is int
          ? TournamentFormat.values[json['format'] as int]
          : TournamentFormat.values.firstWhere(
              (e) => e.toString().split('.').last == json['format'],
            ),
      status: json['status'] is int
          ? TournamentStatus.values[json['status'] as int]
          : TournamentStatus.values.firstWhere(
              (e) => e.toString().split('.').last == json['status'],
              orElse: () => TournamentStatus.open,
            ),
      maxParticipants: json['maxParticipants'] as int? ?? 16,
      entryFee: (json['entryFee'] as num?)?.toDouble() ?? 0.0,
      prizePool: (json['prizePool'] as num?)?.toDouble() ?? 0.0,
      creatorId: json['creatorId'] as int?,
      creatorName: json['creatorName'] as String?,
      settings: json['settings'] as Map<String, dynamic>?,
      participants:
          (json['participants'] as List<dynamic>?)
              ?.map(
                (e) =>
                    TournamentParticipant.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      matches:
          (json['matches'] as List<dynamic>?)
              ?.map((e) => TournamentMatch.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'format': format.toString().split('.').last,
      'status': status.toString().split('.').last,
      'maxParticipants': maxParticipants,
      'entryFee': entryFee,
      'prizePool': prizePool,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'settings': settings,
      'participants': participants.map((e) => e.toJson()).toList(),
      'matches': matches.map((e) => e.toJson()).toList(),
    };
  }
}

/// Tournament Participant Model
class TournamentParticipant {
  final int id;
  final int tournamentId;
  final int memberId;
  final String memberName;
  final String? teamName;
  final int? partnerId;
  final String? partnerName;
  final DateTime registrationDate;
  final bool isApproved;
  final int wins;
  final int losses;
  final int points;
  final int? rank;

  TournamentParticipant({
    required this.id,
    required this.tournamentId,
    required this.memberId,
    required this.memberName,
    this.teamName,
    this.partnerId,
    this.partnerName,
    required this.registrationDate,
    this.isApproved = false,
    this.wins = 0,
    this.losses = 0,
    this.points = 0,
    this.rank,
  });

  factory TournamentParticipant.fromJson(Map<String, dynamic> json) {
    return TournamentParticipant(
      id: json['id'] as int,
      tournamentId: json['tournamentId'] as int,
      memberId: json['memberId'] as int,
      memberName: json['memberName'] as String,
      teamName: json['teamName'] as String?,
      partnerId: json['partnerId'] as int?,
      partnerName: json['partnerName'] as String?,
      registrationDate: DateTime.parse(json['registrationDate'] as String),
      isApproved: json['isApproved'] as bool? ?? false,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      points: json['points'] as int? ?? 0,
      rank: json['rank'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournamentId': tournamentId,
      'memberId': memberId,
      'memberName': memberName,
      'teamName': teamName,
      'partnerId': partnerId,
      'partnerName': partnerName,
      'registrationDate': registrationDate.toIso8601String(),
      'isApproved': isApproved,
      'wins': wins,
      'losses': losses,
      'points': points,
      'rank': rank,
    };
  }
}

/// Tournament Match Model
class TournamentMatch {
  final int id;
  final int tournamentId;
  final int? courtId;
  final String? courtName;
  final DateTime scheduledTime;
  final String? round;
  final int team1Player1Id;
  final String? team1Player1Name;
  final int? team1Player2Id;
  final String? team1Player2Name;
  final int team2Player1Id;
  final String? team2Player1Name;
  final int? team2Player2Id;
  final String? team2Player2Name;
  final int? team1Score;
  final int? team2Score;
  final MatchStatus status;
  final WinningSide? winningSide;

  TournamentMatch({
    required this.id,
    required this.tournamentId,
    this.courtId,
    this.courtName,
    required this.scheduledTime,
    this.round,
    required this.team1Player1Id,
    this.team1Player1Name,
    this.team1Player2Id,
    this.team1Player2Name,
    required this.team2Player1Id,
    this.team2Player1Name,
    this.team2Player2Id,
    this.team2Player2Name,
    this.team1Score,
    this.team2Score,
    this.status = MatchStatus.scheduled,
    this.winningSide,
  });

  factory TournamentMatch.fromJson(Map<String, dynamic> json) {
    return TournamentMatch(
      id: json['id'] as int,
      tournamentId: json['tournamentId'] as int,
      courtId: json['courtId'] as int?,
      courtName: json['courtName'] as String?,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      round: json['round'] as String?,
      team1Player1Id: json['team1Player1Id'] as int,
      team1Player1Name: json['team1Player1Name'] as String?,
      team1Player2Id: json['team1Player2Id'] as int?,
      team1Player2Name: json['team1Player2Name'] as String?,
      team2Player1Id: json['team2Player1Id'] as int,
      team2Player1Name: json['team2Player1Name'] as String?,
      team2Player2Id: json['team2Player2Id'] as int?,
      team2Player2Name: json['team2Player2Name'] as String?,
      team1Score: json['team1Score'] as int?,
      team2Score: json['team2Score'] as int?,
      status: json['status'] != null
          ? MatchStatus.values.firstWhere(
              (e) => e.toString().split('.').last == json['status'],
              orElse: () => MatchStatus.scheduled,
            )
          : MatchStatus.scheduled,
      winningSide: json['winningSide'] != null
          ? WinningSide.values.firstWhere(
              (e) => e.toString().split('.').last == json['winningSide'],
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournamentId': tournamentId,
      'courtId': courtId,
      'courtName': courtName,
      'scheduledTime': scheduledTime.toIso8601String(),
      'round': round,
      'team1Player1Id': team1Player1Id,
      'team1Player1Name': team1Player1Name,
      'team1Player2Id': team1Player2Id,
      'team1Player2Name': team1Player2Name,
      'team2Player1Id': team2Player1Id,
      'team2Player1Name': team2Player1Name,
      'team2Player2Id': team2Player2Id,
      'team2Player2Name': team2Player2Name,
      'team1Score': team1Score,
      'team2Score': team2Score,
      'status': status.toString().split('.').last,
      'winningSide': winningSide?.toString().split('.').last,
    };
  }
}

/// Create Tournament Request
class CreateTournamentRequest {
  final String name;
  final String? description;
  final TournamentType type;
  final DateTime startDate;
  final DateTime endDate;
  final TournamentFormat format;
  final int maxParticipants;
  final double entryFee;

  CreateTournamentRequest({
    required this.name,
    this.description,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.format,
    this.maxParticipants = 16,
    this.entryFee = 0.0,
  });

  factory CreateTournamentRequest.fromJson(Map<String, dynamic> json) {
    return CreateTournamentRequest(
      name: json['name'] as String,
      description: json['description'] as String?,
      type: json['type'] is int
          ? TournamentType.values[json['type'] as int]
          : TournamentType.values.firstWhere(
              (e) => e.toString().split('.').last == json['type'],
            ),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      format: json['format'] is int
          ? TournamentFormat.values[json['format'] as int]
          : TournamentFormat.values.firstWhere(
              (e) => e.toString().split('.').last == json['format'],
            ),
      maxParticipants: json['maxParticipants'] as int? ?? 16,
      entryFee: (json['entryFee'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'type': type.index, // Send as integer
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'format': format.index, // Send as integer
      'maxParticipants': maxParticipants,
      'entryFee': entryFee,
    };
  }
}
