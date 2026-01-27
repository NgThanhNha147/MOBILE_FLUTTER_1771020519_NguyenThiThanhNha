# ✅ DANH SÁCH TÍNH NĂNG ĐÃ HOÀN THÀNH

**Sinh viên:** Nguyễn Thị Thanh Nhã  
**MSSV:** 1771020519  
**Ngày cập nhật:** 27/01/2026

---

## 🎯 TÓM TẮT TỔNG QUAN

Đã hoàn thành **100% yêu cầu CRITICAL** từ đề bài, bao gồm:
- ✅ Hold Slot mechanism (5 phút)
- ✅ Background Service auto-cancel
- ✅ Recurring Booking (VIP only)
- ✅ Booking flow mới: Hold → Confirm
- ✅ Real-time SignalR updates
- ✅ Tier system auto-calculation

---

## 📊 BACKEND API - HOÀN THÀNH

### 1. AUTHENTICATION & AUTHORIZATION ✅
| Endpoint | Method | Chức năng | Status |
|----------|--------|-----------|--------|
| /api/auth/register | POST | Đăng ký tài khoản | ✅ |
| /api/auth/login | POST | Đăng nhập JWT | ✅ |
| /api/auth/me | GET | Lấy thông tin user | ✅ |

**Tính năng:**
- JWT Token 30 ngày
- Role-based authorization (Admin, Treasurer, Referee, Member)
- Password hashing với Identity

---

### 2. WALLET SYSTEM ✅
| Endpoint | Method | Chức năng | Status |
|----------|--------|-----------|--------|
| /api/wallet/deposit | POST | Yêu cầu nạp tiền | ✅ |
| /api/wallet/approve/{id} | PUT | Admin duyệt nạp | ✅ |
| /api/wallet/transactions | GET | Lịch sử giao dịch | ✅ |

**Tính năng:**
- Transaction isolation (SERIALIZABLE)
- Auto wallet balance update
- Real-time SignalR notification
- Proof image URL storage

---

### 3. BOOKING SYSTEM - NÂNG CAP ⭐

#### 3.1 Core Endpoints ✅
| Endpoint | Method | Chức năng | Status |
|----------|--------|-----------|--------|
| /api/bookings/calendar | GET | Xem lịch theo khoảng thời gian | ✅ |
| /api/bookings/slots | GET | Timeline 6am-10pm theo giờ | ✅ |
| /api/bookings/my-bookings | GET | Lịch của tôi | ✅ |

#### 3.2 Hold Slot Flow (MỚI!) ✅
| Endpoint | Method | Chức năng | Status |
|----------|--------|-----------|--------|
| **POST /api/bookings/hold** | POST | **Giữ chỗ 5 phút** | ✅ |
| **POST /api/bookings/confirm/{id}** | POST | **Xác nhận và thanh toán** | ✅ |

**Luồng:**
```
User tap slot → Hold (5 min) → Countdown timer → Confirm → Payment → Confirmed
                                    ↓ timeout
                            Background Service → Auto-cancel
```

**Tính năng Hold Slot:**
- ✅ Tạo booking Status = Holding
- ✅ HoldExpiresAt = Now + 5 phút
- ✅ Không trừ tiền ví (chỉ giữ chỗ)
- ✅ Check overlap (Holding + Confirmed)
- ✅ Return expiresAt + secondsRemaining
- ✅ SignalR broadcast UpdateCalendar

**Tính năng Confirm:**
- ✅ Validate booking là Holding
- ✅ Check HoldExpiresAt chưa quá hạn
- ✅ **Check balance lại lần 2** (user có thể đã chi tiền)
- ✅ Trừ tiền ví + cộng TotalSpent
- ✅ Auto-update Tier
- ✅ Update Status = Confirmed
- ✅ Tạo WalletTransaction
- ✅ SignalR notification

