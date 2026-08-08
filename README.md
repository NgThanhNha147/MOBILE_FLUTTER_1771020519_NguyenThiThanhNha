# Pickleball Club Management

Ứng dụng quản lý câu lạc bộ pickleball gồm mobile app dành cho thành viên và REST API xử lý nghiệp vụ. Dự án được thực hiện trong quá trình học Flutter, với mục tiêu xây dựng một luồng hoàn chỉnh từ giao diện, API đến cơ sở dữ liệu.

## Bài toán

Thành viên có thể xem lịch sân, giữ chỗ, thanh toán bằng số dư trong hệ thống và theo dõi các giải đấu. Những thay đổi quan trọng như trạng thái booking, số dư ví và thông báo được cập nhật theo thời gian thực.

Phần mình tập trung nhiều nhất là luồng đặt sân: một khung giờ được giữ tạm trong 5 phút trước khi xác nhận. Backend kiểm tra trùng lịch và số dư, còn background service tự giải phóng các lượt giữ chỗ đã hết hạn.

## Chức năng chính

- Đăng ký, đăng nhập bằng JWT và phân quyền theo vai trò
- Xem lịch sân và trạng thái từng khung giờ
- Giữ chỗ 5 phút, xác nhận hoặc hủy booking
- Đặt lịch định kỳ cho thành viên đủ hạng
- Hủy sân và tính mức hoàn tiền theo thời gian
- Quản lý số dư, yêu cầu nạp tiền và lịch sử giao dịch
- Quản lý thành viên, giải đấu, tin tức và thông báo
- Đồng bộ lịch, ví và thông báo bằng SignalR

## Công nghệ

| Thành phần | Công nghệ |
| --- | --- |
| Mobile | Flutter, Dart, Riverpod, Dio, GoRouter |
| Backend | ASP.NET Core 9, Entity Framework Core, Identity |
| Database | MySQL |
| Realtime | SignalR |
| Authentication | JWT Bearer |

## Cấu trúc

```text
PCM_Backend/PCM.API/   ASP.NET Core Web API
PCM_Mobile/            Flutter application
```

Backend được chia theo controller, DTO, model và service. Mobile app tách phần gọi API, state management, model và màn hình theo từng nhóm chức năng.

## Chạy dự án ở local

### 1. Chuẩn bị

- .NET SDK 9
- Flutter SDK tương thích Dart 3.10 trở lên
- MySQL

### 2. Cấu hình backend

Connection string mặc định dùng MySQL tại local và database `pcm_db_519`. Có thể ghi đè cấu hình bằng biến môi trường:

```powershell
$env:ConnectionStrings__DefaultConnection="server=localhost;port=3306;database=pcm_db_519;user=root;password=YOUR_PASSWORD;"
$env:Jwt__Key="YOUR_LOCAL_DEVELOPMENT_KEY_AT_LEAST_32_CHARACTERS"
```

JWT key không được lưu trong repository. Mỗi môi trường cần cung cấp key riêng.

Khởi động API:

```powershell
cd PCM_Backend/PCM.API
dotnet restore
dotnet run
```

Ở profile mặc định, API chạy tại `http://localhost:5283` và Swagger được mở tại `http://localhost:5283/swagger` trong môi trường Development. Migration và dữ liệu demo được áp dụng khi ứng dụng khởi động.

### 3. Chạy Flutter app

```powershell
cd PCM_Mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5283
```

`10.0.2.2` là địa chỉ truy cập máy host từ Android Emulator. Khi chạy trên thiết bị thật, thay bằng địa chỉ IP trong mạng nội bộ của máy chạy backend.

## Tài khoản demo

| Vai trò | Email | Mật khẩu |
| --- | --- | --- |
| Admin | `admin@pcm.com` | `Admin@123` |
| Treasurer | `treasurer@pcm.com` | `Treasurer@123` |
| Referee | `referee@pcm.com` | `Referee@123` |
| Member | `member1@pcm.com` | `Member1@123` |

Các tài khoản trên chỉ được tạo để chạy và trình bày dự án ở môi trường local.

## Một số quyết định kỹ thuật

- Booking ở trạng thái `Holding` chưa trừ tiền; số dư được kiểm tra lại khi người dùng xác nhận.
- Background service quét và hủy các lượt giữ chỗ hết hạn để khung giờ có thể được đặt lại.
- Các thao tác ảnh hưởng đến ví và booking sử dụng database transaction nhằm giữ dữ liệu nhất quán.
- SignalR gửi cập nhật đến đúng người dùng hoặc broadcast thay đổi lịch cho các client đang kết nối.
- JWT được lưu bằng secure storage trên mobile và tự động gắn vào request qua Dio interceptor.

## Hướng phát triển

- Bổ sung automated tests cho booking, refund và authorization
- Tích hợp cổng thanh toán thay cho quy trình nạp tiền mô phỏng
- Đóng gói backend bằng Docker và triển khai môi trường demo
- Bổ sung ảnh chụp màn hình và video demo ngắn

## Tác giả

Nguyễn Thị Thanh Nhã
GitHub: [NgThanhNha147](https://github.com/NgThanhNha147)
