# PCM Backend - Hướng dẫn chi tiết

## 📋 THÔNG TIN DỰ ÁN

**Sinh viên:** Nguyễn Thị Thanh Nhã  
**MSSV:** 1771020519  
**3 số cuối MSSV:** **519** (được sử dụng làm prefix cho tất cả bảng)

---

## 🎯 TỔNG QUAN HỆ THỐNG

PCM Backend là ASP.NET Core Web API phục vụ cho ứng dụng mobile quản lý CLB Pickleball "Vợt Thủ Phố Núi". Hệ thống tập trung vào **Ví điện tử**, **Đặt sân thông minh**, **Giải đấu** và **Real-time notifications**.

### Công nghệ sử dụng:
- ✅ .NET 9.0
- ✅ ASP.NET Core Web API
- ✅ Entity Framework Core 9.0
- ✅ MySQL/MariaDB (Pomelo provider)
- ✅ ASP.NET Core Identity (Authentication)
- ✅ JWT Bearer Token (Authorization)
- ✅ SignalR (Real-time communication)
- ✅ Swagger/OpenAPI (API Documentation)

---

## 📊 CẤU TRÚC DATABASE

### Tất cả bảng có prefix **519_**

| Bảng | Mô tả | Trường quan trọng |
|------|-------|-------------------|
| **519_Members** | Thông tin thành viên | UserId (FK→AspNetUsers), WalletBalance, Tier, TotalSpent |
| **519_WalletTransactions** | Lịch sử giao dịch ví | MemberId, Amount, Type, Status, ProofImageUrl |
| **519_Courts** | Sân đấu | Name, PricePerHour, IsActive |
| **519_Bookings** | Đặt sân | CourtId, MemberId, StartTime, EndTime, TotalPrice, Status |
| **519_Tournaments** | Giải đấu | Name, EntryFee, PrizePool, Format, Status |
| **519_TournamentParticipants** | Người tham gia giải | TournamentId, MemberId, PaymentStatus |
| **519_Matches** | Trận đấu | TournamentId, Team1/2 Players, Score, WinningSide |
| **519_Notifications** | Thông báo | ReceiverId, Message, Type, IsRead |
| **519_News** | Tin tức | Title, Content, IsPinned |

### Bảng Identity (ASP.NET Core Identity):
- `AspNetUsers` - Tài khoản đăng nhập
- `AspNetRoles` - Vai trò (Admin, Treasurer, Referee, Member)
- `AspNetUserRoles` - Liên kết User-Role

---

## 🔐 AUTHENTICATION & AUTHORIZATION

### 1. Đăng ký (Register)
**Endpoint:** `POST /api/auth/register`

```json
{
  "email": "user@example.com",
  "password": "Password@123",
  "fullName": "Nguyễn Văn A"
}
```

**Luồng xử lý:**
1. Kiểm tra email đã tồn tại chưa
2. Tạo ApplicationUser (AspNetUsers)
3. Hash password và lưu
4. Gán role mặc định "Member"
5. Tạo Member profile (519_Members) với UserId
6. Return success message

### 2. Đăng nhập (Login)
**Endpoint:** `POST /api/auth/login`

```json
{
  "email": "admin@pcm.com",
  "password": "Admin@123"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "email": "admin@pcm.com",
  "fullName": "Nguyễn Thị Thanh Nhã",
  "role": "Admin",
  "memberId": 1,
  "walletBalance": 10000000
}
```

**Luồng xử lý:**
1. Tìm user theo email
2. Verify password
3. Lấy roles của user
4. Tạo JWT Token (expires 30 ngày)
5. Lấy thông tin Member (số dư ví)
6. Return token + user info

### 3. JWT Token Structure
**Claims trong token:**
- `NameIdentifier` - UserId (Guid)
- `Email` - Email
- `Name` - FullName
- `Role` - Admin/Treasurer/Referee/Member
- `Jti` - Token ID

**Sử dụng:**
```
Authorization: Bearer {token}
```

---

## 💰 HỆ THỐNG VÍ ĐIỆN TỬ (WALLET)

### 1. Yêu cầu nạp tiền
**Endpoint:** `POST /api/wallet/deposit`