#### 3.3 Cancel & Refund ✅
| Endpoint | Method | Chức năng | Status |
|----------|--------|-----------|--------|
| GET /api/bookings/cancel-preview/{id} | GET | Preview refund amount | ✅ |
| POST /api/bookings/cancel/{id} | POST | Hủy sân với refund | ✅ |

**Refund Policy:**
- >24h trước: 100% refund
- 6-24h trước: 50% refund
- <6h trước: 0% refund
- Admin override: Hủy bất cứ lúc nào

#### 3.4 Edit & Reschedule ✅
| Endpoint | Method | Chức năng | Status |
|----------|--------|-----------|--------|
| PUT /api/bookings/edit/{id} | PUT | Sửa booking (5min grace) | ✅ |
| POST /api/bookings/reschedule/{id} | POST | Đổi lịch (24h + 10% fee) | ✅ |

**Edit Booking:**
- Chỉ trong 5 phút đầu sau tạo
- Check overlap slot mới
- Tính lại giá + điều chỉnh ví

**Reschedule:**
- Đổi trước 24h trở lên
- Phí admin 10% giá trị booking
- Tính lại giá + overlap check

#### 3.5 Recurring Booking - VIP ONLY (MỚI!) ✅
| Endpoint | Method | Chức năng | Status |
|----------|--------|-----------|--------|
| **POST /api/bookings/recurring** | POST | **Đặt lịch định kỳ** | ✅ |

**Request:**
```json
{
  "courtId": 1,
  "startDate": "2026-02-01",
  "endDate": "2026-02-28",
  "startTime": "09:00",
  "endTime": "11:00",
  "recurrencePattern": "Weekly;Mon,Wed,Fri",
  "occurrencesCount": 12
}
```

**Tính năng:**
- ✅ **Check Tier = Gold hoặc Diamond**
- ✅ Parse pattern: "Weekly;Mon,Wed,Fri"
- ✅ Generate tất cả slots (loop theo ngày)
- ✅ **Check ALL slots for overlap** (atomic)
- ✅ Calculate total price
- ✅ Check wallet balance
- ✅ Tạo Parent Booking (IsRecurring = true)
- ✅ Tạo tất cả Child Bookings (ParentBookingId)
- ✅ Trừ tiền 1 lần cho tất cả slots
- ✅ Update Tier
- ✅ Single WalletTransaction
- ✅ SignalR broadcast

**Pattern Support:**
- Weekly;Mon,Wed,Fri ✅
- Weekly;Tue,Thu ✅
- Future: Monthly, Custom intervals

---

### 4. BACKGROUND SERVICES (MỚI!) ✅

#### 4.1 BookingHoldCleanupService ⭐
**File:** `PCM.API/Services/BookingHoldCleanupService.cs`

**Cấu hình:**
```csharp
// Chạy mỗi: 1 phút
// Timeout: 5 phút
```

**Chức năng:**
1. Query bookings: `Status = Holding AND CreatedDate < (Now - 5 min)`
2. Set Status = Cancelled
3. Tạo Notification cho user: "Booking đã hủy do không xác nhận"
4. SignalR notify user: `ReceiveNotification`
5. Broadcast: `UpdateCalendar`

**Đăng ký:**
```csharp
// Program.cs
builder.Services.AddHostedService<BookingHoldCleanupService>();
```

**Log output:**
```
[10:30:00] Booking Hold Cleanup Service started
[10:31:00] Found 2 expired holding bookings to cancel
[10:31:00] Cancelled expired holding booking ID: 123
[10:31:00] Successfully cancelled 2 expired holding bookings
```

✅ **Service chạy background liên tục khi API start**

---

### 5. TIER SYSTEM ✅

**Enum:**
```csharp
public enum MemberTier
{
    Standard = 0,  // Mặc định
    Silver = 1,    // >= 3M đ
    Gold = 2,      // >= 5M đ (VIP)
    Diamond = 3    // >= 8M đ (VIP)
}
```

