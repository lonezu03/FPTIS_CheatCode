# Yêu cầu và thiết kế: quản lý nhà trọ

Tài liệu này là đề xuất nghiệp vụ ban đầu để cùng rà soát. Các chi tiết về quy mô, phân quyền và cách tính phí cần được chủ trọ xác nhận trước khi dùng làm căn cứ triển khai chính thức.

## Phạm vi bản chạy cục bộ

Dự án độc lập dùng React, Node.js 23 và SQLite. Bản cục bộ đã có đăng nhập, chủ trọ độc lập, nhân viên được phân quyền theo khu và người thuê liên kết hồ sơ. Các mục bên dưới vẫn là yêu cầu và thiết kế đề xuất; xem README để biết những chức năng và giới hạn của bản chạy. Chưa sẵn sàng công khai Internet hoặc vận hành chính thức.

Trước khi triển khai Internet hoặc cho nhiều người dùng, cần bổ sung xác thực, phân quyền và phạm vi dữ liệu ở máy chủ, bảo vệ kết nối, quản lý phiên, sao lưu và khôi phục, nhật ký thay đổi, xử lý truy cập đồng thời và kiểm thử bảo mật. Không nhập dữ liệu cá nhân thật vào môi trường thử nghiệm không được bảo vệ.

## Mục tiêu và giả định

Chủ trọ theo dõi phòng, người thuê, hợp đồng, điện nước, hóa đơn và các khoản đã thu trên giao diện tiếng Việt, dùng được trên máy tính và điện thoại. Giả định có thể quản lý nhiều khu, mỗi phòng thuộc một khu; tiền tính bằng đồng Việt Nam; kỳ thu thường là một tháng. Chủ trọ hoặc nhân viên nhập và kiểm tra dữ liệu. Quyền truy cập của người thuê, số phòng, quy tắc làm tròn và phương thức tính phí thực tế chưa được xác nhận.

## Phạm vi nghiệp vụ đề xuất

| Phân hệ | Nhu cầu chính |
| --- | --- |
| Tổng quan | Xem số phòng trống/đang thuê, hợp đồng sắp hết hạn, tổng phải thu, đã thu và còn nợ theo khu và kỳ. |
| Khu và phòng | Lưu tên, địa chỉ khu; mã phòng duy nhất trong khu, giá niêm yết, trạng thái, ghi chú. Tìm kiếm và lọc theo khu, trạng thái. |
| Người thuê | Lưu họ tên, số điện thoại, thông tin liên hệ và ghi chú; theo dõi người đại diện và người ở cùng theo hợp đồng. |
| Hợp đồng | Gắn phòng với người đại diện, ngày bắt đầu/kết thúc, giá thuê, tiền cọc, ngày thu, quy tắc và đơn giá dịch vụ. Xem lịch sử và cảnh báo sắp hết hạn. |
| Chỉ số và dịch vụ | Nhập chỉ số đầu/cuối kỳ, đơn giá điện nước; hỗ trợ đề xuất các cách tính theo đồng hồ, theo người và cố định. Đơn giá áp dụng phải được lưu tại kỳ tính. |
| Hóa đơn | Tạo hóa đơn theo hợp đồng và kỳ, liệt kê tiền phòng, dịch vụ, điều chỉnh và hạn thanh toán; xem trước trước khi xác nhận. |
| Thu tiền và công nợ | Ghi nhận nhiều lần thanh toán, số tiền, ngày, phương thức và ghi chú; hiển thị số còn phải thu và lịch sử. |
| Báo cáo | Tổng phải thu, tiền thực thu, công nợ và tỷ lệ lấp đầy theo kỳ/khu; phân biệt tiền cọc với doanh thu thuê phòng. |

## Luồng sử dụng

1. Tạo khu và phòng, cấu hình giá thuê và các dịch vụ áp dụng.
2. Thêm người thuê, lập hợp đồng với phòng trống và ghi nhận tiền cọc theo thực tế.
3. Đến kỳ, nhập chỉ số hoặc số lượng dịch vụ; xem trước chi tiết hóa đơn và xác nhận phát hành.
4. Ghi nhận từng lần thu; hệ thống tính số còn nợ, cập nhật trạng thái và báo cáo.
5. Khi kết thúc thuê, đối chiếu hóa đơn, tiền cọc và tình trạng phòng; lưu lịch sử và đưa phòng về trạng thái phù hợp.

## Quy tắc và trường hợp cần xử lý

- Không để hai hợp đồng đang hiệu lực chồng lấn thời gian cho cùng một phòng. Không xóa phòng hay người thuê nếu làm mất lịch sử tài chính; ưu tiên ngừng hoạt động hoặc lưu trữ.
- Chỉ số cuối không nhỏ hơn chỉ số đầu thông thường; thay hoặc đặt lại đồng hồ cần quy trình điều chỉnh có lý do. Mức tiêu thụ bằng chỉ số cuối trừ chỉ số đầu.
- Mỗi hóa đơn ghi lại tên khoản thu, số lượng, đơn giá và thành tiền tại thời điểm lập để thay đổi giá về sau không sửa lại lịch sử. Tổng phải thu bằng tổng khoản thu cộng điều chỉnh tăng trừ giảm giá.
- Số đã thu là tổng các lần thanh toán còn hiệu lực; số còn nợ bằng tổng phải thu trừ số đã thu. Đề xuất không nhận thanh toán vượt số phải thu cho đến khi có quy định xử lý tiền thừa.
- Trạng thái đề xuất: hóa đơn nháp, chưa thanh toán, thanh toán một phần, đã thanh toán, hủy. Quá hạn là chỉ báo tính từ hạn thanh toán và số còn nợ, không tự xóa lịch sử.
- Tiền cọc được theo dõi riêng; hoàn hoặc khấu trừ khi thanh lý cần ghi rõ lý do và số tiền. Cách tính ngày lẻ, phí trả phòng sớm và xử lý khoản thừa phải được thống nhất trước khi tự động hóa.
- Hóa đơn đã phát hành và thanh toán cần có lịch sử điều chỉnh/hủy và người thực hiện. Phải tránh tạo trùng hóa đơn cùng hợp đồng và kỳ; thao tác lưu lặp không được tạo khoản thu trùng.
- Thông tin cá nhân chỉ hiển thị cho người có quyền phù hợp. Phân quyền chủ trọ/nhân viên và truy cập của người thuê cần chốt theo mô hình sử dụng thực tế.