```json
{
  "amount": 500000,
  "proofImageUrl": "https://example.com/proof.jpg"
}
```

**Luồng:**
1. Lấy Member từ JWT token
2. Tạo WalletTransaction (Status: Pending)
3. Type: Deposit
4. Chờ Admin/Treasurer approve

### 2. Admin duyệt nạp tiền
**Endpoint:** `PUT /api/wallet/approve/{transactionId}`  
**Role required:** Admin hoặc Treasurer

```json
{
  "approved": true
}
```

**Luồng (nếu approved = true):**
1. Bắt đầu Database Transaction
2. Cập nhật Status = Completed
3. Cộng tiền vào WalletBalance
4. Tạo Notification cho user
5. Gửi SignalR notification real-time
6. Commit transaction

**Nếu approved = false:**
- Status = Rejected
- Không cộng tiền
- Tạo notification từ chối

### 3. Lịch sử giao dịch
**Endpoint:** `GET /api/wallet/transactions?page=1&pageSize=20`

**Response:**
```json
{
  "total": 10,
  "page": 1,
  "pageSize": 20,
  "data": [
    {
      "id": 1,
      "amount": 500000,
      "type": "Deposit",
      "status": "Completed",
      "description": "Nạp tiền 500,000đ vào ví",
      "createdDate": "2026-01-27T10:30:00"
    }
  ]
}
```

### 4. Transaction Types
- **Deposit** - Nạp tiền
- **Withdraw** - Rút tiền (chưa implement)
- **Payment** - Thanh toán (đặt sân, tham gia giải)
- **Refund** - Hoàn tiền (hủy sân)
- **Reward** - Thưởng giải

---

## 🏟️ HỆ THỐNG ĐẶT SÂN (BOOKING) - CẬP NHẬT MỚI

### Booking Status Flow:
```
Holding (5 phút) → Confirmed → Completed
     ↓
  Cancelled
```

### Booking Statuses:
- **Holding** (0) - Đang giữ chỗ tạm thời (5 phút)
- **PendingPayment** (1) - Chờ thanh toán (legacy, không dùng nữa)
- **Confirmed** (2) - Đã xác nhận và thanh toán
- **Cancelled** (3) - Đã hủy
- **Completed** (4) - Đã hoàn thành

### 1. Xem lịch sân
**Endpoint:** `GET /api/bookings/calendar?from=2026-01-27&to=2026-02-27`

**Response:** Danh sách bookings trong khoảng thời gian (bao gồm cả Holding slots)

### 2. Xem timeline theo giờ
**Endpoint:** `GET /api/bookings/slots?date=2026-01-28`

**Response:** Timeline 6am-10pm cho tất cả sân
```json
[
  {
    "courtId": 1,
    "courtName": "Sân 1",
    "hour": 9,
    "time": "09:00",
    "isBooked": true,
    "bookingId": 5,
    "memberId": 3,
    "memberName": "Nguyễn Văn A",
    "status": "Holding"
  }
]
```

### 3. HOLD SLOT - Giữ chỗ tạm thời (MỚI!)
**Endpoint:** `POST /api/bookings/hold`

```json
{
  "courtId": 1,
  "startTime": "2026-01-28T09:00:00",
  "endTime": "2026-01-28T11:00:00"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Giữ chỗ thành công! Vui lòng xác nhận trong 5 phút.",
  "data": {
    "bookingId": 123,
    "expiresAt": "2026-01-28T09:05:00",
    "totalPrice": 200000,
    "secondsRemaining": 300
  }
}
```

**Luồng xử lý:**
1. Validate input (time, court)
2. Pre-check wallet balance
3. Check overlap (bao gồm cả Holding và Confirmed)
4. Tạo Booking với Status = **Holding**
5. Set HoldExpiresAt = DateTime.Now + 5 phút
6. **KHÔNG trừ tiền ví** (chỉ giữ chỗ)
7. Broadcast SignalR "UpdateCalendar"
8. Return bookingId + expiresAt

**Đặc điểm:**
- Slot bị khóa trong 5 phút cho người khác
- Người giữ chỗ có 5 phút để xác nhận
- Nếu hết 5 phút không confirm → Auto-cancel bởi Background Service