**Auto-update logic:**
```csharp
member.TotalSpent += amount;

if (member.TotalSpent > 8000000)
    member.Tier = MemberTier.Diamond;
else if (member.TotalSpent > 5000000)
    member.Tier = MemberTier.Gold;
else if (member.TotalSpent > 3000000)
    member.Tier = MemberTier.Silver;
```

**VIP Benefits:**
- ✅ Gold & Diamond: Đặt lịch định kỳ (Recurring Booking)
- 🔜 Diamond: Ưu tiên support, giảm giá (future)

---

### 6. ERROR HANDLING ✅

#### 6.1 Standardized ApiResponse
```csharp
public class ApiResponse<T>
{
    public bool Success { get; set; }
    public string Message { get; set; }
    public T? Data { get; set; }
    public string? ErrorCode { get; set; }
    public DateTime Timestamp { get; set; }
}
```

#### 6.2 Error Codes
**Hold Slot:**
- `HOLD_FAILED` - Không thể giữ chỗ
- `HOLD_EXPIRED` - Hết 5 phút timeout
- `CONFIRM_FAILED` - Không xác nhận được
- `INVALID_STATUS` - Status không hợp lệ

**Recurring Booking:**
- `VIP_REQUIRED` - Cần Gold/Diamond tier
- `INVALID_PATTERN` - Pattern sai format
- `NO_SLOTS_GENERATED` - Không tạo được slot
- `RECURRING_FAILED` - Lỗi tạo lịch

**General:**
- `TIME_SLOT_CONFLICT` - Trùng lịch
- `INSUFFICIENT_BALANCE` - Ví không đủ
- `BOOKING_TOO_LONG` - Quá 5 giờ
- `COURT_NOT_FOUND` - Không tìm thấy sân

---

### 7. SIGNALR REAL-TIME ✅

**Hub:** `PcmHub` tại `/pcmhub`

**Methods implemented:**
```csharp
// To specific user
await Clients.User(userId).SendAsync("ReceiveNotification", message);
await Clients.User(userId).SendAsync("UpdateWallet", balance);

// Broadcast to all
await Clients.All.SendAsync("UpdateCalendar");

// To group (match viewers)
await Clients.Group($"match_{matchId}").SendAsync("UpdateMatchScore", score);
```

**Use cases:**
- ✅ Hold booking created → Broadcast UpdateCalendar
- ✅ Confirm booking → User notification + Broadcast
- ✅ Background service cancel → User notification + Broadcast
- ✅ Wallet approved → User UpdateWallet
- ✅ Cancel booking → Broadcast UpdateCalendar

---

## 📱 FLUTTER MOBILE - HOÀN THÀNH

### 1. BOOKING SERVICE ✅

**File:** `lib/core/services/booking_service.dart`

**Methods:**
```dart
// Hold Slot
Future<Map<String, dynamic>> holdBooking({
  required int courtId,
  required DateTime startTime,
  required DateTime endTime,
}) async { ... }

// Confirm Booking
Future<void> confirmBooking(int bookingId) async { ... }

// Cancel Hold
Future<void> cancelHoldBooking(int bookingId) async { ... }

// Recurring Booking
Future<Map<String, dynamic>> createRecurringBooking({
  required int courtId,
  required DateTime startDate,
  required DateTime endDate,
  required String startTime,
  required String endTime,
  required String recurrencePattern,
  required int occurrencesCount,
}) async { ... }

// Existing methods
Future<List<TimeSlot>> getDailySlots(DateTime date) async { ... }
Future<CancelPreview> getCancelPreview(int bookingId) async { ... }
Future<void> editBooking(...) async { ... }
Future<void> rescheduleBooking(...) async { ... }
```

**Error Handling:**
- ✅ Error code translation (Vietnamese)
- ✅ Retry logic (only 500/503)
- ✅ Never retry 409 conflicts

---

### 2. BOOKING PROVIDER ✅

**File:** `lib/providers/booking_provider.dart`

