# Quy trình đặt cơm và quản lý quỹ

## 1. Mục tiêu

Module đặt cơm chuyển quy trình đang làm thủ công thành một luồng có thể kiểm tra và đối soát:

1. Quán gửi thực đơn dạng văn bản cho admin.
2. Admin import thực đơn, ngày áp dụng, giờ chốt và đơn giá.
3. Nhân viên chọn món cho mình hoặc đặt hộ đồng nghiệp.
4. Hệ thống trừ quỹ nếu người trả có đủ số dư; nếu không đủ vẫn giữ phần ăn và đánh dấu chưa thanh toán.
5. Khi hết giờ nhận đơn, admin đóng đơn, tổng hợp nội dung và copy gửi quán.
6. Admin ghi nhận tiền đã nhận ngoài hệ thống và xác nhận các đơn chưa thanh toán.

Tiền trong module được lưu theo số nguyên Việt Nam đồng. Đơn giá mặc định của một phần là **35.000đ**, nhưng admin có thể đặt đơn giá khác khi import từng ngày.

## 2. Vai trò

### User

- Xem thực đơn hôm nay, giờ chốt và đơn giá.
- Chọn một phần cho bản thân.
- Đặt hộ một đồng nghiệp; người đặt là người trả hộ nếu quỹ còn đủ.
- Sửa hoặc hủy phần mình phụ trách trước giờ chốt.
- Xem lịch sử đơn, trạng thái thanh toán, số dư và sổ giao dịch quỹ.
- Tự đối soát tiền với đồng nghiệp ở bên ngoài khi đặt hộ.

### Admin

Admin có toàn bộ quyền của user và thêm các quyền:

- Import thực đơn hằng ngày.
- Chọn nhãn đơn, tên quán, ngày áp dụng, giờ chốt và đơn giá.
- Đóng đơn sớm hoặc mở lại đơn.
- Xem tất cả phần ăn và các đơn chưa thanh toán.
- Tổng hợp, copy nội dung gửi quán và xem số lượng theo từng món.
- Nhận tiền mặt/chuyển khoản ở bên ngoài rồi nạp quỹ cho user.
- Xác nhận một đơn chưa thanh toán đã được thu tiền bên ngoài.

Danh sách admin được cấu hình bằng biến môi trường `ADMIN_EMAILS`; xem phần cấu hình trong README.

## 3. Import thực đơn và ý nghĩa dấu `+`

Admin dán nguyên văn thực đơn quán gửi. Mỗi dòng không rỗng là một món. Dòng chỉ chứa ký tự `+` là ranh giới giữa hai nhóm:

- Các món **trước** dấu `+`: món thường (`REGULAR`), dùng để ghép một phần cơm hai món.
- Các món **sau** dấu `+`: món đơn/đặc biệt (`SPECIAL`), mỗi phần chỉ chọn một món.

Ví dụ:

```txt
Lòng gà roty
Tôm ram
Khô cá lưỡi trâu chiên
Sườn ram
Cà tím nướng mỡ hành
Thịt kho
Trứng kho
Gà kho sả
Cá ngừ kho
+
Phở bò
```

Quy tắc parse:

- Bỏ qua dòng trống và khoảng trắng thừa ở đầu/cuối dòng.
- Gộp nhiều khoảng trắng liên tiếp trong tên món thành một khoảng trắng.
- Dấu `+` phải nằm trên một dòng riêng và chỉ được xuất hiện tối đa một lần.
- Nếu không có dấu `+`, tất cả món đều thuộc nhóm món thường.
- Không chấp nhận tên món trùng nhau, không phân biệt chữ hoa/chữ thường.
- Nếu có dấu `+`, phía sau phải có ít nhất một món đặc biệt.
- Nhóm món thường có đúng một món là không hợp lệ vì không thể tạo phần hai món.
- Thực đơn rỗng hoặc chỉ có dấu `+` là không hợp lệ.
- Mỗi ngày chỉ có một thực đơn. Import trùng ngày phải bị từ chối để tránh hai danh sách nhận đơn song song.

Khi import thành công, thực đơn ở trạng thái `OPEN`. Tuy nhiên, user chỉ đặt được khi thực đơn vừa `OPEN` vừa chưa tới `cutoffAt`.

