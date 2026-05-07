USE [iHRP_V34_KPMG]
GO
/****** Object:  StoredProcedure [dbo].[HR_spfrmNews_Approve]    Script Date: 3/13/2026 4:37:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [dbo].[HR_spfrmNews_Approve]
-- Add the parameters for the stored procedure here
@Activity		nvarchar(50) = 'GetList',
@UserGroupID nvarchar(50) = null,
@FunctionID		nvarchar(50) = null,
@EmpID int = null,
@LanguageID		nvarchar(2)	 = 'VN',
@FromDate		nvarchar(12) = null,
@ToDate			nvarchar(12) = null,
@ReturnMess		nvarchar(4000)=null out,
--rlogID:7512
@EmpCode			nvarchar(100) = null,
@EmpName			nvarchar(4000) = null,
@LSCompanyID int = null,
@LSLevel1ID int = null,
@LSLevel2ID int = null,
@LSLevel3ID int = null,
@LSLevel4ID int = null,
@LSLevel5ID int = null,
@LSLevel6ID int = null,
@LSLevel7ID int = null,
@LSLevel8ID int = null,
@LSLevel9ID int = null,
@LSLocationID int = null,
@LSJobTitleID int = null,
@Status				nvarchar(2) = null,
@LSLoaiHinhNhanVienID int = null,
--Hlevel
@LSHLevel1ID int = null,
@LSHLevel2ID int = null,
@LSHLevel3ID int = null,
@LSHLevel4ID int = null,
@LSHLevel5ID int = null,
@LSHLevel6ID int = NULL
,@LoaiThongTinThayDoiID NVARCHAR(12) = NULL /*11540*/
,@TinhTrangSoatXetID NVARCHAR(12) = NULL /*RlogID 24215 - MESSER*/

