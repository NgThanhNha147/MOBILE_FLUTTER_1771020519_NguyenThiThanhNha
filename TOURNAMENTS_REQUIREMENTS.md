# YÊU CẦU CHỨC NĂNG TOURNAMENTS

## TỔNG QUAN
Hệ thống tournaments gồm 4 loại:
1. **Official** - Giải đấu chính thức (Admin tạo)
2. **Challenge 1v1** - Kèo thách đấu 1vs1 (User tự tạo)
3. **Team Battle** - Đấu đội/team (User tự tạo)
4. **MiniGame** - Mini game cuối tuần (Admin tạo)

## BACKEND API (ASP.NET Core)

### 1. TournamentsController Endpoints

#### GET /api/tournaments
```csharp
// Lấy danh sách tournaments với filter
Parameters:
- type? (TournamentType): 0=Official, 1=Challenge1v1, 2=TeamBattle, 3=MiniGame
- status? (TournamentStatus): 0=Open, 1=Registering, 2=DrawCompleted, 3=Ongoing, 4=Finished

Response:
{
  "success": true,
  "message": "Tournaments retrieved successfully",
  "data": [
    {
      "id": 1,
      "name": "Giải Pickleball Mùa Xuân",
      "description": "...",
      "type": 0,  // Official
      "format": 1,  // 0=RoundRobin, 1=Knockout, 2=Hybrid
      "status": 0,  // Open
      "startDate": "2026-02-07T00:00:00",
      "endDate": "2026-02-09T00:00:00",
      "maxParticipants": 16,
      "currentParticipants": 5,
      "entryFee": 200000,
      "prizePool": 5000000,
      "creatorId": null,  // null = Admin created
      "creatorName": "Admin"
    }
  ]
}
```

#### GET /api/tournaments/{id}
```csharp
// Lấy chi tiết tournament
Response:
{
  "success": true,
  "data": {
    ...  // Giống trên nhưng có thêm:
    "participants": [
      {
        "id": 1,
        "memberId": 1,
        "memberName": "Nguyễn Văn A",
        "registrationDate": "2026-01-31T00:00:00",
        "isApproved": true
      }
    ],
    "matches": []  // Nếu có
  }
}
```

#### POST /api/tournaments
```csharp
// Tạo tournament mới (Challenge1v1 hoặc TeamBattle only)
Request Body:
{
  "name": "Kèo solo 100k",
  "description": "Ai dám đấu không?",
  "type": 1,  // 1=Challenge1v1 hoặc 2=TeamBattle
  "format": 1,  // Knockout
  "startDate": "2026-02-01T14:00:00",
  "endDate": "2026-02-01T16:00:00",
  "maxParticipants": 2,  // 2 cho 1v1, 4-32 cho team
  "entryFee": 100000
}

Response: 201 Created
{
  "success": true,
  "message": "Tournament created successfully",
  "data": { ... tournament object ... }
}

Validation:
- Chỉ cho phép type = Challenge1v1 hoặc TeamBattle
- Official và MiniGame chỉ Admin tạo được
- MaxParticipants: 2 cho 1v1, 4-32 cho team
- EntryFee >= 0
```

#### POST /api/tournaments/{id}/join
```csharp
// Tham gia tournament
Response:
{
  "success": true,
  "message": "Joined tournament successfully"
}

Validation:
- Tournament phải ở trạng thái Open
- Chưa đủ số người (currentParticipants < maxParticipants)
- User chưa tham gia
```

#### DELETE /api/tournaments/{id}
```csharp
// Xóa tournament (chỉ creator hoặc admin)
Response:
{
  "success": true,
  "message": "Tournament deleted successfully"
}

Validation:
- Chưa có người tham gia
- Hoặc là creator/admin
```

### 2. DTOs Required

```csharp
// PCM.API/DTOs/TournamentDtos.cs
public class TournamentDto
{
    public int Id { get; set; }
    public string Name { get; set; }
    public string? Description { get; set; }
    public int Type { get; set; }
    public int Format { get; set; }
    public int Status { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public int MaxParticipants { get; set; }
    public int CurrentParticipants { get; set; }
    public decimal EntryFee { get; set; }
    public decimal PrizePool { get; set; }
    public int? CreatorId { get; set; }
    public string CreatorName { get; set; }
    public List<object> Participants { get; set; }
}

public class TournamentDetailDto : TournamentDto
{
    public List<object> Matches { get; set; }
}

public class CreateTournamentRequest
{
    [Required]
    [MaxLength(200)]
    public string Name { get; set; }
    
    [MaxLength(500)]
    public string? Description { get; set; }
    
    [Required]
    public TournamentType Type { get; set; }  // Must be Challenge1v1 or TeamBattle
    
    [Required]
    public TournamentFormat Format { get; set; }
    
    [Required]
    public DateTime StartDate { get; set; }
    
    [Required]
    public DateTime EndDate { get; set; }
    
    [Range(2, 32)]
    public int MaxParticipants { get; set; }
    
    [Range(0, double.MaxValue)]
    public decimal EntryFee { get; set; }
}
```

