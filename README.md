# PCM - Hệ thống quản lý CLB Pickleball "Vợt Thủ Phố Núi"

## Thông tin sinh viên
- **Họ và tên:** Nguyễn Thị Thanh Nhã
- **MSSV:** 1771020519
- **3 số cuối MSSV:** 519 (được sử dụng trong tên bảng database)

## Cấu trúc project
```
├── PCM_Backend/         # ASP.NET Core Web API
│   └── PCM.API/
├── PCM_Mobile/          # Flutter Mobile App
└── README.md
```

## Backend - ASP.NET Core Web API

### Yêu cầu hệ thống
- .NET SDK 9.0 hoặc cao hơn
- MySQL/MariaDB (XAMPP)
- EF Core Tools

### Cài đặt .NET 9.0 Runtime (nếu chưa có)
Tải và cài đặt từ: https://dotnet.microsoft.com/download/dotnet/9.0

### Cài đặt EF Core Tools
```bash
dotnet tool install --global dotnet-ef --version 9.0.0
```

### Cấu hình Database
1. Mở XAMPP và start MySQL
2. Database sẽ được tự động tạo với tên: `pcm_db_519`
3. Connection string trong `appsettings.json`:
```json
"server=localhost;port=3306;database=pcm_db_519;user=root;password=;"
```

### Chạy Migration và Seed Data
```bash
cd PCM_Backend/PCM.API
dotnet ef migrations add InitialCreate
dotnet ef database update
```

### Chạy Backend API
```bash
cd PCM_Backend/PCM.API
dotnet run
```

API sẽ chạy tại: `http://localhost:5000` và `https://localhost:5001`
Swagger UI: `https://localhost:5001/swagger`

### Tài khoản mẫu sau khi seed data

**Admin** (Nguyễn Thị Thanh Nhã - MSSV 1771020519):
- Email: admin@pcm.com
- Password: Admin@123
- Wallet: 10,000,000đ
- Tier: Diamond

**Treasurer**:
- Email: treasurer@pcm.com
- Password: Treasurer@123
- Wallet: 5,000,000đ

**Referee**:
- Email: referee@pcm.com
- Password: Referee@123
- Wallet: 3,000,000đ

**20 Members** (member1@pcm.com đến member20@pcm.com):
- Password: Member1@123, Member2@123, ...
- Wallet: 2,000,000đ - 10,000,000đ (random)

### API Endpoints chính

**Auth:**
- POST `/api/auth/login` - Đăng nhập
- POST `/api/auth/register` - Đăng ký
- GET `/api/auth/me` - Thông tin user hiện tại

**Wallet:**
- POST `/api/wallet/deposit` - Yêu cầu nạp tiền
- GET `/api/wallet/transactions` - Lịch sử giao dịch
- PUT `/api/admin/wallet/approve/{id}` - Admin duyệt nạp tiền

**Courts:**
- GET `/api/courts` - Danh sách sân

**Bookings:**
- GET `/api/bookings/calendar` - Lịch đặt sân
- POST `/api/bookings` - Đặt sân mới
- POST `/api/bookings/cancel/{id}` - Hủy sân
- GET `/api/bookings/my-bookings` - Lịch sử đặt sân

**Members:**
- GET `/api/members` - Danh sách thành viên
- GET `/api/members/{id}/profile` - Profile thành viên

**News:**
- GET `/api/news` - Tin tức

**Notifications:**
- GET `/api/notifications` - Thông báo của tôi
- PUT `/api/notifications/{id}/mark-read` - Đánh dấu đã đọc

**SignalR Hub:**
- `/pcmhub` - Real-time notifications và updates

---

## Mobile - Flutter App

### Yêu cầu
- Flutter SDK 3.38.0 trở lên
- Dart 3.10.0 trở lên
- Android Studio / VS Code
- Android Emulator hoặc thiết bị thật

### Cài đặt dependencies
```bash
cd PCM_Mobile/pcm_mobile
flutter pub get
```

### Cấu hình API URL
Mở file `lib/core/constants/api_constants.dart` và cập nhật:
```dart
// Nếu chạy trên Android Emulator:
static const String baseUrl = 'http://10.0.2.2:5000/api';

// Nếu chạy trên thiết bị thật hoặc iOS Simulator:
static const String baseUrl = 'http://192.168.x.x:5000/api';
```

### Chạy app
```bash
flutter run
```

### Tính năng chính

1. **Authentication**
   - Đăng nhập / Đăng ký
   - JWT Token authentication
   - Auto refresh khi hết hạn

2. **Dashboard**
   - Hiển thị số dư ví
   - Thống kê: Booking, Tournaments, Rank
   - Tin tức mới nhất

3. **Wallet (Ví điện tử)**
   - Hiển thị số dư
   - Yêu cầu nạp tiền (kèm ảnh chứng minh)
   - Lịch sử giao dịch
   - Filter theo loại giao dịch