--rlogID:12143
,@CountValue  int =null out
,@IsWarningList int =0
-------------------
,@IsListApprove					NVARCHAR(1) = NULL	/**Rlog 22588 -Lấy số lượng Remind cho MyPage*/
,@ReturnCountRemind				INT = NULL OUT		/**Rlog 22588 - Trả về số lượng Remind cho MyPage*/
AS
BEGIN	
	declare @dFromDate datetime, @dToDate datetime
	
	set @dFromDate = convert(datetime, case when isnull(@FromDate, '') = '' then '01/01/1900' else @FromDate end, 103)
	set @dToDate = convert(datetime, case when isnull(@ToDate, '') = '' then '01/01/2500' else @ToDate end, 103)

	Declare @PhanQuyenTTThayDoiTheoNhomNguoiDung bit 
	/*Start Rlog: 15905 - EIB - NhanHM4 - 01/03/2021*/
	DECLARE @ChoPhepChuyenVaPheDuyetThongTinCaNhanTungDong BIT
	/*End   Rlog: 15905 - EIB - NhanHM4 - 01/03/2021*/

	select @PhanQuyenTTThayDoiTheoNhomNguoiDung= ISNULL(PhanQuyenTTThayDoiTheoNhomNguoiDung, 0), 
	@ChoPhepChuyenVaPheDuyetThongTinCaNhanTungDong = ISNULL(ChoPhepChuyenVaPheDuyetThongTinCaNhanTungDong,0) from HR_tblSetupHR(NOLOCK)
	
	/*RlogID 22501 - SVFC*/
	Declare @hascat bit = 0
	if exists(select top 1 1 from LS_tblCauHinhTabThongTinNhanVien) set @hascat = 1
	/*RlogID 22501 - SVFC*/
	--1 Ly lich ca nhan
	--2 Thong tin nguoi than
	--3 Bang cap
	--4 Qua trinh lam viec truoc
	--5 TT nguoi nguocngoai
	--6 Thong tin suc khoe
	--7 Hoat dong xa hoi
	--8 Ho so luu tru
	--9 Quá trình làm việc
	
	--TuuPNQ: 26.06.2017 đưa vào bảng tạm để tăng tốc xử lý (không bị mất index)
	/*RlogID 22501 - SVFC: Bổ sung thêm cột ShowName để map tên ở MH cấu hình tab hiển thị*/
	SELECT A.*
	INTO #TempData
	FROM
	(
		select distinct EmpID,case when @hascat = 1 then N'LLCN' else '' end as ShowName, 1 as Loai, 
		SendDate, 156124 as FunctionID, NULL AS ChonTabCoDuLieu, CONVERT(NVARCHAR(10), EditTime, 103) AS EditTime, TinhTrangSoatXetID, User_SoatXet, Ngay_SoatXet from HR_tblEmpCV_CapNhat(NoLock) where RecordStatus=2 and (IsMobile is null or IsMobile = 0)
		union all
		select distinct EmpID, case when @hascat = 1 then N'NguoiThan' else '' end as ShowName, 2 as Loai,
		SendDate, 156125 as FunctionID, NULL AS ChonTabCoDuLieu, CONVERT(NVARCHAR(10), EditTime, 103) AS EditTime, TinhTrangSoatXetID, User_SoatXet, Ngay_SoatXet from HR_tblRelative_CapNhat(NoLock) where RecordStatus=2 and (IsMobile is null or IsMobile = 0)
		union all
		select distinct EmpID, case when @hascat = 1 then N'BCCC' else '' end as ShowName, 3 as Loai,
		SendDate, 156126 as FunctionID, NULL AS ChonTabCoDuLieu, CONVERT(NVARCHAR(10), EditTime, 103) AS EditTime, TinhTrangSoatXetID, User_SoatXet, Ngay_SoatXet from HR_tblQualification_CapNhat(NoLock) where RecordStatus=2 and (IsMobile is null or IsMobile = 0)
		union all
		select distinct EmpID, case when @hascat = 1 then N'KNLV' else '' end as ShowName, 4 as Loai,
		SendDate, 156128 as FunctionID, NULL AS ChonTabCoDuLieu, CONVERT(NVARCHAR(10), EditTime, 103) AS EditTime, TinhTrangSoatXetID, User_SoatXet, Ngay_SoatXet from HR_tblWorkingBackground_CapNhat(NoLock) where RecordStatus=2 and (IsMobile is null or IsMobile = 0)
		union all
		select distinct EmpID, case when @hascat = 1 then N'VisaPassport' else '' end as ShowName, 5 as Loai,
		SendDate, 156127 as FunctionID, Type AS ChonTabCoDuLieu, CONVERT(NVARCHAR(10), EditTime, 103) AS EditTime, TinhTrangSoatXetID, User_SoatXet, Ngay_SoatXet from HR_tblPassPortVisa_CapNhat(NoLock) where RecordStatus=2 and (IsMobile is null or IsMobile = 0)
		union all
		select distinct EmpID, case when @hascat = 1 then N'ThongTinSucKhoe' else '' end as ShowName, 6 as Loai,
		SendDate, 156129 as FunctionID, NULL AS ChonTabCoDuLieu, CONVERT(NVARCHAR(10), EditTime, 103) AS EditTime, TinhTrangSoatXetID, User_SoatXet, Ngay_SoatXet from HR_tblHealthcareRecord_CapNhat(NoLock) where RecordStatus=2
		union all
		select distinct A.EmpID, case when @hascat = 1 then N'HoatDongXH' else '' end as ShowName, 7 as Loai,
		A.SendDate, 156130 as FunctionID, NULL AS ChonTabCoDuLieu, CONVERT(NVARCHAR(10), A.EditTime, 103) AS EditTime, NULL, NULL, NULL
		from HR_tblEmpOther_CapNhat(NoLock) A 
		left join HR_tblEmpCV_CapNhat(NoLock) B on A.EmpID = B.EmpID
		where A.RecordStatus=2 and (B.IsMobile is null or B.IsMobile = 0)
		union all
		select distinct EmpID, case when @hascat = 1 then N'HoSoLuuTru' else '' end as ShowName, 8 as Loai,
		SendDate, 156134 as FunctionID, NULL AS ChonTabCoDuLieu, CONVERT(NVARCHAR(10), EditTime, 103) AS EditTime, TinhTrangSoatXetID, User_SoatXet, Ngay_SoatXet from HR_tblEmpDocument_CapNhat(NoLock) where RecordStatus=2
		union all
		select distinct EmpID, case when @hascat = 1 then N'QTLV' else '' end as ShowName,9 as Loai, 
		SendDate, 1498 as FunctionID, NULL AS ChonTabCoDuLieu, CONVERT(NVARCHAR(10), EditTime, 103) AS EditTime, NULL, NULL, NULL from HR_tblWorkingRecord_CapNhat(NoLock) where RecordStatus=2
		union all
		select distinct EmpID, case when @hascat = 1 then N'KyLuatKhenThuong' else '' end as ShowName, 10 as Loai,
		SendDate, 2563 as FunctionID, NULL AS ChonTabCoDuLieu, CONVERT(NVARCHAR(10), EditTime, 103) AS EditTime, NULL, NULL, NULL from HR_tblThanhTich_CapNhat(NoLock) where Status=2
		union all
		--RlogID: 11541
		select distinct EmpID, case when @hascat = 1 then N'TKCT' else '' end as ShowName, 11 as Loai,
		ApprovedDate, 3241 as FunctionID, NULL AS ChonTabCoDuLieu, CONVERT(NVARCHAR(10), EditTime, 103) AS EditTime, NULL, NULL, NULL from HR_tblDetailAccountNumber_CapNhat(NoLock) where RecordStatus=2--
	) A
	
	--RlogID: 11542
	select Distinct T1.FunctionID
	into #Tbl_PQNhomNguoiDung_LoaiThongTinThayDoi
	from SYS_tblPhanQuyenNhomNguoiDungTheoLoaiThongTinThayDoi (nolock) T1
	left join UMS_tblUserGroup (nolock) T2 on T1.GroupID = T2.GroupID
	where T2.UserID = @UserGroupID

	 /**Bổ sung thêm trường hợp nếu là GroupAdmin của Khách hàng - HomeCredit - TuuPNQ@FPT.COM.VN**/
	DECLARE @GroupID nvarchar(50)
	select @GroupID = GroupID
	from UMS_tblUserGroup (nolock) 
	where UserID = @UserGroupID
	if @IsWarningList=1
	begin
			select	@CountValue = count(*)
			from #TempData(nolock)  tblNews
				inner join dbo.fnGetAllEmp_Permission(@UserGroupID, @FunctionID) PQ on PQ.EmpID = tblNews.EmpID -- phan quyen du lieu
				left join #Tbl_PQNhomNguoiDung_LoaiThongTinThayDoi(nolock)  PQ1 on PQ1.FunctionID = tblNews.FunctionID
			where 1=1
			and (@PhanQuyenTTThayDoiTheoNhomNguoiDung = 0 or PQ1.FunctionID Is not null or @UserGroupID = 'admin' or /**Bổ sung thêm trường hợp nếu là GroupAdmin của Khách hàng - HomeCredit - TuuPNQ@FPT.COM.VN**/@GroupID = 'admin')

			select @CountValue CountEmp
	end
	else
	BEGIN
		IF @ChoPhepChuyenVaPheDuyetThongTinCaNhanTungDong = 1
		BEGIN
			DECLARE @tEmp tEmp
			
			INSERT INTO @tEmp(EmpID)
			SELECT DISTINCT(PQ.EmpID) AS EmpID
			FROM dbo.fnGetAllEmp_Permission(@UserGroupID, @FunctionID) PQ 
			INNER JOIN #TempData(NOLOCK) tblNews on PQ.EmpID = tblNews.EmpID -- phan quyen du lieu
			left join #Tbl_PQNhomNguoiDung_LoaiThongTinThayDoi(nolock) PQ1 on PQ1.FunctionID = tblNews.FunctionID
			left join HR_vEmp(NoLock) D on PQ.EmpID = D.EmpID	
			where 1 = 1
			AND (SendDate between @dFromDate and @dToDate + 1)
			and (@EmpCode = '' or @EmpCode is null or D.EmpCode like N'%' + @EmpCode + '%')
			and (@EmpName = '' or @EmpName is null or D.EmpName like N'%' + @EmpName + '%' or D.EmpName_Unsign like N'%'+ @EmpName +'%')	
			and (@LSLevel1ID is null  or D.LSLevel1ID = @LSLevel1ID)
			and (@LSLevel2ID is null or D.LSLevel2ID = @LSLevel2ID)
			and (@LSLevel3ID is null or D.LSLevel3ID = @LSLevel3ID)
			and (@LSLevel4ID is null or D.LSLevel4ID = @LSLevel4ID)
			and (@LSLevel5ID is null or D.LSLevel5ID = @LSLevel5ID)
			and (@LSLevel6ID is null or D.LSLevel6ID = @LSLevel6ID)
			and (@LSLevel7ID is null or D.LSLevel7ID = @LSLevel7ID)
			and (@LSLevel8ID is null or D.LSLevel8ID = @LSLevel8ID)
			and (@LSLevel9ID is null or D.LSLevel9ID = @LSLevel9ID)
			and (@LSCompanyID is null or D.LSCompanyID = @LSCompanyID)
			and (@LSLocationID is null or D.LSLocationID = @LSLocationID)
			and (@LSJobTitleID is null or D.LSJobTitleID = @LSJobTitleID)
			and (D.Status = @Status or @Status = '2' or @Status is null)			
			and (@LSLoaiHinhNhanVienID is null or D.LSLoaiHinhNhanVienID = @LSLoaiHinhNhanVienID)
			and (@LSHLevel1ID is null or D.LSHLevel1ID = @LSHLevel1ID)
			and (@LSHLevel2ID is null or D.LSHLevel2ID = @LSHLevel2ID)
			and (@LSHLevel3ID is null or D.LSHLevel3ID = @LSHLevel3ID)
			and (@LSHLevel4ID is null or D.LSHLevel4ID = @LSHLevel4ID)
			and (@LSHLevel5ID is null or D.LSHLevel5ID = @LSHLevel5ID)
			and (@LSHLevel6ID is null or D.LSHLevel6ID = @LSHLevel6ID)
			AND (@LoaiThongTinThayDoiID IS NULL OR @LoaiThongTinThayDoiID = '' OR tblNews.Loai= @LoaiThongTinThayDoiID)
			and (@PhanQuyenTTThayDoiTheoNhomNguoiDung = 0 or PQ1.FunctionID Is not null or @UserGroupID = 'admin' or /**Bổ sung thêm trường hợp nếu là GroupAdmin của Khách hàng - HomeCredit - TuuPNQ@FPT.COM.VN**/@GroupID = 'admin')

			IF OBJECT_ID('tempdb..#TempDataGroup') IS NOT NULL
				DROP TABLE #TempDataGroup
			/*RlogID 22501 - SVFC: Bổ sung thêm cột ShowName để map tên ở MH cấu hình tab hiển thị*/
			SELECT A.*
			INTO #TempDataGroup
			FROM
			(
				select distinct EmpID, case when @hascat = 1 then N'LLCN' else '' end as ShowName, 1 as Loai, 
				SendDate, 156124 as FunctionID, RecordStatus AS DMSStatusID, NULL AS ChonTabCoDuLieu, CONVERT(NVARCHAR(10), EditTime, 103) AS EditTime, TinhTrangSoatXetID, User_SoatXet, Ngay_SoatXet from HR_tblEmpCV_CapNhat(NoLock) WHERE RecordStatus=2 and (IsMobile is null or IsMobile = 0)
				union all
				select distinct EmpID, case when @hascat = 1 then N'NguoiThan' else '' end as ShowName, 2 as Loai, 
				SendDate, 156125 as FunctionID, isnull(DMSStatusID,RecordStatus) DMSStatusID, NULL AS ChonTabCoDuLieu, CONVERT(NVARCHAR(10), EditTime, 103) AS EditTime, TinhTrangSoatXetID, User_SoatXet, Ngay_SoatXet from HR_tblRelative_CapNhat(NoLock) where (DMSStatusID IN (2) or RecordStatus=2)  and (IsMobile is null or IsMobile = 0)
				union all
				select distinct EmpID, case when @hascat = 1 then N'BCCC' else '' end as ShowName, 3 as Loai,
				SendDate, 156126 as FunctionID, isnull(DMSStatusID,RecordStatus) DMSStatusID, NULL AS ChonTabCoDuLieu, CONVERT(NVARCHAR(10), EditTime, 103) AS EditTime, TinhTrangSoatXetID, User_SoatXet, Ngay_SoatXet from HR_tblQualification_CapNhat(NoLock) where  (DMSStatusID IN (2) or RecordStatus=2)  and (IsMobile is null or IsMobile = 0)
				union all
				select distinct EmpID, case when @hascat = 1 then N'KNLV' else '' end as ShowName, 4 as Loai, 
				SendDate, 156128 as FunctionID, isnull(DMSStatusID,RecordStatus) DMSStatusID, NULL AS ChonTabCoDuLieu, CONVERT(NVARCHAR(10), EditTime, 103) AS EditTime, TinhTrangSoatXetID, User_SoatXet, Ngay_SoatXet from HR_tblWorkingBackground_CapNhat(NoLock) where  (DMSStatusID IN (2) or RecordStatus=2)  and (IsMobile is null or IsMobile = 0)
				union all
				select distinct B.EmpID, case when @hascat = 1 then N'VisaPassport' else '' end as ShowName, 5 as Loai, 
				B.SendDate, 156127 as FunctionID, isnull(B.DMSStatusID,B.RecordStatus) DMSStatusID, A.ChonTabCoDuLieu, CONVERT(NVARCHAR(10), EditTime, 103) AS EditTime, B.TinhTrangSoatXetID, B.User_SoatXet, B.Ngay_SoatXet
				FROM HR_tblPassPortVisa_CapNhat(NoLock) B
				OUTER APPLY (
					SELECT TOP 1 A.Type AS ChonTabCoDuLieu FROM HR_tblPassPortVisa_CapNhat(NOLOCK) A where (A.DMSStatusID IN (2) or A.RecordStatus=2) AND A.EmpID = B.EmpID ORDER BY case when A.RecordStatus is null then A.DMSStatusID else A.RecordStatus end desc 
				) A
				WHERE  (DMSStatusID IN (2) or RecordStatus=2)  and (IsMobile is null or IsMobile = 0)
				union all
				select distinct EmpID, case when @hascat = 1 then N'ThongTinSucKhoe' else '' end as ShowName, 6 as Loai,
				SendDate, 156129 as FunctionID, isnull(DMSStatusID,RecordStatus) DMSStatusID, NULL AS ChonTabCoDuLieu, CONVERT(NVARCHAR(10), EditTime, 103) AS EditTime, TinhTrangSoatXetID, User_SoatXet, Ngay_SoatXet from HR_tblHealthcareRecord_CapNhat(NoLock) where DMSStatusID IN (2) or RecordStatus=2
				union all
				select distinct A.EmpID, case when @hascat = 1 then N'HoatDongXH' else '' end as ShowName, 7 as Loai,
				A.SendDate, 156130 as FunctionID, A.RecordStatus AS DMSStatusID, NULL AS ChonTabCoDuLieu, CONVERT(NVARCHAR(10), A.EditTime, 103) AS EditTime, NULL, NULL, NULL
				from HR_tblEmpOther_CapNhat(NoLock) A 
				left join HR_tblEmpCV_CapNhat(NoLock) B on A.EmpID = B.EmpID
				where A.RecordStatus=2 and (B.IsMobile is null or B.IsMobile = 0)
				union all
				select distinct EmpID, case when @hascat = 1 then N'HoSoLuuTru' else '' end as ShowName, 8 as Loai,  
				SendDate, 156134 as FunctionID, RecordStatus AS DMSStatusID, NULL AS ChonTabCoDuLieu, CONVERT(NVARCHAR(10), EditTime, 103) AS EditTime, TinhTrangSoatXetID, User_SoatXet, Ngay_SoatXet from HR_tblEmpDocument_CapNhat(NoLock) where RecordStatus=2
				union all
				select distinct EmpID, case when @hascat = 1 then N'QTLV' else '' end as ShowName, 9 as Loai,  
				SendDate, 1498 as FunctionID, RecordStatus AS DMSStatusID, NULL AS ChonTabCoDuLieu, CONVERT(NVARCHAR(10), EditTime, 103) AS EditTime, NULL, NULL, NULL from HR_tblWorkingRecord_CapNhat(NoLock) where RecordStatus=2
				union all
				select distinct EmpID, case when @hascat = 6 then N'KyLuatKhenThuong' else '' end as ShowName, 10 as Loai,
				SendDate, 2563 as FunctionID, Status AS DMSStatusID, NULL AS ChonTabCoDuLieu, CONVERT(NVARCHAR(10), EditTime, 103) AS EditTime, NULL, NULL, NULL from HR_tblThanhTich_CapNhat(NoLock) where Status=2
				union all
				--RlogID: 11541
				select distinct EmpID, case when @hascat = 1 then N'TKCT' else '' end as ShowName, 11 as Loai,
				ApprovedDate, 3241 as FunctionID, RecordStatus AS DMSStatusID, NULL AS ChonTabCoDuLieu, CONVERT(NVARCHAR(10), EditTime, 103) AS EditTime, NULL, NULL, NULL from HR_tblDetailAccountNumber_CapNhat(NoLock) where RecordStatus=2
			) A

			IF OBJECT_ID('tempdb..#tmpPivot') IS NOT NULL
				DROP TABLE #tmpPivot

			SELECT EmpID, ShowName, Loai, ChonTabCoDuLieu, EditTime, TinhTrangSoatXetID, User_SoatXet, Ngay_SoatXet, [2] AS DaChuyen, [3] AS TraLai, [4] AS Duyet
			INTO #tmpPivot
			FROM  
				(SELECT EmpID, ShowName, Loai, DMSStatusID, ChonTabCoDuLieu, EditTime, TinhTrangSoatXetID, User_SoatXet, Ngay_SoatXet FROM #TempDataGroup(NOLOCK)) AS A
			PIVOT  
			(  
				COUNT(DMSStatusID)  
				FOR DMSStatusID IN ([2], [3], [4])  
			) AS PivotTable;  

			IF(@IsListApprove = '1')
			BEGIN
				SELECT @ReturnCountRemind = COUNT(A.EmpID) FROM #tmpPivot A
				INNER JOIN @tEmp B ON B.EmpID = A.EmpID
				LEFT JOIN HR_vEmp(NoLock) D on D.EmpID = B.EmpID
				LEFT JOIN LS_tblCauHinhTabThongTinNhanVien (NOLOCK) DM ON A.ShowName = DM.LSCauHinhTabThongTinNhanVienCode --RLogID 22501 - SVFC
				WHERE 1 = 1
						AND (@LoaiThongTinThayDoiID IS NULL OR @LoaiThongTinThayDoiID = '' OR A.Loai = @LoaiThongTinThayDoiID)
			END
			ELSE
			BEGIN
			
						SELECT A.EmpID, A.Loai,
						case Loai
								 when '1' then case when @LanguageID='VN' then N'Lý lịch cá nhân' else 'Curriculum viate' end
								 when '2' then case when @LanguageID='VN' then N'Thông tin người thân' else 'Relative infomation' end
								 when '3' then case when @LanguageID='VN' then N'Bằng cấp/ Chứng chỉ' else 'Degree/certificate' end
								 when '4' then case when @LanguageID='VN' then N'Quá trình làm việc trước' else 'Working background' end
								 when '5' then case when @LanguageID='VN' then N'Thông tin Visa/ Passport/ Giấy phép lao động' else 'Visa/passport/working pemit infomation' end
								 when '6' then case when @LanguageID='VN' then N'Thông tin sức khỏe' else 'Health infomation' end
								 when '7' then case when @LanguageID='VN' then N'Hoạt động xã hội' else 'Social activity' end
								 when '8' then case when @LanguageID='VN' then N'Hồ sơ lưu trữ'  else 'Archive document' end
								 when '9' then case when @LanguageID='VN' then N'Quá trình làm việc'  else 'Working Record' end
								 when '10' then case when @LanguageID='VN' then N'Thành tích cá nhân'  else 'Personal achievements' end
								 when '11' then case when @LanguageID='VN' then N'Thông tin tài khoản chi tiết'  else 'Detail Account information' end
							end as TenLoai,
						case when @hascat = 1 AND DM.Used = 1 then case when @LanguageID = 'VN' then DM.VNName else DM.[Name] end  else --RLogID 22501 - SVFC
							case Loai
								 when '1' then case when @LanguageID='VN' then N'Lý lịch cá nhân' else 'Curriculum viate' end
								 when '2' then case when @LanguageID='VN' then N'Thông tin người thân' else 'Relative infomation' end
								 when '3' then case when @LanguageID='VN' then N'Bằng cấp/ Chứng chỉ' else 'Degree/certificate' end
								 when '4' then case when @LanguageID='VN' then N'Quá trình làm việc trước' else 'Working background' end
								 when '5' then case when @LanguageID='VN' then N'Thông tin Visa/ Passport/ Giấy phép lao động' else 'Visa/passport/working pemit infomation' end
								 when '6' then case when @LanguageID='VN' then N'Thông tin sức khỏe' else 'Health infomation' end
								 when '7' then case when @LanguageID='VN' then N'Hoạt động xã hội' else 'Social activity' end
								 when '8' then case when @LanguageID='VN' then N'Hồ sơ lưu trữ'  else 'Archive document' end
								 when '9' then case when @LanguageID='VN' then N'Quá trình làm việc'  else 'Working Record' end
								 when '10' then case when @LanguageID='VN' then N'Thành tích cá nhân'  else 'Personal achievements' end
								 when '11' then case when @LanguageID='VN' then N'Thông tin tài khoản chi tiết'  else 'Detail Account information' end
							end end as ThongTinThayDoi_Cach2,
							D.EmpCode, D.LSCompanyID, D.LSLevel1ID, D.LSLevel2ID, D.LSLevel3ID, D.EmpName as FullName,
							case when @LanguageID='EN' then D.CompanyEN else D.CompanyVN end as LSCompanyName,
							case when @LanguageID='EN' then D.Level1EN else D.Level1VN end as LSLevel1Name,
							case when @LanguageID='EN' then D.Level2EN else D.Level2VN end as LSLevel2Name,
							case when @LanguageID='EN' then D.Level3EN else D.Level3VN end as LSLevel3Name,
							/*Start [GUARDIAN_iHRP_PM] Bo sung dich vu ca nhan - NhanHM4 - 10/10/2020*/
							case when @LanguageID='EN' then D.Level4EN else D.Level4VN end as LSLevel4Name,
							case when @LanguageID='EN' then D.Level5EN else D.Level5VN end as LSLevel5Name,
							case when @LanguageID='EN' then D.Level6EN else D.Level6VN end as LSLevel6Name,
							case when @LanguageID='EN' then D.Level7EN else D.Level7VN end as LSLevel7Name,
							case when @LanguageID='EN' then D.Level8EN else D.Level8VN end as LSLevel8Name,
							case when @LanguageID='EN' then D.Level9EN else D.Level9VN end as LSLevel9Name,
							/*RlogID 24215 - MESSER*/
							case when @LanguageID='EN' then TT.VNName else TT.Name end as TinhTrangSoatXet,
							A.Ngay_SoatXet AS NgaySoatXet,
							UAE.F_EmpName AS NguoiSoatXet,
							A.TinhTrangSoatXetID,
							/*END RlogID 24215 - MESSER*/
							A.DaChuyen, A.Duyet, A.TraLai, A.ChonTabCoDuLieu, A.EditTime
							,case when @LanguageID='EN' then D.JobTitleEN else D.JobTitleVN end as ChucDanh
							,RE.SendDate NgayGuiDon
						FROM #tmpPivot(NOLOCK) A
						INNER JOIN @tEmp B ON B.EmpID = A.EmpID
						LEFT JOIN HR_vEmp(NoLock) D on D.EmpID = B.EmpID
						LEFT JOIN LS_tblCauHinhTabThongTinNhanVien (NOLOCK) DM ON A.ShowName = DM.LSCauHinhTabThongTinNhanVienCode --RLogID 22501 - SVFC
						LEFT JOIN dbo.NEWS_tblTinhTrangSoatXet (NOLOCK) TT ON TT.TinhTrangSoatXetID = A.TinhTrangSoatXetID
						LEFT JOIN dbo.UMS_tblUserAccount (NOLOCK) UA ON UA.UserGroupID = A.User_SoatXet
						LEFT JOIN dbo.HR_tblEmp (NOLOCK) UAE ON UAE.EmpID = UA.EmpID
						OUTER APPLY(
							SELECT TOP 1 CONVERT(NVARCHAR(10),Rc.SendDate,103) AS SendDate
							FROM HR_tblRelative_CapNhat (NOLOCK) RC
							WHERE RC.EmpID = A.EmpID
							ORDER BY Rc.EditTime DESC
						)RE
						WHERE 1 = 1
						AND (@LoaiThongTinThayDoiID IS NULL OR @LoaiThongTinThayDoiID = '' OR A.Loai = @LoaiThongTinThayDoiID)
						AND (@TinhTrangSoatXetID IS NULL OR @TinhTrangSoatXetID = 3 OR ISNULL(A.TinhTrangSoatXetID, 2) = @TinhTrangSoatXetID)
			END
			
		END
		ELSE
		BEGIN

			IF(@IsListApprove = '1')
			BEGIN
				SELECT @ReturnCountRemind = COUNT(tblNews.EmpID) from (
							SELECT tblNews.EmpID, tblNews.ShowName ,tblNews.FunctionID, tblNews.Loai, MIN(tblNews.ChonTabCoDuLieu) AS ChonTabCoDuLieu, MAX(tblNews.SendDate) AS SendDate, MAX(tblNews.EditTime) AS EditTime
							FROM #TempData(NOLOCK) tblNews
							GROUP BY tblNews.EmpID, tblNews.ShowName, tblNews.FunctionID, tblNews.Loai				
						) tblNews
						inner join dbo.fnGetAllEmp_Permission(@UserGroupID, @FunctionID) PQ on PQ.EmpID = tblNews.EmpID -- phan quyen du lieu
						left join #Tbl_PQNhomNguoiDung_LoaiThongTinThayDoi(NOLOCK) PQ1 on PQ1.FunctionID = tblNews.FunctionID
						left join dbo.HR_tblEmpCV(NoLock) ECV on tblNews.EmpID=ECV.EmpID  
						left join dbo.HR_tblEmp(NoLock) E on tblNews.EmpID=E.EmpID  
						left join dbo.LS_tblCompany(NoLock) C on C.LSCompanyID = E.LSCompanyID
						left join dbo.LS_tblLevel1(NoLock) L1 on L1.LSLevel1ID = E.LSLevel1ID
						left join dbo.LS_tblLevel2(NoLock) L2 on L2.LSLevel2ID = E.LSLevel2ID
						left join dbo.LS_tblLevel3(NoLock) L3 on L3.LSLevel3ID = E.LSLevel3ID
						left join dbo.LS_tblLevel4(NoLock) L4 on L4.LSLevel4ID = E.LSLevel4ID
						left join dbo.LS_tblLevel5(NoLock) L5 on L5.LSLevel5ID = E.LSLevel5ID
						left join dbo.LS_tblLevel6(NoLock) L6 on L6.LSLevel6ID = E.LSLevel6ID
						left join dbo.LS_tblLevel7(NoLock) L7 on L7.LSLevel7ID = E.LSLevel7ID
						left join dbo.LS_tblLevel8(NoLock) L8 on L8.LSLevel8ID = E.LSLevel8ID
						left join dbo.LS_tblLevel9(NoLock) L9 on L9.LSLevel9ID = E.LSLevel9ID
						LEFT JOIN LS_tblCauHinhTabThongTinNhanVien (NOLOCK) DM ON tblNews.ShowName = DM.LSCauHinhTabThongTinNhanVienCode --RLogID 22501 - SVFC
						left join HR_vEmp(NoLock) D on E.EmpID = D.EmpID	
						where (SendDate between @dFromDate and @dToDate + 1)
						and (@EmpCode = '' or @EmpCode is null or D.EmpCode like N'%' + @EmpCode + '%')
						and (@EmpName = '' or @EmpName is null or D.EmpName like N'%' + @EmpName + '%' or D.EmpName_Unsign like N'%'+ @EmpName +'%')	
						and (@LSLevel1ID is null  or D.LSLevel1ID = @LSLevel1ID)
						and (@LSLevel2ID is null or D.LSLevel2ID = @LSLevel2ID)
						and (@LSLevel3ID is null or D.LSLevel3ID = @LSLevel3ID)
						and (@LSLevel4ID is null or D.LSLevel4ID = @LSLevel4ID)
						and (@LSLevel5ID is null or D.LSLevel5ID = @LSLevel5ID)
						and (@LSLevel6ID is null or D.LSLevel6ID = @LSLevel6ID)
						and (@LSLevel7ID is null or D.LSLevel7ID = @LSLevel7ID)
						and (@LSLevel8ID is null or D.LSLevel8ID = @LSLevel8ID)
						and (@LSLevel9ID is null or D.LSLevel9ID = @LSLevel9ID)
						and (@LSCompanyID is null or D.LSCompanyID = @LSCompanyID)
						and (@LSLocationID is null or D.LSLocationID = @LSLocationID)
						and (@LSJobTitleID is null or D.LSJobTitleID = @LSJobTitleID)
						and (D.Status = @Status or @Status = '2' or @Status is null)			
						and (@LSLoaiHinhNhanVienID is null or E.LSLoaiHinhNhanVienID = @LSLoaiHinhNhanVienID)
						and (@LSHLevel1ID is null or D.LSHLevel1ID = @LSHLevel1ID)
						and (@LSHLevel2ID is null or D.LSHLevel2ID = @LSHLevel2ID)
						and (@LSHLevel3ID is null or D.LSHLevel3ID = @LSHLevel3ID)
						and (@LSHLevel4ID is null or D.LSHLevel4ID = @LSHLevel4ID)
						and (@LSHLevel5ID is null or D.LSHLevel5ID = @LSHLevel5ID)
						and (@LSHLevel6ID is null or D.LSHLevel6ID = @LSHLevel6ID)
						AND (@LoaiThongTinThayDoiID IS NULL OR @LoaiThongTinThayDoiID = '' OR tblNews.Loai= @LoaiThongTinThayDoiID)
						and (@PhanQuyenTTThayDoiTheoNhomNguoiDung = 0 or PQ1.FunctionID Is not null or @UserGroupID = 'admin' or /**Bổ sung thêm trường hợp nếu là GroupAdmin của Khách hàng - HomeCredit - TuuPNQ@FPT.COM.VN**/@GroupID = 'admin')
			END
			ELSE
			BEGIN
			
						select tblNews.EmpID, Loai,
						case Loai
							 when '1' then case when @LanguageID='VN' then N'Lý lịch cá nhân' else 'Curriculum viate' end
							 when '2' then case when @LanguageID='VN' then N'Thông tin người thân' else 'Relative infomation' end
							 when '3' then case when @LanguageID='VN' then N'Bằng cấp/ Chứng chỉ' else 'Degree/certificate' end
							 when '4' then case when @LanguageID='VN' then N'Quá trình làm việc trước' else 'Working background' end
							 when '5' then case when @LanguageID='VN' then N'Thông tin Visa/ Passport' else 'Visa/passport infomation' end
							 when '6' then case when @LanguageID='VN' then N'Thông tin sức khỏe' else 'Health infomation' end
							 when '7' then case when @LanguageID='VN' then N'Hoạt động xã hội' else 'Social activity' end
							 when '8' then case when @LanguageID='VN' then N'Hồ sơ lưu trữ'  else 'Archive document' end
							 when '9' then case when @LanguageID='VN' then N'Quá trình làm việc'  else 'Working Record' end
							 when '10' then case when @LanguageID='VN' then N'Thành tích cá nhân'  else 'Personal achievements' end
							 when '11' then case when @LanguageID='VN' then N'Thông tin tài khoản chi tiết'  else 'Detail Account information' end
						end as TenLoai,
						case when @hascat = 1 AND DM.Used = 1 then case when @LanguageID = 'VN' then DM.VNName else DM.[Name] end  else--RLogID 22501 - SVFC
						--Start RlogID: 14828 - PNJ - NhanHM4 - 13/01/2020
						case Loai
							 when '1' then case when @LanguageID='VN' then N'Lý lịch cá nhân' else 'Curriculum viate' end
							 when '2' then case when @LanguageID='VN' then N'Thông tin người thân' else 'Relative infomation' end
							 when '3' then case when @LanguageID='VN' then N'Bằng cấp/ Chứng chỉ' else 'Degree/certificate' end
							 when '4' then case when @LanguageID='VN' then N'Quá trình làm việc trước' else 'Working background' end
							 when '5' then case when @LanguageID='VN' then N'Thông tin Visa/ Passport' else 'Visa/passport infomation' end
							 when '6' then case when @LanguageID='VN' then N'Thông tin sức khỏe' else 'Health infomation' end
							 when '7' then case when @LanguageID='VN' then N'Hoạt động xã hội' else 'Social activity' end
							 when '8' then case when @LanguageID='VN' then N'Hồ sơ lưu trữ'  else 'Archive document' end
							 when '9' then case when @LanguageID='VN' then N'Quá trình làm việc'  else 'Working Record' end
							 when '10' then case when @LanguageID='VN' then N'Thành tích cá nhân'  else 'Personal achievements' end
							 when '11' then case when @LanguageID='VN' then N'Thông tin tài khoản chi tiết'  else 'Detail Account information' end
						end end as ThongTinThayDoi_Cach2,
						--End   RlogID: 14828 - PNJ - NhanHM4 - 13/01/2020
						E.EmpCode, E.LSCompanyID,E.LSLevel1ID, E.LSLevel2ID, E.LSLevel3ID,D.EmpName as FullName,
						case when @LanguageID='EN' then C.Name else C.VNName end as LSCompanyName,
						case when @LanguageID='EN' then L1.Name else L1.VNName end as LSLevel1Name,
						case when @LanguageID='EN' then L2.Name else L2.VNName end as LSLevel2Name,
						case when @LanguageID='EN' then L3.Name else L3.VNName end as LSLevel3Name,
						/*Start [GUARDIAN_iHRP_PM] Bo sung dich vu ca nhan - NhanHM4 - 10/10/2020*/
						case when @LanguageID='EN' then L4.Name else L4.VNName end as LSLevel4Name,
						case when @LanguageID='EN' then L5.Name else L5.VNName end as LSLevel5Name,
						case when @LanguageID='EN' then L6.Name else L6.VNName end as LSLevel6Name,
						case when @LanguageID='EN' then L7.Name else L7.VNName end as LSLevel7Name,
						case when @LanguageID='EN' then L8.Name else L8.VNName end as LSLevel8Name,
						case when @LanguageID='EN' then L9.Name else L9.VNName end as LSLevel9Name
						/*End   [GUARDIAN_iHRP_PM] Bo sung dich vu ca nhan - NhanHM4 - 10/10/2020*/
						,'' AS DaChuyen, '' AS Duyet, '' AS TraLai, tblNews.ChonTabCoDuLieu
						,tblNews.EditTime, /*LGE_IHRP_2021_PM-787*/
						/*RlogID 24215 - MESSER*/
						case when @LanguageID='EN' then TT.VNName else TT.Name end as TinhTrangSoatXet,
						tblNews.Ngay_SoatXet AS NgaySoatXet,
						UAE.F_EmpName AS NguoiSoatXet
						,tblNews.TinhTrangSoatXetID
						/*END RlogID 24215 - MESSER*/
					from (
							SELECT tblNews.EmpID, tblNews.ShowName ,tblNews.FunctionID, tblNews.Loai, tblNews.TinhTrangSoatXetID, tblNews.User_SoatXet, tblNews.Ngay_SoatXet, MIN(tblNews.ChonTabCoDuLieu) AS ChonTabCoDuLieu, MAX(tblNews.SendDate) AS SendDate, MAX(tblNews.EditTime) AS EditTime
							FROM #TempData(NOLOCK) tblNews
							GROUP BY tblNews.EmpID, tblNews.ShowName, tblNews.FunctionID, tblNews.Loai, tblNews.TinhTrangSoatXetID, tblNews.User_SoatXet, tblNews.Ngay_SoatXet				
						) tblNews
						inner join dbo.fnGetAllEmp_Permission(@UserGroupID, @FunctionID) PQ on PQ.EmpID = tblNews.EmpID -- phan quyen du lieu
						left join #Tbl_PQNhomNguoiDung_LoaiThongTinThayDoi(NOLOCK) PQ1 on PQ1.FunctionID = tblNews.FunctionID
						left join dbo.HR_tblEmpCV(NoLock) ECV on tblNews.EmpID=ECV.EmpID  
						left join dbo.HR_tblEmp(NoLock) E on tblNews.EmpID=E.EmpID  
						left join dbo.LS_tblCompany(NoLock) C on C.LSCompanyID = E.LSCompanyID
						left join dbo.LS_tblLevel1(NoLock) L1 on L1.LSLevel1ID = E.LSLevel1ID
						left join dbo.LS_tblLevel2(NoLock) L2 on L2.LSLevel2ID = E.LSLevel2ID
						left join dbo.LS_tblLevel3(NoLock) L3 on L3.LSLevel3ID = E.LSLevel3ID
						left join dbo.LS_tblLevel4(NoLock) L4 on L4.LSLevel4ID = E.LSLevel4ID
						left join dbo.LS_tblLevel5(NoLock) L5 on L5.LSLevel5ID = E.LSLevel5ID
						left join dbo.LS_tblLevel6(NoLock) L6 on L6.LSLevel6ID = E.LSLevel6ID
						left join dbo.LS_tblLevel7(NoLock) L7 on L7.LSLevel7ID = E.LSLevel7ID
						left join dbo.LS_tblLevel8(NoLock) L8 on L8.LSLevel8ID = E.LSLevel8ID
						left join dbo.LS_tblLevel9(NoLock) L9 on L9.LSLevel9ID = E.LSLevel9ID
						LEFT JOIN LS_tblCauHinhTabThongTinNhanVien (NOLOCK) DM ON tblNews.ShowName = DM.LSCauHinhTabThongTinNhanVienCode --RLogID 22501 - SVFC
						left join HR_vEmp(NoLock) D on E.EmpID = D.EmpID		
						LEFT JOIN dbo.NEWS_tblTinhTrangSoatXet (NOLOCK) TT ON TT.TinhTrangSoatXetID = tblNews.TinhTrangSoatXetID
						LEFT JOIN dbo.UMS_tblUserAccount (NOLOCK) UA ON UA.UserGroupID = tblNews.User_SoatXet
						LEFT JOIN dbo.HR_tblEmp (NOLOCK) UAE ON UAE.EmpID = UA.EmpID
					where (SendDate between @dFromDate and @dToDate + 1)
					and (@EmpCode = '' or @EmpCode is null or D.EmpCode like N'%' + @EmpCode + '%')
					and (@EmpName = '' or @EmpName is null or D.EmpName like N'%' + @EmpName + '%' or D.EmpName_Unsign like N'%'+ @EmpName +'%')	
					and (@LSLevel1ID is null  or D.LSLevel1ID = @LSLevel1ID)
					and (@LSLevel2ID is null or D.LSLevel2ID = @LSLevel2ID)
					and (@LSLevel3ID is null or D.LSLevel3ID = @LSLevel3ID)
					and (@LSLevel4ID is null or D.LSLevel4ID = @LSLevel4ID)
					and (@LSLevel5ID is null or D.LSLevel5ID = @LSLevel5ID)
					and (@LSLevel6ID is null or D.LSLevel6ID = @LSLevel6ID)
					and (@LSLevel7ID is null or D.LSLevel7ID = @LSLevel7ID)
					and (@LSLevel8ID is null or D.LSLevel8ID = @LSLevel8ID)
					and (@LSLevel9ID is null or D.LSLevel9ID = @LSLevel9ID)
					and (@LSCompanyID is null or D.LSCompanyID = @LSCompanyID)
					and (@LSLocationID is null or D.LSLocationID = @LSLocationID)
					and (@LSJobTitleID is null or D.LSJobTitleID = @LSJobTitleID)
					and (D.Status = @Status or @Status = '2' or @Status is null)			
					and (@LSLoaiHinhNhanVienID is null or E.LSLoaiHinhNhanVienID = @LSLoaiHinhNhanVienID)
					and (@LSHLevel1ID is null or D.LSHLevel1ID = @LSHLevel1ID)
					and (@LSHLevel2ID is null or D.LSHLevel2ID = @LSHLevel2ID)
					and (@LSHLevel3ID is null or D.LSHLevel3ID = @LSHLevel3ID)
					and (@LSHLevel4ID is null or D.LSHLevel4ID = @LSHLevel4ID)
					and (@LSHLevel5ID is null or D.LSHLevel5ID = @LSHLevel5ID)
					and (@LSHLevel6ID is null or D.LSHLevel6ID = @LSHLevel6ID)
					AND (@LoaiThongTinThayDoiID IS NULL OR @LoaiThongTinThayDoiID = '' OR tblNews.Loai= @LoaiThongTinThayDoiID)
					and (@PhanQuyenTTThayDoiTheoNhomNguoiDung = 0 or PQ1.FunctionID Is not null or @UserGroupID = 'admin' or /**Bổ sung thêm trường hợp nếu là GroupAdmin của Khách hàng - HomeCredit - TuuPNQ@FPT.COM.VN**/@GroupID = 'admin')
					AND (@TinhTrangSoatXetID IS NULL OR @TinhTrangSoatXetID = 3 OR ISNULL(tblNews.TinhTrangSoatXetID, 2) = @TinhTrangSoatXetID)
					order by Loai, SendDate DESC
			END
			
		END
	end
END