**State Management (Riverpod):**
```dart
class BookingNotifier extends StateNotifier<BookingState> {
  // Hold Slot
  Future<Map<String, dynamic>> holdBooking(...) async { ... }
  
  // Confirm
  Future<void> confirmBooking(int bookingId) async { ... }
  
  // Cancel Hold
  Future<void> cancelHoldBooking(int bookingId) async { ... }
  
  // SignalR listener
  void _setupSignalRListeners() {
    _signalRService.onCalendarUpdate.listen((_) {
      // Auto reload calendar
      loadCalendar(...);
    });
  }
}
```

---

### 3. BOOKING UI - NÂNG CAP ⭐

#### 3.1 CourtTimeline Widget ✅
**File:** `lib/features/bookings/widgets/court_timeline.dart`

**Tính năng:**
- ✅ Horizontal scroll timeline
- ✅ Display 6am-10pm slots
- ✅ Color-coded:
  - Green: Available (trống)
  - Blue: My booking (của tôi)
  - Red: Booked by others (đã đặt)
  - **Orange: Holding** (đang giữ chỗ) ⭐
- ✅ Icon indicators per status
- ✅ Tap handler

**Colors:**
```dart
if (slot.status == 'Holding') {
  if (isMyHolding) {
    color = Colors.orange;  // My hold
    icon = Icons.timer;
  } else {
    color = Colors.orange.shade300;  // Other's hold
    icon = Icons.lock_clock;
  }
}
```

#### 3.2 HoldConfirmDialog Widget (MỚI!) ⭐
**File:** `lib/features/bookings/widgets/hold_confirm_dialog.dart`

**Tính năng:**
- ✅ **Countdown timer: 5:00 → 4:59 → ... → 0:00**
- ✅ Timer color: Green (>2min) → Red (<2min)
- ✅ Display booking info (court, date, time)
- ✅ Display price breakdown
- ✅ Display balance before/after
- ✅ Auto-close when timeout
- ✅ "Xác nhận" button → confirmBooking()
- ✅ "Hủy giữ chỗ" button → cancelHoldBooking()

**State management:**
```dart
Timer _timer;
int _secondsRemaining;

void _startCountdown() {
  _timer = Timer.periodic(Duration(seconds: 1), (timer) {
    setState(() {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
      } else {
        _handleExpired();  // Auto close dialog
      }
    });
  });
}
```

#### 3.3 BookingsScreen - Updated Flow ✅
**File:** `lib/features/bookings/bookings_screen.dart`

**Luồng mới:**
```dart
void _showQuickBookingDialog(...) async {
  // Show loading
  showDialog(context, "Đang giữ chỗ...");
  
  // Step 1: Hold booking
  final holdData = await bookingProvider.holdBooking(...);
  
  // Close loading
  Navigator.pop(context);
  
  // Step 2: Show confirmation dialog
  showDialog(
    context: context,
    barrierDismissible: false,  // Force user to choose
    builder: (context) => HoldConfirmDialog(
      bookingId: holdData['bookingId'],
      expiresAt: holdData['expiresAt'],
      totalPrice: holdData['totalPrice'],
      ...
    ),
  );
}
```

**Timeline integration:**
```dart
FutureBuilder<List<TimeSlot>>(
  future: bookingProvider.getDailySlots(selectedDate),
  builder: (context, snapshot) {
    return CourtTimeline(
      slots: snapshot.data,
      onSlotTap: (slot) {
        if (!slot.isBooked) {
          _showQuickBookingDialog(...);  // Hold slot
        } else if (slot.memberId == currentUserId) {
          _showMyBookingOptions(slot);   // Cancel/Edit
        }
      },
    );
  },
)
```

---

### 4. MODELS ✅

#### 4.1 BookingStatus Enum (Updated)
**File:** `lib/models/enums.dart`

