# Quy trình đặt cơm và quản lý quỹ

## 1. Mục tiêu

Module đặt cơm chuyển quy trình đang làm thủ công thành một luồng có thể kiểm tra và đối soát:

1. Quán gửi thực đơn dạng văn bản cho admin.
2. Admin import thực đơn, ngày áp dụng, giờ chốt và đơn giá.
3. Nhân viên chọn món cho mình hoặc đặt hộ đồng nghiệp.
4. Hệ thống dùng quỹ của người nhận phần ăn; nếu không đủ thì dùng hết số dư và ghi phần thiếu vào công nợ của người nhận.
5. Khi hết giờ nhận đơn, admin đóng đơn, tổng hợp nội dung và copy gửi quán.
6. Admin ghi nhận tiền đã nhận ngoài hệ thống và xác nhận các đơn chưa thanh toán.

Tiền trong module được lưu theo số nguyên Việt Nam đồng. Đơn giá mặc định của một phần là **35.000đ**, nhưng admin có thể đặt đơn giá khác khi import từng ngày.

## 2. Vai trò

### User

- Xem thực đơn hôm nay, giờ chốt và đơn giá.
- Tạo một hoặc nhiều phần cho bản thân trong cùng một lần đặt.
- Đặt nhiều phần hộ đồng nghiệp mà không cần đủ quỹ cá nhân; chi phí luôn thuộc tài khoản của từng người nhận.
- Sửa hoặc hủy phần mình phụ trách trước giờ chốt.
- Xem lịch sử đơn, trạng thái thanh toán, số dư và sổ giao dịch quỹ.
- Theo dõi rõ ai là người thao tác đặt hộ và ai là người nhận/chịu chi phí.

### Admin

Admin có toàn bộ quyền của user và thêm các quyền:

- Import một hoặc nhiều bộ thực đơn trong cùng một ngày; mỗi menu có admin tạo/điều phối riêng.
- Sửa toàn bộ danh sách món hoặc xóa menu nháp để import lại trước khi có đơn.
- Chọn nhãn đơn, tên quán, ngày áp dụng, giờ chốt và đơn giá cơ bản; thêm đồ uống/món lẻ có đơn giá riêng.
- Đóng đơn sớm hoặc mở lại đơn.
- Xem tất cả phần ăn và các đơn chưa thanh toán.
- Tổng hợp, copy nội dung gửi quán và xem số lượng theo từng món.
- Nhận tiền mặt/chuyển khoản ở bên ngoài rồi nạp quỹ cho user.
- Xác nhận một đơn chưa thanh toán đã được thu tiền bên ngoài.

Danh sách admin được cấu hình bằng biến môi trường `ADMIN_EMAILS`; xem phần cấu hình trong README.

## 3. Import thực đơn và ý nghĩa dấu `+`