## 4. Quy tắc chọn món

User chọn đúng một trong hai loại phần:

| Loại | Mã | Quy tắc |
| --- | --- | --- |
| Cơm hai món | `COMBO` | Chọn đúng 2 món khác nhau trong nhóm trước dấu `+` |
| Món đơn | `SINGLE` | Chọn đúng 1 món trong nhóm sau dấu `+` |

Không được:

- Chọn cùng một món hai lần.
- Ghép một món thường với một món đặc biệt.
- Chọn hai món đặc biệt cho một phần.
- Gửi ID món thuộc thực đơn khác hoặc món không còn tồn tại.

User có thể thêm ghi chú như `cơm thêm + rau thêm`. Ghi chú được làm sạch khoảng trắng, giới hạn 500 ký tự và được đặt trong ngoặc ở nội dung gửi quán.

## 5. Đặt cho mình và trả hộ

Ba khái niệm được lưu riêng:

- **Người nhận (`beneficiary`)**: người có phần ăn.
- **Người tạo đơn (`orderedBy`)**: người thao tác đặt.
- **Người trả (`payer`)**: chủ tài khoản quỹ bị trừ tiền.

### Đặt cho bản thân

Nếu user không chọn đồng nghiệp, cả ba vai trò là chính user đó. Một user chỉ có tối đa một phần đang hoạt động trong một thực đơn.

### Đặt hộ đồng nghiệp

Nếu user A chọn user B làm người nhận:

- B là người nhận phần ăn.
- A là người tạo đơn và là người trả hộ nếu quỹ của A đủ.
- Hệ thống trừ đúng một đơn giá từ quỹ của A.
- A và B tự hoàn tiền/đối soát với nhau bên ngoài hệ thống.
- B vẫn chỉ có tối đa một phần trong ngày; nếu người khác đã đặt cho B, yêu cầu tiếp theo phải bị từ chối thay vì tạo phần trùng.

## 6. Quỹ và trạng thái thanh toán

### Nạp quỹ

Hệ thống không trực tiếp thu tiền. Quy trình nạp quỹ là:

1. User đưa tiền mặt hoặc chuyển khoản cho admin ở bên ngoài.
2. Admin chọn đúng user, nhập số tiền dương và ghi chú đối soát.
3. Hệ thống tăng số dư và tạo giao dịch `TOP_UP`.

Nạp quỹ không tự động đổi trạng thái một đơn `UNPAID` cũ. Admin phải xác nhận khoản thu ngoài cho đúng đơn để tránh vừa tăng quỹ vừa tính đơn đó là đã trả.

### Đủ quỹ

Nếu quỹ của người đặt/người trả lớn hơn hoặc bằng đơn giá:

- Trừ toàn bộ đơn giá trong một giao dịch `ORDER_DEBIT`.
- Không trừ từng phần và không cho số dư âm.
- Đơn nhận trạng thái `PAID_FUND`.
- Giao dịch lưu số dư sau giao dịch và liên kết tới đơn để đối soát.

Với đơn giá mặc định, số dư thay đổi như sau:

```txt
100.000đ - 35.000đ = 65.000đ
```

### Không đủ quỹ

Nếu số dư nhỏ hơn đơn giá:

- Hệ thống vẫn tạo và giữ phần ăn.
- Không trừ một phần số dư và không tạo số dư âm.
- Đơn nhận trạng thái `UNPAID`.
- Admin thu đủ tiền bên ngoài rồi xác nhận đơn; đơn chuyển thành `PAID_EXTERNAL`.
- Xác nhận ngoài không trừ quỹ lần nữa.

Một người nhận có đơn `UNPAID` từ ngày trước sẽ không được tạo phần cho ngày sau cho tới khi admin xác nhận khoản tiền ngoài. Quy tắc này áp dụng cả khi chính họ đặt và khi người khác cố đặt hộ.

### Hủy đơn

