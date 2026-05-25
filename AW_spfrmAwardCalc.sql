USE [iHRP_V34_PMC]
GO
/****** Object:  StoredProcedure [dbo].[AW_spfrmAwardCalc]    Script Date: 5/20/2026 3:31:50 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER procedure 	[dbo].[AW_spfrmAwardCalc]
@Activity				varchar(50),
@iError					int = null		OUTPUT,
@sError					nvarchar(4000) = null 	OUTPUT,
@ReturnMess				nvarchar(4000) = null 	OUTPUT,
@LanguageID 			nvarchar(2)='VN',
@UserGroupID			nvarchar(150)=null,
@FunctionID 			nvarchar(20) = null,
--
@SetFormulaID			nvarchar(50) = null,
@Month 					nvarchar(7)=null,
@LSAwardsID				int = null,

@EmpID					int = null,
@EmpCode				nvarchar(50) = null,
@EmpName				nvarchar(200)=null,
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
--Hlevel
@LSHLevel1ID int = null,
@LSHLevel2ID int = null,
@LSHLevel3ID int = null,
@LSHLevel4ID int = null,
@LSHLevel5ID int = null,
@LSHLevel6ID int = null,
@LSLocationID int = null,
@LSJobTitleID int = null,
@LSLoaiHinhNhanVienID int = null,
@Status					nvarchar(2) = null,
@IsLockPR				nvarchar(2) = null,
@IsUpdateAwardEmp		bit = null,
@LSCapBacNhanVienID			nvarchar(4000) = NULL,
@LSKhoiNhanVienID					nvarchar(4000) = NULL,
@LSDanhMucQTLV1ID					nvarchar(4000) = NULL,
/*Theo RlogID = 14816*/
@EHDS_LSLoaiNhanVienID nvarchar(max) =null,
@EHDS_LSNhomNhanVienID nvarchar(max)=null,
@EHDS_LSCapBacNhanVienID nvarchar(max)=null,
@EHDS_LSContractTypeID nvarchar(max)=null,
@EHDS_LSStatusChangeID nvarchar(max)=null,
@EHDS_UserGroupID nvarchar(max)=null,
@EHDS_Email nvarchar(max)=null,
@EHDS_HRCode nvarchar(max)=null,
@EHDS_IDNo nvarchar(max)=null,
@EHDS_MaSoThue nvarchar(max)=null,
@EHDS_AccountNo nvarchar(max)=null,
@EHDS_MaTheChamCong nvarchar(max)=null,
@EHDS_EmpCodeOld nvarchar(max)=null

AS
DECLARE @IsAlert bit
	set @IsAlert = 1	

------------------------------------------
declare @Date date
declare @strDate nvarchar(10)
IF EXISTS(SELECT TOP 1 1 FROM dbo.PR_tblSalarySetup(NOLOCK) WHERE XuatBCThuongTheoNgayChotKhacQTLV = 1)
	SET @strDate = CONVERT(nvarchar(10), dbo.[AW_fnGetNgayKetThucPeriod](@Month, @LSAwardsID), 103)						
ELSE 
BEGIN 
	set @Date = dbo.AW_fnGetNgayChotPeriod(@Month, @LSAwardsID)
	select @strDate = convert(nvarchar,@Date,103)
END 
------------------------------------------
DECLARE @strSQL	nvarchar(max), @strSQL2 nvarchar(max), 
		@strSQLMaHoa NVARCHAR(MAX), @strColMaHoa NVARCHAR(MAX), @strColNotChange NVARCHAR(MAX), 
		@strCol1	NVARCHAR(MAX), @strCol2	NVARCHAR(MAX),
		@strSQLtmp nvarchar(max), @strSQLtmpText nvarchar(max), @strSQLtmpCalc nvarchar(max),
		@tableName nvarchar(20), @MonthUserID nvarchar(50), @Prefix NVARCHAR(150)
Declare @AWTieuChiThuongID nvarchar(12), @AWTieuChiThuongCode nvarchar(50), @Formula nvarchar(4000), @IsText bit, @IsCompany bit,
		@Seq int, @CustomerID nvarchar(50), @PreMonth nvarchar(7), @ChangeOrgCol nvarchar(50)
Declare @ReplaceFunctionSlowDetailID INT

select @ChangeOrgCol = isnull(Text1, '') from AW_tblAWSetting(NoLock)

set @tableName = Replace(@Month, '/', '') + '_' + convert(nvarchar(12), @LSAwardsID)

set @MonthUserID =  REPLACE(dbo.fnFormatStrRemoveSpecChar(isnull(@UserGroupID,'')),'.','')
/*TungTT83 bổ sung replace sau dấu @*/
if (CHARINDEX('@', @MonthUserID) > 0)
BEGIN
	SET @MonthUserID = LEFT(@MonthUserID, CHARINDEX('@', @MonthUserID) - 1) 
END

SET @Prefix = REPLACE(REPLACE(REPLACE(CONVERT(NVARCHAR(20), GETDATE(), 120), '-', ''), ':', ''), ' ', '') + RIGHT('000' + CAST(DATEPART(MILLISECOND, GETDATE()) AS VARCHAR(3)), 3)

SET @Prefix = @tableName + '_' + @MonthUserID + '_' + @FunctionID + '_' + @Prefix

SET @MonthUserID = @Prefix

set @PreMonth = right(convert(nvarchar, dateadd(mm, -1, convert(date, '01/' + @Month, 103)), 103), 7)

SET @EHDS_UserGroupID = CASE WHEN @EHDS_UserGroupID = '' THEN NULL ELSE  dbo.fnConvertToStringParseXML(@EHDS_UserGroupID,2) END 
SET @EHDS_Email = CASE WHEN @EHDS_Email = '' THEN NULL ELSE  dbo.fnConvertToStringParseXML(@EHDS_Email,2) END
SET @EHDS_HRCode = CASE WHEN @EHDS_HRCode = '' THEN NULL ELSE  dbo.fnConvertToStringParseXML(@EHDS_HRCode,2) END
SET @EHDS_IDNo = CASE WHEN @EHDS_IDNo = '' THEN NULL ELSE  dbo.fnConvertToStringParseXML(@EHDS_IDNo,2) END
SET @EHDS_MaSoThue = CASE WHEN @EHDS_MaSoThue = '' THEN NULL ELSE  dbo.fnConvertToStringParseXML(@EHDS_MaSoThue,2) END
SET @EHDS_AccountNo = CASE WHEN @EHDS_AccountNo = '' THEN NULL ELSE  dbo.fnConvertToStringParseXML(@EHDS_AccountNo,2) END
SET @EHDS_MaTheChamCong = CASE WHEN @EHDS_MaTheChamCong = '' THEN NULL ELSE  dbo.fnConvertToStringParseXML(@EHDS_MaTheChamCong,2) END
SET @EHDS_EmpCodeOld = CASE WHEN @EHDS_EmpCodeOld = '' THEN NULL ELSE  dbo.fnConvertToStringParseXML(@EHDS_EmpCodeOld,2) END

select top 1 @CustomerID = CustomerID from PR_tblCustomerSetup(NoLock) where Active = 1

----tao chuoi dieu kien
set @strSQL2 = ''

IF isnull(@EmpCode, '') <> ''
	SET @strSQL2 = @strSQL2 + ' AND (E.EmpCode like N''%' + @EmpCode + '%'')'
IF isnull(@EmpName, '') <> ''
	SET @strSQL2 = @strSQL2 + ' AND (E.EmpName like N''%' + @EmpName + '%'' OR E.EmpName_Unsign like N''%' + @EmpName + '%'')'
IF  @LSCompanyID is not null
	SET @strSQL2 = @strSQL2 + ' AND (E.LSCompanyID = ' + convert(nvarchar(12), @LSCompanyID) + ')'  
IF  @LSLevel1ID is not null
	SET @strSQL2 = @strSQL2 + ' AND (E.LSLevel1ID = ' + convert(nvarchar(12), @LSLevel1ID) + ')'  
IF  @LSLevel2ID is not null
	SET @strSQL2 = @strSQL2 + ' AND (E.LSLevel2ID = ' + convert(nvarchar(12), @LSLevel2ID) + ')'  
IF  @LSLevel3ID is not null
	SET @strSQL2 = @strSQL2 + ' AND (E.LSLevel3ID = ' + convert(nvarchar(12), @LSLevel3ID) + ')'
IF  @LSLevel4ID is not null
	SET @strSQL2 = @strSQL2 + ' AND (E.LSLevel4ID = ' + convert(nvarchar(12), @LSLevel4ID) + ')'
IF  @LSLevel5ID is not null
	SET @strSQL2 = @strSQL2 + ' AND (E.LSLevel5ID = ' + convert(nvarchar(12), @LSLevel5ID) + ')'
IF  @LSLevel6ID is not null
	SET @strSQL2 = @strSQL2 + ' AND (E.LSLevel6ID = ' + convert(nvarchar(12), @LSLevel6ID) + ')'
IF  @LSLevel7ID is not null
	SET @strSQL2 = @strSQL2 + ' AND (E.LSLevel7ID = ' + convert(nvarchar(12), @LSLevel7ID) + ')'
IF  @LSLevel8ID is not null
	SET @strSQL2 = @strSQL2 + ' AND (E.LSLevel8ID = ' + convert(nvarchar(12), @LSLevel8ID) + ')'
IF  @LSLevel9ID is not null
	SET @strSQL2 = @strSQL2 + ' AND (E.LSLevel9ID = ' + convert(nvarchar(12), @LSLevel9ID) + ')'