Admin dán nguyên văn thực đơn quán gửi. Mỗi dòng không rỗng là một món. Dòng chỉ chứa ký tự `+` là ranh giới giữa hai nhóm. Có thể thêm section `@DRINKS` hoặc `@EXTRAS` cho món thêm/đồ uống có giá riêng:

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
@DRINKS
Trà đào | 45000
Trà vải 50000
```

Quy tắc parse:

- Bỏ qua dòng trống và khoảng trắng thừa ở đầu/cuối dòng.
- Gộp nhiều khoảng trắng liên tiếp trong tên món thành một khoảng trắng.
- Dấu `+` phải nằm trên một dòng riêng và chỉ được xuất hiện tối đa một lần.
- Nếu không có dấu `+`, tất cả món đều thuộc nhóm món thường.
- Không chấp nhận tên món trùng nhau, không phân biệt chữ hoa/chữ thường.
- Nếu có dấu `+`, phía sau phải có ít nhất một món đặc biệt; section `@DRINKS`/`@EXTRAS` nên đặt sau nhóm này.
- Món trong section extra phải có giá dương theo dạng `Tên món | 45000` hoặc `Tên món 45000`.
- Nhóm món thường có đúng một món là không hợp lệ vì không thể tạo phần hai món. Extra là món thêm đi kèm ít nhất một món cơm hoặc món đơn; menu chỉ có đồ uống mà không có base meal sẽ bị từ chối.
- Tên món không được trùng, kể cả khác nhóm.
- Một ngày có thể có nhiều menu mở đồng thời. User sẽ chọn bộ menu theo tên quán/nhãn đơn/admin điều phối; nếu chỉ có một menu, giao diện giữ nguyên UX cũ.

Khi import thành công, thực đơn ở trạng thái `OPEN`. Tuy nhiên, user chỉ đặt được khi thực đơn vừa `OPEN` vừa chưa tới `cutoffAt`.

### Sửa, xóa và import lại menu

- Admin có thể thay thế ngày, giờ chốt, tên quán, giá và toàn bộ danh sách món của menu đã import bằng **Sửa menu**.
- Admin có thể xóa menu nháp để import lại từ đầu.
- Hai thao tác này chỉ được thực hiện khi menu chưa phát sinh bất kỳ đơn nào và chưa được tổng hợp. Điều này bảo toàn lịch sử món đã chọn, công nợ, giao dịch quỹ và dữ liệu dinh dưỡng.
- Khi thay menu nháp đã đóng thủ công, hệ thống mở lại menu nếu giờ chốt mới vẫn còn trong tương lai; admin không cần mở lại lần thứ hai.
- Sau khi có đơn, admin vẫn có thể chỉnh tên/ảnh/dinh dưỡng từng món; thay đổi cấu trúc trước/sau dấu `+` phải bị chặn.

## 4. Quy tắc chọn món

User chọn đúng một trong hai loại phần:

| Loại | Mã | Quy tắc |
| --- | --- | --- |
| Cơm hai món | `COMBO` | Chọn đúng 2 lượt món trong nhóm trước dấu `+`; cùng một món được chọn 2 lần |
| Món đơn | `SINGLE` | Chọn đúng 1 món trong nhóm sau dấu `+` |

Không được:

- Chọn quá 2 lượt món cơm cho một phần.
- Ghép một món thường với một món đặc biệt trong phần cơm.
- Chọn hai món đặc biệt cho một phần.
- Chọn extra không thuộc menu hoặc extra chưa có giá.
- Gửi ID món thuộc thực đơn khác hoặc món không còn tồn tại.

User có thể thêm ghi chú như `cơm thêm + rau thêm`. Ghi chú được làm sạch khoảng trắng, giới hạn 500 ký tự và được đặt trong ngoặc ở nội dung gửi quán.

## 5. Đặt cho mình và đặt hộ

Ba khái niệm được lưu riêng:

- **Người nhận (`beneficiary`)**: người có phần ăn.
- **Người tạo đơn (`orderedBy`)**: người thao tác đặt.
- **Người trả (`payer`)**: chủ tài khoản quỹ/công nợ chịu chi phí. Với mọi đơn mới, đây luôn là người nhận.

### Đặt cho bản thân

Nếu user không chọn đồng nghiệp, cả ba vai trò là chính user đó. Một user có thể có nhiều phần đang hoạt động trong một thực đơn; mỗi phần là một đơn độc lập để dễ sửa, hủy, tính nợ và tổng hợp.

### Đặt hộ đồng nghiệp

Nếu user A chọn user B làm người nhận:

- B là người nhận phần ăn.
- A chỉ là người tạo đơn (`orderedBy`); quỹ và công nợ của A không bị thay đổi và không được dùng làm điều kiện chặn đơn.
- B đồng thời là người nhận và người trả (`beneficiary = payer`).
- Hệ thống trừ đúng tổng giá phần cơ bản và các extra từ quỹ của B; nếu thiếu thì ghi phần thiếu vào công nợ của B.
- B có thể nhận nhiều phần trong ngày. Mỗi phần được lưu, tính tiền và tạo giao dịch riêng.
- Quy tắc mới áp dụng cho đơn tạo mới. Đơn lịch sử vẫn hoàn tiền về `payer` đã lưu để bảo toàn sổ cái.

## 6. Quỹ và trạng thái thanh toán

### Nạp quỹ

Hệ thống không trực tiếp thu tiền. Quy trình nạp quỹ là:

1. User đưa tiền mặt hoặc chuyển khoản cho admin ở bên ngoài.
2. Admin chọn đúng user, nhập số tiền dương và ghi chú đối soát.
3. Hệ thống tăng số dư và tạo giao dịch `TOP_UP`.

Nạp quỹ không tự động đổi trạng thái một đơn `UNPAID` cũ. Admin phải xác nhận khoản thu ngoài cho đúng đơn để tránh vừa tăng quỹ vừa tính đơn đó là đã trả.

### Hạch toán một phần ăn

Nếu quỹ của người nhận lớn hơn hoặc bằng tổng giá phần (`giá cơ bản + tổng giá extra`):

- Trừ toàn bộ tổng giá trong một giao dịch `ORDER_DEBIT`.
- Không trừ từng phần và không cho số dư âm.
- Đơn nhận trạng thái `PAID_FUND`.
- Giao dịch lưu số dư sau giao dịch và liên kết tới đơn để đối soát.

Với đơn giá mặc định, số dư thay đổi như sau:

```txt
100.000đ - 35.000đ = 65.000đ
```

### Không đủ quỹ

Nếu số dư của người nhận nhỏ hơn tổng giá phần:

- Hệ thống vẫn tạo và giữ phần ăn, kể cả người nhận đang có công nợ cũ.
- Dùng hết số dư dương hiện có, giữ số dư ở `0` và cộng phần thiếu vào công nợ; không tạo số dư âm.
- Đơn vẫn nhận trạng thái `PAID_FUND` vì toàn bộ giá trị đã được hạch toán vào sổ quỹ/công nợ bằng giao dịch `ORDER_DEBIT`.
- Người nhận vẫn được đặt tiếp vào ngày sau; mỗi đơn tiếp tục cộng vào công nợ.
- Admin có thể ghi nhận nạp quỹ hoặc thanh toán nợ sau khi đã đối soát tiền bên ngoài.

### Hủy đơn

- Chỉ được hủy trước giờ chốt và khi menu còn nhận đơn.
- Đơn chuyển từ `ACTIVE` sang `CANCELLED`; dữ liệu cũ được giữ để kiểm tra.
- Nếu đơn đã `PAID_FUND`, hệ thống hoàn đúng giá trị đã hạch toán cho `payer` đã lưu bằng giao dịch `ORDER_REFUND`: giảm công nợ trước, phần còn lại mới cộng vào quỹ.
- Nếu đơn là `UNPAID`, không phát sinh hoàn quỹ.
- Hủy chỉ tác động đến đúng phần được chọn; các phần khác của cùng người nhận vẫn giữ nguyên.

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
2. Kiểm tra tổng số phần, công nợ phát sinh và các đơn `UNPAID` cũ (nếu có).
3. Bấm **Tổng hợp**.
4. Copy nội dung đã sinh và gửi quán.
5. Không sửa dữ liệu sau khi đã gửi quán; nếu bắt buộc thay đổi, admin phải đối soát lại với quán và tổng hợp lại.

## 8. Tổng hợp và copy gửi quán

Tổng hợp chỉ lấy các đơn `ACTIVE`; đơn `CANCELLED` không được tính. Kết quả gồm:

- Tổng số phần.
- Số đơn `PAID_FUND`, `PAID_EXTERNAL` và `UNPAID`.
- Tổng tiền bằng tổng giá cơ bản của từng phần cộng giá từng extra; mỗi extra lặp lại được tính theo số lượng.
- Số lượng xuất hiện của từng món và đồ uống.
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

Thao tác tổng hợp không phải là thao tác thu tiền. Đơn mới thiếu quỹ vẫn có trạng thái `PAID_FUND` vì giá trị đã chuyển vào công nợ; các đơn `UNPAID` cũ vẫn xuất hiện trong danh sách gửi quán và cần admin đối soát riêng.

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
| `PAID_FUND` | Đã hạch toán đủ giá trị vào quỹ/công nợ của `payer` |
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
- **Hai người cùng đặt cho một người nhận:** cả hai phần có thể được tạo; mỗi phần hạch toán riêng vào cùng tài khoản người nhận dưới khóa giao dịch.
- **Hai yêu cầu cùng dùng một số dư:** khóa/phiên giao dịch phải dùng số dư tuần tự; phần thiếu của yêu cầu sau được cộng vào công nợ, không làm số dư âm.
- **Gửi lặp do double-click/retry:** cùng `clientRequestId` phải trả lại batch cũ, không trừ quỹ hoặc tạo phần lần hai.
- **Sửa món:** chỉ thay món/ghi chú trước cutoff; thêm/bớt extra phải ghi thêm `ORDER_DEBIT` hoặc `ORDER_REFUND` cho `payer` đã lưu.
- **Hủy phần đã trả:** hoàn tiền đúng một lần; gọi hủy lại không hoàn thêm.
- **Xác nhận ngoài lặp lại:** không được đổi hoặc cộng/trừ quỹ thêm nếu đơn đã `PAID_EXTERNAL` hay `PAID_FUND`.
- **Nạp quỹ không hợp lệ:** từ chối số tiền bằng 0, số âm, user không tồn tại hoặc ghi chú vượt giới hạn.
- **Món trùng/khác menu/sai nhóm:** từ chối toàn bộ yêu cầu, không tạo đơn và không ghi giao dịch.
- **Tổng hợp nhiều lần:** cùng một tập đơn hoạt động phải cho cùng nội dung và số tiền; không phát sinh giao dịch tài chính.
- **Công nợ hoặc đơn chưa trả của ngày trước:** không chặn phần mới; giá trị mới tiếp tục được hạch toán vào quỹ/công nợ của người nhận.
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
| `POST` | `/lunch/orders` | Tạo một phần cho mình hoặc đồng nghiệp |
| `POST` | `/lunch/orders/batch` | Tạo nhiều phần trong một giao dịch nguyên tử |
| `PUT` | `/lunch/orders/{id}` | Sửa món/ghi chú trước cutoff |
| `DELETE` | `/lunch/orders/{id}` | Hủy phần trước cutoff |

### Admin

| Method | Endpoint | Mục đích |
| --- | --- | --- |
| `GET` | `/lunch/admin/menus` | Tra cứu menu theo khoảng ngày |
| `POST` | `/lunch/admin/menus/import` | Import menu dạng văn bản |
| `PUT` | `/lunch/admin/menus/{id}` | Thay thế menu nháp trước khi có đơn |
| `DELETE` | `/lunch/admin/menus/{id}` | Xóa menu nháp trước khi có đơn |
| `GET` | `/lunch/admin/menus/{id}/orders` | Xem các phần của một menu |
| `POST` | `/lunch/admin/menus/{id}/close` | Đóng nhận đơn |
| `POST` | `/lunch/admin/menus/{id}/reopen` | Mở lại menu |
| `POST` | `/lunch/admin/menus/{id}/summarize` | Tổng hợp nội dung gửi quán |
| `GET` | `/lunch/admin/members` | Xem số dư và số đơn chưa trả của thành viên |
| `POST` | `/lunch/admin/funds/top-up` | Ghi nhận nạp quỹ |
| `POST` | `/lunch/admin/orders/{id}/confirm-external` | Xác nhận đã thu tiền ngoài |