- Chỉ được hủy trước giờ chốt và khi menu còn nhận đơn.
- Đơn chuyển từ `ACTIVE` sang `CANCELLED`; dữ liệu cũ được giữ để kiểm tra.
- Nếu đơn đã `PAID_FUND`, hệ thống hoàn đúng số tiền đã trừ cho người trả bằng giao dịch `ORDER_REFUND`.
- Nếu đơn là `UNPAID`, không phát sinh hoàn quỹ.
- Hủy hoặc gửi lại đồng thời không được tạo hai phần cho cùng người nhận.

## 7. Giờ chốt và đóng/mở đơn

Một menu nhận đơn khi đồng thời thỏa mãn:

```txt
status = OPEN và thời gian máy chủ < cutoffAt
```

Từ đúng thời điểm chốt trở đi, user không thể tạo, sửa hoặc hủy đơn. Admin có thể:

- **Đóng đơn (`CLOSED`)** trước giờ chốt để ngừng nhận ngay.
- **Mở lại (`OPEN`)** nếu đóng nhầm. Mở lại sau `cutoffAt` không làm menu nhận đơn trở lại vì điều kiện thời gian vẫn không thỏa mãn.

Mọi kiểm tra cutoff phải thực hiện ở backend, không dựa riêng vào đồng hồ hoặc trạng thái nút ở trình duyệt. Múi giờ vận hành của hệ thống là `Asia/Ho_Chi_Minh`.

Quy trình khuyến nghị khi chốt:

1. Chờ tới cutoff hoặc chủ động đóng menu.
2. Kiểm tra tổng số phần và số đơn `UNPAID`.
3. Bấm **Tổng hợp**.
4. Copy nội dung đã sinh và gửi quán.
5. Không sửa dữ liệu sau khi đã gửi quán; nếu bắt buộc thay đổi, admin phải đối soát lại với quán và tổng hợp lại.

## 8. Tổng hợp và copy gửi quán

Tổng hợp chỉ lấy các đơn `ACTIVE`; đơn `CANCELLED` không được tính. Kết quả gồm:

- Tổng số phần.
- Số đơn `PAID_FUND`, `PAID_EXTERNAL` và `UNPAID`.
- Tổng tiền bằng `số phần × đơn giá`.
- Số lượng xuất hiện của từng món.
- Chuỗi đã định dạng để copy gửi quán.

Định dạng:

```txt
{Nhãn đơn} - {dd-MM}: {số phần} phần
- {món 1} + {món 2}
- {món 1} + {món 2} ({ghi chú})
- {món đơn}
```

Ví dụ:

```txt
Vũ - 21-07: 6 phần
- Sườn ram + Canh khổ qua dồn thịt
- Cá ngừ chiên sốt cà + Gỏi gà (cơm thêm + rau thêm)
- Gỏi gà + Thịt kho đậu hủ
- Sườn ram + Thịt kho đậu hủ
- Bánh canh gạo hải sản
- Trứng chiên + Canh khổ qua
```

Thao tác tổng hợp không phải là thao tác thu tiền. Đơn `UNPAID` vẫn xuất hiện trong danh sách gửi quán và vẫn cần được admin xác nhận riêng sau khi nhận tiền.

## 9. Trạng thái

### Menu

| Trạng thái | Ý nghĩa |
| --- | --- |
| `OPEN` | Menu được mở; chỉ nhận đơn nếu chưa tới cutoff |
| `CLOSED` | Admin đã đóng, không nhận tạo/sửa/hủy |

### Đơn

| Trạng thái | Ý nghĩa |
| --- | --- |
| `ACTIVE` | Phần ăn hợp lệ và được tính khi tổng hợp |
| `CANCELLED` | Đã hủy, không tính khi tổng hợp |

### Thanh toán

| Trạng thái | Ý nghĩa |
| --- | --- |
| `PAID_FUND` | Đã trừ đủ tiền từ quỹ |
| `PAID_EXTERNAL` | Admin đã nhận và xác nhận tiền bên ngoài |
| `UNPAID` | Đã giữ phần nhưng chưa thu đủ tiền |

### Giao dịch quỹ

| Loại | Hướng tiền | Ý nghĩa |
| --- | --- | --- |
| `TOP_UP` | Tăng | Admin ghi nhận tiền user đã nộp ngoài hệ thống |
| `ORDER_DEBIT` | Giảm | Trừ tiền cho một phần ăn |
| `ORDER_REFUND` | Tăng | Hoàn tiền khi hủy phần đã trả bằng quỹ |
| `ADMIN_ADJUSTMENT` | Tăng/giảm | Điều chỉnh có kiểm soát và bắt buộc có lý do |