### 4. XÁC NHẬN BOOKING - Thanh toán (MỚI!)
**Endpoint:** `POST /api/bookings/confirm/{bookingId}`

**Luồng xử lý:**
1. Kiểm tra booking tồn tại và thuộc user
2. Kiểm tra Status = Holding
3. Kiểm tra HoldExpiresAt chưa quá hạn
4. **Check lại wallet balance** (user có thể đã chi tiền trong 5 phút giữ chỗ)
5. **Trừ tiền ví:**
   ```csharp
   member.WalletBalance -= booking.TotalPrice;
   member.TotalSpent += booking.TotalPrice;
   ```
6. **Update Tier:**
   ```csharp
   if (member.TotalSpent > 8000000) member.Tier = Diamond;
   else if (member.TotalSpent > 5000000) member.Tier = Gold;
   else if (member.TotalSpent > 3000000) member.Tier = Silver;
   ```
7. Update Status = **Confirmed**
8. Clear HoldExpiresAt
9. Tạo WalletTransaction (Type: Payment)
10. Tạo Notification
11. Broadcast SignalR

**Error cases:**
- `HOLD_EXPIRED` - Hết 5 phút → Auto cancel
- `INSUFFICIENT_BALANCE` - Ví không đủ tiền → Cancel + thông báo
- `INVALID_STATUS` - Không phải Holding status

### 5. Đặt sân trực tiếp (Legacy - Deprecated)
**Endpoint:** `POST /api/bookings`

**⚠️ Deprecated:** Sử dụng flow Hold → Confirm thay thế

### 6. Hủy giữ chỗ
**Endpoint:** `POST /api/bookings/cancel/{id}`

**Áp dụng cho:**
- Hủy Holding booking (miễn phí, không hoàn tiền vì chưa trả)
- Hủy Confirmed booking (có refund policy)

**Refund Policy (cho Confirmed):**
- Hủy trước **>24h**: Hoàn 100%
- Hủy trong **6-24h**: Hoàn 50%
- Hủy trong **<6h**: Không hoàn tiền
- **Admin override:** Có thể hủy bất cứ lúc nào

### 7. Preview refund trước khi hủy
**Endpoint:** `GET /api/bookings/cancel-preview/{id}`

**Response:**
```json
{
  "canCancel": true,
  "refundPercentage": 100,
  "refundAmount": 200000,
  "message": "Bạn sẽ được hoàn 100% (200,000đ)",
  "hoursUntilStart": 48.5
}
```

### 8. Sửa booking (5 phút grace period)
**Endpoint:** `PUT /api/bookings/edit/{id}`

```json
{
  "newStartTime": "2026-01-28T10:00:00",
  "newEndTime": "2026-01-28T12:00:00"
}
```

**Điều kiện:**
- Chỉ trong **5 phút** sau khi tạo booking
- Check overlap slot mới
- Tính lại giá, điều chỉnh ví (trừ thêm hoặc hoàn lại)

### 9. Đổi lịch booking (reschedule)
**Endpoint:** `POST /api/bookings/reschedule/{id}`

```json
{
  "newStartTime": "2026-01-30T09:00:00",
  "newEndTime": "2026-01-30T11:00:00"
}
```

**Điều kiện:**
- Đổi trước **24h** trở lên
- Phí admin: **10%** giá trị booking
- Check overlap slot mới
- Tính lại giá + phí admin

### 10. ĐẶT LỊCH ĐỊNH KỲ - VIP ONLY (MỚI!)
**Endpoint:** `POST /api/bookings/recurring`

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

**Yêu cầu:**
- Member Tier phải là **Gold** hoặc **Diamond**
- Pattern format: `"Weekly;Mon,Wed,Fri"` hoặc `"Weekly;Tue,Thu"`

**Luồng xử lý:**
1. **Check VIP Tier:**
   ```csharp
   if (member.Tier != Gold && member.Tier != Diamond)
       return 403 "VIP_REQUIRED";
   ```

2. **Parse Recurrence Pattern:**
   ```csharp
   // "Weekly;Mon,Wed,Fri" → [Monday, Wednesday, Friday]
   var parts = pattern.Split(';');
   var frequency = parts[0]; // "Weekly"
   var days = parts[1].Split(','); // ["Mon", "Wed", "Fri"]
   ```

