# salon*booking*

Dự án Flutter cho quản lý đặt lịch salon.

## Cấu trúc dự án

Mã nguồn chính nằm trong thư mục `lib/`.

### `lib/main.dart`

- Điểm vào của ứng dụng.
- Khởi tạo Flutter và nạp cấu hình cấp ứng dụng, chủ đề, và định tuyến.

### `lib/core/`

Chứa cấu trúc hạ tầng dùng chung cho toàn bộ ứng dụng.

- `constants/`: các hằng số toàn cục như chuỗi, khóa, và cấu hình tĩnh.
- `network/`: tầng mạng, client API, xử lý request/response và tiện ích mạng.
- `service/`: các dịch vụ lõi của ứng dụng, bao gồm logic dùng chung, thiết lập phụ thuộc, và dịch vụ hỗ trợ.
- `themes/`: định nghĩa theme ứng dụng, màu sắc, kiểu chữ và phong cách hiển thị toàn cục.
- `utils/`: các hàm tiện ích chung và helper tái sử dụng.
- `widgets/`: widget cốt lõi có thể dùng lại khắp ứng dụng.

### `lib/features/`

Chứa các module theo từng tính năng cụ thể của ứng dụng đặt lịch salon.
Mỗi thư mục thường bao gồm màn hình UI, controller, quản lý trạng thái, và logic riêng của tính năng.

- `auth/`: luồng xác thực, đăng nhập/đăng ký, và quản lý session người dùng.
- `booking/`: luồng đặt lịch và cuộc hẹn, màn hình đặt chỗ, chọn lịch, và quản lý booking.
- `chat/`: tính năng trò chuyện hoặc nhắn tin giữa người dùng và nhân viên salon.
- `location/`: chức năng liên quan đến vị trí, ví dụ bản đồ, chọn địa chỉ, hoặc tìm salon gần.
- `service/`: dịch vụ salon, trang chi tiết dịch vụ, và quản lý danh mục dịch vụ.

### `lib/shared/`

Chứa các thành phần và mô hình dữ liệu tái sử dụng được dùng chung giữa nhiều tính năng.

- `extensions/`: các extension Dart mở rộng phương thức cho các kiểu dữ liệu cơ bản.
- `models/`: mô hình dữ liệu và định nghĩa thực thể của ứng dụng.
- `widgets/`: widget UI tái sử dụng giữa nhiều tính năng và màn hình.

## Ghi chú

Cấu trúc thư mục trên phân tách rõ ràng:

- hạ tầng lõi và tiện ích ứng dụng ở `lib/core/`.
- chức năng theo từng tính năng ở `lib/features/`.
- thành phần dùng chung và định nghĩa dữ liệu ở `lib/shared/`.

Điều này giúp ứng dụng dễ điều hướng, mở rộng và bảo trì hơn.
