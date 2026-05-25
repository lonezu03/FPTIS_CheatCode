USE [iHRP_V34_PMC]
GO
/****** Object:  StoredProcedure [dbo].[PR_spfrmTongHopPhanBoChiPhiTheoCostCenter_CustomerID163_Create]    Script Date: 5/19/2026 4:29:05 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[PR_spfrmTongHopPhanBoChiPhiTheoCostCenter_CustomerID163_Create]
	@Activity			varchar(50) = '',
	@UserGroupID		nvarchar(50)=null,
	@FunctionID			NVARCHAR(50) = NULL,
	@LanguageID 		nvarchar(2)='VN',
	@ReturnMess			nvarchar(max) = null 	OUTPUT,
	@ReturnMessCode		nvarchar(2) = null 	OUTPUT,
	----------------------------------
	@PRMonth			NVARCHAR(7) = NULL,
	@LSCostCenterID		NVARCHAR(12) = NULL,
	@TinhTrang			NVARCHAR(2) = NULL,
	@strLoaiNhanVien	nvarchar(4000)=null
AS
	DECLARE @strSQL	NVARCHAR(MAX)
BEGIN
	IF (@Activity = 'Create')
	BEGIN
		IF object_id('tempdb..#PR_spfrmTongHopPhanBoChiPhiTheoCostCenter_CustomerID163_Create_EmpList')is not null
			DROP table [dbo].[#PR_spfrmTongHopPhanBoChiPhiTheoCostCenter_CustomerID163_Create_EmpList]
		IF object_id('tempdb..#PR_spfrmTongHopPhanBoChiPhiTheoCostCenter_CustomerID163_Create_EmpList_NotLockPR')is not null
			DROP table [dbo].[#PR_spfrmTongHopPhanBoChiPhiTheoCostCenter_CustomerID163_Create_EmpList_NotLockPR]
		IF object_id('tempdb..#PR_spfrmTongHopPhanBoChiPhiTheoCostCenter_CustomerID163_Create_PR')is not null
			DROP table [dbo].[#PR_spfrmTongHopPhanBoChiPhiTheoCostCenter_CustomerID163_Create_PR]
		IF object_id('tempdb..#PR_spfrmTongHopPhanBoChiPhiTheoCostCenter_CustomerID163_Create')is not null
			DROP table [dbo].[#PR_spfrmTongHopPhanBoChiPhiTheoCostCenter_CustomerID163_Create]

		CREATE TABLE [#PR_spfrmTongHopPhanBoChiPhiTheoCostCenter_CustomerID163_Create_EmpList](EmpID	INT)
		CREATE TABLE [#PR_spfrmTongHopPhanBoChiPhiTheoCostCenter_CustomerID163_Create_EmpList_NotLockPR](EmpID	INT)
		
	CREATE TABLE [#PR_spfrmTongHopPhanBoChiPhiTheoCostCenter_CustomerID163_Create_PR](
			EmpID								INT,
			PRMonth								NVARCHAR(7),
			LSCostCenterID						NVARCHAR(12),
			TK_Costcenter						NVARCHAR(150),
			TT_TienCom							MONEY,
			TT_TienXangThang					MONEY,
			Add52_3								MONEY,
			Add15_3								MONEY,
			Add53_3								MONEY,
			Add39_3								MONEY,
			Add54_3								MONEY,
			Add55_3								MONEY,
			SIEmp								MONEY,
			HIEmp								MONEY,
			UIEmp								MONEY,
			TT_DoanPhi							MONEY,
			TaxLiability						MONEY,
			HT_TroCapThoiViec					MONEY,
			HT_TroCapThoiViec_2					MONEY,
			HT_TruyThuTheBHYT					MONEY,
			SICom								MONEY,
			TT_BHTN_BNN							MONEY,
			HICom								MONEY,
			UICom								MONEY,
			TT_KinhPhiCongDoan					MONEY,
			/*TriTV 11-12-2025 RLog 24957*/
			TT_BHXHEE							MONEY,
			TT_BHYTEE							MONEY,
			TT_BHTNEE							MONEY,
			TT_BHXHER							MONEY,
			TT_BHYTER							MONEY,
			TT_BHTNER							MONEY,
			TT_BHYTNVBoSung  					MONEY,
			HT_BHXHNVBoSung						MONEY,
			HT_BHTNNVBoSung						MONEY,
			TT_DoanPhi_DC						MONEY,
			HT_BHYTCTyBoSung					MONEY,
			HT_BHXHCTyBoSung					MONEY,
			HT_BHTNCTyBoSung					MONEY,
			TT_KinhPhiCongDoan_DC				MONEY
			/*End TriTV 11-12-2025 RLog 24957*/
		)
		
		CREATE TABLE [#PR_spfrmTongHopPhanBoChiPhiTheoCostCenter_CustomerID163_Create](
			PRMonth							NVARCHAR(7),
			LSCostCenterID					NVARCHAR(12),
			CostCenter						NVARCHAR(150),
			TT_TienCom						MONEY,
			TT_TienXangThang				MONEY,
			Add52_3							MONEY,
			Add15_3							MONEY,
			Add53_3							MONEY,
			Add39_3							MONEY,
			Add54_3							MONEY,
			Add55_3							MONEY,
			SIEmp							MONEY,
			HIEmp							MONEY,
			UIEmp							MONEY,
			TT_DoanPhi						MONEY,
			TaxLiability					MONEY,
			HT_TroCapThoiViec				MONEY,
			HT_TroCapThoiViec_2				MONEY,
			HT_TruyThuTheBHYT				MONEY,
			SICom							MONEY,
			TT_BHTN_BNN						MONEY,
			HICom							MONEY,
			UICom							MONEY,
			TT_KinhPhiCongDoan				MONEY,
			/*TriTV 11-12-2025 RLog 24957*/
			BHYT_NVDC							MONEY,
			BHXH_NVDC							MONEY,
			BHTN_NVDC							MONEY,
			DoanPhi_NVDC						MONEY,
			BHYT_CTDC							MONEY,
			BHXH_CTDC							MONEY,
			BHTN_CTDC							MONEY,
			DoanPhi_CTDC						MONEY
			/*End TriTV 11-12-2025 RLog 24957*/
		)

      --+ Cost Center: TK_Costcenter (**)
      --+ Phụ cấp – Cơm trưa = TT_TienCom
      --+ Phụ cấp – Xăng = TT_TienXangThang
      --+ Phụ cấp – Công tác phí = Add52_3
      --+ Phụ cấp – Điện thoại = Add15_3
      --+ Phụ cấp – Bảo dưỡng xe = Add53_3
      --+ Phụ cấp – Gửi xe = Add39_3
      --+ Phụ cấp – Khoán ngoài giờ = Add54_3
      --+ Phụ cấp – An toàn vệ sinh = Add55_3
      --+ BHXH – Nhân viên = SIEmp
      --+ BHYT – Nhân viên = HIEmp
      --+ BHTN – Nhân viên = UIEmp
      --+ Đoàn phí – Nhân viên = TT_DoanPhi
      --+ Thuế TNCN phải nộp = TaxLiability
      --+ Trợ cấp thôi việc – trước 2008 = HT_TroCapThoiViec
      --+ Trợ cấp thôi việc – sau 2008 = HT_TroCapThoiViec_2
      --+ BHXH – Công ty = SICom
      --+ BHTNLĐ-BNN – Công ty = TT_BHTN_BNN
      --+ BHYT – Công ty = HICom
      --+ BHTN – Công ty = UICom
      --+ Đoàn phí – Công ty = TT_KinhPhiCongDoan



		IF object_id('PR_vPayroll_' + REPLACE(@PRMonth,'/','') ) is not null
        BEGIN
			
			SET @strSQL = N'
			INSERT INTO [#PR_spfrmTongHopPhanBoChiPhiTheoCostCenter_CustomerID163_Create_EmpList_NotLockPR](EmpID)
			SELECT PR.EmpID
			FROM PR_vPayroll_' + REPLACE(@PRMonth,'/','') + N' (NOLOCK) PR
			LEFT JOIN dbo.PR_tblLockPayrollEmp (NOLOCK) LPR ON LPR.EmpID = PR.EmpID AND LPR.Month = PR.PRMonth
			LEFT JOIN HR_vemp (NOLOCK) vE ON vE.EmpID = PR.EmpID
			LEFT JOIN LS_tblloainhanvien (NOLOCK) L ON L.LSLoaiNhanVienID = vE.LSLoaiNhanVienID
			WHERE L.LSLoaiNhanVienCode IN (''NVCT'',''NVTVI'') AND (LPR.IsLock IS NULL OR LPR.IsLock = 0)
			And ('''+isnull(@strLoaiNhanVien,'')+'''='''' or '''+isnull('@'+@strLoaiNhanVien,'')+''' like N''%@''+Convert(varchar(12), vE.LSLoaiNhanVienID)+''@%'')
			'
			PRINT (@strSQL)
			EXEC (@strSQL)

			IF EXISTS (SELECT TOP 1 1 FROM [#PR_spfrmTongHopPhanBoChiPhiTheoCostCenter_CustomerID163_Create_EmpList_NotLockPR] (NOLOCK)) and 1=2
			BEGIN
				SET @ReturnMess = dbo.SYS_fnGetMess('PR_075', @LanguageID)
				SET @ReturnMessCode = '0'
				RETURN
			END

			SET @strSQL = N'
			INSERT INTO [#PR_spfrmTongHopPhanBoChiPhiTheoCostCenter_CustomerID163_Create_EmpList](EmpID)
			SELECT PR.EmpID
			FROM dbo.PR_vPayroll_' + REPLACE(@PRMonth,'/','') + N' (NOLOCK) PR
			INNER JOIN dbo.PR_tblLockPayrollEmp (NOLOCK) LPR ON LPR.EmpID = PR.EmpID AND LPR.Month = PR.PRMonth AND LPR.IsLock = 1
			LEFT JOIN HR_vemp (NOLOCK) vE ON vE.EmpID = PR.EmpID
			LEFT JOIN LS_tblloainhanvien (NOLOCK) L ON L.LSLoaiNhanVienID = vE.LSLoaiNhanVienID
			WHERE L.LSLoaiNhanVienCode IN (''NVCT'',''NVTVI'')
			And ('''+isnull(@strLoaiNhanVien,'')+'''='''' or '''+isnull('@'+@strLoaiNhanVien,'')+''' like N''%@''+Convert(varchar(12), vE.LSLoaiNhanVienID)+''@%'')

			INSERT INTO [#PR_spfrmTongHopPhanBoChiPhiTheoCostCenter_CustomerID163_Create_PR]
			(
				EmpID
				,PRMonth				
				,TK_Costcenter
				,TT_TienCom			
				,TT_TienXangThang	
				,Add52_3				
				,Add15_3				
				,Add53_3				
				,Add39_3				
				,Add54_3				
				,Add55_3				
				,SIEmp				
				,HIEmp				
				,UIEmp				
				,TT_DoanPhi			
				,TaxLiability		
				,HT_TroCapThoiViec	
				,HT_TroCapThoiViec_2	
				,HT_TruyThuTheBHYT
				,SICom				
				,TT_BHTN_BNN			
				,HICom				
				,UICom				
				,TT_KinhPhiCongDoan,
				/*TriTV 11-12-2025 RLog 24957*/
				TT_BHXHEE, TT_BHYTEE, TT_BHTNEE, TT_BHXHER, TT_BHYTER, TT_BHTNER, 
				TT_BHYTNVBoSung, HT_BHXHNVBoSung, HT_BHTNNVBoSung, TT_DoanPhi_DC, HT_BHYTCTyBoSung, HT_BHXHCTyBoSung, HT_BHTNCTyBoSung, TT_KinhPhiCongDoan_DC
				/*End TriTV 11-12-2025 RLog 24957*/
			)
			'
			SET @strSQL +=
			N'SELECT PR.EmpID, PR.PRMonth
				, PRT.TK_Costcenter
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(PR.TT_TongTienCom)),0) + ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(C.Add76_3)),0)
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(PR.TT_TienXangThang)),0)
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(c.Add52_3)),0)
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(c.Add15_3)),0)
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(c.Add53_3)),0)
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(PR.TT_TienGuiXe)),0)
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(c.Add54_3)),0)
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(c.Add55_3)),0)
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(PR.SIEmp	)),0)
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(PR.HIEmp	)),0)
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(PR.UIEmp)),0)
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(PR.TT_DoanPhi)),0)			
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(PR.TaxLiability)),0)		
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(PR.HT_TroCapThoiViec)),0)	
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(PR.HT_TroCapThoiViec_2)),0)
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(PR.HT_TruyThuTheBHYT)),0)
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(PR.SICom)),0)				
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(PR.TT_BHTN_BNN)),0)		
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(PR.HICom)),0)				
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(PR.UICom)),0)				
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(PR.TT_KinhPhiCongDoan)),0)	
				/*TriTV 11-12-2025 RLog 24957*/
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(PR.TT_BHXHEE)),0)	
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(PR.TT_BHYTEE)),0)	
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(PR.TT_BHTNEE)),0)	
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(PR.TT_BHXHER)),0)	
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(PR.TT_BHYTER)),0)
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(PR.TT_BHTNER)),0)
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(PR.HT_BHYTNVBoSung)),0)
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(PR.HT_BHXHNVBoSung)),0)
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(PR.HT_BHTNNVBoSung)),0)
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(PR.TT_DoanPhi_DC)),0)
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(PR.HT_BHYTCTyBoSung)),0)
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(PR.HT_BHXHCTyBoSung)),0)
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(PR.HT_BHTNCTyBoSung)),0)
				, ISNULL(CONVERT(MONEY, dbo.SYS_fnGetD(PR.TT_KinhPhiCongDoan_DC)),0)
				/*End TriTV 11-12-2025 RLog 24957*/
			FROM dbo.PR_vPayroll_' + REPLACE(@PRMonth,'/','') + N' (NOLOCK) PR
			INNER JOIN [#PR_spfrmTongHopPhanBoChiPhiTheoCostCenter_CustomerID163_Create_EmpList] (NOLOCK) temp on temp.EmpID = PR.EmpID
			LEFT JOIN dbo.PR_vPayrollText_' + REPLACE(@PRMonth,'/','') + N' (NOLOCK) PRT ON PRT.EmpID = PR.EmpID
			LEFT JOIN PR_vAdd_' + replace(@PRMonth, '/', '') + ' (NOLOCK) c on c.EmpID = PR.EmpID
			'
			PRINT (@strSQL) 
			EXEC (@strSQL)
			INSERT INTO [#PR_spfrmTongHopPhanBoChiPhiTheoCostCenter_CustomerID163_Create](
				PRMonth, LSCostCenterID, CostCenter
				,TT_TienCom			
				,TT_TienXangThang	
				,Add52_3				
				,Add15_3				
				,Add53_3				
				,Add39_3				
				,Add54_3				
				,Add55_3				
				,SIEmp				
				,HIEmp				
				,UIEmp				
				,TT_DoanPhi			
				,TaxLiability		
				,HT_TroCapThoiViec	
				,HT_TroCapThoiViec_2	
				,HT_TruyThuTheBHYT
				,SICom				
				,TT_BHTN_BNN			
				,HICom				
				,UICom				
				,TT_KinhPhiCongDoan	
				/*TriTV 11-12-2025 RLog 24957*/
				, BHYT_NVDC, BHXH_NVDC, BHTN_NVDC, DoanPhi_NVDC, BHYT_CTDC, BHXH_CTDC, BHTN_CTDC, DoanPhi_CTDC
				/*End TriTV 11-12-2025 RLog 24957*/
			)
			SELECT @PRMonth AS PRMonth, LSCostCenterID, CostCenter,
			SUM(ISNULL(TT_TienCom,0)),
			SUM(ISNULL(TT_TienXangThang,0)),
			SUM(ISNULL(Add52_3,0)),
			SUM(ISNULL(Add15_3,0)),
			SUM(ISNULL(Add53_3,0)),
			SUM(ISNULL(Add39_3,0)),
			SUM(ISNULL(Add54_3,0)),
			SUM(ISNULL(Add55_3,0)),
			SUM(ISNULL(TT_BHXHEE,0)) AS SIEmp,	/*TriTV 11-12-2025 RLog 24957*//*SUM(ISNULL(SIEmp,0)),*/
			SUM(ISNULL(TT_BHYTEE,0)) AS HIEmp, 	/*TriTV 11-12-2025 RLog 24957*//*SUM(ISNULL(HIEmp,0)),*/
			SUM(ISNULL(TT_BHTNEE,0)) AS UIEmp, 	/*TriTV 11-12-2025 RLog 24957*//*SUM(ISNULL(UIEmp,0)),*/
			SUM(ISNULL(TT_DoanPhi,0)),
			SUM(ISNULL(TaxLiability,0)),
			SUM(ISNULL(HT_TroCapThoiViec,0)),
			SUM(ISNULL(HT_TroCapThoiViec_2,0)),
			SUM(ISNULL(HT_TruyThuTheBHYT,0)),
			SUM(ISNULL(TT_BHXHER,0)) AS SICom,	/*TriTV 11-12-2025 RLog 24957*/ /*SUM(ISNULL(SICom,0)),*/
			SUM(ISNULL(TT_BHTN_BNN,0)),
			SUM(ISNULL(TT_BHYTER,0)) AS HICom,	/*TriTV 11-12-2025 RLog 24957*/ /*SUM(ISNULL(HICom,0)),*/
			SUM(ISNULL(TT_BHTNER,0)) AS UICom,	/*TriTV 11-12-2025 RLog 24957*/ /*SUM(ISNULL(UICom,0)),*/ 
			SUM(ISNULL(TT_KinhPhiCongDoan,0)),
			/*TriTV 11-12-2025 RLog 24957*/
			SUM(ISNULL(TT_BHYTNVBoSung,0)) AS BHYT_NVDC, SUM(ISNULL(HT_BHXHNVBoSung,0)) AS BHXH_NVDC, SUM(ISNULL(HT_BHTNNVBoSung,0)) AS BHTN_NVDC, SUM(ISNULL(TT_DoanPhi_DC,0)) AS DoanPhi_NVDC,
			SUM(ISNULL(HT_BHYTCTyBoSung,0)) AS BHYT_CTDC, SUM(ISNULL(HT_BHXHCTyBoSung,0)) AS BHXH_CTDC, SUM(ISNULL(HT_BHTNCTyBoSung,0)) AS BHTN_CTDC, SUM(ISNULL(TT_KinhPhiCongDoan_DC,0)) AS DoanPhi_CTDC
			/*End TriTV 11-12-2025 RLog 24957*/
			FROM
			(
				SELECT CC.LSCostCenterID, TK_Costcenter AS CostCenter
					,PR.TT_TienCom			
					,PR.TT_TienXangThang	
					,PR.Add52_3				
					,PR.Add15_3				
					,PR.Add53_3				
					,PR.Add39_3				
					,PR.Add54_3				
					,PR.Add55_3				
					,PR.SIEmp				
					,PR.HIEmp				
					,PR.UIEmp				
					,PR.TT_DoanPhi			
					,PR.TaxLiability		
					,PR.HT_TroCapThoiViec	
					,PR.HT_TroCapThoiViec_2	
					,PR.HT_TruyThuTheBHYT
					,PR.SICom				
					,PR.TT_BHTN_BNN			
					,PR.HICom				
					,PR.UICom				
					,PR.TT_KinhPhiCongDoan,
					/*TriTV 11-12-2025 RLog 24957*/
					PR.TT_BHXHEE, PR.TT_BHYTEE, PR.TT_BHTNEE, PR.TT_BHXHER, PR.TT_BHYTER, PR.TT_BHTNER, 
					PR.TT_BHYTNVBoSung, PR.HT_BHXHNVBoSung, PR.HT_BHTNNVBoSung, PR.TT_DoanPhi_DC, PR.HT_BHYTCTyBoSung, PR.HT_BHXHCTyBoSung, PR.HT_BHTNCTyBoSung, PR.TT_KinhPhiCongDoan_DC
					/*End TriTV 11-12-2025 RLog 24957*/
				FROM [#PR_spfrmTongHopPhanBoChiPhiTheoCostCenter_CustomerID163_Create_PR] (NOLOCK) PR
				LEFT JOIN dbo.LS_tblCostCenter (NOLOCK) CC ON CC.LSCostCenterCode = PR.TK_Costcenter
				WHERE (@LSCostCenterID IS NULL OR @LSCostCenterID = '' OR CC.LSCostCenterID = @LSCostCenterID)
			) A
			GROUP BY LSCostCenterID, CostCenter

			--Xoa cac dong chua khoa
			DELETE A
			FROM PR_tblTongHopPhanBoChiPhiTheoCostCenter_CustomerID163 A
			INNER JOIN [#PR_spfrmTongHopPhanBoChiPhiTheoCostCenter_CustomerID163_Create] (NOLOCK) B ON B.PRMonth = A.PRMonth AND B.LSCostCenterID = A.LSCostCenterID AND (A.IsChuyenSAP IS NULL OR A.IsChuyenSAP = 0)

			--Xoa cac dong da khoa
			DELETE A
			FROM [#PR_spfrmTongHopPhanBoChiPhiTheoCostCenter_CustomerID163_Create] A
			INNER JOIN PR_tblTongHopPhanBoChiPhiTheoCostCenter_CustomerID163 (NOLOCK) B ON B.PRMonth = A.PRMonth AND B.LSCostCenterID = A.LSCostCenterID AND B.IsChuyenSAP = 1

			IF NOT EXISTS (SELECT TOP 1 1 FROM [#PR_spfrmTongHopPhanBoChiPhiTheoCostCenter_CustomerID163_Create] (NOLOCK))
			BEGIN
				SET @ReturnMess = dbo.SYS_fnGetMess('0068b', @LanguageID)
				SET @ReturnMessCode = '0'
			END
			ELSE
			BEGIN
				INSERT INTO PR_tblTongHopPhanBoChiPhiTheoCostCenter_CustomerID163(
					
					PRMonth, LSCostCenterID, CostCenter
					,TT_TienCom			
					,TT_TienXangThang	
					,Add52_3				
					,Add15_3				
					,Add53_3				
					,Add39_3				
					,Add54_3				
					,Add55_3				
					,SIEmp				
					,HIEmp				
					,UIEmp				
					,TT_DoanPhi			
					,TaxLiability		
					,HT_TroCapThoiViec	
					,HT_TroCapThoiViec_2	
					,HT_TruyThuTheBHYT
					,SICom				
					,TT_BHTN_BNN			
					,HICom				
					,UICom				
					,TT_KinhPhiCongDoan	
					,BHYT_NVDC, BHXH_NVDC, BHTN_NVDC, DoanPhi_NVDC, BHYT_CTDC, BHXH_CTDC, BHTN_CTDC, DoanPhi_CTDC	/*TriTV 11-12-2025 RLog 24957*/
					,Creater, CreateTime
				)
				SELECT
					PRMonth, LSCostCenterID, CostCenter
					,TT_TienCom			
					,TT_TienXangThang	
					,Add52_3				
					,Add15_3				
					,Add53_3				
					,Add39_3				
					,Add54_3				
					,Add55_3				
					,SIEmp				
					,HIEmp				
					,UIEmp				
					,TT_DoanPhi			
					,TaxLiability		
					,HT_TroCapThoiViec	
					,HT_TroCapThoiViec_2	
					,HT_TruyThuTheBHYT
					,SICom				
					,TT_BHTN_BNN			
					,HICom				
					,UICom				
					,TT_KinhPhiCongDoan	
					,BHYT_NVDC, BHXH_NVDC, BHTN_NVDC, DoanPhi_NVDC, BHYT_CTDC, BHXH_CTDC, BHTN_CTDC, DoanPhi_CTDC	/*TriTV 11-12-2025 RLog 24957*/
					,@UserGroupID, GETDATE()
				FROM [#PR_spfrmTongHopPhanBoChiPhiTheoCostCenter_CustomerID163_Create] (NOLOCK)

				SET @ReturnMess = dbo.SYS_fnGetMess('0046', @LanguageID)
				SET @ReturnMessCode = '1'
			END
        END
	END
END