3. **Generate All Slots:**
   ```csharp
   var bookingSlots = new List<(DateTime start, DateTime end)>();
   var currentDate = startDate;
   
   while (currentDate <= endDate && slots.Count < occurrencesCount) {
       if (targetDays.Contains(currentDate.DayOfWeek)) {
           bookingSlots.Add((startTime, endTime));
       }
       currentDate = currentDate.AddDays(1);
   }
   ```

4. **Calculate Total Price:**
   ```csharp
   var hoursPerSlot = (endTime - startTime).TotalHours;
   var pricePerSlot = hoursPerSlot * court.PricePerHour;
   var totalPrice = pricePerSlot * bookingSlots.Count;
   ```

5. **Check Wallet Balance:**
   ```csharp
   if (member.WalletBalance < totalPrice)
       return 400 "INSUFFICIENT_BALANCE";
   ```

6. **Check ALL Slots for Overlap:**
   ```csharp
   foreach (var (start, end) in bookingSlots) {
       var hasOverlap = await CheckOverlap(courtId, start, end);
       if (hasOverlap) {
           return 409 "TIME_SLOT_CONFLICT";
       }
   }
   ```

7. **Create Parent Booking:**
   ```csharp
   var parentBooking = new Booking {
       IsRecurring = true,
       RecurrenceRule = "Weekly;Mon,Wed,Fri",
       StartTime = firstSlot.start,
       EndTime = lastSlot.end,
       TotalPrice = totalPrice
   };
   ```

8. **Create All Child Bookings:**
   ```csharp
   foreach (var (start, end) in bookingSlots) {
       var childBooking = new Booking {
           ParentBookingId = parentBooking.Id,
           StartTime = start,
           EndTime = end,
           TotalPrice = pricePerSlot,
           Status = Confirmed
       };
   }
   ```

9. **Deduct Wallet & Update Tier:**
   ```csharp
   member.WalletBalance -= totalPrice;
   member.TotalSpent += totalPrice;
   UpdateTierBasedOnTotalSpent(member);
   ```

10. **Create Single Transaction:**
    ```csharp
    var walletTx = new WalletTransaction {
        Amount = -totalPrice,
        Type = Payment,
        Description = $"Đặt lịch định kỳ {courtName} - {slotsCount} buổi"
    };
    ```

**Response:**
```json
{
  "success": true,
  "message": "Đặt lịch định kỳ thành công! 12 buổi",
  "data": {
    "parentBookingId": 456,
    "totalSlots": 12,
    "totalPrice": 2400000,
    "newBalance": 7600000
  }
}
```

**Error Codes:**
- `VIP_REQUIRED` - Chỉ Gold/Diamond được dùng
- `INVALID_PATTERN` - Pattern format sai
- `NO_SLOTS_GENERATED` - Không tạo được slot nào
- `TIME_SLOT_CONFLICT` - Có slot bị trùng
- `INSUFFICIENT_BALANCE` - Ví không đủ tiền

---

## 🤖 BACKGROUND SERVICES (MỚI!)

### 1. BookingHoldCleanupService
**Chức năng:** Auto-cancel các booking Holding quá hạn

**Cấu hình:**
- Chạy mỗi: **1 phút**
- Timeout: **5 phút**

**Luồng xử lý:**
```csharp
protected override async Task ExecuteAsync(CancellationToken stoppingToken)
{
    while (!stoppingToken.IsCancellationRequested)
    {
        var expiredTime = DateTime.Now.Subtract(TimeSpan.FromMinutes(5));
        
        var expiredHoldings = await _context.Bookings
            .Where(b => b.Status == Holding 
                     && b.CreatedDate < expiredTime)
            .ToListAsync();
        
        foreach (var booking in expiredHoldings)
        {
            // Cancel booking
            booking.Status = Cancelled;
            
            // Create notification
            var notification = new Notification {
                Message = $"Booking {courtName} đã bị hủy do không xác nhận trong 5 phút"
            };
            
            // SignalR notify user
            await _hubContext.Clients.User(userId)
                .SendAsync("ReceiveNotification", message);
        }
        
        // Broadcast calendar update
        await _hubContext.Clients.All.SendAsync("UpdateCalendar");
        
        await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
    }
}
```

