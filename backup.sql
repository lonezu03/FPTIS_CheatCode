USE [iHRP_V34_PMC_PRO]
GO
/****** Object:  StoredProcedure [dbo].[MESS_spPushNotificationToApp]    Script Date: 4/24/2026 4:27:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[MESS_spPushNotificationToApp] 
@ReturnMess				NVARCHAR(500)= NULL OUT,
@Activity				NVARCHAR(50) = NULL,
@UserGroupID			NVARCHAR(50) = NULL,
@FunctionID				INT = NULL,
@LanguageID				NVARCHAR(2) = 'VN',
@Type					NVARCHAR(50) = NULL,
@MaQuiTrinh				NVARCHAR(3) = NULL,
@RecordID				NVARCHAR(20) = NULL,
@RecordIDList			NVARCHAR(MAX) = NULL,
@MaQuiTrinhList			NVARCHAR(MAX) = NULL,
@JsonInput				NVARCHAR(MAX) = NULL
AS
BEGIN
	DECLARE @Level INT,@LevelProcess INT, @StatusID INT, @EmpID INT, @UserID NVARCHAR(50), @NguoiThayThe INT, @CCMail NVARCHAR(MAX), @Type_QTBG NVARCHAR(50)
	DECLARE @STT_MIN INT, @STT_MAX INT
	DECLARE @tEmp tEmp
	DECLARE @IsChoPhepTrienKhaiDieuChinhThoiGianCanhBao BIT, @ThoiGianCanhBao NVARCHAR(5),@ThoiGian NVARCHAR(5) = '00:00',
			@IsNotifyCCDuringLeaveRecordApproval BIT, @IsNotifyCCOnLeaveRecordApproved BIT, @IsNotifyCCOnOvertimeApproved BIT

	SELECT @IsChoPhepTrienKhaiDieuChinhThoiGianCanhBao = isnull(IsChoPhepTrienKhaiDieuChinhThoiGianCanhBao,0),
		   @ThoiGianCanhBao = ThoiGianCanhBao,
		   @IsNotifyCCDuringLeaveRecordApproval = ISNULL(IsNotifyCCDuringLeaveRecordApproval,0),
		   @IsNotifyCCOnLeaveRecordApproved = ISNULL(IsNotifyCCOnLeaveRecordApproved,0),
		   @IsNotifyCCOnOvertimeApproved = ISNULL(IsNotifyCCOnOvertimeApproved, 0)
	FROM MOBI_tblSetupMOBI(NOLOCK)

	IF ISNULL(@ThoiGianCanhBao,'') = '' SET @ThoiGianCanhBao = @ThoiGian

	DECLARE @dNow DATETIME = GETDATE()
	DECLARE @dDateID DATETIME = CONVERT(DATE,GETDATE())
	DECLARE @TG DATETIME, @TG_ DATETIME, @Hour INT, @Minute INT
	SET @TG = CONVERT(DATETIME,CONVERT(NVARCHAR(10),@dDateID,103) + ' ' + @ThoiGianCanhBao,103)

	SET @Hour = LEFT(@ThoiGianCanhBao,2)
	SET @Minute = RIGHT(@ThoiGianCanhBao,2)
	SET @TG_ = DATEADD(MINUTE,@Minute * (-1),DATEADD(HOUR, @Hour * (-1),@dDateID))

	DECLARE @CustomerID NVARCHAR(255)
	SET @CustomerID = dbo.fnGetCustomerCode()

	SET @RecordID = REPLACE(@RecordID,'@','')

	SET @Type_QTBG = @Type
	IF @Type LIKE N'%QTBanGiao%' SET @Type = 'QTBanGiao'

	IF @Activity = 'GetInfo'
	BEGIN		
		IF(@Type = 'ThayDoiThongTin')
		BEGIN
			declare @Act nvarchar(2)
			select @Act = items from dbo.[SplitRowIndex](@RecordID,'_') where rowindex = 1
			select @EmpID = items from dbo.[SplitRowIndex](@RecordID,'_') where rowindex = 2
			
			Select top(1) @UserID = UserGroupID
			From UMS_tblUserAccount(Nolock) u1
			Where u1.EmpID = @EmpID and u1.MaLoaiNguoiDung='2' and (Removed is null or Removed = 0)/*Người dùng phụ*/
			
			if isnull(@UserID,'') = ''
			BEGIN
				Select top(1) @UserID = UserGroupID
				From UMS_tblUserAccount(Nolock) u1
				Where u1.EmpID = @EmpID and u1.MaLoaiNguoiDung='1' and (Removed is null or Removed = 0)/*Người dùng chính*/
			END

			SELECT  @UserID as UserID, 
			case when @Act = 'XN' then 'IF001' else 'IF002' end AS Code,
			case @MaQuiTrinh
			when '1' then case when @LanguageID='VN' then N'Lý lịch cá nhân' else 'Curriculum viate' end
			when '2' then case when @LanguageID='VN' then N'Thông tin người thân' else 'Relative infomation' end
			when '31' then case when @LanguageID='VN' then N'Bằng cấp' else 'Degree' END
            when '30' then case when @LanguageID='VN' then N'Chứng chỉ' else 'Certificate' end
			when '4' then case when @LanguageID='VN' then N'Kinh nghiệm làm việc' else 'Working background' end
			when '50' then case when @LanguageID='VN' then N'Giấy phép lao động' else 'Working pemit infomation' end
			when '51' then case when @LanguageID='VN' then N'Thông tin Passport' else 'Passport' end
			when '52' then case when @LanguageID='VN' then N'Thông tin Visa' else 'Visa' end end AS [Param],
			NULL AS MaQuiTrinh,
			NULL AS ScreenType,
			NULL AS RecordID

			RETURN;
		END
		
		IF OBJECT_ID('tempdb..#MESS_spPushNotificationToApp_UserID') IS NOT NULL
			DROP TABLE dbo.[#MESS_spPushNotificationToApp_UserID]

		CREATE TABLE [#MESS_spPushNotificationToApp_UserID] 
		(
			UserID			NVARCHAR(255)
		)

		IF OBJECT_ID('tempdb..#MESS_spPushNotificationToApp') IS NOT NULL
			DROP TABLE dbo.[#MESS_spPushNotificationToApp]

		CREATE TABLE [#MESS_spPushNotificationToApp] 
		(
			UserID			NVARCHAR(255),
			Code			NVARCHAR(255),
			Param			NVARCHAR(MAX),
			MaQuiTrinh		NVARCHAR(100),
			ScreenType		NVARCHAR(2),
			RecordID		NVARCHAR(30)
		)
		/*Start Rlog 20847 HaiNT181 29/03/2024 =======  NOTE: NOTI CHO TIN TỨC*/
		/*Noti của tin tức*/
		IF(@MaQuiTrinh = '999')
		BEGIN
			IF(@Type = 'CoCauTinTuc')
			BEGIN
				EXEC [dbo].[HR_spfrmThietLapNhanThongBaoTheoCoCau] @Activity=N'TransferNew',@LanguageID=@LanguageID,@strListID=@RecordIDList,@FunctionID=@FunctionID,@UserGroupID=@UserGroupID
			END
			RETURN
		END
		/*END Rlog 20847 HaiNT181 29/03/2024 =======  NOTE: NOTI CHO TIN TỨC*/

		/*Nếu là noti từ service*/
		IF @MaQuiTrinh = '-1'
		BEGIN
			IF @Type = 'ETMsReminder'
			BEGIN
				EXEC TS_spGetInvalidCardSwipe
				RETURN
			END

			INSERT INTO @tEmp (EmpID)
			SELECT E.EmpID
			FROM HR_tblEmp (NOLOCK) E
			LEFT JOIN TER_tblTermination (NOLOCK) T ON T.EmpID = E.EmpID
			INNER JOIN
			(
				SELECT EmpID
				FROM UMS_tblUserAccount (NOLOCK)
				GROUP BY EmpID
			) U ON U.EmpID = E.EmpID
			WHERE (T.EmpID IS NULL OR CONVERT(DATE,GETDATE()) < T.EffectDate)
			--AND (@CustomerID <> '153' OR E.LSLevel5ID = 9)
			GROUP BY E.EmpID
			
			IF @Type = 'HoSoLuuTru'
			AND EXISTS (SELECT TOP 1 1 FROM MOBI_tblSetupMOBI (NOLOCK) WHERE CanhBaoNopHoSoLuuTru = 1)
			AND EXISTS (SELECT TOP 1 1 FROM LS_tblCauHinhTabThongTinNhanVien (NOLOCK) WHERE LSCauHinhTabThongTinNhanVienCode = 'HoSoLuuTru' AND Used = 1)
			BEGIN
				IF OBJECT_ID('tempdb..#MESS_TableEmp') IS NOT NULL
					DROP TABLE dbo.[#MESS_TableEmp]

				CREATE TABLE [#MESS_TableEmp] (STT INT IDENTITY(1,1),EmpID INT,SoLuong INT)
				CREATE INDEX IX_MESS_TableEmp_STT_EmpID_SoLuong ON [#MESS_TableEmp](STT,EmpID,SoLuong)

				INSERT INTO [#MESS_TableEmp](EmpID,SoLuong)
				SELECT E.EmpID, ISNULL(B.SoLuong,0)
				FROM @tEmp E
				OUTER APPLY
				(
					SELECT COUNT(*) AS SoLuong
					FROM LS_tblDocument (NOLOCK) B
					LEFT JOIN HR_tblEmpDocument (NOLOCK) A ON B.LSDocumentID = A.LSDocumentID AND A.EmpID = E.EmpID
					LEFT JOIN
					(
						SELECT EmpID,LSDocumentID
						FROM HR_tblEmpDocument_CapNhat (NOLOCK) 
						WHERE DaNop = 1 AND EmpID = E.EmpID
						GROUP BY EmpID,LSDocumentID
					) C on C.LSDocumentID = A.LSDocumentID AND A.EmpID = E.EmpID
					LEFT JOIN TER_tblTermination (NOLOCK) TER ON TER.EmpID = E.EmpID
					LEFT JOIN LS_tblDocumentType (NOLOCK) D ON D.LSDocumentTypeID = B.LSDocumentTypeID
					WHERE B.Used = 1 
					AND C.EmpID IS NULL
					AND B.IsRequire = 1
					AND (A.DaNop IS NULL OR A.DaNop = 0)
					AND (ISNULL(D.LSDocumentTypeCode,'') <> 'TER' OR TER.EmpID IS NOT NULL)
				) B

				INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
				SELECT /*TOP 1*/ D.UserGroupID AS UserID, 
						N'HOSOLUUTRU' AS Code,
						ISNULL(L.SoLuong,0) AS Param,
						NULL AS MaQuiTrinh,
						NULL AS ScreenType,
						NULL AS RecordID
				FROM [#MESS_TableEmp] (NOLOCK) L
				OUTER APPLY dbo.TS_fnTableUserAccountByEmp(L.EmpID,GETDATE()) D
				WHERE D.UserGroupID IS NOT NULL AND ISNULL(L.SoLuong,0) > 0
			END
			ELSE IF @Type = N'CheckInOut'
			AND @IsChoPhepTrienKhaiDieuChinhThoiGianCanhBao = 1
			BEGIN
				IF OBJECT_ID('tempdb..#MESS_TableEmp_InOut') IS NOT NULL
					DROP TABLE dbo.[#MESS_TableEmp_InOut]

				IF OBJECT_ID('tempdb..#MESS_TableEmp_List') IS NOT NULL
					DROP TABLE dbo.[#MESS_TableEmp_List]

				CREATE TABLE [#MESS_TableEmp_InOut] (STT INT IDENTITY(1,1),EmpID INT,[Type] INT)
				CREATE INDEX IX_MESS_TableEmp_InOut_STT_EmpID_SoLuong ON [#MESS_TableEmp_InOut](STT,EmpID,[Type])

				CREATE TABLE [#MESS_TableEmp_List] (EmpID INT,AM_PM INT)
				CREATE INDEX IX_MESS_TableEmp_List_EmpID ON [#MESS_TableEmp_List](EmpID)

				DECLARE @tEmp_ tEmp

				INSERT INTO [#MESS_TableEmp_List] (EmpID, AM_PM)
				--INSERT INTO @tEmp_ (EmpID)
				SELECT A.EmpID, CASE WHEN CT.AM_PM IS NOT NULL THEN CT.AM_PM
									 WHEN ISNULL(CTD.TuGioDK,0) = ISNULL(C.GioLamBatDau,0) AND ISNULL(CTD.TuPhutDK,0) = ISNULL(C.PhutLamBatDau,0) AND
										  ISNULL(CTD.DenGioDK,0) = ISNULL(C.GioNghiTruaBatDau,0) AND ISNULL(CTD.TuPhutDK,0) = ISNULL(C.PhutNghiTruaBatDau,0) THEN 1
									 WHEN ISNULL(CTD.TuGioDK,0) = ISNULL(C.GioNghiTruaKetThuc,0) AND ISNULL(CTD.TuPhutDK,0) = ISNULL(C.PhutNghiTruaKetThuc,0) AND
										  ISNULL(CTD.DenGioDK,0) = ISNULL(C.GioLamKetThuc,0) AND ISNULL(CTD.TuPhutDK,0) = ISNULL(C.PhutLamKetThuc,0) THEN 2								
								ELSE NULL END
				FROM TS_tblAssignEmpWorkDetails (NOLOCK) A
				INNER JOIN @tEmp E ON E.EmpID = A.EmpID
				INNER JOIN LS_tblShift (NOLOCK) C on C.LSShiftID = A.LSShiftID
				LEFT JOIN TS_tblChamCongCT (NOLOCK) CT on CT.EmpID = A.EmpID  AND CT.DateID = A.DateID
				LEFT JOIN
				(
					SELECT EmpID, DateID, MIN(TuGioDK) AS TuGioDK, MIN(TuPhutDK) AS TuPhutDK, MAX(DenGioDK) AS DenGioDK, MAX(DenPhutDK) AS DenPhutDK
					FROM TS_tblChamCongCTDetail (NOLOCK)
					GROUP BY EmpID, DateID
				) CTD ON CTD.EmpID = A.EmpID AND CTD.DateID = A.DateID
				INNER JOIN 
				(
					SELECT A.EmpID
					FROM TS_tblDoiTuongChamCong (NOLOCK) A
					INNER JOIN 
					(
						SELECT A.EmpID, MAX(NgayHieuLuc) NgayHieuLuc 
						FROM TS_tblDoiTuongChamCong (NOLOCK) A
						INNER JOIN @tEmp E ON E.EmpID = A.EmpID
						WHERE NgayHieuLuc <= @dNow
						GROUP BY A.EmpID
					) B ON B.EmpID = A.EmpID AND B.NgayHieuLuc = A.NgayHieuLuc
					WHERE A.ChamCongMay = 1
					GROUP BY A.EmpID
				) DTCC on DTCC.EmpID = A.EmpID -- bảng đối tượng chấm công
				LEFT JOIN
				(
					SELECT TS.EmpID 
					FROM TS_tblDownloadFile (NOLOCK) TS 
					WHERE CONVERT(DATE,DateID) = CONVERT(DATE,@dDateID)
					GROUP BY TS.EmpID
				) TS ON TS.EmpID = A.EmpID
				WHERE A.DateID = CONVERT(DATE,@dDateID)
				AND A.LSShiftID IS NOT NULL
				AND (C.CheckBox1 IS NULL OR C.CheckBox1 = 0)
				AND (C.QuetThe1LanDuCong IS NULL OR C.QuetThe1LanDuCong = 0 OR TS.EmpID IS NULL)
				AND
				(	
					CT.LSWorkPointID IS NULL OR /* Ko tồn tại đơn nghỉ*/
					CT.SoNgayNghi < C.NgayCong /*Nghỉ ko full ngày*/
				)
				AND DTCC.EmpID IS NOT NULL

				/*Ko check in*/
				INSERT INTO [#MESS_TableEmp_InOut](EmpID,[Type])
				SELECT E.EmpID,4
				FROM TS_tblAssignEmpWorkDetails (NOLOCK) A
				LEFT JOIN MB_tblLogNotificationMobility (nolock) B on B.EmpID = A.EmpID and B.DateID = A.DateID and B.TypeID = 4
				--INNER JOIN @tEmp_ E ON E.EmpID = A.EmpID
				INNER JOIN [#MESS_TableEmp_List] E ON E.EmpID = A.EmpID
				INNER JOIN LS_tblShift (NOLOCK) C on C.LSShiftID = A.LSShiftID
				LEFT JOIN
				(
					SELECT TS.EmpID 
					FROM TS_tblDownloadFile (NOLOCK) TS 
					--INNER JOIN @tEmp_ E ON E.EmpID = TS.EmpID
					INNER JOIN [#MESS_TableEmp_List] E ON E.EmpID = TS.EmpID
					WHERE CONVERT(DATE,DateID) = CONVERT(DATE,@dDateID)
					AND (TS.CheckInOut = 0 OR TS.CheckInOutApp = 0 OR (TS.CheckInOut IS NULL AND TS.CheckInOutApp IS NULL))
					GROUP BY TS.EmpID
				) TS ON TS.EmpID = A.EmpID
				WHERE A.DateID = CONVERT(DATE,@dDateID)
				AND B.EmpID IS NULL /*Chưa tồn tại trong table log*/
				AND (TS.EmpID is null OR @CustomerID = '153') /* Những nhân viên chưa check in trong ngày hoặc SHB thì bắn all*/
				AND 
				(
					(@CustomerID <> '153' AND @dNow > DATEADD(MINUTE,ISNULL(C.PhutLamBatDau,0),DATEADD(HOUR,ISNULL(C.GioLamBatDau,0),@TG))) OR
					(@CustomerID = '153' AND @dNow > CASE WHEN E.AM_PM = 1 THEN DATEADD(MINUTE,ISNULL(C.PhutNghiTruaKetThuc,0),DATEADD(HOUR,ISNULL(C.GioNghiTruaKetThuc,0),@TG_)) ELSE DATEADD(MINUTE,ISNULL(C.PhutLamBatDau,0),DATEADD(HOUR,ISNULL(C.GioLamBatDau,0),@TG_)) END )
				) /* Quá thời gian thiết lập thì cảnh báo */
				AND (@CustomerID = '153' OR @dNow BETWEEN DATEADD(MINUTE,ISNULL(C.PhutLamBatDau,0),DATEADD(HOUR,ISNULL(C.GioLamBatDau,0),@TG)) AND DATEADD(MINUTE,ISNULL(C.PhutLamKetThuc,0),DATEADD(HOUR,ISNULL(C.GioLamKetThuc,0),@TG)))
				AND @dNow <= DATEADD(MINUTE,ISNULL(C.PhutLamKetThuc,0),DATEADD(HOUR,ISNULL(C.GioLamKetThuc,0),@TG))

				/*Ko check out*/
				INSERT INTO [#MESS_TableEmp_InOut](EmpID,[Type])
				SELECT E.EmpID, 6
				FROM TS_tblAssignEmpWorkDetails (NOLOCK) A
				LEFT JOIN MB_tblLogNotificationMobility (nolock) B on B.EmpID = A.EmpID and B.DateID = A.DateID and B.TypeID = 6
				--INNER JOIN @tEmp_ E ON E.EmpID = A.EmpID
				INNER JOIN [#MESS_TableEmp_List] E ON E.EmpID = A.EmpID
				INNER JOIN LS_tblShift (NOLOCK) C on C.LSShiftID = A.LSShiftID
				LEFT JOIN
				(
					SELECT TS.EmpID 
					FROM TS_tblDownloadFile (NOLOCK) TS 
					--INNER JOIN @tEmp E ON E.EmpID = TS.EmpID
					INNER JOIN [#MESS_TableEmp_List] E ON E.EmpID = TS.EmpID
					WHERE CONVERT(DATE,DateID) = CONVERT(DATE,@dDateID)
					AND (TS.CheckInOut = 1 OR TS.CheckInOutApp = 1 OR (TS.CheckInOut IS NULL AND TS.CheckInOutApp IS NULL))
					GROUP BY TS.EmpID
				) TS ON TS.EmpID = A.EmpID
				WHERE A.DateID = CONVERT(DATE,@dDateID)
				AND B.EmpID IS NULL /*Chưa tồn tại trong table log*/
				AND (TS.EmpID is null OR @CustomerID = '153') /* Những nhân viên chưa check out trong ngày hoặc SHB thì bắn all*/
				AND (@dNow > CASE WHEN E.AM_PM = 2 THEN DATEADD(MINUTE,ISNULL(C.PhutNghiTruaBatDau,0),DATEADD(HOUR,ISNULL(C.GioNghiTruaBatDau,0),@TG)) ELSE DATEADD(MINUTE,ISNULL(C.PhutLamKetThuc,0),DATEADD(HOUR,ISNULL(C.GioLamKetThuc,0),@TG)) END) /* Quá thời gian thiết lập thì cảnh báo */

				INSERT INTO MB_tblLogNotificationMobility (EmpID,DateID,ThongBaoVN,ThongBaoEN,TypeID,IsSuccess,ActionTime)
				SELECT EmpID,@dDateID,
						CONVERT(NVARCHAR(10),@dDateID,103) + '$' +
						CASE WHEN L.[Type] = 4 THEN N'checkin' ELSE N'checkout' END + '$' +
						CASE WHEN L.[Type] = 4 THEN N'check in' ELSE N'check out' END,
						CONVERT(NVARCHAR(10),@dDateID,103) + '$' +
						CASE WHEN L.[Type] = 4 THEN N'checkin' ELSE N'checkout' END + '$' +
						CASE WHEN L.[Type] = 4 THEN N'check in' ELSE N'check out' END,
						[Type],1,GETDATE()
				FROM [#MESS_TableEmp_InOut] (NOLOCK) L

				INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
				SELECT /*TOP 1*/ D.UserGroupID AS UserID, 
						N'NHACNHOCHECKINOUT' AS Code,
						CONVERT(NVARCHAR(10),@dDateID,103) + '$' +
						CASE WHEN L.[Type] = 4 THEN N'checkin' ELSE N'checkout' END + '$' +
						CASE WHEN L.[Type] = 4 THEN N'check in' ELSE N'check out' END AS Param,
						NULL AS MaQuiTrinh,
						NULL AS ScreenType,
						NULL AS RecordID
				FROM [#MESS_TableEmp_InOut] (NOLOCK) L
				OUTER APPLY dbo.TS_fnTableUserAccountByEmp(L.EmpID,GETDATE()) D
				WHERE D.UserGroupID IS NOT NULL 
			END
			ELSE IF @Type = 'PaySlip'
			BEGIN
				--Xử lý gửi noti tương tự email
				IF OBJECT_ID('tempdb..#MESS_TableEmp_PaySlip') IS NOT NULL
					DROP TABLE dbo.[#MESS_TableEmp_PaySlip]

				CREATE TABLE [#MESS_TableEmp_PaySlip] (STT INT IDENTITY(1,1),PRPaySlipEmpID int, EmpID INT,ThangNam varchar(7))
				CREATE INDEX IX_MESS_TableEmp_PaySlip_STT_EmpID ON [#MESS_TableEmp_PaySlip](STT,PRPaySlipEmpID, EmpID)

				DECLARE @SoMailGuiToiDa INT, @RowLimit int
				SELECT TOP 1    @SoMailGuiToiDa = SoMailGuiToiDa
				FROM SYS_tblSetupSendMail(NOLOCK)

				IF EXISTS(SELECT TOP 1 1 FROM PR_tblSalarySetup(NOLOCK) WHERE SendMailPayslip_SetupSendMail = 1) and @SoMailGuiToiDa > 0
				BEGIN 
					Set @RowLimit = @SoMailGuiToiDa
				END
				ELSE
				BEGIN
					SET @RowLimit = 999999999
				END
				
				Declare @CurDD smallint = Day(@dDateID)
				Declare @CurMMYYYY varchar(7) = Right(Convert(varchar(10),@dDateID,103),7)
				DECLARE @PreMMYYYY VARCHAR(7) = RIGHT(CONVERT(VARCHAR(10),DATEADD(MONTH,-1,@dDateID),103),7)
				
				
				INSERT INTO [#MESS_TableEmp_PaySlip](PRPaySlipEmpID,EmpID,ThangNam)
				SELECT TOP(@RowLimit) A.PRPaySlipEmpID, A.EmpID, A.Month
				FROM PR_tblPaySlipEmp(NOLOCK) A
				INNER JOIN @tEmp E ON A.EmpID = E.EmpID
				LEFT JOIN PR_tblPaySlipTemplate(NOLOCK) B ON A.PaySlipTemplateID = B.PaySlipTemplateID 
				WHERE (A.Noti = 0 OR A.Noti IS NULL)
				AND (A.Noti_Processing IS NULL OR A.Noti_Processing=0)
				AND (
						(
							B.WebViewDate IS NOT NULL 
							AND @CurDD = B.WebViewDate
							AND 
							(
								(B.IsNextMonth = 1 AND RIGHT('0'+A.Month,7) = @PreMMYYYY)
								OR
								((B.IsNextMonth = 0 OR B.IsNextMonth IS NULL) AND RIGHT('0'+A.Month,7) = @CurMMYYYY)
							)
						)
						OR 
						(
							B.WebViewDate IS NULL
							AND (RIGHT('0'+A.Month,7) = @CurMMYYYY)
						)
					)
				ORDER BY A.CreateTime DESC

				--Cập nhật trạng thái đang xử lý
				UPDATE A
				SET A.Noti_Processing = 1
				FROM PR_tblPaySlipEmp A
				INNER JOIN [#MESS_TableEmp_PaySlip] I ON A.PRPaySlipEmpID = I.PRPaySlipEmpID

				INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
				SELECT	--Case when @dDateID='2024-04-01' then 'admintanlong' else D.UserGroupID end AS UserID, 
						D.UserGroupID AS UserID, 
						N'PS01' AS Code,
						L.ThangNam AS Param,
						1009 AS MaQuiTrinh,
						3 AS ScreenType,
						L.PRPaySlipEmpID AS RecordID
				FROM [#MESS_TableEmp_PaySlip] (NOLOCK) L
				OUTER APPLY dbo.TS_fnTableUserAccountByEmp(L.EmpID,GETDATE()) D
				WHERE D.UserGroupID IS NOT NULL AND L.ThangNam IS NOT NULL AND L.ThangNam<>''
			END
			ELSE IF @Type = 'KeHoachNghiPhepNam' /*Rlog 23898 - TungTT83 - MESSER - 26/08/2025*/
			BEGIN
				IF OBJECT_ID('tempdb..#MESS_TableEmp_KeHoachNghiPhepNam') IS NOT NULL
					DROP TABLE dbo.[#MESS_TableEmp_KeHoachNghiPhepNam]

				CREATE TABLE [#MESS_TableEmp_KeHoachNghiPhepNam] 
				(
					[EmpID] INT,
					[TuNgay] VARCHAR(10), 
					[DenNgay] VARCHAR(10)
				)

				INSERT INTO [#MESS_TableEmp_KeHoachNghiPhepNam] ([EmpID], [TuNgay], [DenNgay])
			    EXEC TS_spfrmAutoReminder @Activity='GetAnnualLeave', @IsMess='1' --Lấy như này cho nhanh

				INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
				SELECT	D.UserGroupID AS UserID, 
						N'KEHOACHNGHIPHEPNAM' AS Code,
						L.TuNgay + '$' + L.DenNgay AS [Param],
						NULL AS MaQuiTrinh,
						NULL AS ScreenType,
						NULL AS RecordID
				FROM [#MESS_TableEmp_KeHoachNghiPhepNam] (NOLOCK) L
				OUTER APPLY dbo.TS_fnTableUserAccountByEmp(L.EmpID,GETDATE()) D
				WHERE D.UserGroupID IS NOT NULL 
			END
			ELSE IF @Type = 'HappyBirthDay' /*TanND35 RLOGID 25629*/
			BEGIN
				IF OBJECT_ID('tempdb..#MESS_TableEmp_HappyBirthDay') IS NOT NULL
					DROP TABLE dbo.[#MESS_TableEmp_HappyBirthDay]
				
				CREATE TABLE [#MESS_TableEmp_HappyBirthDay] (STT INT IDENTITY(1,1),EmpID INT,MESS NVARCHAR(MAX))
				CREATE INDEX IX_MESS_TableEmp_HappyBirthDay_STT_EmpID_SoLuong ON [#MESS_TableEmp_HappyBirthDay](EmpID)

				INSERT INTO [#MESS_TableEmp_HappyBirthDay](EmpID,MESS)
				SELECT 
					E.EmpID,
					REPLACE(
						REPLACE(
							REPLACE(
								T.MauCauChuc,
								'$XungHo$', CASE WHEN @LanguageID = 'VN' THEN CASE WHEN ISNULL(E.Gender,1) = 1 THEN N'Anh' ELSE N'Chị' END ELSE N'' END
							),
							'$TenNV$', CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END
						),
						'$ChucVu$', CASE WHEN @LanguageID = 'VN' THEN C.TenChucVuV ELSE C.TenChucVuE END
					) AS MESS
				FROM HR_vemp (NOLOCK)   E
				INNER JOIN @tEmp tE ON tE.EmpID = E.EmpID
				LEFT JOIN (
					SELECT 
						LSChucVuID,
						MauCauChuc,
						ROW_NUMBER() OVER (PARTITION BY LSChucVuID ORDER BY NEWID()) AS rn
					FROM TS_tblThietLapCauChucMungTheoChucVu (NOLOCK)
				) T ON T.LSChucVuID = E.LSChucVuID AND T.rn = 1
				LEFT JOIN LS_tblChucVu (NOLOCK) C ON C.LSChucVuID = T.LSChucVuID
				WHERE 
					E.Dob IS NOT NULL
					AND DAY(E.Dob)   = DAY(@dDateID)
					AND MONTH(E.Dob) =  MONTH(@dDateID)
				INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
				SELECT /*TOP 1*/ D.UserGroupID AS UserID, 
						N'HPPD' AS Code,
						L.MESS AS Param,
						NULL AS MaQuiTrinh,
						NULL AS ScreenType,
						NULL AS RecordID
				FROM [#MESS_TableEmp_HappyBirthDay] (NOLOCK) L
				OUTER APPLY dbo.TS_fnTableUserAccountByEmp(L.EmpID,GETDATE()) D
				WHERE D.UserGroupID IS NOT NULL 
			END
		END

		IF @Type IN ('TimesheetConfirmation')
		BEGIN
			SELECT dbo.ChuyenHaiKyTu(B.[Month]) + '/' + CONVERT(NVARCHAR, B.[Year]) AS [Month], B.Creater, B.StatusID, pro.Approver, B.Editer
			INTO #tmptempTimesheetConf
			FROM dbo.split(@RecordIDList,'@') A
			LEFT JOIN TS_tblTSConfirmation(NOLOCK) B ON A.items = B.Id
			LEFT JOIN
			(
				SELECT P.*
				FROM TS_tblTSConfirmationProcess(NOLOCK) P 
				INNER JOIN
				(
					SELECT ID, MAX(ProcessID) AS ProcessID
					FROM TS_tblTSConfirmationProcess(NOLOCK) 
					GROUP BY ID
				) B ON B.ProcessID = P.ProcessID
			) PRO ON PRO.ID = B.ID
			GROUP BY B.[Month], B.[Year], B.Creater, B.StatusID, pro.Approver, B.Editer

			/*Noti cho cấp trên*/
			SELECT	
					CASE WHEN L.StatusID = 2 THEN L.Approver 
						WHEN L.StatusID = 3 THEN L.Creater 
						WHEN L.StatusID = 4 THEN L.Creater 
					END AS UserID,
					CASE WHEN L.StatusID = 2 THEN 'WS02'
						WHEN L.StatusID = 3 THEN 'WS04'
						WHEN L.StatusID = 4 THEN 'WS05' 
					END AS Code,
					CONVERT(NVARCHAR(12),L.[Month]) + '$' + 
					CASE WHEN L.StatusID = 2 THEN CASE WHEN @LanguageID = 'VN' THEN E2.EmpName ELSE E2.EmpName_Unsign END
						WHEN L.StatusID = 3 THEN CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END
						WHEN L.StatusID = 4 THEN CASE WHEN @LanguageID = 'VN' THEN E2.EmpName ELSE E2.EmpName_Unsign END
					END
					AS [Param],
					'1005' AS MaQuiTrinh,
					CASE WHEN L.StatusID = 2 THEN 2
						WHEN L.StatusID = 3 THEN 2
						WHEN L.StatusID = 4 THEN 1 
					END AS ScreenType,
					-1 AS RecordID
			FROM #tmptempTimesheetConf (NOLOCK) L
			LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.Approver
			LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
			LEFT JOIN UMS_tblUserAccount (NOLOCK) U2 ON U2.UserGroupID = L.Editer
			LEFT JOIN HR_vEmp (NOLOCK) E2 ON E2.EmpID = U2.EmpID
			RETURN
		END
		ELSE IF @Type IN ('ContractReminder')
		BEGIN
			IF NOT EXISTS (SELECT TOP 1 * FROM MESS_tblFunction(NOLOCK) WHERE ID=139 AND Active = 1) RETURN
			SET @RecordIDList = REPLACE(@RecordIDList,';','')
			SELECT B.EmpID
			INTO #tmptempEmp
			FROM dbo.split(@RecordIDList,'$') A
			LEFT JOIN HR_vEmp(NOLOCK) B ON A.items = B.Email
			GROUP BY B.EmpID
			CREATE INDEX ix_EmpID ON #tmptempEmp(EmpID)
			/*Noti cho cấp trên*/
			SELECT	
					ISNULL(OA1.UserGroupID,OA2.UserGroupID) AS UserID,
					'ACRE09' AS Code,
					CASE WHEN @LanguageID = 'VN' THEN N'Bạn có danh sách nhân viên cần đánh giá tái ký hợp đồng lao động' ELSE N'You have a list of employees who need to be evaluated for re-employment.' END 
					AS [Param],
					'63' AS MaQuiTrinh,
					2 AS ScreenType,
					'-3#-1#21000101' AS RecordID
			FROM #tmptempEmp (NOLOCK) L
			OUTER APPLY 
			(
				SELECT TOP(1) UserGroupID
				FROM UMS_tblUserAccount(NOLOCK) u1
				WHERE u1.EmpID = L.EmpID AND u1.MaLoaiNguoiDung='2' AND (Removed IS NULL OR Removed = 0)/*Người dùng phụ*/
			)OA1
			OUTER APPLY 
			(
				SELECT TOP(1) UserGroupID
				FROM UMS_tblUserAccount(NOLOCK) u1
				WHERE u1.EmpID = L.EmpID AND u1.MaLoaiNguoiDung='1' AND (Removed IS NULL OR Removed = 0)/*Người dùng chính*/
			)OA2
			WHERE (OA1.UserGroupID IS NOT NULL OR OA2.UserGroupID IS NOT NULL)
			RETURN
		END
		ELSE IF @Type IN ('ProbationReminder','ProbationReminder1')
		BEGIN
			IF NOT EXISTS (SELECT TOP 1 * FROM MESS_tblFunction(NOLOCK) WHERE ID=136 AND Active = 1) RETURN
			SET @RecordIDList = REPLACE(@RecordIDList,';','')
			SELECT B.EmpID
			INTO #tmptempEmp1
			FROM dbo.split(@RecordIDList,'$') A
			LEFT JOIN HR_vEmp(NOLOCK) B ON A.items = B.Email
			GROUP BY B.EmpID
			CREATE INDEX ix_EmpID ON #tmptempEmp1(EmpID)
			
			IF @Type = 'ProbationReminder'
			BEGIN
				SELECT	
						ISNULL(OA1.UserGroupID,OA2.UserGroupID) AS UserID,
						'EP06' AS Code,
						CONVERT(NVARCHAR(12),ct.ToDate,103) AS [Param],
						'64' AS MaQuiTrinh,
						1 AS ScreenType,
						'-3#-1' AS RecordID
				FROM #tmptempEmp1 (NOLOCK) L
				OUTER APPLY 
				(
					SELECT TOP(1) UserGroupID
					FROM UMS_tblUserAccount(NOLOCK) u1
					WHERE u1.EmpID = L.EmpID AND u1.MaLoaiNguoiDung='2' AND (Removed IS NULL OR Removed = 0)/*Người dùng phụ*/
				)OA1
				OUTER APPLY 
				(
					SELECT TOP(1) UserGroupID
					FROM UMS_tblUserAccount(NOLOCK) u1
					WHERE u1.EmpID = L.EmpID AND u1.MaLoaiNguoiDung='1' AND (Removed IS NULL OR Removed = 0)/*Người dùng chính*/
				)OA2
				LEFT JOIN HR_tblContract(NOLOCK) ct ON L.EmpID = ct.EmpID
				WHERE (OA1.UserGroupID IS NOT NULL OR OA2.UserGroupID IS NOT NULL)
			END
			ELSE/*Noti cho cấp trên*/
			BEGIN
				SELECT	
						ISNULL(OA1.UserGroupID,OA2.UserGroupID) AS UserID,
						'EP01' AS Code,
						CASE WHEN @LanguageID = 'VN' THEN N'Bạn có danh sách nhân viên cần đánh giá thử việc' ELSE N'You have a list of employees that need probationary evaluation.' END 
						AS [Param],
						'64' AS MaQuiTrinh,
						2 AS ScreenType,
						'-3#-1' AS RecordID--
				FROM #tmptempEmp1 (NOLOCK) L
				OUTER APPLY 
				(
					SELECT TOP(1) UserGroupID
					FROM UMS_tblUserAccount(NOLOCK) u1
					WHERE u1.EmpID = L.EmpID AND u1.MaLoaiNguoiDung='2' AND (Removed IS NULL OR Removed = 0)/*Người dùng phụ*/
				)OA1
				OUTER APPLY 
				(
					SELECT TOP(1) UserGroupID
					FROM UMS_tblUserAccount(NOLOCK) u1
					WHERE u1.EmpID = L.EmpID AND u1.MaLoaiNguoiDung='1' AND (Removed IS NULL OR Removed = 0)/*Người dùng chính*/
				)OA2
				WHERE (OA1.UserGroupID is not null or OA2.UserGroupID is not null)
			END
			return
		END
		
		-- Nếu tắt thông số và ko phải F88 thì ko chạy
		IF dbo.fnGetCustomerCode() NOT IN ('99','140')
		AND NOT EXISTS (SELECT TOP 1 1 FROM MOBI_tblSetUpMOBI (NOLOCK) WHERE ChoPhepNotiToApp = 1)
		AND @Type <> 'BangLuong'
		BEGIN
			PRINT (N'Chưa bật thông số')
			RETURN
		END

		IF NOT EXISTS (SELECT TOP 1 1 FROM MOBI_tblSetUpMOBI (NOLOCK) WHERE NoTiMailChuyenDuyetPheDuyet = 1)
		AND @Type = 'BangLuong' 
		BEGIN
			PRINT (N'Chưa bật thông số - Noti BangLuong')
			RETURN
		END

		IF OBJECT_ID('tempdb..#MESS_RecordID') IS NOT NULL
			DROP TABLE dbo.[#MESS_RecordID]

		CREATE TABLE [#MESS_RecordID] (STT INT IDENTITY(1,1),RecordID INT,MaQuiTrinh INT)
		CREATE INDEX IX_MESS_RecordID_STT_RecordID_MaQuiTrinh ON [#MESS_RecordID](STT,RecordID,MaQuiTrinh)

		IF OBJECT_ID('tempdb..#tmp_TblQTBanGiao') IS NOT NULL DROP TABLE dbo.[#tmp_TblQTBanGiao]
		CREATE TABLE [#tmp_TblQTBanGiao] (QTBanGiao_MasterID INT, BanGiao_HangMucID INT,LSPhongBanBanGiaoID INT)

		IF OBJECT_ID('tempdb..#temp_TblBanGiaoUser') IS NOT NULL DROP TABLE dbo.[#temp_TblBanGiaoUser]
		CREATE TABLE [#temp_TblBanGiaoUser] (UserGroupID nvarchar(150), LSPhongBanBanGiaoID INT,RecordID INT)

		IF @Type IN ('QTBanGiao')
		BEGIN
			INSERT INTO HR_tblLogNotiAPP (Query, CreateTime)
			SELECT @Type_QTBG + ' - ' + @RecordIDList, GETDATE()

			INSERT INTO #tmp_TblQTBanGiao (QTBanGiao_MasterID, BanGiao_HangMucID, LSPhongBanBanGiaoID)
			SELECT CASE WHEN ISNULL(QTBanGiao_MasterID, '') = '' THEN NULL ELSE QTBanGiao_MasterID END AS QTBanGiao_MasterID,
				CASE WHEN ISNULL(BanGiao_HangMucID, '') = '' THEN NULL ELSE BanGiao_HangMucID END AS BanGiao_HangMucID,
				CASE WHEN ISNULL(A.LSPhongBanBanGiaoID, '') = '' THEN NULL ELSE A.LSPhongBanBanGiaoID END AS LSPhongBanBanGiaoID
			FROM OPENJSON(@RecordIDList) WITH (
				QTBanGiao_MasterID NVARCHAR(20) '$.QTBanGiao_MasterID',
				BanGiao_HangMucID NVARCHAR(20) '$.BanGiao_HangMucID',
				LSPhongBanBanGiaoID NVARCHAR(20) '$.LSPhongBanBanGiaoID'
			) A
			
			INSERT INTO [#MESS_RecordID] (RecordID)
			SELECT DISTINCT A.QTBanGiao_MasterID
			FROM #tmp_TblQTBanGiao (NOLOCK) A
		END
		ELSE IF ISNULL(@RecordIDList,'') = '' AND ISNULL(@MaQuiTrinhList,'') = '' AND ISNULL(@RecordID,'') <> ''
		BEGIN
			INSERT INTO [#MESS_RecordID] (RecordID,MaQuiTrinh)
			VALUES(@RecordID,@MaQuiTrinh)
		END ELSE
		BEGIN
			IF @RecordIDList LIKE N'%$%'
			BEGIN
				INSERT INTO [#MESS_RecordID] (RecordID,MaQuiTrinh)
				SELECT A.items,B.items
				FROM dbo.SplitRowIndex(@RecordIDList,'$') A
				LEFT JOIN dbo.SplitRowIndex(@MaQuiTrinhList,'$') B ON B.rowindex = A.rowindex
				WHERE A.items IS NOT NULL
			END 
			ELSE -- IF @RecordIDList LIKE N'%@%'
			BEGIN
				INSERT INTO [#MESS_RecordID] (RecordID,MaQuiTrinh)
				SELECT A.items,B.items
				FROM dbo.SplitRowIndex(@RecordIDList,'@') A
				LEFT JOIN dbo.SplitRowIndex(@MaQuiTrinhList,'@') B ON B.rowindex = A.rowindex
				WHERE A.items IS NOT NULL
			END
		END

		IF NOT EXISTS (SELECT TOP 1 1 FROM [#MESS_RecordID] (NOLOCK))
		AND NOT EXISTS (SELECT TOP 1 1 FROM [#MESS_spPushNotificationToApp] (NOLOCK)) 
		BEGIN
			PRINT (N'Không có dữ liệu')
			RETURN
		END

		SELECT @STT_MIN = MIN(STT), @STT_MAX = MAX(STT)
		FROM [#MESS_RecordID] (NOLOCK)

		WHILE @STT_MIN <= @STT_MAX
		BEGIN
			SELECT @RecordID = RecordID, @MaQuiTrinh = MaQuiTrinh
			FROM [#MESS_RecordID] (NOLOCK)
			WHERE STT = @STT_MIN

			/*Quy trình đăng ký nghỉ*/
			IF @Type = 'LeaveRecord'
			BEGIN
				SELECT @UserID = CurApprover,
					   @EmpID = EmpID,
					   @StatusID = ApprovedStatus,
					   @Level = ApprovedLevel,
					   @NguoiThayThe = NguoiThayThe,
					   @CCMail = CCMail
				FROM TS_tblLeaveRecord (NOLOCK)
				WHERE LeaveRecordID = @RecordID

				SELECT TOP 1 @LevelProcess = Cap
				FROM TS_tblLeaveRecordProcess (NOLOCK)
				WHERE LeaveRecordID = @RecordID
				ORDER BY CONVERT(BIGINT,LeaveRecordProcessID) DESC

				/*Vừa chuyển đơn*/
				IF @StatusID IN (3,7) AND @Level = 1
				BEGIN
					/*Noti cho người phê duyệt*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT L.CurApprover AS UserID, 
						   CASE WHEN @StatusID = 3 THEN N'PHEP03' ELSE N'PHEP20' END AS Code,
						   CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
						   CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
						   CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END AS Param,
						   CASE WHEN @StatusID = 3 THEN N'1' ELSE N'2' END AS MaQuiTrinh,
						   '2' AS ScreenType,
						   L.LeaveRecordID AS RecordID
					FROM TS_tblLeaveRecord (NOLOCK) L
					LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = L.CurApprover
					WHERE L.LeaveRecordID = @RecordID
					AND P.UserID IS NULL

					IF ISNULL(@NguoiThayThe,'') <> ''
					BEGIN
						SELECT @UserID = UserGroupID FROM dbo.TS_fnTableUserAccountByEmp(@NguoiThayThe,GETDATE())
						IF ISNULL(@UserID,'') <> ''
						BEGIN
							/*Noti cho người thay thế*/
							INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
							SELECT @UserID AS UserID, 
								   CASE WHEN @StatusID = 3 THEN N'PHEP01' ELSE N'PHEP18' END AS Code,
								   CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
								   CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
								   CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END + '$' +
								   CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END AS Param,
								   CASE WHEN @StatusID = 3 THEN N'1' ELSE N'2' END AS MaQuiTrinh,
								   '3' AS ScreenType,
								   L.LeaveRecordID AS RecordID
							FROM TS_tblLeaveRecord (NOLOCK) L
							LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
							LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
							LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.CurApprover
							LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
							LEFT JOIN
							(
								SELECT UserID
								FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
								GROUP BY UserID
							) P ON P.UserID = @UserID
							WHERE L.LeaveRecordID = @RecordID
							AND P.UserID IS NULL
						END
					END
					IF ISNULL(@CCMail,'') <> ''
					BEGIN
						/*Noti cho người liên quan*/
						INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
						SELECT D.UserGroupID AS UserID, 
								CASE WHEN @StatusID = 3 THEN N'PHEP02' ELSE N'PHEP19' END AS Code,
								CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
								CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
								CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END + '$' +
								CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END AS Param,
								CASE WHEN @StatusID = 3 THEN N'1' ELSE N'2' END AS MaQuiTrinh,
								'3' AS ScreenType,
								L.LeaveRecordID AS RecordID
						FROM TS_tblLeaveRecord (NOLOCK) L
						LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
						LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
						LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.CurApprover
						LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
						LEFT JOIN dbo.Split(@CCMail,'$') CC ON 1 = 1
						OUTER APPLY dbo.TS_fnTableUserAccountByEmp(CC.items,GETDATE()) D
						LEFT JOIN
						(
							SELECT UserID
							FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
							GROUP BY UserID
						) P ON P.UserID = D.UserGroupID
						WHERE L.LeaveRecordID = @RecordID
						AND D.UserGroupID IS NOT NULL
						AND P.UserID IS NULL
					END
				END
				/*Vừa rút đơn*/
				ELSE IF @StatusID = 1 AND @Level = 0
				BEGIN
					/*Noti cho người phê duyệt*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT D.NguoiPheDuyet AS UserID, 
						   N'PHEP04' AS Code,
						   CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
						   CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
						   CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END AS Param,
						   '1' AS MaQuiTrinh,
						   '3' AS ScreenType,
						   L.LeaveRecordID AS RecordID
					FROM TS_tblLeaveRecord (NOLOCK) L
					LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					OUTER APPLY
					(
						SELECT TOP 1 P.*
						FROM TS_tblLeaveRecordProcess (NOLOCK) P
						WHERE P.TrangThai = 3
						AND P.LeaveRecordID = L.LeaveRecordID
						ORDER BY CONVERT(BIGINT,P.LeaveRecordProcessID) DESC
					) D
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = D.NguoiPheDuyet
					WHERE L.LeaveRecordID = @RecordID
					AND D.NguoiPheDuyet IS NOT NULL
					AND P.UserID IS NULL
				END
				/*Vừa duyệt trung gian*/
				ELSE IF @StatusID IN (3,7) AND @Level > 1
				BEGIN
					/*Noti cho người phê duyệt*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT L.CurApprover AS UserID, 
						   CASE WHEN @StatusID = 3 THEN N'PHEP08' ELSE N'PHEP24' END AS Code,
						   CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
						   CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
						   CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END AS Param,
						   CASE WHEN @StatusID = 3 THEN N'1' ELSE N'2' END AS MaQuiTrinh,
						   '2' AS ScreenType,
						   L.LeaveRecordID AS RecordID
					FROM TS_tblLeaveRecord (NOLOCK) L
					LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = L.CurApprover
					WHERE L.LeaveRecordID = @RecordID
					AND P.UserID IS NULL

					IF ISNULL(@NguoiThayThe,'') <> ''
					BEGIN
						SELECT @UserID = UserGroupID FROM dbo.TS_fnTableUserAccountByEmp(@NguoiThayThe,GETDATE())
						IF ISNULL(@UserID,'') <> ''
						BEGIN
							/*Noti cho người thay thế*/
							INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
							SELECT @UserID AS UserID, 
								   CASE WHEN @StatusID = 3 THEN N'PHEP06' ELSE N'PHEP22' END AS Code,
								   CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
								   CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
								   CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END + '$' +
								   CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END AS Param,
								   CASE WHEN @StatusID = 3 THEN N'1' ELSE N'2' END AS MaQuiTrinh,
								   '3' AS ScreenType,
								   L.LeaveRecordID AS RecordID
							FROM TS_tblLeaveRecord (NOLOCK) L
							LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
							LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
							LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.CurApprover
							LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
							LEFT JOIN
							(
								SELECT UserID
								FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
								GROUP BY UserID
							) P ON P.UserID = @UserID
							WHERE L.LeaveRecordID = @RecordID
							AND P.UserID IS NULL
						END
					END
					IF ISNULL(@CCMail,'') <> ''
					BEGIN
						/*Noti cho người liên quan*/
						INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
						SELECT D.UserGroupID AS UserID, 
								CASE WHEN @StatusID = 3 THEN N'PHEP07' ELSE N'PHEP23' END AS Code,
								CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
								CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
								CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END + '$' +
								CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END AS Param,
								CASE WHEN @StatusID = 3 THEN N'1' ELSE N'2' END AS MaQuiTrinh,
								'3' AS ScreenType,
								L.LeaveRecordID AS RecordID
						FROM TS_tblLeaveRecord (NOLOCK) L
						LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
						LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
						LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.CurApprover
						LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
						LEFT JOIN dbo.Split(@CCMail,'$') CC ON 1 = 1
						OUTER APPLY dbo.TS_fnTableUserAccountByEmp(CC.items,GETDATE()) D
						LEFT JOIN
						(
							SELECT UserID
							FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
							GROUP BY UserID
						) P ON P.UserID = D.UserGroupID
						WHERE L.LeaveRecordID = @RecordID
						AND D.UserGroupID IS NOT NULL
						AND P.UserID IS NULL
					END

					/*Noti cho người tạo đơn*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT L.Creater AS UserID, 
							CASE WHEN @StatusID = 3 THEN N'PHEP05' ELSE N'PHEP21' END AS Code,
							CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
							CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
							CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END AS Param,
							CASE WHEN @StatusID = 3 THEN N'1' ELSE N'2' END AS MaQuiTrinh,
							'1' AS ScreenType,
							L.LeaveRecordID AS RecordID
					FROM TS_tblLeaveRecord (NOLOCK) L
					LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.CurApprover
					LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = L.Creater
					WHERE L.LeaveRecordID = @RecordID
					AND P.UserID IS NULL

					/*Noti cho cấp trung gian*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT A.NguoiPheDuyet AS UserID, 
							CASE WHEN @StatusID = 3 THEN N'PHEP09' ELSE N'PHEP25' END AS Code,
							CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
							CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
							CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END + '$' +
							CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END AS Param,
							CASE WHEN @StatusID = 3 THEN N'1' ELSE N'2' END AS MaQuiTrinh,
							'3' AS ScreenType,
							L.LeaveRecordID AS RecordID
					FROM TS_tblLeaveRecord (NOLOCK) L
					LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.CurApprover
					LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
					LEFT JOIN
					(
						SELECT A.*
						FROM TS_tblLeaveRecordProcess (NOLOCK) A
						INNER JOIN
						(
							SELECT Cap,LeaveRecordID, MAX(CONVERT(BIGINT,LeaveRecordProcessID)) AS LeaveRecordProcessID
							FROM TS_tblLeaveRecordProcess (NOLOCK)
							GROUP BY LeaveRecordID,Cap
						) B ON B.LeaveRecordProcessID = A.LeaveRecordProcessID
						WHERE A.NguoiPheDuyet IS NOT NULL
						AND
						(
							(@StatusID = 3 AND A.TrangThai <= 5) OR
							(@StatusID = 7 AND A.TrangThai > 5) 
						)
						AND A.Cap < @LevelProcess
					) A ON A.LeaveRecordID = L.LeaveRecordID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = A.NguoiPheDuyet
					WHERE L.LeaveRecordID = @RecordID
					AND P.UserID IS NULL
				END
				/*Vừa duyệt cấp cuối*/
				ELSE IF @StatusID IN (4,8)
				BEGIN
					/*Noti cho người tạo đơn*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT L.Creater AS UserID, 
							CASE WHEN @StatusID = 4 THEN N'PHEP10' ELSE N'PHEP26' END  AS Code,
							CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
							CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END AS Param,
							CASE WHEN @StatusID = 4 THEN N'1' ELSE N'2' END AS MaQuiTrinh,
							'1' AS ScreenType,
							L.LeaveRecordID AS RecordID
					FROM TS_tblLeaveRecord (NOLOCK) L
					LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.CurApprover
					LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = L.Creater
					WHERE L.LeaveRecordID = @RecordID
					AND P.UserID IS NULL

					IF ISNULL(@NguoiThayThe,'') <> ''
					BEGIN
						SELECT @UserID = UserGroupID FROM dbo.TS_fnTableUserAccountByEmp(@NguoiThayThe,GETDATE())
						IF ISNULL(@UserID,'') <> ''
						BEGIN
							/*Noti cho người thay thế*/
							INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
							SELECT @UserID AS UserID, 
									CASE WHEN @StatusID = 4 THEN N'PHEP11' ELSE N'PHEP27' END AS Code,
									CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
									CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
									CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END AS Param,
									CASE WHEN @StatusID = 4 THEN N'1' ELSE N'2' END AS MaQuiTrinh,
									'3' AS ScreenType,
									L.LeaveRecordID AS RecordID
							FROM TS_tblLeaveRecord (NOLOCK) L
							LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
							LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
							LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.CurApprover
							LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
							LEFT JOIN
							(
								SELECT UserID
								FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
								GROUP BY UserID
							) P ON P.UserID = @UserID
							WHERE L.LeaveRecordID = @RecordID
							AND P.UserID IS NULL
						END
					END
					IF ISNULL(@CCMail,'') <> ''
					BEGIN
						/*Noti cho người liên quan*/
						INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
						SELECT D.UserGroupID AS UserID, 
								CASE WHEN @StatusID = 4 THEN N'PHEP12' ELSE N'PHEP28' END  AS Code,
								CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
								CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
								CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END AS Param,
								CASE WHEN @StatusID = 4 THEN N'1' ELSE N'2' END AS MaQuiTrinh,
								'3' AS ScreenType,
								L.LeaveRecordID AS RecordID
						FROM TS_tblLeaveRecord (NOLOCK) L
						LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
						LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
						LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.CurApprover
						LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
						LEFT JOIN dbo.Split(@CCMail,'$') CC ON 1 = 1
						OUTER APPLY dbo.TS_fnTableUserAccountByEmp(CC.items,GETDATE()) D
						LEFT JOIN
						(
							SELECT UserID
							FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
							GROUP BY UserID
						) P ON P.UserID = D.UserGroupID
						WHERE L.LeaveRecordID = @RecordID
						AND D.UserGroupID IS NOT NULL
						AND P.UserID IS NULL
					END

					/*Noti cho cấp trung gian*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT A.NguoiPheDuyet AS UserID, 
							CASE WHEN @StatusID = 4 THEN N'PHEP13' ELSE N'PHEP29' END AS Code,
							CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
							CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
							CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END AS Param,
							CASE WHEN @StatusID = 4 THEN N'1' ELSE N'2' END AS MaQuiTrinh,
							'3' AS ScreenType,
							L.LeaveRecordID AS RecordID
					FROM TS_tblLeaveRecord (NOLOCK) L
					LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.CurApprover
					LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
					LEFT JOIN
					(
						SELECT A.*
						FROM TS_tblLeaveRecordProcess (NOLOCK) A
						INNER JOIN
						(
							SELECT Cap,LeaveRecordID, MAX(CONVERT(BIGINT,LeaveRecordProcessID)) AS LeaveRecordProcessID
							FROM TS_tblLeaveRecordProcess (NOLOCK)
							GROUP BY LeaveRecordID,Cap
						) B ON B.LeaveRecordProcessID = A.LeaveRecordProcessID
						WHERE A.NguoiPheDuyet IS NOT NULL
						AND
						(
							(@StatusID = 4 AND A.TrangThai <= 5) OR
							(@StatusID = 8 AND A.TrangThai > 5) 
						)
					) A ON A.LeaveRecordID = L.LeaveRecordID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = A.NguoiPheDuyet
					WHERE L.LeaveRecordID = @RecordID
					AND P.UserID IS NULL

					-- Rlog 25761 - PMC
					IF @IsNotifyCCOnLeaveRecordApproved = 1
					BEGIN
						TRUNCATE TABLE [#MESS_spPushNotificationToApp_UserID]
						INSERT INTO [#MESS_spPushNotificationToApp_UserID] (UserID)
						EXEC MESS_GetUserCcMailForLeaveRecord @UserGroupID=@UserGroupID,@WorkLowID= @MaQuiTrinh,@RecordID=@RecordID,@EmpID=@EmpID,@Type=2
						
						/*Noti cho CCmail Done*/
						INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
						SELECT A.UserID AS UserID, 
								CASE WHEN @StatusID = 4 THEN N'PHEP34' ELSE N'PHEP37' END AS Code,
								CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
								CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END + '$' +
								E.EmpCode + '$' +
								CONVERT(NVARCHAR(10),L.FromDate,103) + '$' +
								CONVERT(NVARCHAR(10),L.ToDate,103) + '$' +
								RTRIM(L.LeaveTaken) AS Param,
								CASE WHEN @StatusID = 4 THEN N'1' ELSE N'2' END AS MaQuiTrinh,
								'3' AS ScreenType,
								L.LeaveRecordID AS RecordID
						FROM TS_tblLeaveRecord (NOLOCK) L
						LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
						LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
						LEFT JOIN [#MESS_spPushNotificationToApp_UserID] (NOLOCK) A ON 1 = 1
						LEFT JOIN
						(
							SELECT UserID
							FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
							GROUP BY UserID
						) P ON P.UserID = A.UserID
						WHERE L.LeaveRecordID = @RecordID
						AND A.UserID IS NOT NULL AND P.UserID IS NULL
					END
				END
				/*Vừa từ chối*/
				ELSE IF @StatusID IN (5,9) and @Level = 0
				BEGIN
					/*Noti cho người tạo đơn*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT L.Creater AS UserID, 
							CASE WHEN @StatusID = 5 THEN N'PHEP14' ELSE N'PHEP30' END AS Code,
							CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
							CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
							CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END AS Param,
							CASE WHEN @StatusID = 5 THEN N'1' ELSE N'2' END AS MaQuiTrinh,
							'1' AS ScreenType,
							L.LeaveRecordID AS RecordID
					FROM TS_tblLeaveRecord (NOLOCK) L
					LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					OUTER APPLY
					(
						SELECT TOP 1 P.*
						FROM TS_tblLeaveRecordProcess (NOLOCK) P
						WHERE P.TrangThai = @StatusID
						AND P.LeaveRecordID = L.LeaveRecordID
						ORDER BY CONVERT(BIGINT,P.LeaveRecordProcessID) DESC
					) D
					LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = D.Editer
					LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = L.Creater
					WHERE L.LeaveRecordID = @RecordID
					AND P.UserID IS NULL

					IF ISNULL(@NguoiThayThe,'') <> ''
					BEGIN
						SELECT @UserID = UserGroupID FROM dbo.TS_fnTableUserAccountByEmp(@NguoiThayThe,GETDATE())
						IF ISNULL(@UserID,'') <> ''
						BEGIN
							/*Noti cho người thay thế*/
							INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
							SELECT @UserID AS UserID, 
									CASE WHEN @StatusID = 5 THEN N'PHEP15' ELSE N'PHEP31' END AS Code,
									CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
									CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
									CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END + '$' +
									CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END AS Param,
									CASE WHEN @StatusID = 5 THEN N'1' ELSE N'2' END AS MaQuiTrinh,
									'3' AS ScreenType,
									L.LeaveRecordID AS RecordID
							FROM TS_tblLeaveRecord (NOLOCK) L
							LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
							LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
							OUTER APPLY
							(
								SELECT TOP 1 P.*
								FROM TS_tblLeaveRecordProcess (NOLOCK) P
								WHERE P.TrangThai = @StatusID
								AND P.LeaveRecordID = L.LeaveRecordID
								ORDER BY CONVERT(BIGINT,P.LeaveRecordProcessID) DESC
							) D
							LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = D.Editer
							LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
							LEFT JOIN
							(
								SELECT UserID
								FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
								GROUP BY UserID
							) P ON P.UserID = @UserID
							WHERE L.LeaveRecordID = @RecordID
							AND P.UserID IS NULL
						END
					END
					IF ISNULL(@CCMail,'') <> ''
					BEGIN
						/*Noti cho người liên quan*/
						INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
						SELECT D.UserGroupID AS UserID, 
								CASE WHEN @StatusID = 5 THEN N'PHEP16' ELSE N'PHEP32' END AS Code,
								CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
								CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
								CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END + '$' +
								CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END AS Param,
								CASE WHEN @StatusID = 5 THEN N'1' ELSE N'2' END AS MaQuiTrinh,
								'3' AS ScreenType,
								L.LeaveRecordID AS RecordID
						FROM TS_tblLeaveRecord (NOLOCK) L
						LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
						LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
						OUTER APPLY
						(
							SELECT TOP 1 P.*
							FROM TS_tblLeaveRecordProcess (NOLOCK) P
							WHERE P.TrangThai = @StatusID
							AND P.LeaveRecordID = L.LeaveRecordID
							ORDER BY CONVERT(BIGINT,P.LeaveRecordProcessID) DESC
						) DD
						LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = DD.Editer
						LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
						LEFT JOIN dbo.Split(@CCMail,'$') CC ON 1 = 1
						OUTER APPLY dbo.TS_fnTableUserAccountByEmp(CC.items,GETDATE()) D
						LEFT JOIN
						(
							SELECT UserID
							FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
							GROUP BY UserID
						) P ON P.UserID = D.UserGroupID
						WHERE L.LeaveRecordID = @RecordID
						AND D.UserGroupID IS NOT NULL
						AND P.UserID IS NULL
					END

					/*Noti cho cấp trung gian*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT A.NguoiPheDuyet AS UserID, 
							CASE WHEN @StatusID = 5 THEN N'PHEP17' ELSE N'PHEP33' END AS Code,
							CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
							CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
							CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END + '$' +
							CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END AS Param,
							CASE WHEN @StatusID = 5 THEN N'1' ELSE N'2' END AS MaQuiTrinh,
							'3' AS ScreenType,
							L.LeaveRecordID AS RecordID
					FROM TS_tblLeaveRecord (NOLOCK) L
					LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					OUTER APPLY
					(
						SELECT TOP 1 P.*
						FROM TS_tblLeaveRecordProcess (NOLOCK) P
						WHERE P.TrangThai = @StatusID
						AND P.LeaveRecordID = L.LeaveRecordID
						ORDER BY CONVERT(BIGINT,P.LeaveRecordProcessID) DESC
					) DD
					LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = DD.Editer
					LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
					LEFT JOIN
					(
						SELECT A.*
						FROM TS_tblLeaveRecordProcess (NOLOCK) A
						INNER JOIN
						(
							SELECT Cap,LeaveRecordID, MAX(CONVERT(BIGINT,LeaveRecordProcessID)) AS LeaveRecordProcessID
							FROM TS_tblLeaveRecordProcess (NOLOCK)
							GROUP BY LeaveRecordID,Cap
						) B ON B.LeaveRecordProcessID = A.LeaveRecordProcessID
						WHERE A.NguoiPheDuyet IS NOT NULL
						AND
						(
							(@StatusID = 5 AND A.TrangThai <= 5) OR
							(@StatusID = 9 AND A.TrangThai > 5) 
						)
						AND A.Cap < @LevelProcess
					) A ON A.LeaveRecordID = L.LeaveRecordID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = A.NguoiPheDuyet
					WHERE L.LeaveRecordID = @RecordID
					AND P.UserID IS NULL
				END

				-- Rlog 25761 - PMC
				IF @IsNotifyCCDuringLeaveRecordApproval = 1
				BEGIN
					TRUNCATE TABLE [#MESS_spPushNotificationToApp_UserID]
					INSERT INTO [#MESS_spPushNotificationToApp_UserID] (UserID)
					EXEC MESS_GetUserCcMailForLeaveRecord @UserGroupID=@UserGroupID,@WorkLowID= @MaQuiTrinh,@RecordID=@RecordID,@EmpID=@EmpID,@Type=1
						
					/*Noti cho CCmail Inprogress*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT A.UserID AS UserID, 
							CASE WHEN @StatusID = 4 THEN N'PHEP35' ELSE N'PHEP38' END AS Code,
							CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
							CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END + '$' +
							E.EmpCode + '$' +
							CONVERT(NVARCHAR(10),L.FromDate,103) + '$' +
							CONVERT(NVARCHAR(10),L.ToDate,103) + '$' +
							RTRIM(L.LeaveTaken) + '$' +
							CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END AS Param,
							CASE WHEN @StatusID = 4 THEN N'1' ELSE N'2' END AS MaQuiTrinh,
							'3' AS ScreenType,
							L.LeaveRecordID AS RecordID
					FROM TS_tblLeaveRecord (NOLOCK) L
					LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.CurApprover
					LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
					LEFT JOIN [#MESS_spPushNotificationToApp_UserID] (NOLOCK) A ON 1 = 1
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = A.UserID
					WHERE L.LeaveRecordID = @RecordID
					AND A.UserID IS NOT NULL AND P.UserID IS NULL
				END
			END
			/*Quy trình nghỉ phép giờ*/
			ELSE IF @Type = 'LeaveRecordHour'
			BEGIN
			    SELECT @UserID = CurApprover,
						@EmpID = EmpID,
						@StatusID = ApprovedStatus,
						@Level = ApprovedLevel,
						@NguoiThayThe = NguoiThayThe,
						@CCMail = CCMail
				FROM dbo.TS_tblLeaveRecordHour (NOLOCK)
				WHERE LeaveRecordHourID = @RecordID

				SELECT TOP 1 @LevelProcess = Cap
				FROM dbo.TS_tblLeaveRecordHourProcess (NOLOCK)
				WHERE LeaveRecordHourID = @RecordID
				ORDER BY CONVERT(BIGINT,LeaveRecordHourProcessID) DESC

				/*Vừa chuyển đơn*/
				IF @StatusID IN (3,7) AND @Level = 1
				BEGIN
					/*Noti cho người phê duyệt*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT L.CurApprover AS UserID, 
						   CASE WHEN @StatusID = 3 THEN N'PHEPGIO03' ELSE N'PHEPGIO20' END AS Code,
						   CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
						   CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
						   CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END AS Param,
						   '1003' MaQuiTrinh,
						   '2' AS ScreenType,
						   L.LeaveRecordHourID AS RecordID
					FROM TS_tblLeaveRecordHour (NOLOCK) L
					LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = L.CurApprover
					WHERE L.LeaveRecordHourID = @RecordID
					AND P.UserID IS NULL

					IF ISNULL(@NguoiThayThe,'') <> ''
					BEGIN
						SELECT @UserID = UserGroupID FROM dbo.TS_fnTableUserAccountByEmp(@NguoiThayThe,GETDATE())
						IF ISNULL(@UserID,'') <> ''
						BEGIN
							/*Noti cho người thay thế*/
							INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
							SELECT @UserID AS UserID, 
								   CASE WHEN @StatusID = 3 THEN N'PHEPGIO01' ELSE N'PHEPGIO18' END AS Code,
								   CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
								   CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
								   CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END + '$' +
								   CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END AS Param,
								   '1003' MaQuiTrinh,
								   '3' AS ScreenType,
								   L.LeaveRecordHourID AS RecordID
							FROM TS_tblLeaveRecordHour (NOLOCK) L
							LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
							LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
							LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.CurApprover
							LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
							LEFT JOIN
							(
								SELECT UserID
								FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
								GROUP BY UserID
							) P ON P.UserID = @UserID
							WHERE L.LeaveRecordHourID = @RecordID
							AND P.UserID IS NULL
						END
					END
					IF ISNULL(@CCMail,'') <> ''
					BEGIN
						/*Noti cho người liên quan*/
						INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
						SELECT D.UserGroupID AS UserID, 
								CASE WHEN @StatusID = 3 THEN N'PHEPGIO02' ELSE N'PHEPGIO19' END AS Code,
								CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
								CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
								CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END + '$' +
								CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END AS Param,
								'1003' MaQuiTrinh,
								'3' AS ScreenType,
								L.LeaveRecordHourID AS RecordID
						FROM TS_tblLeaveRecordHour (NOLOCK) L
						LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
						LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
						LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.CurApprover
						LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
						LEFT JOIN dbo.Split(@CCMail,'$') CC ON 1 = 1
						OUTER APPLY dbo.TS_fnTableUserAccountByEmp(CC.items,GETDATE()) D
						LEFT JOIN
						(
							SELECT UserID
							FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
							GROUP BY UserID
						) P ON P.UserID = D.UserGroupID
						WHERE L.LeaveRecordHourID = @RecordID
						AND D.UserGroupID IS NOT NULL
						AND P.UserID IS NULL
					END
				END
				/*Vừa rút đơn*/
				ELSE IF @StatusID = 1 AND @Level = 0
				BEGIN
					/*Noti cho người phê duyệt*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT D.NguoiPheDuyet AS UserID, 
						   N'PHEPGIO04' AS Code,
						   CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
						   CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
						   CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END AS Param,
						   '1003' MaQuiTrinh,
						   '3' AS ScreenType,
						   L.LeaveRecordHourID AS RecordID
					FROM TS_tblLeaveRecordHour (NOLOCK) L
					LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					OUTER APPLY
					(
						SELECT TOP 1 P.*
						FROM TS_tblLeaveRecordHourProcess (NOLOCK) P
						WHERE P.TrangThai = 3
						AND P.LeaveRecordHourID = L.LeaveRecordHourID
						ORDER BY CONVERT(BIGINT,P.LeaveRecordHourProcessID) DESC
					) D
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = D.NguoiPheDuyet
					WHERE L.LeaveRecordHourID = @RecordID
					AND D.NguoiPheDuyet IS NOT NULL
					AND P.UserID IS NULL
				END
				/*Vừa duyệt trung gian*/
				ELSE IF @StatusID IN (3,7) AND @Level > 1
				BEGIN
					/*Noti cho người phê duyệt*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT L.CurApprover AS UserID, 
						   CASE WHEN @StatusID = 3 THEN N'PHEPGIO08' ELSE N'PHEPGIO24' END AS Code,
						   CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
						   CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
						   CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END AS Param,
						   '1003' MaQuiTrinh,
						   '2' AS ScreenType,
						   L.LeaveRecordHourID AS RecordID
					FROM TS_tblLeaveRecordHour (NOLOCK) L
					LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = L.CurApprover
					WHERE L.LeaveRecordHourID = @RecordID
					AND P.UserID IS NULL

					IF ISNULL(@NguoiThayThe,'') <> ''
					BEGIN
						SELECT @UserID = UserGroupID FROM dbo.TS_fnTableUserAccountByEmp(@NguoiThayThe,GETDATE())
						IF ISNULL(@UserID,'') <> ''
						BEGIN
							/*Noti cho người thay thế*/
							INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
							SELECT @UserID AS UserID, 
								   CASE WHEN @StatusID = 3 THEN N'PHEPGIO06' ELSE N'PHEPGIO22' END AS Code,
								   CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
								   CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
								   CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END + '$' +
								   CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END AS Param,
								   '1003' MaQuiTrinh,
								   '3' AS ScreenType,
								   L.LeaveRecordHourID AS RecordID
							FROM TS_tblLeaveRecordHour (NOLOCK) L
							LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
							LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
							LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.CurApprover
							LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
							LEFT JOIN
							(
								SELECT UserID
								FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
								GROUP BY UserID
							) P ON P.UserID = @UserID
							WHERE L.LeaveRecordHourID = @RecordID
							AND P.UserID IS NULL
						END
					END
					IF ISNULL(@CCMail,'') <> ''
					BEGIN
						/*Noti cho người liên quan*/
						INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
						SELECT D.UserGroupID AS UserID, 
								CASE WHEN @StatusID = 3 THEN N'PHEPGIO07' ELSE N'PHEPGIO23' END AS Code,
								CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
								CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
								CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END + '$' +
								CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END AS Param,
								'1003' MaQuiTrinh,
								'3' AS ScreenType,
								L.LeaveRecordHourID AS RecordID
						FROM TS_tblLeaveRecordHour (NOLOCK) L
						LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
						LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
						LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.CurApprover
						LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
						LEFT JOIN dbo.Split(@CCMail,'$') CC ON 1 = 1
						OUTER APPLY dbo.TS_fnTableUserAccountByEmp(CC.items,GETDATE()) D
						LEFT JOIN
						(
							SELECT UserID
							FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
							GROUP BY UserID
						) P ON P.UserID = D.UserGroupID
						WHERE L.LeaveRecordHourID = @RecordID
						AND D.UserGroupID IS NOT NULL
						AND P.UserID IS NULL
					END

					/*Noti cho người tạo đơn*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT L.Creater AS UserID, 
							CASE WHEN @StatusID = 3 THEN N'PHEPGIO05' ELSE N'PHEPGIO21' END AS Code,
							CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
							CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
							CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END AS Param,
							'1003' MaQuiTrinh,
							'1' AS ScreenType,
							L.LeaveRecordHourID AS RecordID
					FROM TS_tblLeaveRecordHour (NOLOCK) L
					LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.CurApprover
					LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = L.Creater
					WHERE L.LeaveRecordHourID = @RecordID
					AND P.UserID IS NULL

					/*Noti cho cấp trung gian*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT A.NguoiPheDuyet AS UserID, 
							CASE WHEN @StatusID = 3 THEN N'PHEPGIO09' ELSE N'PHEPGIO25' END AS Code,
							CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
							CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
							CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END + '$' +
							CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END AS Param,
							'1003' MaQuiTrinh,
							'3' AS ScreenType,
							L.LeaveRecordHourID AS RecordID
					FROM TS_tblLeaveRecordHour (NOLOCK) L
					LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.CurApprover
					LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
					LEFT JOIN
					(
						SELECT A.*
						FROM TS_tblLeaveRecordHourProcess (NOLOCK) A
						INNER JOIN
						(
							SELECT Cap,LeaveRecordHourID, MAX(CONVERT(BIGINT,LeaveRecordHourProcessID)) AS LeaveRecordHourProcessID
							FROM TS_tblLeaveRecordHourProcess (NOLOCK)
							GROUP BY LeaveRecordHourID,Cap
						) B ON B.LeaveRecordHourProcessID = A.LeaveRecordHourProcessID
						WHERE A.NguoiPheDuyet IS NOT NULL
						AND
						(
							(@StatusID = 3 AND A.TrangThai <= 5) OR
							(@StatusID = 7 AND A.TrangThai > 5) 
						)
						AND A.Cap < @LevelProcess
					) A ON A.LeaveRecordHourID = L.LeaveRecordHourID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = A.NguoiPheDuyet
					WHERE L.LeaveRecordHourID = @RecordID
					AND P.UserID IS NULL
				END
				/*Vừa duyệt cấp cuối*/
				ELSE IF @StatusID IN (4,8)
				BEGIN
					/*Noti cho người tạo đơn*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT L.Creater AS UserID, 
							CASE WHEN @StatusID = 4 THEN N'PHEPGIO10' ELSE N'PHEPGIO26' END  AS Code,
							CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
							CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END AS Param,
							'1003' MaQuiTrinh,
							'1' AS ScreenType,
							L.LeaveRecordHourID AS RecordID
					FROM TS_tblLeaveRecordHour (NOLOCK) L
					LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.CurApprover
					LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = L.Creater
					WHERE L.LeaveRecordHourID = @RecordID
					AND P.UserID IS NULL

					IF ISNULL(@NguoiThayThe,'') <> ''
					BEGIN
						SELECT @UserID = UserGroupID FROM dbo.TS_fnTableUserAccountByEmp(@NguoiThayThe,GETDATE())
						IF ISNULL(@UserID,'') <> ''
						BEGIN
							/*Noti cho người thay thế*/
							INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
							SELECT @UserID AS UserID, 
									CASE WHEN @StatusID = 4 THEN N'PHEPGIO11' ELSE N'PHEPGIO27' END AS Code,
									CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
									CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
									CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END AS Param,
									'1003' MaQuiTrinh,
									'3' AS ScreenType,
									L.LeaveRecordHourID AS RecordID
							FROM TS_tblLeaveRecordHour (NOLOCK) L
							LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
							LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
							LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.CurApprover
							LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
							LEFT JOIN
							(
								SELECT UserID
								FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
								GROUP BY UserID
							) P ON P.UserID = @UserID
							WHERE L.LeaveRecordHourID = @RecordID
							AND P.UserID IS NULL
						END
					END
					IF ISNULL(@CCMail,'') <> ''
					BEGIN
						/*Noti cho người liên quan*/
						INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
						SELECT D.UserGroupID AS UserID, 
								CASE WHEN @StatusID = 4 THEN N'PHEPGIO12' ELSE N'PHEPGIO28' END  AS Code,
								CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
								CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
								CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END AS Param,
								'1003' MaQuiTrinh,
								'3' AS ScreenType,
								L.LeaveRecordHourID AS RecordID
						FROM TS_tblLeaveRecordHour (NOLOCK) L
						LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
						LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
						LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.CurApprover
						LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
						LEFT JOIN dbo.Split(@CCMail,'$') CC ON 1 = 1
						OUTER APPLY dbo.TS_fnTableUserAccountByEmp(CC.items,GETDATE()) D
						LEFT JOIN
						(
							SELECT UserID
							FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
							GROUP BY UserID
						) P ON P.UserID = D.UserGroupID
						WHERE L.LeaveRecordHourID = @RecordID
						AND D.UserGroupID IS NOT NULL
						AND P.UserID IS NULL
					END

					/*Noti cho cấp trung gian*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT A.NguoiPheDuyet AS UserID, 
							CASE WHEN @StatusID = 4 THEN N'PHEPGIO13' ELSE N'PHEPGIO29' END AS Code,
							CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
							CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
							CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END AS Param,
							'1003' MaQuiTrinh,
							'3' AS ScreenType,
							L.LeaveRecordHourID AS RecordID
					FROM TS_tblLeaveRecordHour (NOLOCK) L
					LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.CurApprover
					LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
					LEFT JOIN
					(
						SELECT A.*
						FROM TS_tblLeaveRecordHourProcess (NOLOCK) A
						INNER JOIN
						(
							SELECT Cap,LeaveRecordHourID, MAX(CONVERT(BIGINT,LeaveRecordHourProcessID)) AS LeaveRecordHourProcessID
							FROM TS_tblLeaveRecordHourProcess (NOLOCK)
							GROUP BY LeaveRecordHourID,Cap
						) B ON B.LeaveRecordHourProcessID = A.LeaveRecordHourProcessID
						WHERE A.NguoiPheDuyet IS NOT NULL
						AND
						(
							(@StatusID = 4 AND A.TrangThai <= 5) OR
							(@StatusID = 8 AND A.TrangThai > 5) 
						)
					) A ON A.LeaveRecordHourID = L.LeaveRecordHourID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = A.NguoiPheDuyet
					WHERE L.LeaveRecordHourID = @RecordID
					AND P.UserID IS NULL
				END
				/*Vừa từ chối*/
				ELSE IF @StatusID IN (5,9) and @Level = 0
				BEGIN
					/*Noti cho người tạo đơn*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT L.Creater AS UserID, 
							CASE WHEN @StatusID = 5 THEN N'PHEPGIO14' ELSE N'PHEPGIO30' END AS Code,
							CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
							CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
							CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END AS Param,
							'1003' MaQuiTrinh,
							'1' AS ScreenType,
							L.LeaveRecordHourID AS RecordID
					FROM TS_tblLeaveRecordHour (NOLOCK) L
					LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					OUTER APPLY
					(
						SELECT TOP 1 P.*
						FROM TS_tblLeaveRecordHourProcess (NOLOCK) P
						WHERE P.TrangThai = @StatusID
						AND P.LeaveRecordHourID = L.LeaveRecordHourID
						ORDER BY CONVERT(BIGINT,P.LeaveRecordHourProcessID) DESC
					) D
					LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = D.Editer
					LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = L.Creater
					WHERE L.LeaveRecordHourID = @RecordID
					AND P.UserID IS NULL

					IF ISNULL(@NguoiThayThe,'') <> ''
					BEGIN
						SELECT @UserID = UserGroupID FROM dbo.TS_fnTableUserAccountByEmp(@NguoiThayThe,GETDATE())
						IF ISNULL(@UserID,'') <> ''
						BEGIN
							/*Noti cho người thay thế*/
							INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
							SELECT @UserID AS UserID, 
									CASE WHEN @StatusID = 5 THEN N'PHEPGIO15' ELSE N'PHEPGIO31' END AS Code,
									CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
									CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
									CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END + '$' +
									CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END AS Param,
									'1003' MaQuiTrinh,
									'3' AS ScreenType,
									L.LeaveRecordHourID AS RecordID
							FROM TS_tblLeaveRecordHour (NOLOCK) L
							LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
							LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
							OUTER APPLY
							(
								SELECT TOP 1 P.*
								FROM TS_tblLeaveRecordHourProcess (NOLOCK) P
								WHERE P.TrangThai = @StatusID
								AND P.LeaveRecordHourID = L.LeaveRecordHourID
								ORDER BY CONVERT(BIGINT,P.LeaveRecordHourProcessID) DESC
							) D
							LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = D.Editer
							LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
							LEFT JOIN
							(
								SELECT UserID
								FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
								GROUP BY UserID
							) P ON P.UserID = @UserID
							WHERE L.LeaveRecordHourID = @RecordID
							AND P.UserID IS NULL
						END
					END
					IF ISNULL(@CCMail,'') <> ''
					BEGIN
						/*Noti cho người liên quan*/
						INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
						SELECT D.UserGroupID AS UserID, 
								CASE WHEN @StatusID = 5 THEN N'PHEPGIO16' ELSE N'PHEPGIO32' END AS Code,
								CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
								CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
								CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END + '$' +
								CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END AS Param,
								'1003' MaQuiTrinh,
								'3' AS ScreenType,
								L.LeaveRecordHourID AS RecordID
						FROM TS_tblLeaveRecordHour (NOLOCK) L
						LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
						LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
						OUTER APPLY
						(
							SELECT TOP 1 P.*
							FROM TS_tblLeaveRecordHourProcess (NOLOCK) P
							WHERE P.TrangThai = @StatusID
							AND P.LeaveRecordHourID = L.LeaveRecordHourID
							ORDER BY CONVERT(BIGINT,P.LeaveRecordHourProcessID) DESC
						) DD
						LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = DD.Editer
						LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
						LEFT JOIN dbo.Split(@CCMail,'$') CC ON 1 = 1
						OUTER APPLY dbo.TS_fnTableUserAccountByEmp(CC.items,GETDATE()) D
						LEFT JOIN
						(
							SELECT UserID
							FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
							GROUP BY UserID
						) P ON P.UserID = D.UserGroupID
						WHERE L.LeaveRecordHourID = @RecordID
						AND D.UserGroupID IS NOT NULL
						AND P.UserID IS NULL
					END

					/*Noti cho cấp trung gian*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT A.NguoiPheDuyet AS UserID, 
							CASE WHEN @StatusID = 5 THEN N'PHEPGIO17' ELSE N'PHEPGIO33' END AS Code,
							CASE WHEN @LanguageID = 'VN' THEN W.VNName ELSE W.Name END + '$' +
							CASE WHEN L.FromDate = L.ToDate THEN CONVERT(NVARCHAR(10),L.FromDate,103) ELSE CONVERT(NVARCHAR(10),L.FromDate,103) + ' - ' + CONVERT(NVARCHAR(10),L.ToDate,103) END + '$' +
							CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END + '$' +
							CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END AS Param,
							'1003' MaQuiTrinh,
							'3' AS ScreenType,
							L.LeaveRecordHourID AS RecordID
					FROM TS_tblLeaveRecordHour (NOLOCK) L
					LEFT JOIN LS_tblWorkPoint (NOLOCK) W ON W.LSWorkPointID = L.LSWorkPointID
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					OUTER APPLY
					(
						SELECT TOP 1 P.*
						FROM TS_tblLeaveRecordHourProcess (NOLOCK) P
						WHERE P.TrangThai = @StatusID
						AND P.LeaveRecordHourID = L.LeaveRecordHourID
						ORDER BY CONVERT(BIGINT,P.LeaveRecordHourProcessID) DESC
					) DD
					LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = DD.Editer
					LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
					LEFT JOIN
					(
						SELECT A.*
						FROM TS_tblLeaveRecordHourProcess (NOLOCK) A
						INNER JOIN
						(
							SELECT Cap,LeaveRecordHourID, MAX(CONVERT(BIGINT,LeaveRecordHourProcessID)) AS LeaveRecordHourProcessID
							FROM TS_tblLeaveRecordHourProcess (NOLOCK)
							GROUP BY LeaveRecordHourID,Cap
						) B ON B.LeaveRecordHourProcessID = A.LeaveRecordHourProcessID
						WHERE A.NguoiPheDuyet IS NOT NULL
						AND
						(
							(@StatusID = 5 AND A.TrangThai <= 5) OR
							(@StatusID = 9 AND A.TrangThai > 5) 
						)
						AND A.Cap < @LevelProcess
					) A ON A.LeaveRecordHourID = L.LeaveRecordHourID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = A.NguoiPheDuyet
					WHERE L.LeaveRecordHourID = @RecordID
					AND P.UserID IS NULL
				END
			END
			/*Quy trình đăng ký OT*/
			ELSE IF @Type = 'OverTime'
			BEGIN
				SELECT @UserID = CurApprover,
						@EmpID = EmpID,
						@StatusID = ApprovedStatus,
						@Level = ApprovedLevel
				FROM TS_tblLamNgoaiGioKeHoach (NOLOCK)
				WHERE LamNgoaiGioID = @RecordID

				SELECT TOP 1 @LevelProcess = Cap
				FROM TS_tblLamNgoaiGioKeHoachTrangThai (NOLOCK)
				WHERE LamNgoaiGioID = @RecordID
				ORDER BY CONVERT(BIGINT,LamNgoaiGioTrangThaiID) DESC 

				/*Vừa chuyển đơn*/
				IF @StatusID IN (3,7) AND @Level = 1
				BEGIN
					/*Noti cho người phê duyệt*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT L.CurApprover AS UserID, 
						   CASE WHEN @StatusID = 3 THEN N'OT01' ELSE N'OT10' END AS Code,
						   CONVERT(NVARCHAR(10),L.Ngay,103) + '$' +
						   CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END AS Param,
						   CASE WHEN @StatusID = 3 THEN N'3' ELSE N'4' END AS MaQuiTrinh,
						   '2' AS ScreenType,
						   L.LamNgoaiGioID AS RecordID
					FROM TS_tblLamNgoaiGioKeHoach (NOLOCK) L
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = L.CurApprover
					WHERE L.LamNgoaiGioID = @RecordID
					AND P.UserID IS NULL
				END
				/*Vừa rút đơn*/
				ELSE IF @StatusID = 1 AND @Level = 0
				BEGIN
					/*Noti cho người phê duyệt*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT D.NguoiPheDuyet AS UserID, 
						   N'OT02' AS Code,
						   CONVERT(NVARCHAR(10),L.Ngay,103) + '$' +
						   CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END AS Param,
						   '3' AS MaQuiTrinh,
						   '3' AS ScreenType,
						   L.LamNgoaiGioID AS RecordID
					FROM TS_tblLamNgoaiGioKeHoach (NOLOCK) L
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					OUTER APPLY
					(
						SELECT TOP 1 P.*
						FROM TS_tblLamNgoaiGioKeHoachTrangThai (NOLOCK) P
						WHERE P.TrangThai = 3
						AND P.LamNgoaiGioID = L.LamNgoaiGioID
						ORDER BY CONVERT(BIGINT,P.LamNgoaiGioTrangThaiID) DESC
					) D
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = D.NguoiPheDuyet
					WHERE L.LamNgoaiGioID = @RecordID
					AND D.NguoiPheDuyet IS NOT NULL
					AND P.UserID IS NULL
				END
				/*Vừa duyệt trung gian*/
				ELSE IF @StatusID IN (3,7) AND @Level > 1
				BEGIN
					/*Noti cho người phê duyệt*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT L.CurApprover AS UserID, 
						   CASE WHEN @StatusID = 3 THEN N'OT04' ELSE N'OT12' END AS Code,
						   CONVERT(NVARCHAR(10),L.Ngay,103) + '$' +
						   CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END AS Param,
						   CASE WHEN @StatusID = 3 THEN N'3' ELSE N'4' END AS MaQuiTrinh,
						   '2' AS ScreenType,
						   L.LamNgoaiGioID AS RecordID
					FROM TS_tblLamNgoaiGioKeHoach (NOLOCK) L
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = L.CurApprover
					WHERE L.LamNgoaiGioID = @RecordID
					AND P.UserID IS NULL

					/*Noti cho người tạo đơn*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT L.Creater AS UserID, 
							CASE WHEN @StatusID = 3 THEN N'OT03' ELSE N'OT11' END AS Code,
							CONVERT(NVARCHAR(10),L.Ngay,103) + '$' +
							CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END AS Param,
							CASE WHEN @StatusID = 3 THEN N'3' ELSE N'4' END AS MaQuiTrinh,
							'1' AS ScreenType,
							L.LamNgoaiGioID AS RecordID
					FROM TS_tblLamNgoaiGioKeHoach (NOLOCK) L
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.CurApprover
					LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = L.Creater
					WHERE L.LamNgoaiGioID = @RecordID
					AND P.UserID IS NULL

					/*Noti cho cấp trung gian*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT A.NguoiPheDuyet AS UserID, 
							CASE WHEN @StatusID = 3 THEN N'OT05' ELSE N'OT13' END AS Code,
							CONVERT(NVARCHAR(10),L.Ngay,103) + '$' +
							CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END + '$' +
							CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END AS Param,
							CASE WHEN @StatusID = 3 THEN N'3' ELSE N'4' END AS MaQuiTrinh,
							'3' AS ScreenType,
							L.LamNgoaiGioID AS RecordID
					FROM TS_tblLamNgoaiGioKeHoach (NOLOCK) L
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.CurApprover
					LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
					LEFT JOIN
					(
						SELECT A.*
						FROM TS_tblLamNgoaiGioKeHoachTrangThai (NOLOCK) A
						INNER JOIN
						(
							SELECT Cap,LamNgoaiGioID, MAX(CONVERT(BIGINT,LamNgoaiGioTrangThaiID)) AS LeaveRecordProcessID
							FROM TS_tblLamNgoaiGioKeHoachTrangThai (NOLOCK)
							GROUP BY LamNgoaiGioID,Cap
						) B ON B.LeaveRecordProcessID = A.LamNgoaiGioTrangThaiID
						WHERE A.NguoiPheDuyet IS NOT NULL
						AND
						(
							(@StatusID = 3 AND A.TrangThai <= 5) OR
							(@StatusID = 7 AND A.TrangThai > 5) 
						)
						AND A.Cap < @LevelProcess
					) A ON A.LamNgoaiGioID = L.LamNgoaiGioID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = A.NguoiPheDuyet
					WHERE L.LamNgoaiGioID = @RecordID
					AND P.UserID IS NULL
				END
				/*Vừa duyệt cấp cuối*/
				ELSE IF @StatusID IN (4,8)
				BEGIN
					/*Noti cho người tạo đơn*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT L.Creater AS UserID, 
							CASE WHEN @StatusID = 4 THEN N'OT06' ELSE N'OT14' END  AS Code,
							CONVERT(NVARCHAR(10),L.Ngay,103) AS Param,
							CASE WHEN @StatusID = 4 THEN N'3' ELSE N'4' END AS MaQuiTrinh,
							'1' AS ScreenType,
							L.LamNgoaiGioID AS RecordID
					FROM TS_tblLamNgoaiGioKeHoach (NOLOCK) L
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.CurApprover
					LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = L.Creater
					WHERE L.LamNgoaiGioID = @RecordID
					AND P.UserID IS NULL

					/*Noti cho cấp trung gian*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT A.NguoiPheDuyet AS UserID, 
							CASE WHEN @StatusID = 4 THEN N'OT07' ELSE N'OT15' END AS Code,
							CONVERT(NVARCHAR(10),L.Ngay,103) + '$' +
							CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END AS Param,
							CASE WHEN @StatusID = 4 THEN N'3' ELSE N'4' END AS MaQuiTrinh,
							'3' AS ScreenType,
							L.LamNgoaiGioID AS RecordID
					FROM TS_tblLamNgoaiGioKeHoach (NOLOCK) L
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.CurApprover
					LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
					LEFT JOIN
					(
						SELECT A.*
						FROM TS_tblLamNgoaiGioKeHoachTrangThai (NOLOCK) A
						INNER JOIN
						(
							SELECT Cap,LamNgoaiGioID, MAX(CONVERT(BIGINT,LamNgoaiGioTrangThaiID)) AS LeaveRecordProcessID
							FROM TS_tblLamNgoaiGioKeHoachTrangThai (NOLOCK)
							GROUP BY LamNgoaiGioID,Cap
						) B ON B.LeaveRecordProcessID = A.LamNgoaiGioTrangThaiID
						WHERE A.NguoiPheDuyet IS NOT NULL
						AND
						(
							(@StatusID = 4 AND A.TrangThai <= 5) OR
							(@StatusID = 8 AND A.TrangThai > 5) 
						)
					) A ON A.LamNgoaiGioID = L.LamNgoaiGioID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = A.NguoiPheDuyet
					WHERE L.LamNgoaiGioID = @RecordID
					AND P.UserID IS NULL

					/*Noti cho cấp trung gian*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT A.NguoiPheDuyet AS UserID, 
							CASE WHEN @StatusID = 4 THEN N'OT07' ELSE N'OT15' END AS Code,
							CONVERT(NVARCHAR(10),L.Ngay,103) + '$' +
							CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END AS Param,
							CASE WHEN @StatusID = 4 THEN N'3' ELSE N'4' END AS MaQuiTrinh,
							'3' AS ScreenType,
							L.LamNgoaiGioID AS RecordID
					FROM TS_tblLamNgoaiGioKeHoach (NOLOCK) L
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.CurApprover
					LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
					LEFT JOIN
					(
						SELECT A.*
						FROM TS_tblLamNgoaiGioKeHoachTrangThai (NOLOCK) A
						INNER JOIN
						(
							SELECT Cap,LamNgoaiGioID, MAX(CONVERT(BIGINT,LamNgoaiGioTrangThaiID)) AS LeaveRecordProcessID
							FROM TS_tblLamNgoaiGioKeHoachTrangThai (NOLOCK)
							GROUP BY LamNgoaiGioID,Cap
						) B ON B.LeaveRecordProcessID = A.LamNgoaiGioTrangThaiID
						WHERE A.NguoiPheDuyet IS NOT NULL
						AND
						(
							(@StatusID = 4 AND A.TrangThai <= 5) OR
							(@StatusID = 8 AND A.TrangThai > 5) 
						)
					) A ON A.LamNgoaiGioID = L.LamNgoaiGioID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = A.NguoiPheDuyet
					WHERE L.LamNgoaiGioID = @RecordID
					AND P.UserID IS NULL

					/*Noti cho CcMailDoneText khi duyệt cấp cuối - Rlog 25635 */
					IF @IsNotifyCCOnOvertimeApproved = 1
					BEGIN
						TRUNCATE TABLE [#MESS_spPushNotificationToApp_UserID]
						INSERT INTO [#MESS_spPushNotificationToApp_UserID] (UserID)
						EXEC MESS_GetUserCcMailForLeaveRecord @UserGroupID=@UserGroupID,@WorkLowID= @MaQuiTrinh,@RecordID=@RecordID,@EmpID=@EmpID,@Type=2

						INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param)
						SELECT	U.UserID AS UserID, 
								N'OT18' AS Code,
								CONVERT(NVARCHAR(10), L.Ngay,103) AS Param
						FROM	TS_tblLamNgoaiGioKeHoach (NOLOCK) L
								LEFT JOIN [#MESS_spPushNotificationToApp_UserID] (NOLOCK) U ON 1 = 1
						WHERE	L.LamNgoaiGioID = @RecordID
								AND @StatusID = 4
					END	
				END
				/*Vừa từ chối*/
				ELSE IF @StatusID IN (5,9) and @Level = 0
				BEGIN
					/*Noti cho người tạo đơn*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT L.Creater AS UserID, 
							CASE WHEN @StatusID = 5 THEN N'OT08' ELSE N'OT16' END AS Code,
							CONVERT(NVARCHAR(10),L.Ngay,103) + '$' +
							CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END AS Param,
							CASE WHEN @StatusID = 5 THEN N'3' ELSE N'4' END AS MaQuiTrinh,
							'1' AS ScreenType,
							L.LamNgoaiGioID AS RecordID
					FROM TS_tblLamNgoaiGioKeHoach (NOLOCK) L
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					OUTER APPLY
					(
						SELECT TOP 1 P.*
						FROM TS_tblLamNgoaiGioKeHoachTrangThai (NOLOCK) P
						WHERE P.TrangThai = @StatusID
						AND P.LamNgoaiGioID = L.LamNgoaiGioID
						ORDER BY CONVERT(BIGINT,P.LamNgoaiGioTrangThaiID) DESC
					) D
					LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = D.Editer
					LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = L.Creater
					WHERE L.LamNgoaiGioID = @RecordID
					AND P.UserID IS NULL

					/*Noti cho cấp trung gian*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT A.NguoiPheDuyet AS UserID, 
							CASE WHEN @StatusID = 5 THEN N'OT09' ELSE N'OT17' END AS Code,
							CONVERT(NVARCHAR(10),L.Ngay,103) + '$' +
							CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END + '$' +
							CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END AS Param,
							CASE WHEN @StatusID = 5 THEN N'3' ELSE N'4' END AS MaQuiTrinh,
							'3' AS ScreenType,
							L.LamNgoaiGioID AS RecordID
					FROM TS_tblLamNgoaiGioKeHoach (NOLOCK) L
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					OUTER APPLY
					(
						SELECT TOP 1 P.*
						FROM TS_tblLamNgoaiGioKeHoachTrangThai (NOLOCK) P
						WHERE P.TrangThai = @StatusID
						AND P.LamNgoaiGioID = L.LamNgoaiGioID
						ORDER BY CONVERT(BIGINT,P.LamNgoaiGioTrangThaiID) DESC
					) DD
					LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = DD.Editer
					LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
					LEFT JOIN
					(
						SELECT A.*
						FROM TS_tblLamNgoaiGioKeHoachTrangThai (NOLOCK) A
						INNER JOIN
						(
							SELECT Cap,LamNgoaiGioID, MAX(CONVERT(BIGINT,LamNgoaiGioTrangThaiID)) AS LeaveRecordProcessID
							FROM TS_tblLamNgoaiGioKeHoachTrangThai (NOLOCK)
							GROUP BY LamNgoaiGioID,Cap
						) B ON B.LeaveRecordProcessID = A.LamNgoaiGioTrangThaiID
						WHERE A.NguoiPheDuyet IS NOT NULL
						AND
						(
							(@StatusID = 5 AND A.TrangThai <= 5) OR
							(@StatusID = 9 AND A.TrangThai > 5) 
						)
						AND A.Cap < @LevelProcess
					) A ON A.LamNgoaiGioID = L.LamNgoaiGioID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = A.NguoiPheDuyet
					WHERE L.LamNgoaiGioID = @RecordID
					AND P.UserID IS NULL
				END
			END
			/*Quy trình bổ sung công*/
			ELSE IF @Type = 'LogTMS'
			BEGIN
				SELECT @UserID = CurApprover,
						@EmpID = EmpID,
						@StatusID = CurStatus,
						@Level = CurLevel
				FROM TS_tblDKXacNhanQTOnline_V2 (NOLOCK)
				WHERE TSDKXacNhanQTOnline2ID = @RecordID

				SELECT TOP 1 @LevelProcess = Level
				FROM TS_tblDKXacNhanQTOnlineProcess_V2 (NOLOCK)
				WHERE TSDKXacNhanQTOnline2ID = @RecordID
				ORDER BY CONVERT(BIGINT,TSDKXacNhanQTOnlineProcess2ID) DESC 

				/*Vừa chuyển đơn*/
				IF @StatusID IN (2) AND @Level = 1
				BEGIN
					/*Noti cho người phê duyệt*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT L.CurApprover AS UserID, 
						   N'LOGTMS01' AS Code,
						   CONVERT(NVARCHAR(10),L.NgayDK,103) + '$' +
						   CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END AS Param,
						   N'75' AS MaQuiTrinh,
						   '2' AS ScreenType,
						   L.TSDKXacNhanQTOnline2ID AS RecordID
					FROM TS_tblDKXacNhanQTOnline_V2 (NOLOCK) L
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = L.CurApprover
					WHERE L.TSDKXacNhanQTOnline2ID = @RecordID
					AND P.UserID IS NULL
				END
				/*Vừa rút đơn*/
				ELSE IF @StatusID = 1 AND @Level = 0
				BEGIN
					/*Noti cho người phê duyệt*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT D.Approver AS UserID, 
						   N'LOGTMS02' AS Code,
						   CONVERT(NVARCHAR(10),L.NgayDK,103) + '$' +
						   CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END AS Param,
						   '75' AS MaQuiTrinh,
						   '3' AS ScreenType,
						   L.TSDKXacNhanQTOnline2ID AS RecordID
					FROM TS_tblDKXacNhanQTOnline_V2 (NOLOCK) L
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					OUTER APPLY
					(
						SELECT TOP 1 P.*
						FROM TS_tblDKXacNhanQTOnlineProcess_V2 (NOLOCK) P
						WHERE P.Status = 2
						AND P.TSDKXacNhanQTOnline2ID = L.TSDKXacNhanQTOnline2ID
						ORDER BY CONVERT(BIGINT,P.TSDKXacNhanQTOnlineProcess2ID) DESC
					) D
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = D.Approver
					WHERE L.TSDKXacNhanQTOnline2ID = @RecordID
					AND D.Approver IS NOT NULL
					AND P.UserID IS NULL
				END
				/*Vừa duyệt trung gian*/
				ELSE IF @StatusID IN (2) AND @Level > 1
				BEGIN
					/*Noti cho người phê duyệt*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT L.CurApprover AS UserID, 
						   N'LOGTMS04' AS Code,
						   CONVERT(NVARCHAR(10),L.NgayDK,103) + '$' +
						   CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END AS Param,
						   N'75' AS MaQuiTrinh,
						   '2' AS ScreenType,
						   L.TSDKXacNhanQTOnline2ID AS RecordID
					FROM TS_tblDKXacNhanQTOnline_V2 (NOLOCK) L
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = L.CurApprover
					WHERE L.TSDKXacNhanQTOnline2ID = @RecordID
					AND P.UserID IS NULL

					/*Noti cho người tạo đơn*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT L.Creater AS UserID, 
							N'LOGTMS03' AS Code,
							CONVERT(NVARCHAR(10),L.NgayDK,103) + '$' +
						    CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END AS Param,
							N'75' AS MaQuiTrinh,
							'1' AS ScreenType,
							L.TSDKXacNhanQTOnline2ID AS RecordID
					FROM TS_tblDKXacNhanQTOnline_V2 (NOLOCK) L
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.CurApprover
					LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = L.Creater
					WHERE L.TSDKXacNhanQTOnline2ID = @RecordID
					AND P.UserID IS NULL

					/*Noti cho cấp trung gian*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT A.Approver AS UserID, 
							N'LOGTMS05' AS Code,
							CONVERT(NVARCHAR(10),L.NgayDK,103) + '$' +
							CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END + '$' +
							CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END AS Param,
							N'75' AS MaQuiTrinh,
							'3' AS ScreenType,
							L.TSDKXacNhanQTOnline2ID AS RecordID
					FROM TS_tblDKXacNhanQTOnline_V2 (NOLOCK) L
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.CurApprover
					LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
					LEFT JOIN
					(
						SELECT A.*
						FROM TS_tblDKXacNhanQTOnlineProcess_V2 (NOLOCK) A
						INNER JOIN
						(
							SELECT Level,TSDKXacNhanQTOnline2ID, MAX(CONVERT(BIGINT,TSDKXacNhanQTOnlineProcess2ID)) AS LeaveRecordProcessID
							FROM TS_tblDKXacNhanQTOnlineProcess_V2 (NOLOCK)
							GROUP BY TSDKXacNhanQTOnline2ID,Level
						) B ON B.LeaveRecordProcessID = A.TSDKXacNhanQTOnlineProcess2ID
						WHERE A.Approver IS NOT NULL
						AND A.Level < @LevelProcess
					) A ON A.TSDKXacNhanQTOnline2ID = L.TSDKXacNhanQTOnline2ID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = A.Approver
					WHERE L.TSDKXacNhanQTOnline2ID = @RecordID
					AND P.UserID IS NULL
				END
				/*Vừa duyệt cấp cuối*/
				ELSE IF @StatusID IN (3)
				BEGIN
					/*Noti cho người tạo đơn*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT L.Creater AS UserID, 
							N'LOGTMS06' AS Code,
							CONVERT(NVARCHAR(10),L.NgayDK,103) AS Param,
							N'75' AS MaQuiTrinh,
							'1' AS ScreenType,
							L.TSDKXacNhanQTOnline2ID AS RecordID
					FROM TS_tblDKXacNhanQTOnline_V2 (NOLOCK) L
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.CurApprover
					LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = L.Creater
					WHERE L.TSDKXacNhanQTOnline2ID = @RecordID
					AND P.UserID IS NULL

					/*Noti cho cấp trung gian*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT A.Approver AS UserID, 
							N'LOGTMS07' AS Code,
							CONVERT(NVARCHAR(10),L.NgayDK,103) + '$' +
							CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END AS Param,
							N'75' AS MaQuiTrinh,
							'3' AS ScreenType,
							L.TSDKXacNhanQTOnline2ID AS RecordID
					FROM TS_tblDKXacNhanQTOnline_V2 (NOLOCK) L
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.CurApprover
					LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
					LEFT JOIN
					(
						SELECT A.*
						FROM TS_tblDKXacNhanQTOnlineProcess_V2 (NOLOCK) A
						INNER JOIN
						(
							SELECT Level,TSDKXacNhanQTOnline2ID, MAX(CONVERT(BIGINT,TSDKXacNhanQTOnlineProcess2ID)) AS LeaveRecordProcessID
							FROM TS_tblDKXacNhanQTOnlineProcess_V2 (NOLOCK)
							GROUP BY TSDKXacNhanQTOnline2ID,Level
						) B ON B.LeaveRecordProcessID = A.TSDKXacNhanQTOnlineProcess2ID
						WHERE A.Approver IS NOT NULL
					) A ON A.TSDKXacNhanQTOnline2ID = L.TSDKXacNhanQTOnline2ID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = A.Approver
					WHERE L.TSDKXacNhanQTOnline2ID = @RecordID
					AND P.UserID IS NULL
				END
				/*Vừa từ chối*/
				ELSE IF @StatusID IN (4) and @Level = 0
				BEGIN
					/*Noti cho người tạo đơn*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT L.Creater AS UserID, 
							N'LOGTMS08' AS Code,
							CONVERT(NVARCHAR(10),L.NgayDK,103) + '$' +
							CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END AS Param,
							N'75' AS MaQuiTrinh,
							'1' AS ScreenType,
							L.TSDKXacNhanQTOnline2ID AS RecordID
					FROM TS_tblDKXacNhanQTOnline_V2 (NOLOCK) L
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					OUTER APPLY
					(
						SELECT TOP 1 P.*
						FROM TS_tblDKXacNhanQTOnlineProcess_V2 (NOLOCK) P
						WHERE P.Status = @StatusID
						AND P.TSDKXacNhanQTOnline2ID = L.TSDKXacNhanQTOnline2ID
						ORDER BY CONVERT(BIGINT,P.TSDKXacNhanQTOnlineProcess2ID) DESC
					) D
					LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = D.Editer
					LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = L.Creater
					WHERE L.TSDKXacNhanQTOnline2ID = @RecordID
					AND P.UserID IS NULL

					/*Noti cho cấp trung gian*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT A.Approver AS UserID, 
							N'LOGTMS09' AS Code,
							CONVERT(NVARCHAR(10),L.NgayDK,103) + '$' +
							CASE WHEN @LanguageID = 'VN' THEN E.EmpName ELSE E.EmpName_Unsign END  + '$' +
							CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END AS Param,
							N'75' AS MaQuiTrinh,
							'3' AS ScreenType,
							L.TSDKXacNhanQTOnline2ID AS RecordID
					FROM TS_tblDKXacNhanQTOnline_V2 (NOLOCK) L
					LEFT JOIN HR_vEmp (NOLOCK) E ON E.EmpID = L.EmpID
					LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = L.Editer
					LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
					LEFT JOIN
					(
						SELECT A.*
						FROM TS_tblDKXacNhanQTOnlineProcess_V2 (NOLOCK) A
						INNER JOIN
						(
							SELECT Level,TSDKXacNhanQTOnline2ID, MAX(CONVERT(BIGINT,TSDKXacNhanQTOnlineProcess2ID)) AS LeaveRecordProcessID
							FROM TS_tblDKXacNhanQTOnlineProcess_V2 (NOLOCK)
							GROUP BY TSDKXacNhanQTOnline2ID,Level
						) B ON B.LeaveRecordProcessID = A.TSDKXacNhanQTOnlineProcess2ID
						WHERE A.Approver IS NOT NULL
						AND A.Level < @LevelProcess
					) A ON A.TSDKXacNhanQTOnline2ID = L.TSDKXacNhanQTOnline2ID
					LEFT JOIN
					(
						SELECT UserID
						FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
						GROUP BY UserID
					) P ON P.UserID = A.Approver
					WHERE L.TSDKXacNhanQTOnline2ID = @RecordID
					AND P.UserID IS NULL
				END
			END
			ELSE IF @Type in ('OfferLetter')
			BEGIN
				/*Noti cho người phê duyệt*/
				INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
				SELECT	case when L.ApproveStatus = 4 then L.Creater else L.Approver end AS UserID, 
						case when L.ApproveStatus = 2 then 'OL04' 
							when L.ApproveStatus = 3 then 'OL06' 
							when L.ApproveStatus = 4 then 'OL08' 
						end AS Code,
						case when L.ApproveStatus = 4 then ca.CandidateName + '$' + CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END 
							else
								CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END 
						  end
						as [Param],
						N'1001' AS MaQuiTrinh,
						case when L.ApproveStatus = 3 then 5 else 2 end AS ScreenType,
						L.ChuyenUVThanhNVID AS RecordID
				FROM RE_tblChuyenUVThanhNV (NOLOCK) L
				LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = @UserGroupID
				LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
				left join Re_tblCandidate(nolock) ca on L.CandidateID = ca.CandidateID
				WHERE L.ChuyenUVThanhNVID = @RecordID
			END
			ELSE IF @Type in ('Demand')
			BEGIN
				IF (@customerId <> 148) -- # HLV
				BEGIN 
					/*Noti cho người phê duyệt*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT	case when L.REApprovedStatusID = 4 then L.Creater else L.CurApprover end AS UserID, 
							case when L.REApprovedStatusID = 2 then 'RR04'
								when L.REApprovedStatusID = 3 then 'RR06'
								when L.REApprovedStatusID = 4 then 'RR08' 
							end AS Code,
							case when L.REApprovedStatusID = 4 then L.DemandName + '$' + pro.Comment
								else
									CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END 
							end
							as [Param],
							'1002' AS MaQuiTrinh,
							case when L.REApprovedStatusID = 3 then 5 else 2 end AS ScreenType,
							L.DemandID AS RecordID
					FROM RE_tblDemand (NOLOCK) L
					LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = @UserGroupID
					LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
					outer apply (
						select top 1 *
						from RE_tblDemandProcess(nolock) pr
						where L.DemandID = pr.DemandID and pr.REApprovedStatusID = 4
						order by pr.DemandProcessID desc
					) pro
					WHERE L.DemandID = @RecordID
				END
			END
			ELSE IF @Type in ('DeXuatThoiViec')
			BEGIN
				/*Noti cho người phê duyệt*/
				INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
				SELECT	case when L.StatusID = 4 then L.Creater else L.CurApprover end AS UserID, 
						case when L.StatusID = 2 then 'THOIVIEC01'
							when L.StatusID = 3 then 'THOIVIEC06'
							when L.StatusID = 4 then 'THOIVIEC08' 
						end AS Code,
						case when L.StatusID = 2 then CASE WHEN @LanguageID = 'VN' THEN E2.EmpName ELSE E2.EmpName_Unsign END
							when L.StatusID = 3 then ''
							when L.StatusID = 4 then CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END 
						end AS [Param],
						'43' AS MaQuiTrinh,
						case when L.StatusID = 2 then 2
							when L.StatusID = 3 then 3
							when L.StatusID = 4 then 1 
						end AS ScreenType,
						L.ID AS RecordID
				FROM HR_tblLeaveRequest (NOLOCK) L
				LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = @UserGroupID
				LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
				LEFT JOIN HR_vEmp (NOLOCK) E2 ON E2.EmpID = L.EmpID
				outer apply (
					select top 1 *
					from HR_tblLeaveRequestProcess(nolock) pr
					where L.ID = pr.ID and pr.StatusID = 4
					order by pr.ProcessID desc
				) pro
				WHERE L.ID = @RecordID
			END
			ELSE IF @Type in ('DanhGiaGHHD')
			BEGIN
				/*Noti cho người phê duyệt*/
				INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
				SELECT	case when L.StatusID = 4 then L.Creater else L.CurApprover end AS UserID, 
						case when L.StatusID = 2 then 'ACRE02'
							when L.StatusID = 3 then 'ACRE04'
							when L.StatusID = 4 then 'ACRE05' 
							when L.StatusID = 5 then 'ACRE06' /*RlogID 24219 - MESSER*/
						end AS Code,
						case when L.StatusID = 2 then CASE WHEN @LanguageID = 'VN' THEN E2.EmpName ELSE E2.EmpName_Unsign END  + '$' + convert(nvarchar(12), L.ToDate,103) + '$' + CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END
							when L.StatusID = 3 then CASE WHEN @LanguageID = 'VN' THEN E2.EmpName ELSE E2.EmpName_Unsign END  + '$' + CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END
							when L.StatusID = 4 then CASE WHEN @LanguageID = 'VN' THEN E2.EmpName ELSE E2.EmpName_Unsign END  + '$' + CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END
							when L.StatusID = 5 then CASE WHEN @LanguageID = 'VN' THEN E2.EmpName ELSE E2.EmpName_Unsign END  + '$' + CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END
						end AS [Param],
						'63' AS MaQuiTrinh,
						case when L.StatusID = 2 then 1
							when L.StatusID = 3 then 2
							when L.StatusID = 4 then 1 
							when L.StatusID = 5 then 1 
						end AS ScreenType,
							--L.ID + '#' + L.EmpID + '#' + CONVERT(NVARCHAR(10),L.FromDate,103) AS RecordID
							CONVERT(NVARCHAR(20), L.ID) + '#' + 
							CONVERT(NVARCHAR(20), L.EmpID) + '#' + 
							CONVERT(NVARCHAR(10), L.FromDate, 103) AS RecordID
				FROM HR_tblDanhGiaGiaHanHopDong (NOLOCK) L
				LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = @UserGroupID
				LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
				LEFT JOIN HR_vEmp (NOLOCK) E2 ON E2.EmpID = L.EmpID
				outer apply (
					select top 1 *
					from HR_tblDanhGiaGiaHanHopDongProcess(nolock) pr
					where L.ID = pr.ID and pr.StatusID = 4
					order by pr.ProcessID desc
				) pro
				WHERE L.ID = @RecordID
				/*xu ly gom*/
			END
			ELSE IF @Type in ('DanhGiaTV')
			BEGIN
				/*Noti cho người phê duyệt*/
				INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
				SELECT	L.CurApproved AS UserID,--case when L.REApprovedStatusID = 4 then L.Creater else L.CurApproved end AS UserID, 
						case when L.REApprovedStatusID = 2 then 'EP03'
							when L.REApprovedStatusID = 3 then 'EP04'
							when L.REApprovedStatusID = 4 then 'EP05' 
						end AS Code,
						case when L.REApprovedStatusID = 2 then CASE WHEN @LanguageID = 'VN' THEN E2.EmpName ELSE E2.EmpName_Unsign END  + '$' + convert(nvarchar(12), L.ProbationDate_To,103) + '$' + CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END
							when L.REApprovedStatusID = 3 then CASE WHEN @LanguageID = 'VN' THEN E2.EmpName ELSE E2.EmpName_Unsign END  + '$' + CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END
							when L.REApprovedStatusID = 4 then CASE WHEN @LanguageID = 'VN' THEN E2.EmpName ELSE E2.EmpName_Unsign END  + '$' + CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END
						end AS [Param],
						'64' AS MaQuiTrinh,
						case when L.REApprovedStatusID = 2 then 6
							when L.REApprovedStatusID = 3 then 6
							when L.REApprovedStatusID = 4 then 1 
						end AS ScreenType,
						convert(nvarchar(12),L.HRDanhGiaTVID) + '#' + convert(nvarchar(12),U1.EmpID) AS RecordID
				FROM HR_tblDanhGiaTV (NOLOCK) L
				LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = @UserGroupID
				LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
				LEFT JOIN HR_vEmp (NOLOCK) E2 ON E2.EmpID = L.EmpID
				LEFT JOIN UMS_tblUserAccount (NOLOCK) U1 ON U1.UserGroupID = L.Creater
				outer apply (
					select top 1 *
					from HR_tblDanhGiaTV_QT(nolock) pr
					where L.HRDanhGiaTVID = pr.HRDanhGiaTVID and pr.REApprovedStatusID = 4
					order by pr.HRDanhGiaTV_QTID desc
				) pro
				WHERE L.HRDanhGiaTVID = @RecordID
				/*xu ly gom*/
			END
			ELSE IF @Type = 'BangLuong'
			BEGIN
				SELECT	@UserID = Approver,
						@EmpID = EmpID,
						@StatusID = LSTinhTrangPheDuyet_BangLuong_TLGID,
						@Level = ApprovedLevel
				FROM	PR_tblBangLuongOnline (NOLOCK)
				WHERE	PRBangLuongOnlineID = @RecordID

				/*Vừa chuyển đơn*/
				IF @StatusID = 2 AND @Level = 1
				BEGIN
					Print(N'Vừa chuyển đơn bảng lương')
					/*Noti cho người phê duyệt*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT L.Approver AS UserID, 
						   'APO04' AS Code,
						   CONVERT(NVARCHAR(10),L.PRMonth) + '$' +
						   ISNULL(CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END, '') AS Param,
						   '1000' AS MaQuiTrinh,
						   '2' AS ScreenType,
						   L.PRBangLuongOnlineID AS RecordID
					FROM PR_tblBangLuongOnline (NOLOCK) L
					LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = @UserGroupID
					LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
					--LEFT JOIN
					--(
					--	SELECT UserID
					--	FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
					--	GROUP BY UserID
					--) P ON P.UserID = L.Approver
					WHERE L.PRBangLuongOnlineID = @RecordID
					--AND P.UserID IS NULL
				END
				/*Vừa duyệt trung gian*/
				ELSE IF @StatusID IN (2) AND @Level > 1
				BEGIN
					Print(N'Vừa duyệt trung gian bảng lương')
					/*Noti cho người phê duyệt*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT L.Approver AS UserID, 
						   'APO04' AS Code,
						   CONVERT(NVARCHAR(10),L.PRMonth) + '$' +
						   ISNULL(CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END, '') AS Param,
						   '1000' AS MaQuiTrinh,
						   '2' AS ScreenType,
						   L.PRBangLuongOnlineID AS RecordID
					FROM PR_tblBangLuongOnline (NOLOCK) L
					LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = @UserGroupID
					LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
					--LEFT JOIN
					--(
					--	SELECT UserID
					--	FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
					--	GROUP BY UserID
					--) P ON P.UserID = L.Approver
					WHERE L.PRBangLuongOnlineID = @RecordID
					--AND P.UserID IS NULL
				END
				/*Vừa duyệt cấp cuối*/
				ELSE IF @StatusID IN (4)
				BEGIN
					Print(N'Vừa duyệt cấp cuối')
					/*Noti cho người phê duyệt*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT L.Creator AS UserID, 
						   'APO06' AS Code,
						   CONVERT(NVARCHAR(10),L.PRMonth) AS Param,
						   '1000' AS MaQuiTrinh,
						   '3' AS ScreenType,
						   L.PRBangLuongOnlineID AS RecordID
					FROM PR_tblBangLuongOnline (NOLOCK) L
					LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = @UserGroupID
					LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
					--LEFT JOIN
					--(
					--	SELECT UserID
					--	FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
					--	GROUP BY UserID
					--) P ON P.UserID = L.Approver
					WHERE L.PRBangLuongOnlineID = @RecordID
					--AND P.UserID IS NULL
				END
				/*Vừa từ chối*/
				ELSE IF @StatusID IN (3) and @Level = 0
				BEGIN
					Print(N'Vừa từ chối bảng lương')
					/*Noti cho người phê duyệt*/
					INSERT INTO [#MESS_spPushNotificationToApp] (UserID,Code,Param,MaQuiTrinh,ScreenType,RecordID)
					SELECT L.Creator AS UserID, 
						   'APO08' AS Code,
						   CONVERT(NVARCHAR(10),L.PRMonth) + '$' +
						   ISNULL(CASE WHEN @LanguageID = 'VN' THEN E1.EmpName ELSE E1.EmpName_Unsign END, '') AS Param,
						   '1000' AS MaQuiTrinh,
						   '3' AS ScreenType,
						   L.PRBangLuongOnlineID AS RecordID
					FROM PR_tblBangLuongOnline (NOLOCK) L
					LEFT JOIN UMS_tblUserAccount (NOLOCK) U ON U.UserGroupID = @UserGroupID
					LEFT JOIN HR_vEmp (NOLOCK) E1 ON E1.EmpID = U.EmpID
					--LEFT JOIN
					--(
					--	SELECT UserID
					--	FROM [#MESS_spPushNotificationToApp] (NOLOCK) 
					--	GROUP BY UserID
					--) P ON P.UserID = L.Approver
					WHERE L.PRBangLuongOnlineID = @RecordID
					--AND P.UserID IS NULL
				END

			END
			ELSE IF @Type = 'QTBanGiao'
			BEGIN
				insert into #temp_TblBanGiaoUser (UserGroupID, LSPhongBanBanGiaoID, RecordID)
				select DISTINCT B.items, A.LSPhongBanBanGiaoID, @RecordID AS RecordID
				FROM
				(
					SELECT B.CurApprover, A.LSPhongBanBanGiaoID
					FROM #tmp_TblQTBanGiao A
					INNER JOIN dbo.HR_tblQTBanGiao_KeToan (NOLOCK) B ON B.QTBanGiao_KeToanID = A.BanGiao_HangMucID
					WHERE A.LSPhongBanBanGiaoID = 1 AND B.QTBanGiao_MasterID = @RecordID
					UNION
					SELECT B.CurApprover, A.LSPhongBanBanGiaoID
					FROM #tmp_TblQTBanGiao A
					INNER JOIN dbo.HR_tblQTBanGiao_NhanSu (NOLOCK) B ON B.QTBanGiao_NhanSuID = A.BanGiao_HangMucID
					WHERE A.LSPhongBanBanGiaoID = 3 AND B.QTBanGiao_MasterID = @RecordID
					UNION
					SELECT B.CurApprover, A.LSPhongBanBanGiaoID
					FROM #tmp_TblQTBanGiao A
					INNER JOIN dbo.HR_tblQTBanGiao_CNTT (NOLOCK) B ON B.QTBanGiao_CNTTID = A.BanGiao_HangMucID
					WHERE A.LSPhongBanBanGiaoID = 4 AND B.QTBanGiao_MasterID = @RecordID
					UNION
					SELECT B.CurApprover, A.LSPhongBanBanGiaoID
					FROM #tmp_TblQTBanGiao A
					INNER JOIN dbo.HR_tblQTBanGiao_HangMuc1 (NOLOCK) B ON B.QTBanGiao_HangMuc1ID = A.BanGiao_HangMucID
					WHERE A.LSPhongBanBanGiaoID = 8 AND B.QTBanGiao_MasterID = @RecordID
				)A
				OUTER APPLY
				(
					SELECT * FROM dbo.Split(A.CurApprover, ';') B
				) B 			

				IF @Type_QTBG = 'QTBanGiao_SEND_QLTT'
				BEGIN
					insert into #temp_TblBanGiaoUser (UserGroupID, RecordID)
					select DISTINCT NT.UserGroupID, A.QTBanGiao_MasterID
					FROM dbo.HR_tblQTBanGiao_Master (NOLOCK) A
					LEFT JOIN
					(
						SELECT WR.EmpID, MAX(WR.FromDate) AS FromDate
						FROM dbo.HR_tblWorkingRecord (NOLOCK) WR
						WHERE WR.FromDate <= GETDATE()
						GROUP BY WR.EmpID
					) WR_ ON WR_.EmpID = A.EmpID
					LEFT JOIN dbo.HR_tblWorkingRecord (NOLOCK) WR ON WR.EmpID = WR_.EmpID AND WR.FromDate = WR_.FromDate
					OUTER APPLY [dbo].[TS_fnTableUserAccountByEmp](WR.SupervisorID, GETDATE()) NT
					WHERE A.QTBanGiao_MasterID = @RecordID
				END
				ELSE IF @Type_QTBG IN ('QTBanGiao_QLTT_REJT', 'QTBanGiao_QLTT_APPR')
				BEGIN
					insert into #temp_TblBanGiaoUser (UserGroupID, RecordID)
					select DISTINCT NT.UserGroupID, A.QTBanGiao_MasterID
					FROM dbo.HR_tblQTBanGiao_Master (NOLOCK) A
					OUTER APPLY [dbo].[TS_fnTableUserAccountByEmp](A.EmpID, GETDATE()) NT
					WHERE A.QTBanGiao_MasterID = @RecordID
				END
			END

			SET @STT_MIN = @STT_MIN + 1
		END

		IF(@Type <> 'BangLuong')
		BEGIN
			/*Không gửi Noti đến chính người thao tác*/
			DELETE [#MESS_spPushNotificationToApp] WHERE UserID = @UserGroupID
		END

		IF @Type = 'QTBanGiao'
		BEGIN
			declare @Code NVARCHAR(10) = 'HO01'
			declare @ScreenType NVARCHAR(10) = '2'

			if @Type_QTBG = 'QTBanGiao_Rejec' set @Code = 'HO02'
			if @Type_QTBG = 'QTBanGiao_SEND_QLTT' set @Code = 'HO06'
			if @Type_QTBG = 'QTBanGiao_QLTT_REJT' set @Code = 'HO05'
			if @Type_QTBG = 'QTBanGiao_QLTT_APPR' set @Code = 'HO04'

			if @Type_QTBG = 'QTBanGiao_Rejec' set @ScreenType = '1'
			if @Type_QTBG = 'QTBanGiao_SEND_QLTT' set @ScreenType = '6'
			if @Type_QTBG = 'QTBanGiao_QLTT_REJT' set @ScreenType = '1'
			if @Type_QTBG = 'QTBanGiao_QLTT_APPR' set @ScreenType = '1'

			select A.UserGroupID, A.RecordID, String1 = STUFF(
									(SELECT ';' + convert(nvarchar(12),LSPhongBanBanGiaoID) 
									FROM [#temp_TblBanGiaoUser] A1
								WHERE A1.UserGroupID = A.UserGroupID AND A1.RecordID = A.RecordID
								FOR XML PATH ('')), 1, 1, ''
							)
			INTO #temp_TblBanGiaoUser2
			from #temp_TblBanGiaoUser A
			GROUP BY A.UserGroupID, A.RecordID

			SELECT A.UserGroupID AS UserID, @Code AS Code, C.F_EmpName AS [Param], '1004' AS MaQuiTrinh, @ScreenType AS ScreenType,
				case when @Type_QTBG in ('QTBanGiao_NV', 'QTBanGiao_Trans')
 					then CASE WHEN A.String1 LIKE N'%;%' THEN '-3' else CONVERT(NVARCHAR(12), A.RecordID) END + '#' + CONVERT(NVARCHAR(12), C.EmpID) + '#' + ISNULL(A.String1, '')
					else CASE WHEN A.String1 LIKE N'%;%' THEN '-3' else CONVERT(NVARCHAR(12), A.RecordID) END + '#-1#-1'
				end AS RecordID
			FROM #temp_TblBanGiaoUser2 A
			LEFT JOIN dbo.HR_tblQTBanGiao_Master (NOLOCK) M ON M.QTBanGiao_MasterID = A.RecordID
			LEFT JOIN UMS_tblUserAccount (NOLOCK) B ON B.UserGroupID = @UserGroupID
			LEFT JOIN HR_TblEmp (NOLOCK) C ON C.EmpID = CASE WHEN @Type_QTBG = 'QTBanGiao_SEND_QLTT' THEN M.EmpID ELSE B.EmpID END

			RETURN
		END

		--UPDATE [#MESS_spPushNotificationToApp] SET UserID = 'nhilhp'
		--UPDATE [#MESS_spPushNotificationToApp] SET UserID = 'thold6'
		
		--SELECT * FROM [#MESS_spPushNotificationToApp] (NOLOCK)

		SELECT  UserID, Code, [Param], MaQuiTrinh, ScreenType,
				 CASE 
					WHEN CHARINDEX(',', RecordID) > 0 THEN convert(nvarchar(12),-1)
					ELSE convert(nvarchar(12),RecordID)
				END AS RecordID 
		FROM
		(
				SELECT	UserID, Code, Param, MaQuiTrinh, ScreenType,
						RecordID = STUFF(
									 (SELECT ',' + convert(nvarchar(12),RecordID) 
									 FROM (
											select *
											from [#MESS_spPushNotificationToApp]
									) t1
								  WHERE t1.UserID = t2.UserID AND t1.MaQuiTrinh = t2.MaQuiTrinh
								  FOR XML PATH ('')), 1, 1, ''
								) 
				FROM (
						select *
						from [#MESS_spPushNotificationToApp]
					 ) t2 
				where UserID is not null 
				GROUP BY UserID, Code, Param, MaQuiTrinh, ScreenType
		) A
	END
	Else if @Activity='UpdateAfterResponse'
	Begin
		if @Type='PaySlip'
		Begin
			IF ISJSON(@JsonInput) = 1
			BEGIN
				SELECT @RecordID = JSON_VALUE(@JsonInput, '$.Payload.RecordID')
				if @RecordID is not null and @RecordID <> ''
				Begin
					Update PR_tblPaySlipEmp 
					set Noti =1,
						Noti_Processing = 0
					Where PRPaySlipEmpID = @RecordID
				End
			END
			ELSE
			BEGIN
				RAISERROR('Invalid JSON format', 16, 1);
			END
		End
	End
END
