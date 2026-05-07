USE [iHRP_V34_PMC_PRO]
GO
/****** Object:  StoredProcedure [dbo].[HR_sprptThongKeNhanSuThang]    Script Date: 3/3/2026 3:36:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[HR_sprptThongKeNhanSuThang]
@LanguageID 							NCHAR(2) = 'VN',
@FunctionID								NVARCHAR(15) = NULL,
@UserGroupID							NVARCHAR(150) = NULL,
@Activity								NVARCHAR(50) = NULL,
-----------------------------------------------------
@EmpCode								NVARCHAR(30) = NULL,
@EmpName								NVARCHAR(200) = NULL,
@LSCompanyID							INT = NULL,
@LSLevel1ID								INT = NULL,
@LSLevel2ID								INT = NULL,
@LSLevel3ID								INT = NULL,
@LSLevel4ID								INT = NULL,
@LSLevel5ID								INT = NULL,
@LSLevel6ID								INT = NULL,
@LSLevel7ID								INT = NULL,
@LSLevel8ID								INT = NULL,
@LSLevel9ID								INT = NULL,
@LSLocationID							INT = NULL, 
@LSJobTitleID							INT = NULL,
@LSNhomNhanVienID						INT=NULL,
@LSLoaiHinhNhanVienID					INT=NULL,
@Status									NVARCHAR(2) = NULL,
@LSHLevel1ID							INT = NULL,
@LSHLevel2ID							INT = NULL,
@LSHLevel3ID							INT = NULL,
@LSHLevel4ID							INT = NULL,
@LSHLevel5ID							INT = NULL,
@LSHLevel6ID							INT = NULL,  
-----------------------------------------------------
@EHDS_LSLoaiNhanVienID					NVARCHAR(MAX) = NULL,
@EHDS_LSNhomNhanVienID					NVARCHAR(MAX) = NULL,
@EHDS_LSCapBacNhanVienID				NVARCHAR(MAX) = NULL,
@EHDS_LSContractTypeID					NVARCHAR(MAX) = NULL,
@EHDS_LSStatusChangeID					NVARCHAR(MAX) = NULL,
@EHDS_UserGroupID						NVARCHAR(MAX) = NULL,
@EHDS_Email								NVARCHAR(MAX) = NULL,
@EHDS_HRCode							NVARCHAR(MAX) = NULL,
@EHDS_IDNo								NVARCHAR(MAX) = NULL,
@EHDS_MaSoThue							NVARCHAR(MAX) = NULL,
@EHDS_AccountNo							NVARCHAR(MAX) = NULL,
@EHDS_MaTheChamCong						NVARCHAR(MAX) = NULL,
@EHDS_EmpCodeOld						NVARCHAR(MAX) = NULL,
-----------------------------------------------------
@FromDate								NVARCHAR(10) = NULL,
@ToDate									NVARCHAR(10) = NULL
AS
BEGIN
	DECLARE @dFromDate		DATETIME,
			@dToDate		DATETIME

	SET @dFromDate = CASE WHEN ISNULL(@FromDate, '') = '' THEN '1900-01-01' ELSE CONVERT(DATETIME, @FromDate, 103) END
	SET @dToDate = CASE WHEN ISNULL(@ToDate, '') = '' THEN '2500-12-31' ELSE  CONVERT(DATETIME, @ToDate, 103) END

	SET @EHDS_UserGroupID = CASE WHEN @EHDS_UserGroupID = '' THEN NULL ELSE  dbo.fnConvertToStringParseXML(@EHDS_UserGroupID,2) END 
	SET @EHDS_Email = CASE WHEN @EHDS_Email = '' THEN NULL ELSE  dbo.fnConvertToStringParseXML(@EHDS_Email,2) END
	SET @EHDS_HRCode = CASE WHEN @EHDS_HRCode = '' THEN NULL ELSE  dbo.fnConvertToStringParseXML(@EHDS_HRCode,2) END
	SET @EHDS_IDNo = CASE WHEN @EHDS_IDNo = '' THEN NULL ELSE  dbo.fnConvertToStringParseXML(@EHDS_IDNo,2) END
	SET @EHDS_MaSoThue = CASE WHEN @EHDS_MaSoThue = '' THEN NULL ELSE  dbo.fnConvertToStringParseXML(@EHDS_MaSoThue,2) END
	SET @EHDS_AccountNo = CASE WHEN @EHDS_AccountNo = '' THEN NULL ELSE  dbo.fnConvertToStringParseXML(@EHDS_AccountNo,2) END
	SET @EHDS_MaTheChamCong = CASE WHEN @EHDS_MaTheChamCong = '' THEN NULL ELSE  dbo.fnConvertToStringParseXML(@EHDS_MaTheChamCong,2) END
	SET @EHDS_EmpCodeOld = CASE WHEN @EHDS_EmpCodeOld = '' THEN NULL ELSE  dbo.fnConvertToStringParseXML(@EHDS_EmpCodeOld,2) END


	IF OBJECT_ID('tempdb..#HR_tblDSNV_PQ') IS NOT NULL
		DROP TABLE [#HR_tblDSNV_PQ]
	CREATE TABLE [#HR_tblDSNV_PQ] (EmpID INT)
	
	CREATE INDEX [IX_#HR_tblDSNV_PQ_EmpID] ON [dbo].[#HR_tblDSNV_PQ] ([EmpID])

	IF OBJECT_ID('tempdb..#HR_tblDSNV_PQ_E') IS NOT NULL
		DROP TABLE [#HR_tblDSNV_PQ_E]
	CREATE TABLE [#HR_tblDSNV_PQ_E] (EmpID INT)
	
	CREATE INDEX [IX_#HR_tblDSNV_PQ_E_EmpID] ON [dbo].[#HR_tblDSNV_PQ_E] ([EmpID])
	
	INSERT	INTO dbo.[#HR_tblDSNV_PQ]
	EXEC	HR_spGetEmpList_EmpHeaderSearch 
			@LanguageID  = @LanguageID,
			@UserGroupID = @UserGroupID,
			@FunctionID  = @FunctionID,

			@EmpCode			= @EmpCode,		@EmpName			= @EmpName,
			@LSCompanyID		= @LSCompanyID,		@LSLevel1ID			= @LSLevel1ID,	
			@LSLevel2ID			= @LSLevel2ID,		@LSLevel3ID			= @LSLevel3ID,	
			@LSLevel4ID			= @LSLevel4ID,		@LSLevel5ID			= @LSLevel5ID,	
			@LSLevel6ID			= @LSLevel6ID,		@LSLevel7ID			= @LSLevel7ID,	
			@LSLevel8ID			= @LSLevel8ID,		@LSLevel9ID			= @LSLevel9ID,	
			@LSHLevel1ID		= @LSHLevel1ID,		@LSHLevel2ID		= @LSHLevel2ID,
			@LSHLevel3ID		= @LSHLevel3ID,		@LSHLevel4ID		= @LSHLevel4ID,
			@LSHLevel5ID		= @LSHLevel5ID,		@LSHLevel6ID		= @LSHLevel6ID,
			@LSLoaiHinhNhanVienID = @LSLoaiHinhNhanVienID,	@Status		= @Status,
			@LSLocationID		= @LSLocationID,	@LSJobTitleID		= @LSJobTitleID,

			@EHDS_LSLoaiNhanVienID		= @EHDS_LSLoaiNhanVienID,
			@EHDS_LSNhomNhanVienID		= @EHDS_LSNhomNhanVienID,
			@EHDS_LSCapBacNhanVienID	= @EHDS_LSCapBacNhanVienID,
			@EHDS_LSContractTypeID		= @EHDS_LSContractTypeID,
			@EHDS_LSStatusChangeID		= @EHDS_LSStatusChangeID,
			@EHDS_UserGroupID			= @EHDS_UserGroupID,
			@EHDS_Email					= @EHDS_Email,
			@EHDS_HRCode				= @EHDS_HRCode,
			@EHDS_IDNo					= @EHDS_IDNo,
			@EHDS_MaSoThue				= @EHDS_MaSoThue,
			@EHDS_AccountNo				= @EHDS_AccountNo,
			@EHDS_MaTheChamCong			= @EHDS_MaTheChamCong,
			@EHDS_EmpCodeOld			= @EHDS_EmpCodeOld,
			
			@IsPermission				= 1,		@IsPermission_TheoThoiGian	= 0,
			@IsPermission_NonEmp		= 0,		@IsDSNV_TheoThoiGian		= 1,
			@IsStatus_TheoThoiGian		= 0,		@dToDate					= @dFromDate

	INSERT	INTO dbo.[#HR_tblDSNV_PQ_E]
	EXEC	HR_spGetEmpList_EmpHeaderSearch 
			@LanguageID  = @LanguageID,
			@UserGroupID = @UserGroupID,
			@FunctionID  = @FunctionID,

			@EmpCode			= @EmpCode,		@EmpName			= @EmpName,
			@LSCompanyID		= @LSCompanyID,		@LSLevel1ID			= @LSLevel1ID,	
			@LSLevel2ID			= @LSLevel2ID,		@LSLevel3ID			= @LSLevel3ID,	
			@LSLevel4ID			= @LSLevel4ID,		@LSLevel5ID			= @LSLevel5ID,	
			@LSLevel6ID			= @LSLevel6ID,		@LSLevel7ID			= @LSLevel7ID,	
			@LSLevel8ID			= @LSLevel8ID,		@LSLevel9ID			= @LSLevel9ID,	
			@LSHLevel1ID		= @LSHLevel1ID,		@LSHLevel2ID		= @LSHLevel2ID,
			@LSHLevel3ID		= @LSHLevel3ID,		@LSHLevel4ID		= @LSHLevel4ID,
			@LSHLevel5ID		= @LSHLevel5ID,		@LSHLevel6ID		= @LSHLevel6ID,
			@LSLoaiHinhNhanVienID = @LSLoaiHinhNhanVienID,	@Status		= @Status,
			@LSLocationID		= @LSLocationID,	@LSJobTitleID		= @LSJobTitleID,

			@EHDS_LSLoaiNhanVienID		= @EHDS_LSLoaiNhanVienID,
			@EHDS_LSNhomNhanVienID		= @EHDS_LSNhomNhanVienID,
			@EHDS_LSCapBacNhanVienID	= @EHDS_LSCapBacNhanVienID,
			@EHDS_LSContractTypeID		= @EHDS_LSContractTypeID,
			@EHDS_LSStatusChangeID		= @EHDS_LSStatusChangeID,
			@EHDS_UserGroupID			= @EHDS_UserGroupID,
			@EHDS_Email					= @EHDS_Email,
			@EHDS_HRCode				= @EHDS_HRCode,
			@EHDS_IDNo					= @EHDS_IDNo,
			@EHDS_MaSoThue				= @EHDS_MaSoThue,
			@EHDS_AccountNo				= @EHDS_AccountNo,
			@EHDS_MaTheChamCong			= @EHDS_MaTheChamCong,
			@EHDS_EmpCodeOld			= @EHDS_EmpCodeOld,
			
			@IsPermission				= 1,		@IsPermission_TheoThoiGian	= 0,
			@IsPermission_NonEmp		= 0,		@IsDSNV_TheoThoiGian		= 1,
			@IsStatus_TheoThoiGian		= 0,		@dToDate					= @dToDate

	IF OBJECT_ID('tempdb..#HR_tblDSNV_Group') IS NOT NULL
		DROP TABLE [#HR_tblDSNV_Group]
	CREATE TABLE [#HR_tblDSNV_Group] (EmpID INT, ContractID INT, LSLoaiNhanVienCode NVARCHAR(50), LSContractTypeCode NVARCHAR(50), LSLevel1ID INT, Gender INT, LSLocationID INT, IsEnd BIT DEFAULT 0)
	
	CREATE INDEX [IX_#HR_tblDSNV_Group_EmpID] ON [dbo].[#HR_tblDSNV_Group] (EmpID)
	CREATE INDEX [IX_#HR_tblDSNV_Group_LSLoaiNhanVienCode] ON [dbo].[#HR_tblDSNV_Group] (LSLoaiNhanVienCode)
	CREATE INDEX [IX_#HR_tblDSNV_Group_LSLevel1ID] ON [dbo].[#HR_tblDSNV_Group] ([LSLevel1ID])
	CREATE INDEX [IX_#HR_tblDSNV_Group_LSLocationID] ON [dbo].[#HR_tblDSNV_Group] ([LSLocationID])
	CREATE INDEX [IX_#HR_tblDSNV_Group_LSContractTypeCode] ON [dbo].[#HR_tblDSNV_Group] (LSContractTypeCode)
	CREATE INDEX [IX_#HR_tblDSNV_Group_ContractID] ON [dbo].[#HR_tblDSNV_Group] (ContractID)

	/* DSNV đầu kỳ */
	INSERT INTO #HR_tblDSNV_Group (EmpID, ContractID, LSLoaiNhanVienCode, LSContractTypeCode , LSLevel1ID, Gender, LSLocationID)
	SELECT	A.EmpID, C.ContractID, B.LSLoaiNhanVienCode, D.LSContractTypeCode, A.LSLevel1ID, A.Gender, A.LSLocationID
	FROM	dbo.HR_fnEmp(@dFromDate) A
			INNER JOIN #HR_tblDSNV_PQ (NOLOCK) PQ ON PQ.EmpID = A.EmpID
			LEFT JOIN dbo.HR_tblContract (NOLOCK) C ON C.EmpID = A.EmpID AND C.EffectiveDate = A.ContractFromDate
			LEFT JOIN dbo.LS_tblLoaiNhanVien (NOLOCK) B ON B.LSLoaiNhanVienID = A.LSLoaiNhanVienID
			LEFT JOIN dbo.LS_tblContractType (NOLOCK) D ON D.LSContractTypeID = A.LSContractTypeID
	--WHERE	A.LSLocationID IS NOT NULL
	--		AND A.LSLoaiNhanVienID IS NOT NULL

	/* DSNV cuối kỳ */
	INSERT INTO #HR_tblDSNV_Group (EmpID, ContractID, LSLoaiNhanVienCode, LSContractTypeCode , LSLevel1ID, Gender, LSLocationID, IsEnd)
	SELECT	A.EmpID, C.ContractID, B.LSLoaiNhanVienCode, D.LSContractTypeCode, A.LSLevel1ID, A.Gender, A.LSLocationID, 1
	FROM	dbo.HR_fnEmp(@dToDate) A
			INNER JOIN #HR_tblDSNV_PQ_E (NOLOCK) PQ ON PQ.EmpID = A.EmpID
			LEFT JOIN dbo.HR_tblContract (NOLOCK) C ON C.EmpID = A.EmpID AND C.EffectiveDate = A.ContractFromDate
			LEFT JOIN dbo.LS_tblLoaiNhanVien (NOLOCK) B ON B.LSLoaiNhanVienID = A.LSLoaiNhanVienID
			LEFT JOIN dbo.LS_tblContractType (NOLOCK) D ON D.LSContractTypeID = A.LSContractTypeID
	--WHERE	A.LSLocationID IS NOT NULL
	--		AND A.LSLoaiNhanVienID IS NOT NULL

	IF @Activity = 'GetDataExport'
	BEGIN
		SELECT	CASE @LanguageID WHEN 'VN' THEN B.VNName ELSE B.[Name] END LSOfficeTypeName,
				CASE @LanguageID WHEN 'VN' THEN C.VNName ELSE C.[Name] END LSLevel1Name,
				/* FromDate */
				A.S_TS,
				(A.S_NVCT_M + A.S_NVCT_F) S_NVCT,
				A.S_NVCT_M,
				A.S_NVCT_F,
				(A.S_NVTVU_M + A.S_NVTVU_F) S_NVTVU,
				A.S_NVTVU_M,
				A.S_NVTVU_F,
				(A.S_NVCT_M + A.S_NVTVU_M) S_M,
				(A.S_NVCT_F + A.S_NVTVU_F) S_F,
				/* ToDate */
				A.E_TS,
				(A.E_NVCT_M + A.E_NVCT_F) E_NVCT,
				A.E_NVCT_M,
				A.E_NVCT_F,
				(A.E_NVTVU_M + A.E_NVTVU_F) E_NVTVU,
				A.E_NVTVU_M,
				A.E_NVTVU_F,
				(A.E_NVCT_M + A.E_NVTVU_M) S_M,
				(A.E_NVCT_F + A.E_NVTVU_F) S_F
		FROM	(
					SELECT	A.LSOfficeTypeID, D.LSLevel1ID,
							SUM(CASE WHEN C.IsEnd = 0 THEN 1 ELSE 0 END) S_TS,
							SUM(CASE WHEN C.IsEnd = 0 AND C.LSLoaiNhanVienCode IN ('NVCT', 'NVTVI') AND C.Gender = 1 THEN 1 ELSE 0 END)		S_NVCT_M,
							SUM(CASE WHEN C.IsEnd = 0 AND C.LSLoaiNhanVienCode IN ('NVCT', 'NVTVI') AND C.Gender = 0 THEN 1 ELSE 0 END)		S_NVCT_F,
							SUM(CASE WHEN C.IsEnd = 0 AND C.LSLoaiNhanVienCode = 'NVTVU' AND C.Gender = 1 THEN 1 ELSE 0 END)	S_NVTVU_M,
							SUM(CASE WHEN C.IsEnd = 0 AND C.LSLoaiNhanVienCode = 'NVTVU' AND C.Gender = 0 THEN 1 ELSE 0 END)	S_NVTVU_F,
							SUM(CASE WHEN C.IsEnd = 1 THEN 1 ELSE 0 END) E_TS,
							SUM(CASE WHEN C.IsEnd = 1 AND C.LSLoaiNhanVienCode IN ('NVCT', 'NVTVI') AND C.Gender = 1 THEN 1 ELSE 0 END)		E_NVCT_M,
							SUM(CASE WHEN C.IsEnd = 1 AND C.LSLoaiNhanVienCode IN ('NVCT', 'NVTVI') AND C.Gender = 0 THEN 1 ELSE 0 END)		E_NVCT_F,
							SUM(CASE WHEN C.IsEnd = 1 AND C.LSLoaiNhanVienCode = 'NVTVU' AND C.Gender = 1 THEN 1 ELSE 0 END)	E_NVTVU_M,
							SUM(CASE WHEN C.IsEnd = 1 AND C.LSLoaiNhanVienCode = 'NVTVU' AND C.Gender = 0 THEN 1 ELSE 0 END)	E_NVTVU_F
 					FROM	dbo.LS_tblOfficeType (NOLOCK) A
							INNER JOIN dbo.LS_tblLocation (NOLOCK) B ON B.OfficeTypeID = A.LSOfficeTypeID
							INNER JOIN #HR_tblDSNV_Group (NOLOCK) C ON C.LSLocationID = B.LSLocationID
							LEFT JOIN dbo.LS_tblLevel1 (NOLOCK) D ON D.LSLevel1ID = C.LSLevel1ID
					WHERE	A.Used = 1
							AND B.Used = 1
							AND C.LSLoaiNhanVienCode IN ('NVCT', 'NVTVU', 'NVTVI')
					GROUP BY
							A.LSOfficeTypeID, D.LSLevel1ID
				) A
				LEFT JOIN dbo.LS_tblOfficeType (NOLOCK) B ON B.LSOfficeTypeID = A.LSOfficeTypeID
				LEFT JOIN dbo.LS_tblLevel1 (NOLOCK) C ON C.LSLevel1ID = A.LSLevel1ID
		ORDER BY
				ISNULL(B.[Rank], 999),
				ISNULL(C.[Rank], 999)

		SELECT	ISNULL(S_M, 0) S_M,
				ISNULL(S_F, 0) S_F,
				(ISNULL(S_M, 0) + ISNULL(S_F, 0)) S_TT,
				ISNULL(E_M, 0) E_M,
				ISNULL(E_F, 0) E_F,
				(ISNULL(E_M, 0) + ISNULL(E_F, 0)) E_TT
			FROM	(
						SELECT	SUM(CASE WHEN A.IsEnd = 0 AND A.Gender = 1 THEN 1 ELSE 0 END) S_M,
								SUM(CASE WHEN A.IsEnd = 0 AND A.Gender = 0 THEN 1 ELSE 0 END) S_F,
								SUM(CASE WHEN A.IsEnd = 1 AND A.Gender = 1 THEN 1 ELSE 0 END) E_M,
								SUM(CASE WHEN A.IsEnd = 1 AND A.Gender = 0 THEN 1 ELSE 0 END) E_F,
								1 [Rank]
						FROM	#HR_tblDSNV_Group (NOLOCK) A
						WHERE	A.LSContractTypeCode = 'HDKXDTH'
						UNION ALL
						SELECT	B.S_M,
								B.S_F,
								B.E_M,
								B.E_F,
								2 [Rank]
						FROM	(SELECT 1 Dummy) A
								LEFT JOIN 
								(
									SELECT	SUM(CASE WHEN A.IsEnd = 0 AND A.Gender = 1 THEN 1 ELSE 0 END) S_M,
											SUM(CASE WHEN A.IsEnd = 0 AND A.Gender = 0 THEN 1 ELSE 0 END) S_F,
											SUM(CASE WHEN A.IsEnd = 1 AND A.Gender = 1 THEN 1 ELSE 0 END) E_M,
											SUM(CASE WHEN A.IsEnd = 1 AND A.Gender = 0 THEN 1 ELSE 0 END) E_F
									FROM	#HR_tblDSNV_Group (NOLOCK) A
											LEFT JOIN 
											(
												SELECT	DISTINCT AA.EmpID, AA.IsEnd
												FROM	#HR_tblDSNV_Group (NOLOCK) AA
												WHERE	AA.LSContractTypeCode IN ('HD03', 'HD04', 'HD05')
												GROUP BY
														AA.EmpID, AA.IsEnd
												HAVING	COUNT(AA.ContractID) = 1
											) B ON A.EmpID = B.EmpID AND B.IsEnd = A.IsEnd
									WHERE	B.EmpID IS NOT NULL
								) B ON 1 = 1
						UNION ALL
						SELECT	B.S_M,
								B.S_F,
								B.E_M,
								B.E_F,
								3 [Rank]
						FROM	(SELECT 1 Dummy) A
								LEFT JOIN 
								(
									SELECT	SUM(CASE WHEN A.IsEnd = 0 AND A.Gender = 1 THEN 1 ELSE 0 END) S_M,
											SUM(CASE WHEN A.IsEnd = 0 AND A.Gender = 0 THEN 1 ELSE 0 END) S_F,
											SUM(CASE WHEN A.IsEnd = 1 AND A.Gender = 1 THEN 1 ELSE 0 END) E_M,
											SUM(CASE WHEN A.IsEnd = 1 AND A.Gender = 0 THEN 1 ELSE 0 END) E_F
									FROM	#HR_tblDSNV_Group (NOLOCK) A
											LEFT JOIN 
											(
												SELECT	DISTINCT AA.EmpID, AA.IsEnd
												FROM	#HR_tblDSNV_Group (NOLOCK) AA
												WHERE	AA.LSContractTypeCode IN ('HD03', 'HD04', 'HD05')
												GROUP BY
														AA.EmpID, AA.IsEnd
												HAVING	COUNT(AA.ContractID) = 2
											) B ON A.EmpID = B.EmpID AND B.IsEnd = A.IsEnd
									WHERE	B.EmpID IS NOT NULL
								) B ON 1 = 1
						UNION ALL
						SELECT	SUM(CASE WHEN A.IsEnd = 0 AND A.Gender = 1 THEN 1 ELSE 0 END) S_M,
								SUM(CASE WHEN A.IsEnd = 0 AND A.Gender = 0 THEN 1 ELSE 0 END) S_F,
								SUM(CASE WHEN A.IsEnd = 1 AND A.Gender = 1 THEN 1 ELSE 0 END) E_M,
								SUM(CASE WHEN A.IsEnd = 1 AND A.Gender = 0 THEN 1 ELSE 0 END) E_F,
								4 [Rank]
						FROM	#HR_tblDSNV_Group (NOLOCK) A
								LEFT JOIN 
								(
									SELECT DISTINCT G.EmpID, G.IsEnd
									FROM	#HR_tblDSNV_Group (NOLOCK) G
											JOIN dbo.HR_tblContract (NOLOCK) B ON B.EmpID = G.EmpID
											JOIN dbo.LS_tblContractType (NOLOCK) C ON C.LSContractTypeID = B.LSContractTypeID
									WHERE	C.LSContractTypeCode = 'HDLDCT'
										AND DATEDIFF(MONTH, B.EffectiveDate, ISNULL(B.ToDate, @dToDate)) BETWEEN 5 AND 7
										AND (
												(G.IsEnd = 0 AND @dFromDate BETWEEN B.EffectiveDate AND ISNULL(B.ToDate, '9999-12-31'))
												OR (G.IsEnd = 1 AND @dToDate BETWEEN B.EffectiveDate AND ISNULL(B.ToDate, '9999-12-31'))
										)
								) B ON A.EmpID = B.EmpID AND A.IsEnd = B.IsEnd
						WHERE	B.EmpID IS NOT NULL
						UNION ALL
						SELECT	SUM(CASE WHEN A.IsEnd = 0 AND A.Gender = 1 THEN 1 ELSE 0 END) S_M,
								SUM(CASE WHEN A.IsEnd = 0 AND A.Gender = 0 THEN 1 ELSE 0 END) S_F,
								SUM(CASE WHEN A.IsEnd = 1 AND A.Gender = 1 THEN 1 ELSE 0 END) E_M,
								SUM(CASE WHEN A.IsEnd = 1 AND A.Gender = 0 THEN 1 ELSE 0 END) E_F,
								5 [Rank]
						FROM	#HR_tblDSNV_Group (NOLOCK) A
								LEFT JOIN 
								(
									SELECT DISTINCT G.EmpID, G.IsEnd
									FROM	#HR_tblDSNV_Group (NOLOCK) G
											JOIN dbo.HR_tblContract (NOLOCK) B ON B.EmpID = G.EmpID
											JOIN dbo.LS_tblContractType (NOLOCK) C ON C.LSContractTypeID = B.LSContractTypeID
									WHERE	C.LSContractTypeCode = 'HDLDCT'
										AND DATEDIFF(MONTH, B.EffectiveDate, ISNULL(B.ToDate, @dToDate)) >= 11
										AND (
												(G.IsEnd = 0 AND @dFromDate BETWEEN B.EffectiveDate AND ISNULL(B.ToDate, '9999-12-31'))
												OR (G.IsEnd = 1 AND @dToDate BETWEEN B.EffectiveDate AND ISNULL(B.ToDate, '9999-12-31'))
										)
								) B ON A.EmpID = B.EmpID AND A.IsEnd = B.IsEnd
						WHERE	B.EmpID IS NOT NULL
						UNION ALL
						SELECT	SUM(CASE WHEN A.IsEnd = 0 AND A.Gender = 1 THEN 1 ELSE 0 END) S_M,
								SUM(CASE WHEN A.IsEnd = 0 AND A.Gender = 0 THEN 1 ELSE 0 END) S_F,
								SUM(CASE WHEN A.IsEnd = 1 AND A.Gender = 1 THEN 1 ELSE 0 END) E_M,
								SUM(CASE WHEN A.IsEnd = 1 AND A.Gender = 0 THEN 1 ELSE 0 END) E_F,
								8 [Rank]
						FROM	#HR_tblDSNV_Group (NOLOCK) A
								LEFT JOIN dbo.HR_tblContract (NOLOCK) B ON B.ContractID = A.ContractID
								LEFT JOIN dbo.LS_tblContractType (NOLOCK) C ON C.LSContractTypeID = B.LSContractTypeID
								LEFT JOIN dbo.LS_tblContractTypeGroup (NOLOCK) D ON D.ContractTypeGroupID = C.[Type]
						WHERE	D.LSContractTypeGroupCode = 'NHD03'
						UNION ALL
						SELECT	SUM(CASE WHEN A.IsEnd = 0 AND A.Gender = 1 THEN 1 ELSE 0 END) S_M,
								SUM(CASE WHEN A.IsEnd = 0 AND A.Gender = 0 THEN 1 ELSE 0 END) S_F,
								SUM(CASE WHEN A.IsEnd = 1 AND A.Gender = 1 THEN 1 ELSE 0 END) E_M,
								SUM(CASE WHEN A.IsEnd = 1 AND A.Gender = 0 THEN 1 ELSE 0 END) E_F,
								9 [Rank]
						FROM	#HR_tblDSNV_Group (NOLOCK) A
						WHERE	A.LSContractTypeCode = 'HDTV'
						UNION ALL
						SELECT	SUM(CASE WHEN A.IsEnd = 0 AND A.Gender = 1 THEN 1 ELSE 0 END) S_M,
								SUM(CASE WHEN A.IsEnd = 0 AND A.Gender = 0 THEN 1 ELSE 0 END) S_F,
								SUM(CASE WHEN A.IsEnd = 1 AND A.Gender = 1 THEN 1 ELSE 0 END) E_M,
								SUM(CASE WHEN A.IsEnd = 1 AND A.Gender = 0 THEN 1 ELSE 0 END) E_F,
								10 [Rank]
						FROM	#HR_tblDSNV_Group (NOLOCK) A
						WHERE	A.LSContractTypeCode = 'HD12'
						UNION ALL
						SELECT	SUM(CASE WHEN A.IsEnd = 0 AND A.Gender = 1 THEN 1 ELSE 0 END) S_M,
								SUM(CASE WHEN A.IsEnd = 0 AND A.Gender = 0 THEN 1 ELSE 0 END) S_F,
								SUM(CASE WHEN A.IsEnd = 1 AND A.Gender = 1 THEN 1 ELSE 0 END) E_M,
								SUM(CASE WHEN A.IsEnd = 1 AND A.Gender = 0 THEN 1 ELSE 0 END) E_F,
								11 [Rank]
						FROM	#HR_tblDSNV_Group (NOLOCK) A
						WHERE	A.LSContractTypeCode = 'HD11'
						UNION ALL
						SELECT	SUM(CASE WHEN A.IsEnd = 0 AND A.Gender = 1 THEN 1 ELSE 0 END) S_M,
								SUM(CASE WHEN A.IsEnd = 0 AND A.Gender = 0 THEN 1 ELSE 0 END) S_F,
								SUM(CASE WHEN A.IsEnd = 1 AND A.Gender = 1 THEN 1 ELSE 0 END) E_M,
								SUM(CASE WHEN A.IsEnd = 1 AND A.Gender = 0 THEN 1 ELSE 0 END) E_F,
								12 [Rank]
						FROM	#HR_tblDSNV_Group (NOLOCK) A
						WHERE	A.LSContractTypeCode = 'HD10'
					) A
			ORDER BY
					A.[Rank]
		END
	END