```dart
enum BookingStatus {
  holding(0),        // MỚI
  pendingPayment(1),
  confirmed(2),
  cancelled(3),
  completed(4);
  
  final int value;
  const BookingStatus(this.value);
}

extension BookingStatusExtension on BookingStatus {
  String get displayName {
    switch (this) {
      case BookingStatus.holding:
        return 'Đang giữ chỗ';  // MỚI
      case BookingStatus.confirmed:
        return 'Đã xác nhận';
      // ...
    }
  }
}
```

**⚠️ CRITICAL:** Index phải match backend (0=Holding, 1=PendingPayment, ...)

#### 4.2 TimeSlot Model ✅
```dart
class TimeSlot {
  final int courtId;
  final String courtName;
  final int hour;
  final String time;
  final bool isBooked;
  final int? bookingId;
  final int? memberId;
  final String? memberName;
  final String? status;  // "Holding", "Confirmed", ...
}
```

---

## 🎯 YÊU CẦU ĐÃ HOÀN THÀNH

### ✅ PHẦN 3: YÊU CẦU API & MOBILE APP

#### Backend API:
- [x] Auth & Members endpoints
- [x] Wallet system (Deposit, Approve, Transactions)
- [x] Courts & Bookings endpoints
- [x] **Hold Slot endpoint** ⭐
- [x] **Confirm Booking endpoint** ⭐
- [x] **Recurring Booking endpoint** ⭐
- [x] Cancel with refund policy
- [x] Edit & Reschedule
- [x] SignalR Real-time

#### Mobile App:
- [x] API Client (Dio + Interceptor)
- [x] Auth (JWT token management)
- [x] State Management (Riverpod)
- [x] Booking Calendar
- [x] **Timeline UI (6am-10pm slots)** ⭐
- [x] **Hold Confirmation Dialog** ⭐
- [x] **Countdown timer** ⭐
- [x] Cancel preview & refund
- [x] SignalR connection

---

### ✅ PHẦN 4: YÊU CẦU KỸ THUẬT SYSTEM

- [x] **Background Services:**
  - [x] **BookingHoldCleanupService - Auto-cancel unpaid bookings** ⭐
  - [x] Chạy mỗi 1 phút
  - [x] Cancel bookings Holding > 5 phút
  
- [x] **SignalR Implementation:**
  - [x] User-specific notifications
  - [x] Global calendar updates
  - [x] Real-time booking status
  
- [x] **Data Seeding:**
  - [x] 1 Admin, 1 Treasurer, 1 Referee
  - [x] 20 Members với Rank và Tier
  - [x] Wallet balance 2M-10M đ
  - [x] 2 Tournaments (Finished + Registering)

---

## 📈 TIẾN ĐỘ HOÀN THÀNH

| Phần | Mô tả | Tiến độ | Status |
|------|-------|---------|--------|
| **Backend Core** | Auth, Wallet, CRUD | 100% | ✅ |
| **Hold Slot** | 5-min temporary hold | 100% | ✅ |
| **Background Service** | Auto-cancel expired | 100% | ✅ |
| **Recurring Booking** | VIP periodic booking | 100% | ✅ |
| **Booking Flow** | Hold → Confirm | 100% | ✅ |
| **Cancel/Refund** | Preview + Policy | 100% | ✅ |
| **Edit/Reschedule** | Grace + Fee | 100% | ✅ |
| **Flutter UI** | Timeline + Countdown | 100% | ✅ |
| **SignalR** | Real-time updates | 100% | ✅ |
| **Error Handling** | Standardized codes | 100% | ✅ |
| **Tier System** | Auto-update VIP | 100% | ✅ |

**TỔNG THỂ: 100% YÊU CẦU CRITICAL** ✅

---

## 🚧 TÍNH NĂNG OPTIONAL (Chưa làm)

### Bonus Features:
- [ ] Payment Gateway (VNPay/VietQR)
- [ ] Export Reports (Excel/PDF)
- [ ] Chat System (SignalR)
- [ ] Push Notifications (FCM)
- [ ] Biometric Login
- [ ] Tier badge UI display
- [ ] Pre-check balance warning UI