**Đăng ký service:**
```csharp
// Program.cs
builder.Services.AddHostedService<BookingHoldCleanupService>();
```

**Log output:**
```
[10:30:00] Booking Hold Cleanup Service started
[10:31:00] Found 2 expired holding bookings to cancel
[10:31:00] Cancelled expired holding booking ID: 123
[10:31:00] Cancelled expired holding booking ID: 124
[10:31:00] Successfully cancelled 2 expired holding bookings
```

---

## 🏟️ HỆ THỐNG ĐẶT SÂN - DATABASE CHANGES

### Booking Model Updates:
```csharp
public class Booking
{
    // ... existing fields
    
    // NEW FIELDS:
    public DateTime? HoldExpiresAt { get; set; }  // Thời gian hết hạn giữ chỗ
    public bool IsRecurring { get; set; }         // Đánh dấu lịch định kỳ
    public string? RecurrenceRule { get; set; }   // Quy tắc lặp
    public int? ParentBookingId { get; set; }     // ID booking cha (nếu là con)
}
```

### BookingStatus Enum (Updated):
```csharp
public enum BookingStatus
{
    Holding = 0,         // MỚI: Đang giữ chỗ
    PendingPayment = 1,  // Legacy
    Confirmed = 2,       // Đã xác nhận
    Cancelled = 3,       // Đã hủy
    Completed = 4        // Đã hoàn thành
}
```

**⚠️ CRITICAL:** Thứ tự enum quan trọng! Frontend phải sync index giống backend.

---

## 📊 BOOKING DTOs (MỚI)

### HoldBookingDto
```csharp
public class HoldBookingDto
{
    public int CourtId { get; set; }
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
}
```

### HoldResponseDto
```csharp
public class HoldResponseDto
{
    public int BookingId { get; set; }
    public DateTime ExpiresAt { get; set; }
    public decimal TotalPrice { get; set; }
    public int SecondsRemaining { get; set; }
}
```

### RecurringBookingDto
```csharp
public class RecurringBookingDto
{
    public int CourtId { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public TimeOnly StartTime { get; set; }
    public TimeOnly EndTime { get; set; }
    public string RecurrencePattern { get; set; } // "Weekly;Mon,Wed,Fri"
    public int OccurrencesCount { get; set; }
}
```

### CancelPreviewDto
```csharp
public class CancelPreviewDto
{
    public bool CanCancel { get; set; }
    public decimal RefundPercentage { get; set; }
    public decimal RefundAmount { get; set; }
    public string Message { get; set; }
    public double HoursUntilStart { get; set; }
}
```

### TimeSlotDto
```csharp
public class TimeSlotDto
{
    public int CourtId { get; set; }
    public string CourtName { get; set; }
    public int Hour { get; set; }
    public string Time { get; set; }
    public bool IsBooked { get; set; }
    public int? BookingId { get; set; }
    public int? MemberId { get; set; }
    public string? MemberName { get; set; }
    public string? Status { get; set; }  // "Holding", "Confirmed", etc.
}
```

---

## 🔄 BOOKING FLOW COMPARISON

### Old Flow (Deprecated):
```
User tap slot → POST /api/bookings → Trừ tiền ngay → Confirmed
```
❌ **Vấn đề:** Race condition, user không có thời gian suy nghĩ

### New Flow (Current):
```
User tap slot 
  ↓
POST /api/bookings/hold → Holding (5 phút)
  ↓
User xem form + countdown timer (5:00 → 0:00)
  ↓
User click "Xác nhận"
  ↓
POST /api/bookings/confirm/{id} → Check balance → Trừ tiền → Confirmed
  ↓
Background Service (nếu timeout) → Auto-cancel
```
✅ **Ưu điểm:** 
- User có thời gian suy nghĩ
- Tránh race condition
- Balance check 2 lần (hold + confirm)
- Auto-cleanup expired holds

---

## 🎯 MEMBER TIER SYSTEM

### Tier Levels:
```csharp
public enum MemberTier
{
    Standard = 0,  // Mặc định
    Silver = 1,    // >= 3,000,000đ
    Gold = 2,      // >= 5,000,000đ (VIP)
    Diamond = 3    // >= 8,000,000đ (VIP)
}
```

