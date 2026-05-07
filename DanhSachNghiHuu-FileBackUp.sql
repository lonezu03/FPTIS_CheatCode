USE [iHRP_V34_PMC]
GO
/****** Object:  StoredProcedure [dbo].[HR_spfrmWarning_DSNVHetTuoiLaoDong2]    Script Date: 5/5/2026 9:15:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[HR_spfrmWarning_DSNVHetTuoiLaoDong2]
@UserGroupID NVARCHAR(50) = NULL,
@FunctionID			NVARCHAR(20) = NULL,
@Activity			NVARCHAR(50) = NULL,
@LanguageID			NVARCHAR(02) = 'VN',
@ReturnMess			NVARCHAR(500)= NULL OUT,
@Truoc1Nam			INT = 0,
@IsThongBao			INT = 0,
@ThoiHanThongBao	INT = 0,
@CountValue			INT	= 0 OUT, --QuangPNV : Tong hong bao cao
@IsWarningList			BIT = 0,
@FromDate			VARCHAR(10) =NULL,
@ToDate				VARCHAR(10) =NULL,
/* Rlog 24515 */
@LoadDefault		BIT = 1
AS

DECLARE @Param1 NVARCHAR(100),
		@Param2	NVARCHAR(100),
		@dFromdate DATETIME,
		@dTodate DATETIME

SELECT	@Param1 = CASE WHEN ISNULL(@Truoc1Nam,0) = 0 THEN 'HR_NhacNhoHetTuoiLD' ELSE 'HR_NhacNhoHetTuoiLDTruoc1Nam' END,
		@Param2 = CASE WHEN ISNULL(@Truoc1Nam,0) = 0 THEN 'HR_ThoiHanNhacNhoHetTuoiLD' ELSE 'HR_ThoiHanNhacNhoHetTuoiLDTruoc1Nam' END

IF(ISNULL(@FromDate,'') <> '') SET @dFromdate = CONVERT(DATETIME,@FromDate,103)
IF(ISNULL(@ToDate,'') <> '') SET @dTodate = CONVERT(DATETIME,@ToDate,103)

--update bang he thong	
IF @Activity = 'Update'
BEGIN
	UPDATE dbo.SYS_tblParameters
	SET ParamValue=@IsThongBao
	WHERE ParamName = @Param1


	UPDATE dbo.SYS_tblParameters
	SET ParamValue = @ThoiHanThongBao
	WHERE ParamName= @Param2