4. **Booking (Đặt sân)**
   - Calendar view xem lịch sân
   - Đặt sân mới (tự động trừ tiền từ ví)
   - Hủy sân (hoàn tiền theo chính sách)
   - Xem lịch sử đặt sân

5. **Members**
   - Danh sách thành viên
   - Tìm kiếm thành viên
   - Xem profile và lịch sử thi đấu

6. **Tournaments**
   - Danh sách giải đấu
   - Chi tiết giải
   - Tham gia giải (trừ Entry Fee)
   - Xem bracket và kết quả

7. **Notifications**
   - Danh sách thông báo
   - Real-time updates (SignalR)
   - Badge số lượng chưa đọc

8. **Admin Features**
   - Duyệt yêu cầu nạp tiền
   - Dashboard thống kê doanh thu
   - Quản lý giải đấu

### Packages sử dụng
- **dio**: HTTP client
- **riverpod**: State management
- **go_router**: Navigation
- **flutter_secure_storage**: Lưu JWT token
- **signalr_netcore**: Real-time SignalR
- **table_calendar**: Calendar view
- **fl_chart**: Charts và biểu đồ
- **image_picker**: Upload ảnh
- **cached_network_image**: Cache ảnh

---

## Database Schema

Tất cả bảng bắt đầu với prefix **519** (3 số cuối MSSV):

- `519_Members` - Thông tin thành viên
- `519_WalletTransactions` - Giao dịch ví điện tử
- `519_News` - Tin tức
- `519_Courts` - Sân đấu
- `519_Bookings` - Đặt sân
- `519_Tournaments` - Giải đấu
- `519_TournamentParticipants` - Người tham gia giải
- `519_Matches` - Trận đấu
- `519_Notifications` - Thông báo

---

## Luồng hoạt động chính

### 1. Đăng nhập → Xem Dashboard
```
User mở app → Login → JWT Token được lưu 
→ Dashboard hiển thị số dư ví, rank, bookings sắp tới
```

### 2. Nạp tiền vào ví
```
User → Wallet → Tap "Nạp tiền" → Nhập số tiền + upload ảnh CK
→ API tạo WalletTransaction (Status: Pending)
→ Admin vào app → Approve transaction
→ Số dư ví tăng → User nhận notification (SignalR)
```

### 3. Đặt sân
```
User → Bookings → Calendar → Chọn slot trống → Chọn Court
→ API check ví đủ tiền → Tạo Booking → Trừ tiền ví
→ Create WalletTransaction (Type: Payment)
→ Broadcast UpdateCalendar (SignalR) → All users thấy slot đã đặt
→ User nhận notification "Đặt sân thành công"
```

### 4. Tham gia giải đấu
```
User → Tournaments → Chọn giải → Tap "Tham gia"
→ API check ví đủ Entry Fee → Trừ tiền → Create TournamentParticipant
→ User nhận notification "Đã tham gia giải"
```

---

## Tính năng nâng cao đã implement

✅ **Real-time với SignalR**
- Notifications tức thì
- Calendar auto-update khi có booking mới
- Match score live updates

✅ **Wallet System**
- Giao dịch an toàn với Database Transaction
- Tự động update Tier dựa trên TotalSpent
- Refund policy khi hủy sân

✅ **Smart Booking**
- Check trùng lịch
- Tính giá tự động theo giờ
- Hold slot mechanism (5 phút)

✅ **Data Seeding**
- Admin là sinh viên (Nguyễn Thị Thanh Nhã - 1771020519)
- 20 members với ví và tier khác nhau
- 2 tournaments mẫu
- 4 courts
- News mẫu

---

## Video Demo

Luồng demo:
1. Mở app → Đăng nhập (admin@pcm.com)
2. Xem Dashboard → Số dư ví 10,000,000đ
3. Vào Wallet → Xem lịch sử giao dịch
4. Vào Bookings → Xem calendar → Đặt sân mới
5. Ví giảm xuống → Notification hiện ra
6. Vào Members → Xem danh sách thành viên
7. Admin: Approve deposit request từ user khác
8. Xem Tournaments → Chi tiết giải

---

## Lưu ý khi chấm bài

1. **Cần start MySQL (XAMPP) trước khi chạy Backend**
2. **Cần chạy Backend trước khi chạy Mobile app**
3. **Cấu hình đúng API URL trong Flutter (10.0.2.2 cho emulator)**
4. **Tất cả bảng có prefix 519** (3 số cuối MSSV)
5. **Admin account là thông tin sinh viên thật**

---

## Contact
- Sinh viên: Nguyễn Thị Thanh Nhã
- MSSV: 1771020519
- GitHub: [Link repository]

---

**Ngày hoàn thành:** 27/01/2026