--Hlevel
IF  @LSHLevel1ID is not null
	SET @strSQL2 = @strSQL2 + ' AND (E.LSHLevel1ID = N''' + convert(nvarchar(12), @LSHLevel1ID) + ''')'
IF  @LSHLevel2ID is not null
	SET @strSQL2 = @strSQL2 + ' AND (E.LSHLevel2ID = N''' + convert(nvarchar(12), @LSHLevel2ID) + ''')'
IF  @LSHLevel3ID is not null
	SET @strSQL2 = @strSQL2 + ' AND (E.LSHLevel3ID = N''' + convert(nvarchar(12), @LSHLevel3ID) + ''')'
IF  @LSHLevel4ID is not null
	SET @strSQL2 = @strSQL2 + ' AND (E.LSHLevel4ID = N''' + convert(nvarchar(12), @LSHLevel4ID) + ''')'
IF  @LSHLevel5ID is not null
	SET @strSQL2 = @strSQL2 + ' AND (E.LSHLevel5ID = N''' + convert(nvarchar(12), @LSHLevel5ID) + ''')'	
IF  @LSHLevel6ID is not null
	SET @strSQL2 = @strSQL2 + ' AND (E.LSHLevel6ID = N''' + convert(nvarchar(12), @LSHLevel6ID) + ''')'
	
IF  @LSLocationID is not null
	SET @strSQL2 = @strSQL2 + ' AND (E.LSLocationID = N''' + convert(nvarchar(12), @LSLocationID) + ''')'
IF  @LSJobTitleID is not null
	SET @strSQL2 = @strSQL2 + ' AND (E.LSJobTitleID = N''' + convert(nvarchar(12), @LSJobTitleID) + ''')'
IF  @LSLoaiHinhNhanVienID is not null
	SET @strSQL2 = @strSQL2 + ' AND (E.LSLoaiHinhNhanVienID = N''' + convert(nvarchar(12), @LSLoaiHinhNhanVienID) + ''')'
IF isnull(@SetFormulaID, '') <> '' and @Activity not in ('CalSalaryItemSYS','CalSalaryItemUser')
	SET @strSQL2 = @strSQL2 + ' AND (''' + @SetFormulaID + ''' = dbo.AW_fnGetFormulaID(E.EmpID, ''' + @Month + ''', ''' + convert(nvarchar(12), @LSAwardsID) + ''') )'

--RlogID 12819
IF isnull(@LSCapBacNhanVienID, '') <> ''
	SET @strSQL2 = @strSQL2 + ' AND (charindex(''@'' + convert(nvarchar(12),E.LSCapBacNhanVienID) + ''@'' , ''@' + @LSCapBacNhanVienID + '@'', 0) > 0)'
IF isnull(@LSKhoiNhanVienID, '') <> ''
	SET @strSQL2 = @strSQL2 + ' AND (charindex(''@'' + convert(nvarchar(12),E.LSKhoiNhanVienID) + ''@'' , ''@' + @LSKhoiNhanVienID + '@'', 0) > 0)'
IF isnull(@LSDanhMucQTLV1ID, '') <> ''
	SET @strSQL2 = @strSQL2 + ' AND (charindex(''@'' + convert(nvarchar(12),WR.DanhMucQTLV1ID) + ''@'' , ''@' + @LSDanhMucQTLV1ID + '@'', 0) > 0)'

	--tao bang tam
	create table #tempPer(EmpID int null)
	SET @strSQLtmp = ' CREATE NONCLUSTERED INDEX [IX_tempPer_' + dbo.fnFormatStrRemoveSpecChar(isnull(@UserGroupID,'')) + '_' + convert(nvarchar(12), @FunctionID) + '_EmpID] ON [dbo].[#tempPer]([EmpID] ASC) '
	print(@strSQLtmp)	
	exec(@strSQLtmp)

------------------------------------------------------
if @Activity='LoadData'
BEGIN
	IF object_id('tempdb..#AW_spfrmAwardCalc_LoadData_Per') is not null
		DROP table [dbo].[#AW_spfrmAwardCalc_LoadData_Per]
	
	CREATE TABLE [#AW_spfrmAwardCalc_LoadData_Per](EmpID INT)
	CREATE INDEX IX_2802_EmpID ON dbo.[#AW_spfrmAwardCalc_LoadData_Per] (EmpID)

	IF object_id('AW_vAwardPeriod_' + @tableName) is not null 
	BEGIN			
		INSERT INTO [#AW_spfrmAwardCalc_LoadData_Per] (EmpID)
		SELECT EmpID
		FROM dbo.fnGetAllEmp_Permission_EffDate(@UserGroupID, @FunctionID ,convert(datetime, @strDate, 103))

		set @strSQLtmp = 
		N'
			declare @Date datetime = convert(datetime,'''+@strDate+''', 103)
	
			Insert into dbo.[#tempPer](EmpID)
			select E.EmpID
			from  HR_fnEmp(@Date) E 
				inner join [#AW_spfrmAwardCalc_LoadData_Per] (NOLOCK) PQ on E.EmpID = PQ.EmpID
				LEFT JOIN 
				(
					Select W1.EmpID, W1.DanhMucQTLV1ID
					from HR_tblWorkingRecord (Nolock) W1
					inner join
					(
						Select R1.EmpID, MAX(R1.FromDate) as FromDate
						from HR_tblWorkingRecord (Nolock) R1
						Group by R1.EmpID
					) W2 on W2.EmpID = W1.EmpID and W2.FromDate = W1.FromDate
				) WR on WR.EmpID = E.EmpID
		'
		if (isnull(@strSQL2, '') <> '')
			SET @strSQLtmp = @strSQLtmp + @strSQL2			
		
		print(@strSQLtmp)	
		
		exec(@strSQLtmp)

		SET @strSQL=
		N'
			declare @date date
			set @date = convert(date, '''+@strDate+''', 103)

			SELECT AW.EmpID, AW.LSAwardsID, '''+@Month+''' Month, E.EmpCode, E.EmpName
				, case when LPR.IsLock = 1 then ''X'' else '''' end Status
				,case when ''' + @LanguageID + ''' = ''EN'' then E.CompanyEN else CompanyVN end Company
				,case when ''' + @LanguageID + ''' = ''EN'' then E.Level1EN else Level1VN end Level1
				,case when ''' + @LanguageID + ''' = ''EN'' then E.Level2EN else Level2VN end Level2
				,case when ''' + @LanguageID + ''' = ''EN'' then E.Level3EN else Level3VN end Level3
				,case when ''' + @LanguageID + ''' = ''EN'' then E.Level4EN else Level4VN end Level4
				,case when ''' + @LanguageID + ''' = ''EN'' then E.Level5EN else Level5VN end Level5
				,case when ''' + @LanguageID + ''' = ''EN'' then E.Level6EN else Level6VN end Level6
				,case when ''' + @LanguageID + ''' = ''EN'' then E.Level7EN else Level7VN end Level7
				,case when ''' + @LanguageID + ''' = ''EN'' then E.Level8EN else Level8VN end Level8
				,case when ''' + @LanguageID + ''' = ''EN'' then E.Level9EN else Level9VN end Level9
				,case when ''' + @LanguageID + ''' = ''EN'' then E.JobTitleEN else JobTitleVN end JobTitle
				,E.StartDateStr AS StartDateStr
				,CONVERT(NVARCHAR(15), E.StartDateCompany,103) StartDateCompany
				,CONVERT(NVARCHAR(15), TER.LastWorkingDate,103) LastWorkingDate
				,CONVERT(NVARCHAR(15), TER.EffectDate,103) EffectDate
			FROM AW_vAwardPeriod_' + @tableName + ' (NoLock) AW
				inner join HR_fnEmp (@Date) E on AW.EmpID = E.EmpID
				inner join dbo.[#tempPer] PQ on E.EmpID = PQ.EmpID
				LEFT JOIN TER_tblTermination(NOLOCK) TER ON E.EmpID = TER.EmpID
				LEFT JOIN 
				(
					Select W1.EmpID, W1.DanhMucQTLV1ID
					from HR_tblWorkingRecord (Nolock) W1
					inner join
					(
						Select R1.EmpID, MAX(R1.FromDate) as FromDate
						from HR_tblWorkingRecord (Nolock) R1
						Group by R1.EmpID
					) W2 on W2.EmpID = W1.EmpID and W2.FromDate = W1.FromDate
				) WR on WR.EmpID = E.EmpID
				left join AW_tblLockAwardEmp(NoLock) LPR On LPR.EmpID = AW.EmpID and LPR.Month = ''' + @Month + ''' and LPR.LSAwardsID = ''' + convert(nvarchar(12), @LSAwardsID) +'''
				left join LS_tblAwards(Nolock)AWW on AWW.LSAwardsID = '''+convert(nvarchar(12), @LSAwardsID)+'''
				LEFT JOIN AW_tblSetUpAwardPaymentOrg (NOLOCK) D ON AW.EmpID = D.EmpID AND D.Month = ''' + @Month + ''' AND D.LSAwardsID = ' + RTRIM(@LSAwardsID) + '
		'
		
		IF @EHDS_LSLoaiNhanVienID IS NOT NULL
			BEGIN
				SET @strSQL = @strSQL + CHAR(13) + N' LEFT JOIN dbo.Split(''' + @EHDS_LSLoaiNhanVienID + ''','';'') EHDS1 ON EHDS1.items = case when ISNULL(E.LSLoaiNhanVienID,'''') = '''' THEN -1 else E.LSLoaiNhanVienID end'
				SET @strSQL2 = @strSQL2 + CHAR(13) + N' AND EHDS1.items IS NOT NULL'
			END 

		IF @EHDS_LSNhomNhanVienID IS NOT NULL
			BEGIN 
				SET @strSQL = @strSQL + CHAR(13) + N' LEFT JOIN dbo.Split(''' + @EHDS_LSNhomNhanVienID + ''','';'') EHDS2 ON EHDS2.items = case when ISNULL(E.LSNhomNhanVienID,'''') = '''' THEN -1 else E.LSNhomNhanVienID end'
				SET @strSQL2 = @strSQL2 + CHAR(13) + N' AND EHDS2.items IS NOT NULL'
			END 

		IF @EHDS_LSCapBacNhanVienID IS NOT NULL
			BEGIN 
				SET @strSQL = @strSQL + CHAR(13) + N' LEFT JOIN dbo.Split(''' + @EHDS_LSCapBacNhanVienID + ''','';'') EHDS3 ON EHDS3.items = case when ISNULL(E.LSCapBacNhanVienID,'''') = '''' THEN -1 else E.LSCapBacNhanVienID end'
				SET @strSQL2 = @strSQL2 + CHAR(13) + N' AND EHDS3.items IS NOT NULL'
			END 	

		IF @EHDS_LSContractTypeID IS NOT NULL
			BEGIN 
				SET @strSQL = @strSQL + CHAR(13) + N' LEFT JOIN dbo.Split(''' + @EHDS_LSContractTypeID + ''','';'') EHDS4 ON EHDS4.items = case WHEN ISNULL(E.LSContractTypeID,'''') = '''' THEN -1 else E.LSContractTypeID end'
				SET @strSQL2 = @strSQL2 + CHAR(13) + N' AND EHDS4.items IS NOT NULL'
			END 

		IF @EHDS_LSStatusChangeID IS NOT NULL
			BEGIN 
				SET @strSQL = @strSQL + CHAR(13) + N' LEFT JOIN dbo.Split(''' + @EHDS_LSStatusChangeID + ''','';'') EHDS5 ON EHDS5.items = case when ISNULL(E.LSStatusChangeID,'''') = '''' THEN -1 else E.LSStatusChangeID end'
				SET @strSQL2 = @strSQL2 + CHAR(13) + N' AND EHDS5.items IS NOT NULL'
			END 

		IF @EHDS_Email IS NOT NULL
			BEGIN 
				SET @strSQL = @strSQL + CHAR(13) + N' LEFT JOIN dbo.Split(''' + @EHDS_Email + ''','';'') EHDS6 ON EHDS6.items = E.Email'
				SET @strSQL2 = @strSQL2 + CHAR(13) + N' AND EHDS6.items IS NOT NULL'
			END 

		IF @EHDS_HRCode IS NOT NULL
			BEGIN 
				SET @strSQL = @strSQL + CHAR(13) + N' LEFT JOIN dbo.Split(''' + @EHDS_HRCode + ''','';'') EHDS7 ON EHDS7.items = E.HRCode'
				SET @strSQL2 = @strSQL2 + CHAR(13) + N' AND EHDS7.items IS NOT NULL'
			END 

		IF @EHDS_IDNo IS NOT NULL
			BEGIN 
				SET @strSQL = @strSQL + CHAR(13) + N' LEFT JOIN dbo.Split(''' + @EHDS_IDNo + ''','';'') EHDS8 ON EHDS8.items = E.IDNo'
				SET @strSQL2 = @strSQL2 + CHAR(13) + N' AND EHDS8.items IS NOT NULL'
			END
			 
		IF @EHDS_MaSoThue IS NOT NULL
			BEGIN 
				SET @strSQL = @strSQL + CHAR(13) + N' LEFT JOIN dbo.Split(''' + @EHDS_MaSoThue + ''','';'') EHDS9 ON EHDS9.items = E.MaSoThue'
				SET @strSQL2 = @strSQL2 + CHAR(13) + N' AND EHDS9.items IS NOT NULL'
			END 

		IF @EHDS_MaTheChamCong IS NOT NULL
			BEGIN 
				SET @strSQL = @strSQL + CHAR(13) + N' LEFT JOIN dbo.Split(''' + @EHDS_MaTheChamCong + ''','';'') EHDS10 ON EHDS10.items = E.MaTheChamCong'
				SET @strSQL2 = @strSQL2 + CHAR(13) + N' AND EHDS10.items IS NOT NULL'
			END 

		IF @EHDS_EmpCodeOld IS NOT NULL
			BEGIN 
				SET @strSQL = @strSQL + CHAR(13) + N' LEFT JOIN dbo.Split(''' + @EHDS_EmpCodeOld + ''','';'') EHDS11 ON EHDS11.items = E.EmpCodeOld'
				SET @strSQL2 = @strSQL2 + CHAR(13) + N' AND EHDS11.items IS NOT NULL'
			END 

		IF @EHDS_AccountNo IS NOT NULL
			BEGIN 
				SET @strSQL = @strSQL + CHAR(13) + N' LEFT JOIN dbo.Split(''' + @EHDS_AccountNo + ''','';'') EHDS12 ON EHDS12.items = E.AccountNo'
				SET @strSQL2 = @strSQL2 + CHAR(13) + N' AND EHDS12.items IS NOT NULL'
			END 

		IF @EHDS_UserGroupID IS NOT NULL
			BEGIN 
				SET @strSQL = @strSQL + CHAR(13) + N' LEFT JOIN dbo.HR_fnGetEmpIDbyUserGroupID(''' + @EHDS_UserGroupID + ''') EHDS13 ON EHDS13.EmpID = PQ.EmpID'
				SET @strSQL2 = @strSQL2 + CHAR(13) + N' AND EHDS13.EmpID IS NOT NULL'
			END 

		-- ThoLD6: nếu có trong bảng này thì ko xuất ra báo cáo	D.
		SET @strSQL = @strSQL + CHAR(13) +
		'
			WHERE 1=1 AND D.EmpID IS NULL 
		'
		if (isnull(@IsLockPR, '') <> '2')
			SET @strSQL = @strSQL + ' AND (isnull(LPR.IsLock, ''0'') = N''' + @IsLockPR + ''')' + @strSQL2
		
		print (@strSQL)
		
		EXEC (@strSQL)		
	END
END	
-------------------------------------------------
else IF @Activity = 'checkEmpToCalc'  
BEGIN	
	set @strSQLtmp = 
	N'
		declare @Date datetime = convert(datetime,'''+@strDate+''', 103)
		
		if object_id(''tempdb..#Permission_Emp'') is not null
			drop table #Permission_Emp

		create table #Permission_Emp(EmpID int)
		CREATE NONCLUSTERED INDEX [IX_Permission_Emp_' + dbo.fnFormatStrRemoveSpecChar(isnull(@UserGroupID,'')) + '_' + convert(nvarchar(12), @FunctionID) + '_EmpID] ON [dbo].[#Permission_Emp]([EmpID] ASC) 

		insert into #Permission_Emp(EmpID)
		select EmpID
		From dbo.fnGetAllEmp_Permission_EffDate('''+ @UserGroupID +''','''+ @FunctionID +''',@Date)

		Insert into dbo.[#tempPer](EmpID)
		select E.EmpID
		from HR_fnEmp(@Date) E 
		inner join #Permission_Emp (NOLOCK) PQ on PQ.EmpID = E.EmpID
		LEFT JOIN 
		(
			Select W1.EmpID, W1.DanhMucQTLV1ID
			from HR_tblWorkingRecord (Nolock) W1
			inner join
			(
				Select R1.EmpID, MAX(R1.FromDate) as FromDate
				from HR_tblWorkingRecord (Nolock) R1
				inner join #Permission_Emp (NOLOCK) PQ on PQ.EmpID = R1.EmpID
				Group by R1.EmpID
			) W2 on W2.EmpID = W1.EmpID and W2.FromDate = W1.FromDate
		) WR on WR.EmpID = E.EmpID
	'
	if (isnull(@strSQL2, '') <> '')
		SET @strSQLtmp = @strSQLtmp + @strSQL2	
	
	print(@strSQLtmp)	
	
	exec(@strSQLtmp)

	set @strSQLtmp = 
	N'
		select top 1 AW.EmpID
		from AW_vAwardPeriod_' + @tableName + ' (NoLock) AW						
			inner join dbo.[#tempPer] (Nolock) PQ on AW.EmpID = PQ.EmpID
			left join AW_tblLockAwardEmp (NoLock) LPR On LPR.EmpID = AW.EmpID and LPR.LSAwardsID = AW.LSAwardsID and LPR.Month = ''' + @Month + ''' and LPR.IsLock = 1
			left join LS_tblAwards (Nolock) AWW on AWW.LSAwardsID = '''+convert(nvarchar(12),@LSAwardsID)+'''
		WHERE LPR.LockAwardEmpID is null
	'
	
	print(@strSQLtmp)

	exec(@strSQLtmp)	
END
-------------------------------------------------
else IF @Activity = 'CalSalaryItemSYS'  -- Tinh theo chi tieu luong system
BEGIN	
	declare @Date1 datetime, @Date2 datetime
	if object_id('AW_vAwardPeriod_' + @MonthUserID + '_temp') is not null
	Begin				
		exec('drop table AW_vAwardPeriod_' + @MonthUserID + '_temp')
	End	

	--Tao bang luong tinh theo user
	set @strSQLtmp = 
	N'
		declare @Date date
		set @Date = convert(date,'''+@strDate+''', 103)

		if object_id(''tempdb..#tempCalSalaryItemSYS_Permission_EffDate'') is not null
		drop table #tempCalSalaryItemSYS_Permission_EffDate
	
		Select EmpID
		into dbo.[#tempCalSalaryItemSYS_Permission_EffDate]
		from dbo.fnGetAllEmp_Permission_EffDate('''+ @UserGroupID +''','''+ @FunctionID +''',@Date)

		if object_id(''tempdb..#tempCalSalaryItemSYS_FormulaID'') is not null
		drop table dbo.[#tempCalSalaryItemSYS_FormulaID]

		create table bo.[#tempCalSalaryItemSYS_FormulaID] (EmpID int, FormulaID nvarchar(12))
	'
	if(isnull(@SetFormulaID, '') <> '')
	begin
		SET @strSQLtmp = @strSQLtmp + 
			'
				INSERT INTO dbo.[#tempCalSalaryItemSYS_FormulaID](EmpID,FormulaID)
				Select E.EmpID, dbo.AW_fnGetFormulaID(E.EmpID, ''' + @Month + ''', ''' + convert(nvarchar(12), @LSAwardsID) + ''') as FormulaID			
				from HR_tblEmp (Nolock) E
				inner join dbo.[#tempCalSalaryItemSYS_Permission_EffDate] (Nolock) T on T.EmpID = E.EmpID
			'
	END

	SET @strSQLtmp = @strSQLtmp + 
	N'
		SELECT * INTO AW_vAwardPeriod_' + @MonthUserID + '_temp 
		FROM 
		(
			select AW.* 
			from AW_vAwardPeriod_' + @tableName + ' (NoLock) AW
			inner JOIN HR_fnEmp (@Date) E on E.EmpID = AW.EmpID
			LEFT JOIN 
			(
				Select W1.EmpID, W1.DanhMucQTLV1ID
				from HR_tblWorkingRecord (Nolock) W1
				inner join
				(
					Select R1.EmpID, MAX(R1.FromDate) as FromDate
					from HR_tblWorkingRecord (Nolock) R1
					Group by R1.EmpID
				) W2 on W2.EmpID = W1.EmpID and W2.FromDate = W1.FromDate
			) WR on WR.EmpID = E.EmpID
			left join AW_tblLockAwardEmp(NoLock) LPR On LPR.EmpID = E.EmpID and LPR.LSAwardsID = AW.LSAwardsID and LPR.Month = ''' + @Month + ''' and IsLock = 1
			inner join dbo.[#tempCalSalaryItemSYS_Permission_EffDate] (Nolock) C on E.EmpID = C.EmpID
			left join dbo.[#tempCalSalaryItemSYS_FormulaID]	(Nolock) FID on FID.EmpID = AW.EmpID							
			left join LS_tblAwards(Nolock) AWW on AWW.LSAwardsID = '''+convert(nvarchar(12),@LSAwardsID)+'''
			WHERE LPR.LockAwardEmpID is null 
	'
	if(isnull(@SetFormulaID, '') <> '')
	BEGIN
		set @strSQLtmp = @strSQLtmp + 
		N'
			and FID.FormulaID = ''' + isnull(@SetFormulaID,'') + ''' 
		'
	END
							
	if (isnull(@strSQL2, '') <> '')
		SET @strSQLtmp = @strSQLtmp + @strSQL2	
		
	SET @strSQLtmp = @strSQLtmp + 
	'
		) A
	' 
	
	print(@strSQLtmp)
	exec(@strSQLtmp)

	-- ThoLD6 RlogID - 22370 - DXG
	-- Lấy thêm những nhân viên trong kỳ có gán tính tổng hợp về nhân viên đơn vị chi thưởng
	IF EXISTS (SELECT TOP 1 1 FROM dbo.sysobjects (NOLOCK) WHERE [name] = 'AW_vAwardPeriod_' + @MonthUserID + '_temp')
	AND EXISTS (SELECT TOP 1 1 FROM AW_tblAWSetting (NOLOCK) WHERE TongHopThuongVeMaNVDonViChiThuong = 1)
	AND EXISTS (SELECT TOP 1 1 FROM AW_tblSetUpAwardPaymentOrg WHERE [Month] = @Month AND LSAwardsID = @LSAwardsID)
	BEGIN		
		 SET @strCol1 = ''
		 SET @strCol2 = ''
		 SELECT @strCol1 = @strCol1 + QUOTENAME(COLUMN_NAME) + ',',
			 @strCol2 = @strCol2 + 'AW.' + QUOTENAME(COLUMN_NAME) + ',' 
		FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'AW_vAwardPeriod_' + @MonthUserID + '_temp'

		IF ISNULL(@strCol1,'') <> '' SET @strCol1 = LEFT(@strCol1,LEN(@strCol1)-1)
		IF ISNULL(@strCol2,'') <> '' SET @strCol2 = LEFT(@strCol2,LEN(@strCol2)-1)

		SET @strSQLtmp = N'
		-- ThoLD6: Thêm nhân viên để tính tổng hợp
		INSERT INTO AW_vAwardPeriod_' + @MonthUserID + '_temp ( ' +  @strCol1 + ' )
		SELECT ' + @strCol2 + '
		FROM AW_vAwardPeriod_' + @tableName + ' (NoLock) AW
		INNER JOIN
		(
			SELECT D.EmpID
			FROM AW_vAwardPeriod_' + @MonthUserID + '_temp (NOLOCK) AW
			INNER JOIN AW_tblSetUpAwardPaymentOrg (NOLOCK) D ON D.EmpID_Sum = AW.EmpID AND D.Month = ''' + @Month + ''' AND D.LSAwardsID = ' + RTRIM(@LSAwardsID) + '
			GROUP BY D.EmpID	
		) D ON D.EmpID = AW.EmpID
		LEFT JOIN AW_vAwardPeriod_' + @MonthUserID + '_temp (NOLOCK) B ON B.EmpID = AW.EmpID
		WHERE B.EmpID IS NULL
		'
		PRINT(@strSQLtmp)
		EXEC(@strSQLtmp)
	END	
	-- End ThoLD6 RlogID - 22370 - DXG

	SET @strCol1 = ''
	SET @strCol2 = ''
	SELECT @strCol1 = @strCol1 + QUOTENAME(COLUMN_NAME) + ',',
		@strCol2 = @strCol2 + CASE WHEN COLUMN_NAME IN ('EmpID','AWMonth', 'LSAwardsID','AWNgayChot') OR 
			COLUMN_NAME IN (SELECT DISTINCT AWTieuChiThuongCode FROM AW_tblTieuChiThuong (NOLOCK) WHERE IsText = 1) 
			THEN '' ELSE 'CONVERT(FLOAT, ' + QUOTENAME(COLUMN_NAME) + ') AS ' END + QUOTENAME(COLUMN_NAME) + ',' 
	FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'AW_vAwardPeriod_' + @MonthUserID + '_temp'
	
	if(isnull(@strCol1,'') <> '')	set @strCol1 = LEFT(@strCol1,LEN(@strCol1)-1)
	if(isnull(@strCol2,'') <> '')	set @strCol2 = LEFT(@strCol2,LEN(@strCol2)-1)

	--TriTV 18-02-2019 RLog 13914
	--Bo ma hoa du lieu va chuyen cac cot ve dang money de tinh toan
	SET @strColNotChange = ''

	SELECT @strColNotChange = @strColNotChange + AWTieuChiThuongCode + '@'
	FROM AW_tblTieuChiThuong (NOLOCK)
	WHERE IsText = 1
	if(isnull(@strColNotChange,'') <> '')	set @strColNotChange = '@' + LEFT(@strColNotChange,LEN(@strColNotChange)-1)

	SET @strSQLMaHoa = N'
	EXEC SYS_spGetD @Activity = ''AllColumn'', @TableName = ''AW_vAwardPeriod_' + @MonthUserID + '_temp'', @ColumnNotD = ''EmpID@AWMonth@LSAwardsID@AWNgayChot' + @strColNotChange + '''
	'
	PRINT @strSQLMaHoa
	EXEC (@strSQLMaHoa)

	--Kiem tra bang thuong
	if exists (select top 1 1 from dbo.sysobjects (Nolock) where [name] = 'AW_vAwardPeriod_' + @MonthUserID )
	Begin		
		set @strSQLtmp = 'drop table AW_vAwardPeriod_' + @MonthUserID
		exec(@strSQLtmp)
	End	

	SET @strSQLMaHoa = N'
		SELECT *
		INTO AW_vAwardPeriod_' + @MonthUserID + '
		FROM AW_vAwardPeriod_' + @MonthUserID + '_temp

		EXEC SYS_spAlterTable @Activity = ''AlterAllColumn'', @TableName = ''AW_vAwardPeriod_' + @MonthUserID + ''', @DataType=''float'', @ColumnNotChange = ''EmpID@AWMonth@LSAwardsID@AWNgayChot' + @strColNotChange + '''

		CREATE NONCLUSTERED INDEX [IX_AW_vAwardPeriod_' + @MonthUserID + '_ItemSYS_EmpID] ON [dbo].[AW_vAwardPeriod_' + @MonthUserID + '] ([EmpID])
	'
	
	if(@IsAlert = 1) PRINT @strSQLMaHoa
	EXEC (@strSQLMaHoa)

	if exists (select top 1 1 from dbo.sysobjects (Nolock) where [name] = 'AW_vAwardPeriod_' + @MonthUserID + '_temp')
	Begin		
		set @strSQLtmp = 'drop table AW_vAwardPeriod_' + @MonthUserID + '_temp'
		exec(@strSQLtmp)
	End	
	--EndTriTV 18-02-2019 RLog 13914

	if object_id('PR_Table_TieuChiSYS') is null
	begin		
		create table PR_Table_TieuChiSYS
		(				
			TieuChi nvarchar(max),
			ThoiGian int,
			CreateTime DATETIME,
			IsPR	bit,
			IsPIT	bit,
			IsAW	bit
		)
	END
    
	Declare @while_ReplaceTableName nvarchar(1000)
	Declare @while_ReplaceFormula nvarchar(1000)
	Declare @while_ReplaceColumnName nvarchar(1000)
	Declare @while_Declare nvarchar(max)
	
	if OBJECT_ID('tempdb..#PR_tblReplaceFunctionTable') is not null
		Drop table dbo.[#PR_tblReplaceFunctionTable]

	Select B.ReplaceFunctionSlowDetailID, A.TableName,B.ColumnName,B.Formula
	into #PR_tblReplaceFunctionTable
	from PR_tblReplaceFunctionTable (Nolock) A
	inner join PR_tblReplaceFunctionTableDetail (Nolock) B on B.ReplaceFunctionSlowID = A.ReplaceFunctionSlowID
	Where A.UsetmpEmp = 1

	--quanbm2 20111020 : lay du lieu vao bang tam de tang toc tinh toan
	delete from AW_tblAwardCalc
	
	set @strSQLtmp = 
	N'	
		declare @Date datetime, @dMonth datetime
		set @Date = convert(datetime,''' + @strDate + ''', 103)
		set @dMonth = convert(datetime, ''' + '01/' + @Month + ''' , 103)
					
		Insert into AW_tblAwardCalc(EmpID, IncomeByOrgID, BasicSalary)
		select EmpID, 
			dbo.AW_fnDoanhThuLoiNhuan_Org_ID(AW.EmpID, ''' + @Month + ''', 1, AW.LSAwardsID),
			dbo.fnGetBasicSalary_MoiNhat(AW.EmpID, @Date)
		from 
		(	
			select distinct EmpID, LSAwardsID
			from AW_tblIncomeByEmp (NoLock) 
			where LSAwardsID = ''' + convert(nvarchar(12), @LSAwardsID) + '''
			and IncomeDate <= @dMonth
		) AW
	'
		--nhung khach hang nao su dung moi chay thui
	if exists(select top 1 1 from AW_tblTieuChiThuong (NoLock) where Formula like '%AW_fnGetBasicSalary_Org%')
	Begin
		print(@strSQLtmp)
		exec(@strSQLtmp)
	End
	--end quanbm2 20111020
	
	--Gan ngay thay doi co cau cho Cot
	if exists(select top 1 1 from AW_tblChangeOrgEmp(NoLock))
		--Co thiet lap cot Ngay thay doi co cau hok?
		and exists(select top 1 1 from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'AW_vAwardPeriod_' + @MonthUserID and COLUMN_NAME = @ChangeOrgCol)
		--Loai thuong co dc map thay doi co cau hok?
		and exists(select top 1 1 from dbo.LS_tblAwards (NoLock) where LSAwardsID = @LSAwardsID and IsChangeOrg = 1)
	Begin
		if not exists(select top 1 1 from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME = 'AW_vAwardPeriod_' + @MonthUserID and COLUMN_NAME = '_STT')
		Begin
			--them cot tam
			set @strSQLtmp = 
			N'	
				ALTER Table AW_vAwardPeriod_' + @MonthUserID + ' 
				Add _STT int null
			'
			--print(@strSQLtmp)
			exec (@strSQLtmp)
		End
			--Update cot tam
			set @strSQLtmp = 
			'
				DECLARE @id INT, @EmpID int
				SET @id = 0
				set @EmpID = '''';

				WITH main_sql AS
				(
					SELECT top 100000 *
					FROM AW_vAwardPeriod_' + @MonthUserID + '(NoLock) 
					where EmpID in (select distinct EmpID from AW_tblChangeOrgEmp(NoLock))
					ORDER BY EmpID 
				)

				UPDATE  main_sql
				SET @id = _STT = case when EmpID <> @EmpID then 1 else @id + 1 end,
					@EmpID = EmpID
			'
			--print(@strSQLtmp)
			exec (@strSQLtmp)
			--Update cot ngay thay doi co cau
			set @strSQLtmp = 
			N'
				declare @FromDate datetime, @Date datetime
				set @FromDate = dbo.AW_fnGetTuNgayChotPeriod(''' + @Month + ''', ''' + convert(nvarchar(12), @LSAwardsID) + ''')
				set @Date = convert(datetime,'''+@strDate+''', 103)
				
				Update A
				Set ' + @ChangeOrgCol + ' = isnull(B.FromDate, A.AWNgayChot)
				from AW_vAwardPeriod_' + @MonthUserID + '(NoLock) A
				left join 
				(	
					select row_number() over (PARTITION by EmpID ORDER BY EmpID) row, EmpID, FromDate
					from dbo.AW_fnChangeOrgEmp(@FromDate, @Date)
				) B on A.EmpID = B.EmpID and A._STT = B.row
			'
			--print(@strSQLtmp)
			exec (@strSQLtmp)
			
		--drop cot tam
		set @strSQLtmp = 
		N'	
			ALTER Table AW_vAwardPeriod_' + @MonthUserID + ' 
			drop column _STT 
		'
		--print(@strSQLtmp)
		exec (@strSQLtmp)
	End
	--end Gan ngay thay doi co cau cho cot
	if object_id('AW_tblAwardLog_' + Replace(@Month,'/','') + '_'+ CONVERT(NVARCHAR,@LSAwardsID)) is not NULL
    begin
	--Insert vao bang log	
		SET @strSQLtmp = 
		N'
			Insert into AW_tblAwardLog_' + Replace(@Month,'/','') + '_'+ CONVERT(NVARCHAR,@LSAwardsID) + ' 
				(EmpID, Action, FunctionID, Creater, CreateTime)
			select EmpID, ''Calculate'', ' + isnull(@FunctionID, '102') + ', ''' + isnull(@UserGroupID, '') + ''', getdate()
			from AW_vAwardPeriod_' + @MonthUserID +  '(Nolock) 
		'			
		--print @strSQL
		EXEC (@strSQLtmp) 
	end

	--Tinh toan cac cong thuc luong
	set @strSQLtmp = ' 
						[BEGIN###]
						UPDATE AW 
						SET AW.[$ColValue$] = isnull($Formula$, 0)
						FROM AW_vAwardPeriod_'+ @MonthUserID + ' AW
						[END###]
						'
	
	set @strSQLtmpText = '
						[BEGIN###]
						UPDATE AW 
						SET AW.[$ColValue$] =  $Formula$	
						FROM AW_vAwardPeriod_'+ @MonthUserID + ' AW
						[END###]
						'
						
	Create table #tmpIsCompany(Amount nvarchar(255))
	declare @Amount nvarchar(255)
	

	declare cur cursor for
	SELECT AWTieuChiThuongID, AWTieuChiThuongCode, isnull(Formula,'0') as Formula, IsText, IsCompany, ReplaceFunctionSlowDetailID
	FROM AW_tblTieuChiThuong(NoLock) 
	where IsSYS = 1 
		and (LSAwardsID = @LSAwardsID or LSAwardsID is null)
		--and rtrim(ltrim(isnull(Formula, ''))) <> ''
		and (
				(AWTieuChiThuongCode <> @ChangeOrgCol and isnull(@ChangeOrgCol, '') <> '') 
				or @ChangeOrgCol = '' or @ChangeOrgCol is null
			)
		and CustomerID = @CustomerID 
	Order by Rank, IsText desc 
	
	open cur
	fetch next from cur into @AWTieuChiThuongID, @AWTieuChiThuongCode, @Formula, @IsText, @IsCompany, @ReplaceFunctionSlowDetailID
	while @@FETCH_STATUS = 0
		begin	
			set @Date1 = GETDATE()
			
			if (@IsText = 0)
				set @strSQL = @strSQLtmp
			else set @strSQL = @strSQLtmpText
			
			set @strSQL = replace(@strSQL, '$ColValue$', @AWTieuChiThuongCode)
			if (isnull(@IsCompany, 0) = 0)
				set @strSQL = replace(@strSQL, '$Formula$', @Formula)
			set @strSQL = replace(@strSQL, '$AWTieuChiThuongID$', @AWTieuChiThuongID)		
			set @strSQL = replace(@strSQL, '''''', '''')
			set @strSQL = replace(@strSQL, '"', '''')
			
			print(@AWTieuChiThuongCode)
			print(@Formula)
			print(@IsCompany)
			
			if (isnull(@IsCompany, 0) = 1)
			Begin
				print('zôooooooo')
				delete #tmpIsCompany
				
				set @strSQLtmpCalc = 
				'
					Insert into #tmpIsCompany(Amount)
					select convert(nvarchar(255), ' + @Formula + ')
				'
				set @strSQLtmpCalc = replace(@strSQLtmpCalc, 'AW.AWMonth', '''' + @Month + '''')
				set @strSQLtmpCalc = replace(@strSQLtmpCalc, 'AW.LSAwardsID', '''' + convert(nvarchar(12), @LSAwardsID) + '''')
				print @strSQLtmpCalc
				exec (@strSQLtmpCalc)
				
				select @Amount = Amount
				from #tmpIsCompany
				
				if (@IsText = 0)
					set @strSQL = replace(@strSQL, '$Formula$', @Amount)
				else set @strSQL = replace(@strSQL, '$Formula$', '''' + @Amount + '''')
			End
			
			--Thay thế Function Table
			if exists (select top 1 1 from dbo.[#PR_tblReplaceFunctionTable] (Nolock) where ReplaceFunctionSlowDetailID = @ReplaceFunctionSlowDetailID)
			begin
				set @while_Declare = 
				N'
					Declare @tEmp tEmp, @DauCK date, @CuoiCK date
					Select TOP 1 @DauCK = TK_TuNgayChot, @CuoiCK = AWNgayChot
					from dbo.AW_vAwardPeriod_' +  @MonthUserID + ' (Nolock)
							
					INSERT INTO @tEmp (EmpID)
					Select EmpID
					from AW_vAwardPeriod_'+ @MonthUserID + ' (Nolock)							 
				'
						
				Select	@while_ReplaceTableName = TableName,
						@while_ReplaceColumnName = ColumnName,
						@while_ReplaceFormula = Formula						
				from dbo.[#PR_tblReplaceFunctionTable] (Nolock)
				where ReplaceFunctionSlowDetailID = @ReplaceFunctionSlowDetailID

				set @strSQL = replace(@strSQL,'[BEGIN###]',@while_Declare)
				set @strSQL = replace(@strSQL,'[END###]',@while_ReplaceTableName)
				set @strSQL = Replace(@strSQL,@while_ReplaceFormula,@while_ReplaceColumnName)						
			end
					
			set @strSQL = replace(@strSQL,'[BEGIN###]','')
			set @strSQL = replace(@strSQL,'[END###]','')

			print @strSQL
			exec (@strSQL)
					
			set @Date2 = GETDATE()
			print(datediff(ss, @Date2, @Date1))

			INSERT INTO PR_Table_TieuChiSYS(TieuChi,ThoiGian,CreateTime,IsAW)
			VALUES(@strSQL,datediff(second, @Date1, @Date2),GETDATE(),1)
			
			fetch next from cur into @AWTieuChiThuongID, @AWTieuChiThuongCode, @Formula, @IsText, @IsCompany, @ReplaceFunctionSlowDetailID
		end	--end while cur 1
	close cur
	deallocate cur
	
	SET @strSQLtmp = replace(@strSQLtmp,'[BEGIN###]','')
	SET @strSQLtmp = replace(@strSQLtmp,'[END###]','')
	SET @strSQLtmpText = replace(@strSQLtmpText,'[BEGIN###]','')
	SET @strSQLtmpText = replace(@strSQLtmpText,'[END###]','')

	--Tinh toan cac cot du lieu tong hop
	if exists(	select top 1 1 from AW_tblSetupColumnToCalTotal(NoLock) 
				where isnull(CalAfterColumn, '') = '' 
					and (LSAwardsID is null or LSAwardsID = @LSAwardsID)
				)
	Begin
		exec AW_spfrmCalc_SetupColumnToCalTotal @Month = @Month, @LSAwardsID = @LSAwardsID, 
			@SQLWhere = @strSQL2, @tableName = @MonthUserID, @IsCalcSys = 1
	End
	
	--Tinh toan cac cot du lieu tong hop Tu Luong qua Thuong
	if exists(	select top 1 1 from AW_tblSetupColumnPRToAW(NoLock) 
				where isnull(CalAfterColumn, '') = '' 
					and (LSAwardsID is null or LSAwardsID = @LSAwardsID)
				)
	Begin
		exec AW_spfrmCalc_SetupColumnPRToAW @Month = @Month, @LSAwardsID = @LSAwardsID, 
			@SQLWhere = @strSQL2, @tableName = @MonthUserID, @IsCalcSys = 1
	End
	
	--Tinh toan cac cot du lieu tong hop Tu Luong qua Thuong - Cách 2
	if exists(	select top 1 1 from AW_tblSetupColumnPRToAW_nd(NoLock) 
				where isnull(CalAfterColumn, '') = '' 
					and (LSAwardsID is null or LSAwardsID = @LSAwardsID)
				)
	Begin
		exec AW_spfrmCalc_SetupColumnPRToAW_nd @Month = @Month, @LSAwardsID = @LSAwardsID, 
			@SQLWhere = @strSQL2, @tableName = @MonthUserID, @IsCalcSys = 1
	END
    PRINT(' AW_spfrmCalc_SetupColumnPRToAW_nd @Month = '+ @Month + ', @LSAwardsID ='+ CONVERT(VARCHAR,@LSAwardsID) + ', 
			@SQLWhere ='+ @strSQL2+ ', @tableName = '+@MonthUserID+ ', @IsCalcSys = 1')
	
	--Tinh toan cac cot du lieu tong hop theo tieu chi--
	if exists(select top 1 1 from AW_tblSetupColumnToCalTotalByItem(NoLock) where isnull(CalAfterColumn, '') = '')
	Begin
		exec AW_spfrmCalc_SetupColumnToCalTotalByItem @Month = @Month, @LSAwardsID = @LSAwardsID, 
			@SQLWhere = @strSQL2, @tableName = @MonthUserID, @IsCalcSys = 1			
	End

	--Tinh toan cac cot du lieu tong hop Tu Thuong qua Thuong
	print('Tinh toan cac cot du lieu tong hop Tu Thuong qua Thuong')	
	if exists(	select top 1 1 from AW_tblSetupColumnAWToAW(NoLock) where isnull(CalAfterColumn, '') = '' and ToLSAwardsID = @LSAwardsID)
	Begin
		exec AW_spfrmCalc_SetupColumnAWToAW @Month = @Month, @LSAwardsID = @LSAwardsID, 
			@SQLWhere = @strSQL2, @tableName = @MonthUserID, @IsCalcSys = 1
	End
	
	--TriTV 01-04-2021 RLog 16124
	--Tinh toan cac cot du lieu tong hop Tu Thuong qua Thuong theo thoi gian
	print('Tinh toan cac cot du lieu tong hop Tu Thuong qua Thuong')	
	if exists(	select top 1 1 from AW_tblSetupColumnAWToAW_ByTime(NoLock) where isnull(CalAfterColumn, '') = '')
	Begin
		exec AW_spfrmCalc_SetupColumnAWToAW_ByTime @Month = @Month, @LSAwardsID = @LSAwardsID, 
			@SQLWhere = @strSQL2, @tableName = @MonthUserID, @IsCalcSys = 1
	End
	--End TriTV 01-04-2021 RLog 16124

	if exists(	select top 1 1 from AW_tblSetupColumnAWToAWPIT(NoLock) where isnull(CalAfterColumn, '') = '')
	BEGIN
	PRINT('Tinh toan cac cot du lieu tong hop Tu Thuong qua Thuong PIT')	
		exec AW_spfrmCalc_SetupColumnAWToAWPIT @Month = @Month, @LSAwardsID = @LSAwardsID, 
			@SQLWhere = @strSQL2, @tableName = @MonthUserID, @IsCalcSys = 1
	End
	
	--TriTV 18-02-2019 RLog 13914
	--Convert ve decimal de ko bi loi so luu vao qua dai ra chu e+
	SET @strColNotChange = 'EmpID@AWMonth@LSAwardsID@AWNgayChot' + @strColNotChange

	SET @strCol1 = ''
	SET @strCol2 = ''
	SELECT @strCol1 = @strCol1 + QUOTENAME(COLUMN_NAME) + ',',
		@strCol2 = @strCol2 + CASE WHEN COLUMN_NAME IN ('EmpID','AWMonth', 'LSAwardsID','AWNgayChot') OR 
					COLUMN_NAME IN (SELECT DISTINCT AWTieuChiThuongCode FROM AW_tblTieuChiThuong (NOLOCK)	WHERE IsText = 1) 
				THEN '' ELSE 'CONVERT(FLOAT, ' + QUOTENAME(COLUMN_NAME) + ') AS ' END + QUOTENAME(COLUMN_NAME) + ',' 
	FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'AW_vAwardPeriod_' + @MonthUserID + '_temp'
	
	if(isnull(@strCol1,'') <> '')	set @strCol1 = LEFT(@strCol1,LEN(@strCol1)-1)
	if(isnull(@strCol2,'') <> '')	set @strCol2 = LEFT(@strCol2,LEN(@strCol2)-1)
	--EndTriTV 18-02-2019 RLog 13914

	--Delete cai cu
	set @strSQLtmp = 'Delete AW
					from AW_vAwardPeriod_' + @MonthUserID + ' AW1
						inner join AW_vAwardPeriod_' + @tableName + ' AW on AW1.EmpID = AW.EmpID'							
	print(@strSQLtmp)	
	exec(@strSQLtmp)	
	
	--Insert cai moi
	set @strSQLtmp = 'Insert into AW_vAwardPeriod_' + @tableName + ' (' + @strCol1 + ' )
					select ' + @strCol2 + ' from AW_vAwardPeriod_' + @MonthUserID + '(Nolock)'
						
	print(@strSQLtmp)	
	exec(@strSQLtmp)
	
	--Xoa bang tam
	set @strSQLtmp = 'drop table AW_vAwardPeriod_' + @MonthUserID
						
	print(@strSQLtmp)	
	exec(@strSQLtmp)
	
	--TriTV 18-02-2019 RLog 13914
	--Ma hoa lai nhung cot dc danh dau la IsMaHoa
	SET @strColMaHoa = N''
	SELECT @strColMaHoa = @strColMaHoa + A.AWTieuChiThuongCode + '@'
	FROM AW_tblTieuChiThuong(NoLock) A
	WHERE A.CustomerID = @CustomerID 
	AND A.IsMaHoa = 1

	if(isnull(@strColMaHoa,'') <> '')
	BEGIN
		set @strColMaHoa = LEFT(@strColMaHoa,LEN(@strColMaHoa)-1)
	
		SET @strSQLMaHoa = N'
		EXEC SYS_spSetE @Activity = ''MultiColumn'', @TableName = ''AW_vAwardPeriod_' + @tableName + ''', @ColumnName = ''' + @strColMaHoa + ''', 
						@ColumnNotE = ''EmpID@AWMonth@LSAwardsID@AWNgayChot''
		'
		PRINT @strSQLMaHoa
		EXEC (@strSQLMaHoa)
	END
	--End TriTV 18-02-2019 RLog 13914
END
----------------------------------------------------------------------
-- Buoc 2
-- Tính SalaryItem for user
else IF @Activity = 'CalSalaryItemUser'  -- Tinh theo chi tieu luong
BEGIN
	declare @SQLCur2 nvarchar(4000), @SQLCur2_tmp nvarchar(4000), @SQLCalPR nvarchar(4000)
	
	if object_id('PR_Table_TieuChiUser') is null
	begin		
		create table PR_Table_TieuChiUser
		(				
			TieuChi nvarchar(max),
			ThoiGian int,
			CreateTime datetime,
			IsPR	bit,
			IsPIT	bit,
			IsAW	bit
		)
	end


	if object_id('tempdb..##tempCalSalaryItemUser_Temp') is not null
		drop table dbo.[##tempCalSalaryItemUser_Temp]

	--Cong chuoi cho Cur2
	set @SQLCur2 = 
	'
			declare @Date datetime
			set @Date = convert(datetime,'''+@strDate+''', 103)
											
			SELECT AW.AWTieuChiThuongID, AW.Formula, AW.Seq, AW.AWTieuChiThuongCode
			INTO dbo.[##tempCalSalaryItemUser_Temp]
			FROM AW_tblAwardPeriod_' + @tableName + ' (NoLock) AW 
				INNER JOIN HR_fnEmp(@Date) E ON AW.EmpID = E.EmpID
				LEFT JOIN 
				(
					Select W1.EmpID, W1.DanhMucQTLV1ID
					from HR_tblWorkingRecord (Nolock) W1
					inner join
					(
						Select R1.EmpID, MAX(R1.FromDate) as FromDate
						from HR_tblWorkingRecord (Nolock) R1
						Group by R1.EmpID
					) W2 on W2.EmpID = W1.EmpID and W2.FromDate = W1.FromDate
				) WR on WR.EmpID = E.EmpID
				left join AW_tblLockAwardEmp (NoLock) LPR On LPR.EmpID = E.EmpID and LPR.LSAwardsID = AW.LSAwardsID and LPR.Month = ''' + @Month + ''' and IsLock = 1
				left join LS_tblAwards (Nolock)AWW on AWW.LSAwardsID = '''+convert(nvarchar(12),@LSAwardsID)+'''					
			WHERE AW.AWMonth = ''' + @Month + ''' 
				and AW.IsSys = 0 
				and LPR.LockAwardEmpID is null													
	'
							
	if (isnull(@strSQL2, '') <> '')
		SET @SQLCur2 = @SQLCur2 + @strSQL2
			
	SET @SQLCur2 = @SQLCur2 + 
	' 
		group by AW.AWTieuChiThuongID, AW.Formula, AW.Seq, AW.AWTieuChiThuongCode
		Order by AW.Seq
	'
		
	--Kiem tra bang luong
	if exists (select * from dbo.sysobjects where [name] = 'AW_vAwardPeriod_' + @MonthUserID )
	Begin		
		set @strSQLtmp = 'drop table AW_vAwardPeriod_' + @MonthUserID
		exec(@strSQLtmp)
	End	
	--Tao bang luong tinh theo user
	set @strSQLtmp = 
	'
		declare @Date datetime
		set @Date = convert(datetime,'''+@strDate+''', 103)

		if object_id(''tempdb..#tempCalSalaryItemUser_Permission_EffDate'') is not null
		drop table #tempCalSalaryItemUser_Permission_EffDate
	
		Select EmpID
		into dbo.[#tempCalSalaryItemUser_Permission_EffDate]
		from dbo.fnGetAllEmp_Permission_EffDate('''+ @UserGroupID +''','''+ @FunctionID +''',@Date)

		if object_id(''tempdb..#tempCalSalaryItemUser_FormulaID'') is not null
			drop table dbo.[#tempCalSalaryItemUser_FormulaID]

		create table bo.[#tempCalSalaryItemUser_FormulaID] (EmpID int, FormulaID nvarchar(12))
	'
	if(isnull(@SetFormulaID, '') <> '')
	begin
		SET @strSQLtmp = @strSQLtmp + 
		N'
			INSERT INTO dbo.[#tempCalSalaryItemUser_FormulaID](EmpID,FormulaID)
			Select E.EmpID, dbo.AW_fnGetFormulaID(E.EmpID, ''' + @Month + ''', ''' + convert(nvarchar(12), @LSAwardsID) + ''') as FormulaID			
			from HR_tblEmp (Nolock) E
			inner join dbo.[#tempCalSalaryItemUser_Permission_EffDate] (Nolock) T on T.EmpID = E.EmpID
		'
	END
	
	SET @strSQLtmp = @strSQLtmp + 
	N'
		SELECT * INTO AW_vAwardPeriod_' + @MonthUserID + '_temp 
		FROM 
		(	
			select AW.* 
			from AW_vAwardPeriod_' + @tableName + ' (Nolock) AW
			inner JOIN  HR_fnEmp(@Date) E on E.EmpID = AW.EmpID
			LEFT JOIN 
			(
				Select W1.EmpID, W1.DanhMucQTLV1ID
				from HR_tblWorkingRecord (Nolock) W1
				inner join
				(
					Select R1.EmpID, MAX(R1.FromDate) as FromDate
					from HR_tblWorkingRecord (Nolock) R1
					Group by R1.EmpID
				) W2 on W2.EmpID = W1.EmpID and W2.FromDate = W1.FromDate
			) WR on WR.EmpID = E.EmpID
			left join AW_tblLockAwardEmp(NoLock) LPR On LPR.EmpID = E.EmpID and LPR.LSAwardsID = AW.LSAwardsID and LPR.Month = ''' + @Month + ''' and IsLock = 1
			inner join dbo.[#tempCalSalaryItemUser_Permission_EffDate] C on E.EmpID = C.EmpID
			left join dbo.[#tempCalSalaryItemUser_FormulaID] (Nolock) FID on FID.EmpID = AW.EmpID
			left join LS_tblAwards(Nolock)AWW on AWW.LSAwardsID = ''' + convert(nvarchar(12),@LSAwardsID) + '''
			WHERE LPR.LockAwardEmpID is null
	'
	if(isnull(@SetFormulaID, '') <> '')
	BEGIN
		set @strSQLtmp = @strSQLtmp + 
		N'
			and FID.FormulaID = ''' + isnull(@SetFormulaID,'') + ''' 
		'
	END
							
	if (isnull(@strSQL2, '') <> '')
		SET @strSQLtmp = @strSQLtmp + @strSQL2	
		
	SET @strSQLtmp = @strSQLtmp + ') A'
	print(@strSQLtmp)	
	
	exec(@strSQLtmp)		

	-- ThoLD6 RlogID - 22370 - DXG
	-- Lấy thêm những nhân viên trong kỳ có gán tính tổng hợp về nhân viên đơn vị chi thưởng
	IF EXISTS (SELECT TOP 1 1 FROM dbo.sysobjects (NOLOCK) WHERE [name] = 'AW_vAwardPeriod_' + @MonthUserID + '_temp')
	AND EXISTS (SELECT TOP 1 1 FROM AW_tblAWSetting (NOLOCK) WHERE TongHopThuongVeMaNVDonViChiThuong = 1)
	AND EXISTS (SELECT TOP 1 1 FROM AW_tblSetUpAwardPaymentOrg WHERE [Month] = @Month AND LSAwardsID = @LSAwardsID)
	BEGIN		
		SET @strCol1 = ''
		SET @strCol2 = ''
		SELECT @strCol1 = @strCol1 + QUOTENAME(COLUMN_NAME) + ',',
		       @strCol2 = @strCol2 + 'AW.' + QUOTENAME(COLUMN_NAME) + ',' 
		FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'AW_vAwardPeriod_' + @MonthUserID + '_temp'

		IF ISNULL(@strCol1,'') <> '' SET @strCol1 = LEFT(@strCol1,LEN(@strCol1)-1)
		IF ISNULL(@strCol2,'') <> '' SET @strCol2 = LEFT(@strCol2,LEN(@strCol2)-1)

		SET @strSQLtmp = N'
		-- ThoLD6: Thêm nhân viên để tính tổng hợp
		INSERT INTO AW_vAwardPeriod_' + @MonthUserID + '_temp ( ' +  @strCol1 + ' )
		SELECT ' + @strCol2 + '
		FROM AW_vAwardPeriod_' + @tableName + ' (NoLock) AW
		INNER JOIN
		(
			SELECT D.EmpID
			FROM AW_vAwardPeriod_' + @MonthUserID + '_temp (NOLOCK) AW
			INNER JOIN AW_tblSetUpAwardPaymentOrg (NOLOCK) D ON D.EmpID_Sum = AW.EmpID AND D.Month = ''' + @Month + ''' AND D.LSAwardsID = ' + RTRIM(@LSAwardsID) + '
			GROUP BY D.EmpID	
		) D ON D.EmpID = AW.EmpID
		LEFT JOIN AW_vAwardPeriod_' + @MonthUserID + '_temp (NOLOCK) B ON B.EmpID = AW.EmpID
		WHERE B.EmpID IS NULL
		'
		PRINT(@strSQLtmp)
		EXEC(@strSQLtmp)
	END	
	-- End ThoLD6 RlogID - 22370 - DXG
	
	SET @strCol1 = ''
	SET @strCol2 = ''
	SELECT @strCol1 = @strCol1 + QUOTENAME(COLUMN_NAME) + ',',
		@strCol2 = @strCol2 + CASE WHEN COLUMN_NAME IN ('EmpID','AWMonth', 'LSAwardsID','AWNgayChot') OR 
				COLUMN_NAME IN (SELECT DISTINCT AWTieuChiThuongCode FROM AW_tblTieuChiThuong (NOLOCK)	WHERE IsText = 1) 
				THEN '' ELSE 'CONVERT(FLOAT, ' + QUOTENAME(COLUMN_NAME) + ') AS ' END + QUOTENAME(COLUMN_NAME) + ',' 
	FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'AW_vAwardPeriod_' + @MonthUserID + '_temp'
	
	if(isnull(@strCol1,'') <> '')	set @strCol1 = LEFT(@strCol1,LEN(@strCol1)-1)
	if(isnull(@strCol2,'') <> '')	set @strCol2 = LEFT(@strCol2,LEN(@strCol2)-1)
	
	--TriTV 18-02-2019 RLog 13914
	--Bo ma hoa du lieu va chuyen cac cot ve dang money de tinh toan
	SET @strColNotChange = ''

	SELECT @strColNotChange = @strColNotChange + AWTieuChiThuongCode + '@'
	FROM AW_tblTieuChiThuong (NOLOCK)
	WHERE IsText = 1
	if(isnull(@strColNotChange,'') <> '')	set @strColNotChange = '@' + LEFT(@strColNotChange,LEN(@strColNotChange)-1)

	SET @strSQLMaHoa = N'
	EXEC SYS_spGetD @Activity = ''AllColumn'', @TableName = ''AW_vAwardPeriod_' + @MonthUserID + '_temp'', @ColumnNotD = ''EmpID@AWMonth@LSAwardsID@AWNgayChot' + @strColNotChange + '''
	'
	PRINT @strSQLMaHoa
	EXEC (@strSQLMaHoa)

	--Kiem tra bang thuong
	if exists (select top 1 1 from dbo.sysobjects (Nolock) where [name] = 'AW_vAwardPeriod_' + @MonthUserID )
	Begin		
		set @strSQLtmp = 'drop table AW_vAwardPeriod_' + @MonthUserID
		exec(@strSQLtmp)
	End	

	SET @strSQLMaHoa = N'
		SELECT *
		INTO AW_vAwardPeriod_' + @MonthUserID + '
		FROM AW_vAwardPeriod_' + @MonthUserID + '_temp

		EXEC SYS_spAlterTable @Activity = ''AlterAllColumn'', @TableName = ''AW_vAwardPeriod_' + @MonthUserID + ''', @DataType=''float'', @ColumnNotChange = ''EmpID@AWMonth@LSAwardsID@AWNgayChot' + @strColNotChange + '''

		CREATE NONCLUSTERED INDEX [IX_AW_vAwardPeriod_' + @MonthUserID + '_ItemSYS_EmpID] ON [dbo].[AW_vAwardPeriod_' + @MonthUserID + '] ([EmpID])
	'
	
	if(@IsAlert = 1) PRINT @strSQLMaHoa
	EXEC (@strSQLMaHoa)

	if exists (select top 1 1 from dbo.sysobjects (Nolock) where [name] = 'AW_vAwardPeriod_' + @MonthUserID + '_temp')
	Begin		
		set @strSQLtmp = 'drop table AW_vAwardPeriod_' + @MonthUserID + '_temp'
		exec(@strSQLtmp)
	End	
	--EndTriTV 18-02-2019 RLog 13914
		
	--Tinh toan cac cong thuc luong
	set @strSQLtmp = 
	' 
		UPDATE AW 
		SET AW.[$ColValue$] = isnull($Formula$,0)
		FROM AW_vAwardPeriod_'+ @MonthUserID + ' (Nolock) AW
	'	
	
	--Cong chuoi cho Exec query Update
	set @SQLCalPR = N'
		UPDATE AW
		SET AW.[$ColValue$] = isnull($Formula$,0)
		FROM AW_vAwardPeriod_' + @MonthUserID + ' AW
		inner join (	select EmpID
							from AW_tblAwardPeriod_' + @tableName + '(NoLock) 							
							where Formula = N''$Formula2$''
								and AWTieuChiThuongCode = ''$ColValue$''
						)AW2 on AW.EmpID = AW2.EmpID						
		'

	set @SQLCur2_tmp = @SQLCur2
	print(@SQLCur2_tmp)						
	exec (@SQLCur2_tmp)


	declare curCalPayroll2 cursor READ_ONLY for			
		Select AW.AWTieuChiThuongID, AW.Formula, AW.Seq, AW.AWTieuChiThuongCode 
		from dbo.[##tempCalSalaryItemUser_Temp](Nolock) AW
		Order by AW.Seq asc					
	---mo cursor 2	
	open curCalPayroll2
	fetch next from curCalPayroll2 into @AWTieuChiThuongID, @Formula, @Seq, @AWTieuChiThuongCode
	while @@FETCH_STATUS = 0
		begin	
			set @Date1 = GETDATE()
			set @Formula = replace(@Formula,'[','')
			set @Formula = replace(@Formula,']','') 
			set @Formula = case when rtrim(ltrim(isnull(@Formula, ''))) = '' then '0' else @Formula end
			set @strSQLtmp = @SQLCalPR
			
			set @strSQLtmp = replace(@strSQLtmp, '$ColValue$', @AWTieuChiThuongCode)
			set @strSQLtmp = replace(@strSQLtmp, '$Formula$', @Formula)
			set @strSQLtmp = replace(@strSQLtmp, '"', '''')
			set @strSQLtmp = replace(@strSQLtmp, '$Formula2$', replace(@Formula, '''', ''''''))
			set @strSQLtmp = replace(@strSQLtmp, '$AWTieuChiThuongID$', @AWTieuChiThuongID)
						
			print(@strSQLtmp)
			exec (@strSQLtmp)
							
			set @Date2 = GETDATE()
			print(datediff(ss, @Date2, @Date1))

			INSERT INTO PR_Table_TieuChiUser(TieuChi,ThoiGian,CreateTime,IsAW)
			VALUES(@strSQLtmp,DateDiff(second,@Date1,@Date2),GETDATE(),1)

			--Tinh toan cac cot du lieu tong hop--
			if exists(	select top 1 1 from AW_tblSetupColumnToCalTotal(NoLock) 
						where isnull(CalAfterColumn, '') = @AWTieuChiThuongCode 
							and (LSAwardsID is null or LSAwardsID = @LSAwardsID)
						)
			Begin
				exec AW_spfrmCalc_SetupColumnToCalTotal @Month = @Month, @LSAwardsID = @LSAwardsID, 
					@SQLWhere = @strSQL2, @tableName = @MonthUserID, 
					@IsCalcSys = 0, @AWTieuChiThuongCode = @AWTieuChiThuongCode
			End
			
			--Tinh toan cac cot du lieu tong hop Tu Luong qua Thuong
			if exists(	select top 1 1 from AW_tblSetupColumnPRToAW (NoLock)
						where isnull(CalAfterColumn, '') = @AWTieuChiThuongCode 
							and (LSAwardsID is null or LSAwardsID = @LSAwardsID)
						)
			Begin
				exec AW_spfrmCalc_SetupColumnPRToAW @Month = @Month, @LSAwardsID = @LSAwardsID, 
					@SQLWhere = @strSQL2, @tableName = @MonthUserID, 
					@IsCalcSys = 0, @AWTieuChiThuongCode = @AWTieuChiThuongCode
			End		

			--Tinh toan cac cot du lieu tong hop Tu Luong qua Thuong - cách 2
			if exists(	select top 1 1 from AW_tblSetupColumnPRToAW_nd(NoLock)
						where isnull(CalAfterColumn, '') = @AWTieuChiThuongCode 
							and (LSAwardsID is null or LSAwardsID = @LSAwardsID)
						)
			Begin
				exec AW_spfrmCalc_SetupColumnPRToAW_nd @Month = @Month, @LSAwardsID = @LSAwardsID, 
					@SQLWhere = @strSQL2, @tableName = @MonthUserID, 
					@IsCalcSys = 0, @AWTieuChiThuongCode = @AWTieuChiThuongCode
			End	
			PRINT '@AWTieuChiThuongCode$' + @AWTieuChiThuongCode
			
			--Tinh toan cac cot du lieu tong hop theo tieu chi--
			if exists(select top 1 1 from AW_tblSetupColumnToCalTotalByItem(NoLock) where isnull(CalAfterColumn, '') = @AWTieuChiThuongCode)
			Begin
				exec AW_spfrmCalc_SetupColumnToCalTotalByItem @Month = @Month, @LSAwardsID = @LSAwardsID, 
					@SQLWhere = @strSQL2, @tableName = @MonthUserID, @IsCalcSys = 0, 
					@AWTieuChiThuongCode = @AWTieuChiThuongCode, @Formula = @Formula
			End		
			
			--Tinh toan cac cot du lieu tong hop Tu Thuong qua Thuong
			print('Tinh toan cac cot du lieu tong hop Tu Thuong qua Thuong')	
			if exists(	select top 1 1 from AW_tblSetupColumnAWToAW(NoLock) where isnull(CalAfterColumn, '') = @AWTieuChiThuongCode and ToLSAwardsID = @LSAwardsID)
			Begin
				exec AW_spfrmCalc_SetupColumnAWToAW @Month = @Month, @LSAwardsID = @LSAwardsID, @AWTieuChiThuongCode = @AWTieuChiThuongCode,
					@SQLWhere = @strSQL2, @tableName = @MonthUserID, @IsCalcSys = 0
			End	
			
			--TriTV 01-04-2021 RLog 16124
			--Tinh toan cac cot du lieu tong hop Tu Thuong qua Thuong theo thoi gian
			print('Tinh toan cac cot du lieu tong hop Tu Thuong qua Thuong')	
			if exists(	select top 1 1 from AW_tblSetupColumnAWToAW_ByTime(NoLock) where isnull(CalAfterColumn, '') = @AWTieuChiThuongCode)
			Begin
				exec AW_spfrmCalc_SetupColumnAWToAW_ByTime @Month = @Month, @LSAwardsID = @LSAwardsID, @AWTieuChiThuongCode = @AWTieuChiThuongCode,
					@SQLWhere = @strSQL2, @tableName = @MonthUserID, @IsCalcSys = 0
			End
			--End TriTV 01-04-2021 RLog 16124

			if exists(	select top 1 1 from AW_tblSetupColumnAWToAWPIT(NoLock) where isnull(CalAfterColumn, '') = @AWTieuChiThuongCode)
			Begin
				PRINT('Tinh toan cac cot du lieu tong hop Tu Thuong qua Thuong PIT')	
				exec AW_spfrmCalc_SetupColumnAWToAWPIT @Month = @Month, @LSAwardsID = @LSAwardsID, @AWTieuChiThuongCode = @AWTieuChiThuongCode,
					@SQLWhere = @strSQL2, @tableName = @MonthUserID, @IsCalcSys = 0
			End	
			
			--TriTV 26-03-2021 NhienTBS yeu cau them cho cac turogn hop cong thuc co SUM, MAX, MIN
			IF((charindex('SUM', @Formula) > 0 OR charindex('MAX', @Formula) > 0 OR charindex('MIN', @Formula) > 0))
			AND 1 = 0 -- ThoLD6: ko chạy đoạn này nửa vì chết các dự án ráp fn dbo.MAX ... 
			BEGIN
				IF object_id('tempdb..#temp_Awards') is not null
					DROP table [dbo].[#temp_Awards]

				CREATE TABLE [#temp_Awards](EmpID INT, LSAwardsID INT, Amount MONEY)

				DECLARE @strSQL_SUM_MIN_MAX NVARCHAR(MAX)
				DECLARE @Formula_New NVARCHAR(MAX) = ''
				SET @Formula_New = CASE	WHEN charindex('SUM', @Formula) > 0 THEN 'SUM' 
										WHEN charindex('MAX', @Formula) > 0 THEN 'MAX' 
										WHEN charindex('MIN', @Formula) > 0 THEN 'MIN' 
									END

				SET @Formula = RTRIM(LTRIM(REPLACE(REPLACE(REPLACE(@Formula,'/*SUM*/', ''),'/*MIN*/', ''),'/*MAX*/', '')))	--Khong dc doi sang TRIM, SQL2008 se chet
				
				SET @Formula_New  = @Formula_New + '(ISNULL(Amount,0))'
				
				SET @strSQL_SUM_MIN_MAX = N''
				SELECT @strSQL_SUM_MIN_MAX = @strSQL_SUM_MIN_MAX + N'
				IF object_id(''AW_vAwardPeriod_' + REPLACE(@Month,'/','') + N'_' + CONVERT(NVARCHAR(20), LSAwardsID) +''') is not null
				BEGIN
					IF EXISTS(SELECT * FROM   INFORMATION_SCHEMA.COLUMNS WHERE  TABLE_NAME = ''AW_vAwardPeriod_' + REPLACE(@Month,'/','') + N'_' + CONVERT(NVARCHAR(20), LSAwardsID) +''' AND COLUMN_NAME = ''' + REPLACE(@Formula, '''','''''') + ''')
					BEGIN
						INSERT INTO [#temp_Awards](EmpID, LSAwardsID , Amount)
						SELECT EmpID, LSAwardsID , ' + @Formula + '
						FROM AW_vAwardPeriod_' + REPLACE(@Month, '/', '') + N'_' + CONVERT(NVARCHAR(20), LSAwardsID) + N' (NOLOCK)
					END
				END
				'
				FROM dbo.LS_tblAwards (NOLOCK) 
				WHERE LSAwardsID <> @LSAwardsID
				
				IF(@IsAlert = 1) PRINT (@strSQL_SUM_MIN_MAX)
				EXEC (@strSQL_SUM_MIN_MAX)
				
				SET @strSQL_SUM_MIN_MAX = N'
				UPDATE AW
				SET AW.' + @AWTieuChiThuongCode + ' = isnull(B.Amount,0)
				FROM AW_vAwardPeriod_' + @MonthUserID + ' AW
				INNER JOIN (
					SELECT EmpID, ' + @Formula_New + N' as Amount
					FROM [#temp_Awards] (NOLOCK) WHERE EmpID = 28500
					GROUP BY EmpID
				) B on B.EmpID = AW.EmpID
				'
				
				IF(@IsAlert = 1) PRINT (@strSQL_SUM_MIN_MAX)
				EXEC (@strSQL_SUM_MIN_MAX)

			END
			--End TriTV 26-03-2021 NhienTBS yeu cau them cho cac turogn hop cong thuc co SUM, MAX, MIN

			fetch next from curCalPayroll2 into @AWTieuChiThuongID, @Formula, @Seq, @AWTieuChiThuongCode
		end	--end while cur 2
	close curCalPayroll2
	deallocate curCalPayroll2
	--end cuisor 2		
	
	--TriTV 18-02-2019 RLog 13914
	--Convert ve money de ko bi loi so luu vao qua dai ra chu e+
	SET @strColNotChange = 'EmpID@AWMonth@LSAwardsID@AWNgayChot' + @strColNotChange

	SET @strCol1 = ''
	SET @strCol2 = ''
	SELECT @strCol1 = @strCol1 + QUOTENAME(COLUMN_NAME) + ',',
		@strCol2 = @strCol2 + CASE WHEN COLUMN_NAME IN (SELECT DISTINCT items FROM dbo.Split(@strColNotChange, '@')) THEN '' 
				   WHEN @CustomerID = '143' AND COLUMN_NAME IN (SELECT DISTINCT AWTieuChiThuongCode FROM AW_tblTieuChiThuong (NOLOCK)	WHERE IsText = 0 AND IsText IS NULL)  THEN 'REPLACE(dbo.TS_fnConvertNumberDecimal(' + QUOTENAME(COLUMN_NAME) + ',4,0),'','','''') AS ' 
		   ELSE 'CONVERT(DECIMAL(30,4), ' + QUOTENAME(COLUMN_NAME) + ') AS ' END + QUOTENAME(COLUMN_NAME) + ',' 
 	FROM INFORMATION_SCHEMA.COLUMNS (NOLOCK) WHERE TABLE_NAME = 'AW_vAwardPeriod_' + @tableName
	
	if(isnull(@strCol1,'') <> '')	set @strCol1 = LEFT(@strCol1,LEN(@strCol1)-1)
	if(isnull(@strCol2,'') <> '')	set @strCol2 = LEFT(@strCol2,LEN(@strCol2)-1)
	--EndTriTV 18-02-2019 RLog 13914

	--Delete cai cu
	set @strSQLtmp = 
	'
		Delete AW
		from AW_vAwardPeriod_' + @MonthUserID + ' AW1
		inner join AW_vAwardPeriod_' + @tableName + ' (Nolock) AW on AW1.EmpID = AW.EmpID
	'							
	print(@strSQLtmp)	
	exec(@strSQLtmp)	
	
	--Insert cai moi
	set @strSQLtmp = 'Insert into AW_vAwardPeriod_' + @tableName + ' (' + @strCol1 + ' )
					select ' + @strCol2 + ' from AW_vAwardPeriod_' + @MonthUserID + '(Nolock)'
						
	print(@strSQLtmp)	
	exec(@strSQLtmp)

	--Xoa bang tam
	set @strSQLtmp = 'drop table AW_vAwardPeriod_' + @MonthUserID
						
	print(@strSQLtmp)	
	exec(@strSQLtmp)
	
	--TriTV 18-02-2019 RLog 13914
	--Ma hoa lai nhung cot dc danh dau la IsMaHoa
	SET @strColMaHoa = N''
	SELECT @strColMaHoa = @strColMaHoa + A.AWTieuChiThuongCode + '@'
	FROM AW_tblTieuChiThuong(NoLock) A
	WHERE A.CustomerID = @CustomerID 
	AND A.IsMaHoa = 1

	if(isnull(@strColMaHoa,'') <> '')
	BEGIN
		set @strColMaHoa = LEFT(@strColMaHoa,LEN(@strColMaHoa)-1)
	
		SET @strSQLMaHoa = N'
		EXEC SYS_spSetE @Activity = ''MultiColumn'', @TableName = ''AW_vAwardPeriod_' + @tableName + ''', @ColumnName = ''' + @strColMaHoa + ''', 
						@ColumnNotE = ''EmpID@AWMonth@LSAwardsID@AWNgayChot''
		'
		PRINT @strSQLMaHoa
		EXEC (@strSQLMaHoa)
	END
	--End TriTV 18-02-2019 RLog 13914
END
----------------------------------------------------------------------
else IF @Activity = 'ViewAwardDetailEmp' 
BEGIN
	IF not EXISTS (SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'AW_vAwardPeriod_' + @tableName)
	begin
		select '' AwardCode, '' AwardName, '' Value		
	end
	else
	begin
		
		--TriTV 18-02-2019 RLog 13914
		if exists (select top 1 1 from dbo.sysobjects (nolock) where [name] = 'AW_vAwardPeriod_' + @MonthUserID + '_temp')
		Begin		
			set @strSQLtmp = 'drop table AW_vAwardPeriod_' + @MonthUserID + '_temp'
			exec(@strSQLtmp)
		End

		set @strSQLtmp = 
			'
				select AW.* 
				INTO AW_vAwardPeriod_' + @MonthUserID + '_temp 
				FROM AW_vAwardPeriod_' + @tableName + '(NoLock) AW
			'
		EXEC (@strSQLtmp)

		SET @strCol1 = ''
		SET @strCol2 = ''
		SELECT @strCol1 = @strCol1 + QUOTENAME(COLUMN_NAME) + ',',
			@strCol2 = @strCol2 + CASE WHEN COLUMN_NAME IN ('EmpID','AWMonth', 'LSAwardsID','AWNgayChot') OR 
					COLUMN_NAME IN (SELECT DISTINCT AWTieuChiThuongCode FROM AW_tblTieuChiThuong (NOLOCK)	WHERE IsText = 1) 
				THEN '' ELSE 'CONVERT(FLOAT, ' + QUOTENAME(COLUMN_NAME) + ') AS ' END + QUOTENAME(COLUMN_NAME) + ',' 
		FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'AW_vAwardPeriod_' + @MonthUserID + '_temp'
	
		if(isnull(@strCol1,'') <> '')	set @strCol1 = LEFT(@strCol1,LEN(@strCol1)-1)
		if(isnull(@strCol2,'') <> '')	set @strCol2 = LEFT(@strCol2,LEN(@strCol2)-1)

		--Bo ma hoa du lieu va chuyen cac cot ve dang money de tinh toan
		SET @strColNotChange = ''

		SELECT @strColNotChange = @strColNotChange + AWTieuChiThuongCode + '@'
		FROM AW_tblTieuChiThuong (NOLOCK)
		WHERE IsText = 1
		if(isnull(@strColNotChange,'') <> '')	set @strColNotChange = '@' + LEFT(@strColNotChange,LEN(@strColNotChange)-1)

		SET @strSQLtmp = N'
		EXEC SYS_spGetD @Activity = ''AllColumn'', @TableName = ''AW_vAwardPeriod_' + @MonthUserID + '_temp'', @ColumnNotD = ''EmpID@AWMonth@LSAwardsID@AWNgayChot' + @strColNotChange + '''
		'
		PRINT @strSQLtmp
		EXEC (@strSQLtmp)

		--Kiem tra bang thuong
		if exists (select top 1 1 from dbo.sysobjects (Nolock) where [name] = 'AW_vAwardPeriod_' + @MonthUserID )
		Begin		
			set @strSQLtmp = 'drop table AW_vAwardPeriod_' + @MonthUserID
			exec(@strSQLtmp)
		End	

		SET @strSQLMaHoa = N'
			SELECT *
			INTO AW_vAwardPeriod_' + @MonthUserID + '
			FROM AW_vAwardPeriod_' + @MonthUserID + '_temp (Nolock)

			EXEC SYS_spAlterTable @Activity = ''AlterAllColumn'', @TableName = ''AW_vAwardPeriod_' + @MonthUserID + ''', @DataType=''float'', @ColumnNotChange = ''EmpID@AWMonth@LSAwardsID@AWNgayChot' + @strColNotChange + '''

			CREATE NONCLUSTERED INDEX [IX_AW_vAwardPeriod_' + @MonthUserID + '_ItemSYS_EmpID] ON [dbo].[AW_vAwardPeriod_' + @MonthUserID + '] ([EmpID])
		'
	
		if(@IsAlert = 1) PRINT @strSQLMaHoa
		EXEC (@strSQLMaHoa)

		if exists (select top 1 1 from dbo.sysobjects (Nolock) where [name] = 'AW_vAwardPeriod_' + @MonthUserID + '_temp')
		Begin		
			set @strSQLtmp = 'drop table AW_vAwardPeriod_' + @MonthUserID + '_temp'
			exec(@strSQLtmp)
		End	
		--End TriTV 18-02-2019 RLog 13914

		declare @strCol nvarchar(max), @strColSelect nvarchar(max), @strSQL3 nvarchar(max), @strSQL4 nvarchar(max)
		set @strCol = ''
		set @strColSelect = ''
		
		select @strCol = @strCol + '[' + AWTieuChiThuongCode + '],'	,
			@strColSelect = @strColSelect + --'convert(nvarchar, convert(money, [' + AWTieuChiThuongCode + '])) as ' +AWTieuChiThuongCode  + ','
							case when isnull(IsText, 0) = 1 
								then 'convert(nvarchar, [' + AWTieuChiThuongCode + ']) as ' +AWTieuChiThuongCode  + ','
								else 'convert(nvarchar, convert(money, [' + AWTieuChiThuongCode + '])) as '  +AWTieuChiThuongCode +  ',' end
		from AW_tblTieuChiThuong (NoLock)
		WHERE Used = 1
			and CustomerID = @CustomerID
		ORDER BY IsSys DESC, AWTieuChiThuongCode
		
		if (isnull(@strCol, '') <> '')
		Begin
			set @strCol = left (@strCol, len(@strCol) - 1)
			set @strColSelect = left (@strColSelect, len(@strColSelect) - 1)
		End
		
		SET @strSQL = '
		select 
			/*case when isnull(s.IsText, 0) = 0 then dbo.fnConvertNumber( convert(float, PR2.Orders) )
											else end Value*/ /*TriTV 26-09-2019: LoanLT3: yeu cau bo, luu the nao lay len the do*/
			PR2.Orders as Value
			, case when isnull(s.IsText, 0) = 0 then ''0'' else ''1'' end IsText
			, A.AWTieuChiThuongCode AwardCode
			, case when '''+@LanguageID+''' = ''VN'' then S.VNName else S.Name end as AwardName
			$IsUpdateAwardEmp0$
			, A.Formula			
		from AW_tblAwardPeriod_' + @tableName + '(NoLock) A
			inner join (
							SELECT EmpID, AWTieuChiThuongCode, Orders
							FROM 
							   (SELECT top 1 EmpID, ' 
							   
		set @strSQL3 = '
							   FROM AW_vAwardPeriod_' + @MonthUserID + '(NoLock)
							   where EmpID = ''' + convert(nvarchar(12), @EmpID) + '''
							   ) p
							UNPIVOT
							   (Orders FOR AWTieuChiThuongCode IN 
								  (' 
									 
		set @strSQL4 = 
								')
							)AS unpvt
						)PR2 on A.EmpID = PR2.EmpID and A.AWTieuChiThuongCode = PR2.AWTieuChiThuongCode
			left join AW_tblTieuChiThuong(NoLock) S On S.AWTieuChiThuongID = A.AWTieuChiThuongID
			$IsUpdateAwardEmp1$
		where 1=1
			and CustomerID = ''' + @CustomerID + '''
			and A.EmpID = N'''+ convert(nvarchar(12), @EmpID) + '''
			$IsUpdateAwardEmp2$	
		order by $IsUpdateAwardEmp3$ S.IsSys desc, isnull(A.Seq, 0)	, isnull(S.Rank, 0), S.IsText desc
		'
		if (isnull(@IsUpdateAwardEmp, 0) = 0)
		Begin
			set @strSQL = replace(@strSQL, '$IsUpdateAwardEmp0$', '')
			set @strSQL4 = replace(@strSQL4, '$IsUpdateAwardEmp1$', '')
			set @strSQL4 = replace(@strSQL4, '$IsUpdateAwardEmp2$', '')
			set @strSQL4 = replace(@strSQL4, '$IsUpdateAwardEmp3$', '')
		End
		else
		Begin
			declare @strtmp nvarchar(max)			
			
			set @strtmp = ' , case when '''+@LanguageID+''' = ''VN'' then isnull(U.VNName, S.VNName) else isnull(U.Name, S.Name) end as AwardName2 '
			set @strSQL = replace(@strSQL, '$IsUpdateAwardEmp0$', @strtmp)
			
			set @strtmp = ' left join AW_tblUpdateAwardConfig U on U.LSAwardsID = ''' + convert(nvarchar(12), @LSAwardsID) + ''' and U.AWTieuChiThuongID = S.AWTieuChiThuongID '
			set @strSQL4 = replace(@strSQL4, '$IsUpdateAwardEmp1$', @strtmp)
			
			set @strtmp = ' and (U.Display is null or U.Display = 1) '
			set @strSQL4 = replace(@strSQL4, '$IsUpdateAwardEmp2$', @strtmp)
			
			set @strtmp = ' isnull(U.Rank, S.Rank), '
			set @strSQL4 = replace(@strSQL4, '$IsUpdateAwardEmp3$', @strtmp)
		End
		
		print(@strSQL)
		print(@strColSelect)
		print(@strSQL3)
		print(@strCol)
		print(@strSQL4)
		 
		exec(@strSQL + @strColSelect + @strSQL3 + @strCol + @strSQL4)		
		
		--Xoa bang tam
		set @strSQLtmp = 'drop table AW_vAwardPeriod_' + @MonthUserID
		exec(@strSQLtmp)
	end
END
----------------------------------------------------------------------
else IF @Activity = 'GetFormulabyEmp'  
BEGIN
	
	select NameFormula
	from AW_tblSetFormula(NoLock)
	where SetFormulaID = dbo.AW_fnGetFormulaID(@EmpID, @Month, @LSAwardsID)  
	
	
END
----------------------------------------------------------------------

SET @iError = @@ERROR IF @iError = 0 BEGIN SET @sError = '' RETURN END

GETERRMSG:
	EXEC SYS_spGetMessage @Activity, @LanguageID, @sError OUTPUT
	RETURN

ERRTRANS:

	ROLLBACK TRANSACTION
	GOTO GETERRMSG
