USE [iHRP_UAT2_TanLong_PRO2]
GO
/****** Object:  StoredProcedure [dbo].[NEW_spfrmManagementDashboardNew_V2]    Script Date: 11/19/2026 1:21:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[NEW_spfrmManagementDashboardNew_V2]
@Activity		VARCHAR(50) = NULL,
@LanguageID		VARCHAR(2) = 'VN',
@UserGroupID	VARCHAR(150) = NULL,
@FunctionID		VARCHAR(50) = NULL,
--------------------------------
@ChartID		NVARCHAR(20) = NULL,
@TypeChart		CHAR(1) = NULL,
@ModuleID NVARCHAR(MAX) = NULL,
@FilterJson		NVARCHAR(MAX) = NULL,
@EmployeeIDs	NVARCHAR(MAX) = NULL,	
@EmployeeCacheKey VARCHAR(64) = NULL,	
@ChuKyCongJson NVARCHAR(MAX) = NULL,
@NgayChotCongGanNhat DATETIME = NULL,
@FirstDateTimeLine DATETIME = NULL,
@LastDateTimeLine DATETIME = NULL,
@EmpID BIGINT = NULL	

AS

	DECLARE @dDate DATE = GETDATE()

	DECLARE @V2FunctionIDs VARCHAR(500) = ',6565,'
	DECLARE @IsV2Screen BIT =
		CASE WHEN CHARINDEX(',' + LTRIM(RTRIM(ISNULL(@FunctionID, ''))) + ',', @V2FunctionIDs) > 0
			 THEN 1 ELSE 0 END

BEGIN
	IF @Activity = 'GetAllGroupCatalog'
	BEGIN
		SELECT	LSDashboardGroupCatalogID, LSDashboardGroupCatalogCode, 
				CASE WHEN @LanguageID = 'VN' THEN VNName ELSE Name END AS GroupCatalogName
		FROM LS_tblDashboardGroupCatalog (NOLOCK) 
		WHERE TypeChart = @TypeChart AND Used = 1 
		ORDER BY Rank
	END
	ELSE IF @Activity = 'GetAllCatalog'
	BEGIN
		DECLARE @CatalogModuleIDs TABLE
		(
			ModuleID VARCHAR(12) NOT NULL PRIMARY KEY
		);

		INSERT INTO @CatalogModuleIDs (ModuleID)
		SELECT DISTINCT LEFT(LTRIM(RTRIM([value])), 12)
		FROM STRING_SPLIT(ISNULL(@ModuleID, N''), N',')
		WHERE LTRIM(RTRIM([value])) <> N'';

		DECLARE @HasCatalogModule BIT = CASE WHEN EXISTS (SELECT 1 FROM @CatalogModuleIDs) THEN 1 ELSE 0 END;

		;WITH CatalogSource AS
		(
			SELECT * FROM dbo.LS_tblDashboardCatalogV2 (NOLOCK) WHERE @IsV2Screen = 1
			UNION ALL
			SELECT * FROM dbo.LS_tblDashboardCatalog   (NOLOCK) WHERE @IsV2Screen = 0
		),
		PER AS
		(
			SELECT DISTINCT P.FunctionID
			FROM @CatalogModuleIDs M
			CROSS APPLY SYS_fnGetFunctionListByUser(@UserGroupID, M.ModuleID) P

			UNION

			SELECT DISTINCT P.FunctionID
			FROM SYS_fnGetFunctionListByUser(@UserGroupID, @ModuleID) P
			WHERE @HasCatalogModule = 0
		)
		SELECT	A.LSDashboardCatalogID, A.LSDashboardGroupCatalogID, A.LSDashboardCatalogCode, 
				A.ChartID, A.FunctionID AS ChartFunctionID,
				CASE
					WHEN A.ChartID = 'index_card_208' AND @LanguageID = 'VN'
						THEN N'Tuyển mới trong tháng và sắp nhận việc'
					WHEN A.ChartID = 'index_card_208'
						THEN N'New hires this month and upcoming onboardings'
					WHEN A.ChartID = 'index_card_209' AND @LanguageID = 'VN'
						THEN N'Nghỉ việc trong tháng và sắp nghỉ việc'
					WHEN A.ChartID = 'index_card_209'
						THEN N'Terminations this month and upcoming terminations'
					WHEN @LanguageID = 'VN' THEN A.VNName
					ELSE A.Name
				END AS CatalogName,
				A.CustomCSS, A.Width, A.Height, FL.ModuleID,
				A.BackColor,
				A.ChartKind,
				A.ColSpan, A.RowSpan, A.LayoutGroupID, A.Rank,
				----------------------------------------------------------------------------------------------
				ISNULL(A.FontColor, '#333333') AS FontColor,
				ISNULL(A.TitleFontColor, '#333333') AS TitleFontColor, 
				ISNULL(A.xAxisFontColor, '#333333') AS xAxisFontColor, 
				ISNULL(A.yAxisFontColor, '#333333') AS yAxisFontColor,
				ISNULL(A.yAxisTitleFont, '#333333') AS yAxisTitleFont,
				ISNULL(A.yAxisTitleFontColor, '#333333') AS yAxisTitleFontColor,
				----------------------------------------------------------------------------------------------
				ISNULL(F1.LSFontCode, 'sans-serif') AS Font, 
				ISNULL(F2.LSFontCode, 'sans-serif') AS TitleFont,
				ISNULL(F3.LSFontCode, 'sans-serif') AS xAxisFont, 
				ISNULL(F4.LSFontCode, 'sans-serif') AS yAxisFont, 
				----------------------------------------------------------------------------------------------
				A.ColorClass, A.IconClass, A.MainValueID, A.SubFirstValueID, A.SubSecondValueID,
				CASE WHEN @LanguageID = 'VN' THEN A.SubFirstVNName ELSE A.SubFirstName END AS SubFirstText,
				CASE WHEN @LanguageID = 'VN' THEN A.SubSecondVNName ELSE A.SubSecondName END AS SubSecondText,
				----------------------------------------------------------------------------------------------
				'SetUpFinalRating_' + B1.PM_SetUpFinalRatingCode AS RatingValueID_1,B1.ColorClass AS ColorClass_1, B1.IconClass AS IconClass_1,
				'SetUpFinalRating_' + B2.PM_SetUpFinalRatingCode AS RatingValueID_2,B2.ColorClass AS ColorClass_2, B2.IconClass AS IconClass_2,
				'SetUpFinalRating_' + B3.PM_SetUpFinalRatingCode AS RatingValueID_3,B3.ColorClass AS ColorClass_3, B3.IconClass AS IconClass_3,
				'SetUpFinalRating_' + B4.PM_SetUpFinalRatingCode AS RatingValueID_4,B4.ColorClass AS ColorClass_4, B4.IconClass AS IconClass_4,
				'SetUpFinalRating_' + B5.PM_SetUpFinalRatingCode AS RatingValueID_5,B5.ColorClass AS ColorClass_5, B5.IconClass AS IconClass_5,
				'SetUpFinalRating_' + B6.PM_SetUpFinalRatingCode AS RatingValueID_6,B6.ColorClass AS ColorClass_6, B6.IconClass AS IconClass_6
		FROM CatalogSource A
		LEFT JOIN PM_tblSetUpFinalRating_New  (NOLOCK) B1 ON B1.PM_SetUpFinalRating_NewID = 1 AND A.LSDashboardCatalogID = 54
		LEFT JOIN PM_tblSetUpFinalRating_New  (NOLOCK) B2 ON B2.PM_SetUpFinalRating_NewID = 2 AND A.LSDashboardCatalogID = 54
		LEFT JOIN PM_tblSetUpFinalRating_New  (NOLOCK) B3 ON B3.PM_SetUpFinalRating_NewID = 3 AND A.LSDashboardCatalogID = 54
		LEFT JOIN PM_tblSetUpFinalRating_New  (NOLOCK) B4 ON B4.PM_SetUpFinalRating_NewID = 4 AND A.LSDashboardCatalogID = 54
		LEFT JOIN PM_tblSetUpFinalRating_New  (NOLOCK) B5 ON B5.PM_SetUpFinalRating_NewID = 5 AND A.LSDashboardCatalogID = 54
		LEFT JOIN PM_tblSetUpFinalRating_New  (NOLOCK) B6 ON B6.PM_SetUpFinalRating_NewID = 6 AND A.LSDashboardCatalogID = 54
		LEFT JOIN LS_tblFont (NOLOCK) F1 ON F1.LSFontID = A.Font
		LEFT JOIN LS_tblFont (NOLOCK) F2 ON F2.LSFontID = A.TitleFont
		LEFT JOIN LS_tblFont (NOLOCK) F3 ON F3.LSFontID = A.xAxisFont
		LEFT JOIN LS_tblFont (NOLOCK) F4 ON F4.LSFontID = A.yAxisFont
		LEFT JOIN SYS_tblFunctionList (NOLOCK) FL ON FL.FunctionID = A.FunctionID
		LEFT JOIN PER ON PER.FunctionID = A.FunctionID
		WHERE A.TypeChart = @TypeChart
		AND (@HasCatalogModule = 0 OR FL.ModuleID IN (SELECT ModuleID FROM @CatalogModuleIDs))
		AND A.Used = 1
		AND PER.FunctionID IS NOT NULL
		AND (@IsV2Screen = 1
		  OR (@IsV2Screen = 0 AND A.ChartID NOT IN
			(N'index_card_207', N'index_card_208', N'index_card_209', N'index_card_210',
			 N'main_chart_201', N'main_chart_202', N'main_chart_203', N'main_chart_204',
			 N'main_chart_205', N'main_chart_206', N'main_chart_211')))
		ORDER BY A.Rank
	END
	ELSE IF @Activity = 'GetGridColumns'
	BEGIN
		SELECT ISNULL(
			(SELECT TOP 1 GridColumns FROM dbo.LS_tblDashboardGridConfig WHERE FunctionID = @FunctionID),
			10
		) AS GridColumns
	END
	ELSE IF @Activity = 'GetLayoutGroups'
	BEGIN
		SELECT	LayoutGroupID, ParentGroupID,
				CASE WHEN @LanguageID = 'VN' THEN VNName ELSE [Name] END AS Title,
				TitleAlign, ColSpan, RowSpan, GridColumns, Rank
		FROM dbo.LS_tblDashboardLayoutGroup (NOLOCK)
		WHERE FunctionID = @FunctionID
		ORDER BY Rank;
	END
	ELSE IF @Activity = 'GetFilter'
	BEGIN
		;WITH FilterConfig AS
		(
			SELECT	LSFilterConfigID, LSFilterConfigCode, [Name], VNName, [Rank], Used, Note,
					Placeholder, PlaceholderVN, [Min], [Max], IsDisabled, IsSearch,
					IsSelectAll, IsListAll, Width, Height, DropdownWidth, DropdownHeight,
					onChange, onSelect, onUnselect, onMaxReached
			FROM dbo.LS_tblDashboardFilterConfig (NOLOCK)
			WHERE Used = 1

			UNION ALL

			SELECT LSFilterConfigID, LSFilterConfigCode, [Name], VNName, [Rank], 1, Note,
				   Placeholder, PlaceholderVN, [Min], [Max], IsDisabled, IsSearch,
				   IsSelectAll, IsListAll, Width, Height, DropdownWidth, DropdownHeight,
				   onChange, onSelect, onUnselect, onMaxReached
			FROM dbo.LS_tblDashboardFilterConfig (NOLOCK)
			WHERE @FunctionID = '6565' AND LSFilterConfigCode = 'QUARTER' AND Used = 0

			UNION ALL

			SELECT	15, 'HLEVEL1', N'H Level 1', N'Pháp nhân', 4, 1, NULL,
					N'Select legal entity', N'Chọn pháp nhân', NULL, NULL, 0, 1,
					1, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
			WHERE @FunctionID = '6565'
			AND NOT EXISTS
			(
				SELECT 1
				FROM dbo.LS_tblDashboardFilterConfig (NOLOCK)
				WHERE LSFilterConfigCode = 'HLEVEL1' AND Used = 1
			)

			UNION ALL

			SELECT V.ID, V.Code, V.EnglishName, V.VietnameseName, V.[Rank], 1, NULL,
				   V.EnglishPlaceholder, V.VietnamesePlaceholder, NULL, NULL, 0, 1,
				   1, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
			FROM (VALUES
				(16, 'JOBTITLE', N'Job title', N'Chức danh', 16, N'Select job title', N'Chọn chức danh'),
				(17, 'CAPBACNV', N'Employee grade', N'Cấp bậc nhân viên', 17, N'Select employee grade', N'Chọn cấp bậc')
			) V(ID, Code, EnglishName, VietnameseName, [Rank], EnglishPlaceholder, VietnamesePlaceholder)
			WHERE @FunctionID = '6565'
			AND NOT EXISTS
			(
				SELECT 1 FROM dbo.LS_tblDashboardFilterConfig (NOLOCK) C
				WHERE C.LSFilterConfigCode = V.Code AND C.Used = 1
			)
		)
		SELECT	LSFilterConfigID, LSFilterConfigCode, 
				'filter' + '_' + CONVERT(VARCHAR(4), LSFilterConfigID) + '_' + LSFilterConfigCode AS ID,
				CASE WHEN @LanguageID = 'VN' THEN VNName ELSE [Name] END AS [Name],
				CASE WHEN @LanguageID = 'VN' THEN PlaceholderVN ELSE Placeholder END AS Placeholder,
				'LoadFilter_' + LSFilterConfigCode AS Activity,
				[Min], [Max], IsDisabled, IsSearch, IsSelectAll, IsListAll, 
				Width, Height, DropdownWidth, DropdownHeight,
				onChange, onSelect, onUnselect, onMaxReached,
				Rank, Used, Note
		FROM FilterConfig A
		ORDER BY CASE WHEN LSFilterConfigCode = 'HLEVEL1' THEN 45 ELSE A.[Rank] * 10 END,
				 A.LSFilterConfigID
	END
	ELSE IF @Activity = 'GetChuKyCongData'
	BEGIN
		IF ISJSON(@FilterJson) = 0
		BEGIN
			RAISERROR('Invalid JSON',16,1)
			RETURN
		END

		DECLARE @CKYears tID;
		DECLARE @CKQuarters tID;
		DECLARE @CKMonths tID;
		DECLARE @CKResolved TABLE (FilterType VARCHAR(10), Value INT);

		INSERT INTO @CKYears SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'YEAR';
		INSERT INTO @CKQuarters SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'QUARTER';
		INSERT INTO @CKMonths SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'MONTH';

		IF NOT EXISTS (SELECT 1 FROM @CKYears)
		BEGIN
			INSERT INTO @CKYears(ID) VALUES (YEAR(@dDate));
		END

		INSERT INTO @CKResolved
		SELECT * FROM dbo.NEW_fnTableResolveTimeFilter(@CKYears,@CKQuarters,@CKMonths);

		DELETE FROM @CKMonths;
		INSERT INTO @CKMonths
		SELECT Value FROM @CKResolved WHERE FilterType = 'MONTH';

		;WITH ChuKyCong AS
		(
			SELECT ROW_NUMBER() OVER(ORDER BY GeneralName) AS RowID, *
			FROM dbo.NEW_fnTableGenerateChuKyCong(@CKYears,@CKQuarters,@CKMonths,@dDate)
		)
		SELECT	RowID,
				GeneralName,
				Years,
				Months,
				Quarters,
				MonthYear,
				FirstDateOfYear,
				LastDateOfYear,
				ChuKyCongFirst,
				ChuKyCongLast,
				FirstDateTimeline,
				LastDateTimeline,
				NgayChotCongGanNhat,
				TRY_CONVERT(DATETIME, FirstDateTimeline, 103) AS FirstDateTimeLineDate,
				TRY_CONVERT(DATETIME, LastDateTimeline, 103) AS LastDateTimeLineDate,
				TRY_CONVERT(DATETIME, NgayChotCongGanNhat, 103) AS NgayChotCongGanNhatDate,
				MonthStart,
				MonthEnd
		FROM ChuKyCong
		ORDER BY RowID;
	END
	ELSE IF @Activity = 'GetEmployeeData'
	BEGIN
		IF EXISTS
		   (
			SELECT 1 FROM dbo.LS_tblDashboardCatalogV2 C
			WHERE C.FunctionID = TRY_CONVERT(INT, @FunctionID) AND C.IsNewV2 = 1
			AND C.ChartID IN (N'index_card_207', N'index_card_208', N'index_card_209', N'index_card_210',
			                  N'main_chart_201', N'main_chart_202', N'main_chart_203', N'main_chart_204',
			                  N'main_chart_205', N'main_chart_206', N'main_chart_211')
		   )
		   AND NOT EXISTS
		   (
			SELECT 1
			FROM dbo.SYS_fnGetFunctionListByUser(@UserGroupID, N'NEW') P
			WHERE P.FunctionID = TRY_CONVERT(INT, @FunctionID)
		   )
			THROW 51511, 'No permission to load employees for this HR chart.', 1;

		IF ISJSON(@FilterJson) = 0
		BEGIN
			RAISERROR('Invalid JSON',16,1)
			RETURN
		END

		DECLARE @EmpYears tID;
		DECLARE @EmpQuarters tID;
		DECLARE @EmpMonths tID;
		DECLARE @EmpCompanys tID;
		DECLARE @EmpLoaiChucDanhs tID;
		DECLARE @EmpLevel1s tID;
		DECLARE @EmpLevel2s tID;
		DECLARE @EmpLevel3s tID;
		DECLARE @EmpLevel4s tID;
		DECLARE @EmpLevel5s tID;
		DECLARE @EmpLevel6s tID;
		DECLARE @EmpLevel7s tID;
		DECLARE @EmpLevel8s tID;
		DECLARE @EmpLevel9s tID;
		DECLARE @EmpHLevel1s tID;
		DECLARE @EmpHLevel2s tID;
		DECLARE @EmpHLevel3s tID;
		DECLARE @EmpJobTitles tID;
		DECLARE @EmpCapBacNVs tID;
		DECLARE @EmpNhomNVs tID;
		DECLARE @EmpLoaiHinhNVs tID;
		DECLARE @EmpResolved TABLE (FilterType VARCHAR(10), Value INT);

		INSERT INTO @EmpYears SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'YEAR';
		INSERT INTO @EmpQuarters SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'QUARTER';
		INSERT INTO @EmpMonths SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'MONTH';
		INSERT INTO @EmpCompanys SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'COMPANY';
		INSERT INTO @EmpLoaiChucDanhs SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'LOAICHUCDANH';
		INSERT INTO @EmpLevel1s SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'LEVEL1';
		INSERT INTO @EmpLevel2s SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'LEVEL2';
		INSERT INTO @EmpLevel3s SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'LEVEL3';
		INSERT INTO @EmpLevel4s SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'LEVEL4';
		INSERT INTO @EmpLevel5s SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'LEVEL5';
		INSERT INTO @EmpLevel6s SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'LEVEL6';
		INSERT INTO @EmpLevel7s SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'LEVEL7';
		INSERT INTO @EmpLevel8s SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'LEVEL8';
		INSERT INTO @EmpLevel9s SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'LEVEL9';
		INSERT INTO @EmpHLevel1s SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'HLEVEL1';
		INSERT INTO @EmpHLevel2s SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'HLEVEL2';
		INSERT INTO @EmpHLevel3s SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'HLEVEL3';
		INSERT INTO @EmpJobTitles SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'JOBTITLE';
		INSERT INTO @EmpCapBacNVs SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'CAPBACNV';
		INSERT INTO @EmpNhomNVs SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'NHOMNV';
		INSERT INTO @EmpLoaiHinhNVs SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'LOAIHINHNV';

		IF NOT EXISTS (SELECT 1 FROM @EmpYears)
		BEGIN
			INSERT INTO @EmpYears(ID) VALUES (YEAR(@dDate));
		END

		INSERT INTO @EmpResolved
		SELECT * FROM dbo.NEW_fnTableResolveTimeFilter(@EmpYears,@EmpQuarters,@EmpMonths);

		DELETE FROM @EmpMonths;
		INSERT INTO @EmpMonths
		SELECT Value FROM @EmpResolved WHERE FilterType = 'MONTH';

		DECLARE @TLGHasOrgFilter BIT = CASE WHEN
			   EXISTS (SELECT 1 FROM @EmpCompanys) OR EXISTS (SELECT 1 FROM @EmpLoaiChucDanhs)
			OR EXISTS (SELECT 1 FROM @EmpLevel1s) OR EXISTS (SELECT 1 FROM @EmpLevel2s)
			OR EXISTS (SELECT 1 FROM @EmpLevel3s) OR EXISTS (SELECT 1 FROM @EmpLevel4s)
			OR EXISTS (SELECT 1 FROM @EmpLevel5s) OR EXISTS (SELECT 1 FROM @EmpLevel6s)
			OR EXISTS (SELECT 1 FROM @EmpLevel7s) OR EXISTS (SELECT 1 FROM @EmpLevel8s)
			OR EXISTS (SELECT 1 FROM @EmpLevel9s) OR EXISTS (SELECT 1 FROM @EmpHLevel1s)
			OR EXISTS (SELECT 1 FROM @EmpHLevel2s) OR EXISTS (SELECT 1 FROM @EmpHLevel3s)
			OR EXISTS (SELECT 1 FROM @EmpJobTitles) OR EXISTS (SELECT 1 FROM @EmpCapBacNVs)
			OR EXISTS (SELECT 1 FROM @EmpNhomNVs) OR EXISTS (SELECT 1 FROM @EmpLoaiHinhNVs)
			THEN 1 ELSE 0 END;

		CREATE TABLE #EmpUniverse (EmpID INT NOT NULL);

		IF @TLGHasOrgFilter = 0
		BEGIN
			;WITH EmpPeriods AS
			(
				SELECT	ROW_NUMBER() OVER(ORDER BY GeneralName) AS RowID,
						COALESCE(TRY_CONVERT(DATETIME, NgayChotCongGanNhat, 103), TRY_CONVERT(DATETIME, LastDateTimeline, 103), @LastDateTimeLine) AS PeriodEnd
				FROM dbo.NEW_fnTableGenerateChuKyCong(@EmpYears,@EmpQuarters,@EmpMonths,@dDate)
			)
			INSERT INTO #EmpUniverse (EmpID)
			SELECT DISTINCT PQ.EmpID
			FROM EmpPeriods P
			CROSS APPLY dbo.fnGetAllEmp_Permission_EffDate(@UserGroupID, @FunctionID, P.PeriodEnd) PQ
			INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = PQ.EmpID
			WHERE P.PeriodEnd IS NOT NULL
			AND (E.StartDate IS NULL OR E.StartDate <= CONVERT(DATE, P.PeriodEnd));
		END
		ELSE
		BEGIN
			;WITH EmpPeriods AS
			(
				SELECT	ROW_NUMBER() OVER(ORDER BY GeneralName) AS RowID,
						COALESCE(TRY_CONVERT(DATETIME, NgayChotCongGanNhat, 103), TRY_CONVERT(DATETIME, LastDateTimeline, 103), @LastDateTimeLine) AS PeriodEnd
				FROM dbo.NEW_fnTableGenerateChuKyCong(@EmpYears,@EmpQuarters,@EmpMonths,@dDate)
			),
			CandidateEmployees AS
			(
				SELECT DISTINCT PQ.EmpID
				FROM EmpPeriods P
				CROSS APPLY dbo.fnGetAllEmp_Permission_EffDate(@UserGroupID, @FunctionID, P.PeriodEnd) PQ
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = PQ.EmpID
				CROSS APPLY
				(
					SELECT TOP 1 W.LSCompanyID, W.LSLevel1ID, W.LSLevel2ID, W.LSLevel3ID, W.LSLevel4ID,
						   W.LSLevel5ID, W.LSLevel6ID, W.LSLevel7ID, W.LSLevel8ID, W.LSLevel9ID,
						   W.LSHLevel1ID, W.LSHLevel2ID, W.LSHLevel3ID, W.LSJobTitleID,
						   W.LSCapBacNhanVienID, W.LSNhomNhanVienID, W.LSLoaiHinhNhanVienID
					FROM dbo.HR_tblWorkingRecord W (NOLOCK)
					WHERE W.EmpID = PQ.EmpID AND W.FromDate <= CONVERT(DATE, P.PeriodEnd)
					ORDER BY W.FromDate DESC, W.WorkingRecordID DESC
				) WR
				WHERE P.PeriodEnd IS NOT NULL
				AND (E.StartDate IS NULL OR E.StartDate <= CONVERT(DATE, P.PeriodEnd))
				AND (NOT EXISTS (SELECT 1 FROM @EmpCompanys) OR WR.LSCompanyID IN (SELECT ID FROM @EmpCompanys))
				AND (NOT EXISTS (SELECT 1 FROM @EmpLoaiChucDanhs) OR EXISTS
					(
						SELECT 1 FROM dbo.LS_tbljobtitle (NOLOCK) J
						WHERE J.LSJobTitleID = WR.LSJobTitleID
						AND TRY_CONVERT(BIGINT, J.LSLoaiChucDanhID) IN (SELECT ID FROM @EmpLoaiChucDanhs)
					))
				AND (NOT EXISTS (SELECT 1 FROM @EmpLevel1s) OR WR.LSLevel1ID IN (SELECT ID FROM @EmpLevel1s))
				AND (NOT EXISTS (SELECT 1 FROM @EmpLevel2s) OR WR.LSLevel2ID IN (SELECT ID FROM @EmpLevel2s))
				AND (NOT EXISTS (SELECT 1 FROM @EmpLevel3s) OR WR.LSLevel3ID IN (SELECT ID FROM @EmpLevel3s))
				AND (NOT EXISTS (SELECT 1 FROM @EmpLevel4s) OR WR.LSLevel4ID IN (SELECT ID FROM @EmpLevel4s))
				AND (NOT EXISTS (SELECT 1 FROM @EmpLevel5s) OR WR.LSLevel5ID IN (SELECT ID FROM @EmpLevel5s))
				AND (NOT EXISTS (SELECT 1 FROM @EmpLevel6s) OR WR.LSLevel6ID IN (SELECT ID FROM @EmpLevel6s))
				AND (NOT EXISTS (SELECT 1 FROM @EmpLevel7s) OR WR.LSLevel7ID IN (SELECT ID FROM @EmpLevel7s))
				AND (NOT EXISTS (SELECT 1 FROM @EmpLevel8s) OR WR.LSLevel8ID IN (SELECT ID FROM @EmpLevel8s))
				AND (NOT EXISTS (SELECT 1 FROM @EmpLevel9s) OR WR.LSLevel9ID IN (SELECT ID FROM @EmpLevel9s))
				AND (NOT EXISTS (SELECT 1 FROM @EmpHLevel1s) OR WR.LSHLevel1ID IN (SELECT ID FROM @EmpHLevel1s))
				AND (NOT EXISTS (SELECT 1 FROM @EmpHLevel2s) OR WR.LSHLevel2ID IN (SELECT ID FROM @EmpHLevel2s))
				AND (NOT EXISTS (SELECT 1 FROM @EmpHLevel3s) OR WR.LSHLevel3ID IN (SELECT ID FROM @EmpHLevel3s))
				AND (NOT EXISTS (SELECT 1 FROM @EmpJobTitles) OR WR.LSJobTitleID IN (SELECT ID FROM @EmpJobTitles))
				AND (NOT EXISTS (SELECT 1 FROM @EmpCapBacNVs) OR WR.LSCapBacNhanVienID IN (SELECT ID FROM @EmpCapBacNVs))
				AND (NOT EXISTS (SELECT 1 FROM @EmpNhomNVs) OR WR.LSNhomNhanVienID IN (SELECT ID FROM @EmpNhomNVs))
				AND (NOT EXISTS (SELECT 1 FROM @EmpLoaiHinhNVs) OR WR.LSLoaiHinhNhanVienID IN (SELECT ID FROM @EmpLoaiHinhNVs))
			)
			INSERT INTO #EmpUniverse (EmpID)
			SELECT EmpID
			FROM CandidateEmployees;
		END

		IF @EmployeeCacheKey IS NOT NULL
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM dbo.NEW_tblDashboardEmpCache
						   WHERE UserGroupID = @UserGroupID AND FunctionID = @FunctionID AND CacheKey = @EmployeeCacheKey)
			BEGIN
				INSERT INTO dbo.NEW_tblDashboardEmpCache (UserGroupID, FunctionID, CacheKey, EmpID)
				SELECT @UserGroupID, @FunctionID, @EmployeeCacheKey, EmpID
				FROM #EmpUniverse;
			END

			DELETE FROM dbo.NEW_tblDashboardEmpCache
			WHERE UserGroupID = @UserGroupID AND FunctionID = @FunctionID
			AND CacheKey <> @EmployeeCacheKey
			AND CreateTime < DATEADD(SECOND, -30, GETDATE());

			-- ③ Don rac TTL theo ME NHO (co index CreateTime, khong scan, khong giu khoa lau)
			DELETE TOP (5000) FROM dbo.NEW_tblDashboardEmpCache
			WHERE CreateTime < DATEADD(HOUR, -8, GETDATE());

			-- Chi tra ve so luong (danh sach nam lai trong DB)
			SELECT COUNT(1) AS EmpCount
			FROM dbo.NEW_tblDashboardEmpCache
			WHERE UserGroupID = @UserGroupID AND FunctionID = @FunctionID AND CacheKey = @EmployeeCacheKey;
		END
		ELSE
		BEGIN
			SELECT EmpID FROM #EmpUniverse ORDER BY EmpID;
		END
	END
	ELSE IF @Activity = 'GetChartData'
	BEGIN
		IF ISJSON(@FilterJson) = 0
		BEGIN
			RAISERROR('Invalid JSON',16,1)
			RETURN
		END

		DECLARE @RequiredHRChartFID INT;
		SELECT @RequiredHRChartFID = C.FunctionID
		FROM dbo.LS_tblDashboardCatalogV2 C
		WHERE C.ChartID = @ChartID AND C.IsNewV2 = 1
		  AND C.ChartID IN (N'index_card_207', N'index_card_208', N'index_card_209', N'index_card_210',
		                    N'main_chart_201', N'main_chart_202', N'main_chart_203', N'main_chart_204',
		                    N'main_chart_205', N'main_chart_206', N'main_chart_211');

		IF @RequiredHRChartFID IS NOT NULL
		BEGIN
			IF ISNULL(TRY_CONVERT(INT, @FunctionID), -1) <> @RequiredHRChartFID
				THROW 51512, 'HR chart request used the wrong permission FID.', 1;
			IF NOT EXISTS
			(
				SELECT 1
				FROM dbo.SYS_fnGetFunctionListByUser(@UserGroupID, N'NEW') P
				WHERE P.FunctionID = @RequiredHRChartFID
			)
				THROW 51513, 'No permission to load this HR chart.', 1;
		END

		DECLARE @Years tID;
		DECLARE @Quarters tID;
		DECLARE @Months tID;
		DECLARE @Companys tID;
		DECLARE @LoaiChucDanhs tID;
		DECLARE @JobTitles tID;
		DECLARE @CapBacNVs tID;
		DECLARE @Level1s tID;
		DECLARE @Level2s tID;
		DECLARE @Level3s tID;
		DECLARE @Level4s tID;
		DECLARE @Level5s tID;
		DECLARE @Level6s tID;
		DECLARE @Level7s tID;
		DECLARE @Level8s tID;
		DECLARE @Level9s tID;
		DECLARE @HLevel1s tID;
		DECLARE @Employees tID;

		/* Parse JSON */
		INSERT INTO @Years SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'YEAR';
		INSERT INTO @Quarters SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'QUARTER';
		INSERT INTO @Months SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'MONTH';
		INSERT INTO @Companys SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'COMPANY';
		INSERT INTO @LoaiChucDanhs SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'LOAICHUCDANH';
		INSERT INTO @JobTitles SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'JOBTITLE';
		INSERT INTO @CapBacNVs SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'CAPBACNV';
		INSERT INTO @Level1s SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'LEVEL1';
		INSERT INTO @Level2s SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'LEVEL2';
		INSERT INTO @Level3s SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'LEVEL3';
		INSERT INTO @Level4s SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'LEVEL4';
		INSERT INTO @Level5s SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'LEVEL5';
		INSERT INTO @Level6s SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'LEVEL6';
		INSERT INTO @Level7s SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'LEVEL7';
		INSERT INTO @Level8s SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'LEVEL8';
		INSERT INTO @Level9s SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'LEVEL9';
		INSERT INTO @HLevel1s SELECT FilterValue FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'HLEVEL1';

		INSERT INTO @Employees(ID)
		SELECT DISTINCT TRY_CONVERT(BIGINT, value)
		FROM STRING_SPLIT(ISNULL(@EmployeeIDs, ''), ',')
		WHERE TRY_CONVERT(BIGINT, value) IS NOT NULL
		AND LTRIM(RTRIM(value)) <> '';

		IF NOT EXISTS (SELECT 1 FROM @Employees WHERE ID > 0) AND @EmployeeCacheKey IS NOT NULL
		BEGIN
			INSERT INTO @Employees (ID)
			SELECT EmpID
			FROM dbo.NEW_tblDashboardEmpCache (NOLOCK)
			WHERE UserGroupID = @UserGroupID AND FunctionID = @FunctionID AND CacheKey = @EmployeeCacheKey;
		END

		DELETE Emp
		FROM @Employees Emp
		WHERE EXISTS (SELECT 1 FROM @LoaiChucDanhs)
		AND NOT EXISTS
		(
			SELECT 1
			FROM dbo.HR_tblEmp (NOLOCK) E
			INNER JOIN dbo.HR_vEmp (NOLOCK) vE ON vE.EmpID = E.EmpID
			INNER JOIN dbo.LS_tbljobtitle (NOLOCK) J ON J.LSJobTitleID = vE.LSJobTitleID
			WHERE E.EmpID = Emp.ID
			AND TRY_CONVERT(BIGINT, J.LSLoaiChucDanhID) IN (SELECT ID FROM @LoaiChucDanhs)
		);

		DECLARE @tblChartChuKyCong TABLE
		(
			RowID INT,
			GeneralName NVARCHAR(50),
			Years INT,
			Months INT NULL,
			Quarters INT NULL,
			MonthYear NVARCHAR(7) NULL,
			FirstDateTimeline NVARCHAR(12) NULL,
			LastDateTimeline NVARCHAR(12) NULL,
			NgayChotCongGanNhat NVARCHAR(12) NULL,
			FirstDateTimeLineDate DATETIME NULL,
			LastDateTimeLineDate DATETIME NULL,
			NgayChotCongGanNhatDate DATETIME NULL,
			MonthStart INT NULL,
			MonthEnd INT NULL
		);

		IF ISJSON(ISNULL(@ChuKyCongJson, N'')) = 1
		BEGIN
			INSERT INTO @tblChartChuKyCong
			(
				RowID, GeneralName, Years, Months, Quarters, MonthYear,
				FirstDateTimeline, LastDateTimeline, NgayChotCongGanNhat,
				FirstDateTimeLineDate, LastDateTimeLineDate, NgayChotCongGanNhatDate,
				MonthStart, MonthEnd
			)
			SELECT RowID, GeneralName, Years, Months, Quarters, MonthYear,
				   FirstDateTimeline, LastDateTimeline, NgayChotCongGanNhat,
				   FirstDateTimeLineDate, LastDateTimeLineDate, NgayChotCongGanNhatDate,
				   MonthStart, MonthEnd
			FROM OPENJSON(@ChuKyCongJson)
			WITH
			(
				RowID INT '$.RowID',
				GeneralName NVARCHAR(50) '$.GeneralName',
				Years INT '$.Years',
				Months INT '$.Months',
				Quarters INT '$.Quarters',
				MonthYear NVARCHAR(7) '$.MonthYear',
				FirstDateTimeline NVARCHAR(12) '$.FirstDateTimeline',
				LastDateTimeline NVARCHAR(12) '$.LastDateTimeline',
				NgayChotCongGanNhat NVARCHAR(12) '$.NgayChotCongGanNhat',
				FirstDateTimeLineDate DATETIME '$.FirstDateTimeLineDate',
				LastDateTimeLineDate DATETIME '$.LastDateTimeLineDate',
				NgayChotCongGanNhatDate DATETIME '$.NgayChotCongGanNhatDate',
				MonthStart INT '$.MonthStart',
				MonthEnd INT '$.MonthEnd'
			);
		END

		DECLARE @ChartNgayChotCongGanNhat DATETIME = @NgayChotCongGanNhat;
		DECLARE @ChartFirstDateTimeLine DATETIME = @FirstDateTimeLine;
		DECLARE @ChartLastDateTimeLine DATETIME = @LastDateTimeLine;

		IF @ChartNgayChotCongGanNhat IS NULL
			SELECT @ChartNgayChotCongGanNhat = MAX(NgayChotCongGanNhatDate) FROM @tblChartChuKyCong;
		IF @ChartFirstDateTimeLine IS NULL
			SELECT @ChartFirstDateTimeLine = MIN(FirstDateTimeLineDate) FROM @tblChartChuKyCong;
		IF @ChartLastDateTimeLine IS NULL
			SELECT @ChartLastDateTimeLine = MAX(LastDateTimeLineDate) FROM @tblChartChuKyCong;

		--SELECT * FROM @Employees
		--SELECT * FROM @tblChartChuKyCong

		IF @ChartID IN ('main_chart_103', 'main_chart_104', 'main_chart_105', 'main_chart_106')
		BEGIN
			DECLARE @SalaryPeriods TABLE
			(
				RowID INT IDENTITY(1,1),
				Years INT NOT NULL,
				Months INT NOT NULL,
				PeriodEnd DATE NOT NULL,
				TableSuffix CHAR(6) NOT NULL
			);
			DECLARE @SalaryYrTmp tID;
			DECLARE @SalaryQtrTmp tID;
			DECLARE @SalaryMoTmp tID;
			DECLARE @SalaryRes TABLE (FilterType VARCHAR(10), Value INT);

			INSERT INTO @SalaryPeriods (Years, Months, PeriodEnd, TableSuffix)
			SELECT DISTINCT Years,
				   Months,
				   CONVERT(DATE, COALESCE(NgayChotCongGanNhatDate, LastDateTimeLineDate, EOMONTH(DATEFROMPARTS(Years, Months, 1)))),
				   RIGHT('0' + CONVERT(VARCHAR(2), Months), 2) + CONVERT(CHAR(4), Years)
			FROM @tblChartChuKyCong
			WHERE Years IS NOT NULL AND Months IS NOT NULL;

			IF NOT EXISTS (SELECT 1 FROM @SalaryPeriods)
			BEGIN
				INSERT INTO @SalaryYrTmp SELECT ID FROM @Years;
				IF NOT EXISTS (SELECT 1 FROM @SalaryYrTmp) INSERT INTO @SalaryYrTmp(ID) VALUES (YEAR(@dDate));
				INSERT INTO @SalaryQtrTmp SELECT ID FROM @Quarters;
				INSERT INTO @SalaryMoTmp SELECT ID FROM @Months;

				INSERT INTO @SalaryRes
				SELECT * FROM dbo.NEW_fnTableResolveTimeFilter(@SalaryYrTmp, @SalaryQtrTmp, @SalaryMoTmp);

				DELETE FROM @SalaryMoTmp;
				INSERT INTO @SalaryMoTmp
				SELECT DISTINCT Value FROM @SalaryRes WHERE FilterType = 'MONTH';

				INSERT INTO @SalaryPeriods (Years, Months, PeriodEnd, TableSuffix)
				SELECT DISTINCT Y.ID,
					   M.ID,
					   EOMONTH(DATEFROMPARTS(Y.ID, M.ID, 1)),
					   RIGHT('0' + CONVERT(VARCHAR(2), M.ID), 2) + CONVERT(CHAR(4), Y.ID)
				FROM @SalaryYrTmp Y
				CROSS JOIN @SalaryMoTmp M
				WHERE Y.ID IS NOT NULL AND M.ID BETWEEN 1 AND 12;
			END

			IF OBJECT_ID('tempdb..#EmployeeSalary') IS NOT NULL DROP TABLE #EmployeeSalary;
			CREATE TABLE #EmployeeSalary
			(
				EmpID BIGINT NOT NULL,
				Years INT NOT NULL,
				Months INT NOT NULL,
				TableSuffix CHAR(6) NOT NULL,
				TK_CongTy_Code NVARCHAR(510) NULL,
				TK_DonViCap1 NVARCHAR(1000) NULL,
				TK_DonViCap1_Code NVARCHAR(510) NULL,
				TK_DonViCap2 NVARCHAR(1000) NULL,
				TK_DonViCap2_Code NVARCHAR(510) NULL,
				TK_DonViCap3 NVARCHAR(1000) NULL,
				TK_DonViCap3_Code NVARCHAR(510) NULL,
				TK_DonViCap4 NVARCHAR(1000) NULL,
				TK_DonViCap4_Code NVARCHAR(510) NULL,
				TK_DonViCap5 NVARCHAR(1000) NULL,
				TK_DonViCap5_Code NVARCHAR(510) NULL,
				TK_DonViCap6 NVARCHAR(1000) NULL,
				TK_DonViCap6_Code NVARCHAR(510) NULL,
				TK_ViTriCongViecCode_New NVARCHAR(50) NULL,
				TK_ViTriCongViec_New NVARCHAR(500) NULL
			);

			DECLARE @SalaryLoop INT = 1;
			DECLARE @SalaryLoopCount INT = (SELECT COUNT(1) FROM @SalaryPeriods);
			DECLARE @SalaryYears INT;
			DECLARE @SalaryMonths INT;
			DECLARE @SalaryPeriodEnd DATE;
			DECLARE @SalarySuffix CHAR(6);
			DECLARE @SalaryPitTextTable SYSNAME;
			DECLARE @SalarySQL NVARCHAR(MAX);

			WHILE @SalaryLoop <= @SalaryLoopCount
			BEGIN
				SELECT @SalaryYears = Years,
					   @SalaryMonths = Months,
					   @SalaryPeriodEnd = PeriodEnd,
					   @SalarySuffix = TableSuffix
				FROM @SalaryPeriods
				WHERE RowID = @SalaryLoop;

				SET @SalaryPitTextTable = N'PIT_vPITMonthText_' + @SalarySuffix + N'_0';

				IF OBJECT_ID(N'dbo.' + @SalaryPitTextTable) IS NOT NULL
				AND COL_LENGTH(N'dbo.' + @SalaryPitTextTable, 'TK_CongTy_Code') IS NOT NULL
				AND COL_LENGTH(N'dbo.' + @SalaryPitTextTable, 'TK_DonViCap1') IS NOT NULL
				AND COL_LENGTH(N'dbo.' + @SalaryPitTextTable, 'TK_DonViCap1_Code') IS NOT NULL
				AND COL_LENGTH(N'dbo.' + @SalaryPitTextTable, 'TK_DonViCap2') IS NOT NULL
				AND COL_LENGTH(N'dbo.' + @SalaryPitTextTable, 'TK_DonViCap2_Code') IS NOT NULL
				AND COL_LENGTH(N'dbo.' + @SalaryPitTextTable, 'TK_DonViCap3') IS NOT NULL
				AND COL_LENGTH(N'dbo.' + @SalaryPitTextTable, 'TK_DonViCap3_Code') IS NOT NULL
				AND COL_LENGTH(N'dbo.' + @SalaryPitTextTable, 'TK_DonViCap4') IS NOT NULL
				AND COL_LENGTH(N'dbo.' + @SalaryPitTextTable, 'TK_DonViCap4_Code') IS NOT NULL
				AND COL_LENGTH(N'dbo.' + @SalaryPitTextTable, 'TK_DonViCap5') IS NOT NULL
				AND COL_LENGTH(N'dbo.' + @SalaryPitTextTable, 'TK_DonViCap5_Code') IS NOT NULL
				AND COL_LENGTH(N'dbo.' + @SalaryPitTextTable, 'TK_DonViCap6') IS NOT NULL
				AND COL_LENGTH(N'dbo.' + @SalaryPitTextTable, 'TK_DonViCap6_Code') IS NOT NULL
				AND COL_LENGTH(N'dbo.' + @SalaryPitTextTable, 'TK_ViTriCongViecCode_New') IS NOT NULL
				AND COL_LENGTH(N'dbo.' + @SalaryPitTextTable, 'TK_ViTriCongViec_New') IS NOT NULL
				BEGIN
					SET @SalarySQL = N'
						;WITH PITTextRaw AS
						(
							SELECT TRY_CONVERT(BIGINT, TXT.EmpID) AS EmpID,
								   TXT.TK_CongTy_Code,
								   TXT.TK_DonViCap1, TXT.TK_DonViCap1_Code,
								   TXT.TK_DonViCap2, TXT.TK_DonViCap2_Code,
								   TXT.TK_DonViCap3, TXT.TK_DonViCap3_Code,
								   TXT.TK_DonViCap4, TXT.TK_DonViCap4_Code,
								   TXT.TK_DonViCap5, TXT.TK_DonViCap5_Code,
								   TXT.TK_DonViCap6, TXT.TK_DonViCap6_Code,
								   TXT.TK_ViTriCongViecCode_New, TXT.TK_ViTriCongViec_New
							FROM dbo.' + QUOTENAME(@SalaryPitTextTable) + N' (NOLOCK) TXT
							WHERE TRY_CONVERT(BIGINT, TXT.EmpID) IS NOT NULL
						),
						PITText AS
						(
							SELECT *,
								   ROW_NUMBER() OVER
								   (
									   PARTITION BY EmpID
									   ORDER BY EmpID
								   ) AS rn
							FROM PITTextRaw TXT
							WHERE EXISTS
							(
								SELECT 1
								FROM dbo.fnGetAllEmp_Permission_EffDate(@UserGroupID, @FunctionID, @PeriodEnd) PQ
								WHERE PQ.EmpID = TXT.EmpID
							)
							AND (NOT EXISTS (SELECT 1 FROM @Companys) OR EXISTS
								(
									SELECT 1
									FROM dbo.LS_tblCompany (NOLOCK) CO
									WHERE CO.LSCompanyCode = TXT.TK_CongTy_Code
									AND CO.LSCompanyID IN (SELECT ID FROM @Companys)
								))
							AND (NOT EXISTS (SELECT 1 FROM @Level1s) OR EXISTS
								(
									SELECT 1
									FROM dbo.LS_tblLevel1 (NOLOCK) L1
									WHERE L1.LSLevel1Code = TXT.TK_DonViCap1_Code
									AND L1.LSLevel1ID IN (SELECT ID FROM @Level1s)
								))
							AND (NOT EXISTS (SELECT 1 FROM @Level2s) OR EXISTS
								(
									SELECT 1
									FROM dbo.LS_tblLevel2 (NOLOCK) L2
									WHERE L2.LSLevel2Code = TXT.TK_DonViCap2_Code
									AND L2.LSLevel2ID IN (SELECT ID FROM @Level2s)
								))
							AND (NOT EXISTS (SELECT 1 FROM @Level3s) OR EXISTS
								(
									SELECT 1
									FROM dbo.LS_tblLevel3 (NOLOCK) L3
									WHERE L3.LSLevel3Code = TXT.TK_DonViCap3_Code
									AND L3.LSLevel3ID IN (SELECT ID FROM @Level3s)
								))
							AND (NOT EXISTS (SELECT 1 FROM @Level4s) OR EXISTS
								(
									SELECT 1
									FROM dbo.LS_tblLevel4 (NOLOCK) L4
									WHERE L4.LSLevel4Code = TXT.TK_DonViCap4_Code
									AND L4.LSLevel4ID IN (SELECT ID FROM @Level4s)
								))
							AND (NOT EXISTS (SELECT 1 FROM @Level5s) OR EXISTS
								(
									SELECT 1
									FROM dbo.LS_tblLevel5 (NOLOCK) L5
									WHERE L5.LSLevel5Code = TXT.TK_DonViCap5_Code
									AND L5.LSLevel5ID IN (SELECT ID FROM @Level5s)
								))
							AND (NOT EXISTS (SELECT 1 FROM @Level6s) OR EXISTS
								(
									SELECT 1
									FROM dbo.LS_tblLevel6 (NOLOCK) L6
									WHERE L6.LSLevel6Code = TXT.TK_DonViCap6_Code
									AND L6.LSLevel6ID IN (SELECT ID FROM @Level6s)
								))
						)
						INSERT INTO #EmployeeSalary
						(
							EmpID, Years, Months, TableSuffix,
							TK_CongTy_Code,
							TK_DonViCap1, TK_DonViCap1_Code,
							TK_DonViCap2, TK_DonViCap2_Code,
							TK_DonViCap3, TK_DonViCap3_Code,
							TK_DonViCap4, TK_DonViCap4_Code,
							TK_DonViCap5, TK_DonViCap5_Code,
							TK_DonViCap6, TK_DonViCap6_Code,
							TK_ViTriCongViecCode_New, TK_ViTriCongViec_New
						)
						SELECT TXT.EmpID, @Years, @Months, @TableSuffix,
							   TXT.TK_CongTy_Code,
							   TXT.TK_DonViCap1, TXT.TK_DonViCap1_Code,
							   TXT.TK_DonViCap2, TXT.TK_DonViCap2_Code,
							   TXT.TK_DonViCap3, TXT.TK_DonViCap3_Code,
							   TXT.TK_DonViCap4, TXT.TK_DonViCap4_Code,
							   TXT.TK_DonViCap5, TXT.TK_DonViCap5_Code,
							   TXT.TK_DonViCap6, TXT.TK_DonViCap6_Code,
							   TXT.TK_ViTriCongViecCode_New, TXT.TK_ViTriCongViec_New
						FROM PITText TXT
						WHERE TXT.rn = 1
						AND NOT EXISTS
						(
							SELECT 1
							FROM #EmployeeSalary ES
							WHERE ES.TableSuffix = @TableSuffix
							AND ES.EmpID = TXT.EmpID
						);';

					EXEC sp_executesql @SalarySQL,
						N'@Years INT, @Months INT, @TableSuffix CHAR(6), @PeriodEnd DATE, @UserGroupID VARCHAR(50), @FunctionID VARCHAR(50), @Companys tID READONLY, @Level1s tID READONLY, @Level2s tID READONLY, @Level3s tID READONLY, @Level4s tID READONLY, @Level5s tID READONLY, @Level6s tID READONLY',
						@Years=@SalaryYears, @Months=@SalaryMonths, @TableSuffix=@SalarySuffix, @PeriodEnd=@SalaryPeriodEnd,
						@UserGroupID=@UserGroupID, @FunctionID=@FunctionID,
						@Companys=@Companys, @Level1s=@Level1s, @Level2s=@Level2s, @Level3s=@Level3s, @Level4s=@Level4s, @Level5s=@Level5s, @Level6s=@Level6s;
				END

				SET @SalaryLoop = @SalaryLoop + 1;
			END

			;WITH DuplicateEmployeeSalary AS
			(
				SELECT *,
					   ROW_NUMBER() OVER
					   (
						   PARTITION BY TableSuffix, EmpID
						   ORDER BY Years, Months
					   ) AS rn
				FROM #EmployeeSalary
			)
			DELETE FROM DuplicateEmployeeSalary
			WHERE rn > 1;

			CREATE UNIQUE INDEX IX_EmployeeSalary_PeriodEmp ON #EmployeeSalary (TableSuffix, EmpID);
		END

		IF (@ChartID IN ('index_card_28', 'index_card_29', 'index_card_30'))
		BEGIN
			DECLARE @IndexSummaryDate DATE = @dDate;
			DECLARE @IndexFirstDateOfYear DATE = DATEFROMPARTS(YEAR(@dDate), 1, 1);
			DECLARE @PresentEmployeeCount INT = 0;
			DECLARE @TerminatedEmployeeCount INT = 0;
			DECLARE @NewHireEmployeeCount INT = 0;
			DECLARE @TurnoverRate DECIMAL(18, 2) = 0;

			;WITH PresentEmployees AS
			(
				SELECT DISTINCT E.EmpID
				FROM dbo.fnGetAllEmp_Permission_EffDate(@UserGroupID, @FunctionID, @IndexSummaryDate) P
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = P.EmpID
				WHERE (E.StartDate IS NULL OR CONVERT(DATE, E.StartDate) <= @IndexSummaryDate)
				AND (NOT EXISTS (SELECT 1 FROM @Companys) OR E.LSCompanyID IN (SELECT ID FROM @Companys))
				AND (NOT EXISTS (SELECT 1 FROM @LoaiChucDanhs) OR E.LSLoaiChucDanhID IN (SELECT ID FROM @LoaiChucDanhs))
				AND (NOT EXISTS (SELECT 1 FROM @Level1s) OR E.LSLevel1ID IN (SELECT ID FROM @Level1s))
				AND (NOT EXISTS (SELECT 1 FROM @Level2s) OR E.LSLevel2ID IN (SELECT ID FROM @Level2s))
				AND (NOT EXISTS (SELECT 1 FROM @Level3s) OR E.LSLevel3ID IN (SELECT ID FROM @Level3s))
				AND (NOT EXISTS (SELECT 1 FROM @Level4s) OR E.LSLevel4ID IN (SELECT ID FROM @Level4s))
				AND (NOT EXISTS (SELECT 1 FROM @Level5s) OR E.LSLevel5ID IN (SELECT ID FROM @Level5s))
				AND (NOT EXISTS (SELECT 1 FROM @Level6s) OR E.LSLevel6ID IN (SELECT ID FROM @Level6s))
				AND (NOT EXISTS (SELECT 1 FROM @Level7s) OR E.LSLevel7ID IN (SELECT ID FROM @Level7s))
				AND (NOT EXISTS (SELECT 1 FROM @Level8s) OR E.LSLevel8ID IN (SELECT ID FROM @Level8s))
				AND (NOT EXISTS (SELECT 1 FROM @Level9s) OR E.LSLevel9ID IN (SELECT ID FROM @Level9s))
				AND NOT EXISTS
				(
					SELECT 1
					FROM dbo.TER_tblTermination (NOLOCK) TER
					WHERE TER.EmpID = E.EmpID
					AND TER.EffectDate IS NOT NULL
					AND CONVERT(DATE, TER.EffectDate) <= @IndexSummaryDate
				)
			),
			TerminatedEmployees AS
			(
				SELECT DISTINCT TER.EmpID
				FROM dbo.TER_tblTermination (NOLOCK) TER
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = TER.EmpID
				WHERE TER.EffectDate IS NOT NULL
				AND CONVERT(DATE, TER.EffectDate) BETWEEN @IndexFirstDateOfYear AND @IndexSummaryDate
				AND (NOT EXISTS (SELECT 1 FROM @Companys) OR E.LSCompanyID IN (SELECT ID FROM @Companys))
				AND (NOT EXISTS (SELECT 1 FROM @LoaiChucDanhs) OR E.LSLoaiChucDanhID IN (SELECT ID FROM @LoaiChucDanhs))
				AND (NOT EXISTS (SELECT 1 FROM @Level1s) OR E.LSLevel1ID IN (SELECT ID FROM @Level1s))
				AND (NOT EXISTS (SELECT 1 FROM @Level2s) OR E.LSLevel2ID IN (SELECT ID FROM @Level2s))
				AND (NOT EXISTS (SELECT 1 FROM @Level3s) OR E.LSLevel3ID IN (SELECT ID FROM @Level3s))
				AND (NOT EXISTS (SELECT 1 FROM @Level4s) OR E.LSLevel4ID IN (SELECT ID FROM @Level4s))
				AND (NOT EXISTS (SELECT 1 FROM @Level5s) OR E.LSLevel5ID IN (SELECT ID FROM @Level5s))
				AND (NOT EXISTS (SELECT 1 FROM @Level6s) OR E.LSLevel6ID IN (SELECT ID FROM @Level6s))
				AND (NOT EXISTS (SELECT 1 FROM @Level7s) OR E.LSLevel7ID IN (SELECT ID FROM @Level7s))
				AND (NOT EXISTS (SELECT 1 FROM @Level8s) OR E.LSLevel8ID IN (SELECT ID FROM @Level8s))
				AND (NOT EXISTS (SELECT 1 FROM @Level9s) OR E.LSLevel9ID IN (SELECT ID FROM @Level9s))
				AND EXISTS
				(
					SELECT 1
					FROM dbo.fnGetAllEmp_Permission_EffDate(@UserGroupID, @FunctionID, CONVERT(DATE, TER.EffectDate)) P
					WHERE P.EmpID = TER.EmpID
				)
			),
			NewHireEmployees AS
			(
				SELECT DISTINCT E.EmpID
				FROM dbo.HR_tblEmp (NOLOCK) E
				WHERE E.StartDate IS NOT NULL
				AND CONVERT(DATE, E.StartDate) BETWEEN @IndexFirstDateOfYear AND @IndexSummaryDate
				AND (NOT EXISTS (SELECT 1 FROM @Companys) OR E.LSCompanyID IN (SELECT ID FROM @Companys))
				AND (NOT EXISTS (SELECT 1 FROM @LoaiChucDanhs) OR E.LSLoaiChucDanhID IN (SELECT ID FROM @LoaiChucDanhs))
				AND (NOT EXISTS (SELECT 1 FROM @Level1s) OR E.LSLevel1ID IN (SELECT ID FROM @Level1s))
				AND (NOT EXISTS (SELECT 1 FROM @Level2s) OR E.LSLevel2ID IN (SELECT ID FROM @Level2s))
				AND (NOT EXISTS (SELECT 1 FROM @Level3s) OR E.LSLevel3ID IN (SELECT ID FROM @Level3s))
				AND (NOT EXISTS (SELECT 1 FROM @Level4s) OR E.LSLevel4ID IN (SELECT ID FROM @Level4s))
				AND (NOT EXISTS (SELECT 1 FROM @Level5s) OR E.LSLevel5ID IN (SELECT ID FROM @Level5s))
				AND (NOT EXISTS (SELECT 1 FROM @Level6s) OR E.LSLevel6ID IN (SELECT ID FROM @Level6s))
				AND (NOT EXISTS (SELECT 1 FROM @Level7s) OR E.LSLevel7ID IN (SELECT ID FROM @Level7s))
				AND (NOT EXISTS (SELECT 1 FROM @Level8s) OR E.LSLevel8ID IN (SELECT ID FROM @Level8s))
				AND (NOT EXISTS (SELECT 1 FROM @Level9s) OR E.LSLevel9ID IN (SELECT ID FROM @Level9s))
				AND EXISTS
				(
					SELECT 1
					FROM dbo.fnGetAllEmp_Permission_EffDate(@UserGroupID, @FunctionID, CONVERT(DATE, E.StartDate)) P
					WHERE P.EmpID = E.EmpID
				)
			)
			SELECT	@PresentEmployeeCount = (SELECT COUNT(1) FROM PresentEmployees),
					@TerminatedEmployeeCount = (SELECT COUNT(1) FROM TerminatedEmployees),
					@NewHireEmployeeCount = (SELECT COUNT(1) FROM NewHireEmployees);

			SET @TurnoverRate = CASE
				WHEN (@PresentEmployeeCount + @TerminatedEmployeeCount) = 0 THEN 0
				ELSE CONVERT(DECIMAL(18, 2), @TerminatedEmployeeCount * 100.0 / (@PresentEmployeeCount + @TerminatedEmployeeCount))
			END;

			IF (@ChartID = 'index_card_28')
			BEGIN
				SELECT CONVERT(NVARCHAR(30), @PresentEmployeeCount) AS MainValue, NULL AS SubFirstValue, NULL AS SubSecondValue
			END
			ELSE IF (@ChartID = 'index_card_29')
			BEGIN
				SELECT CONVERT(NVARCHAR(30), @TurnoverRate) + N'%' AS MainValue, NULL AS SubFirstValue, NULL AS SubSecondValue
			END
			ELSE IF (@ChartID = 'index_card_30')
			BEGIN
				SELECT CONVERT(NVARCHAR(30), @NewHireEmployeeCount) AS MainValue, NULL AS SubFirstValue, NULL AS SubSecondValue
			END
		END
		ELSE IF (@ChartID IN ('main_chart_201', 'main_chart_202', 'main_chart_203', 'main_chart_204', 'main_chart_205', 'main_chart_206', 'main_chart_211',
							  'index_card_207', 'index_card_208', 'index_card_209', 'index_card_210'))
		BEGIN
			-- =====================================================================
			-- 33306RLOG TLG: DU LIEU THAT - tinh truc tiep tu bang goc theo spec
			-- View_HR_2.docx (user quyet dinh KHONG tao view DASH_v*, khong job).
			-- Ky bao cao = thang/nam tu bo loc; chua chon -> thang hien tai.
			-- index_card_207/208/209: 3 card TLG moi TINH THEO BO LOC (thay 3 card
			-- SHB 28/29/30 dinh cung "hom nay").
			-- =====================================================================
			DECLARE @TLGYear INT = ISNULL((SELECT MAX(ID) FROM @Years), YEAR(@dDate));
			-- Thang bao cao: uu tien MONTH; chi chon QUARTER -> thang cuoi quy;
			-- khong chon gi -> thang hien tai (nam qua khu -> thang 12).
			DECLARE @TLGMonth INT = COALESCE(
					(SELECT MAX(ID) FROM @Months),
					(SELECT MAX(ID) * 3 FROM @Quarters),
					CASE WHEN @TLGYear = YEAR(@dDate) THEN MONTH(@dDate) ELSE 12 END);
			DECLARE @TLGKyDau DATE = DATEFROMPARTS(@TLGYear, @TLGMonth, 1);
			DECLARE @TLGKyCuoi DATE = EOMONTH(DATEFROMPARTS(@TLGYear, @TLGMonth, 1));

			DECLARE @TLGRangeDau DATE = CASE
					WHEN EXISTS (SELECT 1 FROM @Months) THEN @TLGKyDau
					WHEN EXISTS (SELECT 1 FROM @Quarters) THEN DATEFROMPARTS(@TLGYear, ((SELECT MAX(ID) FROM @Quarters) - 1) * 3 + 1, 1)
					ELSE DATEFROMPARTS(@TLGYear, 1, 1) END;
			DECLARE @TLGRangeCuoi DATE = CASE
					WHEN EXISTS (SELECT 1 FROM @Months) THEN @TLGKyCuoi
					WHEN EXISTS (SELECT 1 FROM @Quarters) THEN EOMONTH(DATEFROMPARTS(@TLGYear, (SELECT MAX(ID) FROM @Quarters) * 3, 1))
					ELSE DATEFROMPARTS(@TLGYear, 12, 31) END;

			-- TLG multi-period: use disjoint months for event totals, not MIN..MAX.
			-- Snapshot cards keep the existing latest-period dates above.
			DECLARE @TLGSelectedPeriods TABLE
			(
				MonthID INT NOT NULL PRIMARY KEY,
				PeriodStart DATE NOT NULL,
				PeriodEndExclusive DATE NOT NULL
			);
			INSERT INTO @TLGSelectedPeriods (MonthID, PeriodStart, PeriodEndExclusive)
			SELECT M.ID, DATEFROMPARTS(@TLGYear, M.ID, 1),
				   DATEADD(MONTH, 1, DATEFROMPARTS(@TLGYear, M.ID, 1))
			FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12)) M(ID)
			WHERE (EXISTS (SELECT 1 FROM @Months) AND M.ID IN (SELECT ID FROM @Months))
			   OR (NOT EXISTS (SELECT 1 FROM @Months)
				   AND (NOT EXISTS (SELECT 1 FROM @Quarters)
					OR (M.ID - 1) / 3 + 1 IN (SELECT ID FROM @Quarters)));
			DECLARE @TLGMultipleSelections BIT = CASE WHEN
				(SELECT COUNT(DISTINCT ID) FROM @Months) > 1
				OR (NOT EXISTS (SELECT 1 FROM @Months) AND (SELECT COUNT(DISTINCT ID) FROM @Quarters) > 1)
				THEN 1 ELSE 0 END;
			DECLARE @TLGEventStartDate DATE = (SELECT MIN(PeriodStart) FROM @TLGSelectedPeriods);
			DECLARE @TLGEventEndExclusive DATE = (SELECT MAX(PeriodEndExclusive) FROM @TLGSelectedPeriods);

			IF NOT EXISTS (SELECT 1 FROM @Employees WHERE ID > 0)
			BEGIN
				DECLARE @TLGFallbackYears tID, @TLGFallbackMonths tID;
				INSERT INTO @TLGFallbackYears (ID) VALUES (@TLGYear);
				INSERT INTO @TLGFallbackMonths (ID) SELECT MonthID FROM @TLGSelectedPeriods;
				INSERT INTO @Employees (ID)
				SELECT DISTINCT PQ.EmpID
				FROM
				(
					SELECT COALESCE(TRY_CONVERT(DATETIME, NgayChotCongGanNhat, 103),
						   TRY_CONVERT(DATETIME, LastDateTimeline, 103), @LastDateTimeLine) AS PeriodEnd
					FROM dbo.NEW_fnTableGenerateChuKyCong(@TLGFallbackYears,@Quarters,@TLGFallbackMonths,@dDate)
					WHERE @TLGMultipleSelections = 1
					UNION
					SELECT @TLGKyCuoi WHERE @TLGMultipleSelections = 0
				) EP
				CROSS APPLY dbo.fnGetAllEmp_Permission_EffDate(@UserGroupID, @FunctionID, EP.PeriodEnd) PQ
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = PQ.EmpID
				OUTER APPLY
				(
					SELECT TOP 1 W.WorkingRecordID, W.LSCompanyID, W.LSLevel1ID, W.LSLevel2ID, W.LSLevel3ID, W.LSLevel4ID,
						   W.LSLevel5ID, W.LSLevel6ID, W.LSLevel7ID, W.LSLevel8ID, W.LSLevel9ID,
					   W.LSHLevel1ID, W.LSJobTitleID, W.LSCapBacNhanVienID
					FROM dbo.HR_tblWorkingRecord W (NOLOCK)
					WHERE W.EmpID = PQ.EmpID AND W.FromDate <= EP.PeriodEnd
					ORDER BY W.FromDate DESC, W.WorkingRecordID DESC
				) WR
				WHERE (E.StartDate IS NULL OR E.StartDate <= EP.PeriodEnd)
				AND (@TLGMultipleSelections = 1 OR WR.WorkingRecordID IS NOT NULL)
				AND (NOT EXISTS (SELECT 1 FROM @Companys) OR WR.LSCompanyID IN (SELECT ID FROM @Companys))
				AND (NOT EXISTS (SELECT 1 FROM @LoaiChucDanhs) OR EXISTS
					(
						SELECT 1 FROM dbo.LS_tbljobtitle (NOLOCK) J
						WHERE J.LSJobTitleID = WR.LSJobTitleID
						AND TRY_CONVERT(BIGINT, J.LSLoaiChucDanhID) IN (SELECT ID FROM @LoaiChucDanhs)
					))
				AND (NOT EXISTS (SELECT 1 FROM @JobTitles) OR WR.LSJobTitleID IN (SELECT ID FROM @JobTitles))
				AND (NOT EXISTS (SELECT 1 FROM @CapBacNVs) OR WR.LSCapBacNhanVienID IN (SELECT ID FROM @CapBacNVs))
				AND (NOT EXISTS (SELECT 1 FROM @Level1s) OR WR.LSLevel1ID IN (SELECT ID FROM @Level1s))
				AND (NOT EXISTS (SELECT 1 FROM @Level2s) OR WR.LSLevel2ID IN (SELECT ID FROM @Level2s))
				AND (NOT EXISTS (SELECT 1 FROM @Level3s) OR WR.LSLevel3ID IN (SELECT ID FROM @Level3s))
				AND (NOT EXISTS (SELECT 1 FROM @Level4s) OR WR.LSLevel4ID IN (SELECT ID FROM @Level4s))
				AND (NOT EXISTS (SELECT 1 FROM @Level5s) OR WR.LSLevel5ID IN (SELECT ID FROM @Level5s))
				AND (NOT EXISTS (SELECT 1 FROM @Level6s) OR WR.LSLevel6ID IN (SELECT ID FROM @Level6s))
				AND (NOT EXISTS (SELECT 1 FROM @Level7s) OR WR.LSLevel7ID IN (SELECT ID FROM @Level7s))
				AND (NOT EXISTS (SELECT 1 FROM @Level8s) OR WR.LSLevel8ID IN (SELECT ID FROM @Level8s))
				AND (NOT EXISTS (SELECT 1 FROM @Level9s) OR WR.LSLevel9ID IN (SELECT ID FROM @Level9s))
				AND (NOT EXISTS (SELECT 1 FROM @HLevel1s) OR WR.LSHLevel1ID IN (SELECT ID FROM @HLevel1s));
			END

			IF (@ChartID = 'main_chart_201')
			BEGIN
				;WITH Thang AS
				(
					SELECT MonthID AS T FROM @TLGSelectedPeriods
				)
				SELECT N'T' + RIGHT('0' + CONVERT(VARCHAR(2), Th.T), 2) + '/' + CONVERT(VARCHAR(4), @TLGYear) AS TimeLine,
					   ISNULL(TM.SoLuong, 0) AS SoTuyenMoi,
					   ISNULL(NGV.SoLuong, 0) AS SoNghiViec
				FROM Thang Th
				OUTER APPLY
				(
					SELECT COUNT(1) AS SoLuong
					FROM dbo.HR_tblEmp (NOLOCK) E
					INNER JOIN @Employees Emp ON Emp.ID = E.EmpID
					WHERE E.StartDate >= DATEFROMPARTS(@TLGYear, Th.T, 1)
					AND E.StartDate <= EOMONTH(DATEFROMPARTS(@TLGYear, Th.T, 1))
				) TM
				OUTER APPLY
				(
					SELECT COUNT(DISTINCT TER.EmpID) AS SoLuong
					FROM dbo.TER_tblTermination (NOLOCK) TER
					INNER JOIN @Employees Emp ON Emp.ID = TER.EmpID
					WHERE TER.EffectDate IS NOT NULL
					AND CONVERT(DATE, TER.EffectDate) >= DATEFROMPARTS(@TLGYear, Th.T, 1)
					AND CONVERT(DATE, TER.EffectDate) <= EOMONTH(DATEFROMPARTS(@TLGYear, Th.T, 1))
				) NGV
				ORDER BY Th.T;
			END
			ELSE IF (@ChartID = 'main_chart_202')
			BEGIN
				DECLARE @TLGGroupLevel TINYINT;
				SELECT @TLGGroupLevel =
					CASE
						WHEN EXISTS (SELECT 1 FROM @Level9s) THEN 9
						WHEN EXISTS (SELECT 1 FROM @Level8s) THEN 9
						WHEN EXISTS (SELECT 1 FROM @Level7s) THEN 8
						WHEN EXISTS (SELECT 1 FROM @Level6s) THEN 7
						WHEN EXISTS (SELECT 1 FROM @Level5s) THEN 6
						WHEN EXISTS (SELECT 1 FROM @Level4s) THEN 5
						WHEN EXISTS (SELECT 1 FROM @Level3s) THEN 4
						WHEN EXISTS (SELECT 1 FROM @Level2s) THEN 3
						WHEN EXISTS (SELECT 1 FROM @Level1s) THEN 2
						WHEN EXISTS (SELECT 1 FROM @Companys) THEN 1
						ELSE NULL
					END;

				SELECT Emp.ID AS EmpID,
					   ISNULL(SL.TongLuong, 0) + ISNULL(PC.PhuCap, 0) AS QuyLuong,
					   WR.LSCompanyID,
					   WR.LSLevel1ID, WR.LSLevel2ID, WR.LSLevel3ID,
					   WR.LSLevel4ID, WR.LSLevel5ID, WR.LSLevel6ID,
					   WR.LSLevel7ID, WR.LSLevel8ID, WR.LSLevel9ID
				INTO #TLGQuyLuong
				FROM @Employees Emp
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = Emp.ID
				CROSS APPLY
				(
					SELECT TOP 1 W.LSCompanyID,
						   W.LSLevel1ID, W.LSLevel2ID, W.LSLevel3ID,
						   W.LSLevel4ID, W.LSLevel5ID, W.LSLevel6ID,
						   W.LSLevel7ID, W.LSLevel8ID, W.LSLevel9ID
					FROM dbo.HR_tblWorkingRecord W (NOLOCK)
					WHERE W.EmpID = Emp.ID AND W.FromDate <= @TLGKyCuoi
					ORDER BY W.FromDate DESC, W.WorkingRecordID DESC
				) WR
				OUTER APPLY
				(
					SELECT TOP 1 CONVERT(FLOAT, dbo.sys_fnGetD(S.TongLuong)) AS TongLuong
					FROM dbo.PR_tblSalary S (NOLOCK)
					WHERE S.EmpID = Emp.ID AND S.FromDate <= @TLGKyCuoi
					ORDER BY S.FromDate DESC
				) SL
				OUTER APPLY
				(
					SELECT SUM(CONVERT(FLOAT, dbo.sys_fnGetD(A.Amount))) AS PhuCap
					FROM dbo.PR_tblAddSalaryEmp A (NOLOCK)
					INNER JOIN dbo.LS_tblAdd_Salary L (NOLOCK) ON L.LSAddSalaryID = A.LSAddSalaryID
					WHERE A.EmpID = Emp.ID
					AND L.LSAddSalaryGroupID = 1
					AND A.FromDate <= @TLGKyCuoi
					AND (A.ToDate IS NULL OR A.ToDate >= @TLGKyDau)
				) PC
				-- "dang lam viec" theo TER_tblTermination (dong bo voi index card + block 201)
				WHERE NOT EXISTS
				(
					SELECT 1 FROM dbo.TER_tblTermination (NOLOCK) TER
					WHERE TER.EmpID = Emp.ID
					AND TER.EffectDate IS NOT NULL
					AND CONVERT(DATE, TER.EffectDate) <= @TLGKyCuoi
				);

				IF @TLGGroupLevel IS NULL
				BEGIN
					DECLARE @TLGCompanyCount INT, @TLGLevel1Count INT, @TLGLevel2Count INT,
							@TLGLevel3Count INT, @TLGLevel4Count INT, @TLGLevel5Count INT,
							@TLGLevel6Count INT, @TLGLevel7Count INT, @TLGLevel8Count INT,
							@TLGLevel9Count INT;

					SELECT @TLGCompanyCount = COUNT(DISTINCT LSCompanyID),
						   @TLGLevel1Count = COUNT(DISTINCT LSLevel1ID),
						   @TLGLevel2Count = COUNT(DISTINCT LSLevel2ID),
						   @TLGLevel3Count = COUNT(DISTINCT LSLevel3ID),
						   @TLGLevel4Count = COUNT(DISTINCT LSLevel4ID),
						   @TLGLevel5Count = COUNT(DISTINCT LSLevel5ID),
						   @TLGLevel6Count = COUNT(DISTINCT LSLevel6ID),
						   @TLGLevel7Count = COUNT(DISTINCT LSLevel7ID),
						   @TLGLevel8Count = COUNT(DISTINCT LSLevel8ID),
						   @TLGLevel9Count = COUNT(DISTINCT LSLevel9ID)
					FROM #TLGQuyLuong;

					SET @TLGGroupLevel =
						CASE
							WHEN @TLGCompanyCount > 1 THEN 0
							WHEN @TLGLevel1Count > 1 THEN 1
							WHEN @TLGLevel2Count > 1 THEN 2
							WHEN @TLGLevel3Count > 1 THEN 3
							WHEN @TLGLevel4Count > 1 THEN 4
							WHEN @TLGLevel5Count > 1 THEN 5
							WHEN @TLGLevel6Count > 1 THEN 6
							WHEN @TLGLevel7Count > 1 THEN 7
							WHEN @TLGLevel8Count > 1 THEN 8
							WHEN @TLGLevel9Count > 1 THEN 9
							WHEN @TLGLevel9Count > 0 THEN 9
							WHEN @TLGLevel8Count > 0 THEN 8
							WHEN @TLGLevel7Count > 0 THEN 7
							WHEN @TLGLevel6Count > 0 THEN 6
							WHEN @TLGLevel5Count > 0 THEN 5
							WHEN @TLGLevel4Count > 0 THEN 4
							WHEN @TLGLevel3Count > 0 THEN 3
							WHEN @TLGLevel2Count > 0 THEN 2
							WHEN @TLGLevel1Count > 0 THEN 1
							ELSE 0
						END;
				END;

				SELECT COALESCE(NULLIF(G.Category, N''),
								CASE WHEN @LanguageID = 'VN' THEN N'Cơ cấu chưa xác định'
									 ELSE N'Unassigned organization' END) AS Category,
					   SUM(T.QuyLuong) AS TongQuyLuong
				FROM #TLGQuyLuong T
				LEFT JOIN dbo.LS_tblCompany (NOLOCK) C ON C.LSCompanyID = T.LSCompanyID
				LEFT JOIN dbo.LS_tblLevel1 (NOLOCK) L1 ON L1.LSLevel1ID = T.LSLevel1ID
				LEFT JOIN dbo.LS_tblLevel2 (NOLOCK) L2 ON L2.LSLevel2ID = T.LSLevel2ID
				LEFT JOIN dbo.LS_tblLevel3 (NOLOCK) L3 ON L3.LSLevel3ID = T.LSLevel3ID
				LEFT JOIN dbo.LS_tblLevel4 (NOLOCK) L4 ON L4.LSLevel4ID = T.LSLevel4ID
				LEFT JOIN dbo.LS_tblLevel5 (NOLOCK) L5 ON L5.LSLevel5ID = T.LSLevel5ID
				LEFT JOIN dbo.LS_tblLevel6 (NOLOCK) L6 ON L6.LSLevel6ID = T.LSLevel6ID
				LEFT JOIN dbo.LS_tblLevel7 (NOLOCK) L7 ON L7.LSLevel7ID = T.LSLevel7ID
				LEFT JOIN dbo.LS_tblLevel8 (NOLOCK) L8 ON L8.LSLevel8ID = T.LSLevel8ID
				LEFT JOIN dbo.LS_tblLevel9 (NOLOCK) L9 ON L9.LSLevel9ID = T.LSLevel9ID
				CROSS APPLY
				(
					SELECT CASE @TLGGroupLevel
							   WHEN 0 THEN T.LSCompanyID
							   WHEN 1 THEN T.LSLevel1ID WHEN 2 THEN T.LSLevel2ID
							   WHEN 3 THEN T.LSLevel3ID WHEN 4 THEN T.LSLevel4ID
							   WHEN 5 THEN T.LSLevel5ID WHEN 6 THEN T.LSLevel6ID
							   WHEN 7 THEN T.LSLevel7ID WHEN 8 THEN T.LSLevel8ID
							   WHEN 9 THEN T.LSLevel9ID END AS GroupID,
						   CASE @TLGGroupLevel
							   WHEN 0 THEN CASE WHEN @LanguageID = 'VN' THEN C.VNName ELSE C.Name END
							   WHEN 1 THEN CASE WHEN @LanguageID = 'VN' THEN L1.VNName ELSE L1.Name END
							   WHEN 2 THEN CASE WHEN @LanguageID = 'VN' THEN L2.VNName ELSE L2.Name END
							   WHEN 3 THEN CASE WHEN @LanguageID = 'VN' THEN L3.VNName ELSE L3.Name END
							   WHEN 4 THEN CASE WHEN @LanguageID = 'VN' THEN L4.VNName ELSE L4.Name END
							   WHEN 5 THEN CASE WHEN @LanguageID = 'VN' THEN L5.VNName ELSE L5.Name END
							   WHEN 6 THEN CASE WHEN @LanguageID = 'VN' THEN L6.VNName ELSE L6.Name END
							   WHEN 7 THEN CASE WHEN @LanguageID = 'VN' THEN L7.VNName ELSE L7.Name END
							   WHEN 8 THEN CASE WHEN @LanguageID = 'VN' THEN L8.VNName ELSE L8.Name END
							   WHEN 9 THEN CASE WHEN @LanguageID = 'VN' THEN L9.VNName ELSE L9.Name END
						   END AS Category
				) G
				GROUP BY G.GroupID, G.Category
				ORDER BY Category;

				DROP TABLE #TLGQuyLuong;
			END
			ELSE IF (@ChartID = 'main_chart_211')
			BEGIN
				DECLARE @TLGQuyLuongTuThang DATE = DATEADD(MONTH, -1, @TLGRangeDau);
				DECLARE @TLGSoThangQuyLuong INT = DATEDIFF(MONTH, @TLGQuyLuongTuThang, @TLGRangeCuoi) + 1;

				CREATE TABLE #TLGQuyLuongTheoThang
				(
					KyDau DATE NOT NULL PRIMARY KEY,
					KyCuoi DATE NOT NULL,
					TimeLine NVARCHAR(20) NOT NULL,
					TongQuyLuong FLOAT NOT NULL
				);

				;WITH Thang AS
				(
					SELECT TOP (@TLGSoThangQuyLuong)
						   DATEADD(MONTH, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1, @TLGQuyLuongTuThang) AS KyDau
					FROM sys.all_objects
				)
				INSERT INTO #TLGQuyLuongTheoThang (KyDau, KyCuoi, TimeLine, TongQuyLuong)
				SELECT Th.KyDau,
					   EOMONTH(Th.KyDau) AS KyCuoi,
					   N'T' + RIGHT('0' + CONVERT(VARCHAR(2), MONTH(Th.KyDau)), 2)
						   + '/' + CONVERT(VARCHAR(4), YEAR(Th.KyDau)) AS TimeLine,
					   ISNULL(QL.TongQuyLuong, 0) AS TongQuyLuong
				FROM Thang Th
				OUTER APPLY
				(
					SELECT SUM(ISNULL(SL.TongLuong, 0) + ISNULL(PC.PhuCap, 0)) AS TongQuyLuong
					FROM @Employees Emp
					INNER JOIN dbo.HR_tblEmp E (NOLOCK) ON E.EmpID = Emp.ID
					OUTER APPLY
					(
						SELECT TOP 1 CONVERT(FLOAT, dbo.sys_fnGetD(S.TongLuong)) AS TongLuong
						FROM dbo.PR_tblSalary S (NOLOCK)
						WHERE S.EmpID = Emp.ID
						AND S.FromDate <= EOMONTH(Th.KyDau)
						ORDER BY S.FromDate DESC
					) SL
					OUTER APPLY
					(
						SELECT SUM(CONVERT(FLOAT, dbo.sys_fnGetD(A.Amount))) AS PhuCap
						FROM dbo.PR_tblAddSalaryEmp A (NOLOCK)
						INNER JOIN dbo.LS_tblAdd_Salary L (NOLOCK) ON L.LSAddSalaryID = A.LSAddSalaryID
						WHERE A.EmpID = Emp.ID
						AND L.LSAddSalaryGroupID = 1
						AND A.FromDate <= EOMONTH(Th.KyDau)
						AND (A.ToDate IS NULL OR A.ToDate >= Th.KyDau)
					) PC
					WHERE (E.StartDate IS NULL OR E.StartDate <= EOMONTH(Th.KyDau))
					AND NOT EXISTS
					(
						SELECT 1
						FROM dbo.TER_tblTermination TER (NOLOCK)
						WHERE TER.EmpID = Emp.ID
						AND TER.EffectDate IS NOT NULL
						AND CONVERT(DATE, TER.EffectDate) <= EOMONTH(Th.KyDau)
					)
				) QL;

				;WITH BienDong AS
				(
					SELECT KyDau, TimeLine, TongQuyLuong,
						   LAG(TongQuyLuong) OVER (ORDER BY KyDau) AS QuyLuongThangTruoc
					FROM #TLGQuyLuongTheoThang
				)
				SELECT TimeLine,
					   TongQuyLuong,
					   CONVERT(DECIMAL(18, 2),
						   CASE WHEN ISNULL(QuyLuongThangTruoc, 0) = 0 THEN 0
								ELSE (TongQuyLuong - QuyLuongThangTruoc) * 100.0 / QuyLuongThangTruoc
						   END) AS TyLeBienDong
				FROM BienDong
				WHERE KyDau >= @TLGRangeDau
				AND KyDau <= @TLGRangeCuoi
				ORDER BY KyDau;

				DROP TABLE #TLGQuyLuongTheoThang;
			END
			ELSE IF (@ChartID = 'main_chart_204')
			BEGIN
				DECLARE @TLG204MaKeHoach NVARCHAR(50);
				DECLARE @TLG204OrgPermission TABLE
				(
					OrgLevel TINYINT NOT NULL,
					OrgID INT NOT NULL,
					PRIMARY KEY (OrgLevel, OrgID)
				);

				INSERT INTO @TLG204OrgPermission (OrgLevel, OrgID)
				SELECT DISTINCT P.OrgLevel, P.OrgID
				FROM
				(
					SELECT 0 AS OrgLevel, strValue AS OrgID FROM dbo.fnGetAllLevel_Permission(@UserGroupID, @FunctionID, 'Comp')
					UNION ALL SELECT 1 AS OrgLevel, strValue AS OrgID FROM dbo.fnGetAllLevel_Permission(@UserGroupID, @FunctionID, 'Level1')
					UNION ALL SELECT 2 AS OrgLevel, strValue AS OrgID FROM dbo.fnGetAllLevel_Permission(@UserGroupID, @FunctionID, 'Level2')
					UNION ALL SELECT 3 AS OrgLevel, strValue AS OrgID FROM dbo.fnGetAllLevel_Permission(@UserGroupID, @FunctionID, 'Level3')
					UNION ALL SELECT 4 AS OrgLevel, strValue AS OrgID FROM dbo.fnGetAllLevel_Permission(@UserGroupID, @FunctionID, 'Level4')
					UNION ALL SELECT 5 AS OrgLevel, strValue AS OrgID FROM dbo.fnGetAllLevel_Permission(@UserGroupID, @FunctionID, 'Level5')
					UNION ALL SELECT 6 AS OrgLevel, strValue AS OrgID FROM dbo.fnGetAllLevel_Permission(@UserGroupID, @FunctionID, 'Level6')
					UNION ALL SELECT 7 AS OrgLevel, strValue AS OrgID FROM dbo.fnGetAllLevel_Permission(@UserGroupID, @FunctionID, 'Level7')
					UNION ALL SELECT 8 AS OrgLevel, strValue AS OrgID FROM dbo.fnGetAllLevel_Permission(@UserGroupID, @FunctionID, 'Level8')
					UNION ALL SELECT 9 AS OrgLevel, strValue AS OrgID FROM dbo.fnGetAllLevel_Permission(@UserGroupID, @FunctionID, 'Level9')
				) P
				WHERE P.OrgID IS NOT NULL;

				SELECT TOP 1 @TLG204MaKeHoach = KH.MaKHDinhBienLaoDong
				FROM dbo.RE_tblKHDinhBienLaoDong KH (NOLOCK)
				WHERE KH.Nam = YEAR(@TLGKyCuoi)
				AND KH.NgayLap <= @TLGKyCuoi
				ORDER BY KH.NgayLap DESC, KH.MaKHDinhBienLaoDong DESC;

				;WITH DaTuyenByDemand AS
				(
					SELECT P.DemandID, COUNT(DISTINCT C.CandidateID) AS DaTuyen
					FROM dbo.RE_tblProject P (NOLOCK)
					INNER JOIN dbo.RE_tblChuyenUVThanhNV C (NOLOCK) ON C.ProjectID = P.ProjectID
					INNER JOIN dbo.HR_tblEmp (NOLOCK) E2 ON E2.CandidateID = C.CandidateID
					WHERE E2.StartDate IS NOT NULL
					GROUP BY P.DemandID
				),
				DemandByDepartment AS
				(
					SELECT ISNULL(D.LSLevel4ID, 0) AS LSLevel4ID,
						   SUM(ISNULL(D.RequireAmount, 0)) AS SoLuongYeuCau,
						   SUM(ISNULL(DT.DaTuyen, 0)) AS SoLuongDaTuyen
					FROM dbo.RE_tblDemand D (NOLOCK)
					LEFT JOIN DaTuyenByDemand DT ON DT.DemandID = D.DemandID
					WHERE EXISTS
					(
						SELECT 1 FROM @TLGSelectedPeriods P
						WHERE D.DemandDate < P.PeriodEndExclusive
						AND (D.ExpireDate IS NULL OR D.ExpireDate >= P.PeriodStart)
					)
					-- Start Rlog: 33306 - TanND35 - 29/10/2026 (ghep tu ban zip 27/10/2026)
					AND (D.LSCompanyID IS NULL OR EXISTS (SELECT 1 FROM @TLG204OrgPermission P WHERE P.OrgLevel = 0 AND P.OrgID = D.LSCompanyID))
					AND (D.LSLevel1ID IS NULL OR EXISTS (SELECT 1 FROM @TLG204OrgPermission P WHERE P.OrgLevel = 1 AND P.OrgID = D.LSLevel1ID))
					AND (D.LSLevel2ID IS NULL OR EXISTS (SELECT 1 FROM @TLG204OrgPermission P WHERE P.OrgLevel = 2 AND P.OrgID = D.LSLevel2ID))
					AND (D.LSLevel3ID IS NULL OR EXISTS (SELECT 1 FROM @TLG204OrgPermission P WHERE P.OrgLevel = 3 AND P.OrgID = D.LSLevel3ID))
					AND (D.LSLevel4ID IS NULL OR EXISTS (SELECT 1 FROM @TLG204OrgPermission P WHERE P.OrgLevel = 4 AND P.OrgID = D.LSLevel4ID))
					AND (D.LSLevel5ID IS NULL OR EXISTS (SELECT 1 FROM @TLG204OrgPermission P WHERE P.OrgLevel = 5 AND P.OrgID = D.LSLevel5ID))
					AND (D.LSLevel6ID IS NULL OR EXISTS (SELECT 1 FROM @TLG204OrgPermission P WHERE P.OrgLevel = 6 AND P.OrgID = D.LSLevel6ID))
					AND (D.LSLevel7ID IS NULL OR EXISTS (SELECT 1 FROM @TLG204OrgPermission P WHERE P.OrgLevel = 7 AND P.OrgID = D.LSLevel7ID))
					AND (D.LSLevel8ID IS NULL OR EXISTS (SELECT 1 FROM @TLG204OrgPermission P WHERE P.OrgLevel = 8 AND P.OrgID = D.LSLevel8ID))
					AND (D.LSLevel9ID IS NULL OR EXISTS (SELECT 1 FROM @TLG204OrgPermission P WHERE P.OrgLevel = 9 AND P.OrgID = D.LSLevel9ID))
					-- End Rlog: 33306
					AND (NOT EXISTS (SELECT 1 FROM @Companys) OR D.LSCompanyID IN (SELECT ID FROM @Companys))
					AND (NOT EXISTS (SELECT 1 FROM @Level1s) OR D.LSLevel1ID IN (SELECT ID FROM @Level1s))
					AND (NOT EXISTS (SELECT 1 FROM @Level2s) OR D.LSLevel2ID IN (SELECT ID FROM @Level2s))
					AND (NOT EXISTS (SELECT 1 FROM @Level3s) OR D.LSLevel3ID IN (SELECT ID FROM @Level3s))
					AND (NOT EXISTS (SELECT 1 FROM @Level4s) OR D.LSLevel4ID IN (SELECT ID FROM @Level4s))
					AND (NOT EXISTS (SELECT 1 FROM @Level5s) OR D.LSLevel5ID IN (SELECT ID FROM @Level5s))
					AND (NOT EXISTS (SELECT 1 FROM @Level6s) OR D.LSLevel6ID IN (SELECT ID FROM @Level6s))
					AND (NOT EXISTS (SELECT 1 FROM @Level7s) OR D.LSLevel7ID IN (SELECT ID FROM @Level7s))
					AND (NOT EXISTS (SELECT 1 FROM @Level8s) OR D.LSLevel8ID IN (SELECT ID FROM @Level8s))
					AND (NOT EXISTS (SELECT 1 FROM @Level9s) OR D.LSLevel9ID IN (SELECT ID FROM @Level9s))
					GROUP BY ISNULL(D.LSLevel4ID, 0)
				),
				HeadcountByDepartment AS
				(
					SELECT ISNULL(CT.LSLevel4ID, 0) AS LSLevel4ID,
						   SUM(CASE MONTH(@TLGKyCuoi)
							   WHEN 1 THEN ISNULL(CT.Thang1, 0) WHEN 2 THEN ISNULL(CT.Thang2, 0)
							   WHEN 3 THEN ISNULL(CT.Thang3, 0) WHEN 4 THEN ISNULL(CT.Thang4, 0)
							   WHEN 5 THEN ISNULL(CT.Thang5, 0) WHEN 6 THEN ISNULL(CT.Thang6, 0)
							   WHEN 7 THEN ISNULL(CT.Thang7, 0) WHEN 8 THEN ISNULL(CT.Thang8, 0)
							   WHEN 9 THEN ISNULL(CT.Thang9, 0) WHEN 10 THEN ISNULL(CT.Thang10, 0)
							   WHEN 11 THEN ISNULL(CT.Thang11, 0) ELSE ISNULL(CT.Thang12, 0)
						   END) AS DinhBien
					FROM dbo.RE_tblKHDinhBienLaoDongChiTiet CT (NOLOCK)
					WHERE CT.MaKHDinhBienLaoDong = @TLG204MaKeHoach
					AND (CT.LSCompanyID IS NULL OR EXISTS (SELECT 1 FROM @TLG204OrgPermission P WHERE P.OrgLevel = 0 AND P.OrgID = CT.LSCompanyID))
					AND (CT.LSLevel1ID IS NULL OR EXISTS (SELECT 1 FROM @TLG204OrgPermission P WHERE P.OrgLevel = 1 AND P.OrgID = CT.LSLevel1ID))
					AND (CT.LSLevel2ID IS NULL OR EXISTS (SELECT 1 FROM @TLG204OrgPermission P WHERE P.OrgLevel = 2 AND P.OrgID = CT.LSLevel2ID))
					AND (CT.LSLevel3ID IS NULL OR EXISTS (SELECT 1 FROM @TLG204OrgPermission P WHERE P.OrgLevel = 3 AND P.OrgID = CT.LSLevel3ID))
					AND (CT.LSLevel4ID IS NULL OR EXISTS (SELECT 1 FROM @TLG204OrgPermission P WHERE P.OrgLevel = 4 AND P.OrgID = CT.LSLevel4ID))
					AND (CT.LSLevel5ID IS NULL OR EXISTS (SELECT 1 FROM @TLG204OrgPermission P WHERE P.OrgLevel = 5 AND P.OrgID = CT.LSLevel5ID))
					AND (CT.LSLevel6ID IS NULL OR EXISTS (SELECT 1 FROM @TLG204OrgPermission P WHERE P.OrgLevel = 6 AND P.OrgID = CT.LSLevel6ID))
					AND (CT.LSLevel7ID IS NULL OR EXISTS (SELECT 1 FROM @TLG204OrgPermission P WHERE P.OrgLevel = 7 AND P.OrgID = CT.LSLevel7ID))
					AND (CT.LSLevel8ID IS NULL OR EXISTS (SELECT 1 FROM @TLG204OrgPermission P WHERE P.OrgLevel = 8 AND P.OrgID = CT.LSLevel8ID))
					AND (CT.LSLevel9ID IS NULL OR EXISTS (SELECT 1 FROM @TLG204OrgPermission P WHERE P.OrgLevel = 9 AND P.OrgID = CT.LSLevel9ID))
					-- End Rlog: 33306
					AND (NOT EXISTS (SELECT 1 FROM @Companys) OR CT.LSCompanyID IN (SELECT ID FROM @Companys))
					AND (NOT EXISTS (SELECT 1 FROM @Level1s) OR CT.LSLevel1ID IN (SELECT ID FROM @Level1s))
					AND (NOT EXISTS (SELECT 1 FROM @Level2s) OR CT.LSLevel2ID IN (SELECT ID FROM @Level2s))
					AND (NOT EXISTS (SELECT 1 FROM @Level3s) OR CT.LSLevel3ID IN (SELECT ID FROM @Level3s))
					AND (NOT EXISTS (SELECT 1 FROM @Level4s) OR CT.LSLevel4ID IN (SELECT ID FROM @Level4s))
					AND (NOT EXISTS (SELECT 1 FROM @Level5s) OR CT.LSLevel5ID IN (SELECT ID FROM @Level5s))
					AND (NOT EXISTS (SELECT 1 FROM @Level6s) OR CT.LSLevel6ID IN (SELECT ID FROM @Level6s))
					AND (NOT EXISTS (SELECT 1 FROM @Level7s) OR CT.LSLevel7ID IN (SELECT ID FROM @Level7s))
					AND (NOT EXISTS (SELECT 1 FROM @Level8s) OR CT.LSLevel8ID IN (SELECT ID FROM @Level8s))
					AND (NOT EXISTS (SELECT 1 FROM @Level9s) OR CT.LSLevel9ID IN (SELECT ID FROM @Level9s))
					GROUP BY ISNULL(CT.LSLevel4ID, 0)
				),
				Departments AS
				(
					SELECT LSLevel4ID FROM DemandByDepartment
					UNION
					SELECT LSLevel4ID FROM HeadcountByDepartment
				)
				SELECT ISNULL(CASE WHEN @LanguageID = 'VN' THEN L4.VNName ELSE L4.Name END,
							  N'(Chưa xác định phòng ban)') AS PhongBan,
					   ISNULL(HC.DinhBien, 0) AS DinhBien,
					   ISNULL(DM.SoLuongYeuCau, 0) AS SoLuongYeuCau,
					   ISNULL(DM.SoLuongDaTuyen, 0) AS SoLuongDaTuyen,
					   CASE WHEN ISNULL(DM.SoLuongYeuCau, 0) > ISNULL(DM.SoLuongDaTuyen, 0)
							THEN ISNULL(DM.SoLuongYeuCau, 0) - ISNULL(DM.SoLuongDaTuyen, 0)
							ELSE 0 END AS SoLuongConThieu
				FROM Departments DP
				LEFT JOIN DemandByDepartment DM ON DM.LSLevel4ID = DP.LSLevel4ID
				LEFT JOIN HeadcountByDepartment HC ON HC.LSLevel4ID = DP.LSLevel4ID
				LEFT JOIN dbo.LS_tblLevel4 L4 (NOLOCK) ON L4.LSLevel4ID = NULLIF(DP.LSLevel4ID, 0)
				ORDER BY SoLuongConThieu DESC, PhongBan;
			END
			ELSE IF (@ChartID = 'main_chart_206')
			BEGIN
				SELECT CC.EmpID,
					   COUNT(CASE WHEN CC.DiTre = 1 THEN 1 END) AS SoLanDiTre,
					   COUNT(CASE WHEN CC.VeSom = 1 THEN 1 END) AS SoLanVeSom,
					   COUNT(CASE WHEN CC.KhongQuetThe = 1 THEN 1 END) AS SoLanKhongQuetThe,
					   COUNT(CASE WHEN CC.QuetThe1Lan = 1 THEN 1 END) AS SoLanQuetTheMotLan
				INTO #TLGViPham
				FROM dbo.TS_tblChamCongCT CC (NOLOCK)
				INNER JOIN @Employees Emp ON Emp.ID = CC.EmpID
				WHERE CC.DateID >= @TLGEventStartDate AND CC.DateID < @TLGEventEndExclusive
				AND EXISTS
				(
					SELECT 1 FROM @TLGSelectedPeriods P
					WHERE CC.DateID >= P.PeriodStart AND CC.DateID < P.PeriodEndExclusive
				)
				GROUP BY CC.EmpID
				HAVING COUNT(CASE WHEN CC.DiTre = 1 THEN 1 END)
					 + COUNT(CASE WHEN CC.VeSom = 1 THEN 1 END)
					 + COUNT(CASE WHEN CC.KhongQuetThe = 1 THEN 1 END)
					 + COUNT(CASE WHEN CC.QuetThe1Lan = 1 THEN 1 END) > 0;

				SELECT vE.EmpName,
                       V.SoLanDiTre, V.SoLanVeSom,
                       V.SoLanKhongQuetThe, V.SoLanQuetTheMotLan
                FROM #TLGViPham V
                INNER JOIN dbo.HR_vEmp (NOLOCK) vE ON vE.EmpID = V.EmpID
                ORDER BY V.SoLanDiTre + V.SoLanVeSom
                       + V.SoLanKhongQuetThe + V.SoLanQuetTheMotLan DESC,
                         vE.EmpName;

                DROP TABLE #TLGViPham;
			END
			ELSE IF (@ChartID = 'main_chart_203')
			BEGIN
				/*
					vupt35 08/09/2026: danh sach cho xu ly day du 24 quy trinh.
					- Moi dong phai dung nguoi duyet hien tai va trang thai cho xu ly cua phan he.
					- Tra khoa/route chi tiet cho iframe; quyen duyet van do man nghiep vu kiem tra.
					- Cong tac dung TS_tblNhatKyCongTac/NhatKyCongTacID, khong dung TS_tblCongTac.
				*/
				CREATE TABLE #TLGPending203
				(
					FlowOrder INT NOT NULL,
					LoaiQuyTrinh NVARCHAR(255) NOT NULL,
					EmpID INT NULL,
					SubjectName NVARCHAR(510) NULL,
					NgayGui DATETIME NULL,
					TargetFID INT NOT NULL,
					RecordID NVARCHAR(100) NOT NULL,
					DetailType VARCHAR(50) NOT NULL,
					DetailAscx NVARCHAR(500) NULL,
					DetailOpenMode VARCHAR(20) NOT NULL,
					DetailQuery NVARCHAR(4000) NOT NULL,
					CanApprove BIT NOT NULL,
					PeriodMonth INT NULL,
					PeriodYear INT NULL,
					PeriodFromDate DATETIME NULL,
					PeriodToDate DATETIME NULL
				);

				-- 1. Nghi phep ngay.
				INSERT #TLGPending203
				SELECT 1,N'Nghỉ phép',
					   L.EmpID,NULL,L.CreateTime,417,CONVERT(NVARCHAR(100),L.LeaveRecordID),
					   'LeaveDay',N'MdlTMS/Form/TS_NghiPhepOnline_Process.ascx','FormPage',
					   N'&LeaveRecordID='+CONVERT(NVARCHAR(100),L.LeaveRecordID),0,NULL,NULL,NULL,NULL
				FROM dbo.TS_tblLeaveRecord L (NOLOCK)
				CROSS APPLY (SELECT TOP 1 P.TrangThai,P.NguoiPheDuyet FROM dbo.TS_tblLeaveRecordProcess P (NOLOCK)
							 WHERE P.LeaveRecordID=L.LeaveRecordID ORDER BY P.LeaveRecordProcessID DESC) Q
				WHERE L.LoaiDangKy=1 AND Q.TrangThai IN (2,3,15) AND Q.NguoiPheDuyet=@UserGroupID;

				-- 2. Nghi phep theo gio.
				INSERT #TLGPending203
				SELECT 2,N'Nghỉ phép theo giờ',L.EmpID,NULL,L.CreateTime,1336,CONVERT(NVARCHAR(100),L.LeaveRecordHourID),
					   'LeaveHour',N'MdlTMS/Form/TS_NghiPhepTheoGioOnlineProcess.ascx','FormPage',
					   N'&LeaveRecordHourID='+CONVERT(NVARCHAR(100),L.LeaveRecordHourID),0,NULL,NULL,NULL,NULL
				FROM dbo.TS_tblLeaveRecordHour L (NOLOCK)
				CROSS APPLY (SELECT TOP 1 P.TrangThai,P.NguoiPheDuyet FROM dbo.TS_tblLeaveRecordHourProcess P (NOLOCK)
							 WHERE P.LeaveRecordHourID=L.LeaveRecordHourID ORDER BY P.LeaveRecordHourProcessID DESC) Q
				WHERE L.LoaiDangKy=1 AND Q.TrangThai IN (2,3,15) AND Q.NguoiPheDuyet=@UserGroupID;

				-- 3. Legacy BusinessTrip is not used by TLG. CT1 remains in LeaveDay above.
				-- 4. Lam ngoai gio.
				INSERT #TLGPending203
				SELECT 4,N'Ngoài giờ',L.EmpID,NULL,L.CreateTime,1738,CONVERT(NVARCHAR(100),L.LamNgoaiGioID),
					   'Overtime',N'MdlTMS/Form/DangKyPhieuLamNgoaiGioOnlineProcess.ascx','FormPage',
					   N'&LamNgoaiGioID='+CONVERT(NVARCHAR(100),L.LamNgoaiGioID),0,NULL,NULL,NULL,NULL
				FROM dbo.TS_tblLamNgoaiGioKeHoach L (NOLOCK)
				CROSS APPLY (SELECT TOP 1 P.TrangThai,P.NguoiPheDuyet FROM dbo.TS_tblLamNgoaiGioKeHoachTrangThai P (NOLOCK)
							 WHERE P.LamNgoaiGioID=L.LamNgoaiGioID ORDER BY TRY_CONVERT(BIGINT,P.LamNgoaiGioTrangThaiID) DESC) Q
				WHERE Q.TrangThai IN (3,7) AND Q.NguoiPheDuyet=@UserGroupID;

				-- 5. Xac nhan bang cong thang; man 1823 vua la danh sach vua la man duyet.
				INSERT #TLGPending203
				SELECT 5,N'Xác nhận chấm công',L.EmpID,NULL,L.CreateTime,1823,CONVERT(NVARCHAR(100),L.ID),
					   'Timesheet',NULL,'Function',
					   N'&Action=Approve&RecordID='+CONVERT(NVARCHAR(100),L.ID)+N'&EmpID='+CONVERT(NVARCHAR(20),L.EmpID)
					   +N'&Month='+CONVERT(NVARCHAR(2),L.[Month])+N'&Year='+CONVERT(NVARCHAR(4),L.[Year]),1,
					   L.[Month],L.[Year],L.FromDate,L.ToDate
				FROM dbo.TS_tblTSConfirmation L (NOLOCK)
				WHERE L.CurLevel>0 AND L.StatusID IN (2,6) AND L.CurApprover=@UserGroupID;

				-- 6. Giai trinh/bo sung du lieu quet the.
				INSERT #TLGPending203
				SELECT 6,N'Giải trình chấm công',L.EmpID,NULL,L.CreateTime,3577,CONVERT(NVARCHAR(100),L.TSDKXacNhanQTOnline2ID),
					   'ClockCorrection',NULL,'Function',
					   N'&EmpID='+CONVERT(NVARCHAR(20),L.EmpID)+N'&DateID='+CONVERT(NVARCHAR(10),L.NgayDK,103)
					   +N'&TSDKXacNhanQTOnline2ID='+CONVERT(NVARCHAR(100),L.TSDKXacNhanQTOnline2ID)+N'&IsList=1',0,
					   MONTH(L.NgayDK),YEAR(L.NgayDK),L.NgayDK,L.NgayDK
				FROM dbo.TS_tblDKXacNhanQTOnline_V2 L (NOLOCK)
				WHERE L.CurStatus=2 AND L.CurLevel>0 AND L.CurApprover=@UserGroupID;

				-- 7. Chuyen duyet bang luong; man goc hien duyet tren danh sach.
				INSERT #TLGPending203
				SELECT 7,N'Chuyển duyệt bảng lương',L.EmpID,NULL,L.CreateTime,5329,CONVERT(NVARCHAR(100),L.PRBangLuongOnlineID),
					   'Payroll',NULL,'Function',N'&PRBangLuongOnlineID='+CONVERT(NVARCHAR(100),L.PRBangLuongOnlineID),1,
					   MONTH(L.FromDate),YEAR(L.FromDate),L.FromDate,L.ToDate
				FROM dbo.PR_tblBangLuongOnline L (NOLOCK)
				WHERE L.LSTinhTrangPheDuyet_BangLuong_TLGID=2 AND L.ApprovedLevel>0 AND L.Approver=@UserGroupID;

				-- 8. Ke hoach hanh dong sau dao tao.
				INSERT #TLGPending203
				SELECT 8,N'Kế hoạch hành động sau đào tạo',L.EmpID_DangKy,NULL,L.CreateDate,1807,L.KeHoachHanhDongSauDaoTaoID,
					   'TrainingActionPlan',NULL,'Function',
					   N'&KeHoachHanhDongSauDaoTaoID='+L.KeHoachHanhDongSauDaoTaoID
					   +N'&EmpID_DangKy='+CONVERT(NVARCHAR(20),L.EmpID_DangKy)
					   +N'&TrainingCourseID='+CONVERT(NVARCHAR(20),L.TrainingcourseID)
					   +N'&Duyet=True&IsCapCuoi='
					   +CASE WHEN dbo.TS_fnLayNguoiPheDuyetCuoiCung(L.EmpID_DangKy,'44')=L.CurApproveLevel THEN N'1' ELSE N'0' END
					   +N'&Cap='+CONVERT(NVARCHAR(10),L.CurApproveLevel),1,NULL,NULL,NULL,NULL
				FROM dbo.TR_tblKeHoachHanhDongSauDaoTao L (NOLOCK)
				WHERE L.CurApproveStatus=2 AND L.CurApproveLevel>0 AND L.CurApprover=@UserGroupID;

				-- 9-10. Danh gia va phe duyet gia han hop dong.
				INSERT #TLGPending203
				SELECT 9,N'Cấp trên đánh giá gia hạn HĐLĐ',L.EmpID,NULL,L.CreateTime,2895,CONVERT(NVARCHAR(100),L.ID),
					   'ContractSupervisor',NULL,'Function',N'&ID='+CONVERT(NVARCHAR(100),L.ID)+N'&EmpID='+CONVERT(NVARCHAR(20),L.EmpID),0,
					   NULL,NULL,L.FromDate,L.ToDate
				FROM dbo.HR_tblDanhGiaGiaHanHopDong L (NOLOCK)
				WHERE L.StatusID=10 AND L.CurApprover=@UserGroupID;

				INSERT #TLGPending203
				SELECT 10,N'Phê duyệt đánh giá gia hạn HĐLĐ',L.EmpID,NULL,L.CreateTime,2903,CONVERT(NVARCHAR(100),L.ID),
					   'ContractApproval',NULL,'Function',
					   N'&ParentFuncID=2901&ID='+CONVERT(NVARCHAR(100),L.ID)+N'&Edit=1&EmpID='+CONVERT(NVARCHAR(20),L.EmpID)
					   +N'&From='+CONVERT(NVARCHAR(10),L.FromDate,103)+N'&To='+CONVERT(NVARCHAR(10),L.ToDate,103)
					   +N'&CurLevel='+CONVERT(NVARCHAR(10),L.CurLevel)+N'&CurApprove='+ISNULL(L.CurApprover,N''),1,
					   NULL,NULL,L.FromDate,L.ToDate
				FROM dbo.HR_tblDanhGiaGiaHanHopDong L (NOLOCK)
				WHERE L.StatusID IN (2,6) AND L.CurLevel>0 AND L.CurApprover=@UserGroupID;

				-- 11-12. Danh gia va phe duyet thu viec.
				INSERT #TLGPending203
				SELECT 11,N'Cấp trên đánh giá thử việc',L.EmpID,NULL,L.CreateTime,2904,CONVERT(NVARCHAR(100),L.HRDanhGiaTVID),
					   'ProbationSupervisor',NULL,'Function',
					   N'&HRDanhGiaTVID='+CONVERT(NVARCHAR(100),L.HRDanhGiaTVID)+N'&EmpID='+CONVERT(NVARCHAR(20),L.EmpID),0,
					   NULL,NULL,L.ProbationDate_From,L.ProbationDate_To
				FROM dbo.HR_tblDanhGiaTV L (NOLOCK)
				WHERE L.REApprovedStatusID=18 AND L.CurApproved=@UserGroupID;

				INSERT #TLGPending203
				SELECT 12,N'Phê duyệt đánh giá thử việc',L.EmpID,NULL,L.CreateTime,2910,CONVERT(NVARCHAR(100),L.HRDanhGiaTVID),
					   'ProbationApproval',NULL,'Function',
					   N'&ParentFuncID=2908&HRDanhGiaTVID='+CONVERT(NVARCHAR(100),L.HRDanhGiaTVID)
					   +N'&EmpID='+CONVERT(NVARCHAR(20),L.EmpID)+N'&sLevel='+CONVERT(NVARCHAR(10),L.ApprovedLevel)
					   +N'&sCurApproved='+ISNULL(L.CurApproved,N''),1,NULL,NULL,L.ProbationDate_From,L.ProbationDate_To
				FROM dbo.HR_tblDanhGiaTV L (NOLOCK)
				WHERE L.REApprovedStatusID IN (2,6) AND L.ApprovedLevel>0 AND L.CurApproved=@UserGroupID;

				-- 13. Offer.
				INSERT #TLGPending203
				SELECT 13,N'Phê duyệt offer',C.EmpID,C.CandidateName,L.CreateDate,4501,CONVERT(NVARCHAR(100),L.ChuyenUVThanhNVID),
					   'Offer',NULL,'Function',N'&CandidateID='+CONVERT(NVARCHAR(100),L.CandidateID)
					   +N'&ProjectID='+CONVERT(NVARCHAR(100),L.ProjectID)+N'&DemandID='+ISNULL(CONVERT(NVARCHAR(100),C.DemandID),N'')
					   +N'&Action=IsApprove&Level='+CONVERT(NVARCHAR(10),L.ApproveLevel),1,NULL,NULL,NULL,NULL
				FROM dbo.RE_tblChuyenUVThanhNV L (NOLOCK)
				LEFT JOIN dbo.RE_tblCandidate C (NOLOCK) ON C.CandidateID=L.CandidateID
				WHERE L.ApproveStatus=2 AND L.ApproveLevel>0 AND L.Approver=@UserGroupID;

				-- 14. Danh gia KPI nhan vien (du lieu cuoi nam).
				INSERT #TLGPending203
				SELECT 14,N'Phê duyệt đánh giá KPI nhân viên',L.EmpID,NULL,L.CreateTime,5933,CONVERT(NVARCHAR(100),L.PM_EVAL_EndYear_ID),
					   'KpiEmployeeEvaluation',NULL,'Function',
					   N'&ParentFuncID=5822&TypePopup=EndYear&MasterID='+CONVERT(NVARCHAR(100),L.PM_EVAL_EndYear_ID)
					   +N'&PeriodID='+CONVERT(NVARCHAR(20),L.PM_EvaluationPeriodID)+N'&EmpID='+CONVERT(NVARCHAR(20),L.EmpID),1,
					   NULL,NULL,NULL,NULL
				FROM dbo.PM_tblEVAL_EndYear L (NOLOCK)
				WHERE L.PM_ApprovedStatusID=101 AND L.PM_ApprovedLevelID>0 AND L.CurApprover=@UserGroupID;

				-- 15. Danh gia KPI phong ban.
				INSERT #TLGPending203
				SELECT 15,N'Phê duyệt đánh giá KPI phòng ban',L.EmpID,NULL,L.CreateTime,5741,CONVERT(NVARCHAR(100),L.DanhGiaMucTieuCoCauID),
					   'KpiDepartmentEvaluation',NULL,'Function',N'&ParentFuncID=5740&TypePopup='+ISNULL(L.Type,N'')
					   +N'&MasterID='+CONVERT(NVARCHAR(100),L.DanhGiaMucTieuCoCauID)+N'&Year='+CONVERT(NVARCHAR(4),L.[Year])
					   +N'&EvaluationPeriodID='+CONVERT(NVARCHAR(20),L.EvaluationPeriodID)
					   -- vupt35 09/09/2026: FID 5741 doc truc tiep LSCompanyID/Level1/Level2 tai Page_Load.
					   -- Truyen day du co cau nhu man danh sach goc de popup khong bi NullReferenceException.
					   +N'&LSCompanyID='+ISNULL(CONVERT(NVARCHAR(20),L.LSCompanyID),N'')
					   +N'&LSLevel1ID='+ISNULL(CONVERT(NVARCHAR(20),L.LSLevel1ID),N'')
					   +N'&LSLevel2ID='+ISNULL(CONVERT(NVARCHAR(20),L.LSLevel2ID),N'')
					   +N'&LSLevel3ID='+ISNULL(CONVERT(NVARCHAR(20),L.LSLevel3ID),N'')
					   +N'&LSLevel4ID='+ISNULL(CONVERT(NVARCHAR(20),L.LSLevel4ID),N'')
					   +N'&LSLevel5ID='+ISNULL(CONVERT(NVARCHAR(20),L.LSLevel5ID),N'')
					   +N'&LSLevel6ID='+ISNULL(CONVERT(NVARCHAR(20),L.LSLevel6ID),N'')
					   +N'&LSLevel7ID='+ISNULL(CONVERT(NVARCHAR(20),L.LSLevel7ID),N'')
					   +N'&LSLevel8ID='+ISNULL(CONVERT(NVARCHAR(20),L.LSLevel8ID),N'')
					   +N'&LSLevel9ID='+ISNULL(CONVERT(NVARCHAR(20),L.LSLevel9ID),N'')
					   +N'&LSTrackingMethodID='+ISNULL(CONVERT(NVARCHAR(20),L.LSTrackingMethodID),N''),1,NULL,L.[Year],NULL,NULL
				FROM dbo.PM_tblDanhGiaMucTieuCoCau L (NOLOCK)
				WHERE L.ApprovedStatusID=86 AND L.ApprovedLevelID>0 AND L.CurApprover=@UserGroupID;

				-- 16. Thiet lap KPI ca nhan.
				INSERT #TLGPending203
				SELECT 16,N'Phê duyệt thiết lập KPI cá nhân',L.EmpID,NULL,L.CreateTime,5799,CONVERT(NVARCHAR(100),L.PM_GoalPeriod_Emp_Master_ID),
					   'KpiEmployeeGoal',NULL,'Function',N'&ParentFuncID=5798&MasterID='+CONVERT(NVARCHAR(100),L.PM_GoalPeriod_Emp_Master_ID)
					   +N'&EmpID='+CONVERT(NVARCHAR(20),L.EmpID),1,NULL,NULL,NULL,NULL
				FROM dbo.PM_tblGoalPeriod_Emp_Master L (NOLOCK)
				WHERE L.PM_ApprovedStatusID=22 AND L.PM_ApprovedLevelID>0 AND L.PM_CurApprover=@UserGroupID;

				-- 17. Thiet lap KPI phong ban.
				INSERT #TLGPending203
				SELECT 17,N'Phê duyệt thiết lập KPI phòng ban',L.EmpID,NULL,L.CreateTime,5726,CONVERT(NVARCHAR(100),L.ThietLapMucTieuCoCauID),
					   'KpiDepartmentGoal',NULL,'Function',N'&ParentFuncID=5725&TypePopup='+ISNULL(L.Type,N'')
					   +N'&MasterID='+CONVERT(NVARCHAR(100),L.ThietLapMucTieuCoCauID),1,NULL,L.[Year],NULL,NULL
				FROM dbo.PM_tblThietLapMucTieuCoCau L (NOLOCK)
				WHERE L.ApprovedStatusID=76 AND L.ApprovedLevelID>0 AND L.CurApprover=@UserGroupID;

				-- 18 va 20. Thay doi tinh trang thuong/ky luat dung cung man chi tiet 2973.
				INSERT #TLGPending203
				SELECT CASE WHEN ISNULL(L.DeXuatKyLuat,0)=1 THEN 20 ELSE 18 END,
					   CASE WHEN ISNULL(L.DeXuatKyLuat,0)=1 THEN N'Thay đổi tình trạng kỷ luật' ELSE N'Thay đổi tình trạng nhân viên' END,
					   L.EmpID,NULL,L.CreateTime,2973,CONVERT(NVARCHAR(100),L.HRThayDoiTinhTrangNhanVienID),
					   CASE WHEN ISNULL(L.DeXuatKyLuat,0)=1 THEN 'DisciplinaryStatusChange' ELSE 'EmployeeStatusChange' END,
					   NULL,'Function',N'&HRThayDoiTinhTrangNhanVienID='+CONVERT(NVARCHAR(100),L.HRThayDoiTinhTrangNhanVienID)
					   +N'&EmpID='+CONVERT(NVARCHAR(20),L.EmpID)+N'&sLevel='+CONVERT(NVARCHAR(10),L.ApprovedLevel)+N'&PheDuyet=1',1,
					   NULL,NULL,L.NgayHieuLuc,L.NgayHieuLuc
				FROM dbo.HR_tblThayDoiTinhTrangNhanVien L (NOLOCK)
				WHERE L.REApprovedStatusID=2 AND L.ApprovedLevel>0 AND L.CurApproved=@UserGroupID;

				-- 19. Kiem nhiem.
				INSERT #TLGPending203
				SELECT 19,N'Thay đổi kiêm nhiệm',L.EmpID,NULL,L.CreateTime,4191,CONVERT(NVARCHAR(100),L.TruongDonViDeXuatKiemNhiemID),
					   'ConcurrentAssignment',NULL,'Function',N'&TruongDonViDeXuatKiemNhiemID='+CONVERT(NVARCHAR(100),L.TruongDonViDeXuatKiemNhiemID)
					   +N'&Action=IsApprove',1,NULL,NULL,L.NgayHieuLuc,L.DenNgay
				FROM dbo.HR_tblTruongDonViDeXuatKiemNhiem L (NOLOCK)
				WHERE L.ApproveStatus=2 AND L.ApproveLevel>0 AND L.Approver=@UserGroupID;

				-- 21. De xuat nhu cau dao tao.
				INSERT #TLGPending203
				SELECT 21,N'Đề xuất nhu cầu đào tạo',TRY_CONVERT(INT,L.EmpID_DeXuat),NULL,L.CreateDate,1681,CONVERT(NVARCHAR(100),L.TrainingCourseID),
					   'TrainingNeed',N'MdlTR/Form/TrainingCourse.ascx','FormPage',N'&IsLoadOnline=1&IsLoadOnlineDeptHead=1&IsLoadApprove=1'
					   +N'&EmpID_DeXuat='+ISNULL(L.EmpID_DeXuat,N'')+N'&TrainingCourseID='+CONVERT(NVARCHAR(100),L.TrainingCourseID)+N'&IsPopUp=1',1,
					   NULL,L.[Year],L.TuNgay,L.DenNgay
				FROM dbo.TR_tblTrainingCourse L (NOLOCK)
				WHERE TRY_CONVERT(INT,L.CurApproveStatus)=2 AND L.CurApproveLevel>0 AND L.CurApprover=@UserGroupID;

				-- 22-23. Tuyen dung ngoai/theo ke hoach.
				INSERT #TLGPending203
				SELECT CASE WHEN TRY_CONVERT(INT,L.IsYCDBKhac)=1 THEN 22 ELSE 23 END,
					   CASE WHEN TRY_CONVERT(INT,L.IsYCDBKhac)=1 THEN N'Tuyển dụng ngoài kế hoạch' ELSE N'Tuyển dụng theo kế hoạch' END,
					   L.Demand_EmpID,NULL,L.CreateDate,7108,CONVERT(NVARCHAR(100),L.DemandID),
					   CASE WHEN TRY_CONVERT(INT,L.IsYCDBKhac)=1 THEN 'RecruitmentOutsidePlan' ELSE 'RecruitmentInPlan' END,
					   NULL,'Function',N'&DemandID='+CONVERT(NVARCHAR(100),L.DemandID),1,NULL,NULL,L.DemandDate,L.JobStartDate
				FROM dbo.RE_tblDemand L (NOLOCK)
				CROSS APPLY (SELECT TOP 1 P.REApprovedStatusID,P.Approve_UserID FROM dbo.RE_tblDemandProcess P (NOLOCK)
							 WHERE P.DemandID=L.DemandID ORDER BY P.DemandProcessID DESC) Q
				WHERE TRY_CONVERT(INT,Q.REApprovedStatusID)=2 AND Q.Approve_UserID=@UserGroupID;

				-- 24. Yeu cau thoi viec.
				INSERT #TLGPending203
				SELECT 24,N'Yêu cầu thôi việc',L.EmpID,NULL,L.CreateTime,3003,L.ID,'Termination',NULL,'Function',
					   N'&IsPopup=1&ParentFuncID=3005&ID='+L.ID+N'&EmpID='+CONVERT(NVARCHAR(20),L.EmpID)
					   +N'&Action=Approve&CancelConfirm=0',1,NULL,NULL,L.ProDate,L.EffDate
				FROM dbo.HR_tblLeaveRequest L (NOLOCK)
				WHERE L.StatusID=2 AND L.CurLevel>0 AND L.CurApprover=@UserGroupID;

				UPDATE #TLGPending203 SET CanApprove = 1 WHERE DetailType IN ('LeaveDay','Overtime','ClockCorrection');
SELECT P.LoaiQuyTrinh,P.EmpID,P.RecordID,P.DetailType,P.DetailAscx,P.DetailOpenMode,P.DetailQuery,P.CanApprove,
					   COALESCE(NULLIF(P.SubjectName,N''),vE.EmpName,N'') AS EmpName,
				   ISNULL(COALESCE(NULLIF(L4.ShortName,N''),NULLIF(L3.ShortName,N''),NULLIF(L2.ShortName,N''),
				                   vE.Level4ShortName,vE.Level3ShortName,vE.Level2ShortName,vE.Level1ShortName,vE.CompanyShortName),N'') AS DonVi,
				   ISNULL(CASE WHEN @LanguageID='VN' THEN L2.VNName ELSE L2.Name END,N'') AS Level2,
				   ISNULL(CASE WHEN @LanguageID='VN' THEN L3.VNName ELSE L3.Name END,N'') AS Level3,
				   ISNULL(CASE WHEN @LanguageID='VN' THEN L4.VNName ELSE L4.Name END,N'') AS Level4,
				/* Rlog SUP-20261113-01 */ ISNULL(CASE WHEN @LanguageID='VN' THEN J203.VNName ELSE J203.Name END,N'') AS ChucDanh,
					   CONVERT(VARCHAR(10),P.NgayGui,103) AS NgayGui,P.TargetFID,P.PeriodMonth,P.PeriodYear,
					   CONVERT(VARCHAR(10),P.PeriodFromDate,103) AS PeriodFromDate,
					   CONVERT(VARCHAR(10),P.PeriodToDate,103) AS PeriodToDate
				FROM #TLGPending203 P
				LEFT JOIN dbo.HR_vEmp vE (NOLOCK) ON vE.EmpID=P.EmpID
				OUTER APPLY
				(
					SELECT TOP 1 W.WorkingRecordID,W.LSCompanyID,W.LSLevel1ID,W.LSLevel2ID,W.LSLevel3ID,
					       W.LSLevel4ID,W.LSLevel5ID,W.LSLevel6ID,W.LSLevel7ID,W.LSLevel8ID,W.LSLevel9ID,
					       W.LSHLevel1ID,W.LSJobTitleID /* Rlog SUP-20261113-01 */
					FROM dbo.HR_tblWorkingRecord W (NOLOCK)
					WHERE W.EmpID=P.EmpID AND W.FromDate<=CONVERT(DATE,GETDATE())
					ORDER BY W.FromDate DESC,W.WorkingRecordID DESC
				) WR
				LEFT JOIN dbo.LS_tblLevel2 L2 (NOLOCK) ON L2.LSLevel2ID=WR.LSLevel2ID
				LEFT JOIN dbo.LS_tblLevel3 L3 (NOLOCK) ON L3.LSLevel3ID=WR.LSLevel3ID
				LEFT JOIN dbo.LS_tblLevel4 L4 (NOLOCK) ON L4.LSLevel4ID=WR.LSLevel4ID
				LEFT JOIN dbo.LS_tblJobTitle J203 (NOLOCK) ON J203.LSJobTitleID=WR.LSJobTitleID /* Rlog SUP-20261113-01 */
				WHERE (NOT EXISTS (SELECT 1 FROM @Companys) OR WR.LSCompanyID IN (SELECT ID FROM @Companys))
				  AND (NOT EXISTS (SELECT 1 FROM @Level1s) OR WR.LSLevel1ID IN (SELECT ID FROM @Level1s))
				  AND (NOT EXISTS (SELECT 1 FROM @Level2s) OR WR.LSLevel2ID IN (SELECT ID FROM @Level2s))
				  AND (NOT EXISTS (SELECT 1 FROM @Level3s) OR WR.LSLevel3ID IN (SELECT ID FROM @Level3s))
				  AND (NOT EXISTS (SELECT 1 FROM @Level4s) OR WR.LSLevel4ID IN (SELECT ID FROM @Level4s))
				  AND (NOT EXISTS (SELECT 1 FROM @Level5s) OR WR.LSLevel5ID IN (SELECT ID FROM @Level5s))
				  AND (NOT EXISTS (SELECT 1 FROM @Level6s) OR WR.LSLevel6ID IN (SELECT ID FROM @Level6s))
				  AND (NOT EXISTS (SELECT 1 FROM @Level7s) OR WR.LSLevel7ID IN (SELECT ID FROM @Level7s))
				  AND (NOT EXISTS (SELECT 1 FROM @Level8s) OR WR.LSLevel8ID IN (SELECT ID FROM @Level8s))
				  AND (NOT EXISTS (SELECT 1 FROM @Level9s) OR WR.LSLevel9ID IN (SELECT ID FROM @Level9s))
				  AND (NOT EXISTS (SELECT 1 FROM @HLevel1s) OR WR.LSHLevel1ID IN (SELECT ID FROM @HLevel1s))
				ORDER BY P.FlowOrder,P.NgayGui DESC;
			END
			ELSE IF (@ChartID = 'main_chart_203_legacy')
			BEGIN
				-- DS CHO XU LY (chot voi user 05/08/2026): CHI don ma USER DANG NHAP
				-- la nguoi duyet hien tai (CurApprover = @UserGroupID), moi don 1 dong,
				-- nut Duyet dieu huong den man phe duyet (TargetFID).
				-- KHONG loc theo ky/bo loc co cau: hang doi phe duyet la HIEN TRANG cua user.
				-- DOT 1 = 4 loai theo chuan trang thai TMS (TS_fnTableTrangThai:
				-- 3=cho phe duyet, 7=cho phe duyet huy):
				--   Nghi phep ngay (TS_tblLeaveRecord, LoaiDangKy=1)           -> FID 417
				--   Nghi phep gio  (TS_tblLeaveRecordHour, LoaiDangKy=1)       -> FID 1336
				--   Cong tac (TS_tblCongTac, IsOnline=1)                      -> FID 417
				--   Ngoai gio (TS_tblLamNgoaiGioKeHoach, trang thai moi nhat)  -> FID 1738
				--   Xac nhan bang cong (TS_tblTSConfirmation, StatusID=2/6)   -> FID 1823
				-- DOT 2 (cho chot ma trang thai tung phan he): thoi viec 3005 (HR_tblLeaveRequest),
				-- thu viec 2908, tai ky HDLD 2901, offer 4521, tuyen dung 7116, thay doi TT 2971...
				-- Uy quyen cua bang cong dung LSChucNangID=28 nhu store phe duyet goc.
				SELECT DON.LoaiQuyTrinh,
					   DON.EmpID,
					   DON.RecordID,
					   DON.DetailType,
					   -- vupt35 08/09/2026: popup da doi chieu voi man goc; NULL = chua xac minh.
					   -- Day la lien ket xem chi tiet, KHONG phai quyen duyet.
					   CASE DON.DetailType
						   WHEN 'LeaveDay' THEN 'MdlTMS/Form/TS_NghiPhepOnline_Process.ascx'
						   WHEN 'LeaveHour' THEN 'MdlTMS/Form/TS_NghiPhepTheoGioOnlineProcess.ascx'
						   WHEN 'Overtime' THEN 'MdlTMS/Form/DangKyPhieuLamNgoaiGioOnlineProcess.ascx'
					   END AS DetailAscx,
					   CASE DON.DetailType
						   WHEN 'LeaveDay' THEN 'LeaveRecordID'
						   WHEN 'LeaveHour' THEN 'LeaveRecordHourID'
						   WHEN 'Overtime' THEN 'LamNgoaiGioID'
					   END AS DetailRecordParam,
					   vE.EmpName,
					   ISNULL(COALESCE(vE.Level4ShortName, vE.Level3ShortName, vE.Level2ShortName,
									   vE.Level1ShortName, vE.CompanyShortName), '') AS DonVi,
					   ISNULL(CASE WHEN @LanguageID = 'VN' THEN vE.Level2VN ELSE vE.Level2EN END, '') AS Level2,
					   ISNULL(CASE WHEN @LanguageID = 'VN' THEN vE.Level3VN ELSE vE.Level3EN END, '') AS Level3,
					   ISNULL(CASE WHEN @LanguageID = 'VN' THEN vE.Level4VN ELSE vE.Level4EN END, '') AS Level4,
					   CONVERT(VARCHAR(10), DON.NgayGui, 103) AS NgayGui,
					   DON.TargetFID,
					   DON.PeriodMonth,
					   DON.PeriodYear,
					   CONVERT(VARCHAR(10), DON.PeriodFromDate, 103) AS PeriodFromDate,
					   CONVERT(VARCHAR(10), DON.PeriodToDate, 103) AS PeriodToDate
				-- FIX 05/08/2026: trang thai "dang cho duyet" phai lay tu BANG PROCESS
				-- MOI NHAT (TrangThai IN (2,3,15)) GIONG man 417/store DanhSachDuyetOnline.
				-- Cot ApprovedStatus tren bang chinh co the LECH process (data co don
				-- ApprovedStatus=3 nhung process moi nhat = 4 da duyet) -> block hien
				-- thua don so voi man duyet.
				FROM
				(
					SELECT N'Nghỉ phép' AS LoaiQuyTrinh, L.EmpID, L.CreateTime AS NgayGui,
						   417 AS TargetFID, L.LeaveRecordID AS RecordID,
						   'LeaveDay' AS DetailType,
						   CAST(NULL AS INT) AS PeriodMonth, CAST(NULL AS INT) AS PeriodYear,
						   CAST(NULL AS DATETIME) AS PeriodFromDate, CAST(NULL AS DATETIME) AS PeriodToDate
					FROM dbo.TS_tblLeaveRecord L (NOLOCK)
					CROSS APPLY
					(
						SELECT TOP 1 PR.TrangThai
						FROM dbo.TS_tblLeaveRecordProcess PR (NOLOCK)
						WHERE PR.LeaveRecordID = L.LeaveRecordID
						ORDER BY PR.LeaveRecordProcessID DESC
					) PT
					WHERE L.LoaiDangKy = 1 AND L.CurApprover = @UserGroupID
					AND PT.TrangThai IN (2, 3, 15)
					UNION ALL
					-- vupt35 08/09/2026: tra khoa don de iframe mo dung chi tiet nghi theo gio.
					SELECT N'Nghỉ phép theo giờ', LH.EmpID, LH.CreateTime, 1336, LH.LeaveRecordHourID,
						   'LeaveHour', NULL, NULL, NULL, NULL
					FROM dbo.TS_tblLeaveRecordHour LH (NOLOCK)
					CROSS APPLY
					(
						SELECT TOP 1 PR.TrangThai
						FROM dbo.TS_tblLeaveRecordHourProcess PR (NOLOCK)
						WHERE PR.LeaveRecordHourID = LH.LeaveRecordHourID
						ORDER BY PR.LeaveRecordHourProcessID DESC
					) PT
					WHERE LH.LoaiDangKy = 1 AND LH.CurApprover = @UserGroupID
					AND PT.TrangThai IN (2, 3, 15)
					UNION ALL
					-- vupt35 08/09/2026: giu dung khoa CongTacID; khong doi thanh NhatKyCongTacID.
					SELECT N'Công tác', CT.EmpID, CT.CreateTime, 417, CT.CongTacID,
						   'BusinessTrip', NULL, NULL, NULL, NULL
					FROM dbo.TS_tblCongTac CT (NOLOCK)
					CROSS APPLY
					(
						SELECT TOP 1 PR.TrangThai
						FROM dbo.TS_tblCongTacProcess PR (NOLOCK)
						WHERE PR.CongTacID = CT.CongTacID
						ORDER BY PR.CongTacProcessID DESC
					) PT
					WHERE CT.IsOnline = 1 AND CT.CurApprover = @UserGroupID
					AND PT.TrangThai IN (2, 3, 15)
					UNION ALL
					SELECT N'Ngoài giờ', NG.EmpID, NG.CreateTime, 1738, NG.LamNgoaiGioID,
						   'Overtime', NULL, NULL, NULL, NULL
					FROM dbo.TS_tblLamNgoaiGioKeHoach NG (NOLOCK)
					CROSS APPLY
					(
						SELECT TOP 1 PR.TrangThai, PR.NguoiPheDuyet
						FROM dbo.TS_tblLamNgoaiGioKeHoachTrangThai PR (NOLOCK)
						WHERE PR.LamNgoaiGioID = NG.LamNgoaiGioID
						ORDER BY CONVERT(BIGINT, PR.LamNgoaiGioTrangThaiID) DESC
					) PT
					WHERE NG.ApprovedStatus IN (3, 7)
					AND PT.TrangThai IN (3, 7)
					AND PT.NguoiPheDuyet = @UserGroupID
					UNION ALL
					SELECT N'Xác nhận chấm công', TH.EmpID, TH.CreateTime, 1823, TH.ID,
						   'Timesheet', TH.[Month], TH.[Year], TH.FromDate, TH.ToDate
					FROM dbo.TS_tblTSConfirmation TH (NOLOCK)
					WHERE TH.CurLevel > 0
					AND TH.StatusID IN (2, 6)
					AND
					(
						TH.CurApprover = @UserGroupID
						OR EXISTS
						(
							SELECT 1
							FROM dbo.SYS_tblDelegate DG (NOLOCK)
							WHERE DG.Account = TH.CurApprover
							AND DG.Account_Delegate = @UserGroupID
							AND DG.LSChucNangID = '28'
							AND @dDate BETWEEN ISNULL(DG.FromDate, '19000101')
										   AND ISNULL(DATEADD(DAY, 1, DG.ToDate), '21000101')
						)
					)
					UNION ALL
					-- Hai bước cấp trên đánh giá không đi qua quy trình phê duyệt online.
					SELECT N'Cấp trên đánh giá thử việc', TV.EmpID, TV.ProbationDate_To, 2904,
						   TV.HRDanhGiaTVID, 'Probation', NULL, NULL, NULL, NULL
					FROM dbo.HR_tblDanhGiaTV TV (NOLOCK)
					WHERE TV.REApprovedStatusID = 2 AND TV.CurApproved = @UserGroupID
					UNION ALL
					SELECT N'Cấp trên đánh giá gia hạn hợp đồng', GH.EmpID, GH.ToDate, 2895,
						   GH.ID, 'ContractExtension', NULL, NULL, NULL, NULL
					FROM dbo.HR_tblDanhGiaGiaHanHopDong GH (NOLOCK)
					WHERE GH.StatusID = 2 AND GH.CurApprover = @UserGroupID
				) DON
				LEFT JOIN dbo.HR_vEmp (NOLOCK) vE ON vE.EmpID = DON.EmpID
				ORDER BY DON.LoaiQuyTrinh, DON.NgayGui DESC;
			END
			ELSE IF (@ChartID = 'main_chart_205')
			BEGIN
				-- KE HOACH NGHI PHEP (chot voi user 05/08/2026):
				--   Ngay le  = TS_tblHolidayDay (FID 271), Used = 1          -> Loai = 2
				--   Don nghi = TS_tblLeaveRecord (FID 144147) DA PHE DUYET
				--              (ApprovedStatus = 4), NV thuoc @Employees      -> Loai = 1
				-- Thang RIENG cua block: JS gui YEAR_LOCAL/MONTH_LOCAL trong FilterJson;
				-- khong gui -> mac dinh THANG HIEN TAI (KHONG theo bo loc chung).
				-- Moi NV nghi 1 dong CHO TUNG NGAY nghi trong thang (JS gom theo ngay).
				DECLARE @TLG205Year INT = ISNULL((SELECT MAX(FilterValue) FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'YEAR_LOCAL'), YEAR(@dDate));
				DECLARE @TLG205Month INT = ISNULL((SELECT MAX(FilterValue) FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'MONTH_LOCAL'), MONTH(@dDate));
				DECLARE @TLG205Dau DATE = DATEFROMPARTS(@TLG205Year, @TLG205Month, 1);
				DECLARE @TLG205Cuoi DATE = EOMONTH(DATEFROMPARTS(@TLG205Year, @TLG205Month, 1));

				-- FIX HIEU NANG 11/08/2026: ban cu JOIN toan bo TS_tblLeaveRecord (bat ke
				-- NV/trang thai) voi bang 31 ngay qua dieu kien BETWEEN CONVERT(DATE,...) -
				-- KHONG sargable (ham boc quanh cot) -> quet lai gan het bang (136k dong tren
				-- DB TLG thuc) nhieu lan -> do duoc 23.8s. Doi lai: loc TRUOC theo @Employees
				-- (seek EmpID, thu hep con rat it dong) + ApprovedStatus + overlap thang bang
				-- dieu kien SARGABLE (so voi BIEN @TLG205Dau/Cuoi, KHONG boc ham quanh cot),
				-- roi moi "no" tung ngay CHO DUNG khoang cua TUNG don (it ngay) - khong con
				-- quet toan bang theo tung ngay trong thang nua.
				;WITH NgayTrongThang AS
				(
					SELECT TOP (DAY(@TLG205Cuoi))
						   DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1, @TLG205Dau) AS Ngay
					FROM sys.all_objects
				),
				LeaveInMonth AS
				(
					SELECT L.LeaveRecordID, L.EmpID, L.LSWorkPointID, L.LeaveTaken, L.FromDate, L.ToDate,
						   CASE WHEN CONVERT(DATE, L.FromDate) < @TLG205Dau THEN @TLG205Dau ELSE CONVERT(DATE, L.FromDate) END AS ClipStart,
						   CASE WHEN CONVERT(DATE, ISNULL(L.ToDate, L.FromDate)) > @TLG205Cuoi THEN @TLG205Cuoi ELSE CONVERT(DATE, ISNULL(L.ToDate, L.FromDate)) END AS ClipEnd
					FROM dbo.TS_tblLeaveRecord L (NOLOCK)
					INNER JOIN @Employees Emp ON Emp.ID = L.EmpID
					WHERE L.ApprovedStatus = 4
					AND L.FromDate <= @TLG205Cuoi
					AND ISNULL(L.ToDate, L.FromDate) >= @TLG205Dau
				)
				-- TS_tblHolidayDay.[Date] la NVARCHAR 'dd/MM' (le lap hang nam, KHONG co nam)
				-- -> ghep nam dang xem roi convert kieu 103; phong truong hop co dong 'dd/MM/yyyy'
				SELECT CONVERT(VARCHAR(10), NL.NgayLe, 120) AS Ngay,
					   2 AS Loai,
					   NULL AS HoTen,
					   ISNULL(CASE WHEN @LanguageID = 'VN' THEN H.VNName ELSE H.Name END, N'Nghỉ lễ') AS LoaiNghi,
					   NULL AS ThoiGianNghi, CAST(NULL AS NVARCHAR(12)) AS LSWorkPointID
				FROM dbo.TS_tblHolidayDay H (NOLOCK)
				CROSS APPLY
				(
					SELECT COALESCE(
						TRY_CONVERT(DATE, LTRIM(RTRIM(H.[Date])) + '/' + CONVERT(VARCHAR(4), @TLG205Year), 103),
						TRY_CONVERT(DATE, LTRIM(RTRIM(H.[Date])), 103)) AS NgayLe
				) NL
				WHERE H.Used = 1
				AND NL.NgayLe BETWEEN @TLG205Dau AND @TLG205Cuoi
				UNION ALL
				-- DISTINCT (05/08/2026): du lieu test co nhieu ban ghi don Y HET nhau
				-- (cung NV, cung khoang nghi) -> khong DISTINCT thi 1 nguoi hien
				-- nhieu lan trong cung 1 o ngay tren calendar
				SELECT DISTINCT
					   CONVERT(VARCHAR(10), N.Ngay, 120),
					   1,
					   vE.EmpName,
					   ISNULL(CASE WHEN @LanguageID = 'VN' THEN WP.VNName ELSE WP.Name END, N'Nghỉ phép'),
					   CONVERT(VARCHAR(5), CONVERT(DATE, L.FromDate), 103) +
					   CASE WHEN CONVERT(DATE, ISNULL(L.ToDate, L.FromDate)) > CONVERT(DATE, L.FromDate)
							THEN ' - ' + CONVERT(VARCHAR(5), CONVERT(DATE, L.ToDate), 103)
							WHEN L.LeaveTaken IS NOT NULL AND L.LeaveTaken < 1 THEN N' (nửa ngày)'
							ELSE N' (cả ngày)' END, L.LSWorkPointID
				FROM LeaveInMonth L
				CROSS APPLY
				(
					SELECT TOP (DATEDIFF(DAY, L.ClipStart, L.ClipEnd) + 1)
						   DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1, L.ClipStart) AS Ngay
					FROM sys.all_objects
				) N
				INNER JOIN dbo.HR_vEmp (NOLOCK) vE ON vE.EmpID = L.EmpID
				LEFT JOIN dbo.LS_tblWorkPoint (NOLOCK) WP ON WP.LSWorkPointID = TRY_CONVERT(INT, L.LSWorkPointID)
				ORDER BY Ngay, HoTen;
			END
			ELSE IF (@ChartID = 'index_card_207')
			BEGIN
				-- CARD: NHAN SU HIEN HUU theo bo loc (chot voi user 05/08/2026):
				-- NV trong universe (StartDate <= cuoi ky, quyen + loc co cau theo QTLV)
				-- va CHUA nghi viec tinh den CUOI KY LOC: khong co TER hoac
				-- TER_tblTermination.EffectDate > @TLGRangeCuoi.
				-- SubFirstValue: ty le tang/giam so voi nhan su hien huu tai cuoi
				-- thang lien truoc. Bo loc quyen/co cau dung chung universe @Employees.
				DECLARE @TLGPreviousMonthEnd DATE = EOMONTH(DATEADD(MONTH, -1, @TLGRangeCuoi));
				DECLARE @TLGCurrentHeadcount INT = 0;
				DECLARE @TLGPreviousHeadcount INT = 0;
				DECLARE @TLGHeadcountChange DECIMAL(18, 2) = 0;

				SELECT @TLGCurrentHeadcount = ISNULL(SUM
					   (
						   CASE
							   WHEN (E.StartDate IS NULL OR CONVERT(DATE, E.StartDate) <= @TLGRangeCuoi)
								AND (TER.FirstEffectDate IS NULL OR TER.FirstEffectDate > @TLGRangeCuoi)
							   THEN 1 ELSE 0
						   END
					   ), 0),
					   @TLGPreviousHeadcount = ISNULL(SUM
					   (
						   CASE
							   WHEN (E.StartDate IS NULL OR CONVERT(DATE, E.StartDate) <= @TLGPreviousMonthEnd)
								AND (TER.FirstEffectDate IS NULL OR TER.FirstEffectDate > @TLGPreviousMonthEnd)
							   THEN 1 ELSE 0
						   END
					   ), 0)
				FROM @Employees Emp
				INNER JOIN dbo.HR_tblEmp E (NOLOCK) ON E.EmpID = Emp.ID
				OUTER APPLY
				(
					SELECT MIN(CONVERT(DATE, T.EffectDate)) AS FirstEffectDate
					FROM dbo.TER_tblTermination T (NOLOCK)
					WHERE T.EmpID = Emp.ID
					AND T.EffectDate IS NOT NULL
				) TER
				WHERE Emp.ID > 0;

				SET @TLGHeadcountChange = CASE
					WHEN @TLGPreviousHeadcount = 0 THEN 0
					ELSE (@TLGCurrentHeadcount - @TLGPreviousHeadcount) * 100.0 / @TLGPreviousHeadcount
				END;

				SELECT CONVERT(NVARCHAR(30), @TLGCurrentHeadcount) AS MainValue,
					   CASE WHEN @TLGHeadcountChange > 0 THEN N'+' ELSE N'' END
					   + CONVERT(NVARCHAR(30), CONVERT(DECIMAL(18, 1), @TLGHeadcountChange))
					   + N'%' AS SubFirstValue,
					   NULL AS SubSecondValue;
			END
			ELSE IF (@ChartID = 'index_card_208')
			BEGIN
				-- CARD: TUYEN MOI TRONG THANG VA SAP NHAN VIEC:
				-- Phan trong ky dung universe @Employees hien tai; phan sap nhan viec
				-- lay truc tiep theo StartDate tuong lai vi cache khong chua NV chua vao lam.
				;WITH CardEmployees AS
				(
					SELECT E.EmpID
					FROM @Employees Emp
					INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = Emp.ID
					WHERE Emp.ID > 0
					AND EXISTS
					(
						SELECT 1 FROM @TLGSelectedPeriods P
						WHERE E.StartDate >= P.PeriodStart AND E.StartDate < P.PeriodEndExclusive
					)

					UNION

					SELECT E.EmpID
					FROM dbo.HR_tblEmp (NOLOCK) E
					OUTER APPLY
					(
						SELECT TOP 1 W.LSCompanyID, W.LSLevel1ID, W.LSLevel2ID, W.LSLevel3ID, W.LSLevel4ID,
							   W.LSLevel5ID, W.LSLevel6ID, W.LSLevel7ID, W.LSLevel8ID, W.LSLevel9ID, W.LSJobTitleID
						FROM dbo.HR_tblWorkingRecord W (NOLOCK)
						WHERE W.EmpID = E.EmpID
						AND W.FromDate <= E.StartDate
						ORDER BY W.FromDate DESC, W.WorkingRecordID DESC
					) WR
					WHERE E.StartDate >= DATEADD(DAY, 1, @dDate)
					AND (NOT EXISTS (SELECT 1 FROM @Companys) OR COALESCE(WR.LSCompanyID, E.LSCompanyID) IN (SELECT ID FROM @Companys))
					AND (NOT EXISTS (SELECT 1 FROM @LoaiChucDanhs) OR EXISTS
					(
						SELECT 1
						FROM dbo.LS_tbljobtitle (NOLOCK) J
						WHERE J.LSJobTitleID = COALESCE(WR.LSJobTitleID, E.LSJobTitleID)
						AND TRY_CONVERT(BIGINT, J.LSLoaiChucDanhID) IN (SELECT ID FROM @LoaiChucDanhs)
					))
					AND (NOT EXISTS (SELECT 1 FROM @Level1s) OR COALESCE(WR.LSLevel1ID, E.LSLevel1ID) IN (SELECT ID FROM @Level1s))
					AND (NOT EXISTS (SELECT 1 FROM @Level2s) OR COALESCE(WR.LSLevel2ID, E.LSLevel2ID) IN (SELECT ID FROM @Level2s))
					AND (NOT EXISTS (SELECT 1 FROM @Level3s) OR COALESCE(WR.LSLevel3ID, E.LSLevel3ID) IN (SELECT ID FROM @Level3s))
					AND (NOT EXISTS (SELECT 1 FROM @Level4s) OR COALESCE(WR.LSLevel4ID, E.LSLevel4ID) IN (SELECT ID FROM @Level4s))
					AND (NOT EXISTS (SELECT 1 FROM @Level5s) OR COALESCE(WR.LSLevel5ID, E.LSLevel5ID) IN (SELECT ID FROM @Level5s))
					AND (NOT EXISTS (SELECT 1 FROM @Level6s) OR COALESCE(WR.LSLevel6ID, E.LSLevel6ID) IN (SELECT ID FROM @Level6s))
					AND (NOT EXISTS (SELECT 1 FROM @Level7s) OR COALESCE(WR.LSLevel7ID, E.LSLevel7ID) IN (SELECT ID FROM @Level7s))
					AND (NOT EXISTS (SELECT 1 FROM @Level8s) OR COALESCE(WR.LSLevel8ID, E.LSLevel8ID) IN (SELECT ID FROM @Level8s))
					AND (NOT EXISTS (SELECT 1 FROM @Level9s) OR COALESCE(WR.LSLevel9ID, E.LSLevel9ID) IN (SELECT ID FROM @Level9s))
					AND EXISTS
					(
						SELECT 1
						FROM dbo.fnGetAllEmp_Permission_EffDate(@UserGroupID, @FunctionID, CONVERT(DATE, E.StartDate)) P
						WHERE P.EmpID = E.EmpID
					)
				)
				SELECT CONVERT(NVARCHAR(30), COUNT(1)) AS MainValue,
					   NULL AS SubFirstValue, NULL AS SubSecondValue
				FROM CardEmployees;
			END
			ELSE IF (@ChartID = 'index_card_209')
			BEGIN
				-- CARD: NGHI VIEC TRONG THANG VA SAP NGHI VIEC:
				-- Phan trong ky dung universe @Employees hien tai; phan sap nghi viec
				-- lay truc tiep theo EffectDate tuong lai va kiem tra quyen tai ngay hieu luc.
				;WITH CardEmployees AS
				(
					SELECT TER.EmpID
					FROM dbo.TER_tblTermination (NOLOCK) TER
					INNER JOIN @Employees Emp ON Emp.ID = TER.EmpID
					WHERE Emp.ID > 0
					AND EXISTS
					(
						SELECT 1 FROM @TLGSelectedPeriods P
						WHERE TER.EffectDate >= P.PeriodStart AND TER.EffectDate < P.PeriodEndExclusive
					)

					UNION

					SELECT TER.EmpID
					FROM dbo.TER_tblTermination (NOLOCK) TER
					INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = TER.EmpID
					OUTER APPLY
					(
						SELECT TOP 1 W.LSCompanyID, W.LSLevel1ID, W.LSLevel2ID, W.LSLevel3ID, W.LSLevel4ID,
							   W.LSLevel5ID, W.LSLevel6ID, W.LSLevel7ID, W.LSLevel8ID, W.LSLevel9ID, W.LSJobTitleID
						FROM dbo.HR_tblWorkingRecord W (NOLOCK)
						WHERE W.EmpID = TER.EmpID
						AND W.FromDate <= TER.EffectDate
						ORDER BY W.FromDate DESC, W.WorkingRecordID DESC
					) WR
					WHERE TER.EffectDate >= DATEADD(DAY, 1, @dDate)
					AND (NOT EXISTS (SELECT 1 FROM @Companys) OR COALESCE(WR.LSCompanyID, E.LSCompanyID) IN (SELECT ID FROM @Companys))
					AND (NOT EXISTS (SELECT 1 FROM @LoaiChucDanhs) OR EXISTS
					(
						SELECT 1
						FROM dbo.LS_tbljobtitle (NOLOCK) J
						WHERE J.LSJobTitleID = COALESCE(WR.LSJobTitleID, E.LSJobTitleID)
						AND TRY_CONVERT(BIGINT, J.LSLoaiChucDanhID) IN (SELECT ID FROM @LoaiChucDanhs)
					))
					AND (NOT EXISTS (SELECT 1 FROM @Level1s) OR COALESCE(WR.LSLevel1ID, E.LSLevel1ID) IN (SELECT ID FROM @Level1s))
					AND (NOT EXISTS (SELECT 1 FROM @Level2s) OR COALESCE(WR.LSLevel2ID, E.LSLevel2ID) IN (SELECT ID FROM @Level2s))
					AND (NOT EXISTS (SELECT 1 FROM @Level3s) OR COALESCE(WR.LSLevel3ID, E.LSLevel3ID) IN (SELECT ID FROM @Level3s))
					AND (NOT EXISTS (SELECT 1 FROM @Level4s) OR COALESCE(WR.LSLevel4ID, E.LSLevel4ID) IN (SELECT ID FROM @Level4s))
					AND (NOT EXISTS (SELECT 1 FROM @Level5s) OR COALESCE(WR.LSLevel5ID, E.LSLevel5ID) IN (SELECT ID FROM @Level5s))
					AND (NOT EXISTS (SELECT 1 FROM @Level6s) OR COALESCE(WR.LSLevel6ID, E.LSLevel6ID) IN (SELECT ID FROM @Level6s))
					AND (NOT EXISTS (SELECT 1 FROM @Level7s) OR COALESCE(WR.LSLevel7ID, E.LSLevel7ID) IN (SELECT ID FROM @Level7s))
					AND (NOT EXISTS (SELECT 1 FROM @Level8s) OR COALESCE(WR.LSLevel8ID, E.LSLevel8ID) IN (SELECT ID FROM @Level8s))
					AND (NOT EXISTS (SELECT 1 FROM @Level9s) OR COALESCE(WR.LSLevel9ID, E.LSLevel9ID) IN (SELECT ID FROM @Level9s))
					AND EXISTS
					(
						SELECT 1
						FROM dbo.fnGetAllEmp_Permission_EffDate(@UserGroupID, @FunctionID, CONVERT(DATE, TER.EffectDate)) P
						WHERE P.EmpID = TER.EmpID
					)
				)
				SELECT CONVERT(NVARCHAR(30), COUNT(1)) AS MainValue,
					   NULL AS SubFirstValue, NULL AS SubSecondValue
				FROM CardEmployees;
			END
			ELSE IF (@ChartID = 'index_card_210')
			BEGIN
				-- CARD: TONG QUY LUONG (chot voi user 07/08/2026) - 1 SO TONG cho toan
				-- universe @Employees, KHONG gom theo Farm/Feed/Food nhu main_chart_202
				-- (chart 202 la breakdown, card nay la TONG chung):
				--   TongLuong = PR_tblSalary.TongLuong (giai ma sys_fnGetD) ban ghi
				--               hieu luc NHO NHAT VA GAN NHAT <= cuoi ky bao cao (FID 4090)
				--   + TongPhuCap = SUM PR_tblAddSalaryEmp.Amount (giai ma) nhom
				--               LS_tblAdd_Salary.LSAddSalaryGroupID = 1 "phu cap" (FID 2128)
				-- Chi tinh NV DANG LAM VIEC tai cuoi ky (dong bo TER voi card 207/main_chart_202).
				-- FORMAT ...,'N0','en-us' -> dau phay ngan chuc ngan kieu "1,000,000"
				-- (chot voi user 07/08/2026 - so tien lon phai co dau phan cach, khong de so tho).
				SELECT FORMAT(CONVERT(BIGINT, ISNULL(SUM(ISNULL(SL.TongLuong, 0) + ISNULL(PC.PhuCap, 0)), 0)), N'N0', 'en-us') AS MainValue,
					   NULL AS SubFirstValue, NULL AS SubSecondValue
				FROM @Employees Emp
				OUTER APPLY
				(
					SELECT TOP 1 CONVERT(FLOAT, dbo.sys_fnGetD(S.TongLuong)) AS TongLuong
					FROM dbo.PR_tblSalary S (NOLOCK)
					WHERE S.EmpID = Emp.ID AND S.FromDate <= @TLGRangeCuoi
					ORDER BY S.FromDate DESC
				) SL
				OUTER APPLY
				(
					SELECT SUM(CONVERT(FLOAT, dbo.sys_fnGetD(A.Amount))) AS PhuCap
					FROM dbo.PR_tblAddSalaryEmp A (NOLOCK)
					INNER JOIN dbo.LS_tblAdd_Salary L (NOLOCK) ON L.LSAddSalaryID = A.LSAddSalaryID
					WHERE A.EmpID = Emp.ID
					AND L.LSAddSalaryGroupID = 1
					AND A.FromDate <= @TLGRangeCuoi
					AND (A.ToDate IS NULL OR A.ToDate >= @TLGRangeDau)
				) PC
				WHERE Emp.ID > 0
				AND NOT EXISTS
				(
					SELECT 1 FROM dbo.TER_tblTermination (NOLOCK) TER
					WHERE TER.EmpID = Emp.ID
					AND TER.EffectDate IS NOT NULL
					AND CONVERT(DATE, TER.EffectDate) <= @TLGRangeCuoi
				);
			END
		END
		ELSE IF (@ChartID = 'main_chart_1')
		BEGIN
			PRINT(N'Not Yet')
		END
		ELSE IF (@ChartID = 'main_chart_2')
		BEGIN
			-- Chart "Tong nhan su dien bien theo tung thang trong nam"
			-- Sinh 12 thang cho TUNG nam duoc chon (multi-year => moi nam 1 duong).
			-- Thang da ket thuc: moc = ngay cuoi thang; Thang hien tai: moc = ngay hien tai (LastDateTimeline).
			-- Hien dien: StartDate <= PeriodEnd AND (EffectDate > PeriodEnd OR EffectDate NULL).
			DECLARE @C2YrTmp tID;
			DECLARE @C2QtrTmp tID;
			DECLARE @C2MoTmp tID;
			DECLARE @C2Res TABLE (FilterType VARCHAR(10), Value INT);
			DECLARE @C2YearList TABLE (rn INT IDENTITY(1,1), Yr INT);
			DECLARE @C2Periods TABLE
			(
				RowID INT IDENTITY(1,1),
				Years INT,
				Months INT NULL,
				GeneralName NVARCHAR(50),
				PeriodEnd DATE
			);
			DECLARE @C2_i INT = 1;
			DECLARE @C2_cnt INT;
			DECLARE @C2_curYr INT;

			INSERT INTO @C2YearList (Yr)
			SELECT DISTINCT ID FROM @Years ORDER BY ID;

			IF NOT EXISTS (SELECT 1 FROM @C2YearList)
				INSERT INTO @C2YearList (Yr) VALUES (YEAR(@dDate));

			SET @C2_cnt = (SELECT COUNT(1) FROM @C2YearList);

			WHILE @C2_i <= @C2_cnt
			BEGIN
				SET @C2_curYr = (SELECT Yr FROM @C2YearList WHERE rn = @C2_i);
				DELETE FROM @C2YrTmp;
				DELETE FROM @C2QtrTmp;
				DELETE FROM @C2MoTmp;
				DELETE FROM @C2Res;

				INSERT INTO @C2YrTmp (ID) VALUES (@C2_curYr);
				INSERT INTO @C2QtrTmp (ID) SELECT ID FROM @Quarters;
				INSERT INTO @C2MoTmp (ID) SELECT ID FROM @Months;

				INSERT INTO @C2Res
				SELECT * FROM dbo.NEW_fnTableResolveTimeFilter(@C2YrTmp, @C2QtrTmp, @C2MoTmp);

				DELETE FROM @C2MoTmp;
				INSERT INTO @C2MoTmp
				SELECT DISTINCT Value FROM @C2Res WHERE FilterType = 'MONTH';

				-- Chart 2 must always render monthly points. Quarter filter is resolved to months above.
				DELETE FROM @C2QtrTmp;

				INSERT INTO @C2Periods (Years, Months, GeneralName, PeriodEnd)
				SELECT g.Years, g.Months, g.GeneralName,
					   CONVERT(DATE, COALESCE(
						   TRY_CONVERT(DATETIME, g.LastDateTimeline, 103),
						   TRY_CONVERT(DATETIME, g.NgayChotCongGanNhat, 103)
					   ))
				FROM dbo.NEW_fnTableGenerateChuKyCong(@C2YrTmp, @C2QtrTmp, @C2MoTmp, @dDate) g
				ORDER BY g.Months;

				SET @C2_i = @C2_i + 1;
			END

			;WITH Eligible AS
			(
				SELECT DISTINCT P.RowID, E.EmpID
				FROM @C2Periods P
				CROSS APPLY dbo.fnGetAllEmp_Permission_EffDate(@UserGroupID, @FunctionID, P.PeriodEnd) PQ
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = PQ.EmpID
				WHERE P.PeriodEnd IS NOT NULL
				AND (E.StartDate IS NULL OR CONVERT(DATE, E.StartDate) <= P.PeriodEnd)
				AND (NOT EXISTS (SELECT 1 FROM @Companys) OR E.LSCompanyID IN (SELECT ID FROM @Companys))
				AND (NOT EXISTS (SELECT 1 FROM @LoaiChucDanhs) OR TRY_CONVERT(BIGINT, E.LSLoaiChucDanhID) IN (SELECT ID FROM @LoaiChucDanhs))
				AND (NOT EXISTS (SELECT 1 FROM @Level1s) OR E.LSLevel1ID IN (SELECT ID FROM @Level1s))
				AND (NOT EXISTS (SELECT 1 FROM @Level2s) OR E.LSLevel2ID IN (SELECT ID FROM @Level2s))
				AND (NOT EXISTS (SELECT 1 FROM @Level3s) OR E.LSLevel3ID IN (SELECT ID FROM @Level3s))
				AND (NOT EXISTS (SELECT 1 FROM @Level4s) OR E.LSLevel4ID IN (SELECT ID FROM @Level4s))
				AND (NOT EXISTS (SELECT 1 FROM @Level5s) OR E.LSLevel5ID IN (SELECT ID FROM @Level5s))
				AND (NOT EXISTS (SELECT 1 FROM @Level6s) OR E.LSLevel6ID IN (SELECT ID FROM @Level6s))
				AND (NOT EXISTS (SELECT 1 FROM @Level7s) OR E.LSLevel7ID IN (SELECT ID FROM @Level7s))
				AND (NOT EXISTS (SELECT 1 FROM @Level8s) OR E.LSLevel8ID IN (SELECT ID FROM @Level8s))
				AND (NOT EXISTS (SELECT 1 FROM @Level9s) OR E.LSLevel9ID IN (SELECT ID FROM @Level9s))
				AND NOT EXISTS
				(
					SELECT 1
					FROM dbo.TER_tblTermination (NOLOCK) TER
					WHERE TER.EmpID = E.EmpID
					AND TER.EffectDate IS NOT NULL
					AND CONVERT(DATE, TER.EffectDate) <= P.PeriodEnd
				)
			)
			SELECT	P.RowID,
					P.GeneralName AS TimeLine,
					P.GeneralName,
					P.Years,
					P.Months,
					COUNT(E.EmpID) AS [Value]
			FROM @C2Periods P
			LEFT JOIN Eligible E ON E.RowID = P.RowID
			GROUP BY P.RowID, P.GeneralName, P.Years, P.Months
			ORDER BY P.RowID
		END
		ELSE IF (@ChartID IN ('main_chart_83', 'main_chart_303')) -- 303: alias doi kieu chart (funnel) - dung chung logic voi 83, xem HANDOFF.md
		BEGIN
			DECLARE @ContractSummaryDate DATE = CONVERT(DATE, COALESCE(@ChartLastDateTimeLine, @ChartNgayChotCongGanNhat, @dDate));

			IF NOT EXISTS (SELECT 1 FROM @Employees WHERE ID > 0)
			BEGIN
				INSERT INTO @Employees (ID)
				SELECT DISTINCT P.EmpID
				FROM dbo.fnGetAllEmp_Permission_EffDate(@UserGroupID, @FunctionID, @ContractSummaryDate) P
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = P.EmpID
				WHERE (E.StartDate IS NULL OR CONVERT(DATE, E.StartDate) <= @ContractSummaryDate)
				AND (NOT EXISTS (SELECT 1 FROM @Companys) OR E.LSCompanyID IN (SELECT ID FROM @Companys))
				AND (NOT EXISTS (SELECT 1 FROM @LoaiChucDanhs) OR E.LSLoaiChucDanhID IN (SELECT ID FROM @LoaiChucDanhs))
				AND (NOT EXISTS (SELECT 1 FROM @Level1s) OR E.LSLevel1ID IN (SELECT ID FROM @Level1s))
				AND (NOT EXISTS (SELECT 1 FROM @Level2s) OR E.LSLevel2ID IN (SELECT ID FROM @Level2s))
				AND (NOT EXISTS (SELECT 1 FROM @Level3s) OR E.LSLevel3ID IN (SELECT ID FROM @Level3s))
				AND (NOT EXISTS (SELECT 1 FROM @Level4s) OR E.LSLevel4ID IN (SELECT ID FROM @Level4s))
				AND (NOT EXISTS (SELECT 1 FROM @Level5s) OR E.LSLevel5ID IN (SELECT ID FROM @Level5s))
				AND (NOT EXISTS (SELECT 1 FROM @Level6s) OR E.LSLevel6ID IN (SELECT ID FROM @Level6s))
				AND (NOT EXISTS (SELECT 1 FROM @Level7s) OR E.LSLevel7ID IN (SELECT ID FROM @Level7s))
				AND (NOT EXISTS (SELECT 1 FROM @Level8s) OR E.LSLevel8ID IN (SELECT ID FROM @Level8s))
				AND (NOT EXISTS (SELECT 1 FROM @Level9s) OR E.LSLevel9ID IN (SELECT ID FROM @Level9s));
			END

			-- Start Rlog: 33306 - TanND35 - 29/10/2026
			-- NV dang lam viec chot vao bang tam co PK truoc, roi LEFT JOIN 1 lan hop dong moi nhat
			-- (CTE NV dung 2 lan lam plan tinh lai nhieu lan: do DEV 27.8s -> 26ms, ket qua khong doi).
			IF OBJECT_ID('tempdb..#TLG303NV') IS NOT NULL DROP TABLE #TLG303NV;
			CREATE TABLE #TLG303NV (EmpID INT NOT NULL PRIMARY KEY);

			INSERT INTO #TLG303NV (EmpID)
			SELECT DISTINCT E.EmpID
			FROM @Employees A
			INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = A.ID
			WHERE A.ID > 0
			AND (E.StartDate IS NULL OR CONVERT(DATE, E.StartDate) <= @ContractSummaryDate)
			AND NOT EXISTS
			(
				SELECT 1
				FROM dbo.TER_tblTermination (NOLOCK) TER
				WHERE TER.EmpID = E.EmpID
				AND TER.EffectDate IS NOT NULL AND CONVERT(DATE, TER.EffectDate) <= @ContractSummaryDate
			);

			;WITH EmployeeContract AS
			(
				SELECT	CT.EmpID,
						CT.LSContractTypeID,
						ROW_NUMBER() OVER(PARTITION BY CT.EmpID ORDER BY CT.EffectiveDate DESC, CT.ContractID DESC) AS RowNo
				FROM dbo.HR_tblContract (NOLOCK) CT
				WHERE CT.EffectiveDate IS NOT NULL
				AND CT.EffectiveDate < DATEADD(DAY, 1, @ContractSummaryDate)
			)
			SELECT	ISNULL(CASE WHEN @LanguageID = 'VN' THEN L.VNName ELSE L.Name END, N'Không xác định') AS Category,
					COUNT(1) AS [Value],
					CONVERT(VARCHAR(10), @ContractSummaryDate, 120) AS SummaryDate,
					N'T' + RIGHT('0' + CONVERT(VARCHAR(2), MONTH(@ContractSummaryDate)), 2) + N'/' + CONVERT(VARCHAR(4), YEAR(@ContractSummaryDate)) AS SummaryLabel
			FROM #TLG303NV P
			LEFT JOIN EmployeeContract EC ON EC.EmpID = P.EmpID AND EC.RowNo = 1
			LEFT JOIN dbo.LS_tblContractType (NOLOCK) L ON L.LSContractTypeID = EC.LSContractTypeID
			GROUP BY ISNULL(CASE WHEN @LanguageID = 'VN' THEN L.VNName ELSE L.Name END, N'Không xác định')
			ORDER BY [Value] DESC, Category;

			DROP TABLE #TLG303NV;
			-- End Rlog: 33306
		END
		ELSE IF (@ChartID IN ('main_chart_84', 'main_chart_304')) -- 304: alias doi kieu chart (horizontal bar) - dung chung logic voi 84
		BEGIN
			DECLARE @JobGroupSummaryDate DATE = CONVERT(DATE, COALESCE(@ChartLastDateTimeLine, @ChartNgayChotCongGanNhat, @dDate));

			IF NOT EXISTS (SELECT 1 FROM @Employees WHERE ID > 0)
			BEGIN
				INSERT INTO @Employees (ID)
				SELECT DISTINCT P.EmpID
				FROM dbo.fnGetAllEmp_Permission_EffDate(@UserGroupID, @FunctionID, @JobGroupSummaryDate) P
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = P.EmpID
				WHERE (E.StartDate IS NULL OR CONVERT(DATE, E.StartDate) <= @JobGroupSummaryDate)
				AND (NOT EXISTS (SELECT 1 FROM @Companys) OR E.LSCompanyID IN (SELECT ID FROM @Companys))
				AND (NOT EXISTS (SELECT 1 FROM @LoaiChucDanhs) OR E.LSLoaiChucDanhID IN (SELECT ID FROM @LoaiChucDanhs))
				AND (NOT EXISTS (SELECT 1 FROM @Level1s) OR E.LSLevel1ID IN (SELECT ID FROM @Level1s))
				AND (NOT EXISTS (SELECT 1 FROM @Level2s) OR E.LSLevel2ID IN (SELECT ID FROM @Level2s))
				AND (NOT EXISTS (SELECT 1 FROM @Level3s) OR E.LSLevel3ID IN (SELECT ID FROM @Level3s))
				AND (NOT EXISTS (SELECT 1 FROM @Level4s) OR E.LSLevel4ID IN (SELECT ID FROM @Level4s))
				AND (NOT EXISTS (SELECT 1 FROM @Level5s) OR E.LSLevel5ID IN (SELECT ID FROM @Level5s))
				AND (NOT EXISTS (SELECT 1 FROM @Level6s) OR E.LSLevel6ID IN (SELECT ID FROM @Level6s))
				AND (NOT EXISTS (SELECT 1 FROM @Level7s) OR E.LSLevel7ID IN (SELECT ID FROM @Level7s))
				AND (NOT EXISTS (SELECT 1 FROM @Level8s) OR E.LSLevel8ID IN (SELECT ID FROM @Level8s))
				AND (NOT EXISTS (SELECT 1 FROM @Level9s) OR E.LSLevel9ID IN (SELECT ID FROM @Level9s));
			END

			-- Nửa khoảng [<= @JobGroupSummaryDate] = [< ngày kế tiếp] de giu sargable (khong CONVERT(DATE) tren cot)
			DECLARE @JobGroupNextDay DATE = DATEADD(DAY, 1, @JobGroupSummaryDate);

			;WITH PresentEmployees AS
			(
				SELECT DISTINCT E.EmpID
				FROM @Employees A
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = A.ID
				WHERE A.ID > 0
				AND (E.StartDate IS NULL OR E.StartDate < @JobGroupNextDay)
				AND NOT EXISTS
				(
					SELECT 1
					FROM dbo.TER_tblTermination (NOLOCK) TER
					WHERE TER.EmpID = E.EmpID
					AND TER.EffectDate IS NOT NULL AND TER.EffectDate < @JobGroupNextDay
				)
			)
			SELECT	ISNULL(CASE WHEN @LanguageID = 'VN' THEN CB.VNName ELSE CB.Name END, N'Không xác định') AS Category,
					COUNT(1) AS [Value],
					CONVERT(VARCHAR(10), @JobGroupSummaryDate, 120) AS SummaryDate,
					N'T' + RIGHT('0' + CONVERT(VARCHAR(2), MONTH(@JobGroupSummaryDate)), 2) + N'/' + CONVERT(VARCHAR(4), YEAR(@JobGroupSummaryDate)) AS SummaryLabel
			FROM PresentEmployees P
			-- Lay 1 ban ghi qua trinh moi nhat con hieu luc tai ngay tong hop cho tung NV:
			-- seek theo (EmpID, FromDate) -> bo qua Sort toan bang cua ROW_NUMBER cu.
			OUTER APPLY
			(
				SELECT TOP (1) WR.LSJobTitleID
				FROM dbo.HR_tblWorkingRecord (NOLOCK) WR
				WHERE WR.EmpID = P.EmpID
				AND WR.LSJobTitleID IS NOT NULL
				AND ISNULL(WR.FromDate, WR.NgayHieuLuc) IS NOT NULL
				AND ISNULL(WR.FromDate, WR.NgayHieuLuc) < @JobGroupNextDay
				AND (WR.ToDate IS NULL OR WR.ToDate >= @JobGroupSummaryDate)
				ORDER BY ISNULL(WR.FromDate, WR.NgayHieuLuc) DESC, WR.WorkingRecordID DESC
			) WR
			LEFT JOIN dbo.LS_tblJobTitle (NOLOCK) JT ON JT.LSJobTitleID = WR.LSJobTitleID
			LEFT JOIN dbo.LS_tblCapBacChucDanh (NOLOCK) CB ON CB.LSCapBacChucDanhID = JT.LSCapBacChucDanhID
			GROUP BY ISNULL(CASE WHEN @LanguageID = 'VN' THEN CB.VNName ELSE CB.Name END, N'Không xác định')
			ORDER BY [Value] DESC, Category;
		END
		ELSE IF (@ChartID = 'main_chart_86')
		BEGIN
			DECLARE @GenderSummaryDate DATE = CONVERT(DATE, COALESCE(@ChartLastDateTimeLine, @ChartNgayChotCongGanNhat, @dDate));

			IF NOT EXISTS (SELECT 1 FROM @Employees WHERE ID > 0)
			BEGIN
				INSERT INTO @Employees (ID)
				SELECT DISTINCT P.EmpID
				FROM dbo.fnGetAllEmp_Permission_EffDate(@UserGroupID, @FunctionID, @GenderSummaryDate) P
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = P.EmpID
				WHERE (E.StartDate IS NULL OR CONVERT(DATE, E.StartDate) <= @GenderSummaryDate)
				AND (NOT EXISTS (SELECT 1 FROM @Companys) OR E.LSCompanyID IN (SELECT ID FROM @Companys))
				AND (NOT EXISTS (SELECT 1 FROM @LoaiChucDanhs) OR E.LSLoaiChucDanhID IN (SELECT ID FROM @LoaiChucDanhs))
				AND (NOT EXISTS (SELECT 1 FROM @Level1s) OR E.LSLevel1ID IN (SELECT ID FROM @Level1s))
				AND (NOT EXISTS (SELECT 1 FROM @Level2s) OR E.LSLevel2ID IN (SELECT ID FROM @Level2s))
				AND (NOT EXISTS (SELECT 1 FROM @Level3s) OR E.LSLevel3ID IN (SELECT ID FROM @Level3s))
				AND (NOT EXISTS (SELECT 1 FROM @Level4s) OR E.LSLevel4ID IN (SELECT ID FROM @Level4s))
				AND (NOT EXISTS (SELECT 1 FROM @Level5s) OR E.LSLevel5ID IN (SELECT ID FROM @Level5s))
				AND (NOT EXISTS (SELECT 1 FROM @Level6s) OR E.LSLevel6ID IN (SELECT ID FROM @Level6s))
				AND (NOT EXISTS (SELECT 1 FROM @Level7s) OR E.LSLevel7ID IN (SELECT ID FROM @Level7s))
				AND (NOT EXISTS (SELECT 1 FROM @Level8s) OR E.LSLevel8ID IN (SELECT ID FROM @Level8s))
				AND (NOT EXISTS (SELECT 1 FROM @Level9s) OR E.LSLevel9ID IN (SELECT ID FROM @Level9s));
			END

			;WITH PresentEmployees AS
			(
				SELECT DISTINCT E.EmpID
				FROM @Employees A
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = A.ID
				WHERE A.ID > 0
				AND (E.StartDate IS NULL OR CONVERT(DATE, E.StartDate) <= @GenderSummaryDate)
				AND NOT EXISTS
				(
					SELECT 1
					FROM dbo.TER_tblTermination (NOLOCK) TER
					WHERE TER.EmpID = E.EmpID
					AND TER.EffectDate IS NOT NULL AND CONVERT(DATE, TER.EffectDate) <= @GenderSummaryDate
				)
			)
			SELECT	ISNULL(CASE WHEN @LanguageID = 'VN' THEN G.VNName ELSE G.Name END, N'Không xác định') AS Category,
					COUNT(1) AS [Value],
					CONVERT(VARCHAR(10), @GenderSummaryDate, 120) AS SummaryDate,
					N'T' + RIGHT('0' + CONVERT(VARCHAR(2), MONTH(@GenderSummaryDate)), 2) + N'/' + CONVERT(VARCHAR(4), YEAR(@GenderSummaryDate)) AS SummaryLabel
			FROM PresentEmployees P
			LEFT JOIN dbo.HR_tblEmpCV (NOLOCK) CV ON CV.EmpID = P.EmpID
			LEFT JOIN dbo.LS_tblGender (NOLOCK) G ON G.ID = CV.Gender
			GROUP BY ISNULL(CASE WHEN @LanguageID = 'VN' THEN G.VNName ELSE G.Name END, N'Không xác định')
			ORDER BY [Value] DESC, Category;
		END
		-- 33306RLOG TLG (13/08/2026 khuya #7): 2 chart MOI theo yeu cau "man 6565
		-- can truc quan/day du hon" - cau truc COPY Y HET main_chart_86 (Gioi tinh)
		-- phia tren, chi doi bang danh muc GROUP BY. Dang ky catalog + FID rieng
		-- qua TLG_33306_add_hr_charts_batch1.sql (xem file do de biet ChartID nao
		-- map vao day - 'main_chart_301'=Dan toc, 'main_chart_302'=Trinh do CM).
		ELSE IF (@ChartID = 'main_chart_301')
		BEGIN
			DECLARE @DanTocSummaryDate DATE = CONVERT(DATE, COALESCE(@ChartLastDateTimeLine, @ChartNgayChotCongGanNhat, @dDate));

			IF NOT EXISTS (SELECT 1 FROM @Employees WHERE ID > 0)
			BEGIN
				INSERT INTO @Employees (ID)
				SELECT DISTINCT P.EmpID
				FROM dbo.fnGetAllEmp_Permission_EffDate(@UserGroupID, @FunctionID, @DanTocSummaryDate) P
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = P.EmpID
				WHERE (E.StartDate IS NULL OR CONVERT(DATE, E.StartDate) <= @DanTocSummaryDate)
				AND (NOT EXISTS (SELECT 1 FROM @Companys) OR E.LSCompanyID IN (SELECT ID FROM @Companys))
				AND (NOT EXISTS (SELECT 1 FROM @LoaiChucDanhs) OR E.LSLoaiChucDanhID IN (SELECT ID FROM @LoaiChucDanhs))
				AND (NOT EXISTS (SELECT 1 FROM @Level1s) OR E.LSLevel1ID IN (SELECT ID FROM @Level1s))
				AND (NOT EXISTS (SELECT 1 FROM @Level2s) OR E.LSLevel2ID IN (SELECT ID FROM @Level2s))
				AND (NOT EXISTS (SELECT 1 FROM @Level3s) OR E.LSLevel3ID IN (SELECT ID FROM @Level3s))
				AND (NOT EXISTS (SELECT 1 FROM @Level4s) OR E.LSLevel4ID IN (SELECT ID FROM @Level4s))
				AND (NOT EXISTS (SELECT 1 FROM @Level5s) OR E.LSLevel5ID IN (SELECT ID FROM @Level5s))
				AND (NOT EXISTS (SELECT 1 FROM @Level6s) OR E.LSLevel6ID IN (SELECT ID FROM @Level6s))
				AND (NOT EXISTS (SELECT 1 FROM @Level7s) OR E.LSLevel7ID IN (SELECT ID FROM @Level7s))
				AND (NOT EXISTS (SELECT 1 FROM @Level8s) OR E.LSLevel8ID IN (SELECT ID FROM @Level8s))
				AND (NOT EXISTS (SELECT 1 FROM @Level9s) OR E.LSLevel9ID IN (SELECT ID FROM @Level9s));
			END

			;WITH PresentEmployees AS
			(
				SELECT DISTINCT E.EmpID
				FROM @Employees A
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = A.ID
				WHERE A.ID > 0
				AND (E.StartDate IS NULL OR CONVERT(DATE, E.StartDate) <= @DanTocSummaryDate)
				AND NOT EXISTS
				(
					SELECT 1
					FROM dbo.TER_tblTermination (NOLOCK) TER
					WHERE TER.EmpID = E.EmpID
					AND TER.EffectDate IS NOT NULL AND CONVERT(DATE, TER.EffectDate) <= @DanTocSummaryDate
				)
			)
			SELECT	ISNULL(CASE WHEN @LanguageID = 'VN' THEN ETH.VNName ELSE ETH.Name END, N'Không xác định') AS Category,
					COUNT(1) AS [Value],
					CONVERT(VARCHAR(10), @DanTocSummaryDate, 120) AS SummaryDate,
					N'T' + RIGHT('0' + CONVERT(VARCHAR(2), MONTH(@DanTocSummaryDate)), 2) + N'/' + CONVERT(VARCHAR(4), YEAR(@DanTocSummaryDate)) AS SummaryLabel
			FROM PresentEmployees P
			LEFT JOIN dbo.HR_tblEmpCV (NOLOCK) CV ON CV.EmpID = P.EmpID
			LEFT JOIN dbo.LS_tblEthnic (NOLOCK) ETH ON ETH.LSEthnicID = CV.LSEthnicID
			GROUP BY ISNULL(CASE WHEN @LanguageID = 'VN' THEN ETH.VNName ELSE ETH.Name END, N'Không xác định')
			ORDER BY [Value] DESC, Category;
		END
		ELSE IF (@ChartID = 'main_chart_302')
		BEGIN
			DECLARE @TrinhDoCMSummaryDate DATE = CONVERT(DATE, COALESCE(@ChartLastDateTimeLine, @ChartNgayChotCongGanNhat, @dDate));

			IF NOT EXISTS (SELECT 1 FROM @Employees WHERE ID > 0)
			BEGIN
				INSERT INTO @Employees (ID)
				SELECT DISTINCT P.EmpID
				FROM dbo.fnGetAllEmp_Permission_EffDate(@UserGroupID, @FunctionID, @TrinhDoCMSummaryDate) P
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = P.EmpID
				WHERE (E.StartDate IS NULL OR CONVERT(DATE, E.StartDate) <= @TrinhDoCMSummaryDate)
				AND (NOT EXISTS (SELECT 1 FROM @Companys) OR E.LSCompanyID IN (SELECT ID FROM @Companys))
				AND (NOT EXISTS (SELECT 1 FROM @LoaiChucDanhs) OR E.LSLoaiChucDanhID IN (SELECT ID FROM @LoaiChucDanhs))
				AND (NOT EXISTS (SELECT 1 FROM @Level1s) OR E.LSLevel1ID IN (SELECT ID FROM @Level1s))
				AND (NOT EXISTS (SELECT 1 FROM @Level2s) OR E.LSLevel2ID IN (SELECT ID FROM @Level2s))
				AND (NOT EXISTS (SELECT 1 FROM @Level3s) OR E.LSLevel3ID IN (SELECT ID FROM @Level3s))
				AND (NOT EXISTS (SELECT 1 FROM @Level4s) OR E.LSLevel4ID IN (SELECT ID FROM @Level4s))
				AND (NOT EXISTS (SELECT 1 FROM @Level5s) OR E.LSLevel5ID IN (SELECT ID FROM @Level5s))
				AND (NOT EXISTS (SELECT 1 FROM @Level6s) OR E.LSLevel6ID IN (SELECT ID FROM @Level6s))
				AND (NOT EXISTS (SELECT 1 FROM @Level7s) OR E.LSLevel7ID IN (SELECT ID FROM @Level7s))
				AND (NOT EXISTS (SELECT 1 FROM @Level8s) OR E.LSLevel8ID IN (SELECT ID FROM @Level8s))
				AND (NOT EXISTS (SELECT 1 FROM @Level9s) OR E.LSLevel9ID IN (SELECT ID FROM @Level9s));
			END

			-- CAP NHAT (13/08/2026 khuya #12): user phan hoi "de 1 hang cong ty thi ky
			-- qua" - THEM Level1 (don vi cap 1) de tach ra NHIEU HANG thay vi don 1
			-- hang "Toan cong ty" nhu truoc. Level1 lay tu QUA TRINH LAM VIEC hieu luc
			-- gan nhat <= ngay tong hop (dung pattern OUTER APPLY nhu main_chart_84/304).
			;WITH PresentEmployees AS
			(
				SELECT DISTINCT E.EmpID
				FROM @Employees A
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = A.ID
				WHERE A.ID > 0
				AND (E.StartDate IS NULL OR CONVERT(DATE, E.StartDate) <= @TrinhDoCMSummaryDate)
				AND NOT EXISTS
				(
					SELECT 1
					FROM dbo.TER_tblTermination (NOLOCK) TER
					WHERE TER.EmpID = E.EmpID
					AND TER.EffectDate IS NOT NULL AND CONVERT(DATE, TER.EffectDate) <= @TrinhDoCMSummaryDate
				)
			)
			SELECT	ISNULL(CASE WHEN @LanguageID = 'VN' THEN L1.VNName ELSE L1.Name END, N'Không xác định') AS Level1Name,
					ISNULL(CASE WHEN @LanguageID = 'VN' THEN PL.VNName ELSE PL.Name END, N'Không xác định') AS Category,
					COUNT(1) AS [Value],
					CONVERT(VARCHAR(10), @TrinhDoCMSummaryDate, 120) AS SummaryDate,
					N'T' + RIGHT('0' + CONVERT(VARCHAR(2), MONTH(@TrinhDoCMSummaryDate)), 2) + N'/' + CONVERT(VARCHAR(4), YEAR(@TrinhDoCMSummaryDate)) AS SummaryLabel
			FROM PresentEmployees P
			LEFT JOIN dbo.HR_tblEmpCV (NOLOCK) CV ON CV.EmpID = P.EmpID
			LEFT JOIN dbo.LS_tblProfessionalLevel (NOLOCK) PL ON PL.LSProfessionalLevelID = CV.LSProfessionalLevelID
			OUTER APPLY
			(
				SELECT TOP 1 WR.LSLevel1ID
				FROM dbo.HR_tblWorkingRecord (NOLOCK) WR
				WHERE WR.EmpID = P.EmpID
				AND ISNULL(WR.FromDate, WR.NgayHieuLuc) IS NOT NULL
				AND ISNULL(WR.FromDate, WR.NgayHieuLuc) <= @TrinhDoCMSummaryDate
				ORDER BY ISNULL(WR.FromDate, WR.NgayHieuLuc) DESC, WR.WorkingRecordID DESC
			) WR
			LEFT JOIN dbo.LS_tblLevel1 (NOLOCK) L1 ON L1.LSLevel1ID = WR.LSLevel1ID
			GROUP BY ISNULL(CASE WHEN @LanguageID = 'VN' THEN L1.VNName ELSE L1.Name END, N'Không xác định'),
					 ISNULL(CASE WHEN @LanguageID = 'VN' THEN PL.VNName ELSE PL.Name END, N'Không xác định')
			ORDER BY Level1Name, Category;
		END
		ELSE IF (@ChartID = 'main_chart_90')
		BEGIN
			DECLARE @TermLatestYear INT = NULL,
					@TermLatestQuarter INT = NULL,
					@TermLatestMonth INT = NULL,
					@TermScope CHAR(1) = NULL,
					@TermSummaryLabel NVARCHAR(50) = NULL;

			DECLARE @TermPeriods TABLE
			(
				PeriodLabel NVARCHAR(50),
				PeriodStart DATE,
				PeriodEnd DATE,
				PeriodSort INT
			);

			IF EXISTS (SELECT 1 FROM @tblChartChuKyCong WHERE Months IS NOT NULL)
			BEGIN
				SELECT TOP 1 @TermLatestYear = Years, @TermLatestMonth = Months
				FROM @tblChartChuKyCong
				WHERE Years IS NOT NULL AND Months IS NOT NULL
				ORDER BY Years DESC, Months DESC;

				SET @TermScope = 'M';
				INSERT INTO @TermPeriods (PeriodLabel, PeriodStart, PeriodEnd, PeriodSort)
				SELECT N'Tháng ' + CONVERT(NVARCHAR(2), @TermLatestMonth),
					   DATEFROMPARTS(@TermLatestYear, @TermLatestMonth, 1),
					   EOMONTH(DATEFROMPARTS(@TermLatestYear, @TermLatestMonth, 1)),
					   @TermLatestMonth;

				SET @TermSummaryLabel = N'Tháng ' + CONVERT(NVARCHAR(2), @TermLatestMonth) + N'/' + CONVERT(NVARCHAR(4), @TermLatestYear);
			END
			ELSE IF EXISTS (SELECT 1 FROM @tblChartChuKyCong WHERE Quarters IS NOT NULL)
			BEGIN
				SELECT TOP 1 @TermLatestYear = Years, @TermLatestQuarter = Quarters
				FROM @tblChartChuKyCong
				WHERE Years IS NOT NULL AND Quarters IS NOT NULL
				ORDER BY Years DESC, Quarters DESC;

				SET @TermScope = 'Q';
				DECLARE @TermQuarterStartMonth INT = ((@TermLatestQuarter - 1) * 3) + 1;
				INSERT INTO @TermPeriods (PeriodLabel, PeriodStart, PeriodEnd, PeriodSort)
				SELECT N'Tháng ' + CONVERT(NVARCHAR(2), V.MonthNo),
					   DATEFROMPARTS(@TermLatestYear, V.MonthNo, 1),
					   EOMONTH(DATEFROMPARTS(@TermLatestYear, V.MonthNo, 1)),
					   V.MonthNo
				FROM (VALUES (@TermQuarterStartMonth), (@TermQuarterStartMonth + 1), (@TermQuarterStartMonth + 2)) V(MonthNo);

				SET @TermSummaryLabel = N'Quý ' + CONVERT(NVARCHAR(2), @TermLatestQuarter) + N'/' + CONVERT(NVARCHAR(4), @TermLatestYear);
			END
			ELSE
			BEGIN
				SELECT @TermLatestYear = MAX(Years)
				FROM @tblChartChuKyCong
				WHERE Years IS NOT NULL;

				SET @TermLatestYear = ISNULL(@TermLatestYear, YEAR(ISNULL(@ChartNgayChotCongGanNhat, @dDate)));
				SET @TermScope = 'Y';

				INSERT INTO @TermPeriods (PeriodLabel, PeriodStart, PeriodEnd, PeriodSort)
				SELECT N'Tháng ' + CONVERT(NVARCHAR(2), V.MonthNo),
					   DATEFROMPARTS(@TermLatestYear, V.MonthNo, 1),
					   EOMONTH(DATEFROMPARTS(@TermLatestYear, V.MonthNo, 1)),
					   V.MonthNo
				FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12)) V(MonthNo);

				SET @TermSummaryLabel = CONVERT(NVARCHAR(4), @TermLatestYear);
			END

			DECLARE @TermMaxPeriodEnd DATE = (SELECT MAX(PeriodEnd) FROM @TermPeriods);

			;WITH TermEmployees AS
			(
				SELECT DISTINCT E.EmpID,
						CONVERT(DATE, TER.EffectDate) AS EffectDate,
						P.PeriodLabel,
						P.PeriodEnd,
						P.PeriodSort
				FROM dbo.TER_tblTermination (NOLOCK) TER
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = TER.EmpID
				INNER JOIN @TermPeriods P ON CONVERT(DATE, TER.EffectDate) >= P.PeriodStart AND CONVERT(DATE, TER.EffectDate) <= P.PeriodEnd
				WHERE TER.EffectDate IS NOT NULL
				AND (NOT EXISTS (SELECT 1 FROM @Companys) OR E.LSCompanyID IN (SELECT ID FROM @Companys))
				AND (NOT EXISTS (SELECT 1 FROM @LoaiChucDanhs) OR E.LSLoaiChucDanhID IN (SELECT ID FROM @LoaiChucDanhs))
				AND (NOT EXISTS (SELECT 1 FROM @Level1s) OR E.LSLevel1ID IN (SELECT ID FROM @Level1s))
				AND (NOT EXISTS (SELECT 1 FROM @Level2s) OR E.LSLevel2ID IN (SELECT ID FROM @Level2s))
				AND (NOT EXISTS (SELECT 1 FROM @Level3s) OR E.LSLevel3ID IN (SELECT ID FROM @Level3s))
				AND (NOT EXISTS (SELECT 1 FROM @Level4s) OR E.LSLevel4ID IN (SELECT ID FROM @Level4s))
				AND (NOT EXISTS (SELECT 1 FROM @Level5s) OR E.LSLevel5ID IN (SELECT ID FROM @Level5s))
				AND (NOT EXISTS (SELECT 1 FROM @Level6s) OR E.LSLevel6ID IN (SELECT ID FROM @Level6s))
				AND (NOT EXISTS (SELECT 1 FROM @Level7s) OR E.LSLevel7ID IN (SELECT ID FROM @Level7s))
				AND (NOT EXISTS (SELECT 1 FROM @Level8s) OR E.LSLevel8ID IN (SELECT ID FROM @Level8s))
				AND (NOT EXISTS (SELECT 1 FROM @Level9s) OR E.LSLevel9ID IN (SELECT ID FROM @Level9s))
				AND EXISTS
				(
					SELECT 1
					FROM dbo.fnGetAllEmp_Permission_EffDate(@UserGroupID, @FunctionID, CONVERT(DATE, TER.EffectDate)) PQ
					WHERE PQ.EmpID = E.EmpID
				)
			),
			TermOrg AS
			(
				SELECT	T.EmpID, T.PeriodLabel, T.PeriodSort,
						TT.LSThuocTinhCoCau1Code,
						CASE
							WHEN TT.LSThuocTinhCoCau1Code = N'ĐVKD' THEN CASE WHEN @LanguageID = 'VN' THEN N'Đơn vị kinh doanh' ELSE N'Business unit' END
							WHEN TT.LSThuocTinhCoCau1Code = N'HO' THEN CASE WHEN @LanguageID = 'VN' THEN N'Trụ sở chính' ELSE N'Head office' END
						END AS Category,
						CASE WHEN TT.LSThuocTinhCoCau1Code = N'ĐVKD' THEN 1 WHEN TT.LSThuocTinhCoCau1Code = N'HO' THEN 2 ELSE 99 END AS CategorySort
				FROM TermEmployees T
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = T.EmpID
				OUTER APPLY
				(
					SELECT TOP 1 WR.*
					FROM dbo.HR_tblWorkingRecord (NOLOCK) WR
					WHERE WR.EmpID = T.EmpID
					AND ISNULL(WR.FromDate, WR.NgayHieuLuc) IS NOT NULL
					AND CONVERT(DATE, ISNULL(WR.FromDate, WR.NgayHieuLuc)) <= T.EffectDate
					AND (WR.ToDate IS NULL OR CONVERT(DATE, WR.ToDate) >= T.EffectDate)
					ORDER BY CONVERT(DATE, ISNULL(WR.FromDate, WR.NgayHieuLuc)) DESC, WR.WorkingRecordID DESC
				) WR
				LEFT JOIN dbo.LS_tblCompany (NOLOCK) CO ON CO.LSCompanyID = ISNULL(WR.LSCompanyID, E.LSCompanyID)
				LEFT JOIN dbo.LS_tblLevel1 (NOLOCK) L1 ON L1.LSLevel1ID = ISNULL(WR.LSLevel1ID, E.LSLevel1ID)
				LEFT JOIN dbo.LS_tblLevel2 (NOLOCK) L2 ON L2.LSLevel2ID = ISNULL(WR.LSLevel2ID, E.LSLevel2ID)
				LEFT JOIN dbo.LS_tblLevel3 (NOLOCK) L3 ON L3.LSLevel3ID = ISNULL(WR.LSLevel3ID, E.LSLevel3ID)
				LEFT JOIN dbo.LS_tblLevel4 (NOLOCK) L4 ON L4.LSLevel4ID = ISNULL(WR.LSLevel4ID, E.LSLevel4ID)
				LEFT JOIN dbo.LS_tblLevel5 (NOLOCK) L5 ON L5.LSLevel5ID = ISNULL(WR.LSLevel5ID, E.LSLevel5ID)
				LEFT JOIN dbo.LS_tblLevel6 (NOLOCK) L6 ON L6.LSLevel6ID = ISNULL(WR.LSLevel6ID, E.LSLevel6ID)
				LEFT JOIN dbo.LS_tblLevel7 (NOLOCK) L7 ON L7.LSLevel7ID = ISNULL(WR.LSLevel7ID, E.LSLevel7ID)
				LEFT JOIN dbo.LS_tblLevel8 (NOLOCK) L8 ON L8.LSLevel8ID = ISNULL(WR.LSLevel8ID, E.LSLevel8ID)
				LEFT JOIN dbo.LS_tblLevel9 (NOLOCK) L9 ON L9.LSLevel9ID = ISNULL(WR.LSLevel9ID, E.LSLevel9ID)
				LEFT JOIN dbo.LS_tblThuocTinhCoCau1 (NOLOCK) TT ON TT.LSThuocTinhCoCau1ID = CASE WHEN L9.LSThuocTinhCoCau1ID IS NOT NULL THEN L9.LSThuocTinhCoCau1ID
																				 WHEN L8.LSThuocTinhCoCau1ID IS NOT NULL THEN L8.LSThuocTinhCoCau1ID
																				 WHEN L7.LSThuocTinhCoCau1ID IS NOT NULL THEN L7.LSThuocTinhCoCau1ID
																				 WHEN L6.LSThuocTinhCoCau1ID IS NOT NULL THEN L6.LSThuocTinhCoCau1ID
																				 WHEN L5.LSThuocTinhCoCau1ID IS NOT NULL THEN L5.LSThuocTinhCoCau1ID
																				 WHEN L4.LSThuocTinhCoCau1ID IS NOT NULL THEN L4.LSThuocTinhCoCau1ID
																				 WHEN L3.LSThuocTinhCoCau1ID IS NOT NULL THEN L3.LSThuocTinhCoCau1ID
																				 WHEN L2.LSThuocTinhCoCau1ID IS NOT NULL THEN L2.LSThuocTinhCoCau1ID
																				 WHEN L1.LSThuocTinhCoCau1ID IS NOT NULL THEN L1.LSThuocTinhCoCau1ID
																			ELSE CO.LSThuocTinhCoCau1ID END
				WHERE TT.LSThuocTinhCoCau1Code IN (N'HO', N'ĐVKD')
			)
			SELECT	C.Category,
					P.PeriodLabel,
					P.PeriodSort,
					C.CategorySort,
					COUNT(T.EmpID) AS [Value],
					@TermScope AS SummaryScope,
					@TermSummaryLabel AS SummaryLabel
			FROM @TermPeriods P
			CROSS JOIN
			(
				SELECT CASE WHEN @LanguageID = 'VN' THEN N'Đơn vị kinh doanh' ELSE N'Business unit' END AS Category, 1 AS CategorySort
				UNION ALL
				SELECT CASE WHEN @LanguageID = 'VN' THEN N'Trụ sở chính' ELSE N'Head office' END AS Category, 2 AS CategorySort
			) C
			LEFT JOIN TermOrg T ON T.PeriodLabel = P.PeriodLabel AND T.Category = C.Category
			GROUP BY C.Category, P.PeriodLabel, P.PeriodSort, C.CategorySort
			ORDER BY C.CategorySort, P.PeriodSort;
		END		
		ELSE IF (@ChartID = 'main_chart_89')
		BEGIN
			DECLARE @HireLatestYear INT = NULL,
					@HireLatestQuarter INT = NULL,
					@HireLatestMonth INT = NULL,
					@HireScope CHAR(1) = NULL,
					@HireSummaryLabel NVARCHAR(50) = NULL;

			DECLARE @HirePeriods TABLE
			(
				PeriodLabel NVARCHAR(50),
				PeriodStart DATE,
				PeriodEnd DATE,
				PeriodSort INT
			);

			IF EXISTS (SELECT 1 FROM @tblChartChuKyCong WHERE Months IS NOT NULL)
			BEGIN
				SELECT TOP 1 @HireLatestYear = Years, @HireLatestMonth = Months
				FROM @tblChartChuKyCong
				WHERE Years IS NOT NULL AND Months IS NOT NULL
				ORDER BY Years DESC, Months DESC;

				SET @HireScope = 'M';
				INSERT INTO @HirePeriods (PeriodLabel, PeriodStart, PeriodEnd, PeriodSort)
				SELECT N'Tháng ' + CONVERT(NVARCHAR(2), @HireLatestMonth),
					   DATEFROMPARTS(@HireLatestYear, @HireLatestMonth, 1),
					   EOMONTH(DATEFROMPARTS(@HireLatestYear, @HireLatestMonth, 1)),
					   @HireLatestMonth;

				SET @HireSummaryLabel = N'Tháng ' + CONVERT(NVARCHAR(2), @HireLatestMonth) + N'/' + CONVERT(NVARCHAR(4), @HireLatestYear);
			END
			ELSE IF EXISTS (SELECT 1 FROM @tblChartChuKyCong WHERE Quarters IS NOT NULL)
			BEGIN
				SELECT TOP 1 @HireLatestYear = Years, @HireLatestQuarter = Quarters
				FROM @tblChartChuKyCong
				WHERE Years IS NOT NULL AND Quarters IS NOT NULL
				ORDER BY Years DESC, Quarters DESC;

				SET @HireScope = 'Q';
				DECLARE @HireQuarterStartMonth INT = ((@HireLatestQuarter - 1) * 3) + 1;
				INSERT INTO @HirePeriods (PeriodLabel, PeriodStart, PeriodEnd, PeriodSort)
				SELECT N'Tháng ' + CONVERT(NVARCHAR(2), V.MonthNo),
					   DATEFROMPARTS(@HireLatestYear, V.MonthNo, 1),
					   EOMONTH(DATEFROMPARTS(@HireLatestYear, V.MonthNo, 1)),
					   V.MonthNo
				FROM (VALUES (@HireQuarterStartMonth), (@HireQuarterStartMonth + 1), (@HireQuarterStartMonth + 2)) V(MonthNo);

				SET @HireSummaryLabel = N'Quý ' + CONVERT(NVARCHAR(2), @HireLatestQuarter) + N'/' + CONVERT(NVARCHAR(4), @HireLatestYear);
			END
			ELSE
			BEGIN
				SELECT @HireLatestYear = MAX(Years)
				FROM @tblChartChuKyCong
				WHERE Years IS NOT NULL;

				SET @HireLatestYear = ISNULL(@HireLatestYear, YEAR(ISNULL(@ChartNgayChotCongGanNhat, @dDate)));
				SET @HireScope = 'Y';

				INSERT INTO @HirePeriods (PeriodLabel, PeriodStart, PeriodEnd, PeriodSort)
				SELECT N'Tháng ' + CONVERT(NVARCHAR(2), V.MonthNo),
					   DATEFROMPARTS(@HireLatestYear, V.MonthNo, 1),
					   EOMONTH(DATEFROMPARTS(@HireLatestYear, V.MonthNo, 1)),
					   V.MonthNo
				FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12)) V(MonthNo);

				SET @HireSummaryLabel = CONVERT(NVARCHAR(4), @HireLatestYear);
			END

			DECLARE @HireMaxPeriodEnd DATE = (SELECT MAX(PeriodEnd) FROM @HirePeriods);

			IF NOT EXISTS (SELECT 1 FROM @Employees WHERE ID > 0)
			BEGIN
				INSERT INTO @Employees (ID)
				SELECT DISTINCT P.EmpID
				FROM dbo.fnGetAllEmp_Permission_EffDate(@UserGroupID, @FunctionID, @HireMaxPeriodEnd) P
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = P.EmpID
				WHERE (E.StartDate IS NULL OR CONVERT(DATE, E.StartDate) <= @HireMaxPeriodEnd)
				AND (NOT EXISTS (SELECT 1 FROM @Companys) OR E.LSCompanyID IN (SELECT ID FROM @Companys))
				AND (NOT EXISTS (SELECT 1 FROM @LoaiChucDanhs) OR E.LSLoaiChucDanhID IN (SELECT ID FROM @LoaiChucDanhs))
				AND (NOT EXISTS (SELECT 1 FROM @Level1s) OR E.LSLevel1ID IN (SELECT ID FROM @Level1s))
				AND (NOT EXISTS (SELECT 1 FROM @Level2s) OR E.LSLevel2ID IN (SELECT ID FROM @Level2s))
				AND (NOT EXISTS (SELECT 1 FROM @Level3s) OR E.LSLevel3ID IN (SELECT ID FROM @Level3s))
				AND (NOT EXISTS (SELECT 1 FROM @Level4s) OR E.LSLevel4ID IN (SELECT ID FROM @Level4s))
				AND (NOT EXISTS (SELECT 1 FROM @Level5s) OR E.LSLevel5ID IN (SELECT ID FROM @Level5s))
				AND (NOT EXISTS (SELECT 1 FROM @Level6s) OR E.LSLevel6ID IN (SELECT ID FROM @Level6s))
				AND (NOT EXISTS (SELECT 1 FROM @Level7s) OR E.LSLevel7ID IN (SELECT ID FROM @Level7s))
				AND (NOT EXISTS (SELECT 1 FROM @Level8s) OR E.LSLevel8ID IN (SELECT ID FROM @Level8s))
				AND (NOT EXISTS (SELECT 1 FROM @Level9s) OR E.LSLevel9ID IN (SELECT ID FROM @Level9s));
			END

			;WITH HireEmployees AS
			(
				SELECT DISTINCT E.EmpID, CONVERT(DATE, E.StartDate) AS StartDate
				FROM @Employees A
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = A.ID
				WHERE A.ID > 0
				AND E.StartDate IS NOT NULL
			),
			HireInPeriod AS
			(
				SELECT H.EmpID, H.StartDate, P.PeriodLabel, P.PeriodStart, P.PeriodEnd, P.PeriodSort
				FROM HireEmployees H
				INNER JOIN @HirePeriods P ON H.StartDate >= P.PeriodStart AND H.StartDate <= P.PeriodEnd
			),
			HireOrg AS
			(
				SELECT	H.EmpID, H.PeriodLabel, H.PeriodSort,
						TT.LSThuocTinhCoCau1Code,
						CASE
							WHEN TT.LSThuocTinhCoCau1Code = N'ĐVKD' THEN CASE WHEN @LanguageID = 'VN' THEN N'Đơn vị kinh doanh' ELSE N'Business unit' END
							WHEN TT.LSThuocTinhCoCau1Code = N'HO' THEN CASE WHEN @LanguageID = 'VN' THEN N'Trụ sở chính' ELSE N'Head office' END
						END AS Category,
						CASE WHEN TT.LSThuocTinhCoCau1Code = N'ĐVKD' THEN 1 WHEN TT.LSThuocTinhCoCau1Code = N'HO' THEN 2 ELSE 99 END AS CategorySort
				FROM HireInPeriod H
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = H.EmpID
				OUTER APPLY
				(
					SELECT TOP 1 WR.*
					FROM dbo.HR_tblWorkingRecord (NOLOCK) WR
					WHERE WR.EmpID = H.EmpID
					AND ISNULL(WR.FromDate, WR.NgayHieuLuc) IS NOT NULL
					AND CONVERT(DATE, ISNULL(WR.FromDate, WR.NgayHieuLuc)) <= H.PeriodEnd
					AND (WR.ToDate IS NULL OR CONVERT(DATE, WR.ToDate) >= H.PeriodEnd)
					ORDER BY CONVERT(DATE, ISNULL(WR.FromDate, WR.NgayHieuLuc)) DESC, WR.WorkingRecordID DESC
				) WR
				LEFT JOIN dbo.LS_tblCompany (NOLOCK) CO ON CO.LSCompanyID = ISNULL(WR.LSCompanyID, E.LSCompanyID)
				LEFT JOIN dbo.LS_tblLevel1 (NOLOCK) L1 ON L1.LSLevel1ID = ISNULL(WR.LSLevel1ID, E.LSLevel1ID)
				LEFT JOIN dbo.LS_tblLevel2 (NOLOCK) L2 ON L2.LSLevel2ID = ISNULL(WR.LSLevel2ID, E.LSLevel2ID)
				LEFT JOIN dbo.LS_tblLevel3 (NOLOCK) L3 ON L3.LSLevel3ID = ISNULL(WR.LSLevel3ID, E.LSLevel3ID)
				LEFT JOIN dbo.LS_tblLevel4 (NOLOCK) L4 ON L4.LSLevel4ID = ISNULL(WR.LSLevel4ID, E.LSLevel4ID)
				LEFT JOIN dbo.LS_tblLevel5 (NOLOCK) L5 ON L5.LSLevel5ID = ISNULL(WR.LSLevel5ID, E.LSLevel5ID)
				LEFT JOIN dbo.LS_tblLevel6 (NOLOCK) L6 ON L6.LSLevel6ID = ISNULL(WR.LSLevel6ID, E.LSLevel6ID)
				LEFT JOIN dbo.LS_tblLevel7 (NOLOCK) L7 ON L7.LSLevel7ID = ISNULL(WR.LSLevel7ID, E.LSLevel7ID)
				LEFT JOIN dbo.LS_tblLevel8 (NOLOCK) L8 ON L8.LSLevel8ID = ISNULL(WR.LSLevel8ID, E.LSLevel8ID)
				LEFT JOIN dbo.LS_tblLevel9 (NOLOCK) L9 ON L9.LSLevel9ID = ISNULL(WR.LSLevel9ID, E.LSLevel9ID)
				LEFT JOIN dbo.LS_tblThuocTinhCoCau1 (NOLOCK) TT ON TT.LSThuocTinhCoCau1ID = CASE WHEN L9.LSThuocTinhCoCau1ID IS NOT NULL THEN L9.LSThuocTinhCoCau1ID
																				 WHEN L8.LSThuocTinhCoCau1ID IS NOT NULL THEN L8.LSThuocTinhCoCau1ID
																				 WHEN L7.LSThuocTinhCoCau1ID IS NOT NULL THEN L7.LSThuocTinhCoCau1ID
																				 WHEN L6.LSThuocTinhCoCau1ID IS NOT NULL THEN L6.LSThuocTinhCoCau1ID
																				 WHEN L5.LSThuocTinhCoCau1ID IS NOT NULL THEN L5.LSThuocTinhCoCau1ID
																				 WHEN L4.LSThuocTinhCoCau1ID IS NOT NULL THEN L4.LSThuocTinhCoCau1ID
																				 WHEN L3.LSThuocTinhCoCau1ID IS NOT NULL THEN L3.LSThuocTinhCoCau1ID
																				 WHEN L2.LSThuocTinhCoCau1ID IS NOT NULL THEN L2.LSThuocTinhCoCau1ID
																				 WHEN L1.LSThuocTinhCoCau1ID IS NOT NULL THEN L1.LSThuocTinhCoCau1ID
																			ELSE CO.LSThuocTinhCoCau1ID END
				WHERE TT.LSThuocTinhCoCau1Code IN (N'HO', N'ĐVKD')
			)
			SELECT	C.Category,
					P.PeriodLabel,
					P.PeriodSort,
					C.CategorySort,
					COUNT(H.EmpID) AS [Value],
					@HireScope AS SummaryScope,
					@HireSummaryLabel AS SummaryLabel
			FROM @HirePeriods P
			CROSS JOIN
			(
				SELECT CASE WHEN @LanguageID = 'VN' THEN N'Đơn vị kinh doanh' ELSE N'Business unit' END AS Category, 1 AS CategorySort
				UNION ALL
				SELECT CASE WHEN @LanguageID = 'VN' THEN N'Trụ sở chính' ELSE N'Head office' END AS Category, 2 AS CategorySort
			) C
			LEFT JOIN HireOrg H ON H.PeriodLabel = P.PeriodLabel AND H.Category = C.Category
			GROUP BY C.Category, P.PeriodLabel, P.PeriodSort, C.CategorySort
			ORDER BY C.CategorySort, P.PeriodSort;
		END		
		ELSE IF (@ChartID = 'main_chart_102')
		BEGIN
			DECLARE @LaborGroupSummaryDate DATE = CONVERT(DATE, COALESCE(@ChartLastDateTimeLine, @ChartNgayChotCongGanNhat, @dDate));
			DECLARE @LaborGroupLatestYear INT = NULL,
					@LaborGroupLatestQuarter INT = NULL,
					@LaborGroupLatestMonth INT = NULL,
					@LaborGroupTitleYear INT = NULL,
					@LaborGroupTitleMonth INT = NULL;

			IF EXISTS (SELECT 1 FROM @tblChartChuKyCong WHERE Months IS NOT NULL) OR EXISTS (SELECT 1 FROM @Months)
			BEGIN
				IF EXISTS (SELECT 1 FROM @tblChartChuKyCong WHERE Months IS NOT NULL)
				BEGIN
					SELECT TOP 1
						   @LaborGroupSummaryDate = CONVERT(DATE, COALESCE(NgayChotCongGanNhatDate, LastDateTimeLineDate, TRY_CONVERT(DATETIME, NgayChotCongGanNhat, 103), TRY_CONVERT(DATETIME, LastDateTimeline, 103), @LaborGroupSummaryDate)),
						   @LaborGroupTitleYear = Years,
						   @LaborGroupTitleMonth = Months
					FROM @tblChartChuKyCong
					WHERE Years IS NOT NULL AND Months IS NOT NULL
					ORDER BY Years DESC, Months DESC;
				END
				ELSE
				BEGIN
					SELECT @LaborGroupLatestYear = ISNULL(MAX(ID), YEAR(@LaborGroupSummaryDate)) FROM @Years;
					SELECT @LaborGroupLatestMonth = MAX(ID) FROM @Months;
					SET @LaborGroupSummaryDate = EOMONTH(DATEFROMPARTS(@LaborGroupLatestYear, @LaborGroupLatestMonth, 1));
					SET @LaborGroupTitleYear = @LaborGroupLatestYear;
					SET @LaborGroupTitleMonth = @LaborGroupLatestMonth;
				END
			END
			ELSE IF EXISTS (SELECT 1 FROM @tblChartChuKyCong WHERE Quarters IS NOT NULL) OR EXISTS (SELECT 1 FROM @Quarters)
			BEGIN
				IF EXISTS (SELECT 1 FROM @tblChartChuKyCong WHERE Quarters IS NOT NULL)
				BEGIN
					SELECT TOP 1
						   @LaborGroupSummaryDate = CONVERT(DATE, COALESCE(NgayChotCongGanNhatDate, LastDateTimeLineDate, TRY_CONVERT(DATETIME, NgayChotCongGanNhat, 103), TRY_CONVERT(DATETIME, LastDateTimeline, 103), @LaborGroupSummaryDate)),
						   @LaborGroupTitleYear = Years,
						   @LaborGroupTitleMonth = Quarters * 3
					FROM @tblChartChuKyCong
					WHERE Years IS NOT NULL AND Quarters IS NOT NULL
					ORDER BY Years DESC, Quarters DESC;
				END
				ELSE
				BEGIN
					SELECT @LaborGroupLatestYear = ISNULL(MAX(ID), YEAR(@LaborGroupSummaryDate)) FROM @Years;
					SELECT @LaborGroupLatestQuarter = MAX(ID) FROM @Quarters;
					SET @LaborGroupSummaryDate = EOMONTH(DATEFROMPARTS(@LaborGroupLatestYear, ((@LaborGroupLatestQuarter - 1) * 3) + 3, 1));
					SET @LaborGroupTitleYear = @LaborGroupLatestYear;
					SET @LaborGroupTitleMonth = @LaborGroupLatestQuarter * 3;
				END
			END
			ELSE IF EXISTS (SELECT 1 FROM @tblChartChuKyCong WHERE Years IS NOT NULL) OR EXISTS (SELECT 1 FROM @Years)
			BEGIN
				IF EXISTS (SELECT 1 FROM @tblChartChuKyCong WHERE Years IS NOT NULL)
				BEGIN
					SELECT TOP 1 @LaborGroupSummaryDate = CONVERT(DATE, COALESCE(NgayChotCongGanNhatDate, LastDateTimeLineDate, TRY_CONVERT(DATETIME, NgayChotCongGanNhat, 103), TRY_CONVERT(DATETIME, LastDateTimeline, 103), @LaborGroupSummaryDate))
					FROM @tblChartChuKyCong
					WHERE Years IS NOT NULL
					ORDER BY Years DESC;
				END
				ELSE
				BEGIN
					SELECT @LaborGroupLatestYear = MAX(ID) FROM @Years;
					SET @LaborGroupSummaryDate = DATEFROMPARTS(@LaborGroupLatestYear, 12, 31);
					SET @LaborGroupTitleYear = @LaborGroupLatestYear;
					SET @LaborGroupTitleMonth = 12;
				END
			END

			SET @LaborGroupTitleYear = ISNULL(@LaborGroupTitleYear, YEAR(@LaborGroupSummaryDate));
			SET @LaborGroupTitleMonth = ISNULL(@LaborGroupTitleMonth, MONTH(@LaborGroupSummaryDate));

			IF NOT EXISTS (SELECT 1 FROM @Employees WHERE ID > 0)
			BEGIN
				INSERT INTO @Employees (ID)
				SELECT DISTINCT P.EmpID
				FROM dbo.fnGetAllEmp_Permission_EffDate(@UserGroupID, @FunctionID, @LaborGroupSummaryDate) P
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = P.EmpID
				WHERE (E.StartDate IS NULL OR CONVERT(DATE, E.StartDate) <= @LaborGroupSummaryDate)
				AND (NOT EXISTS (SELECT 1 FROM @Companys) OR E.LSCompanyID IN (SELECT ID FROM @Companys))
				AND (NOT EXISTS (SELECT 1 FROM @LoaiChucDanhs) OR TRY_CONVERT(BIGINT, E.LSLoaiChucDanhID) IN (SELECT ID FROM @LoaiChucDanhs))
				AND (NOT EXISTS (SELECT 1 FROM @Level1s) OR E.LSLevel1ID IN (SELECT ID FROM @Level1s))
				AND (NOT EXISTS (SELECT 1 FROM @Level2s) OR E.LSLevel2ID IN (SELECT ID FROM @Level2s))
				AND (NOT EXISTS (SELECT 1 FROM @Level3s) OR E.LSLevel3ID IN (SELECT ID FROM @Level3s))
				AND (NOT EXISTS (SELECT 1 FROM @Level4s) OR E.LSLevel4ID IN (SELECT ID FROM @Level4s))
				AND (NOT EXISTS (SELECT 1 FROM @Level5s) OR E.LSLevel5ID IN (SELECT ID FROM @Level5s))
				AND (NOT EXISTS (SELECT 1 FROM @Level6s) OR E.LSLevel6ID IN (SELECT ID FROM @Level6s))
				AND (NOT EXISTS (SELECT 1 FROM @Level7s) OR E.LSLevel7ID IN (SELECT ID FROM @Level7s))
				AND (NOT EXISTS (SELECT 1 FROM @Level8s) OR E.LSLevel8ID IN (SELECT ID FROM @Level8s))
				AND (NOT EXISTS (SELECT 1 FROM @Level9s) OR E.LSLevel9ID IN (SELECT ID FROM @Level9s));
			END

			;WITH PresentEmployees AS
			(
				SELECT DISTINCT E.EmpID
				FROM @Employees A
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = A.ID
				WHERE A.ID > 0
				AND (E.StartDate IS NULL OR CONVERT(DATE, E.StartDate) <= @LaborGroupSummaryDate)
				AND NOT EXISTS
				(
					SELECT 1
					FROM dbo.TER_tblTermination (NOLOCK) TER
					WHERE TER.EmpID = E.EmpID
					AND TER.EffectDate IS NOT NULL AND CONVERT(DATE, TER.EffectDate) <= @LaborGroupSummaryDate
				)
			),
			LatestWorkingRecord AS
			(
				SELECT P.EmpID, WR.LSJobTitleID
				FROM PresentEmployees P
				OUTER APPLY
				(
					SELECT TOP 1 WR.*
					FROM dbo.HR_tblWorkingRecord (NOLOCK) WR
					WHERE WR.EmpID = P.EmpID
					AND ISNULL(WR.FromDate, WR.NgayHieuLuc) IS NOT NULL
					AND CONVERT(DATE, ISNULL(WR.FromDate, WR.NgayHieuLuc)) <= @LaborGroupSummaryDate
					AND (WR.ToDate IS NULL OR CONVERT(DATE, WR.ToDate) >= @LaborGroupSummaryDate)
					ORDER BY CONVERT(DATE, ISNULL(WR.FromDate, WR.NgayHieuLuc)) DESC, WR.WorkingRecordID DESC
				) WR
			),
			LaborGroups AS
			(
				SELECT L.EmpID,
					   ISNULL(CASE WHEN @LanguageID = 'VN' THEN LG.VNName ELSE LG.Name END, N'Không xác định') AS Category,
					   ISNULL(CONVERT(INT, LG.Rank), 999) AS SortOrder
				FROM LatestWorkingRecord L
				LEFT JOIN dbo.LS_tblJobTitle (NOLOCK) JT ON JT.LSJobTitleID = L.LSJobTitleID
				LEFT JOIN dbo.LS_tblChucVu (NOLOCK) CV ON CV.LSChucVuID = JT.LSChucVuID
				LEFT JOIN dbo.LS_tblCapBacChucVu (NOLOCK) LG ON LG.LSCapBacChucVuID = CV.MaCapBacNhanVien
			)
			SELECT Category,
				   COUNT(1) AS [Value],
				   CONVERT(VARCHAR(10), @LaborGroupSummaryDate, 120) AS SummaryDate,
				   N'T' + RIGHT('0' + CONVERT(VARCHAR(2), @LaborGroupTitleMonth), 2) + N'/' + CONVERT(VARCHAR(4), @LaborGroupTitleYear) AS SummaryLabel
			FROM LaborGroups
			GROUP BY Category, SortOrder
			ORDER BY SortOrder, Category;
		END		
		ELSE IF (@ChartID = 'main_chart_93')
		BEGIN
			DECLARE @TurnoverGenLatestYear INT = NULL,
					@TurnoverGenLatestQuarter INT = NULL,
					@TurnoverGenLatestMonth INT = NULL,
					@TurnoverGenScope CHAR(1) = NULL,
					@TurnoverGenRangeStart DATE,
					@TurnoverGenRangeEnd DATE,
					@TurnoverGenSummaryLabel NVARCHAR(50);

			DECLARE @TurnoverGenPeriods TABLE
			(
				MonthNo INT NOT NULL PRIMARY KEY,
				PeriodStart DATE NOT NULL,
				PeriodEnd DATE NOT NULL
			);

			IF EXISTS (SELECT 1 FROM @tblChartChuKyCong WHERE Months IS NOT NULL) OR EXISTS (SELECT 1 FROM @Months)
			BEGIN
				IF EXISTS (SELECT 1 FROM @tblChartChuKyCong WHERE Months IS NOT NULL)
				BEGIN
					SELECT TOP 1 @TurnoverGenLatestYear = Years, @TurnoverGenLatestMonth = Months
					FROM @tblChartChuKyCong
					WHERE Years IS NOT NULL AND Months IS NOT NULL
					ORDER BY Years DESC, Months DESC;
				END
				ELSE
				BEGIN
					SELECT @TurnoverGenLatestYear = ISNULL(MAX(ID), YEAR(ISNULL(@ChartNgayChotCongGanNhat, @dDate))) FROM @Years;
					SELECT @TurnoverGenLatestMonth = MAX(ID) FROM @Months;
				END

				SET @TurnoverGenScope = 'M';
				SET @TurnoverGenRangeStart = DATEFROMPARTS(@TurnoverGenLatestYear, @TurnoverGenLatestMonth, 1);
				SET @TurnoverGenRangeEnd = EOMONTH(@TurnoverGenRangeStart);
				SET @TurnoverGenSummaryLabel = N'Tháng ' + CONVERT(NVARCHAR(2), @TurnoverGenLatestMonth) + N'/' + CONVERT(NVARCHAR(4), @TurnoverGenLatestYear);

				INSERT INTO @TurnoverGenPeriods (MonthNo, PeriodStart, PeriodEnd)
				VALUES (@TurnoverGenLatestMonth, @TurnoverGenRangeStart, @TurnoverGenRangeEnd);
			END
			ELSE IF EXISTS (SELECT 1 FROM @tblChartChuKyCong WHERE Quarters IS NOT NULL) OR EXISTS (SELECT 1 FROM @Quarters)
			BEGIN
				IF EXISTS (SELECT 1 FROM @tblChartChuKyCong WHERE Quarters IS NOT NULL)
				BEGIN
					SELECT TOP 1 @TurnoverGenLatestYear = Years, @TurnoverGenLatestQuarter = Quarters
					FROM @tblChartChuKyCong
					WHERE Years IS NOT NULL AND Quarters IS NOT NULL
					ORDER BY Years DESC, Quarters DESC;
				END
				ELSE
				BEGIN
					SELECT @TurnoverGenLatestYear = ISNULL(MAX(ID), YEAR(ISNULL(@ChartNgayChotCongGanNhat, @dDate))) FROM @Years;
					SELECT @TurnoverGenLatestQuarter = MAX(ID) FROM @Quarters;
				END

				SET @TurnoverGenScope = 'Q';
				DECLARE @TurnoverGenQuarterStartMonth INT = ((@TurnoverGenLatestQuarter - 1) * 3) + 1;
				SET @TurnoverGenRangeStart = DATEFROMPARTS(@TurnoverGenLatestYear, @TurnoverGenQuarterStartMonth, 1);
				SET @TurnoverGenRangeEnd = EOMONTH(DATEFROMPARTS(@TurnoverGenLatestYear, @TurnoverGenQuarterStartMonth + 2, 1));
				SET @TurnoverGenSummaryLabel = N'Quý ' + CONVERT(NVARCHAR(2), @TurnoverGenLatestQuarter) + N'/' + CONVERT(NVARCHAR(4), @TurnoverGenLatestYear);

				INSERT INTO @TurnoverGenPeriods (MonthNo, PeriodStart, PeriodEnd)
				SELECT V.MonthNo,
					   DATEFROMPARTS(@TurnoverGenLatestYear, V.MonthNo, 1),
					   EOMONTH(DATEFROMPARTS(@TurnoverGenLatestYear, V.MonthNo, 1))
				FROM (VALUES (@TurnoverGenQuarterStartMonth), (@TurnoverGenQuarterStartMonth + 1), (@TurnoverGenQuarterStartMonth + 2)) V(MonthNo);
			END
			ELSE
			BEGIN
				SELECT @TurnoverGenLatestYear = MAX(Years)
				FROM @tblChartChuKyCong
				WHERE Years IS NOT NULL;

				IF @TurnoverGenLatestYear IS NULL
					SELECT @TurnoverGenLatestYear = MAX(ID) FROM @Years;

				SET @TurnoverGenLatestYear = ISNULL(@TurnoverGenLatestYear, YEAR(ISNULL(@ChartNgayChotCongGanNhat, @dDate)));
				SET @TurnoverGenScope = 'Y';
				SET @TurnoverGenRangeStart = DATEFROMPARTS(@TurnoverGenLatestYear, 1, 1);
				SET @TurnoverGenRangeEnd = DATEFROMPARTS(@TurnoverGenLatestYear, 12, 31);
				SET @TurnoverGenSummaryLabel = CONVERT(NVARCHAR(4), @TurnoverGenLatestYear);

				INSERT INTO @TurnoverGenPeriods (MonthNo, PeriodStart, PeriodEnd)
				SELECT V.MonthNo,
					   DATEFROMPARTS(@TurnoverGenLatestYear, V.MonthNo, 1),
					   EOMONTH(DATEFROMPARTS(@TurnoverGenLatestYear, V.MonthNo, 1))
				FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12)) V(MonthNo);
			END

			;WITH Generations AS
			(
				SELECT N'Gen Z (Từ 1997)' AS Generation, 1 AS GenerationSort
				UNION ALL SELECT N'Gen Y (Từ 1981-1996)', 2
				UNION ALL SELECT N'Gen X (Từ 1965-1980)', 3
				UNION ALL SELECT N'Baby boomer (<= 1964)', 4
				UNION ALL SELECT N'Không xác định', 5
			),
			PresentByMonth AS
			(
				SELECT P.MonthNo,
					   CASE
						   WHEN CV.DOB IS NULL THEN N'Không xác định'
						   WHEN YEAR(CV.DOB) <= 1964 THEN N'Baby boomer (<= 1964)'
						   WHEN YEAR(CV.DOB) BETWEEN 1965 AND 1980 THEN N'Gen X (Từ 1965-1980)'
						   WHEN YEAR(CV.DOB) BETWEEN 1981 AND 1996 THEN N'Gen Y (Từ 1981-1996)'
						   ELSE N'Gen Z (Từ 1997)'
					   END AS Generation,
					   COUNT(DISTINCT E.EmpID) AS EmployeeCount
				FROM @TurnoverGenPeriods P
				CROSS APPLY dbo.fnGetAllEmp_Permission_EffDate(@UserGroupID, @FunctionID, P.PeriodEnd) PQ
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = PQ.EmpID
				LEFT JOIN dbo.HR_tblEmpCV (NOLOCK) CV ON CV.EmpID = E.EmpID
				WHERE (E.StartDate IS NULL OR CONVERT(DATE, E.StartDate) <= P.PeriodEnd)
				AND (NOT EXISTS (SELECT 1 FROM @Companys) OR E.LSCompanyID IN (SELECT ID FROM @Companys))
				AND (NOT EXISTS (SELECT 1 FROM @LoaiChucDanhs) OR TRY_CONVERT(BIGINT, E.LSLoaiChucDanhID) IN (SELECT ID FROM @LoaiChucDanhs))
				AND (NOT EXISTS (SELECT 1 FROM @Level1s) OR E.LSLevel1ID IN (SELECT ID FROM @Level1s))
				AND (NOT EXISTS (SELECT 1 FROM @Level2s) OR E.LSLevel2ID IN (SELECT ID FROM @Level2s))
				AND (NOT EXISTS (SELECT 1 FROM @Level3s) OR E.LSLevel3ID IN (SELECT ID FROM @Level3s))
				AND (NOT EXISTS (SELECT 1 FROM @Level4s) OR E.LSLevel4ID IN (SELECT ID FROM @Level4s))
				AND (NOT EXISTS (SELECT 1 FROM @Level5s) OR E.LSLevel5ID IN (SELECT ID FROM @Level5s))
				AND (NOT EXISTS (SELECT 1 FROM @Level6s) OR E.LSLevel6ID IN (SELECT ID FROM @Level6s))
				AND (NOT EXISTS (SELECT 1 FROM @Level7s) OR E.LSLevel7ID IN (SELECT ID FROM @Level7s))
				AND (NOT EXISTS (SELECT 1 FROM @Level8s) OR E.LSLevel8ID IN (SELECT ID FROM @Level8s))
				AND (NOT EXISTS (SELECT 1 FROM @Level9s) OR E.LSLevel9ID IN (SELECT ID FROM @Level9s))
				AND NOT EXISTS
				(
					SELECT 1
					FROM dbo.TER_tblTermination (NOLOCK) TER
					WHERE TER.EmpID = E.EmpID
					AND TER.EffectDate IS NOT NULL AND CONVERT(DATE, TER.EffectDate) <= P.PeriodEnd
				)
				GROUP BY P.MonthNo,
					   CASE
						   WHEN CV.DOB IS NULL THEN N'Không xác định'
						   WHEN YEAR(CV.DOB) <= 1964 THEN N'Baby boomer (<= 1964)'
						   WHEN YEAR(CV.DOB) BETWEEN 1965 AND 1980 THEN N'Gen X (Từ 1965-1980)'
						   WHEN YEAR(CV.DOB) BETWEEN 1981 AND 1996 THEN N'Gen Y (Từ 1981-1996)'
						   ELSE N'Gen Z (Từ 1997)'
					   END
			),
			PresentAverage AS
			(
				SELECT G.Generation,
					   CONVERT(DECIMAL(18, 2), AVG(CONVERT(DECIMAL(18, 4), ISNULL(P.EmployeeCount, 0)))) AS EmployeeCount
				FROM Generations G
				CROSS JOIN @TurnoverGenPeriods M
				LEFT JOIN PresentByMonth P ON P.MonthNo = M.MonthNo AND P.Generation = G.Generation
				GROUP BY G.Generation
			),
			TerminatedByGen AS
			(
				SELECT CASE
						   WHEN CV.DOB IS NULL THEN N'Không xác định'
						   WHEN YEAR(CV.DOB) <= 1964 THEN N'Baby boomer (<= 1964)'
						   WHEN YEAR(CV.DOB) BETWEEN 1965 AND 1980 THEN N'Gen X (Từ 1965-1980)'
						   WHEN YEAR(CV.DOB) BETWEEN 1981 AND 1996 THEN N'Gen Y (Từ 1981-1996)'
						   ELSE N'Gen Z (Từ 1997)'
					   END AS Generation,
					   COUNT(DISTINCT TER.EmpID) AS TerminatedCount
				FROM dbo.TER_tblTermination (NOLOCK) TER
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = TER.EmpID
				LEFT JOIN dbo.HR_tblEmpCV (NOLOCK) CV ON CV.EmpID = E.EmpID
				WHERE TER.EffectDate IS NOT NULL
				AND CONVERT(DATE, TER.EffectDate) BETWEEN @TurnoverGenRangeStart AND @TurnoverGenRangeEnd
				AND (NOT EXISTS (SELECT 1 FROM @Companys) OR E.LSCompanyID IN (SELECT ID FROM @Companys))
				AND (NOT EXISTS (SELECT 1 FROM @LoaiChucDanhs) OR TRY_CONVERT(BIGINT, E.LSLoaiChucDanhID) IN (SELECT ID FROM @LoaiChucDanhs))
				AND (NOT EXISTS (SELECT 1 FROM @Level1s) OR E.LSLevel1ID IN (SELECT ID FROM @Level1s))
				AND (NOT EXISTS (SELECT 1 FROM @Level2s) OR E.LSLevel2ID IN (SELECT ID FROM @Level2s))
				AND (NOT EXISTS (SELECT 1 FROM @Level3s) OR E.LSLevel3ID IN (SELECT ID FROM @Level3s))
				AND (NOT EXISTS (SELECT 1 FROM @Level4s) OR E.LSLevel4ID IN (SELECT ID FROM @Level4s))
				AND (NOT EXISTS (SELECT 1 FROM @Level5s) OR E.LSLevel5ID IN (SELECT ID FROM @Level5s))
				AND (NOT EXISTS (SELECT 1 FROM @Level6s) OR E.LSLevel6ID IN (SELECT ID FROM @Level6s))
				AND (NOT EXISTS (SELECT 1 FROM @Level7s) OR E.LSLevel7ID IN (SELECT ID FROM @Level7s))
				AND (NOT EXISTS (SELECT 1 FROM @Level8s) OR E.LSLevel8ID IN (SELECT ID FROM @Level8s))
				AND (NOT EXISTS (SELECT 1 FROM @Level9s) OR E.LSLevel9ID IN (SELECT ID FROM @Level9s))
				AND EXISTS
				(
					SELECT 1
					FROM dbo.fnGetAllEmp_Permission_EffDate(@UserGroupID, @FunctionID, CONVERT(DATE, TER.EffectDate)) P
					WHERE P.EmpID = TER.EmpID
				)
				GROUP BY CASE
						   WHEN CV.DOB IS NULL THEN N'Không xác định'
						   WHEN YEAR(CV.DOB) <= 1964 THEN N'Baby boomer (<= 1964)'
						   WHEN YEAR(CV.DOB) BETWEEN 1965 AND 1980 THEN N'Gen X (Từ 1965-1980)'
						   WHEN YEAR(CV.DOB) BETWEEN 1981 AND 1996 THEN N'Gen Y (Từ 1981-1996)'
						   ELSE N'Gen Z (Từ 1997)'
					   END
			)
			SELECT G.Generation,
				   G.GenerationSort,
				   CONVERT(DECIMAL(18, 2), ISNULL(P.EmployeeCount, 0)) AS EmployeeCount,
				   ISNULL(T.TerminatedCount, 0) AS TerminatedCount,
				   CONVERT(DECIMAL(18, 2), CASE WHEN ISNULL(P.EmployeeCount, 0) + ISNULL(T.TerminatedCount, 0) > 0 THEN ISNULL(T.TerminatedCount, 0) * 100.0 / (ISNULL(P.EmployeeCount, 0) + ISNULL(T.TerminatedCount, 0)) ELSE 0 END) AS TurnoverRate,
				   @TurnoverGenScope AS SummaryScope,
				   @TurnoverGenSummaryLabel AS SummaryLabel,
				   CONVERT(VARCHAR(10), @TurnoverGenRangeStart, 120) AS SummaryStartDate,
				   CONVERT(VARCHAR(10), @TurnoverGenRangeEnd, 120) AS SummaryEndDate
			FROM Generations G
			LEFT JOIN PresentAverage P ON P.Generation = G.Generation
			LEFT JOIN TerminatedByGen T ON T.Generation = G.Generation
			ORDER BY G.GenerationSort;
		END		
		ELSE IF (@ChartID = 'main_chart_92')
		BEGIN
			-- "Ty le nghi viec theo tham nien qua cac nam" => moi nam 1 cot xep chong + 1 diem duong ty le.
			DECLARE @C92Years TABLE (rn INT IDENTITY(1,1), Yr INT);
			INSERT INTO @C92Years (Yr) SELECT DISTINCT ID FROM @Years ORDER BY ID;
			IF NOT EXISTS (SELECT 1 FROM @C92Years)
			BEGIN
				DECLARE @C92Fallback INT = NULL;
				SELECT @C92Fallback = MAX(Years) FROM @tblChartChuKyCong WHERE Years IS NOT NULL;
				INSERT INTO @C92Years (Yr) VALUES (ISNULL(@C92Fallback, YEAR(ISNULL(@ChartNgayChotCongGanNhat, @dDate))));
			END

			DECLARE @C92Out TABLE
			(
				Category NVARCHAR(50), YearLabel NVARCHAR(4), YearSort INT, CategorySort INT,
				[Value] DECIMAL(18,2), RawCount INT, TerminatedCount INT, AverageEmployeeCount DECIMAL(18,4), IsLine BIT
			);
			DECLARE @C92Months TABLE (MonthNo INT NOT NULL PRIMARY KEY, PeriodStart DATE NOT NULL, PeriodEnd DATE NOT NULL);
			DECLARE @C92_i INT = 1, @C92_cnt INT = (SELECT COUNT(1) FROM @C92Years), @C92Yr INT, @C92Start DATE, @C92End DATE;

			WHILE @C92_i <= @C92_cnt
			BEGIN
				SET @C92Yr = (SELECT Yr FROM @C92Years WHERE rn = @C92_i);
				SET @C92Start = DATEFROMPARTS(@C92Yr, 1, 1);
				SET @C92End = DATEFROMPARTS(@C92Yr, 12, 31);

				DELETE FROM @C92Months;
				INSERT INTO @C92Months (MonthNo, PeriodStart, PeriodEnd)
				SELECT V.MonthNo, DATEFROMPARTS(@C92Yr, V.MonthNo, 1), EOMONTH(DATEFROMPARTS(@C92Yr, V.MonthNo, 1))
				FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12)) V(MonthNo);

				;WITH TerminatedEmployees AS
				(
					SELECT DISTINCT E.EmpID,
							CASE WHEN E.StartDate IS NULL THEN NULL ELSE ROUND(DATEDIFF(DAY, CONVERT(DATE, E.StartDate), CONVERT(DATE, TER.EffectDate)) / 365.0, 2) END AS SeniorityYear
					FROM dbo.TER_tblTermination (NOLOCK) TER
					INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = TER.EmpID
					WHERE TER.EffectDate IS NOT NULL
					AND CONVERT(DATE, TER.EffectDate) BETWEEN @C92Start AND @C92End
				AND (NOT EXISTS (SELECT 1 FROM @Companys) OR E.LSCompanyID IN (SELECT ID FROM @Companys))
				AND (NOT EXISTS (SELECT 1 FROM @LoaiChucDanhs) OR E.LSLoaiChucDanhID IN (SELECT ID FROM @LoaiChucDanhs))
				AND (NOT EXISTS (SELECT 1 FROM @Level1s) OR E.LSLevel1ID IN (SELECT ID FROM @Level1s))
				AND (NOT EXISTS (SELECT 1 FROM @Level2s) OR E.LSLevel2ID IN (SELECT ID FROM @Level2s))
				AND (NOT EXISTS (SELECT 1 FROM @Level3s) OR E.LSLevel3ID IN (SELECT ID FROM @Level3s))
				AND (NOT EXISTS (SELECT 1 FROM @Level4s) OR E.LSLevel4ID IN (SELECT ID FROM @Level4s))
				AND (NOT EXISTS (SELECT 1 FROM @Level5s) OR E.LSLevel5ID IN (SELECT ID FROM @Level5s))
				AND (NOT EXISTS (SELECT 1 FROM @Level6s) OR E.LSLevel6ID IN (SELECT ID FROM @Level6s))
				AND (NOT EXISTS (SELECT 1 FROM @Level7s) OR E.LSLevel7ID IN (SELECT ID FROM @Level7s))
				AND (NOT EXISTS (SELECT 1 FROM @Level8s) OR E.LSLevel8ID IN (SELECT ID FROM @Level8s))
				AND (NOT EXISTS (SELECT 1 FROM @Level9s) OR E.LSLevel9ID IN (SELECT ID FROM @Level9s))					AND EXISTS (SELECT 1 FROM dbo.fnGetAllEmp_Permission_EffDate(@UserGroupID, @FunctionID, CONVERT(DATE, TER.EffectDate)) P WHERE P.EmpID = TER.EmpID)
				),
				TerminatedByGroup AS
				(
					SELECT CASE
							   WHEN SeniorityYear IS NULL THEN N'Không xác định'
							   WHEN SeniorityYear < 1 THEN N'Dưới 1 năm'
							   WHEN SeniorityYear < 3 THEN N'Từ 01 - 03 năm'
							   WHEN SeniorityYear < 5 THEN N'Từ 03 - 05 năm'
							   ELSE N'Trên 5 năm'
						   END AS Category,
						   COUNT(1) AS TerminatedCount
					FROM TerminatedEmployees
					GROUP BY CASE
							   WHEN SeniorityYear IS NULL THEN N'Không xác định'
							   WHEN SeniorityYear < 1 THEN N'Dưới 1 năm'
							   WHEN SeniorityYear < 3 THEN N'Từ 01 - 03 năm'
							   WHEN SeniorityYear < 5 THEN N'Từ 03 - 05 năm'
							   ELSE N'Trên 5 năm'
						   END
				),
				MonthlyPresent AS
				(
					SELECT M.MonthNo, COUNT(DISTINCT E.EmpID) AS PresentCount
					FROM @C92Months M
					CROSS APPLY dbo.fnGetAllEmp_Permission_EffDate(@UserGroupID, @FunctionID, M.PeriodEnd) P
					INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = P.EmpID
					WHERE (E.StartDate IS NULL OR CONVERT(DATE, E.StartDate) <= M.PeriodEnd)
				AND (NOT EXISTS (SELECT 1 FROM @Companys) OR E.LSCompanyID IN (SELECT ID FROM @Companys))
				AND (NOT EXISTS (SELECT 1 FROM @LoaiChucDanhs) OR E.LSLoaiChucDanhID IN (SELECT ID FROM @LoaiChucDanhs))
				AND (NOT EXISTS (SELECT 1 FROM @Level1s) OR E.LSLevel1ID IN (SELECT ID FROM @Level1s))
				AND (NOT EXISTS (SELECT 1 FROM @Level2s) OR E.LSLevel2ID IN (SELECT ID FROM @Level2s))
				AND (NOT EXISTS (SELECT 1 FROM @Level3s) OR E.LSLevel3ID IN (SELECT ID FROM @Level3s))
				AND (NOT EXISTS (SELECT 1 FROM @Level4s) OR E.LSLevel4ID IN (SELECT ID FROM @Level4s))
				AND (NOT EXISTS (SELECT 1 FROM @Level5s) OR E.LSLevel5ID IN (SELECT ID FROM @Level5s))
				AND (NOT EXISTS (SELECT 1 FROM @Level6s) OR E.LSLevel6ID IN (SELECT ID FROM @Level6s))
				AND (NOT EXISTS (SELECT 1 FROM @Level7s) OR E.LSLevel7ID IN (SELECT ID FROM @Level7s))
				AND (NOT EXISTS (SELECT 1 FROM @Level8s) OR E.LSLevel8ID IN (SELECT ID FROM @Level8s))
				AND (NOT EXISTS (SELECT 1 FROM @Level9s) OR E.LSLevel9ID IN (SELECT ID FROM @Level9s))					AND NOT EXISTS (SELECT 1 FROM dbo.TER_tblTermination (NOLOCK) TER WHERE TER.EmpID = E.EmpID AND TER.EffectDate IS NOT NULL AND CONVERT(DATE, TER.EffectDate) <= M.PeriodEnd)
					GROUP BY M.MonthNo
				),
				MonthlyTerminated AS
				(
					SELECT M.MonthNo, COUNT(DISTINCT TER.EmpID) AS TerminatedCount
					FROM @C92Months M
					INNER JOIN dbo.TER_tblTermination (NOLOCK) TER ON CONVERT(DATE, TER.EffectDate) BETWEEN M.PeriodStart AND M.PeriodEnd
					INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = TER.EmpID
					WHERE TER.EffectDate IS NOT NULL
				AND (NOT EXISTS (SELECT 1 FROM @Companys) OR E.LSCompanyID IN (SELECT ID FROM @Companys))
				AND (NOT EXISTS (SELECT 1 FROM @LoaiChucDanhs) OR E.LSLoaiChucDanhID IN (SELECT ID FROM @LoaiChucDanhs))
				AND (NOT EXISTS (SELECT 1 FROM @Level1s) OR E.LSLevel1ID IN (SELECT ID FROM @Level1s))
				AND (NOT EXISTS (SELECT 1 FROM @Level2s) OR E.LSLevel2ID IN (SELECT ID FROM @Level2s))
				AND (NOT EXISTS (SELECT 1 FROM @Level3s) OR E.LSLevel3ID IN (SELECT ID FROM @Level3s))
				AND (NOT EXISTS (SELECT 1 FROM @Level4s) OR E.LSLevel4ID IN (SELECT ID FROM @Level4s))
				AND (NOT EXISTS (SELECT 1 FROM @Level5s) OR E.LSLevel5ID IN (SELECT ID FROM @Level5s))
				AND (NOT EXISTS (SELECT 1 FROM @Level6s) OR E.LSLevel6ID IN (SELECT ID FROM @Level6s))
				AND (NOT EXISTS (SELECT 1 FROM @Level7s) OR E.LSLevel7ID IN (SELECT ID FROM @Level7s))
				AND (NOT EXISTS (SELECT 1 FROM @Level8s) OR E.LSLevel8ID IN (SELECT ID FROM @Level8s))
				AND (NOT EXISTS (SELECT 1 FROM @Level9s) OR E.LSLevel9ID IN (SELECT ID FROM @Level9s))					AND EXISTS (SELECT 1 FROM dbo.fnGetAllEmp_Permission_EffDate(@UserGroupID, @FunctionID, CONVERT(DATE, TER.EffectDate)) P WHERE P.EmpID = TER.EmpID)
					GROUP BY M.MonthNo
				),
				MonthlyAverageBase AS
				(
					SELECT M.MonthNo, CONVERT(DECIMAL(18,4), ISNULL(P.PresentCount,0) + ISNULL(T.TerminatedCount,0)) AS EmployeeCount
					FROM @C92Months M
					LEFT JOIN MonthlyPresent P ON P.MonthNo = M.MonthNo
					LEFT JOIN MonthlyTerminated T ON T.MonthNo = M.MonthNo
				),
				Summary AS
				(
					SELECT CONVERT(DECIMAL(18,4), ISNULL(AVG(EmployeeCount),0)) AS AverageEmployeeCount,
						   ISNULL((SELECT COUNT(1) FROM TerminatedEmployees), 0) AS TotalTerminatedCount
					FROM MonthlyAverageBase
				),
				Categories AS
				(
					SELECT N'Dưới 1 năm' AS Category, 1 AS CategorySort
					UNION ALL SELECT N'Từ 01 - 03 năm', 2
					UNION ALL SELECT N'Từ 03 - 05 năm', 3
					UNION ALL SELECT N'Trên 5 năm', 4
				)
				INSERT INTO @C92Out (Category, YearLabel, YearSort, CategorySort, [Value], RawCount, TerminatedCount, AverageEmployeeCount, IsLine)
				SELECT C.Category, CONVERT(NVARCHAR(4), @C92Yr), @C92Yr, C.CategorySort,
					   CONVERT(DECIMAL(18,2), CASE WHEN S.TotalTerminatedCount > 0 THEN ISNULL(T.TerminatedCount,0) * 100.0 / S.TotalTerminatedCount ELSE 0 END),
					   ISNULL(T.TerminatedCount,0), S.TotalTerminatedCount, S.AverageEmployeeCount, 0
				FROM Categories C CROSS JOIN Summary S LEFT JOIN TerminatedByGroup T ON T.Category = C.Category
				UNION ALL
				SELECT N'Tỷ lệ nghỉ việc SHB', CONVERT(NVARCHAR(4), @C92Yr), @C92Yr, 99,
					   CONVERT(DECIMAL(18,2), CASE WHEN S.AverageEmployeeCount > 0 THEN S.TotalTerminatedCount * 100.0 / S.AverageEmployeeCount ELSE 0 END),
					   S.TotalTerminatedCount, S.TotalTerminatedCount, S.AverageEmployeeCount, 1
				FROM Summary S;

				SET @C92_i = @C92_i + 1;
			END

			DECLARE @C92Label NVARCHAR(50) = (SELECT CASE WHEN MIN(Yr) = MAX(Yr) THEN CONVERT(NVARCHAR(4), MIN(Yr))
													  ELSE CONVERT(NVARCHAR(4), MIN(Yr)) + N' - ' + CONVERT(NVARCHAR(4), MAX(Yr)) END FROM @C92Years);

			SELECT Category, YearLabel, YearSort, CategorySort, [Value], RawCount, TerminatedCount,
				   AverageEmployeeCount, CAST(IsLine AS BIT) AS IsLine, @C92Label AS SummaryLabel
			FROM @C92Out
			ORDER BY CategorySort, YearSort;
		END		
		ELSE IF (@ChartID = 'main_chart_91')
		BEGIN
			-- "Ty le nghi viec qua cac nam": cot xep chong NS binh quan (DVKD/HO) + line SHB + line benchmark nganh.
			DECLARE @C91Years TABLE (rn INT IDENTITY(1,1), Yr INT);
			INSERT INTO @C91Years (Yr) SELECT DISTINCT ID FROM @Years ORDER BY ID;
			IF NOT EXISTS (SELECT 1 FROM @C91Years)
			BEGIN
				DECLARE @C91Fallback INT = NULL;
				SELECT @C91Fallback = MAX(Years) FROM @tblChartChuKyCong WHERE Years IS NOT NULL;
				INSERT INTO @C91Years (Yr) VALUES (ISNULL(@C91Fallback, YEAR(ISNULL(@ChartNgayChotCongGanNhat, @dDate))));
			END

			DECLARE @C91Out TABLE
			(
				YearLabel NVARCHAR(4), YearSort INT,
				DVKDAvg DECIMAL(18,2), HOAvg DECIMAL(18,2),
				DVKDSep INT, HOSep INT,
				DVKDRate DECIMAL(18,2), HORate DECIMAL(18,2),
				SHBRate DECIMAL(18,2), BenchmarkRate DECIMAL(18,2)
			);
			DECLARE @C91Months TABLE (MonthNo INT PRIMARY KEY, PeriodStart DATE, PeriodEnd DATE);
			DECLARE @C91MPres TABLE (MonthNo INT, OrgCode NVARCHAR(20), Cnt INT);
			DECLARE @C91MSep TABLE (MonthNo INT, OrgCode NVARCHAR(20), Cnt INT);
			DECLARE @C91_i INT = 1, @C91_cnt INT = (SELECT COUNT(1) FROM @C91Years), @C91Yr INT;
			DECLARE @c91pD DECIMAL(18,4), @c91pH DECIMAL(18,4), @c91sD DECIMAL(18,4), @c91sH DECIMAL(18,4);

			WHILE @C91_i <= @C91_cnt
			BEGIN
				SET @C91Yr = (SELECT Yr FROM @C91Years WHERE rn = @C91_i);
				DELETE FROM @C91Months; DELETE FROM @C91MPres; DELETE FROM @C91MSep;
				INSERT INTO @C91Months (MonthNo, PeriodStart, PeriodEnd)
				SELECT V.MonthNo, DATEFROMPARTS(@C91Yr, V.MonthNo, 1), EOMONTH(DATEFROMPARTS(@C91Yr, V.MonthNo, 1))
				FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12)) V(MonthNo);

				INSERT INTO @C91MPres (MonthNo, OrgCode, Cnt)
				SELECT M.MonthNo, O.OrgCode, COUNT(DISTINCT E.EmpID)
				FROM @C91Months M
				CROSS APPLY dbo.fnGetAllEmp_Permission_EffDate(@UserGroupID, @FunctionID, M.PeriodEnd) P
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = P.EmpID
				OUTER APPLY
				(
					SELECT TOP 1 TT.LSThuocTinhCoCau1Code AS OrgCode
					FROM dbo.HR_tblWorkingRecord (NOLOCK) WR
					LEFT JOIN dbo.LS_tblCompany (NOLOCK) CO ON CO.LSCompanyID = ISNULL(WR.LSCompanyID, E.LSCompanyID)
					LEFT JOIN dbo.LS_tblLevel1 (NOLOCK) L1 ON L1.LSLevel1ID = ISNULL(WR.LSLevel1ID, E.LSLevel1ID)
					LEFT JOIN dbo.LS_tblLevel2 (NOLOCK) L2 ON L2.LSLevel2ID = ISNULL(WR.LSLevel2ID, E.LSLevel2ID)
					LEFT JOIN dbo.LS_tblLevel3 (NOLOCK) L3 ON L3.LSLevel3ID = ISNULL(WR.LSLevel3ID, E.LSLevel3ID)
					LEFT JOIN dbo.LS_tblLevel4 (NOLOCK) L4 ON L4.LSLevel4ID = ISNULL(WR.LSLevel4ID, E.LSLevel4ID)
					LEFT JOIN dbo.LS_tblLevel5 (NOLOCK) L5 ON L5.LSLevel5ID = ISNULL(WR.LSLevel5ID, E.LSLevel5ID)
					LEFT JOIN dbo.LS_tblLevel6 (NOLOCK) L6 ON L6.LSLevel6ID = ISNULL(WR.LSLevel6ID, E.LSLevel6ID)
					LEFT JOIN dbo.LS_tblLevel7 (NOLOCK) L7 ON L7.LSLevel7ID = ISNULL(WR.LSLevel7ID, E.LSLevel7ID)
					LEFT JOIN dbo.LS_tblLevel8 (NOLOCK) L8 ON L8.LSLevel8ID = ISNULL(WR.LSLevel8ID, E.LSLevel8ID)
					LEFT JOIN dbo.LS_tblLevel9 (NOLOCK) L9 ON L9.LSLevel9ID = ISNULL(WR.LSLevel9ID, E.LSLevel9ID)
					LEFT JOIN dbo.LS_tblThuocTinhCoCau1 (NOLOCK) TT ON TT.LSThuocTinhCoCau1ID =
						CASE WHEN L9.LSThuocTinhCoCau1ID IS NOT NULL THEN L9.LSThuocTinhCoCau1ID
							 WHEN L8.LSThuocTinhCoCau1ID IS NOT NULL THEN L8.LSThuocTinhCoCau1ID
							 WHEN L7.LSThuocTinhCoCau1ID IS NOT NULL THEN L7.LSThuocTinhCoCau1ID
							 WHEN L6.LSThuocTinhCoCau1ID IS NOT NULL THEN L6.LSThuocTinhCoCau1ID
							 WHEN L5.LSThuocTinhCoCau1ID IS NOT NULL THEN L5.LSThuocTinhCoCau1ID
							 WHEN L4.LSThuocTinhCoCau1ID IS NOT NULL THEN L4.LSThuocTinhCoCau1ID
							 WHEN L3.LSThuocTinhCoCau1ID IS NOT NULL THEN L3.LSThuocTinhCoCau1ID
							 WHEN L2.LSThuocTinhCoCau1ID IS NOT NULL THEN L2.LSThuocTinhCoCau1ID
							 WHEN L1.LSThuocTinhCoCau1ID IS NOT NULL THEN L1.LSThuocTinhCoCau1ID
							 ELSE CO.LSThuocTinhCoCau1ID END
					WHERE WR.EmpID = E.EmpID
					AND ISNULL(WR.FromDate, WR.NgayHieuLuc) IS NOT NULL
					AND CONVERT(DATE, ISNULL(WR.FromDate, WR.NgayHieuLuc)) <= M.PeriodEnd
					AND (WR.ToDate IS NULL OR CONVERT(DATE, WR.ToDate) >= M.PeriodEnd)
					ORDER BY CONVERT(DATE, ISNULL(WR.FromDate, WR.NgayHieuLuc)) DESC, WR.WorkingRecordID DESC
				) O
				WHERE (E.StartDate IS NULL OR CONVERT(DATE, E.StartDate) <= M.PeriodEnd)
				AND (NOT EXISTS (SELECT 1 FROM @Companys) OR E.LSCompanyID IN (SELECT ID FROM @Companys))
				AND (NOT EXISTS (SELECT 1 FROM @LoaiChucDanhs) OR E.LSLoaiChucDanhID IN (SELECT ID FROM @LoaiChucDanhs))
				AND (NOT EXISTS (SELECT 1 FROM @Level1s) OR E.LSLevel1ID IN (SELECT ID FROM @Level1s))
				AND (NOT EXISTS (SELECT 1 FROM @Level2s) OR E.LSLevel2ID IN (SELECT ID FROM @Level2s))
				AND (NOT EXISTS (SELECT 1 FROM @Level3s) OR E.LSLevel3ID IN (SELECT ID FROM @Level3s))
				AND (NOT EXISTS (SELECT 1 FROM @Level4s) OR E.LSLevel4ID IN (SELECT ID FROM @Level4s))
				AND (NOT EXISTS (SELECT 1 FROM @Level5s) OR E.LSLevel5ID IN (SELECT ID FROM @Level5s))
				AND (NOT EXISTS (SELECT 1 FROM @Level6s) OR E.LSLevel6ID IN (SELECT ID FROM @Level6s))
				AND (NOT EXISTS (SELECT 1 FROM @Level7s) OR E.LSLevel7ID IN (SELECT ID FROM @Level7s))
				AND (NOT EXISTS (SELECT 1 FROM @Level8s) OR E.LSLevel8ID IN (SELECT ID FROM @Level8s))
				AND (NOT EXISTS (SELECT 1 FROM @Level9s) OR E.LSLevel9ID IN (SELECT ID FROM @Level9s))					AND O.OrgCode IN (N'HO', N'ĐVKD')
					AND NOT EXISTS (SELECT 1 FROM dbo.TER_tblTermination (NOLOCK) TER WHERE TER.EmpID = E.EmpID AND TER.EffectDate IS NOT NULL AND CONVERT(DATE, TER.EffectDate) <= M.PeriodEnd)
				GROUP BY M.MonthNo, O.OrgCode;

				INSERT INTO @C91MSep (MonthNo, OrgCode, Cnt)
				SELECT M.MonthNo, O.OrgCode, COUNT(DISTINCT TER.EmpID)
				FROM @C91Months M
				INNER JOIN dbo.TER_tblTermination (NOLOCK) TER ON CONVERT(DATE, TER.EffectDate) BETWEEN M.PeriodStart AND M.PeriodEnd
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = TER.EmpID
				OUTER APPLY
				(
					SELECT TOP 1 TT.LSThuocTinhCoCau1Code AS OrgCode
					FROM dbo.HR_tblWorkingRecord (NOLOCK) WR
					LEFT JOIN dbo.LS_tblCompany (NOLOCK) CO ON CO.LSCompanyID = ISNULL(WR.LSCompanyID, E.LSCompanyID)
					LEFT JOIN dbo.LS_tblLevel1 (NOLOCK) L1 ON L1.LSLevel1ID = ISNULL(WR.LSLevel1ID, E.LSLevel1ID)
					LEFT JOIN dbo.LS_tblLevel2 (NOLOCK) L2 ON L2.LSLevel2ID = ISNULL(WR.LSLevel2ID, E.LSLevel2ID)
					LEFT JOIN dbo.LS_tblLevel3 (NOLOCK) L3 ON L3.LSLevel3ID = ISNULL(WR.LSLevel3ID, E.LSLevel3ID)
					LEFT JOIN dbo.LS_tblLevel4 (NOLOCK) L4 ON L4.LSLevel4ID = ISNULL(WR.LSLevel4ID, E.LSLevel4ID)
					LEFT JOIN dbo.LS_tblLevel5 (NOLOCK) L5 ON L5.LSLevel5ID = ISNULL(WR.LSLevel5ID, E.LSLevel5ID)
					LEFT JOIN dbo.LS_tblLevel6 (NOLOCK) L6 ON L6.LSLevel6ID = ISNULL(WR.LSLevel6ID, E.LSLevel6ID)
					LEFT JOIN dbo.LS_tblLevel7 (NOLOCK) L7 ON L7.LSLevel7ID = ISNULL(WR.LSLevel7ID, E.LSLevel7ID)
					LEFT JOIN dbo.LS_tblLevel8 (NOLOCK) L8 ON L8.LSLevel8ID = ISNULL(WR.LSLevel8ID, E.LSLevel8ID)
					LEFT JOIN dbo.LS_tblLevel9 (NOLOCK) L9 ON L9.LSLevel9ID = ISNULL(WR.LSLevel9ID, E.LSLevel9ID)
					LEFT JOIN dbo.LS_tblThuocTinhCoCau1 (NOLOCK) TT ON TT.LSThuocTinhCoCau1ID =
						CASE WHEN L9.LSThuocTinhCoCau1ID IS NOT NULL THEN L9.LSThuocTinhCoCau1ID
							 WHEN L8.LSThuocTinhCoCau1ID IS NOT NULL THEN L8.LSThuocTinhCoCau1ID
							 WHEN L7.LSThuocTinhCoCau1ID IS NOT NULL THEN L7.LSThuocTinhCoCau1ID
							 WHEN L6.LSThuocTinhCoCau1ID IS NOT NULL THEN L6.LSThuocTinhCoCau1ID
							 WHEN L5.LSThuocTinhCoCau1ID IS NOT NULL THEN L5.LSThuocTinhCoCau1ID
							 WHEN L4.LSThuocTinhCoCau1ID IS NOT NULL THEN L4.LSThuocTinhCoCau1ID
							 WHEN L3.LSThuocTinhCoCau1ID IS NOT NULL THEN L3.LSThuocTinhCoCau1ID
							 WHEN L2.LSThuocTinhCoCau1ID IS NOT NULL THEN L2.LSThuocTinhCoCau1ID
							 WHEN L1.LSThuocTinhCoCau1ID IS NOT NULL THEN L1.LSThuocTinhCoCau1ID
							 ELSE CO.LSThuocTinhCoCau1ID END
					WHERE WR.EmpID = E.EmpID
					AND ISNULL(WR.FromDate, WR.NgayHieuLuc) IS NOT NULL
					AND CONVERT(DATE, ISNULL(WR.FromDate, WR.NgayHieuLuc)) <= CONVERT(DATE, TER.EffectDate)
					AND (WR.ToDate IS NULL OR CONVERT(DATE, WR.ToDate) >= CONVERT(DATE, TER.EffectDate))
					ORDER BY CONVERT(DATE, ISNULL(WR.FromDate, WR.NgayHieuLuc)) DESC, WR.WorkingRecordID DESC
				) O
				WHERE TER.EffectDate IS NOT NULL
				AND (NOT EXISTS (SELECT 1 FROM @Companys) OR E.LSCompanyID IN (SELECT ID FROM @Companys))
				AND (NOT EXISTS (SELECT 1 FROM @LoaiChucDanhs) OR E.LSLoaiChucDanhID IN (SELECT ID FROM @LoaiChucDanhs))
				AND (NOT EXISTS (SELECT 1 FROM @Level1s) OR E.LSLevel1ID IN (SELECT ID FROM @Level1s))
				AND (NOT EXISTS (SELECT 1 FROM @Level2s) OR E.LSLevel2ID IN (SELECT ID FROM @Level2s))
				AND (NOT EXISTS (SELECT 1 FROM @Level3s) OR E.LSLevel3ID IN (SELECT ID FROM @Level3s))
				AND (NOT EXISTS (SELECT 1 FROM @Level4s) OR E.LSLevel4ID IN (SELECT ID FROM @Level4s))
				AND (NOT EXISTS (SELECT 1 FROM @Level5s) OR E.LSLevel5ID IN (SELECT ID FROM @Level5s))
				AND (NOT EXISTS (SELECT 1 FROM @Level6s) OR E.LSLevel6ID IN (SELECT ID FROM @Level6s))
				AND (NOT EXISTS (SELECT 1 FROM @Level7s) OR E.LSLevel7ID IN (SELECT ID FROM @Level7s))
				AND (NOT EXISTS (SELECT 1 FROM @Level8s) OR E.LSLevel8ID IN (SELECT ID FROM @Level8s))
				AND (NOT EXISTS (SELECT 1 FROM @Level9s) OR E.LSLevel9ID IN (SELECT ID FROM @Level9s))					AND O.OrgCode IN (N'HO', N'ĐVKD')
					AND EXISTS (SELECT 1 FROM dbo.fnGetAllEmp_Permission_EffDate(@UserGroupID, @FunctionID, CONVERT(DATE, TER.EffectDate)) PQ WHERE PQ.EmpID = TER.EmpID)
				GROUP BY M.MonthNo, O.OrgCode;

				SET @c91pD = (SELECT ISNULL(SUM(Cnt),0) FROM @C91MPres WHERE OrgCode = N'ĐVKD');
				SET @c91pH = (SELECT ISNULL(SUM(Cnt),0) FROM @C91MPres WHERE OrgCode = N'HO');
				SET @c91sD = (SELECT ISNULL(SUM(Cnt),0) FROM @C91MSep WHERE OrgCode = N'ĐVKD');
				SET @c91sH = (SELECT ISNULL(SUM(Cnt),0) FROM @C91MSep WHERE OrgCode = N'HO');

				INSERT INTO @C91Out (YearLabel, YearSort, DVKDAvg, HOAvg, DVKDSep, HOSep, DVKDRate, HORate, SHBRate, BenchmarkRate)
				SELECT CONVERT(NVARCHAR(4), @C91Yr), @C91Yr,
					   CONVERT(DECIMAL(18,2), (@c91pD + @c91sD) / 12.0),
					   CONVERT(DECIMAL(18,2), (@c91pH + @c91sH) / 12.0),
					   CONVERT(INT, @c91sD), CONVERT(INT, @c91sH),
					   CONVERT(DECIMAL(18,2), CASE WHEN (@c91pD + @c91sD) > 0 THEN @c91sD * 1200.0 / (@c91pD + @c91sD) ELSE 0 END),
					   CONVERT(DECIMAL(18,2), CASE WHEN (@c91pH + @c91sH) > 0 THEN @c91sH * 1200.0 / (@c91pH + @c91sH) ELSE 0 END),
					   CONVERT(DECIMAL(18,2), CASE WHEN (@c91pD + @c91sD + @c91pH + @c91sH) > 0 THEN (@c91sD + @c91sH) * 1200.0 / (@c91pD + @c91sD + @c91pH + @c91sH) ELSE 0 END),
					   (SELECT TOP 1 TyLeNghiViec FROM dbo.NEW_tblTyLeNghiViecNganhNganHang (NOLOCK) WHERE [Year] = @C91Yr ORDER BY ISNULL(EditTime, CreateTime) DESC, ID DESC);

				SET @C91_i = @C91_i + 1;
			END

			DECLARE @C91Label NVARCHAR(50) = (SELECT CASE WHEN MIN(Yr) = MAX(Yr) THEN CONVERT(NVARCHAR(4), MIN(Yr))
													  ELSE CONVERT(NVARCHAR(4), MIN(Yr)) + N' - ' + CONVERT(NVARCHAR(4), MAX(Yr)) END FROM @C91Years);

			SELECT YearLabel, YearSort, DVKDAvg, HOAvg, DVKDSep, HOSep, DVKDRate, HORate, SHBRate, BenchmarkRate, @C91Label AS SummaryLabel
			FROM @C91Out
			ORDER BY YearSort;
		END		
		ELSE IF (@ChartID IN ('main_chart_88', 'main_chart_306')) -- 306: alias doi kieu chart (nightingale rose) - dung chung logic voi 88
		BEGIN
			DECLARE @SenioritySummaryDate DATE = CONVERT(DATE, COALESCE(@ChartLastDateTimeLine, @ChartNgayChotCongGanNhat, @dDate));

			IF NOT EXISTS (SELECT 1 FROM @Employees WHERE ID > 0)
			BEGIN
				INSERT INTO @Employees (ID)
				SELECT DISTINCT P.EmpID
				FROM dbo.fnGetAllEmp_Permission_EffDate(@UserGroupID, @FunctionID, @SenioritySummaryDate) P
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = P.EmpID
				WHERE (E.StartDate IS NULL OR CONVERT(DATE, E.StartDate) <= @SenioritySummaryDate)
				AND (NOT EXISTS (SELECT 1 FROM @Companys) OR E.LSCompanyID IN (SELECT ID FROM @Companys))
				AND (NOT EXISTS (SELECT 1 FROM @LoaiChucDanhs) OR E.LSLoaiChucDanhID IN (SELECT ID FROM @LoaiChucDanhs))
				AND (NOT EXISTS (SELECT 1 FROM @Level1s) OR E.LSLevel1ID IN (SELECT ID FROM @Level1s))
				AND (NOT EXISTS (SELECT 1 FROM @Level2s) OR E.LSLevel2ID IN (SELECT ID FROM @Level2s))
				AND (NOT EXISTS (SELECT 1 FROM @Level3s) OR E.LSLevel3ID IN (SELECT ID FROM @Level3s))
				AND (NOT EXISTS (SELECT 1 FROM @Level4s) OR E.LSLevel4ID IN (SELECT ID FROM @Level4s))
				AND (NOT EXISTS (SELECT 1 FROM @Level5s) OR E.LSLevel5ID IN (SELECT ID FROM @Level5s))
				AND (NOT EXISTS (SELECT 1 FROM @Level6s) OR E.LSLevel6ID IN (SELECT ID FROM @Level6s))
				AND (NOT EXISTS (SELECT 1 FROM @Level7s) OR E.LSLevel7ID IN (SELECT ID FROM @Level7s))
				AND (NOT EXISTS (SELECT 1 FROM @Level8s) OR E.LSLevel8ID IN (SELECT ID FROM @Level8s))
				AND (NOT EXISTS (SELECT 1 FROM @Level9s) OR E.LSLevel9ID IN (SELECT ID FROM @Level9s));
			END

			;WITH PresentEmployees AS
			(
				SELECT DISTINCT E.EmpID, CONVERT(DATE, E.StartDate) AS StartDate
				FROM @Employees A
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = A.ID
				WHERE A.ID > 0
				AND (E.StartDate IS NULL OR CONVERT(DATE, E.StartDate) <= @SenioritySummaryDate)
				AND NOT EXISTS
				(
					SELECT 1
					FROM dbo.TER_tblTermination (NOLOCK) TER
					WHERE TER.EmpID = E.EmpID
					AND TER.EffectDate IS NOT NULL AND CONVERT(DATE, TER.EffectDate) <= @SenioritySummaryDate
				)
			),
			EmployeeSeniority AS
			(
				SELECT	EmpID,
						StartDate,
						CASE WHEN StartDate IS NULL THEN NULL ELSE ROUND(DATEDIFF(DAY, StartDate, @SenioritySummaryDate) / 365.0, 2) END AS SeniorityYear
				FROM PresentEmployees
			),
			SeniorityGroups AS
			(
				SELECT	EmpID,
						CASE
							WHEN SeniorityYear IS NULL THEN N'Không xác định'
							WHEN SeniorityYear < 1 THEN N'Dưới 1 năm'
							WHEN SeniorityYear < 3 THEN N'Từ 01 - 03 năm'
							WHEN SeniorityYear < 5 THEN N'Từ 03 - 05 năm'
							ELSE N'Trên 5 năm'
						END AS Category,
						CASE
							WHEN SeniorityYear IS NULL THEN 5
							WHEN SeniorityYear < 1 THEN 1
							WHEN SeniorityYear < 3 THEN 2
							WHEN SeniorityYear < 5 THEN 3
							ELSE 4
						END AS SortOrder
				FROM EmployeeSeniority
			)
			SELECT	Category,
					COUNT(1) AS [Value],
					CONVERT(VARCHAR(10), @SenioritySummaryDate, 120) AS SummaryDate,
					N'T' + RIGHT('0' + CONVERT(VARCHAR(2), MONTH(@SenioritySummaryDate)), 2) + N'/' + CONVERT(VARCHAR(4), YEAR(@SenioritySummaryDate)) AS SummaryLabel
			FROM SeniorityGroups
			GROUP BY Category, SortOrder
			ORDER BY SortOrder;
		END		
		ELSE IF (@ChartID IN ('main_chart_87', 'main_chart_305')) -- 305: alias doi kieu chart (vertical bar) - dung chung logic voi 87
		BEGIN
			DECLARE @AgeSummaryDate DATE = CONVERT(DATE, COALESCE(@ChartLastDateTimeLine, @ChartNgayChotCongGanNhat, @dDate));
			DECLARE @AgeSummaryYear INT = YEAR(@AgeSummaryDate);

			IF NOT EXISTS (SELECT 1 FROM @Employees WHERE ID > 0)
			BEGIN
				INSERT INTO @Employees (ID)
				SELECT DISTINCT P.EmpID
				FROM dbo.fnGetAllEmp_Permission_EffDate(@UserGroupID, @FunctionID, @AgeSummaryDate) P
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = P.EmpID
				WHERE (E.StartDate IS NULL OR CONVERT(DATE, E.StartDate) <= @AgeSummaryDate)
				AND (NOT EXISTS (SELECT 1 FROM @Companys) OR E.LSCompanyID IN (SELECT ID FROM @Companys))
				AND (NOT EXISTS (SELECT 1 FROM @LoaiChucDanhs) OR E.LSLoaiChucDanhID IN (SELECT ID FROM @LoaiChucDanhs))
				AND (NOT EXISTS (SELECT 1 FROM @Level1s) OR E.LSLevel1ID IN (SELECT ID FROM @Level1s))
				AND (NOT EXISTS (SELECT 1 FROM @Level2s) OR E.LSLevel2ID IN (SELECT ID FROM @Level2s))
				AND (NOT EXISTS (SELECT 1 FROM @Level3s) OR E.LSLevel3ID IN (SELECT ID FROM @Level3s))
				AND (NOT EXISTS (SELECT 1 FROM @Level4s) OR E.LSLevel4ID IN (SELECT ID FROM @Level4s))
				AND (NOT EXISTS (SELECT 1 FROM @Level5s) OR E.LSLevel5ID IN (SELECT ID FROM @Level5s))
				AND (NOT EXISTS (SELECT 1 FROM @Level6s) OR E.LSLevel6ID IN (SELECT ID FROM @Level6s))
				AND (NOT EXISTS (SELECT 1 FROM @Level7s) OR E.LSLevel7ID IN (SELECT ID FROM @Level7s))
				AND (NOT EXISTS (SELECT 1 FROM @Level8s) OR E.LSLevel8ID IN (SELECT ID FROM @Level8s))
				AND (NOT EXISTS (SELECT 1 FROM @Level9s) OR E.LSLevel9ID IN (SELECT ID FROM @Level9s));
			END

			;WITH PresentEmployees AS
			(
				SELECT DISTINCT E.EmpID
				FROM @Employees A
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = A.ID
				WHERE A.ID > 0
				AND (E.StartDate IS NULL OR CONVERT(DATE, E.StartDate) <= @AgeSummaryDate)
				AND NOT EXISTS
				(
					SELECT 1
					FROM dbo.TER_tblTermination (NOLOCK) TER
					WHERE TER.EmpID = E.EmpID
					AND TER.EffectDate IS NOT NULL AND CONVERT(DATE, TER.EffectDate) <= @AgeSummaryDate
				)
			),
			EmployeeAge AS
			(
				SELECT	P.EmpID,
						CASE
							WHEN CV.DOB IS NULL THEN N'Không xác định'
							WHEN (@AgeSummaryYear - YEAR(CV.DOB)) < 25 THEN N'Dưới 25 tuổi'
							WHEN (@AgeSummaryYear - YEAR(CV.DOB)) BETWEEN 25 AND 35 THEN N'Từ 25-35 tuổi'
							WHEN (@AgeSummaryYear - YEAR(CV.DOB)) BETWEEN 36 AND 45 THEN N'Từ 36-45 tuổi'
							WHEN (@AgeSummaryYear - YEAR(CV.DOB)) BETWEEN 46 AND 55 THEN N'Từ 46-55 tuổi'
							ELSE N'Trên 55 tuổi'
						END AS Category,
						CASE
							WHEN CV.DOB IS NULL THEN 6
							WHEN (@AgeSummaryYear - YEAR(CV.DOB)) < 25 THEN 1
							WHEN (@AgeSummaryYear - YEAR(CV.DOB)) BETWEEN 25 AND 35 THEN 2
							WHEN (@AgeSummaryYear - YEAR(CV.DOB)) BETWEEN 36 AND 45 THEN 3
							WHEN (@AgeSummaryYear - YEAR(CV.DOB)) BETWEEN 46 AND 55 THEN 4
							ELSE 5
						END AS SortOrder
				FROM PresentEmployees P
				LEFT JOIN dbo.HR_tblEmpCV (NOLOCK) CV ON CV.EmpID = P.EmpID
			)
			SELECT	Category,
					COUNT(1) AS [Value],
					CONVERT(VARCHAR(10), @AgeSummaryDate, 120) AS SummaryDate,
					N'T' + RIGHT('0' + CONVERT(VARCHAR(2), MONTH(@AgeSummaryDate)), 2) + N'/' + CONVERT(VARCHAR(4), YEAR(@AgeSummaryDate)) AS SummaryLabel
			FROM EmployeeAge
			GROUP BY Category, SortOrder
			ORDER BY SortOrder;
		END		
		ELSE IF (@ChartID = 'main_chart_103')
		BEGIN
			-- 33043RLOG - Bao cao chi phi luong theo mang nghiep vu.
			-- Doanh thu: PR_tblLoaiDinhMucOrg.Amount theo LoaiDinhMucOrgID (TLG: DB khong co cot LSLoaiChucDanhID).
			-- Chi phi luong lay tu PIT_vPITMonth_MMYYYY_0; co cau / vi tri cong viec lay tu PIT_vPITMonthText_MMYYYY_0.
			DECLARE @C103Periods TABLE
			(
				RowID INT IDENTITY(1,1),
				Years INT NOT NULL,
				Months INT NOT NULL,
				PeriodStart DATE NOT NULL,
				PeriodEnd DATE NOT NULL,
				TableSuffix CHAR(6) NOT NULL
			);
			DECLARE @C103Years TABLE (rn INT IDENTITY(1,1), Yr INT NOT NULL);
			DECLARE @C103YrTmp tID;
			DECLARE @C103QtrTmp tID;
			DECLARE @C103MoTmp tID;
			DECLARE @C103Res TABLE (FilterType VARCHAR(10), Value INT);
			DECLARE @C103_i INT = 1;
			DECLARE @C103_cnt INT;
			DECLARE @C103Yr INT;
			DECLARE @C103RangeStart DATE;
			DECLARE @C103RangeEnd DATE;

			INSERT INTO @C103Years (Yr)
			SELECT DISTINCT ID FROM @Years ORDER BY ID;

			IF NOT EXISTS (SELECT 1 FROM @C103Years)
			BEGIN
				INSERT INTO @C103Years (Yr)
				SELECT DISTINCT Years FROM @tblChartChuKyCong WHERE Years IS NOT NULL ORDER BY Years;
			END

			IF NOT EXISTS (SELECT 1 FROM @C103Years)
				INSERT INTO @C103Years (Yr) VALUES (YEAR(@dDate));

			SET @C103_cnt = (SELECT COUNT(1) FROM @C103Years);

			WHILE @C103_i <= @C103_cnt
			BEGIN
				SET @C103Yr = (SELECT Yr FROM @C103Years WHERE rn = @C103_i);
				DELETE FROM @C103YrTmp;
				DELETE FROM @C103QtrTmp;
				DELETE FROM @C103MoTmp;
				DELETE FROM @C103Res;

				INSERT INTO @C103YrTmp (ID) VALUES (@C103Yr);
				INSERT INTO @C103QtrTmp (ID) SELECT ID FROM @Quarters;
				INSERT INTO @C103MoTmp (ID) SELECT ID FROM @Months;

				INSERT INTO @C103Res
				SELECT * FROM dbo.NEW_fnTableResolveTimeFilter(@C103YrTmp, @C103QtrTmp, @C103MoTmp);

				DELETE FROM @C103MoTmp;
				INSERT INTO @C103MoTmp
				SELECT DISTINCT Value FROM @C103Res WHERE FilterType = 'MONTH';

				DELETE FROM @C103QtrTmp;

				INSERT INTO @C103Periods (Years, Months, PeriodStart, PeriodEnd, TableSuffix)
				SELECT DISTINCT g.Years,
					   g.Months,
					   DATEFROMPARTS(g.Years, g.Months, 1),
					   EOMONTH(DATEFROMPARTS(g.Years, g.Months, 1)),
					   RIGHT('0' + CONVERT(VARCHAR(2), g.Months), 2) + CONVERT(CHAR(4), g.Years)
				FROM dbo.NEW_fnTableGenerateChuKyCong(@C103YrTmp, @C103QtrTmp, @C103MoTmp, @dDate) g
				WHERE g.Years IS NOT NULL AND g.Months IS NOT NULL;

				SET @C103_i = @C103_i + 1;
			END

			SELECT @C103RangeStart = MIN(PeriodStart), @C103RangeEnd = MAX(PeriodEnd)
			FROM @C103Periods;

			IF OBJECT_ID('tempdb..#C103SalaryCost') IS NOT NULL DROP TABLE #C103SalaryCost;
			IF OBJECT_ID('tempdb..#C103LoaiChucDanhs') IS NOT NULL DROP TABLE #C103LoaiChucDanhs;

			CREATE TABLE #C103SalaryCost (LSLoaiChucDanhID NVARCHAR(12) NULL, Category NVARCHAR(255) NOT NULL, SalaryCost DECIMAL(18,2) NOT NULL);
			CREATE TABLE #C103LoaiChucDanhs (ID BIGINT NOT NULL PRIMARY KEY);

			INSERT INTO #C103LoaiChucDanhs (ID) SELECT DISTINCT ID FROM @LoaiChucDanhs WHERE ID > 0;

			DECLARE @C103Loop INT = 1;
			DECLARE @C103LoopCount INT = (SELECT COUNT(1) FROM @C103Periods);
			DECLARE @C103Suffix CHAR(6);
			DECLARE @C103PeriodEnd DATE;
			DECLARE @C103PitTable SYSNAME;
			DECLARE @C103SQL NVARCHAR(MAX);

			WHILE @C103Loop <= @C103LoopCount
			BEGIN
				SELECT @C103Suffix = TableSuffix, @C103PeriodEnd = PeriodEnd FROM @C103Periods WHERE RowID = @C103Loop;
				SET @C103PitTable = N'PIT_vPITMonth_' + @C103Suffix + N'_0';

				IF OBJECT_ID(N'dbo.' + @C103PitTable) IS NOT NULL
				AND COL_LENGTH(N'dbo.' + @C103PitTable, 'TT_TongThuNhap_Gross') IS NOT NULL
				BEGIN
					SET @C103SQL = N'
							INSERT INTO #C103SalaryCost (LSLoaiChucDanhID, Category, SalaryCost)
							SELECT JT.LSLoaiChucDanhID,
								   ISNULL(CASE WHEN @LanguageID = ''VN'' THEN LC.VNName ELSE LC.Name END, N''Khong xac dinh'') AS Category,
								   SUM(ISNULL(TRY_CONVERT(DECIMAL(18,2), NUM.TT_TongThuNhap_Gross), 0)) AS SalaryCost
							FROM dbo.' + QUOTENAME(@C103PitTable) + N' (NOLOCK) NUM
							INNER JOIN #EmployeeSalary SE ON SE.EmpID = TRY_CONVERT(BIGINT, NUM.EmpID) AND SE.TableSuffix = @PeriodKey
							LEFT JOIN dbo.LS_tblJobTitle (NOLOCK) JT ON JT.LSJobTitleCode = SE.TK_ViTriCongViecCode_New
							LEFT JOIN dbo.LS_tblLoaiChucDanh (NOLOCK) LC ON LC.LSLoaiChucDanhID = JT.LSLoaiChucDanhID
							WHERE TRY_CONVERT(BIGINT, NUM.EmpID) IS NOT NULL
							AND (NOT EXISTS (SELECT 1 FROM #C103LoaiChucDanhs) OR TRY_CONVERT(BIGINT, JT.LSLoaiChucDanhID) IN (SELECT ID FROM #C103LoaiChucDanhs))
							GROUP BY JT.LSLoaiChucDanhID, ISNULL(CASE WHEN @LanguageID = ''VN'' THEN LC.VNName ELSE LC.Name END, N''Khong xac dinh'');';

					EXEC sp_executesql @C103SQL, N'@LanguageID VARCHAR(2), @PeriodKey CHAR(6)', @LanguageID = @LanguageID, @PeriodKey=@C103Suffix;
				END

				SET @C103Loop = @C103Loop + 1;
			END

			;WITH Revenue AS
			(
				-- TLG: DB nay KHONG co cot PR_tblLoaiDinhMucOrg.LSLoaiChucDanhID (cot rieng SHB them qua 33043RLOG)
				-- => tam thay bang PK LoaiDinhMucOrgID cho store compile duoc; alias giu ten cu de khong dung cac CTE phia duoi
				SELECT O.LoaiDinhMucOrgID AS LSLoaiChucDanhID,
					   ISNULL(CASE WHEN @LanguageID = 'VN' THEN LC.VNName ELSE LC.Name END, N'Khong xac dinh') AS Category,
					   SUM(ISNULL(O.Amount, 0)) AS RevenueAmount
				FROM dbo.PR_tblLoaiDinhMucOrg (NOLOCK) O
				INNER JOIN dbo.LS_tblLoaiDinhMuc (NOLOCK) LDM ON LDM.LSLoaiDinhMucID = O.LSLoaiDinhMucID
				LEFT JOIN dbo.LS_tblLoaiChucDanh (NOLOCK) LC ON LC.LSLoaiChucDanhID = O.LoaiDinhMucOrgID
				WHERE O.LoaiDinhMucOrgID IS NOT NULL
				AND LDM.LSLoaiDinhMucCode = N'DTTH'
				AND (@C103RangeStart IS NULL OR O.EffDate IS NULL OR O.EffDate <= @C103RangeEnd)
				AND (@C103RangeEnd IS NULL OR O.ToDate IS NULL OR O.ToDate >= @C103RangeStart)
				AND (NOT EXISTS (SELECT 1 FROM @Companys) OR O.LSCompanyID IN (SELECT ID FROM @Companys))
				AND (NOT EXISTS (SELECT 1 FROM @Level1s) OR O.LSLevel1ID IN (SELECT ID FROM @Level1s))
				AND (NOT EXISTS (SELECT 1 FROM @Level2s) OR O.LSLevel2ID IN (SELECT ID FROM @Level2s))
				AND (NOT EXISTS (SELECT 1 FROM @Level3s) OR O.LSLevel3ID IN (SELECT ID FROM @Level3s))
				AND (NOT EXISTS (SELECT 1 FROM @Level4s) OR O.LSLevel4ID IN (SELECT ID FROM @Level4s))
				AND (NOT EXISTS (SELECT 1 FROM @Level5s) OR O.LSLevel5ID IN (SELECT ID FROM @Level5s))
				AND (NOT EXISTS (SELECT 1 FROM @Level6s) OR O.LSLevel6ID IN (SELECT ID FROM @Level6s))
				AND (NOT EXISTS (SELECT 1 FROM @LoaiChucDanhs) OR TRY_CONVERT(BIGINT, O.LoaiDinhMucOrgID) IN (SELECT ID FROM @LoaiChucDanhs))
				GROUP BY O.LoaiDinhMucOrgID, ISNULL(CASE WHEN @LanguageID = 'VN' THEN LC.VNName ELSE LC.Name END, N'Khong xac dinh')
			),
			Salary AS
			(
				SELECT LSLoaiChucDanhID, Category, SUM(SalaryCost) AS SalaryCost
				FROM #C103SalaryCost
				GROUP BY LSLoaiChucDanhID, Category
			),
			AllCategories AS
			(
				SELECT LSLoaiChucDanhID, Category FROM Revenue
				UNION
				SELECT LSLoaiChucDanhID, Category FROM Salary
			)
			SELECT A.Category,
				   ISNULL(R.RevenueAmount, 0) AS RevenueAmount,
				   ISNULL(S.SalaryCost, 0) AS SalaryCost,
				   CONVERT(DECIMAL(18,2), CASE WHEN ISNULL(S.SalaryCost, 0) <> 0 THEN ISNULL(R.RevenueAmount, 0) / S.SalaryCost ELSE 0 END) AS RevenueSalaryRatio,
				   CONVERT(VARCHAR(10), @C103RangeStart, 120) AS SummaryStartDate,
				   CONVERT(VARCHAR(10), @C103RangeEnd, 120) AS SummaryEndDate,
				   CASE
					   WHEN @C103RangeStart IS NULL OR @C103RangeEnd IS NULL THEN N''
					   WHEN YEAR(@C103RangeStart) = YEAR(@C103RangeEnd) AND MONTH(@C103RangeStart) = MONTH(@C103RangeEnd)
						   THEN N'T' + RIGHT('0' + CONVERT(VARCHAR(2), MONTH(@C103RangeStart)), 2) + N'/' + CONVERT(VARCHAR(4), YEAR(@C103RangeStart))
					   ELSE N'T' + RIGHT('0' + CONVERT(VARCHAR(2), MONTH(@C103RangeStart)), 2) + N'/' + CONVERT(VARCHAR(4), YEAR(@C103RangeStart))
						  + N' - T' + RIGHT('0' + CONVERT(VARCHAR(2), MONTH(@C103RangeEnd)), 2) + N'/' + CONVERT(VARCHAR(4), YEAR(@C103RangeEnd))
				   END AS SummaryLabel
			FROM AllCategories A
			LEFT JOIN Revenue R ON ISNULL(R.LSLoaiChucDanhID, N'') = ISNULL(A.LSLoaiChucDanhID, N'') AND R.Category = A.Category
			LEFT JOIN Salary S ON ISNULL(S.LSLoaiChucDanhID, N'') = ISNULL(A.LSLoaiChucDanhID, N'') AND S.Category = A.Category
			ORDER BY A.Category;
		END		
		ELSE IF (@ChartID = 'main_chart_79')
		BEGIN
			DECLARE @GenSummaryDate DATE = CONVERT(DATE, COALESCE(@ChartLastDateTimeLine, @ChartNgayChotCongGanNhat, @dDate));

			IF NOT EXISTS (SELECT 1 FROM @Employees WHERE ID > 0)
			BEGIN
				INSERT INTO @Employees (ID)
				SELECT DISTINCT P.EmpID
				FROM dbo.fnGetAllEmp_Permission_EffDate(@UserGroupID, @FunctionID, @GenSummaryDate) P
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = P.EmpID
				WHERE (E.StartDate IS NULL OR CONVERT(DATE, E.StartDate) <= @GenSummaryDate)
				AND (NOT EXISTS (SELECT 1 FROM @Companys) OR E.LSCompanyID IN (SELECT ID FROM @Companys))
				AND (NOT EXISTS (SELECT 1 FROM @LoaiChucDanhs) OR E.LSLoaiChucDanhID IN (SELECT ID FROM @LoaiChucDanhs))
				AND (NOT EXISTS (SELECT 1 FROM @Level1s) OR E.LSLevel1ID IN (SELECT ID FROM @Level1s))
				AND (NOT EXISTS (SELECT 1 FROM @Level2s) OR E.LSLevel2ID IN (SELECT ID FROM @Level2s))
				AND (NOT EXISTS (SELECT 1 FROM @Level3s) OR E.LSLevel3ID IN (SELECT ID FROM @Level3s))
				AND (NOT EXISTS (SELECT 1 FROM @Level4s) OR E.LSLevel4ID IN (SELECT ID FROM @Level4s))
				AND (NOT EXISTS (SELECT 1 FROM @Level5s) OR E.LSLevel5ID IN (SELECT ID FROM @Level5s))
				AND (NOT EXISTS (SELECT 1 FROM @Level6s) OR E.LSLevel6ID IN (SELECT ID FROM @Level6s))
				AND (NOT EXISTS (SELECT 1 FROM @Level7s) OR E.LSLevel7ID IN (SELECT ID FROM @Level7s))
				AND (NOT EXISTS (SELECT 1 FROM @Level8s) OR E.LSLevel8ID IN (SELECT ID FROM @Level8s))
				AND (NOT EXISTS (SELECT 1 FROM @Level9s) OR E.LSLevel9ID IN (SELECT ID FROM @Level9s));
			END

			;WITH PresentEmployees AS
			(
				SELECT DISTINCT E.EmpID
				FROM @Employees A
				INNER JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = A.ID
				WHERE A.ID > 0
				AND (E.StartDate IS NULL OR CONVERT(DATE, E.StartDate) <= @GenSummaryDate)
				AND NOT EXISTS
				(
					SELECT 1
					FROM dbo.TER_tblTermination (NOLOCK) TER
					WHERE TER.EmpID = E.EmpID
					AND TER.EffectDate IS NOT NULL AND CONVERT(DATE, TER.EffectDate) <= @GenSummaryDate
				)
			),
			EmployeeGen AS
			(
				SELECT	P.EmpID,
						ISNULL(CASE WHEN @LanguageID = 'VN' THEN G.VNName ELSE G.Name END, N'Không xác định') AS Category,
						CASE
							WHEN CV.DOB IS NULL THEN N'Không xác định'
							WHEN YEAR(CV.DOB) <= 1964 THEN N'Baby boomer (<= 1964)'
							WHEN YEAR(CV.DOB) BETWEEN 1965 AND 1980 THEN N'Gen X (Từ 1965-1980)'
							WHEN YEAR(CV.DOB) BETWEEN 1981 AND 1996 THEN N'Gen Y (Từ 1981-1996)'
							ELSE N'Gen Z (Từ 1997)'
						END AS GenerationName
				FROM PresentEmployees P
				LEFT JOIN dbo.HR_tblEmpCV (NOLOCK) CV ON CV.EmpID = P.EmpID
				LEFT JOIN dbo.LS_tblGender (NOLOCK) G ON G.ID = CV.Gender
			)
			SELECT	Category,
					SUM(CASE WHEN GenerationName = N'Gen Z (Từ 1997)' THEN 1 ELSE 0 END) AS [Gen Z (Từ 1997)],
					SUM(CASE WHEN GenerationName = N'Gen Y (Từ 1981-1996)' THEN 1 ELSE 0 END) AS [Gen Y (Từ 1981-1996)],
					SUM(CASE WHEN GenerationName = N'Gen X (Từ 1965-1980)' THEN 1 ELSE 0 END) AS [Gen X (Từ 1965-1980)],
					SUM(CASE WHEN GenerationName = N'Baby boomer (<= 1964)' THEN 1 ELSE 0 END) AS [Baby boomer (<= 1964)],
					SUM(CASE WHEN GenerationName = N'Không xác định' THEN 1 ELSE 0 END) AS [Không xác định],
					CONVERT(VARCHAR(10), @GenSummaryDate, 120) AS SummaryDate,
					CONVERT(VARCHAR(10), @GenSummaryDate, 103) AS SummaryLabel
			FROM EmployeeGen
			GROUP BY Category
			ORDER BY CASE Category WHEN N'Nam' THEN 1 WHEN N'Nữ' THEN 2 ELSE 3 END, Category;
		END
		/*rlogid 26336*/
		ELSE IF (@ChartID = 'main_chart_104')
		BEGIN
			DECLARE @C104GroupLevel INT = 0;
			DECLARE @C104GroupLevelName NVARCHAR(50) = N'';

			SELECT @C104GroupLevel = CASE
				WHEN EXISTS (SELECT 1 FROM @Level6s) THEN 6
				WHEN EXISTS (SELECT 1 FROM @Level5s) THEN 5
				WHEN EXISTS (SELECT 1 FROM @Level4s) THEN 4
				WHEN EXISTS (SELECT 1 FROM @Level3s) THEN 3
				WHEN EXISTS (SELECT 1 FROM @Level2s) THEN 2
				WHEN EXISTS (SELECT 1 FROM @Level1s) THEN 1
				WHEN EXISTS (SELECT 1 FROM @Companys) THEN 10
				ELSE 0
			END;

			SET @C104GroupLevelName = CASE @C104GroupLevel
				WHEN 10 THEN N'Company'
				WHEN 1 THEN N'Level1'
				WHEN 2 THEN N'Level2'
				WHEN 3 THEN N'Level3'
				WHEN 4 THEN N'Level4'
				WHEN 5 THEN N'Level5'
				WHEN 6 THEN N'Level6'
				ELSE N''
			END;

			IF @C104GroupLevel = 0
			BEGIN
				SELECT TOP 0
						CONVERT(NVARCHAR(1000), NULL) AS Category,
						CONVERT(INT, NULL) AS EmployeeCount,
						CONVERT(DECIMAL(18,2), NULL) AS TotalSalaryCost,
						CONVERT(DECIMAL(18,2), NULL) AS AverageSalaryCost,
						CONVERT(NVARCHAR(50), NULL) AS GroupLevelName,
						CONVERT(NVARCHAR(50), NULL) AS SummaryLabel;
				RETURN;
			END

			DECLARE @C104Periods TABLE
			(
				RowID INT IDENTITY(1,1),
				Years INT NOT NULL,
				Months INT NOT NULL,
				PeriodEnd DATE NOT NULL,
				TableSuffix CHAR(6) NOT NULL
			);

			INSERT INTO @C104Periods (Years, Months, PeriodEnd, TableSuffix)
			SELECT DISTINCT Years, Months, EOMONTH(DATEFROMPARTS(Years, Months, 1)),
					RIGHT('0' + CONVERT(VARCHAR(2), Months), 2) + CONVERT(CHAR(4), Years)
			FROM @tblChartChuKyCong
			WHERE Years IS NOT NULL AND Months IS NOT NULL;

			IF NOT EXISTS (SELECT 1 FROM @C104Periods)
			BEGIN
				DECLARE @C104YrTmp tID;
				DECLARE @C104QtrTmp tID;
				DECLARE @C104MoTmp tID;
				DECLARE @C104Res TABLE (FilterType VARCHAR(10), Value INT);

				INSERT INTO @C104YrTmp SELECT ID FROM @Years;
				IF NOT EXISTS (SELECT 1 FROM @C104YrTmp) INSERT INTO @C104YrTmp(ID) VALUES (YEAR(@dDate));
				INSERT INTO @C104QtrTmp SELECT ID FROM @Quarters;
				INSERT INTO @C104MoTmp SELECT ID FROM @Months;
				INSERT INTO @C104Res SELECT * FROM dbo.NEW_fnTableResolveTimeFilter(@C104YrTmp, @C104QtrTmp, @C104MoTmp);

				DELETE FROM @C104MoTmp;
				INSERT INTO @C104MoTmp SELECT DISTINCT Value FROM @C104Res WHERE FilterType = 'MONTH';

				INSERT INTO @C104Periods (Years, Months, PeriodEnd, TableSuffix)
				SELECT DISTINCT Y.ID,
						M.ID,
						EOMONTH(DATEFROMPARTS(Y.ID, M.ID, 1)),
						RIGHT('0' + CONVERT(VARCHAR(2), M.ID), 2) + CONVERT(CHAR(4), Y.ID)
				FROM @C104YrTmp Y
				CROSS JOIN @C104MoTmp M
				WHERE Y.ID IS NOT NULL AND M.ID BETWEEN 1 AND 12;
			END

			IF OBJECT_ID('tempdb..#C104SalaryCost') IS NOT NULL DROP TABLE #C104SalaryCost;
			CREATE TABLE #C104SalaryCost
			(
				PeriodKey CHAR(6) NOT NULL,
				GroupID NVARCHAR(510) NULL,
				Category NVARCHAR(1000) NOT NULL,
				EmpID BIGINT NOT NULL,
				SalaryCost DECIMAL(18,2) NOT NULL
			);

			DECLARE @C104Loop INT = 1;
			DECLARE @C104LoopCount INT = (SELECT COUNT(1) FROM @C104Periods);
			DECLARE @C104PitTable SYSNAME;
			DECLARE @C104Suffix CHAR(6);
			DECLARE @C104SQL NVARCHAR(MAX);
			DECLARE @C104GroupIDExpr NVARCHAR(MAX);
			DECLARE @C104GroupNameExpr NVARCHAR(MAX);

			WHILE @C104Loop <= @C104LoopCount
			BEGIN
				SELECT @C104Suffix = TableSuffix FROM @C104Periods WHERE RowID = @C104Loop;
				SET @C104PitTable = N'PIT_vPITMonth_' + @C104Suffix + N'_0';

				IF OBJECT_ID(N'dbo.' + @C104PitTable) IS NOT NULL
				BEGIN
					IF COL_LENGTH(N'dbo.' + @C104PitTable, 'TT_TongThuNhap_Gross') IS NOT NULL
					BEGIN
						SET @C104GroupIDExpr = CASE @C104GroupLevel
							WHEN 10 THEN N'ES.TK_CongTy_Code'
							WHEN 1 THEN N'ES.TK_DonViCap1_Code'
							WHEN 2 THEN N'ES.TK_DonViCap2_Code'
							WHEN 3 THEN N'ES.TK_DonViCap3_Code'
							WHEN 4 THEN N'ES.TK_DonViCap4_Code'
							WHEN 5 THEN N'ES.TK_DonViCap5_Code'
							WHEN 6 THEN N'ES.TK_DonViCap6_Code'
							ELSE N'NULL'
						END;

						SET @C104GroupNameExpr = CASE @C104GroupLevel
							WHEN 10 THEN N'ES.TK_CongTy_Code'
							WHEN 1 THEN N'ES.TK_DonViCap1'
							WHEN 2 THEN N'ES.TK_DonViCap2'
							WHEN 3 THEN N'ES.TK_DonViCap3'
							WHEN 4 THEN N'ES.TK_DonViCap4'
							WHEN 5 THEN N'ES.TK_DonViCap5'
							WHEN 6 THEN N'ES.TK_DonViCap6'
							ELSE N'NULL'
						END;

						SET @C104SQL = N'
							INSERT INTO #C104SalaryCost (PeriodKey, GroupID, Category, EmpID, SalaryCost)
							SELECT @PeriodKey AS PeriodKey,
								' + @C104GroupIDExpr + N' AS GroupID,
								ISNULL(' + @C104GroupNameExpr + N', N''Khong xac dinh'') AS Category,
								TRY_CONVERT(BIGINT, NUM.EmpID) AS EmpID,
								MAX(ISNULL(TRY_CONVERT(DECIMAL(18,2), NUM.TT_TongThuNhap_Gross), 0)) AS SalaryCost
						FROM dbo.' + QUOTENAME(@C104PitTable) + N' (NOLOCK) NUM
						INNER JOIN #EmployeeSalary ES ON ES.EmpID = TRY_CONVERT(BIGINT, NUM.EmpID) AND ES.TableSuffix = @PeriodKey
						WHERE TRY_CONVERT(BIGINT, NUM.EmpID) IS NOT NULL
						AND NULLIF(LTRIM(RTRIM(' + @C104GroupNameExpr + N')), N'''') IS NOT NULL
						GROUP BY ' + @C104GroupIDExpr + N', ' + @C104GroupNameExpr + N', TRY_CONVERT(BIGINT, NUM.EmpID);';

						EXEC sp_executesql @C104SQL,
							N'@LanguageID VARCHAR(2), @PeriodKey CHAR(6), @Companys tID READONLY, @Level1s tID READONLY, @Level2s tID READONLY, @Level3s tID READONLY, @Level4s tID READONLY, @Level5s tID READONLY, @Level6s tID READONLY',
							@LanguageID=@LanguageID, @PeriodKey=@C104Suffix, @Companys=@Companys, @Level1s=@Level1s, @Level2s=@Level2s, @Level3s=@Level3s, @Level4s=@Level4s, @Level5s=@Level5s, @Level6s=@Level6s;
					END
				END

				SET @C104Loop = @C104Loop + 1;
			END

			DECLARE @C104SummaryLabel NVARCHAR(50);
			SELECT @C104SummaryLabel = CASE
					WHEN MIN(Years) = MAX(Years) AND MIN(Months) = MAX(Months)
						THEN N'T' + RIGHT('0' + CONVERT(VARCHAR(2), MIN(Months)), 2) + N'/' + CONVERT(VARCHAR(4), MIN(Years))
					ELSE N'T' + RIGHT('0' + CONVERT(VARCHAR(2), MIN(Months)), 2) + N'/' + CONVERT(VARCHAR(4), MIN(Years))
						+ N' - T' + RIGHT('0' + CONVERT(VARCHAR(2), MAX(Months)), 2) + N'/' + CONVERT(VARCHAR(4), MAX(Years))
			END
			FROM @C104Periods;

			SELECT Category,
					COUNT(1) AS EmployeeCount,
					SUM(SalaryCost) AS TotalSalaryCost,
					CONVERT(DECIMAL(18,2), CASE WHEN COUNT(1) > 0 THEN SUM(SalaryCost) / COUNT(1) ELSE 0 END) AS AverageSalaryCost,
					@C104GroupLevelName AS GroupLevelName,
					@C104SummaryLabel AS SummaryLabel
			FROM #C104SalaryCost
			WHERE ISNULL(Category,'') <> ''
			GROUP BY Category
			HAVING SUM(SalaryCost) > 0
			ORDER BY AverageSalaryCost DESC, Category;
		END
		/*rlogid 26337*/
		ELSE IF (@ChartID = 'main_chart_105')
		BEGIN
			DECLARE @C105CapBacChucDanhs tID;

			INSERT INTO @C105CapBacChucDanhs
			SELECT FilterValue
			FROM dbo.NEW_fnTableParseFilterJson(@FilterJson)
			WHERE FilterName = 'NHOMLAODONG';

			DECLARE @C105Periods TABLE
			(
				RowID INT IDENTITY(1,1),
				Years INT NOT NULL,
				Months INT NOT NULL,
				PeriodEnd DATE NOT NULL,
				TableSuffix CHAR(6) NOT NULL
			);

			INSERT INTO @C105Periods (Years, Months, PeriodEnd, TableSuffix)
			SELECT DISTINCT Years,
				   Months,
				   EOMONTH(DATEFROMPARTS(Years, Months, 1)),
				   RIGHT('0' + CONVERT(VARCHAR(2), Months), 2) + CONVERT(CHAR(4), Years)
			FROM @tblChartChuKyCong
			WHERE Years IS NOT NULL AND Months IS NOT NULL;

			IF NOT EXISTS (SELECT 1 FROM @C105Periods)
			BEGIN
				DECLARE @C105YrTmp tID;
				DECLARE @C105QtrTmp tID;
				DECLARE @C105MoTmp tID;
				DECLARE @C105Res TABLE (FilterType VARCHAR(10), Value INT);

				INSERT INTO @C105YrTmp SELECT ID FROM @Years;
				IF NOT EXISTS (SELECT 1 FROM @C105YrTmp) INSERT INTO @C105YrTmp(ID) VALUES (YEAR(@dDate));
				INSERT INTO @C105QtrTmp SELECT ID FROM @Quarters;
				INSERT INTO @C105MoTmp SELECT ID FROM @Months;

				INSERT INTO @C105Res
				SELECT * FROM dbo.NEW_fnTableResolveTimeFilter(@C105YrTmp, @C105QtrTmp, @C105MoTmp);

				DELETE FROM @C105MoTmp;
				INSERT INTO @C105MoTmp
				SELECT DISTINCT Value FROM @C105Res WHERE FilterType = 'MONTH';

				INSERT INTO @C105Periods (Years, Months, PeriodEnd, TableSuffix)
				SELECT DISTINCT Y.ID,
					   M.ID,
					   EOMONTH(DATEFROMPARTS(Y.ID, M.ID, 1)),
					   RIGHT('0' + CONVERT(VARCHAR(2), M.ID), 2) + CONVERT(CHAR(4), Y.ID)
				FROM @C105YrTmp Y
				CROSS JOIN @C105MoTmp M
				WHERE Y.ID IS NOT NULL AND M.ID BETWEEN 1 AND 12;
			END

			DECLARE @C105SalaryAtPeriodDbg TABLE
			(
				Years INT NOT NULL,
				Months INT NOT NULL,
				PeriodEnd DATE NOT NULL,
				PeriodKey CHAR(6) NOT NULL,
				EmpID BIGINT NOT NULL,
				SalaryRecordID BIGINT NULL,
				SalaryFromDate DATE NULL,
				SalaryToDate DATE NULL,
				IncomeAmount DECIMAL(18,2) NULL,
				rn INT NOT NULL
			);

			DECLARE @C105ScopedProbeDbg TABLE
			(
				Years INT NOT NULL,
				Months INT NOT NULL,
				PeriodEnd DATE NOT NULL,
				PeriodKey CHAR(6) NOT NULL,
				EmpCode NVARCHAR(50) NULL,
				EmpID BIGINT NOT NULL,
				F_EmpName NVARCHAR(500) NULL,
				SalaryRecordID BIGINT NULL,
				SalaryFromDate DATE NULL,
				SalaryToDate DATE NULL,
				IncomeAmount DECIMAL(18,2) NULL,
				WorkingRecordID BIGINT NULL,
				WRFromDate DATETIME NULL,
				WRToDate DATETIME NULL,
				LSCompanyID INT NULL,
				LSLevel1ID INT NULL,
				LSLevel2ID INT NULL,
				LSLevel3ID INT NULL,
				LSLevel4ID INT NULL,
				LSLevel5ID INT NULL,
				LSLevel6ID INT NULL,
				LSJobTitleID INT NULL,
				JobTitleVN NVARCHAR(500) NULL,
				LSChucVuID INT NULL,
				Category NVARCHAR(500) NULL,
				SortOrder INT NULL,
				PassWorkingRecord BIT NOT NULL,
				PassEmployees BIT NOT NULL,
				PassCompany BIT NOT NULL,
				PassLevel1 BIT NOT NULL,
				PassLevel2 BIT NOT NULL,
				PassLevel3 BIT NOT NULL,
				PassLevel4 BIT NOT NULL,
				PassLevel5 BIT NOT NULL,
				PassLevel6 BIT NOT NULL,
				PassCapBacChucDanh BIT NOT NULL
			);

			DECLARE @C105ScopedSalaryDbg TABLE
			(
				Years INT NOT NULL,
				Months INT NOT NULL,
				PeriodEnd DATE NOT NULL,
				PeriodKey CHAR(6) NOT NULL,
				EmpCode NVARCHAR(50) NULL,
				EmpID BIGINT NOT NULL,
				F_EmpName NVARCHAR(500) NULL,
				SalaryRecordID BIGINT NULL,
				SalaryFromDate DATE NULL,
				SalaryToDate DATE NULL,
				IncomeAmount DECIMAL(18,2) NULL,
				WorkingRecordID BIGINT NULL,
				WRFromDate DATETIME NULL,
				WRToDate DATETIME NULL,
				LSCompanyID INT NULL,
				LSLevel1ID INT NULL,
				LSLevel2ID INT NULL,
				LSLevel3ID INT NULL,
				LSLevel4ID INT NULL,
				LSLevel5ID INT NULL,
				LSLevel6ID INT NULL,
				LSJobTitleID INT NULL,
				JobTitleVN NVARCHAR(500) NULL,
				LSChucVuID INT NULL,
				Category NVARCHAR(500) NULL,
				SortOrder INT NULL,
				PassWorkingRecord BIT NOT NULL,
				PassEmployees BIT NOT NULL,
				PassCompany BIT NOT NULL,
				PassLevel1 BIT NOT NULL,
				PassLevel2 BIT NOT NULL,
				PassLevel3 BIT NOT NULL,
				PassLevel4 BIT NOT NULL,
				PassLevel5 BIT NOT NULL,
				PassLevel6 BIT NOT NULL,
				PassCapBacChucDanh BIT NOT NULL
			);

			INSERT INTO @C105SalaryAtPeriodDbg
			(
				Years, Months, PeriodEnd, PeriodKey, EmpID, SalaryRecordID,
				SalaryFromDate, SalaryToDate, IncomeAmount, rn
			)
			SELECT P.Years,
				   P.Months,
				   P.PeriodEnd,
				   P.TableSuffix AS PeriodKey,
				   S.EmpID,
				   S.SalaryRecordID,
				   CONVERT(DATE, S.FromDate) AS SalaryFromDate,
				   CONVERT(DATE, S.ToDate) AS SalaryToDate,
				   TRY_CONVERT(DECIMAL(18,2), REPLACE(dbo.fnConvertNumber(dbo.sys_fnGetD(S.TongThuNhapThang_Root)), ',', '')) AS IncomeAmount,
				   ROW_NUMBER() OVER
				   (
					   PARTITION BY P.PeriodEnd, S.EmpID
					   ORDER BY ISNULL(S.FromDate, '19000101') DESC, ISNULL(S.ToDate, '99991231') DESC, S.SalaryRecordID DESC
				   ) AS rn
			FROM @C105Periods P
			INNER JOIN dbo.PR_tblSalary (NOLOCK) S
				ON S.FromDate IS NOT NULL
			   AND S.FromDate <= P.PeriodEnd
			   AND (S.ToDate IS NULL OR S.ToDate >= P.PeriodEnd);

			INSERT INTO @C105ScopedProbeDbg
			(
				Years, Months, PeriodEnd, PeriodKey, EmpCode, EmpID, F_EmpName,
				SalaryRecordID, SalaryFromDate, SalaryToDate, IncomeAmount,
				WorkingRecordID, WRFromDate, WRToDate, LSCompanyID, LSLevel1ID,
				LSLevel2ID, LSLevel3ID, LSLevel4ID, LSLevel5ID, LSLevel6ID,
				LSJobTitleID, JobTitleVN, LSChucVuID, Category, SortOrder,
				PassWorkingRecord, PassEmployees, PassCompany, PassLevel1,
				PassLevel2, PassLevel3, PassLevel4, PassLevel5, PassLevel6,
				PassCapBacChucDanh
			)
			SELECT SP.Years,
				   SP.Months,
				   SP.PeriodEnd,
				   SP.PeriodKey,
				   E.EmpCode,
				   SP.EmpID,
				   E.F_EmpName,
				   SP.SalaryRecordID,
				   SP.SalaryFromDate,
				   SP.SalaryToDate,
				   SP.IncomeAmount,
				   WR.WorkingRecordID,
				   WR.FromDate AS WRFromDate,
				   WR.ToDate AS WRToDate,
				   WR.LSCompanyID,
				   WR.LSLevel1ID,
				   WR.LSLevel2ID,
				   WR.LSLevel3ID,
				   WR.LSLevel4ID,
				   WR.LSLevel5ID,
				   WR.LSLevel6ID,
				   JT.LSJobTitleID,
				   JT.VNName AS JobTitleVN,
				   CV.LSChucVuID,
				   ISNULL(CASE WHEN @LanguageID = 'VN' THEN CV.TenChucVuV ELSE CV.TenChucVuE END, N'Khong xac dinh') AS Category,
				   ISNULL(CV.STT, 9999) AS SortOrder,
				   CASE WHEN WR.EmpID IS NOT NULL THEN 1 ELSE 0 END AS PassWorkingRecord,
				   CONVERT(BIT, 1) AS PassEmployees,
				   CASE WHEN NOT EXISTS (SELECT 1 FROM @Companys WHERE ID > 0) OR WR.LSCompanyID IN (SELECT ID FROM @Companys WHERE ID > 0) THEN 1 ELSE 0 END AS PassCompany,
				   CASE WHEN NOT EXISTS (SELECT 1 FROM @Level1s WHERE ID > 0) OR WR.LSLevel1ID IN (SELECT ID FROM @Level1s WHERE ID > 0) THEN 1 ELSE 0 END AS PassLevel1,
				   CASE WHEN NOT EXISTS (SELECT 1 FROM @Level2s WHERE ID > 0) OR WR.LSLevel2ID IN (SELECT ID FROM @Level2s WHERE ID > 0) THEN 1 ELSE 0 END AS PassLevel2,
				   CASE WHEN NOT EXISTS (SELECT 1 FROM @Level3s WHERE ID > 0) OR WR.LSLevel3ID IN (SELECT ID FROM @Level3s WHERE ID > 0) THEN 1 ELSE 0 END AS PassLevel3,
				   CASE WHEN NOT EXISTS (SELECT 1 FROM @Level4s WHERE ID > 0) OR WR.LSLevel4ID IN (SELECT ID FROM @Level4s WHERE ID > 0) THEN 1 ELSE 0 END AS PassLevel4,
				   CASE WHEN NOT EXISTS (SELECT 1 FROM @Level5s WHERE ID > 0) OR WR.LSLevel5ID IN (SELECT ID FROM @Level5s WHERE ID > 0) THEN 1 ELSE 0 END AS PassLevel5,
				   CASE WHEN NOT EXISTS (SELECT 1 FROM @Level6s WHERE ID > 0) OR WR.LSLevel6ID IN (SELECT ID FROM @Level6s WHERE ID > 0) THEN 1 ELSE 0 END AS PassLevel6,
				   CASE WHEN NOT EXISTS (SELECT 1 FROM @C105CapBacChucDanhs) OR CV.LSChucVuID IN (SELECT ID FROM @C105CapBacChucDanhs) THEN 1 ELSE 0 END AS PassCapBacChucDanh
			FROM @C105SalaryAtPeriodDbg SP
			LEFT JOIN dbo.HR_tblEmp (NOLOCK) E ON E.EmpID = SP.EmpID
			OUTER APPLY
			(
				SELECT TOP 1 WR.*
				FROM dbo.HR_tblWorkingRecord (NOLOCK) WR
				WHERE WR.EmpID = SP.EmpID
				AND WR.FromDate <= SP.SalaryFromDate
				ORDER BY WR.FromDate DESC, WR.WorkingRecordID DESC
			) WR
			LEFT JOIN dbo.LS_tblJobTitle (NOLOCK) JT ON JT.LSJobTitleID = WR.LSJobTitleID
			LEFT JOIN dbo.LS_tblChucVu (NOLOCK) CV ON CV.LSChucVuID = JT.LSChucVuID
			WHERE SP.rn = 1;

			INSERT INTO @C105ScopedSalaryDbg
			SELECT *
			FROM @C105ScopedProbeDbg
			WHERE PassWorkingRecord = 1
			AND PassCompany = 1
			AND PassLevel1 = 1
			AND PassLevel2 = 1
			AND PassLevel3 = 1
			AND PassLevel4 = 1
			AND PassLevel5 = 1
			AND PassLevel6 = 1
			AND PassCapBacChucDanh = 1;

			SELECT Category,
				   SUM(ISNULL(IncomeAmount, 0)) AS TotalIncome,
				   COUNT(1) AS EmployeeCount,
				   CONVERT(DECIMAL(18,2), CASE WHEN COUNT(1) > 0 THEN SUM(ISNULL(IncomeAmount, 0)) / COUNT(1) ELSE 0 END) AS AverageIncome,
				   CASE
					   WHEN MIN(Years) = MAX(Years) AND MIN(Months) = MAX(Months)
						   THEN N'T' + RIGHT('0' + CONVERT(VARCHAR(2), MIN(Months)), 2) + N'/' + CONVERT(VARCHAR(4), MIN(Years))
					   ELSE N'T' + RIGHT('0' + CONVERT(VARCHAR(2), MIN(Months)), 2) + N'/' + CONVERT(VARCHAR(4), MIN(Years))
						  + N' - T' + RIGHT('0' + CONVERT(VARCHAR(2), MAX(Months)), 2) + N'/' + CONVERT(VARCHAR(4), MAX(Years))
				   END AS SummaryLabel
			FROM @C105ScopedSalaryDbg
			GROUP BY Category, SortOrder
			ORDER BY SortOrder, AverageIncome DESC, Category;
		END
		/*rlogid 26204*/
		ELSE IF (@ChartID = 'main_chart_106')
		BEGIN
			DECLARE @C106Periods TABLE
			(
				RowID INT IDENTITY(1,1),
				Years INT NOT NULL,
				Months INT NOT NULL,
				PeriodStart DATE NOT NULL,
				PeriodEnd DATE NOT NULL,
				TableSuffix CHAR(6) NOT NULL
			);
			DECLARE @C106YrTmp tID;
			DECLARE @C106QtrTmp tID;
			DECLARE @C106MoTmp tID;
			DECLARE @C106Res TABLE (FilterType VARCHAR(10), Value INT);

			INSERT INTO @C106YrTmp SELECT ID FROM @Years;
			IF NOT EXISTS (SELECT 1 FROM @C106YrTmp)
			BEGIN
				INSERT INTO @C106YrTmp
				SELECT DISTINCT Years FROM @tblChartChuKyCong WHERE Years IS NOT NULL;
			END
			IF NOT EXISTS (SELECT 1 FROM @C106YrTmp) INSERT INTO @C106YrTmp(ID) VALUES (YEAR(@dDate));

			INSERT INTO @C106QtrTmp SELECT ID FROM @Quarters;
			INSERT INTO @C106MoTmp SELECT ID FROM @Months;

			INSERT INTO @C106Res
			SELECT * FROM dbo.NEW_fnTableResolveTimeFilter(@C106YrTmp, @C106QtrTmp, @C106MoTmp);

			DELETE FROM @C106MoTmp;
			INSERT INTO @C106MoTmp
			SELECT DISTINCT Value FROM @C106Res WHERE FilterType = 'MONTH';

			INSERT INTO @C106Periods (Years, Months, PeriodStart, PeriodEnd, TableSuffix)
			SELECT DISTINCT Y.ID,
				   M.ID,
				   DATEFROMPARTS(Y.ID, M.ID, 1),
				   EOMONTH(DATEFROMPARTS(Y.ID, M.ID, 1)),
				   RIGHT('0' + CONVERT(VARCHAR(2), M.ID), 2) + CONVERT(CHAR(4), Y.ID)
			FROM @C106YrTmp Y
			CROSS JOIN @C106MoTmp M
			WHERE Y.ID IS NOT NULL AND M.ID BETWEEN 1 AND 12;

			IF OBJECT_ID('tempdb..#C106SalaryCost') IS NOT NULL DROP TABLE #C106SalaryCost;
			CREATE TABLE #C106SalaryCost
			(
				Years INT NOT NULL,
				Months INT NOT NULL,
				SalaryCost DECIMAL(18,2) NOT NULL
			);

			DECLARE @C106Loop INT = 1;
			DECLARE @C106LoopCount INT = (SELECT COUNT(1) FROM @C106Periods);
			DECLARE @C106Year INT;
			DECLARE @C106Month INT;
			DECLARE @C106Suffix CHAR(6);
			DECLARE @C106PitTable SYSNAME;
			DECLARE @C106SQL NVARCHAR(MAX);

			WHILE @C106Loop <= @C106LoopCount
			BEGIN
				SELECT @C106Year = Years, @C106Month = Months, @C106Suffix = TableSuffix
				FROM @C106Periods
				WHERE RowID = @C106Loop;
				SET @C106PitTable = N'PIT_vPITMonth_' + @C106Suffix + N'_0';

				IF OBJECT_ID(N'dbo.' + @C106PitTable) IS NOT NULL
				AND COL_LENGTH(N'dbo.' + @C106PitTable, 'TT_TongThuNhap_Gross') IS NOT NULL
				BEGIN
					SET @C106SQL = N'
						INSERT INTO #C106SalaryCost (Years, Months, SalaryCost)
						SELECT @Years,
							   @Months,
							   SUM(ISNULL(TRY_CONVERT(DECIMAL(18,2), NUM.TT_TongThuNhap_Gross), 0)) AS SalaryCost
						FROM dbo.' + QUOTENAME(@C106PitTable) + N' (NOLOCK) NUM
						INNER JOIN #EmployeeSalary ES ON ES.EmpID = TRY_CONVERT(BIGINT, NUM.EmpID) AND ES.TableSuffix = @TableSuffix
						WHERE TRY_CONVERT(BIGINT, NUM.EmpID) IS NOT NULL
						;';

					EXEC sp_executesql @C106SQL,
						N'@Years INT, @Months INT, @TableSuffix CHAR(6), @Companys tID READONLY, @Level1s tID READONLY, @Level2s tID READONLY, @Level3s tID READONLY, @Level4s tID READONLY, @Level5s tID READONLY, @Level6s tID READONLY',
						@Years=@C106Year,
						@Months=@C106Month,
						@TableSuffix=@C106Suffix,
						@Companys=@Companys, @Level1s=@Level1s, @Level2s=@Level2s, @Level3s=@Level3s, @Level4s=@Level4s, @Level5s=@Level5s, @Level6s=@Level6s;
				END

				SET @C106Loop = @C106Loop + 1;
			END

			;WITH Revenue AS
			(
				SELECT P.Years,
					   P.Months,
					   SUM(ISNULL(O.Amount, 0)) AS RevenueAmount
				FROM @C106Periods P
				INNER JOIN dbo.PR_tblLoaiDinhMucOrg (NOLOCK) O
					ON (O.EffDate IS NULL OR O.EffDate <= P.PeriodEnd)
				   AND (O.ToDate IS NULL OR O.ToDate >= P.PeriodStart)
				INNER JOIN dbo.LS_tblLoaiDinhMuc (NOLOCK) LDM
					ON LDM.LSLoaiDinhMucID = O.LSLoaiDinhMucID
				   AND LDM.LSLoaiDinhMucCode = N'DTTH'
				WHERE (NOT EXISTS (SELECT 1 FROM @Companys) OR O.LSCompanyID IN (SELECT ID FROM @Companys))
				AND (NOT EXISTS (SELECT 1 FROM @Level1s) OR O.LSLevel1ID IN (SELECT ID FROM @Level1s))
				AND (NOT EXISTS (SELECT 1 FROM @Level2s) OR O.LSLevel2ID IN (SELECT ID FROM @Level2s))
				AND (NOT EXISTS (SELECT 1 FROM @Level3s) OR O.LSLevel3ID IN (SELECT ID FROM @Level3s))
				AND (NOT EXISTS (SELECT 1 FROM @Level4s) OR O.LSLevel4ID IN (SELECT ID FROM @Level4s))
				AND (NOT EXISTS (SELECT 1 FROM @Level5s) OR O.LSLevel5ID IN (SELECT ID FROM @Level5s))
				AND (NOT EXISTS (SELECT 1 FROM @Level6s) OR O.LSLevel6ID IN (SELECT ID FROM @Level6s))
				GROUP BY P.Years, P.Months
			),
			Salary AS
			(
				SELECT Years, Months, SUM(SalaryCost) AS SalaryCost
				FROM #C106SalaryCost
				GROUP BY Years, Months
			),
			RangeLabel AS
			(
				SELECT CASE
					   WHEN MIN(Years) = MAX(Years) AND MIN(Months) = MAX(Months)
						   THEN N'T' + RIGHT('0' + CONVERT(VARCHAR(2), MIN(Months)), 2) + N'/' + CONVERT(VARCHAR(4), MIN(Years))
					   ELSE N'T' + RIGHT('0' + CONVERT(VARCHAR(2), MIN(Months)), 2) + N'/' + CONVERT(VARCHAR(4), MIN(Years))
						  + N' - T' + RIGHT('0' + CONVERT(VARCHAR(2), MAX(Months)), 2) + N'/' + CONVERT(VARCHAR(4), MAX(Years))
					   END AS SummaryLabel
				FROM @C106Periods
			)
			SELECT N'T' + RIGHT('0' + CONVERT(VARCHAR(2), P.Months), 2) + N'/' + CONVERT(VARCHAR(4), P.Years) AS Category,
				   P.Years,
				   P.Months,
				   (P.Years * 100) + P.Months AS SortOrder,
				   ISNULL(R.RevenueAmount, 0) AS RevenueAmount,
				   ISNULL(S.SalaryCost, 0) AS SalaryCost,
				   CONVERT(DECIMAL(18,2), CASE WHEN ISNULL(S.SalaryCost, 0) <> 0 THEN ISNULL(R.RevenueAmount, 0) / S.SalaryCost ELSE 0 END) AS RevenueSalaryRatio,
				   RL.SummaryLabel
			FROM @C106Periods P
			CROSS JOIN RangeLabel RL
			LEFT JOIN Revenue R ON R.Years = P.Years AND R.Months = P.Months
			LEFT JOIN Salary S ON S.Years = P.Years AND S.Months = P.Months
			ORDER BY P.Years, P.Months;
		END
	END
	-- =====================================================================
	ELSE IF @Activity IN ('GetESSData', 'GetESSDeXuatTuyenDung')
	BEGIN
		IF ISNULL(@EmpID, 0) <= 0
		BEGIN
			-- Chua co EmpID (tai khoan khong gan nhan vien) -> tra rong, JS tu bao
			SELECT TOP 0 0 AS EmpID;
			RETURN
		END

		DECLARE @ESSYear INT = YEAR(@dDate);
		DECLARE @ESSMonth INT = NULL;
		IF ISJSON(ISNULL(@FilterJson, '')) = 1
		BEGIN
			SET @ESSYear  = ISNULL((SELECT MAX(FilterValue) FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'YEAR'), @ESSYear);
			SET @ESSMonth = (SELECT MAX(FilterValue) FROM dbo.NEW_fnTableParseFilterJson(@FilterJson) WHERE FilterName = 'MONTH');
		END
		DECLARE @ESSKyDau  DATE = CASE WHEN @ESSMonth IS NOT NULL THEN DATEFROMPARTS(@ESSYear, @ESSMonth, 1) ELSE DATEFROMPARTS(@ESSYear, 1, 1) END;
		DECLARE @ESSKyCuoi DATE = CASE WHEN @ESSMonth IS NOT NULL THEN EOMONTH(@ESSKyDau) ELSE DATEFROMPARTS(@ESSYear, 12, 31) END;
		DECLARE @ESSNgayHieuLuc DATE = @ESSKyCuoi;

		IF @Activity = 'GetESSData'
		BEGIN
			DECLARE @ESSWPPhepNam NVARCHAR(15), @ESSWPNghiBu NVARCHAR(15)
			SELECT @ESSWPPhepNam = LSWorkPointID FROM dbo.LS_tblWorkPoint (NOLOCK) WHERE LSWorkPointTypeID = '0001' -- Nhom nghi phep
			SELECT @ESSWPNghiBu  = LSWorkPointID FROM dbo.LS_tblWorkPoint (NOLOCK) WHERE LSWorkPointTypeID = '0018' -- Nhom nghi bu

			DECLARE @ESSPhepDaNghiDenKy NUMERIC(18,4) = NULL;
			DECLARE @ESSPhepDaNghiChuKy NUMERIC(18,4) = NULL;
			DECLARE @ESSNghiBuDaNghiDenKy NUMERIC(18,4) = NULL;
			DECLARE @ESSNghiBuDaNghiChuKy NUMERIC(18,4) = NULL;
			DECLARE @ESSLan TINYINT = 0;
			WHILE @ESSMonth IS NOT NULL AND @ESSLan < 2
			BEGIN
				DECLARE @ESSWPDangTinh NVARCHAR(15) = CASE WHEN @ESSLan = 0 THEN @ESSWPPhepNam ELSE @ESSWPNghiBu END;
				IF @ESSWPDangTinh IS NOT NULL
				BEGIN
				DECLARE @ESSDauChuKyPhep DATE = CONVERT(DATE, dbo.fnLayChuKyTinhPhep(@ESSKyCuoi, @ESSKyCuoi, 'F'), 103);
				DECLARE @ESSNgayThoiViec DATE = NULL;
				DECLARE @ESSKhongTruReject BIT = 0, @ESSKhongTruAddNew BIT = 0;
				DECLARE @ESSThoiHanNghiBu BIT = 0, @ESSBuTheoThang BIT = 0;
				DECLARE @ESSBuSoThang FLOAT = 0, @ESSBuSoNgay FLOAT = 0, @ESSThangHetHan INT = 0;
				SELECT TOP (1) @ESSKhongTruReject = ISNULL(KhongTruNgayPhepKhiDangReject, 0),
					@ESSKhongTruAddNew = ISNULL(KhongTruNgayPhepKhiDangAddNew, 0),
					@ESSThoiHanNghiBu = ISNULL(ThoiHanSuDungNghiBu, 0),
					@ESSBuSoThang = ISNULL(ThoiHanSuDungNghiBu_SoThang, 0),
					@ESSBuSoNgay = ISNULL(ThoiHanSuDungNghiBu_SoNgay, 0),
					@ESSBuTheoThang = ISNULL(ThoiHanSuDungNghiBu_Thang, 0),
					@ESSThangHetHan = ISNULL(ThangHetHanNghiBu, 0)
				FROM dbo.TMS_tblSetupTMS (NOLOCK);
				SELECT @ESSNgayThoiViec = DATEADD(DAY, -1, EffectDate)
				FROM dbo.TER_tblTermination (NOLOCK) WHERE EmpID = @EmpID;
				IF @ESSLan = 1 AND @ESSThoiHanNghiBu = 1 AND @ESSBuSoThang + @ESSBuSoNgay > 0
					SELECT @ESSDauChuKyPhep = MIN(FromDate)
					FROM dbo.TS_fnTableChuKyThoiHanNghiBu(@EmpID, @ESSKyCuoi, @ESSKyCuoi, @ESSWPDangTinh)
					WHERE @ESSKyCuoi BETWEEN FromDate AND ToDate OR FromDate = @ESSKyCuoi;
				ELSE IF @ESSLan = 1 AND @ESSBuTheoThang = 1 AND @ESSThangHetHan > 0
				BEGIN
					DECLARE @ESSKyLuong NVARCHAR(21) = dbo.PR_fnGetFromToDateSalPeriod_GiaQuyen_EmpID_ByDate(@ESSKyCuoi, @EmpID);
					SET @ESSDauChuKyPhep = CONVERT(DATE, LEFT(@ESSKyLuong, 10), 103);
				END

				-- Ham TS_fnTinhPhepDaNghi tinh tron chu ky, nen loc ngay chi tiet de lay luy ke den thang.
				DECLARE @ESSDaNghiDenKy NUMERIC(18,4) = 0;
				SELECT @ESSDaNghiDenKy = ISNULL(SUM(X.LeaveTaken), 0)
				FROM (
					SELECT CONVERT(NUMERIC(18,4), R.LeaveTaken) AS LeaveTaken
					FROM dbo.TS_tblLeaveRecord L (NOLOCK)
					JOIN dbo.TS_tblLeaveRecordDetail R (NOLOCK) ON R.LeaveRecordID = L.LeaveRecordID
					OUTER APPLY (SELECT TOP (1) P.TrangThai FROM dbo.TS_tblLeaveRecordProcess P (NOLOCK)
						WHERE P.LeaveRecordID = L.LeaveRecordID ORDER BY P.LeaveRecordProcessID DESC) P
					WHERE L.EmpID = @EmpID AND L.LSWorkPointID = @ESSWPDangTinh
						AND R.DateID BETWEEN @ESSDauChuKyPhep AND @ESSKyCuoi
						AND (@ESSNgayThoiViec IS NULL OR R.DateID <= @ESSNgayThoiViec)
						AND (P.TrangThai IS NULL OR NOT (P.TrangThai = 8
							OR (@ESSKhongTruReject = 1 AND P.TrangThai = 5)
							OR (@ESSKhongTruAddNew = 1 AND P.TrangThai = 1)))
					UNION ALL
					SELECT CONVERT(NUMERIC(18,4),
						CASE WHEN W.LSWorkPointIDRefer1 = @ESSWPDangTinh
							THEN CASE WHEN ISNULL(R.LeaveTaken1, 0) > 0 OR ISNULL(R.LeaveTaken2, 0) > 0
								THEN ISNULL(R.LeaveTaken1, 0) ELSE ISNULL(R.LeaveTaken, 0) / 2.0 END ELSE 0 END
						+ CASE WHEN W.LSWorkPointIDRefer2 = @ESSWPDangTinh
							THEN CASE WHEN ISNULL(R.LeaveTaken1, 0) > 0 OR ISNULL(R.LeaveTaken2, 0) > 0
								THEN ISNULL(R.LeaveTaken2, 0) ELSE ISNULL(R.LeaveTaken, 0) / 2.0 END ELSE 0 END)
					FROM dbo.TS_tblLeaveRecord L (NOLOCK)
					JOIN dbo.TS_tblLeaveRecordDetail R (NOLOCK) ON R.LeaveRecordID = L.LeaveRecordID
					JOIN dbo.LS_tblWorkPoint W (NOLOCK) ON W.LSWorkPointID = ISNULL(L.HC_LSWorkPointID, L.LSWorkPointID)
					OUTER APPLY (SELECT TOP (1) P.TrangThai FROM dbo.TS_tblLeaveRecordProcess P (NOLOCK)
						WHERE P.LeaveRecordID = L.LeaveRecordID ORDER BY P.LeaveRecordProcessID DESC) P
					WHERE L.EmpID = @EmpID
						AND (W.LSWorkPointIDRefer1 = @ESSWPDangTinh OR W.LSWorkPointIDRefer2 = @ESSWPDangTinh)
						AND R.DateID BETWEEN @ESSDauChuKyPhep AND @ESSKyCuoi
						AND (@ESSNgayThoiViec IS NULL OR R.DateID <= @ESSNgayThoiViec)
						AND (P.TrangThai IS NULL OR NOT (P.TrangThai = 8
							OR (@ESSKhongTruReject = 1 AND P.TrangThai = 5)
							OR (@ESSKhongTruAddNew = 1 AND P.TrangThai = 1)))
					UNION ALL
					SELECT CONVERT(NUMERIC(18,4), R.LeaveTaken)
					FROM dbo.TS_tblLeaveRecordHour L (NOLOCK)
					JOIN dbo.TS_tblLeaveRecordHourDetail R (NOLOCK) ON R.LeaveRecordHourID = L.LeaveRecordHourID
					OUTER APPLY (SELECT TOP (1) P.TrangThai FROM dbo.TS_tblLeaveRecordHourProcess P (NOLOCK)
						WHERE P.LeaveRecordHourID = L.LeaveRecordHourID ORDER BY P.LeaveRecordHourProcessID DESC) P
					WHERE L.EmpID = @EmpID AND L.LSWorkPointID = @ESSWPDangTinh
						AND R.DateID BETWEEN @ESSDauChuKyPhep AND @ESSKyCuoi
						AND (@ESSNgayThoiViec IS NULL OR R.DateID <= @ESSNgayThoiViec)
						AND (P.TrangThai IS NULL OR NOT (P.TrangThai = 8
							OR (@ESSKhongTruReject = 1 AND P.TrangThai = 5)
							OR (@ESSKhongTruAddNew = 1 AND P.TrangThai = 1)))
				) X;
				IF @ESSLan = 0
				BEGIN
					SET @ESSPhepDaNghiDenKy = @ESSDaNghiDenKy;
					SET @ESSPhepDaNghiChuKy = dbo.TS_fnTinhPhepDaNghi(@EmpID, @ESSKyCuoi, @ESSKyCuoi, @ESSWPDangTinh);
				END
				ELSE
				BEGIN
					SET @ESSNghiBuDaNghiDenKy = @ESSDaNghiDenKy;
					SET @ESSNghiBuDaNghiChuKy = dbo.TS_fnTinhPhepDaNghi(@EmpID, @ESSKyCuoi, @ESSKyCuoi, @ESSWPDangTinh);
				END
				END
				SET @ESSLan = @ESSLan + 1;
			END

			SELECT
				CASE WHEN @ESSMonth IS NOT NULL
					 THEN N'T' + RIGHT('0' + CONVERT(VARCHAR(2), @ESSMonth), 2) + '/' + CONVERT(VARCHAR(4), @ESSYear)
					 ELSE N'Cả năm ' + CONVERT(VARCHAR(4), @ESSYear) END AS ReportMonth,
				E.EmpID,
				ISNULL(vL.EmpCode, '') AS EmpCode,
				ISNULL(vE.EmpName, '') + CASE
					WHEN NULLIF(LTRIM(RTRIM(vE.EmpName)), '') IS NULL
					  OR NULLIF(LTRIM(RTRIM(vL.EmpCode)), '') IS NULL
					  OR RIGHT(RTRIM(vE.EmpName), LEN(N' - ' + LTRIM(RTRIM(vL.EmpCode)))) = N' - ' + LTRIM(RTRIM(vL.EmpCode))
					THEN N'' ELSE N' - ' + LTRIM(RTRIM(vL.EmpCode))
				END AS EmpName,
				ISNULL(NULLIF(LTRIM(RTRIM(CASE WHEN @LanguageID = 'VN' THEN vL.GenderStr ELSE vL.GenderStrEN END)), ''),
					   CASE WHEN @LanguageID = 'VN' THEN N'Không xác định' ELSE N'Unknown' END) AS Gender,
				CONVERT(VARCHAR(10), CV.DOB, 103) AS Dob,
				ISNULL(vL.StartDateCompanyStr, '') AS NgayVaoLam,
				CONVERT(VARCHAR(10), vL.StartDate, 103) AS NgayVaoCongTy,
				ISNULL(CONVERT(NVARCHAR(20), vL.ThamNienNam_NgayVaoChinhThuc), '') AS ThamNienCongTac,
				ISNULL(SUP.EmpName, '') + CASE
					WHEN NULLIF(LTRIM(RTRIM(SUP.EmpName)), '') IS NULL
					  OR NULLIF(LTRIM(RTRIM(CASE WHEN @LanguageID = 'VN' THEN SUPJT.VNName ELSE SUPJT.Name END)), '') IS NULL
					THEN N'' ELSE N' - ' + LTRIM(RTRIM(CASE WHEN @LanguageID = 'VN' THEN SUPJT.VNName ELSE SUPJT.Name END))
				END AS CapTrenTrucTiep,
				ISNULL(CASE WHEN @LanguageID = 'VN' THEN JTE.VNName ELSE JTE.Name END, '') AS ChucDanh,
				ISNULL(CASE WHEN @LanguageID = 'VN' THEN CBNV.VNName ELSE CBNV.Name END, '') AS CapBacNhanVien,
				ISNULL(CASE WHEN @LanguageID = 'VN' THEN LNV.VNName ELSE LNV.Name END, '') AS LoaiNhanVien,
				CASE WHEN E.Active = 1 THEN N'Đang làm việc' ELSE N'Đã nghỉ việc' END AS TrangThai,
				ISNULL(CV.FilePhoto, '') AS AvatarURL,
				ISNULL(SL.TongLuong, 0) AS LuongGross,
				ISNULL(PC.PhuCap, 0) AS TongPhuCap,
				ISNULL(CASE WHEN @LanguageID = 'VN' THEN CTT.VNName ELSE CTT.Name END, '') AS TenHopDongLaoDong,
				CONVERT(VARCHAR(10), HD.EffectiveDate, 103) AS HieuLucHDLD,
				CONVERT(VARCHAR(10), HD.ToDate, 103) AS HetHanHDLD,
				ISNULL(HD.ContractNo, '') AS SoHopDong,
				CTT.Duration AS SoThang,
				CASE
					WHEN HD.EffectiveDate IS NULL THEN ''
					WHEN CTT.[Type] = 3 THEN N'Còn hiệu lực'
					WHEN HD.ToDate IS NULL OR HD.ToDate >= @ESSNgayHieuLuc THEN N'Còn hiệu lực'
					ELSE N'Hết hạn hợp đồng'
				END AS TrangThaiHopDong,
				CONVERT(FLOAT, dbo.TS_fnTinhPhepNam(E.EmpID, @ESSKyCuoi, @ESSKyCuoi, @ESSWPPhepNam)) AS TongNgayPhepNam,
				CONVERT(FLOAT, CASE WHEN @ESSMonth IS NULL THEN dbo.TS_fnTinhPhepDaNghi(E.EmpID, @ESSKyCuoi, @ESSKyCuoi, @ESSWPPhepNam)
					ELSE @ESSPhepDaNghiDenKy END) AS SoNgayPhepDaNghi,
				CONVERT(FLOAT, CASE WHEN @ESSMonth IS NULL THEN dbo.TS_fnTinhPhepConLai(E.EmpID, @ESSKyCuoi, @ESSKyCuoi, @ESSWPPhepNam)
					ELSE dbo.TS_fnTinhPhepConLai(E.EmpID, @ESSKyCuoi, @ESSKyCuoi, @ESSWPPhepNam)
						+ ISNULL(@ESSPhepDaNghiChuKy, 0) - ISNULL(@ESSPhepDaNghiDenKy, 0) END) AS SoNgayPhepConLai,
				CONVERT(FLOAT, CASE WHEN @ESSMonth IS NULL THEN dbo.TS_fnTinhPhepConLai(E.EmpID, @ESSKyCuoi, @ESSKyCuoi, @ESSWPNghiBu)
					ELSE dbo.TS_fnTinhPhepConLai(E.EmpID, @ESSKyCuoi, @ESSKyCuoi, @ESSWPNghiBu)
						+ ISNULL(@ESSNghiBuDaNghiChuKy, 0) - ISNULL(@ESSNghiBuDaNghiDenKy, 0) END) AS SoNgayNghiBuConLai,
				ISNULL(OT.TongGio, 0) AS TongSoGioLamNgoaiGio,
				ISNULL(VP.SoDon, 0) AS SoDonViPhamCong,
				ISNULL(GT.SoDon, 0) AS SoDonDaGiaiTrinh,
				ISNULL(CCTH.SoNgayCongThucTe, 0) AS SoNgayCongThucTe,
				ISNULL(CCTH.SoNgayNghiPhepHuongLuong, 0) AS SoNgayNghiPhepHuongLuong,
				ISNULL(CCTH.SoNgayNghiPhepKhongLuong, 0) AS SoNgayNghiPhepKhongLuong,
				ISNULL(CCTH.SoNgayNghiHuongBHXH, 0) AS SoNgayNghiHuongBHXH,
				ISNULL(CCTH.SoGioDiTreVeSom, 0) AS SoGioDiTreVeSom,
				CASE WHEN ISNULL(VP.SoDon, 0) - ISNULL(GT.SoDon, 0) < 0 THEN 0
					 ELSE ISNULL(VP.SoDon, 0) - ISNULL(GT.SoDon, 0) END AS SoDonChuaGiaiTrinh
			FROM dbo.HR_tblEmp E (NOLOCK)
			LEFT JOIN dbo.HR_vEmp vE (NOLOCK) ON vE.EmpID = E.EmpID
			LEFT JOIN dbo.HR_vEmpList vL (NOLOCK) ON vL.EmpID = E.EmpID
			LEFT JOIN dbo.HR_tblEmpCV CV (NOLOCK) ON CV.EmpID = E.EmpID
			OUTER APPLY
			(
				SELECT TOP 1 W.SupervisorID, W.LSJobTitleID, W.LSCapBacNhanVienID, W.LSLoaiNhanVienID
				FROM dbo.HR_tblWorkingRecord W (NOLOCK)
				WHERE W.EmpID = E.EmpID AND W.FromDate <= @ESSNgayHieuLuc
				ORDER BY W.FromDate DESC, W.WorkingRecordID DESC
			) WR
			LEFT JOIN dbo.HR_vEmp SUP (NOLOCK) ON SUP.EmpID = TRY_CONVERT(BIGINT, WR.SupervisorID)
			OUTER APPLY
			(
				SELECT TOP 1 W.LSJobTitleID
				FROM dbo.HR_tblWorkingRecord W (NOLOCK)
				WHERE W.EmpID = SUP.EmpID AND W.FromDate <= @ESSNgayHieuLuc
				ORDER BY W.FromDate DESC, W.WorkingRecordID DESC
			) SUPWR
			LEFT JOIN dbo.LS_tblJobTitle SUPJT (NOLOCK) ON SUPJT.LSJobTitleID = SUPWR.LSJobTitleID
			LEFT JOIN dbo.LS_tblJobTitle JTE (NOLOCK) ON JTE.LSJobTitleID = WR.LSJobTitleID
			LEFT JOIN dbo.LS_tblCapBacNhanVien CBNV (NOLOCK) ON CBNV.LSCapBacNhanVienID = WR.LSCapBacNhanVienID
			LEFT JOIN dbo.LS_tblLoaiNhanVien LNV (NOLOCK) ON LNV.LSLoaiNhanVienID = WR.LSLoaiNhanVienID
			OUTER APPLY
			(
				SELECT TOP 1 CONVERT(FLOAT, dbo.sys_fnGetD(S.TongLuong)) AS TongLuong
				FROM dbo.PR_tblSalary S (NOLOCK)
				WHERE S.EmpID = E.EmpID AND S.FromDate <= @ESSNgayHieuLuc
				ORDER BY S.FromDate DESC
			) SL
			OUTER APPLY
			(
				SELECT SUM(CONVERT(FLOAT, dbo.sys_fnGetD(A.Amount))) AS PhuCap
				FROM dbo.PR_tblAddSalaryEmp A (NOLOCK)
				INNER JOIN dbo.LS_tblAdd_Salary L (NOLOCK) ON L.LSAddSalaryID = A.LSAddSalaryID
				WHERE A.EmpID = E.EmpID
				AND L.LSAddSalaryGroupID = 1
				AND A.FromDate <= @ESSNgayHieuLuc
				AND (A.ToDate IS NULL OR A.ToDate >= @ESSNgayHieuLuc)
			) PC
			OUTER APPLY
			(
				SELECT TOP 1 C.LSContractTypeID, C.EffectiveDate, C.ToDate, C.ContractNo
				FROM dbo.HR_tblContract C (NOLOCK)
				WHERE C.EmpID = E.EmpID AND C.EffectiveDate <= @ESSNgayHieuLuc
				ORDER BY C.EffectiveDate DESC
			) HD
			LEFT JOIN dbo.LS_tblContractType CTT (NOLOCK) ON CTT.LSContractTypeID = HD.LSContractTypeID
			OUTER APPLY
			(
				SELECT SUM(ISNULL(K.GioOTNgayDK, 0) + ISNULL(K.GioOTDemDK, 0)) AS TongGio
				FROM dbo.TS_tblLamNgoaiGioKeHoach K (NOLOCK)
				WHERE K.EmpID = E.EmpID
				AND K.ApprovedStatus = 4
				AND K.Ngay >= @ESSKyDau AND K.Ngay < DATEADD(DAY, 1, @ESSKyCuoi)
			) OT
			-- So don vi pham cong: ngay cham cong co vi pham (4 loai, giong block 206)
			OUTER APPLY
			(
				SELECT COUNT(1) AS SoDon
				FROM dbo.TS_tblChamCongCT CC (NOLOCK)
				WHERE CC.EmpID = E.EmpID
				AND CC.DateID >= @ESSKyDau AND CC.DateID < DATEADD(DAY, 1, @ESSKyCuoi)
				AND (CC.DiTre = 1 OR CC.VeSom = 1 OR CC.KhongQuetThe = 1 OR CC.QuetThe1Lan = 1)
			) VP
			-- Tong hop cham cong theo ky dang chon: ngay cong thuc te, cac nhom nghi va gio di tre/ve som.
			OUTER APPLY
			(
				SELECT
					SUM(ISNULL(TH.SoNgayLamViecTT, 0)) AS SoNgayCongThucTe,
					SUM(ISNULL(TH.SoNgayNghiPhep, 0)) AS SoNgayNghiPhepHuongLuong,
					SUM(ISNULL(TH.SoNgayNghiKhongLuong, 0)) AS SoNgayNghiPhepKhongLuong,
					SUM(ISNULL(TH.SoNgayNghiCheDo, 0)) AS SoNgayNghiHuongBHXH,
					SUM(ISNULL(TH.SoGioDiTre, 0) + ISNULL(TH.SoGioVeSom, 0)) AS SoGioDiTreVeSom
				FROM dbo.TS_tblChamCongTH TH (NOLOCK)
				WHERE TH.EmpID = E.EmpID
				AND TH.TuNgay >= @ESSKyDau
				AND TH.TuNgay < DATEADD(DAY, 1, @ESSKyCuoi)
			) CCTH
			OUTER APPLY
			(
				SELECT COUNT(1) AS SoDon
				FROM dbo.TS_tblDKXacNhanQTOnline_V2 X (NOLOCK)
				OUTER APPLY
				(
					SELECT TOP 1 P.[Status]
					FROM dbo.TS_tblDKXacNhanQTOnlineProcess_V2 P (NOLOCK)
					WHERE P.TSDKXacNhanQTOnline2ID = X.TSDKXacNhanQTOnline2ID
					ORDER BY P.TSDKXacNhanQTOnlineProcess2ID DESC
				) PT
				WHERE X.EmpID = E.EmpID
				AND X.NgayDK >= @ESSKyDau AND X.NgayDK < DATEADD(DAY, 1, @ESSKyCuoi)
				AND ISNULL(PT.[Status], X.CurStatus) = 4
			) GT
			WHERE E.EmpID = @EmpID;
		END
		ELSE IF @Activity = 'GetESSDeXuatTuyenDung'
		BEGIN
			SELECT TOP 10
				   D.DemandCode AS SoPhieu,
				   ISNULL(CASE WHEN @LanguageID = 'VN' THEN J.VNName ELSE J.Name END, ISNULL(D.DemandName, '')) AS ViTri,
				   CONVERT(VARCHAR(10), ISNULL(D.CreateDate, D.DemandDate), 103) AS NgayTao,
				   D.REApprovedStatusID AS MaTrangThai,
				   ISNULL(CASE WHEN @LanguageID = 'VN' THEN ST.REApprovedStatusNameVN ELSE ST.REApprovedStatusName END, '') AS TrangThai
			FROM dbo.RE_tblDemand D (NOLOCK)
			LEFT JOIN dbo.LS_tblJobTitle J (NOLOCK) ON J.LSJobTitleID = D.LSJobTitleID
			LEFT JOIN dbo.LS_tblREApprovedStatus ST (NOLOCK) ON ST.REApprovedStatusID = D.REApprovedStatusID
			WHERE D.Creater = @UserGroupID
			ORDER BY ISNULL(D.CreateDate, D.DemandDate) DESC, D.DemandID DESC;
		END
	END
	ELSE IF CHARINDEX('LoadFilter', @Activity) > 0
	BEGIN
	    DECLARE @tblFilter TABLE
		(
			[value]		VARCHAR(12),
			[text]		NVARCHAR(1000),
			selected	BIT,
			[disabled]	BIT
		)
		
		IF @Activity = 'LoadFilter_YEAR'
		BEGIN
			DECLARE @Before INT																																  
			DECLARE @FromYear INT, @ToYear INT = YEAR(GETDATE())
			DECLARE @tblYear TABLE([Year] INT, Seq INT)																										  

			SELECT @Before = ParamValue FROM SYS_tblParameters (NOLOCK) WHERE ParamName = N'SYS_YearFromBefore'
			SET @Before = ISNULL(@Before, 3)
			SET @FromYear = @ToYear - @Before

			WHILE (@FromYear <= @ToYear)
			BEGIN
				INSERT INTO @tblYear([Year],Seq)
				VALUES (@FromYear, @FromYear)
				---------------------------------
				SET @FromYear = @FromYear + 1
			END

			INSERT INTO @tblFilter ([value], [text], selected, [disabled])
			SELECT	[Year] AS [value], [Year] AS [text], 
					CASE WHEN YEAR(GETDATE()) = [Year] THEN 1 ELSE 0 END AS selected, 
					0 AS [disabled]
			FROM @tblYear
			ORDER BY Seq DESC
		END
		ELSE IF @Activity = 'LoadFilter_QUARTER'
		BEGIN
			INSERT INTO @tblFilter ([value], [text], selected, [disabled])
			SELECT A.[value], A.[text], A.selected, A.[disabled]
			FROM
			(
				SELECT 1 AS [value], CASE WHEN @LanguageID = 'VN' THEN N'Quý 1' ELSE N'1st Quarter' END AS [text], 0 AS selected, 0 AS [disabled]
				UNION 
				SELECT 2 AS [value], CASE WHEN @LanguageID = 'VN' THEN N'Quý 2' ELSE N'2nd Quarter' END AS [text], 0 AS selected, 0 AS [disabled]
				UNION 
				SELECT 3 AS [value], CASE WHEN @LanguageID = 'VN' THEN N'Quý 3' ELSE N'3rd Quarter' END AS [text], 0 AS selected, 0 AS [disabled]
				UNION 
				SELECT 4 AS [value], CASE WHEN @LanguageID = 'VN' THEN N'Quý 4' ELSE N'4th Quarter' END AS [text], 0 AS selected, 0 AS [disabled]
			) A
		END
		ELSE IF @Activity = 'LoadFilter_MONTH'
		BEGIN
			INSERT INTO @tblFilter ([value], [text], selected, [disabled])
			SELECT	MonthNumber AS [value], 
					CASE WHEN @LanguageID = 'VN' THEN MonthNameVietnamese ELSE MonthName END AS [text], 0 AS selected,
					0 AS [disabled]
			FROM dbo.GetMonthsFromYearAndQuarter(NULL,NULL)
		END
		ELSE IF @Activity = 'LoadFilter_COMPANY'
		BEGIN
			IF OBJECT_ID('tempdb..#tmpCompanyPQ') IS NOT NULL DROP TABLE [dbo].[#tmpCompanyPQ]
			CREATE TABLE [#tmpCompanyPQ](LSOfficeTypeID NVARCHAR(50), LSCompanyID INT, LSCompanyCode NVARCHAR(510), Name NVARCHAR(1000), Rank INT, Used BIT, IsDefault BIT)
			INSERT INTO [#tmpCompanyPQ] (LSOfficeTypeID, LSCompanyID, LSCompanyCode, Name, Rank, Used, IsDefault)
			EXEC sp_GetDataComboLevel @LanguageID=@LanguageID, @TableName='LS_tblCompany', @UserGroupID=@UserGroupID, @FunctionID=@FunctionID,@NotUsed='1'

			INSERT INTO @tblFilter ([value], [text], selected, [disabled])
			SELECT	LSCompanyID AS [value], [Name] AS [text], 
					CASE WHEN IsDefault = 1 THEN 1 ELSE 0 END AS selected, 
					CASE WHEN ISNULL(Used, 0) = 0 THEN 1 ELSE 0 END AS [disabled]
			FROM [#tmpCompanyPQ] (NOLOCK)
			ORDER BY ISNULL(Rank, 999), [Name]
		END
		ELSE IF @Activity = 'LoadFilter_LEVEL1'
		BEGIN
			IF OBJECT_ID('tempdb..#tmpLevel1PQ') IS NOT NULL DROP TABLE [dbo].[#tmpLevel1PQ]
			CREATE TABLE [#tmpLevel1PQ](LSLevel1ID INT, LSLevel1Code NVARCHAR(510), LSCompanyID INT, Name NVARCHAR(1000), NameParent NVARCHAR(1000), Rank INT, Used BIT)
			INSERT INTO [#tmpLevel1PQ] (LSLevel1ID, LSLevel1Code, LSCompanyID, Name, NameParent, Rank, Used)
			EXEC sp_GetDataComboLevel @LanguageID=@LanguageID, @TableName='LS_tblLevel1', @UserGroupID=@UserGroupID, @FunctionID=@FunctionID,@NotUsed='1'

			INSERT INTO @tblFilter ([value], [text], selected, [disabled])
			SELECT	PQ.LSLevel1ID AS [value], PQ.[Name] AS [text], 
					CASE WHEN A.IsDefault = 1 THEN 1 ELSE 0 END AS selected,
					CASE WHEN ISNULL(PQ.Used, 0) = 0 THEN 1 ELSE 0 END AS [disabled]
			FROM [#tmpLevel1PQ] (NOLOCK) PQ
			INNER JOIN dbo.LS_tblLevel1 (NOLOCK) A ON A.LSCompanyID = PQ.LSCompanyID AND A.LSLevel1ID = PQ.LSLevel1ID
			-- TLG: chua chon cap cha -> tra FULL danh sach (cho phep loc truc tiep tung cap)
			WHERE
			(
				NOT EXISTS
				(
					SELECT 1
					FROM dbo.NEW_fnTableParseFilterJson(ISNULL(@FilterJson, N'{}')) F
					WHERE F.FilterName = 'COMPANY'
				)
				OR EXISTS
				(
					SELECT 1
					FROM dbo.NEW_fnTableParseFilterJson(ISNULL(@FilterJson, N'{}')) F
					WHERE F.FilterName = 'COMPANY' AND F.FilterValue = PQ.LSCompanyID
				)
			)
			ORDER BY ISNULL(PQ.Rank, 999), PQ.[Name]
		END
		ELSE IF @Activity = 'LoadFilter_LEVEL2'
		BEGIN
			IF OBJECT_ID('tempdb..#tmpLevel2PQ') IS NOT NULL DROP TABLE [dbo].[#tmpLevel2PQ]
			CREATE TABLE [#tmpLevel2PQ](LSLevel1ID INT, LSLevel2ID INT, LSLevel2Code NVARCHAR(510), Name NVARCHAR(1000), NameParent NVARCHAR(1000), Rank INT, Used BIT)
			INSERT INTO [#tmpLevel2PQ] (LSLevel1ID, LSLevel2ID, LSLevel2Code, Name, NameParent, Rank, Used)
			EXEC sp_GetDataComboLevel @LanguageID=@LanguageID, @TableName='LS_tblLevel2', @UserGroupID=@UserGroupID, @FunctionID=@FunctionID,@NotUsed='1'

			INSERT INTO @tblFilter ([value], [text], selected, [disabled])
			SELECT PQ.LSLevel2ID AS [value], PQ.[Name] AS [text], 0 AS selected,
				   CASE WHEN ISNULL(PQ.Used, 0) = 0 THEN 1 ELSE 0 END AS [disabled]
			FROM [#tmpLevel2PQ] (NOLOCK) PQ
			-- TLG: chua chon cap cha -> tra FULL danh sach
			WHERE
			(
				NOT EXISTS
				(
					SELECT 1
					FROM dbo.NEW_fnTableParseFilterJson(ISNULL(@FilterJson, N'{}')) F
					WHERE F.FilterName = 'LEVEL1'
				)
				OR EXISTS
				(
					SELECT 1
					FROM dbo.NEW_fnTableParseFilterJson(ISNULL(@FilterJson, N'{}')) F
					WHERE F.FilterName = 'LEVEL1' AND F.FilterValue = PQ.LSLevel1ID
				)
			)
			ORDER BY ISNULL(PQ.Rank, 999), PQ.[Name]
		END
		ELSE IF @Activity = 'LoadFilter_LEVEL3'
		BEGIN
			IF OBJECT_ID('tempdb..#tmpLevel3PQ') IS NOT NULL DROP TABLE [dbo].[#tmpLevel3PQ]
			CREATE TABLE [#tmpLevel3PQ](LSLevel2ID INT, LSLevel3ID INT, LSLevel3Code NVARCHAR(510), Name NVARCHAR(1000), NameParent NVARCHAR(1000), Rank INT, Used BIT)
			INSERT INTO [#tmpLevel3PQ] (LSLevel2ID, LSLevel3ID, LSLevel3Code, Name, NameParent, Rank, Used)
			EXEC sp_GetDataComboLevel @LanguageID=@LanguageID, @TableName='LS_tblLevel3', @UserGroupID=@UserGroupID, @FunctionID=@FunctionID,@NotUsed='1'

			INSERT INTO @tblFilter ([value], [text], selected, [disabled])
			SELECT PQ.LSLevel3ID AS [value], PQ.[Name] AS [text], 0 AS selected,
				   CASE WHEN ISNULL(PQ.Used, 0) = 0 THEN 1 ELSE 0 END AS [disabled]
			FROM [#tmpLevel3PQ] (NOLOCK) PQ
			-- TLG: chua chon cap cha -> tra FULL danh sach
			WHERE
			(
				NOT EXISTS
				(
					SELECT 1
					FROM dbo.NEW_fnTableParseFilterJson(ISNULL(@FilterJson, N'{}')) F
					WHERE F.FilterName = 'LEVEL2'
				)
				OR EXISTS
				(
					SELECT 1
					FROM dbo.NEW_fnTableParseFilterJson(ISNULL(@FilterJson, N'{}')) F
					WHERE F.FilterName = 'LEVEL2' AND F.FilterValue = PQ.LSLevel2ID
				)
			)
			ORDER BY ISNULL(PQ.Rank, 999), PQ.[Name]
		END
		ELSE IF @Activity = 'LoadFilter_LEVEL4'
		BEGIN
			IF OBJECT_ID('tempdb..#tmpLevel4PQ') IS NOT NULL DROP TABLE [dbo].[#tmpLevel4PQ]
			CREATE TABLE [#tmpLevel4PQ](LSLevel4ID INT, LSLevel4Code NVARCHAR(510), LSLevel3ID INT, Name NVARCHAR(1000), Rank INT, Used BIT)
			INSERT INTO [#tmpLevel4PQ] (LSLevel4ID, LSLevel4Code, LSLevel3ID, Name, Rank, Used)
			EXEC sp_GetDataComboLevel @LanguageID=@LanguageID, @TableName='LS_tblLevel4', @UserGroupID=@UserGroupID, @FunctionID=@FunctionID,@NotUsed='1'

			INSERT INTO @tblFilter ([value], [text], selected, [disabled])
			SELECT PQ.LSLevel4ID AS [value], PQ.[Name] AS [text], 0 AS selected,
				   CASE WHEN ISNULL(PQ.Used, 0) = 0 THEN 1 ELSE 0 END AS [disabled]
			FROM [#tmpLevel4PQ] (NOLOCK) PQ
			-- TLG: chua chon cap cha -> tra FULL danh sach
			WHERE
			(
				NOT EXISTS
				(
					SELECT 1
					FROM dbo.NEW_fnTableParseFilterJson(ISNULL(@FilterJson, N'{}')) F
					WHERE F.FilterName = 'LEVEL3'
				)
				OR EXISTS
				(
					SELECT 1
					FROM dbo.NEW_fnTableParseFilterJson(ISNULL(@FilterJson, N'{}')) F
					WHERE F.FilterName = 'LEVEL3' AND F.FilterValue = PQ.LSLevel3ID
				)
			)
			ORDER BY ISNULL(PQ.Rank, 999), PQ.[Name]
		END
		ELSE IF @Activity = 'LoadFilter_LEVEL5'
		BEGIN
			IF OBJECT_ID('tempdb..#tmpLevel5PQ') IS NOT NULL DROP TABLE [dbo].[#tmpLevel5PQ]
			CREATE TABLE [#tmpLevel5PQ](LSLevel5ID INT, LSLevel5Code NVARCHAR(510), LSLevel4ID INT, Name NVARCHAR(1000), Rank INT, Used BIT)
			INSERT INTO [#tmpLevel5PQ] (LSLevel5ID, LSLevel5Code, LSLevel4ID, Name, Rank, Used)
			EXEC sp_GetDataComboLevel @LanguageID=@LanguageID, @TableName='LS_tblLevel5', @UserGroupID=@UserGroupID, @FunctionID=@FunctionID,@NotUsed='1'

			INSERT INTO @tblFilter ([value], [text], selected, [disabled])
			SELECT PQ.LSLevel5ID AS [value], PQ.[Name] AS [text], 0 AS selected,
				   CASE WHEN ISNULL(PQ.Used, 0) = 0 THEN 1 ELSE 0 END AS [disabled]
			FROM [#tmpLevel5PQ] (NOLOCK) PQ
			-- TLG: chua chon cap cha -> tra FULL danh sach
			WHERE
			(
				NOT EXISTS
				(
					SELECT 1
					FROM dbo.NEW_fnTableParseFilterJson(ISNULL(@FilterJson, N'{}')) F
					WHERE F.FilterName = 'LEVEL4'
				)
				OR EXISTS
				(
					SELECT 1
					FROM dbo.NEW_fnTableParseFilterJson(ISNULL(@FilterJson, N'{}')) F
					WHERE F.FilterName = 'LEVEL4' AND F.FilterValue = PQ.LSLevel4ID
				)
			)
			ORDER BY ISNULL(PQ.Rank, 999), PQ.[Name]
		END
		ELSE IF @Activity = 'LoadFilter_LEVEL6'
		BEGIN
			IF OBJECT_ID('tempdb..#tmpLevel6PQ') IS NOT NULL DROP TABLE [dbo].[#tmpLevel6PQ]
			CREATE TABLE [#tmpLevel6PQ](LSLevel6ID INT, LSLevel6Code NVARCHAR(510), LSLevel5ID INT, Name NVARCHAR(1000), Rank INT, Used BIT)
			INSERT INTO [#tmpLevel6PQ] (LSLevel6ID, LSLevel6Code, LSLevel5ID, Name, Rank, Used)
			EXEC sp_GetDataComboLevel @LanguageID=@LanguageID, @TableName='LS_tblLevel6', @UserGroupID=@UserGroupID, @FunctionID=@FunctionID,@NotUsed='1'

			INSERT INTO @tblFilter ([value], [text], selected, [disabled])
			SELECT PQ.LSLevel6ID AS [value], PQ.[Name] AS [text], 0 AS selected,
				   CASE WHEN ISNULL(PQ.Used, 0) = 0 THEN 1 ELSE 0 END AS [disabled]
			FROM [#tmpLevel6PQ] (NOLOCK) PQ
			-- TLG: chua chon cap cha -> tra FULL danh sach
			WHERE
			(
				NOT EXISTS
				(
					SELECT 1
					FROM dbo.NEW_fnTableParseFilterJson(ISNULL(@FilterJson, N'{}')) F
					WHERE F.FilterName = 'LEVEL5'
				)
				OR EXISTS
				(
					SELECT 1
					FROM dbo.NEW_fnTableParseFilterJson(ISNULL(@FilterJson, N'{}')) F
					WHERE F.FilterName = 'LEVEL5' AND F.FilterValue = PQ.LSLevel5ID
				)
			)
			ORDER BY ISNULL(PQ.Rank, 999), PQ.[Name]
		END
		ELSE IF @Activity = 'LoadFilter_LEVEL7'
		BEGIN
			IF OBJECT_ID('tempdb..#tmpLevel7PQ') IS NOT NULL DROP TABLE [dbo].[#tmpLevel7PQ]
			CREATE TABLE [#tmpLevel7PQ](LSLevel7ID INT, LSLevel7Code NVARCHAR(510), LSLevel6ID INT, Name NVARCHAR(1000), Rank INT, Used BIT)
			INSERT INTO [#tmpLevel7PQ] (LSLevel7ID, LSLevel7Code, LSLevel6ID, Name, Rank, Used)
			EXEC sp_GetDataComboLevel @LanguageID=@LanguageID, @TableName='LS_tblLevel7', @UserGroupID=@UserGroupID, @FunctionID=@FunctionID,@NotUsed='1'

			INSERT INTO @tblFilter ([value], [text], selected, [disabled])
			SELECT PQ.LSLevel7ID AS [value], PQ.[Name] AS [text], 0 AS selected,
				   CASE WHEN ISNULL(PQ.Used, 0) = 0 THEN 1 ELSE 0 END AS [disabled]
			FROM [#tmpLevel7PQ] (NOLOCK) PQ
			-- TLG: chua chon cap cha -> tra FULL danh sach
			WHERE
			(
				NOT EXISTS
				(
					SELECT 1
					FROM dbo.NEW_fnTableParseFilterJson(ISNULL(@FilterJson, N'{}')) F
					WHERE F.FilterName = 'LEVEL6'
				)
				OR EXISTS
				(
					SELECT 1
					FROM dbo.NEW_fnTableParseFilterJson(ISNULL(@FilterJson, N'{}')) F
					WHERE F.FilterName = 'LEVEL6' AND F.FilterValue = PQ.LSLevel6ID
				)
			)
			ORDER BY ISNULL(PQ.Rank, 999), PQ.[Name]
		END
		ELSE IF @Activity = 'LoadFilter_LEVEL8'
		BEGIN
			IF OBJECT_ID('tempdb..#tmpLevel8PQ') IS NOT NULL DROP TABLE [dbo].[#tmpLevel8PQ]
			CREATE TABLE [#tmpLevel8PQ](LSLevel8ID INT, LSLevel8Code NVARCHAR(510), LSLevel7ID INT, Name NVARCHAR(1000), Rank INT, Used BIT)
			INSERT INTO [#tmpLevel8PQ] (LSLevel8ID, LSLevel8Code, LSLevel7ID, Name, Rank, Used)
			EXEC sp_GetDataComboLevel @LanguageID=@LanguageID, @TableName='LS_tblLevel8', @UserGroupID=@UserGroupID, @FunctionID=@FunctionID,@NotUsed='1'

			INSERT INTO @tblFilter ([value], [text], selected, [disabled])
			SELECT PQ.LSLevel8ID AS [value], PQ.[Name] AS [text], 0 AS selected,
				   CASE WHEN ISNULL(PQ.Used, 0) = 0 THEN 1 ELSE 0 END AS [disabled]
			FROM [#tmpLevel8PQ] (NOLOCK) PQ
			-- TLG: chua chon cap cha -> tra FULL danh sach
			WHERE
			(
				NOT EXISTS
				(
					SELECT 1
					FROM dbo.NEW_fnTableParseFilterJson(ISNULL(@FilterJson, N'{}')) F
					WHERE F.FilterName = 'LEVEL7'
				)
				OR EXISTS
				(
					SELECT 1
					FROM dbo.NEW_fnTableParseFilterJson(ISNULL(@FilterJson, N'{}')) F
					WHERE F.FilterName = 'LEVEL7' AND F.FilterValue = PQ.LSLevel7ID
				)
			)
			ORDER BY ISNULL(PQ.Rank, 999), PQ.[Name]
		END
		ELSE IF @Activity = 'LoadFilter_LEVEL9'
		BEGIN
			IF OBJECT_ID('tempdb..#tmpLevel9PQ') IS NOT NULL DROP TABLE [dbo].[#tmpLevel9PQ]
			CREATE TABLE [#tmpLevel9PQ](LSLevel9ID INT, LSLevel9Code NVARCHAR(510), LSLevel8ID INT, Name NVARCHAR(1000), Rank INT, Used BIT)
			INSERT INTO [#tmpLevel9PQ] (LSLevel9ID, LSLevel9Code, LSLevel8ID, Name, Rank, Used)
			EXEC sp_GetDataComboLevel @LanguageID=@LanguageID, @TableName='LS_tblLevel9', @UserGroupID=@UserGroupID, @FunctionID=@FunctionID,@NotUsed='1'

			INSERT INTO @tblFilter ([value], [text], selected, [disabled])
			SELECT PQ.LSLevel9ID AS [value], PQ.[Name] AS [text], 0 AS selected,
				   CASE WHEN ISNULL(PQ.Used, 0) = 0 THEN 1 ELSE 0 END AS [disabled]
			FROM [#tmpLevel9PQ] (NOLOCK) PQ
			-- TLG: chua chon cap cha -> tra FULL danh sach
			WHERE
			(
				NOT EXISTS
				(
					SELECT 1
					FROM dbo.NEW_fnTableParseFilterJson(ISNULL(@FilterJson, N'{}')) F
					WHERE F.FilterName = 'LEVEL8'
				)
				OR EXISTS
				(
					SELECT 1
					FROM dbo.NEW_fnTableParseFilterJson(ISNULL(@FilterJson, N'{}')) F
					WHERE F.FilterName = 'LEVEL8' AND F.FilterValue = PQ.LSLevel8ID
				)
			)
			ORDER BY ISNULL(PQ.Rank, 999), PQ.[Name]
		END
		ELSE IF @Activity = 'LoadFilter_HLEVEL1'
		BEGIN
			-- FID 339 configures data access for each function. Resolve that access
			-- through the same employee-permission function used by dashboard data.
			;WITH PermittedEmployees AS
			(
				SELECT DISTINCT PQ.EmpID
				FROM dbo.fnGetAllEmp_Permission_EffDate(@UserGroupID, @FunctionID, @dDate) PQ
			),
			PermittedHLevel1 AS
			(
				SELECT DISTINCT WR.LSHLevel1ID
				FROM PermittedEmployees PQ
				CROSS APPLY
				(
					SELECT TOP 1 W.LSHLevel1ID
					FROM dbo.HR_tblWorkingRecord W (NOLOCK)
					WHERE W.EmpID = PQ.EmpID
					AND W.FromDate <= @dDate
					ORDER BY W.FromDate DESC, W.WorkingRecordID DESC
				) WR
				WHERE WR.LSHLevel1ID IS NOT NULL
			)
			INSERT INTO @tblFilter ([value], [text], selected, [disabled])
			SELECT	H.LSHLevel1ID AS [value],
					COALESCE(NULLIF(CASE WHEN @LanguageID = 'VN' THEN H.VNName ELSE H.[Name] END, N''), H.LSHLevel1Code) AS [text],
					0 AS selected,
					0 AS [disabled]
			FROM dbo.LS_tblHLevel1 H (NOLOCK)
			INNER JOIN PermittedHLevel1 P ON P.LSHLevel1ID = H.LSHLevel1ID
			WHERE ISNULL(H.Used, 0) = 1
			ORDER BY ISNULL(H.[Rank], 999),
					 COALESCE(NULLIF(CASE WHEN @LanguageID = 'VN' THEN H.VNName ELSE H.[Name] END, N''), H.LSHLevel1Code)
		END
		ELSE IF @Activity = 'LoadFilter_LOAICHUCDANH'
		BEGIN
			INSERT INTO @tblFilter ([value], [text], selected, [disabled])
			SELECT	LSLoaiChucDanhID AS [value],
					CASE WHEN @LanguageID = 'VN' THEN VNName ELSE [Name] END AS [text],
					0 AS selected,
					0 AS [disabled]
			FROM LS_tblLoaiChucDanh (NOLOCK)
			WHERE ISNULL(Used, 0) = 1
			ORDER BY ISNULL(Rank, 999), CASE WHEN @LanguageID = 'VN' THEN VNName ELSE [Name] END
		END
		ELSE IF @Activity = 'LoadFilter_JOBTITLE'
		BEGIN
			INSERT INTO @tblFilter ([value], [text], selected, [disabled])
			SELECT J.LSJobTitleID,
				   COALESCE(NULLIF(CASE WHEN @LanguageID = 'VN' THEN J.VNName ELSE J.[Name] END, N''), J.LSJobTitleCode),
				   0, 0
			FROM dbo.LS_tblJobTitle J (NOLOCK)
			WHERE ISNULL(J.Used, 0) = 1
			ORDER BY ISNULL(J.[Rank], 999), J.LSJobTitleID;
		END
		ELSE IF @Activity = 'LoadFilter_CAPBACNV'
		BEGIN
			INSERT INTO @tblFilter ([value], [text], selected, [disabled])
			SELECT C.LSCapBacNhanVienID,
				   COALESCE(NULLIF(CASE WHEN @LanguageID = 'VN' THEN C.VNName ELSE C.[Name] END, N''), C.LSCapBacNhanVienCode),
				   0, 0
			FROM dbo.LS_tblCapBacNhanVien C (NOLOCK)
			WHERE ISNULL(C.Used, 0) = 1
			ORDER BY ISNULL(C.[Rank], 999), C.LSCapBacNhanVienID;
		END
		ELSE IF @Activity = 'LoadFilter_MODULE'
		BEGIN
			CREATE TABLE [#tmpModulePQ] ( [ModuleID] nvarchar(12), [ModuleName] nvarchar(100), [ModuleName2] nvarchar(100), [GhiChu] nvarchar(500), [GhiChu2] nvarchar(500), [ModuleHome] nvarchar(100), [Rank] int, [cssClass] nvarchar(61), [cssClassRoot] nvarchar(30), [urlIcon] nvarchar(100), [urlIconHover] nvarchar(100), [Parent] int, [FunctionID] int, [Ascx] nvarchar(500), [AscxShort] nvarchar(255) )

			INSERT INTO [#tmpModulePQ] 
			EXEC sp_clsCommon @Activity = N'GetModuleList',@Language = @LanguageID, @UserGroupID = @UserGroupID

		    INSERT INTO @tblFilter ([value], [text], selected, [disabled])
			SELECT ModuleID, ModuleName, 0, 0
			FROM [#tmpModulePQ]
			ORDER BY ISNULL(Rank, 999), ModuleName
		END
		ELSE IF @Activity = 'LoadFilter_NHOMLAODONG'
		BEGIN
			INSERT INTO @tblFilter ([value], [text], selected, [disabled])
			SELECT	CV.LSChucVuID AS [value],
					ISNULL(CASE WHEN @LanguageID = 'VN' THEN CV.TenChucVuV ELSE CV.TenChucVuE END, CV.TenChucVuV) AS [text],
					CASE WHEN ISNULL(CV.IsDefault, 0) = 1 THEN 1 ELSE 0 END AS selected,
					CASE WHEN ISNULL(CV.SuDung, 0) = 0 THEN 1 ELSE 0 END AS [disabled]
			FROM dbo.LS_tblChucVu (NOLOCK) CV
			WHERE ISNULL(CV.SuDung, 0) = 1
			ORDER BY ISNULL(CV.STT, 999), ISNULL(CASE WHEN @LanguageID = 'VN' THEN CV.TenChucVuV ELSE CV.TenChucVuE END, CV.TenChucVuV);
		END

		IF @Activity LIKE 'LoadFilter_LEVEL[1-9]'
		   AND EXISTS (SELECT 1 FROM @tblFilter GROUP BY [text] HAVING COUNT(*) > 1)
		BEGIN
			DECLARE @DuplicateOrgOptions TABLE ([value] VARCHAR(12) PRIMARY KEY, [text] NVARCHAR(1000));
			INSERT INTO @DuplicateOrgOptions ([value], [text])
			SELECT F.[value], F.[text]
			FROM @tblFilter F
			JOIN (SELECT [text] FROM @tblFilter GROUP BY [text] HAVING COUNT(*) > 1) D
			  ON D.[text] = F.[text];

			CREATE TABLE #OrgFilterAncestors
			(
				RootValue VARCHAR(12) NOT NULL,
				RootText NVARCHAR(1000) NOT NULL,
				Depth TINYINT NOT NULL,
				NodeName NVARCHAR(1000) NOT NULL
			);

DECLARE @OrgFilterLevel INT = TRY_CONVERT(INT, RIGHT(@Activity, 1));
			INSERT INTO #OrgFilterAncestors (RootValue, RootText, Depth, NodeName)
			SELECT D.[value], D.[text], CAST(@OrgFilterLevel - A.LevelNo AS TINYINT),
			       CAST(COALESCE(NULLIF(CASE WHEN @LanguageID = 'VN' THEN A.VNName ELSE A.ENName END, N''), A.ENName, N'') AS NVARCHAR(1000))
			FROM @DuplicateOrgOptions D
			LEFT JOIN dbo.LS_tblLevel9 L9 (NOLOCK) ON @OrgFilterLevel = 9 AND L9.LSLevel9ID = TRY_CONVERT(INT, D.[value])
			LEFT JOIN dbo.LS_tblLevel8 L8 (NOLOCK) ON L8.LSLevel8ID = CASE WHEN @OrgFilterLevel = 8 THEN TRY_CONVERT(INT, D.[value]) ELSE L9.LSLevel8ID END
			LEFT JOIN dbo.LS_tblLevel7 L7 (NOLOCK) ON L7.LSLevel7ID = CASE WHEN @OrgFilterLevel = 7 THEN TRY_CONVERT(INT, D.[value]) ELSE L8.LSLevel7ID END
			LEFT JOIN dbo.LS_tblLevel6 L6 (NOLOCK) ON L6.LSLevel6ID = CASE WHEN @OrgFilterLevel = 6 THEN TRY_CONVERT(INT, D.[value]) ELSE L7.LSLevel6ID END
			LEFT JOIN dbo.LS_tblLevel5 L5 (NOLOCK) ON L5.LSLevel5ID = CASE WHEN @OrgFilterLevel = 5 THEN TRY_CONVERT(INT, D.[value]) ELSE L6.LSLevel5ID END
			LEFT JOIN dbo.LS_tblLevel4 L4 (NOLOCK) ON L4.LSLevel4ID = CASE WHEN @OrgFilterLevel = 4 THEN TRY_CONVERT(INT, D.[value]) ELSE L5.LSLevel4ID END
			LEFT JOIN dbo.LS_tblLevel3 L3 (NOLOCK) ON L3.LSLevel3ID = CASE WHEN @OrgFilterLevel = 3 THEN TRY_CONVERT(INT, D.[value]) ELSE L4.LSLevel3ID END
			LEFT JOIN dbo.LS_tblLevel2Level3 Link23 (NOLOCK) ON Link23.LSLevel3ID = L3.LSLevel3ID
			LEFT JOIN dbo.LS_tblLevel2 L2 (NOLOCK) ON L2.LSLevel2ID = CASE WHEN @OrgFilterLevel = 2 THEN TRY_CONVERT(INT, D.[value]) ELSE Link23.LSLevel2ID END
			LEFT JOIN dbo.LS_tblLevel1Level2 Link12 (NOLOCK) ON Link12.LSLevel2ID = L2.LSLevel2ID
			LEFT JOIN dbo.LS_tblLevel1 L1 (NOLOCK) ON L1.LSLevel1ID = CASE WHEN @OrgFilterLevel = 1 THEN TRY_CONVERT(INT, D.[value]) ELSE Link12.LSLevel1ID END
			LEFT JOIN dbo.LS_tblCompany C (NOLOCK) ON C.LSCompanyID = L1.LSCompanyID
			CROSS APPLY (VALUES
				(0, C.VNName, C.[Name]), (1, L1.VNName, L1.[Name]),
				(2, L2.VNName, L2.[Name]), (3, L3.VNName, L3.[Name]),
				(4, L4.VNName, L4.[Name]), (5, L5.VNName, L5.[Name]),
				(6, L6.VNName, L6.[Name]), (7, L7.VNName, L7.[Name]),
				(8, L8.VNName, L8.[Name])
			) A(LevelNo, VNName, ENName)
			WHERE A.LevelNo < @OrgFilterLevel;

			;WITH OrderedAncestors AS
			(
				SELECT RootValue, RootText, NodeName,
				       ROW_NUMBER() OVER (PARTITION BY RootValue ORDER BY Depth) AS Seq
				FROM #OrgFilterAncestors
				WHERE Depth > 0 AND NodeName <> N''
			), AncestorPaths AS
			(
				SELECT RootValue, RootText, Seq, CAST(NodeName AS NVARCHAR(4000)) AS NodePath
				FROM OrderedAncestors
				WHERE Seq = 1
				UNION ALL
				SELECT P.RootValue, P.RootText, A.Seq,
				       CAST(P.NodePath + N' / ' + A.NodeName AS NVARCHAR(4000))
				FROM AncestorPaths P
				JOIN OrderedAncestors A ON A.RootValue = P.RootValue AND A.Seq = P.Seq + 1
			), UniquePaths AS
			(
				SELECT RootValue, NodePath, Seq,
				       COUNT(*) OVER (PARTITION BY RootText, NodePath) AS PathCount
				FROM AncestorPaths
			), ShortestUniquePath AS
			(
				SELECT RootValue, NodePath,
				       ROW_NUMBER() OVER (PARTITION BY RootValue ORDER BY Seq) AS RowNum
				FROM UniquePaths
				WHERE PathCount = 1
			)
			UPDATE F
			SET [text] = LEFT(F.[text] + N' (' + COALESCE(A.NodePath, N'#' + F.[value]) + N')', 1000)
			FROM @tblFilter F
			JOIN @DuplicateOrgOptions D ON D.[value] = F.[value]
			LEFT JOIN ShortestUniquePath A ON A.RootValue = D.[value] AND A.RowNum = 1;

			UPDATE F
			SET [text] = LEFT(F.[text], 960) + N' [#' + F.[value] + N']'
			FROM @tblFilter F
			JOIN (SELECT [text] FROM @tblFilter GROUP BY [text] HAVING COUNT(*) > 1) D
			  ON D.[text] = F.[text];
		END

		SELECT * FROM @tblFilter
	END
END