### Tournaments (Cơ bản có, chưa đầy đủ):
- [x] Join tournament → payment
- [ ] Auto-scheduler (bracket generation)
- [ ] Match result update
- [ ] Prize distribution

---

## 🏆 HIGHLIGHTS

### Backend Achievements:
1. **Hold Slot Mechanism** - Giải quyết race condition khi đặt sân
2. **Background Service** - Auto-cleanup expired holds mỗi 1 phút
3. **Recurring Booking** - VIP feature với pattern parsing phức tạp
4. **Transaction Safety** - SERIALIZABLE isolation level
5. **Double Balance Check** - Hold + Confirm 2 lần
6. **Standardized Errors** - Error codes + Vietnamese translation

### Frontend Achievements:
1. **Timeline UI** - Horizontal scroll 6am-10pm visual
2. **Countdown Timer** - Real-time 5:00 → 0:00 với auto-close
3. **Color-coded Status** - 4 colors (Green, Blue, Red, Orange)
4. **Async State Management** - Riverpod + SignalR integration
5. **Error Translation** - Vietnamese user-friendly messages
6. **Optimistic UI** - Loading states + retry logic

---

## 📝 FILE STRUCTURE

### Backend:
```
PCM.API/
├── Controllers/
│   ├── AuthController.cs
│   ├── BookingsController.cs ⭐ (Updated with Hold/Confirm/Recurring)
│   ├── WalletController.cs
│   └── ...
├── Services/
│   ├── BookingHoldCleanupService.cs ⭐ (NEW)
│   └── TokenService.cs
├── Models/
│   ├── Booking.cs (+ HoldExpiresAt, IsRecurring, RecurrenceRule)
│   ├── Enums.cs (BookingStatus.Holding added)
│   └── ApiResponse.cs ⭐ (NEW)
├── DTOs/
│   └── BookingDtos.cs ⭐ (+ Hold, Confirm, Recurring DTOs)
├── Exceptions/
│   └── BusinessException.cs ⭐ (NEW)
└── Hubs/
    └── PcmHub.cs
```

### Frontend:
```
PCM_Mobile/
├── lib/
│   ├── core/
│   │   └── services/
│   │       └── booking_service.dart ⭐ (+ Hold/Confirm/Recurring methods)
│   ├── models/
│   │   ├── enums.dart ⭐ (BookingStatus.holding added)
│   │   └── time_slot.dart
│   ├── providers/
│   │   └── booking_provider.dart ⭐ (+ Hold/Confirm methods)
│   └── features/
│       └── bookings/
│           ├── bookings_screen.dart ⭐ (Updated flow)
│           └── widgets/
│               ├── court_timeline.dart ⭐ (Orange holding color)
│               └── hold_confirm_dialog.dart ⭐ (NEW)
```

---

## ✅ READY FOR DEMO

### Backend Ready:
```bash
cd PCM_Backend/PCM.API
dotnet run
# Listening on http://localhost:5283
# Swagger: http://localhost:5283/swagger
```

### Frontend Ready:
```bash
cd PCM_Mobile
flutter run
# Connect to http://10.0.2.2:5283 (Android Emulator)
```

### Demo Flow:
1. Login as member1@pcm.com (Gold tier, 5M balance)
2. Tap empty slot → Hold (orange color appears)
3. See countdown timer: 5:00 → 4:59 → ...
4. Click "Xác nhận" → Payment success
5. Balance decreased, tier updated
6. Background service auto-cancel expired holds every 1 min
7. Try Recurring Booking → VIP only message

---

**Kết luận:** Đã hoàn thành 100% yêu cầu CRITICAL từ đề bài! 🎉

**Tạo bởi:** Nguyễn Thị Thanh Nhã - MSSV 1771020519  
**Ngày:** 27/01/2026
