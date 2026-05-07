SELECT * FROM dbo.SYS_tblAutoService_Action WHERE Action = 1

Ghi chú so sánh 2 store GetDataExport:
- Về câu lệnh SELECT đầu tiên (phần tổng hợp theo LSOfficeTypeID, LSLevel1ID): hai file hoàn toàn giống nhau về cột, công thức SUM, bảng, điều kiện WHERE và ORDER BY; chỉ khác nhau về khoảng trắng/thụt lề (format code).
- Về câu lệnh SELECT thứ hai (phần tổng hợp S_M, S_F, E_M, E_F theo [Rank]): hai file cũng giống nhau hoàn toàn về UNION ALL, điều kiện LSContractTypeCode, các điều kiện HAVING COUNT(AA.ContractID), JOIN với HR_tblContract, LS_tblContractType, LS_tblContractTypeGroup và ORDER BY A.[Rank]; chỉ khác nhau ở cách xuống dòng và căn lề "FROM (" và "ORDER BY".
- Các giá trị literal (mã hợp đồng như 'HDKXDTH', 'HD03', 'HD04', 'HD05', 'HDLDCT', 'HDTV', 'HD12', 'HD11', 'HD10', 'NHD03') đều giống nhau.
- Các biểu thức tính toán (S_NVCT, S_NVTVU, S_M, S_F, E_M, E_F, S_TT, E_TT) đều giống về công thức và điều kiện.
Kết luận: Hai store trên là tương đương về mặt logic/thực thi, chỉ khác nhau về định dạng mã nguồn (khoảng trắng, thụt lề, vị trí xuống dòng).