END
ELSE IF @Activity = 'DSNVHetTuoiLaoDong'
BEGIN	
	DECLARE @TuoiNghiHuuNam	INT,
			@TuoiNghiHuuNu	INT,
			@TuoiNghiHuuNam_SoThang	INT,
			@TuoiNghiHuuNu_SoThang	INT
			
	SELECT @IsThongBao		= ISNULL(tb.ParamValue,0)	FROM SYS_tblParameters (NOLOCK) tb WHERE ParamName = @Param1
	SELECT @ThoiHanThongBao = ISNULL(tb.ParamValue,0)	FROM SYS_tblParameters (NOLOCK) tb WHERE ParamName = @Param2
	SELECT @TuoiNghiHuuNam	= ISNULL(tb.ParamValue,0)	FROM SYS_tblParameters (NOLOCK)	tb WHERE ParamName = 'TER_TuoiNghiHuuNam'
	SELECT @TuoiNghiHuuNu	= ISNULL(tb.ParamValue,0)	FROM SYS_tblParameters (NOLOCK)	tb WHERE ParamName = 'TER_TuoiNghiHuuNu'
	SELECT @TuoiNghiHuuNam_SoThang	= ISNULL(tb.ParamValue,0)	FROM SYS_tblParameters (NOLOCK)	tb WHERE ParamName = 'TER_TuoiNghiHuuNam_SoThang'
	SELECT @TuoiNghiHuuNu_SoThang	= ISNULL(tb.ParamValue,0)	FROM SYS_tblParameters (NOLOCK)	tb WHERE ParamName = 'TER_TuoiNghiHuuNu_SoThang'
	
	IF ISNULL(@Truoc1Nam,0)=1
	BEGIN
		SELECT	@TuoiNghiHuuNam = @TuoiNghiHuuNam - 2,
				@TuoiNghiHuuNu  = @TuoiNghiHuuNu  - 2
	END
	PRINT('@TuoiNghiHuuNam=' + CONVERT(NVARCHAR,@TuoiNghiHuuNam))
	PRINT('@TuoiNghiHuuNu=' + CONVERT(NVARCHAR,@TuoiNghiHuuNu))
	PRINT('@IsThongBao=' + CONVERT(NVARCHAR,@IsThongBao))
	PRINT('@ThoiHanThongBao=' + CONVERT(NVARCHAR,@ThoiHanThongBao))
	/************
	SonPQ: Neu co thay doi so luong tham so trong activity nay thi vui long update tuong ung trong store HR_spfrmWarningList @Activity = 'LoadData'
	************/								
	
	SELECT	EmpID
	INTO	dbo.[#temp_Permission]
	FROM	dbo.fnGetAllEmp_Permission(@UserGroupID, @FunctionID)

	IF object_id('tempdb..#tempWaring') is not null
		DROP table [dbo].[#tempWaring]

	CREATE TABLE [#tempWaring](
		EmpID INT NULL,
		NgayHetTuoiLDSort DATETIME NULL
	)

	IF EXISTS (SELECT TOP 1 1 FROM dbo.HR_tblThietLapLoTrinhNghiHuu (NOLOCK))
	BEGIN
		DECLARE @dFromDate_Nam DATE, @dToDate_Nam DATE,
				@dFromDate_Nu DATE, @dToDate_Nu DATE,
				@FromYear INT, @ToYear INT

		SET @FromYear = CASE @LoadDefault 
							WHEN 1 
								THEN YEAR(DATEADD(DAY, @ThoiHanThongBao, GETDATE()))
								ELSE CASE ISNULL(@FromDate, '') 
										WHEN '' 
											THEN 1900 
											ELSE YEAR(CONVERT(DATE, @FromDate, 103))
									 END 
						END
		SET @ToYear = CASE @LoadDefault 
							WHEN 1
								THEN YEAR(DATEADD(DAY, @ThoiHanThongBao, GETDATE()))
								ELSE CASE ISNULL(@ToDate, '') 
										WHEN '' 
											THEN 2100
											ELSE YEAR(CONVERT(DATE, @ToDate, 103))
									 END 
					  END

		SELECT	@dFromDate_Nam = A.FromMonth
		FROM	dbo.HR_tblThietLapLoTrinhNghiHuu (NOLOCK) A
		WHERE	A.Gender = 1
				AND A.FromYear = @FromYear
		SET		@dFromDate_Nam = ISNULL(@dFromDate_Nam, '1962-07-01')

		SELECT	@dToDate_Nam = A.ToMonth
		FROM	dbo.HR_tblThietLapLoTrinhNghiHuu (NOLOCK) A
		WHERE	A.Gender = 1
				AND A.ToYear = @ToYear
		SET		@dToDate_Nam = ISNULL(@dToDate_Nam, '2100-12-31')

		SELECT	@dFromDate_Nu = A.FromMonth
		FROM	dbo.HR_tblThietLapLoTrinhNghiHuu (NOLOCK) A
		WHERE	A.Gender = 0
				AND A.FromYear = @FromYear
		SET		@dFromDate_Nu = ISNULL(@dFromDate_Nu, '1967-05-01')

		SELECT	@dToDate_Nu = A.ToMonth
		FROM	dbo.HR_tblThietLapLoTrinhNghiHuu (NOLOCK) A
		WHERE	A.Gender = 0
				AND A.ToYear = @ToYear
		SET		@dToDate_Nu = ISNULL(@dToDate_Nu, '2100-12-31')




		INSERT INTO #tempWaring (EmpID, NgayHetTuoiLDSort)
		SELECT	A.EmpID, DATEADD(MONTH, ISNULL(C.[Month], 0), DATEADD(YEAR, C.Age, A.DOB))
		FROM	dbo.HR_vEmp (NOLOCK) A
				INNER JOIN dbo.#temp_Permission (NOLOCK) B ON B.EmpID = A.EmpID
				LEFT JOIN dbo.HR_tblThietLapLoTrinhNghiHuu (NOLOCK) C ON C.Gender = A.Gender AND A.DOB BETWEEN C.FromMonth AND C.ToMonth
		WHERE	
				(
					(A.Gender = 0 AND A.DOB BETWEEN @dFromDate_Nu AND @dToDate_Nu)
					OR
					(A.Gender = 1 AND A.DOB BETWEEN @dFromDate_Nam AND @dToDate_Nam)
				)
				AND C.Used = 1
				AND @IsThongBao = 1
				AND A.[Status] = 1
	END
	ELSE
    BEGIN
		--select * into #tempWaring from (
		--select top 10000000

		--	E.EmpID,E.EmpCode, E.EmpName
		--	,case when @LanguageID = 'VN' then E.CompanyVN else E.CompanyEN end as CompanyName
		--	,case when @LanguageID = 'VN' then E.Level1VN  else E.Level1EN end as Division
		--	,case when @LanguageID = 'VN' then E.Level2VN  else E.Level2EN end as Department
		--	,case when @LanguageID = 'VN' then E.Level3VN  else E.Level3EN end as Section		
		--	,case when @LanguageID = 'VN' then E.JobTitleVN else E.JobTitleEN end JobTitle
		--	,E.DOBStr NgaySinh,E.DOB NgaySinhSort
		--	,E.StartDateStr NgayVaoCongTy,E.StartDate NgayVaoCongTySort
		--	,case when E.DOB_GetYear = 1 then
		--			case when E.Gender = 1 then
		--					convert(nvarchar(10),dateadd(mm,@TuoiNghiHuuNam_SoThang,dateadd(yy,@TuoiNghiHuuNam + 1,convert(datetime,'01/01/'+E.DOBStr,103))),103)
		--				 ELSE
		--					convert(nvarchar(10),dateadd(mm,@TuoiNghiHuuNu_SoThang,dateadd(yy,@TuoiNghiHuuNu  + 1,convert(datetime,'01/01/'+E.DOBStr,103))),103)
		--			end
		--		 else
		--			case when E.Gender = 1 then
		--					convert(nvarchar(10),dateadd(mm,@TuoiNghiHuuNam_SoThang,dateadd(yy,@TuoiNghiHuuNam,E.DOB)),103)
		--				  else
		--					convert(nvarchar(10),dateadd(mm,@TuoiNghiHuuNu_SoThang,dateadd(yy,@TuoiNghiHuuNu,E.DOB)),103)
		--			end
		--	 end AS NgayHetTuoiLD
		--	,CASE WHEN E.DOB_GetYear = 1 THEN
		--			CASE WHEN E.Gender = 1 THEN
		--					DATEADD(mm,@TuoiNghiHuuNam_SoThang,DATEADD(yy,@TuoiNghiHuuNam + 1,CONVERT(DATETIME,'01/01/'+E.DOBStr,103)))
		--				 ELSE
		--					DATEADD(mm,@TuoiNghiHuuNu_SoThang,DATEADD(yy,@TuoiNghiHuuNu  + 1,CONVERT(DATETIME,'01/01/'+E.DOBStr,103)))
		--			END
		--		 ELSE
		--			CASE WHEN E.Gender = 1 THEN
		--					DATEADD(mm,@TuoiNghiHuuNam_SoThang,DATEADD(yy,@TuoiNghiHuuNam,E.DOB))
		--				  ELSE
		--					DATEADD(mm,@TuoiNghiHuuNu_SoThang,DATEADD(yy,@TuoiNghiHuuNu,E.DOB))
		--			END
		--	 END AS NgayHetTuoiLDSort,
		--	 CASE WHEN ISNULL(W1.DirectReport,'')<>'' THEN ISNULL(M1.Email,'') ELSE ISNULL(M2.Email,'') END ManagerEmail,
		--	 CASE WHEN ISNULL(W1.DirectReport,'')<>'' THEN M1.vFirstName ELSE M2.vFirstName END ManagerName,
		--	 CASE WHEN (ISNULL(E.DOB, '') <> '') THEN DATEDIFF(yyyy, E.DOB, GETDATE()) ELSE '' END SoTuoi,
		--	 -- Bo sung level 4 den level 9 Bomnv 04/11/2020--
		--	CASE WHEN @LanguageID = 'EN' THEN E.Level4EN ELSE E.Level4VN END Level4,
		--	CASE WHEN @LanguageID = 'EN' THEN E.Level5EN ELSE E.Level5VN END Level5,
		--	CASE WHEN @LanguageID = 'EN' THEN E.Level6EN ELSE E.Level6VN END Level6,
		--	CASE WHEN @LanguageID = 'EN' THEN E.Level7EN ELSE E.Level7VN END Level7,
		--	CASE WHEN @LanguageID = 'EN' THEN E.Level8EN ELSE E.Level8VN END Level8,
		--	CASE WHEN @LanguageID = 'EN' THEN E.Level9EN ELSE E.Level9VN END Level9
		--	-- end sung level 4 den level 9 Bomnv 04/11/2020--

		--FROM HR_vEmp(NOLOCK) e
		--	INNER JOIN dbo.fnGetAllEmp_Permission(@UserGroupID,@FunctionID) PQ ON PQ.EmpID = e.EmpID -- phan quyen du lieu
		--	LEFT JOIN HR_tblWorkingRecord(NOLOCK) W1 ON PQ.EmpID=W1.EmpID
		--	INNER JOIN
		--	(
		--		SELECT EmpID, max(FromDate) FromDate
		--		FROM HR_tblWorkingRecord(NOLOCK)
		--		WHERE FromDate <= GETDATE()
		--		GROUP BY EmpID
		--	) W2 ON W1.EmpID=W2.EmpID AND W1.FromDate=W2.FromDate
		
		--	LEFT JOIN HR_tblEmpCV(NOLOCK) M1 ON W1.DirectReport = M1.EmpID
		--	LEFT JOIN HR_tblEmpCV(NOLOCK) M2 ON W1.InDirectReport = M2.EmpID
		
		--WHERE 1=1
		--	AND @IsThongBao = 1
		--	AND E.Status = 1
		--	AND
		--	(
		--		(
		--			E.Gender=1
		--			AND			
		--			(	
		--				(@FromDate = '' AND @ToDate = '' 
		--					AND
		--					CASE WHEN E.DOB_GetYear = 1 THEN
		--							DATEDIFF(dd,GETDATE(),DATEADD(mm,@TuoiNghiHuuNam_SoThang,DATEADD(yy,@TuoiNghiHuuNam + 1,CONVERT(DATETIME,'01/01/'+E.DOBStr,103))))
		--						 ELSE
		--							DATEDIFF(dd,GETDATE(),DATEADD(mm,@TuoiNghiHuuNam_SoThang,DATEADD(yy,@TuoiNghiHuuNam,E.DOB)))
		--					END BETWEEN 0 AND @ThoiHanThongBao
		--				)
		--				OR
		--				(
		--					CASE WHEN E.DOB_GetYear = 1 THEN
		--							DATEADD(mm,@TuoiNghiHuuNam_SoThang,DATEADD(yy,@TuoiNghiHuuNam + 1,CONVERT(DATETIME,'01/01/'+E.DOBStr,103)))
		--						 ELSE
		--							DATEADD(mm,@TuoiNghiHuuNam_SoThang,DATEADD(yy,@TuoiNghiHuuNam,E.DOB))
		--					END BETWEEN @dFromdate AND @dTodate
		--				)
		--			)
		--		)
		--		OR
		--		(
		--			E.Gender=0
		--			AND
		--			(	
		--				(@FromDate = '' AND @ToDate = ''  
		--					AND
		--					CASE WHEN E.DOB_GetYear = 1 THEN
		--							DATEDIFF(dd,GETDATE(),DATEADD(mm,@TuoiNghiHuuNu_SoThang, DATEADD(yy,@TuoiNghiHuuNu + 1,CONVERT(DATETIME,'01/01/'+E.DOBStr,103))))
		--						 ELSE
		--							DATEDIFF(dd,GETDATE(),DATEADD(mm,@TuoiNghiHuuNu_SoThang, DATEADD(yy,@TuoiNghiHuuNu,E.DOB)))
		--					END BETWEEN 0 AND @ThoiHanThongBao
		--				)
		--				OR
		--				(	
		--					CASE WHEN E.DOB_GetYear = 1 THEN
		--							DATEADD(mm,@TuoiNghiHuuNu_SoThang, DATEADD(yy,@TuoiNghiHuuNu + 1,CONVERT(DATETIME,'01/01/'+E.DOBStr,103)))
		--						 ELSE
		--							DATEADD(mm,@TuoiNghiHuuNu_SoThang, DATEADD(yy,@TuoiNghiHuuNu,E.DOB))
		--					END BETWEEN @dFromdate AND @dTodate
		--				)
		--			)
		--		)
		--	)
		--) AAA

		insert into [dbo].[#tempWaring](EmpID, NgayHetTuoiLDSort)
		select A.EmpID, case when E.DOB_GetYear = 1 then
				case when E.Gender = 1 then
						dateadd(mm,@TuoiNghiHuuNam_SoThang,dateadd(yy,@TuoiNghiHuuNam + 1,convert(datetime,'01/01/'+E.DOBStr,103)))
					 else
						dateadd(mm,@TuoiNghiHuuNu_SoThang,dateadd(yy,@TuoiNghiHuuNu  + 1,convert(datetime,'01/01/'+E.DOBStr,103)))
				end
			 else
				case when E.Gender = 1 then
						dateadd(mm,@TuoiNghiHuuNam_SoThang,dateadd(yy,@TuoiNghiHuuNam,E.DOB))
					  else
						dateadd(mm,@TuoiNghiHuuNu_SoThang,dateadd(yy,@TuoiNghiHuuNu,E.DOB))
				end
		 end AS NgayHetTuoiLDSort
		from [#temp_Permission] A
		LEFT JOIN HR_vEmp(NOLOCK) e ON A.EmpID = e.EmpID
		WHERE 1=1
		AND @IsThongBao = 1
		AND E.Status = 1
		AND
		(
			(
				E.Gender=1
				AND			
				(	
					(@FromDate = '' AND @ToDate = '' 
						AND
						CASE WHEN E.DOB_GetYear = 1 THEN
								DATEDIFF(dd,GETDATE(),DATEADD(mm,@TuoiNghiHuuNam_SoThang,DATEADD(yy,@TuoiNghiHuuNam + 1,CONVERT(DATETIME,'01/01/'+E.DOBStr,103))))
							 ELSE
								DATEDIFF(dd,GETDATE(),DATEADD(mm,@TuoiNghiHuuNam_SoThang,DATEADD(yy,@TuoiNghiHuuNam,E.DOB)))
						END BETWEEN 0 AND @ThoiHanThongBao
					)
					OR
					(
						CASE WHEN E.DOB_GetYear = 1 THEN
								DATEADD(mm,@TuoiNghiHuuNam_SoThang,DATEADD(yy,@TuoiNghiHuuNam + 1,CONVERT(DATETIME,'01/01/'+E.DOBStr,103)))
							 ELSE
								DATEADD(mm,@TuoiNghiHuuNam_SoThang,DATEADD(yy,@TuoiNghiHuuNam,E.DOB))
						END BETWEEN @dFromdate AND @dTodate
					)
				)
			)
			OR
			(
				E.Gender=0
				AND
				(	
					(@FromDate = '' AND @ToDate = ''  
						AND
						CASE WHEN E.DOB_GetYear = 1 THEN
								DATEDIFF(dd,GETDATE(),DATEADD(mm,@TuoiNghiHuuNu_SoThang, DATEADD(yy,@TuoiNghiHuuNu + 1,CONVERT(DATETIME,'01/01/'+E.DOBStr,103))))
							 ELSE
								DATEDIFF(dd,GETDATE(),DATEADD(mm,@TuoiNghiHuuNu_SoThang, DATEADD(yy,@TuoiNghiHuuNu,E.DOB)))
						END BETWEEN 0 AND @ThoiHanThongBao
					)
					OR
					(	
						CASE WHEN E.DOB_GetYear = 1 THEN
								DATEADD(mm,@TuoiNghiHuuNu_SoThang, DATEADD(yy,@TuoiNghiHuuNu + 1,CONVERT(DATETIME,'01/01/'+E.DOBStr,103)))
							 ELSE
								DATEADD(mm,@TuoiNghiHuuNu_SoThang, DATEADD(yy,@TuoiNghiHuuNu,E.DOB))
						END BETWEEN @dFromdate AND @dTodate
					)
				)
			)
		)
	END
		
	--IF (ISNULL(@IsWarningList, 0) = 0)
	--BEGIN
	--	SELECT * FROM #tempWaring ORDER BY NgayHetTuoiLDSort
	--END
	--ELSE
	--BEGIN
	--	SELECT @CountValue = COUNT(*) FROM #tempWaring
	--	SELECT @CountValue CountEmp
	--END
	
	--drop table #tempWaring

	if (isnull(@IsWarningList, 0) = 0)
	begin
		SELECT E.EmpID, E.EmpCode,  E.EmpName, NgayHetTuoiLDSort, convert(nvarchar(10),NgayHetTuoiLDSort,103) NgayHetTuoiLD
		,CASE WHEN @LanguageID = 'VN' THEN E.CompanyVN ELSE E.CompanyEN END AS CompanyName
		,CASE WHEN @LanguageID = 'VN' THEN E.Level1VN  ELSE E.Level1EN END AS Division
		,CASE WHEN @LanguageID = 'VN' THEN E.Level2VN  ELSE E.Level2EN END AS Department
		,CASE WHEN @LanguageID = 'VN' THEN E.Level3VN  ELSE E.Level3EN END AS Section		
		,CASE WHEN @LanguageID = 'VN' THEN E.JobTitleVN ELSE E.JobTitleEN END AS JobTitle
		,CASE WHEN @LanguageID = 'EN' THEN E.Level4EN ELSE E.Level4VN END AS Level4
		,CASE WHEN @LanguageID = 'EN' THEN E.Level5EN ELSE E.Level5VN END AS Level5
		,CASE WHEN @LanguageID = 'EN' THEN E.Level6EN ELSE E.Level6VN END AS Level6
		,CASE WHEN @LanguageID = 'EN' THEN E.Level7EN ELSE E.Level7VN END AS Level7
		,CASE WHEN @LanguageID = 'EN' THEN E.Level8EN ELSE E.Level8VN END AS Level8
		,CASE WHEN @LanguageID = 'EN' THEN E.Level9EN ELSE E.Level9VN END AS Level9
		,E.DOBStr NgaySinh
		,E.DOB NgaySinhSort
		,E.StartDateStr NgayVaoCongTy
		,E.StartDate NgayVaoCongTySort
		,CASE WHEN isnull(W1.DirectReport,'')<>'' THEN isnull(M1.Email,'') ELSE isnull(M2.Email,'') END AS ManagerEmail
		,CASE WHEN isnull(W1.DirectReport,'')<>'' THEN M1.vFirstName ELSE M2.vFirstName END AS ManagerName
		,CASE WHEN (isnull(E.DOB, '') <> '') THEN DATEDIFF(yyyy, E.DOB, getdate()) ELSE '' END AS SoTuoi
		,E.Gender
		,E.DOB_GetYear
		,convert(nvarchar(10), DATEADD(MONTH, DATEDIFF(MONTH, 0, NgayHetTuoiLDSort) + 1, 0), 103) AS NgayNghiHuu /*Tamnb rlog 25707*/
		FROM #tempWaring PQ
		LEFT JOIN dbo.HR_vEmp(NOLOCK) E ON PQ.EmpID = E.EmpID
		LEFT JOIN HR_tblWorkingRecord(NoLock) W1 on PQ.EmpID=W1.EmpID and (GETDATE() between W1.FromDate and Case when W1.ToDate is null then '2300-01-01' else W1.ToDate end)
		LEFT JOIN HR_tblEmpCV(NOLOCK) M1 ON W1.DirectReport = M1.EmpID
		LEFT JOIN HR_tblEmpCV(NOLOCK) M2 ON W1.InDirectReport = M2.EmpID
		order by NgayHetTuoiLDSort
	End
	else
	Begin
		select @CountValue = count(*) from #tempWaring
		select @CountValue CountEmp
	end
	drop table #tempWaring
	
end

