### Auto-Update Logic:
```csharp
// Mỗi lần thanh toán:
member.TotalSpent += amount;

if (member.TotalSpent > 8000000)
    member.Tier = MemberTier.Diamond;
else if (member.TotalSpent > 5000000)
    member.Tier = MemberTier.Gold;
else if (member.TotalSpent > 3000000)
    member.Tier = MemberTier.Silver;
```

### VIP Benefits:
- **Gold & Diamond:** Được đặt lịch định kỳ (Recurring Booking)
- **Diamond:** Ưu tiên support, giảm giá (future feature)

---

## 🔔 ERROR CODES - BOOKING

### Hold Slot Errors:
- `HOLD_FAILED` - Không thể giữ chỗ
- `HOLD_EXPIRED` - Hết 5 phút chờ
- `INSUFFICIENT_BALANCE` - Ví không đủ

### Confirm Errors:
- `CONFIRM_FAILED` - Không xác nhận được
- `INVALID_STATUS` - Status không phải Holding

### Recurring Booking Errors:
- `VIP_REQUIRED` - Cần Gold/Diamond
- `INVALID_PATTERN` - Pattern sai format
- `NO_SLOTS_GENERATED` - Không tạo được slot
- `RECURRING_FAILED` - Lỗi tạo lịch

### General Booking Errors:
- `TIME_SLOT_CONFLICT` - Trùng lịch
- `BOOKING_TOO_LONG` - Quá 5 giờ
- `BOOKING_TOO_SHORT` - Dưới 1 giờ
- `INVALID_START_TIME` - Đặt quá khứ
- `COURT_NOT_FOUND` - Không tìm thấy sân
- `COURT_INACTIVE` - Sân bảo trì

---

## 🏟️ HỆ THỐNG ĐẶT SÂN (BOOKING) - CẬP NHẬT MỚI

5. **Database Transaction:**
   ```csharp
   using var transaction = await _context.Database.BeginTransactionAsync();
   
   // [DEPRECATED - Use Hold → Confirm flow instead]
   ```

6. **SignalR Broadcast:**
   ```csharp
   await _hubContext.Clients.All.SendAsync("UpdateCalendar");
   ```

---

## 🏆 HỆ THỐNG GIẢI ĐẤU (TOURNAMENTS)

### Tournament Status Flow:
```
Open → Registering → DrawCompleted → Ongoing → Finished
```

### Tournament Format:
- **RoundRobin** - Vòng tròn tính điểm
- **Knockout** - Loại trực tiếp
- **Hybrid** - Vòng bảng + Knockout

### 1. Tham gia giải đấu
**Endpoint:** `POST /api/tournaments/{id}/join`

**Luồng:**
1. Kiểm tra ví đủ EntryFee
2. Trừ tiền từ ví
3. Tạo TournamentParticipant
4. Tạo WalletTransaction (Payment)
5. Notification "Đã tham gia giải"

### 2. Tạo lịch thi đấu
**Endpoint:** `POST /api/tournaments/{id}/generate-schedule`  
**Role:** Admin

**Logic (chưa implement đầy đủ):**
- Lấy danh sách participants
- Nếu RoundRobin: Tạo trận đấu vòng tròn
- Nếu Knockout: Random chia cặp đấu
- Tạo các Match records

---

## 🔔 HỆ THỐNG THÔNG BÁO (NOTIFICATIONS)

### Notification Types:
- **Info** - Thông tin chung
- **Success** - Thành công (nạp tiền, đặt sân)
- **Warning** - Cảnh báo (từ chối nạp tiền)

### 1. Real-time với SignalR
**Hub:** `/pcmhub`

**Methods:**
```csharp
// Send to specific user
await Clients.User(userId).SendAsync("ReceiveNotification", message);

// Broadcast to all
await Clients.All.SendAsync("UpdateCalendar");

// Send to group (match viewers)
await Clients.Group($"match_{matchId}").SendAsync("UpdateMatchScore", score1, score2);
```

### 2. Lấy notifications
**Endpoint:** `GET /api/notifications?page=1&pageSize=20`