## Mô hình dữ liệu khái niệm

| Đối tượng | Thuộc tính chính | Quan hệ |
| --- | --- | --- |
| Khu trọ | Tên, địa chỉ, trạng thái | Một khu có nhiều phòng. |
| Phòng | Mã, giá niêm yết, trạng thái, ghi chú | Thuộc một khu; có nhiều hợp đồng theo thời gian. |
| Người thuê | Họ tên, điện thoại, liên hệ | Có thể tham gia nhiều hợp đồng theo thời gian. |
| Hợp đồng | Thời hạn, giá thuê, tiền cọc, trạng thái | Thuộc một phòng; có người đại diện và danh sách người ở. |
| Dịch vụ/hạng mục giá | Tên, phương thức tính, đơn giá | Áp dụng theo hợp đồng hoặc cấu hình khu. |
| Chỉ số kỳ | Kỳ, chỉ số đầu/cuối, đơn giá | Gắn hợp đồng/phòng và loại đồng hồ. |
| Hóa đơn và dòng hóa đơn | Kỳ, hạn trả, trạng thái; mô tả, số lượng, đơn giá | Một hợp đồng có nhiều hóa đơn; một hóa đơn có nhiều dòng. |
| Thanh toán | Số tiền, ngày thu, phương thức, trạng thái | Nhiều thanh toán có thể thuộc một hóa đơn. |
| Giao dịch cọc | Số tiền, loại thu/hoàn/khấu trừ, ngày, lý do | Gắn hợp đồng và lưu riêng lịch sử cọc. |

## Thiết kế màn hình

- **Tổng quan:** bộ lọc khu/kỳ, thẻ phòng trống và công nợ, danh sách việc cần xử lý, lối tắt tạo hóa đơn và ghi thu.
- **Phòng:** danh sách hoặc thẻ phòng với mã, giá, trạng thái và người thuê; chọn phòng để xem hợp đồng và lịch sử.
- **Người thuê và hợp đồng:** bảng tìm kiếm, trang chi tiết và biểu mẫu tạo/sửa; nêu rõ ngày, giá, cọc, người ở và điều kiện dịch vụ.
- **Điện nước:** bảng nhập theo kỳ với chỉ số trước, chỉ số mới, mức dùng và cảnh báo dữ liệu bất thường.
- **Hóa đơn:** danh sách lọc theo kỳ, khu, trạng thái; chi tiết các dòng phí, tổng cộng, các lần thanh toán và số còn nợ.
- **Báo cáo:** bộ lọc kỳ/khu, tổng phải thu, thực thu, nợ và tỷ lệ phòng có người thuê; có giải thích cách tính.

Trên điện thoại, thanh điều hướng chuyển sang menu gọn; bảng dài chuyển sang thẻ hoặc cho phép cuộn ngang. Biểu mẫu phải có nhãn rõ ràng, báo lỗi tại trường và thông báo kết quả lưu.

## Tiêu chí nghiệm thu cốt lõi

1. Tạo khu, phòng và hợp đồng hợp lệ; hệ thống ngăn hợp đồng trùng phòng trong khoảng thời gian chồng lấn.
2. Nhập điện đầu 100, cuối 150 với giá 3.000 đ/kWh: dòng điện là 150.000 đ; từ chối chỉ số cuối 90 nếu không có quy trình điều chỉnh.
3. Hóa đơn 3.150.000 đ ghi thu 1.000.000 đ rồi 2.150.000 đ lần lượt hiển thị còn nợ 2.150.000 đ và 0 đ; trạng thái phản ánh đúng.
4. Thay giá dịch vụ sau khi phát hành không đổi các dòng và tổng hóa đơn cũ; không tạo hai hóa đơn cho cùng hợp đồng và kỳ.
5. Kết thúc hợp đồng vẫn xem được hóa đơn, các khoản thu và lịch sử cọc; báo cáo phân biệt tiền cọc với doanh thu.
6. Quyền truy cập và dữ liệu được kiểm tra phía máy chủ khi triển khai nhiều tài khoản; người không có quyền không thể đọc hoặc thay đổi dữ liệu bằng cách gọi API trực tiếp.
7. Kiểm tra giao diện ở màn hình điện thoại và máy tính, gồm trường hợp chưa có dữ liệu, lỗi nhập, tải chậm và lưu thất bại.

## Cần xác nhận trước khi vận hành

- Có bao nhiêu khu/phòng? Một chủ sở hữu hay nhiều chủ sở hữu độc lập?
- Chỉ chủ trọ, nhân viên hay cả người thuê đăng nhập? Mỗi vai trò được xem và sửa những gì?
- Điện, nước và dịch vụ tính theo đồng hồ, theo người, cố định hay kết hợp? Kỳ chốt, đơn giá, làm tròn và cách tính ngày lẻ là gì?
- Quy trình phát hành/sửa/hủy hóa đơn, hoàn cọc, ghi thu thừa và xử lý nợ khi trả phòng ra sao?
- Cần gửi hóa đơn, xuất tệp, sao lưu, báo cáo chi phí hoặc tích hợp thanh toán ở giai đoạn nào?