## 10. Các tình huống biên cần xử lý

- **Không có menu hôm nay:** hiển thị trạng thái trống, không cho đặt.
- **Menu đã đóng hoặc hết giờ:** backend từ chối mọi thay đổi đơn, kể cả tab trình duyệt đã mở từ trước.
- **Hai người cùng đặt cho một người nhận:** chỉ một yêu cầu thành công; yêu cầu còn lại nhận lỗi xung đột.
- **Hai yêu cầu cùng dùng một số dư:** khóa/phiên giao dịch phải ngăn trừ quá số dư. Nếu chỉ đủ cho một phần thì phần còn lại là `UNPAID`, không làm số dư âm.
- **Gửi lặp do double-click/retry:** không được trừ quỹ hai lần hoặc tạo hai phần cho cùng người nhận.
- **Sửa món:** chỉ thay món/ghi chú trước cutoff; đơn giá và nguồn thanh toán của đơn không bị tính lại.
- **Hủy phần đã trả:** hoàn tiền đúng một lần; gọi hủy lại không hoàn thêm.
- **Xác nhận ngoài lặp lại:** không được đổi hoặc cộng/trừ quỹ thêm nếu đơn đã `PAID_EXTERNAL` hay `PAID_FUND`.
- **Nạp quỹ không hợp lệ:** từ chối số tiền bằng 0, số âm, user không tồn tại hoặc ghi chú vượt giới hạn.
- **Món trùng/khác menu/sai nhóm:** từ chối toàn bộ yêu cầu, không tạo đơn và không ghi giao dịch.
- **Tổng hợp nhiều lần:** cùng một tập đơn hoạt động phải cho cùng nội dung và số tiền; không phát sinh giao dịch tài chính.
- **Đơn chưa trả của ngày trước:** chặn phần ngày mới cho người nhận cho tới khi admin xác nhận tiền ngoài.
- **Lỗi giữa chừng:** tạo đơn và trừ/hoàn quỹ phải nằm trong cùng giao dịch; hoặc cùng thành công, hoặc cùng rollback.

## 11. API chính

Tất cả endpoint dùng prefix `/api` và yêu cầu JWT, trừ các endpoint đăng nhập/đăng ký chung của hệ thống.

### User

| Method | Endpoint | Mục đích |
| --- | --- | --- |
| `GET` | `/lunch/today` | Menu hôm nay, số dư và các phần user phụ trách |
| `GET` | `/lunch/people` | Danh sách người có thể đặt hộ |
| `GET` | `/lunch/orders/history` | Lịch sử phần ăn |
| `GET` | `/lunch/wallet/transactions` | Sổ giao dịch quỹ |
| `POST` | `/lunch/orders` | Tạo phần cho mình hoặc đồng nghiệp |
| `PUT` | `/lunch/orders/{id}` | Sửa món/ghi chú trước cutoff |
| `DELETE` | `/lunch/orders/{id}` | Hủy phần trước cutoff |

### Admin

| Method | Endpoint | Mục đích |
| --- | --- | --- |
| `GET` | `/lunch/admin/menus` | Tra cứu menu theo khoảng ngày |
| `POST` | `/lunch/admin/menus/import` | Import menu dạng văn bản |
| `GET` | `/lunch/admin/menus/{id}/orders` | Xem các phần của một menu |
| `POST` | `/lunch/admin/menus/{id}/close` | Đóng nhận đơn |
| `POST` | `/lunch/admin/menus/{id}/reopen` | Mở lại menu |
| `POST` | `/lunch/admin/menus/{id}/summarize` | Tổng hợp nội dung gửi quán |
| `GET` | `/lunch/admin/members` | Xem số dư và số đơn chưa trả của thành viên |
| `POST` | `/lunch/admin/funds/top-up` | Ghi nhận nạp quỹ |
| `POST` | `/lunch/admin/orders/{id}/confirm-external` | Xác nhận đã thu tiền ngoài |