**Response:**
```json
{
  "total": 50,
  "unreadCount": 5,
  "data": [
    {
      "id": 1,
      "message": "Nạp tiền thành công 500,000đ",
      "type": "Success",
      "isRead": false,
      "createdDate": "2026-01-27T10:30:00"
    }
  ]
}
```

---

## 🔧 CẤU HÌNH & THIẾT LẬP

### appsettings.json
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "server=localhost;port=3306;database=pcm_db_519;user=root;password=;"
  },
  "Jwt": {
    "Key": "YourSuperSecretKeyThatIsAtLeast32CharactersLong519NhaNguyenThiThanhNha",
    "Issuer": "PCM_API_519",
    "Audience": "PCM_Mobile_519"
  }
}
```

### Program.cs - Services Configuration
```csharp
// MySQL
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseMySql(connectionString, serverVersion));

// Identity
builder.Services.AddIdentity<ApplicationUser, IdentityRole>()
    .AddEntityFrameworkStores<ApplicationDbContext>();

// JWT
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options => {
        // Token validation parameters
    });

// SignalR
builder.Services.AddSignalR();

// CORS
builder.Services.AddCors(options => {
    options.AddPolicy("AllowAll", builder => {
        builder.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader();
    });
});
```

---

## 📝 DATA SEEDING

### Tài khoản đã seed:

| Email | Password | Role | Wallet | Tier |
|-------|----------|------|--------|------|
| admin@pcm.com | Admin@123 | Admin | 10,000,000đ | Diamond |
| treasurer@pcm.com | Treasurer@123 | Treasurer | 5,000,000đ | Gold |
| referee@pcm.com | Referee@123 | Referee | 3,000,000đ | Silver |
| member1@pcm.com | Member1@123 | Member | 2M-10M | Random |
| ... member20@pcm.com | Member20@123 | Member | 2M-10M | Random |

### Dữ liệu mẫu:
- ✅ 4 Courts (Sân 1, 2, 3, VIP)
- ✅ 2 Tournaments:
  - "Summer Open 2026" - Đã kết thúc (Finished)
  - "Winter Cup 2026" - Đang mở đăng ký (Registering)
- ✅ 3 News bài viết (2 pinned)

---

## 🚀 CHẠY BACKEND

### Bước 1: Chuẩn bị
```bash
# Start XAMPP MySQL
# Đảm bảo MySQL đang chạy trên port 3306
```

### Bước 2: Migration (chỉ lần đầu)
```bash
cd PCM_Backend/PCM.API
dotnet ef migrations add InitialCreate
dotnet ef database update
```

### Bước 3: Chạy API
```bash
dotnet run
```

**Output:**
```
Now listening on: http://localhost:5283
Application started. Press Ctrl+C to shut down.
```

### Bước 4: Test API
- Swagger UI: http://localhost:5283/swagger
- SignalR Hub: http://localhost:5283/pcmhub

---

## ✅ CHECKLIST TRIỂN KHAI

### Backend Setup ✅
- [x] Tạo project ASP.NET Core Web API
- [x] Cài đặt packages (Pomelo, Identity, JWT, SignalR)
- [x] Tạo Models với prefix **519_**
- [x] Tạo ApplicationDbContext
- [x] Cấu hình Identity & JWT
- [x] Tạo Migration và Update Database
- [x] Implement Data Seeder
- [x] Cấu hình CORS
- [x] Cấu hình SignalR Hub

### Controllers ✅
- [x] AuthController (Login, Register, GetMe)
- [x] WalletController (Deposit, Approve, Transactions)
- [x] CourtsController (GetCourts)
- [x] BookingsController - ENHANCED WITH NEW FEATURES:
  - [x] GET /calendar - Xem lịch sân
  - [x] GET /slots - Timeline 6am-10pm theo giờ
  - [x] **POST /hold - Giữ chỗ 5 phút (MỚI)**
  - [x] **POST /confirm/{id} - Xác nhận và thanh toán (MỚI)**
  - [x] POST /cancel/{id} - Hủy sân với refund policy
  - [x] GET /cancel-preview/{id} - Preview refund
  - [x] PUT /edit/{id} - Sửa booking (5min grace)
  - [x] POST /reschedule/{id} - Đổi lịch (24h + 10% fee)
  - [x] **POST /recurring - Đặt lịch định kỳ VIP (MỚI)**
  - [x] GET /my-bookings - Lịch của tôi
- [x] MembersController (GetMembers, GetProfile)
- [x] NewsController (GetNews)
- [x] NotificationsController (GetNotifications, MarkRead)

### Business Logic ✅
- [x] JWT Token generation & validation
- [x] Wallet deposit approval workflow
- [x] **Hold Slot mechanism - 5 phút timeout (MỚI)**
- [x] **Background Service auto-cancel expired holds (MỚI)**
- [x] Booking overlap detection (check Holding + Confirmed)
- [x] Automatic price calculation
- [x] Tier auto-update based on TotalSpent
- [x] **VIP tier check for recurring booking (MỚI)**
- [x] **Recurring booking pattern parsing (MỚI)**
- [x] Refund policy (24h/6h rules + admin override)
- [x] SignalR real-time notifications
- [x] **Standardized error responses with error codes (MỚI)**

### Advanced Features ✅
- [x] **BookingHoldCleanupService - Chạy mỗi 1 phút (MỚI)**
- [x] **Hold → Confirm booking flow (MỚI)**
- [x] **Recurring booking generation algorithm (MỚI)**
- [x] **Transaction isolation (SERIALIZABLE) for race conditions**
- [x] **Balance check 2 lần (hold + confirm)**
- [x] **Parent-child booking relationship**
- [x] Cancel preview with refund calculation
- [x] Edit booking with price adjustment
- [x] Reschedule with admin fee

### Testing cần làm 🔄
- [ ] Test Hold → Confirm flow
- [ ] Test Hold timeout → auto-cancel
- [ ] Test Recurring booking (VIP only)
- [ ] Test Background Service cleanup
- [ ] Test Cancel preview + refund
- [ ] Test Edit/Reschedule booking
- [ ] Test Wallet deposit → approve flow
- [ ] Test SignalR real-time updates
- [ ] Test CORS từ Flutter

---

## 🔜 TIẾP THEO: FLUTTER MOBILE APP

### Cần implement:
1. **Setup Flutter Project**
   - Tạo project structure
   - Cài packages: dio, riverpod, go_router, flutter_secure_storage, signalr_netcore, table_calendar

2. **API Client**
   - Dio HTTP client với interceptor
   - JWT token management
   - Error code translation (Vietnamese)
   - Retry logic (500/503 only)

3. **Booking Screens** ⭐
   - **Calendar với Timeline view (6am-10pm slots)**
   - **Hold Confirmation Dialog với countdown timer**
   - Color-coded slots: Green (trống), Blue (của tôi), Red (đã đặt), **Orange (holding)**
   - Cancel dialog với preview refund
   - Recurring booking form (VIP only)

4. **State Management**
   - Riverpod providers
   - Auth state
   - Wallet balance state
   - Booking list state

5. **Real-time**
   - SignalR connection
   - Listen to ReceiveNotification
   - Listen to UpdateCalendar

---

## 🐛 TROUBLESHOOTING

### Lỗi thường gặp:

**1. Database connection failed**
```
Solution: Kiểm tra XAMPP MySQL đã start chưa
```

**2. Migration error**
```
Solution: Cài dotnet-ef tools:
dotnet tool install --global dotnet-ef --version 9.0.0
```

**3. JWT Token invalid**
```
Solution: Kiểm tra Jwt:Key trong appsettings.json phải >= 32 ký tự
```

**4. CORS error từ Flutter**
```
Solution: Đã cấu hình AllowAll policy trong Program.cs
```

---

## 📚 TÀI LIỆU THAM KHẢO

- ASP.NET Core Identity: https://docs.microsoft.com/aspnet/core/security/authentication/identity
- JWT Authentication: https://jwt.io/introduction
- SignalR: https://docs.microsoft.com/aspnet/core/signalr/introduction
- Pomelo MySQL: https://github.com/PomeloFoundation/Pomelo.EntityFrameworkCore.MySql

---

**Tạo bởi:** Nguyễn Thị Thanh Nhã - MSSV 1771020519  
**Ngày:** 27/01/2026