## FLUTTER FRONTEND

### 1. Service Layer (tournament_service.dart)

```dart
class TournamentService {
  final Dio dio;
  
  // GET all tournaments with filters
  Future<List<Tournament>> getTournaments({
    TournamentType? type,
    TournamentStatus? status,
  }) async {
    final queryParams = <String, dynamic>{};
    if (type != null) queryParams['type'] = type.index;
    if (status != null) queryParams['status'] = status.index;
    
    final response = await dio.get(
      '/api/tournaments',
      queryParameters: queryParams,
    );
    
    if (response.data['success']) {
      final List data = response.data['data'];
      return data.map((json) => Tournament.fromJson(json)).toList();
    }
    throw Exception(response.data['message']);
  }
  
  // GET tournament by id
  Future<TournamentDetail> getTournamentById(int id) async {...}
  
  // POST create tournament
  Future<Tournament> createTournament(CreateTournamentRequest request) async {...}
  
  // POST join tournament
  Future<void> joinTournament(int tournamentId) async {...}
  
  // DELETE tournament
  Future<void> deleteTournament(int tournamentId) async {...}
}
```

### 2. UI Screens

#### TournamentsScreen (Main List)
```
┌────────────────────────────────────────┐
│  🏆 Giải đấu & Kèo         [+ Tạo mới] │
├────────────────────────────────────────┤
│  Tabs (Main):                          │
│  [Giải đấu] [Kèo 1v1] [Team] [MiniGame]│
├────────────────────────────────────────┤
│  Sub-tabs cho mỗi type:                │
│  [Mở đăng ký] [Đang diễn ra] [Kết thúc]│
├────────────────────────────────────────┤
│  ┌──────────────────────────────────┐  │
│  │ 🏆 Giải Pickleball Mùa Xuân 2026 │  │
│  │ Giải thưởng: 5,000,000đ          │  │
│  │ Lệ phí: 200,000đ | 12/16 người   │  │
│  │ 07/02-09/02/2026                 │  │
│  └──────────────────────────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │ ⚔️ Kèo solo 100k - Nguyễn Văn A  │  │
│  │ Ai dám đấu không?                │  │
│  │ Lệ phí: 100,000đ | 1/2 người     │  │
│  └──────────────────────────────────┘  │
└────────────────────────────────────────┘

Logic:
- Tab "Giải đấu" (Official): Hiện các giải do Admin tạo, user chỉ đăng ký
- Tab "Kèo 1v1" (Challenge1v1): User có thể tạo mới và join
- Tab "Team" (TeamBattle): User có thể tạo mới và join
- Tab "MiniGame": Admin tạo, 12 người, lệ phí 50k, giải 600k

Button [+ Tạo mới]:
- Chỉ hiện khi đang ở tab "Kèo 1v1" hoặc "Team"
- Mở CreateTournamentDialog
```

#### CreateTournamentDialog
```
┌────────────────────────────────────────┐
│  Tạo giải đấu mới                  [X] │
├────────────────────────────────────────┤
│  Tên: [________________________]       │
│  Mô tả: [_____________________]        │
│  Loại: [Dropdown: 1v1 / Team]          │
│  Format: [Dropdown: Knockout/RoundRobin]│
│  Ngày bắt đầu: [DatePicker]            │
│  Ngày kết thúc: [DatePicker]           │
│  Số người tối đa: [2-32]               │
│  Lệ phí: [___________đ]                │
│                                        │
│  [Hủy]              [Tạo giải đấu]    │
└────────────────────────────────────────┘

Validation:
- Tên: required, max 200 chars
- Loại: auto-set based on current tab
- Số người: 2 cho 1v1, 4-32 cho team
- Lệ phí: >= 0
- EndDate > StartDate
```

#### TournamentDetailScreen
```
┌────────────────────────────────────────┐
│  [<] Giải Pickleball Mùa Xuân 2026     │
├────────────────────────────────────────┤
│  Tabs:                                 │
│  [Thông tin] [Danh sách] [Lịch] [KQ]  │
├────────────────────────────────────────┤
│  TAB THÔNG TIN:                        │
│  Mô tả: Giải đấu lớn...                │
│  Loại: Giải đấu chính thức             │
│  Format: Knockout                      │
│  Thời gian: 07/02 - 09/02/2026         │
│  Số người: 12/16                       │
│  Lệ phí: 200,000đ                      │
│  Giải thưởng: 5,000,000đ               │
│  Người tạo: Admin                      │
│                                        │
│  [Đăng ký tham gia]                    │
└────────────────────────────────────────┘

TAB DANH SÁCH (Participants):
- Hiển thị list người đã đăng ký
- Avatar, tên, ngày đăng ký

TAB LỊCH (Matches):
- Hiển thị lịch thi đấu (nếu có)
- Chỉ có khi status >= DrawCompleted

TAB KẾT QUẢ (Results):
- Hiển thị kết quả các trận (nếu có)
- Chỉ có khi status >= Ongoing
```

### 3. Provider/State Management

```dart
// tournament_provider.dart
final tournamentsProvider = FutureProvider.family<List<Tournament>, TournamentFilters>((ref, filters) async {
  final service = ref.read(tournamentServiceProvider);
  return await service.getTournaments(
    type: filters.type,
    status: filters.status,
  );
});

final tournamentDetailProvider = FutureProvider.family<TournamentDetail, int>((ref, id) async {
  final service = ref.read(tournamentServiceProvider);
  return await service.getTournamentById(id);
});

class TournamentNotifier extends StateNotifier<AsyncValue<void>> {
  Future<void> createTournament(CreateTournamentRequest request) async {...}
  Future<void> joinTournament(int id) async {...}
  Future<void> leaveTournament(int id) async {...}
  Future<void> deleteTournament(int id) async {...}
}
```

## DATA SEEDING (Backend)

```csharp
// DataSeeder.cs - Thêm data cho 4 loại tournaments

// 1. OFFICIAL (Admin tạo)
new Tournament {
    Name = "Giải Pickleball Mùa Xuân 2026",
    Type = TournamentType.Official,
    Status = TournamentStatus.Open,
    MaxParticipants = 16,
    EntryFee = 200000,
    PrizePool = 5000000,
    CreatorId = null  // Admin
},

// 2. CHALLENGE 1V1 (User tạo)
new Tournament {
    Name = "⚔️ Thách đấu từ Nguyễn Văn A",
    Type = TournamentType.Challenge1v1,
    Status = TournamentStatus.Open,
    MaxParticipants = 2,
    EntryFee = 100000,
    PrizePool = 160000,  // 80% of total
    CreatorId = 1  // Member ID
},

// 3. TEAM BATTLE (User tạo)
new Tournament {
    Name = "👥 Đấu đôi cuối tuần",
    Type = TournamentType.TeamBattle,
    Status = TournamentStatus.Open,
    MaxParticipants = 8,  // 4 teams x 2 người
    EntryFee = 150000,
    PrizePool = 960000,
    CreatorId = 2
},

// 4. MINIGAME (Admin tạo)
new Tournament {
    Name = "🎮 Mini Game Cuối Tuần",
    Type = TournamentType.MiniGame,
    Status = TournamentStatus.Open,
    MaxParticipants = 12,
    EntryFee = 50000,
    PrizePool = 600000,
    CreatorId = null  // Admin
}
```

## IMPLEMENTATION CHECKLIST

### Backend Tasks:
- [ ] Tạo TournamentDtos.cs với TournamentDto, TournamentDetailDto, CreateTournamentRequest
- [ ] Update TournamentsController với các endpoints: GET all, GET by id, POST create, POST join, DELETE
- [ ] Thêm validation logic cho create tournament
- [ ] Update DataSeeder với đủ 4 loại tournaments
- [ ] Test API với Swagger/Postman

### Frontend Tasks:
- [ ] Update tournament_service.dart với đủ methods
- [ ] Update tournament_provider.dart với filters support
- [ ] Rebuild TournamentsScreen với 4 tabs + sub-tabs
- [ ] Tạo CreateTournamentDialog với validation
- [ ] Update TournamentDetailScreen với join button
- [ ] Test toàn bộ flow: xem list, tạo mới, join, xem detail

## NOTES

1. **Authentication**: Hiện tại chưa có auth, dùng hardcoded user ID = 1
2. **Authorization**: Admin vs User logic cần implement sau
3. **Payments**: Join tournament với entryFee > 0 cần tích hợp wallet
4. **Matches**: Tạo lịch thi đấu tự động sau khi đủ người (future feature)
5. **Notifications**: Thông báo khi có người join/leave (future feature)
