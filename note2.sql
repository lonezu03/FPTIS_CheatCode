USE [iHRP_V34_PMC_PRO]
GO
/****** Object:  StoredProcedure [dbo].[HR_spfrmThietLapNguoiKyHD]    Script Date: 4/28/2026 1:16:45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROC [dbo].[HR_spfrmThietLapNguoiKyHD]
@Activity			nvarchar(50) = null,
@LanguageID			nvarchar(2)='VN',
@UserGroupID nvarchar(50)='admin',
@FunctionID			nvarchar(12) =null,

@EmpID int =null,--ngươi ký
@LSCompanyID int =null,
@LSLevel1ID int =null,
@LSLevel2ID int =null,
@LSLevel3ID int =null,
@LSLevel4ID int =null,
@LSLevel5ID int =null,
@LSLevel6ID int =null,
@LSLevel7ID int =null,
@LSLevel8ID int =null,
@LSLevel9ID int =null,
@LSCapBacNhanVienID int = null,
@LSJobTitleID int = null,
@LSLoaiNhanVienID int = null,
@LSLocationID int = null,
@LSChucVuID		int = null,
--man hinh search		
@TuNgay				varchar(12) =null,
@DenNgay			varchar(12) =null,
@dsLoaiHDSearch		varchar(1000) =null,
@TenNguoiKySearch	nvarchar(100) =null,
@ChucDanhSearch		nvarchar(100) =null,

--man hinh Hop dong
@ThietLapID			varchar(12) =null,
@NgayHieuLuc		varchar(12) =null,
@TenNguoiKy			nvarchar(100)=null,
@ChucDanh			nvarchar(100)=null,
@NoiKy				nvarchar(200)=null,
--Thong tin them 1->10
@Other1				nvarchar(255)=null,
@Other2				nvarchar(255)=null,
@Other3				nvarchar(255)=null,
@Other4				nvarchar(255)=null,
@Other5				nvarchar(255)=null,
@Other6				nvarchar(255)=null,
@Other7				nvarchar(255)=null,
@Other8				nvarchar(255)=null,
@Other9				nvarchar(255)=null,
@Other10			nvarchar(255)=null,
----------
@GiayUyQuyen		nvarchar(4000)=null,
@dsLoaiHD			nvarchar(1000)=null,
@dsThietLapID		nvarchar(max)=null,
@LoaiHDID			nvarchar(12)=null,
--delete
@ThietLapChiTietID	nvarchar(12) =null,
@LSNhomNhanVienID int =null,
@AuthorizationDate nvarchar(10) = null, --Rlog 19909 22/09/2023
--retrurn
@ReturnSuccessRows	INT  =0 output,
@ReturnMess			nvarchar(200)=null output,
@ReturnCode			nvarchar(200)=null OUTPUT,
--rlogID:7715
@strLSJobTitleID nvarchar(max) = null,
@strLSChucVuID		nvarchar(max) = null,
@IsDup			int = 0,
/*Start RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
@LSHLevel1ID		INT = NULL,
@LSHLevel2ID		INT = NULL,
@LSHLevel3ID		INT = NULL,
@LSHLevel4ID		INT = NULL,
@LSHLevel5ID		INT = NULL,
@LSHLevel6ID		INT = NULL
/*End   RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
,@LSLoaiHinhNhanVienID	int  =NULL
/*Rlog 20571 THienLK4 - DXG - 21/12/2023*/
,@LSCapBacCongViecNoiBoID INT = NULL
/*Rlog 20571 THienLK4 - DXG - 21/12/2023*/
,@AttachFile varchar(50) = null ---TamnB rlog 20863
/*START Rlog 21420 HaiNT181 26/06/2024*/
,@NguoiKyNhay INT = NULL
,@EmailVanThu VARCHAR(100) = NULL
,@TaiKhoanVanThu VARCHAR(150) = NULL
/*END Rlog 21420 HaiNT181 26/06/2024*/
/*Tamnb rlog 21379*/
,@Reviewer1 nvarchar(100) = null
,@Reviewer2 nvarchar(100) = null
,@Reviewer3 nvarchar(100) = null
,@Reviewer4 nvarchar(100) = null
/*Tamnb rlog 21379*/
,@LSLoaiLaoDongID int = null,
@strLSCapBacNhanVienID nvarchar(max) = null --TanND35 rlogid 23254
AS
Declare @dNgayHieuLuc	datetime
Declare @dTuNgay		datetime
Declare @dDenNgay		datetime
Declare @Current		int
Declare @_EffectiveDate	varchar(12)
DECLARE @LoaiHD			varchar(12)
DECLARE @strSql			nvarchar(4000)
declare @tmp			nvarchar(12)
DECLARE @bAuthorizationDate date = convert(datetime, @AuthorizationDate, 103)
SET @ReturnSuccessRows=0
set @Current=1
set @tmp = ''
SET @dNgayHieuLuc=convert(datetime,@NgayHieuLuc,103)

if @Activity not in ('ValidDuplicate', 'ValidDuplicate_New')
Begin
	select	@LSLevel1ID = case when @LSLevel1ID IS null then null else @LSLevel1ID end,
		@LSCapBacNhanVienID = case when isnull(@LSCapBacNhanVienID,'')='' then null else @LSCapBacNhanVienID end,
		@LSJobTitleID = case when isnull(@LSJobTitleID,'')='' then null else @LSJobTitleID end,
		@LSLoaiNhanVienID = case when isnull(@LSLoaiNhanVienID,'')='' then null else @LSLoaiNhanVienID end,
		@LSLocationID = case when isnull(@LSLocationID,'')='' then null else @LSLocationID end,
		@LSLoaiLaoDongID = case when isnull(@LSLoaiLaoDongID,'')='' then null else @LSLoaiLaoDongID end
End

IF(@Activity= 'GetDataForContractInfo')--Lấy thông tin ký HD theo nhieu loai HD
	BEGIN
		SELECT @LSCompanyID=LSCompanyID, @LSLevel1ID=LSLevel1ID FROM HR_tblEmp(NoLock) WHERE EmpID=@EmpID;

		--Lay data theo CongTy, DonVi va ngay hieu luc sau cung
		Select  TL.ThietLapID, 
				TL.EmpID, 
				TLCT.ThietLapChiTietID,
				TL.LSCompanyID,
				TL.LSLevel1ID, 
				CASE WHEN @LanguageID='EN' THEN CP.[Name] ELSE CP.[VNName] END AS CompanyName,--cty ký
				CASE WHEN @LanguageID='EN' THEN L1.[Name] ELSE L1.[VNName] END AS Level1Name,--Don vi ký
				CONVERT(NVARCHAR,TL.NgayHieuLuc,103) AS NgayHieuLuc,
				V.EmpCode,
				CASE WHEN ISNULL(TL.TenNguoiKy, '') <> '' THEN TL.TenNguoiKy ELSE V.EmpName  END  TenNguoiKy,
				V.JobTitleVN AS ChucDanh,
				TL.NoiKy
				,TL.Other1,TL.Other2,TL.Other3,TL.Other4,TL.Other5,TL.Other6,TL.Other7,TL.Other8,TL.Other9,TL.Other10       
				,TL.GiayUyQuyen,
				TLCT.LoaiHD,
				CASE WHEN @LanguageID='EN' THEN CT.[Name] ELSE CT.[VNName] END AS TenLoaiHD				
				
			FROM
				(select  top 1 ThietLapID, LSCompanyID, LSLevel1ID,EmpID, NgayHieuLuc, NoiKy, GiayUyQuyen
						,Other1,Other2,Other3,Other4,Other5,Other6,Other7,Other8,Other9,Other10, TenNguoiKy       
					from HR_tblThietLapNguoiKyHD (nolock)
					where @LSCompanyID=LSCompanyID
						and (@LSLevel1ID=LSLevel1ID or isnull(LSLevel1ID,'')='')--neu chi thiet lap muc Cong ty
						and ngayhieuluc<=getdate()
					order by NgayHieuLuc desc,LSLevel1ID desc-- Uu tiên nếu thiết cho DonVi (null đứng sau), khi cùng ngày hiệu lực có 2 thiết lập
				) TL
				--left join HR_tblThietLapNguoiKyHD TL on KQ.ThietLapID=TL.ThietLapID
				LEFT JOIN dbo.HR_vEmp (nolock) V ON V.empID=TL.EmpID
				LEFT JOIN HR_tblThietLapNguoiKyHD_ChiTiet (nolock) TLCT ON TL.ThietLapID=TLCT.ThietLapID
				LEFT JOIN dbo.LS_tblCompany  (nolock)CP ON TL.LSCompanyID=CP.LSCompanyID
				LEFT JOIN dbo.LS_tblLevel1 (nolock) L1 ON TL.LSLevel1ID=L1.LSLevel1ID
				LEFT JOIN dbo.LS_tblContractType (nolock) CT ON CT.LSContractTypeID=TLCT.LoaiHD
			ORDER BY TL.LSCompanyID, Tl.LSLevel1ID, NgayHieuLuc DESC, VfirstName, VlastName		
	END
	
IF(@Activity= 'CreateData')--tạo và lưu Data
BEGIN	
	DECLARE @iSuccess INT
	SET @iSuccess	=0 --số dòng insert thành công
	/************************/
	BEGIN				
		/*rlogID:7715*/
		declare @Current1 int
		create table #TempChucDanh_ChucVu_CapBacNhanVien(LSJobTitleID int null, LSChucVuID int null,LSCapBacNhanVienID int null)
		if isnull(@strLSJobTitleID,'')<>'' and isnull(@strLSChucVuID,'')<>'' and isnull(@strLSCapBacNhanVienID,'')<>'' /*if else vì nếu 1 trong 2 bảng không có dòng thì khi cross join sẽ ko ra dữ liệu*/
		Begin
			insert into #TempChucDanh_ChucVu_CapBacNhanVien
			select A.*, B.*,C.*
			from [dbo].[Split](@strLSJobTitleID,'@') A
			cross join [dbo].[Split](@strLSChucVuID,'@') B
			cross join [dbo].[Split](@strLSCapBacNhanVienID,'@') C

		End
		Else if isnull(@strLSJobTitleID,'')<>'' and isnull(@strLSChucVuID,'')='' and isnull(@strLSCapBacNhanVienID,'')=''
		Begin
			insert into #TempChucDanh_ChucVu_CapBacNhanVien
			select A.*,null , null
			from [dbo].[Split](@strLSJobTitleID,'@') A
		End
		Else if isnull(@strLSJobTitleID,'')<>'' and isnull(@strLSChucVuID,'')='' and isnull(@strLSCapBacNhanVienID,'') <> ''
		Begin
			insert into #TempChucDanh_ChucVu_CapBacNhanVien
			select A.*,null ,C.*
			from [dbo].[Split](@strLSJobTitleID,'@') A
			cross join [dbo].[Split](@strLSCapBacNhanVienID,'@') C
		End
		else if isnull(@strLSJobTitleID,'')='' and isnull(@strLSChucVuID,'')<>'' and isnull(@strLSCapBacNhanVienID,'')=''
		Begin
			insert into #TempChucDanh_ChucVu_CapBacNhanVien
			select null,B.*,null
			from [dbo].[Split](@strLSChucVuID,'@') B
		END
		else if isnull(@strLSJobTitleID,'')='' and isnull(@strLSChucVuID,'')<>'' and isnull(@strLSCapBacNhanVienID,'')<>''
		Begin
			insert into #TempChucDanh_ChucVu_CapBacNhanVien
			select null,B.*,C.*
			from [dbo].[Split](@strLSChucVuID,'@') B
			cross join [dbo].[Split](@strLSCapBacNhanVienID,'@') C
		END
		else if isnull(@strLSJobTitleID,'')='' and isnull(@strLSChucVuID,'')='' and isnull(@strLSCapBacNhanVienID,'')<>''
		Begin
			insert into #TempChucDanh_ChucVu_CapBacNhanVien
			select null,null,C.*
			from [dbo].[Split](@strLSCapBacNhanVienID,'@')C
		END
		/***************************/
		
		if not exists (select * from #TempChucDanh_ChucVu_CapBacNhanVien)
		begin
			print 'No'
			set @LSJobTitleID = null
			set @LSChucVuID = null
			/***************/
			if exists (
				Select	distinct Case when @dsLoaiHD <> '' and @dsLoaiHD is not null	then Case when @LanguageID='EN' then CTT.Name else CTT.VNName end 
							when @dsLoaiHD = '' or @dsLoaiHD is null		then Case when @LanguageID='EN' then N'Check contract type' else N'Kiểm tra loại hợp đồng' end 
						end as ContractTypeDup
				from (	Select	isnull(LSCompanyID,-1) LSCompanyID_, isnull(LSLevel1ID,-1) LSLevel1ID_,isnull(LSLevel2ID,-1) LSLevel2ID_,isnull(LSLevel3ID,-1) LSLevel3ID_,isnull(LSLevel4ID,-1) LSLevel4ID_,isnull(LSLevel5ID,-1) LSLevel5ID_,isnull(LSLevel6ID,-1) LSLevel6ID_,isnull(LSLevel7ID,-1) LSLevel7ID_,isnull(LSLevel8ID,-1) LSLevel8ID_,isnull(LSLevel9ID,-1) LSLevel9ID_,
							/*Start RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
							 isnull(LSHLevel1ID,-1) LSHLevel1ID_,isnull(LSHLevel2ID,-1) LSHLevel2ID_,isnull(LSHLevel3ID,-1) LSHLevel3ID_,isnull(LSHLevel4ID,-1) LSHLevel4ID_,isnull(LSHLevel5ID,-1) LSHLevel5ID_,isnull(LSHLevel6ID,-1) LSHLevel6ID_,
							/*End   RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
									isnull(LSCapBacNhanVienID,-1) LSCapBacNhanVienID_,
									isnull(LSJobTitleID,-1) LSJobTitleID_,isnull(LSLoaiNhanVienID,-1) LSLoaiNhanVienID_,isnull(LSLoaiLaoDongID,-1) as LSLoaiLaoDongID_,
									isnull(LSLocationID,-1) LSLocationID_,isnull(LSNhomNhanVienID,-1) as LSNhomNhanVienID_,isnull(LSChucVuID,-1) as LSChucVuID_,
									*
							From HR_tblThietLapNguoiKyHD(NoLock) 
						)NK
				left join HR_tblThietLapNguoiKyHD_Chitiet(NoLock)  CT  on NK.ThietLapID=CT.ThietLapID
				Left join LS_tblContractType(Nolock) CTT on CT.LoaiHD = CTT.LSContractTypeID
				where 1=1
					and (NK.ThietLapID<>@ThietLapID or @ThietLapID = '' or @ThietLapID is null)
					and NgayHieuLuc=@dNgayHieuLuc 
					and (NK.LSCompanyID_=case when @LSCompanyID is null then -1 else @LSCompanyID end) 
					and (NK.LSLevel1ID_=case when @LSLevel1ID is null then -1 else @LSLevel1ID end)  
					and (NK.LSLevel2ID_=case when @LSLevel2ID is null then -1 else @LSLevel2ID end)  
					and (NK.LSLevel3ID_=case when @LSLevel3ID is null then -1 else @LSLevel3ID end)  
					and (NK.LSLevel4ID_=case when @LSLevel4ID is null then -1 else @LSLevel4ID end)  
					and (NK.LSLevel5ID_=case when @LSLevel5ID is null then -1 else @LSLevel5ID end)  
					and (NK.LSLevel6ID_=case when @LSLevel6ID is null then -1 else @LSLevel6ID end)  
					and (NK.LSLevel7ID_=case when @LSLevel7ID is null then -1 else @LSLevel7ID end)  
					and (NK.LSLevel8ID_=case when @LSLevel8ID is null then -1 else @LSLevel8ID end)  
					and (NK.LSLevel9ID_=case when @LSLevel9ID is null then -1 else @LSLevel9ID end)  
					/*Start RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
					and (NK.LSHLevel1ID_=case when @LSHLevel1ID is null then -1 else @LSHLevel1ID end)  
					and (NK.LSHLevel2ID_=case when @LSHLevel2ID is null then -1 else @LSHLevel2ID end)  
					and (NK.LSHLevel3ID_=case when @LSHLevel3ID is null then -1 else @LSHLevel3ID end)  
					and (NK.LSHLevel4ID_=case when @LSHLevel4ID is null then -1 else @LSHLevel4ID end)  
					and (NK.LSHLevel5ID_=case when @LSHLevel5ID is null then -1 else @LSHLevel5ID end)  
					and (NK.LSHLevel6ID_=case when @LSHLevel6ID is null then -1 else @LSHLevel6ID end)  
					/*End   RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
					and (NK.LSCapBacNhanVienID_=case when @LSCapBacNhanVienID is null then -1 else @LSCapBacNhanVienID end)
					and (NK.LSJobTitleID_=case when @LSJobTitleID is null then -1 else @LSJobTitleID end)
					and (NK.LSLoaiNhanVienID_=case when @LSLoaiNhanVienID is null then -1 else @LSLoaiNhanVienID end)
					and (NK.LSLoaiLaoDongID_=case when @LSLoaiLaoDongID is null then -1 else @LSLoaiLaoDongID end)
					and (NK.LSLocationID_=case when @LSLocationID is null then -1 else @LSLocationID end)
					and (NK.LSNhomNhanVienID_=case when @LSNhomNhanVienID is null then -1 else @LSNhomNhanVienID end)
					and (NK.LSChucVuID_ = case when @LSChucVuID is null then -1 else @LSChucVuID end)
					and (case when Nk.LSLoaiHinhNhanVienID is null then -1 else Nk.LSLoaiHinhNhanVienID end = case when @LSLoaiHinhNhanVienID is null then -1 else @LSLoaiHinhNhanVienID end)
					and (
							(
								(@dsLoaiHD = '' or @dsLoaiHD is null)
								and CT.LoaiHD is null
							)
							or
							(
								(@dsLoaiHD <> '' or @dsLoaiHD is not null)
								and ('@'+@dsLoaiHD like '%'+'@'+CT.LoaiHD+'@'+'%')
							)
						)
					)
			begin
				 set @ReturnMess = '0024'
				 set @ReturnCode = '0024'
				 return
			end
			/**************/
			SET @iSuccess	=0 --số dòng insert thành công
			--Update Seq - 25/01/2019 - NhanHM4
			EXEC [dbo].[SYS_spGetAutoID_UpdateSeq] @TableName='HR_tblThietLapNguoiKyHD',@ColumnName='ThietLapID',@Seq=@ThietLapID OUTPUT

			--insert cha
			insert into HR_tblThietLapNguoiKyHD
			(
				ThietLapID,LSCompanyID, LSLevel1ID, 
				LSLevel2ID,LSLevel3ID,LSLevel4ID,LSLevel5ID,
				LSLevel6ID,LSLevel7ID,LSLevel8ID,LSLevel9ID,
				/*Start RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
				LSHLevel1ID, LSHLevel2ID, LSHLevel3ID, LSHLevel4ID, LSHLevel5ID, LSHLevel6ID,
				/*End   RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
				NgayHieuLuc, EmpID, TenNguoiKy, ChucDanh, NoiKy,
				GiayUyQuyen,Other1,Other2,Other3,Other4,Other5,Other6,Other7,Other8,Other9,Other10, 
				LSCapBacNhanVienID,LSJobTitleID,LSLoaiNhanVienID,LSLocationID, LSNhomNhanVienID,LSChucVuID,LSLoaiHinhNhanVienID, AuthorizationDate --Rlog 19909 22/09/2023
				,Creater, CreateDate /*TungTT83 bổ sung checkList đào tạo 02/12/2023*/, LSCapBacCongViecNoiBoID /*Rlog 20571 THienLK4 - DXG - 21/12/2023*/
				,AttachFile
				,NguoiKyNhay,EmailVanThu,TaiKhoanVanThu
				,Reviewer1,Reviewer2,Reviewer3,Reviewer4
				,LSLoaiLaoDongID
			)
			VALUES
			(
				@ThietLapID,@LSCompanyID, @LSLevel1ID, 
				@LSLevel2ID,@LSLevel3ID,@LSLevel4ID,@LSLevel5ID,
				@LSLevel6ID,@LSLevel7ID,@LSLevel8ID,@LSLevel9ID,
				/*Start RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
				@LSHLevel1ID, @LSHLevel2ID, @LSHLevel3ID, @LSHLevel4ID, @LSHLevel5ID, @LSHLevel6ID,
				/*End   RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
				CONVERT(DATETIME,@NgayHieuLuc,103), @EmpID, @TenNguoiKy, @ChucDanh, @NoiKy,
				@GiayUyQuyen,@Other1,@Other2,@Other3,@Other4,@Other5,@Other6,@Other7,@Other8,@Other9,@Other10,
				@LSCapBacNhanVienID,@LSJobTitleID,@LSLoaiNhanVienID,@LSLocationID,@LSNhomNhanVienID,@LSChucVuID,@LSLoaiHinhNhanVienID, @bAuthorizationDate --Rlog 19909 22/09/2023
				,@UserGroupID, GETDATE() /*TungTT83 bổ sung checkList đào tạo 02/12/2023*/, @LSCapBacCongViecNoiBoID /*Rlog 20571 THienLK4 - DXG - 21/12/2023*/
				,@AttachFile
				,@NguoiKyNhay,@EmailVanThu,@TaiKhoanVanThu
				,@Reviewer1,@Reviewer2,@Reviewer3,@Reviewer4
				,@LSLoaiLaoDongID
			)
			------------
			set @Current1 = 1
			--insert con
			WHILE (dbo.fnGetStringByToken(@dsLoaiHD,'@',@Current1) <> '')
			BEGIN					
				set @LoaiHD	= dbo.fnGetStringByToken(@dsLoaiHD,'@',@Current1)
				--TrangNT: 20151030: Không cần valid trùng vì đã valid ở activity ValidDuplicate
				--Update Seq - 25/01/2019 - NhanHM4
				EXEC [dbo].[SYS_spGetAutoID_UpdateSeq] @TableName='HR_tblThietLapNguoiKyHD_ChiTiet',@ColumnName='ThietLapChiTietID',@Seq=@ThietLapChiTietID OUTPUT

				INSERT INTO HR_tblThietLapNguoiKyHD_Chitiet
				(
					ThietLapChiTietID, ThietLapID, LoaiHD
				)
				VALUES
				(
					@ThietLapChiTietID, @ThietLapID, @LoaiHD
				)
				SET @iSuccess= @iSuccess+1
				set @Current1 = @Current1 + 1				
			END--end While
		
			IF @iSuccess=0 and not exists(select top 1 1 from HR_tblSetupHR where NoCheckContractType = 1)
			BEGIN
				DELETE HR_tblThietLapNguoiKyHD WHERE ThietLapID=@ThietLapID
			END
		
			if @iSuccess=0 and isnull(@ThietLapID,'') <> ''
				set @iSuccess = @iSuccess + 1
			SET @ReturnSuccessRows=@iSuccess
			SET @ReturnMess=''
			SET @ReturnCode='TL_0002'
		end
		else
		BEGIN
			
			declare db_Cursor CURSOR FOR
				select @UserGroupID UserGroupID,@LSCompanyID LSCompanyID,
				case when @LSLevel1ID = '' then null else @LSLevel1ID end LSLevel1ID,
				case when @LSLevel2ID = '' then null else @LSLevel2ID end LSLevel2ID, 
				case when @LSLevel3ID = '' then null else @LSLevel3ID end LSLevel3ID, 
				case when @LSLevel4ID = '' then null else @LSLevel4ID end LSLevel4ID, 
				case when @LSLevel5ID = '' then null else @LSLevel5ID end LSLevel5ID, 
				case when @LSLevel6ID = '' then null else @LSLevel6ID end LSLevel6ID, 
				case when @LSLevel7ID = '' then null else @LSLevel7ID end LSLevel7ID, 
				case when @LSLevel8ID = '' then null else @LSLevel8ID end LSLevel8ID, 
				case when @LSLevel9ID = '' then null else @LSLevel9ID end LSLevel9ID, 
				/*Start RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
				case when @LSHLevel1ID = '' then null else @LSHLevel1ID end LSHLevel1ID,
				case when @LSHLevel2ID = '' then null else @LSHLevel2ID end LSHLevel2ID, 
				case when @LSHLevel3ID = '' then null else @LSHLevel3ID end LSHLevel3ID, 
				case when @LSHLevel4ID = '' then null else @LSHLevel4ID end LSHLevel4ID, 
				case when @LSHLevel5ID = '' then null else @LSHLevel5ID end LSHLevel5ID, 
				case when @LSHLevel6ID = '' then null else @LSHLevel6ID end LSHLevel6ID,
				/*End   RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
				--case when @LSCapBacNhanVienID = '' then null else @LSCapBacNhanVienID end 
				LSCapBacNhanVienID,
				case when @LSCapBacCongViecNoiBoID = '' then null else @LSCapBacCongViecNoiBoID end LSCapBacCongViecNoiBoID,
				LSJobTitleID,
				case when @LSLoaiNhanVienID = '' then null else @LSLoaiNhanVienID end LSLoaiNhanVienID,
				case when @LSLoaiLaoDongID = '' then null else @LSLoaiLaoDongID end LSLoaiLaoDongID,
				case when @LSLocationID = '' then null else @LSLocationID end LSLocationID,
				case when @LSNhomNhanVienID = '' then null else @LSNhomNhanVienID end LSNhomNhanVienID,
				LSChucVuID,
				@NgayHieuLuc NgayHieuLuc,@dsLoaiHD strLSLoaiHopDongID, @EmpID EmpID, @TenNguoiKy EmpName_NguoiKy, @ChucDanh Emp_ChucDanh,
				@NoiKy NoiKy,@GiayUyQuyen TheoGiayUyQuyen,@Other1 Other1,@Other2 Other2,@Other3 Other3,@Other4 Other4,
				@Other5 Other5,@Other6 Other6,@Other7 Other7,@Other8 Other8,@Other9 Other9,@Other10 Other10, @LSLoaiHinhNhanVienID LSLoaiHinhNhanVienID, @bAuthorizationDate AuthorizationDate --Rlog 19909 22/09/2023
				from #TempChucDanh_ChucVu_CapBacNhanVien
			open db_Cursor
				FETCH NEXT FROM db_Cursor INTO @UserGroupID,@LSCompanyID,@LSLevel1ID, 
					@LSLevel2ID,@LSLevel3ID,@LSLevel4ID,@LSLevel5ID,
					@LSLevel6ID,@LSLevel7ID,@LSLevel8ID,@LSLevel9ID,
					/*Start RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
					@LSHLevel1ID, @LSHLevel2ID,@LSHLevel3ID,@LSHLevel4ID,@LSHLevel5ID,@LSHLevel6ID,
					/*End   RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
					@LSCapBacNhanVienID, @LSCapBacCongViecNoiBoID,@LSJobTitleID,@LSLoaiNhanVienID,@LSLoaiLaoDongID,@LSLocationID,@LSNhomNhanVienID,@LSChucVuID,
					@NgayHieuLuc,@dsLoaiHD,@EmpID, @TenNguoiKy, @ChucDanh, @NoiKy,
					@GiayUyQuyen,@Other1,@Other2,@Other3,@Other4,@Other5,@Other6,@Other7,@Other8,@Other9,@Other10,@LSLoaiHinhNhanVienID, @bAuthorizationDate --Rlog 19909 22/09/2023
			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @ThietLapID = NULL
				------------
				SET @iSuccess	=0 --số dòng insert thành công
				IF EXISTS (
				SELECT	DISTINCT CASE WHEN @dsLoaiHD <> '' AND @dsLoaiHD IS NOT NULL	THEN CASE WHEN @LanguageID='EN' THEN CTT.Name ELSE CTT.VNName END 
							WHEN @dsLoaiHD = '' OR @dsLoaiHD IS NULL		THEN CASE WHEN @LanguageID='EN' THEN N'Check contract type' ELSE N'Kiểm tra loại hợp đồng' END 
						END AS ContractTypeDup
				FROM (	SELECT	ISNULL(LSCompanyID,-1) LSCompanyID_, ISNULL(LSLevel1ID,-1) LSLevel1ID_,ISNULL(LSLevel2ID,-1) LSLevel2ID_,ISNULL(LSLevel3ID,-1) LSLevel3ID_,ISNULL(LSLevel4ID,-1) LSLevel4ID_,ISNULL(LSLevel5ID,-1) LSLevel5ID_,ISNULL(LSLevel6ID,-1) LSLevel6ID_,ISNULL(LSLevel7ID,-1) LSLevel7ID_,ISNULL(LSLevel8ID,-1) LSLevel8ID_,ISNULL(LSLevel9ID,-1) LSLevel9ID_,
									/*Start RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
									ISNULL(LSHLevel1ID,-1) LSHLevel1ID_,ISNULL(LSHLevel2ID,-1) LSHLevel2ID_,ISNULL(LSHLevel3ID,-1) LSHLevel3ID_,ISNULL(LSHLevel4ID,-1) LSHLevel4ID_,ISNULL(LSHLevel5ID,-1) LSHLevel5ID_,ISNULL(LSHLevel6ID,-1) LSHLevel6ID_,
									/*End   RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
									ISNULL(LSCapBacNhanVienID,-1) LSCapBacNhanVienID_, ISNULL(LSCapBacCongViecNoiBoID, -1) LSCapBacCongViecNoiBoID_,
									ISNULL(LSJobTitleID,-1) LSJobTitleID_,ISNULL(LSLoaiNhanVienID,-1) LSLoaiNhanVienID_, ISNULL(LSLoaiLaoDongID,-1) LSLoaiLaoDongID_,
									ISNULL(LSLocationID,-1) LSLocationID_,ISNULL(LSNhomNhanVienID,-1) AS LSNhomNhanVienID_,ISNULL(LSChucVuID,-1) AS LSChucVuID_,*
							FROM HR_tblThietLapNguoiKyHD(NOLOCK) 
						)NK
				LEFT JOIN HR_tblThietLapNguoiKyHD_Chitiet(NOLOCK)  CT  ON NK.ThietLapID=CT.ThietLapID
				LEFT JOIN LS_tblContractType(NOLOCK) CTT ON CT.LoaiHD = CTT.LSContractTypeID
				WHERE 1=1
					AND (NK.ThietLapID<>@ThietLapID OR @ThietLapID = '' OR @ThietLapID IS NULL)
					AND NgayHieuLuc=@dNgayHieuLuc 
					AND (NK.LSCompanyID_=CASE WHEN @LSCompanyID IS NULL THEN -1 ELSE @LSCompanyID END) 
					AND (NK.LSLevel1ID_=CASE WHEN @LSLevel1ID IS NULL THEN -1 ELSE @LSLevel1ID END)  
					AND (NK.LSLevel2ID_=CASE WHEN @LSLevel2ID IS NULL THEN -1 ELSE @LSLevel2ID END)  
					AND (NK.LSLevel3ID_=CASE WHEN @LSLevel3ID IS NULL THEN -1 ELSE @LSLevel3ID END)  
					AND (NK.LSLevel4ID_=CASE WHEN @LSLevel4ID IS NULL THEN -1 ELSE @LSLevel4ID END)  
					AND (NK.LSLevel5ID_=CASE WHEN @LSLevel5ID IS NULL THEN -1 ELSE @LSLevel5ID END)  
					AND (NK.LSLevel6ID_=CASE WHEN @LSLevel6ID IS NULL THEN -1 ELSE @LSLevel6ID END)  
					AND (NK.LSLevel7ID_=CASE WHEN @LSLevel7ID IS NULL THEN -1 ELSE @LSLevel7ID END)  
					AND (NK.LSLevel8ID_=CASE WHEN @LSLevel8ID IS NULL THEN -1 ELSE @LSLevel8ID END)  
					AND (NK.LSLevel9ID_=CASE WHEN @LSLevel9ID IS NULL THEN -1 ELSE @LSLevel9ID END)  
					/*Start RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
					AND (NK.LSHLevel1ID_=CASE WHEN @LSHLevel1ID IS NULL THEN -1 ELSE @LSHLevel1ID END)  
					AND (NK.LSHLevel2ID_=CASE WHEN @LSHLevel2ID IS NULL THEN -1 ELSE @LSHLevel2ID END)  
					AND (NK.LSHLevel3ID_=CASE WHEN @LSHLevel3ID IS NULL THEN -1 ELSE @LSHLevel3ID END)  
					AND (NK.LSHLevel4ID_=CASE WHEN @LSHLevel4ID IS NULL THEN -1 ELSE @LSHLevel4ID END)  
					AND (NK.LSHLevel5ID_=CASE WHEN @LSHLevel5ID IS NULL THEN -1 ELSE @LSHLevel5ID END)  
					AND (NK.LSHLevel6ID_=CASE WHEN @LSHLevel6ID IS NULL THEN -1 ELSE @LSHLevel6ID END) 
					/*End   RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
					AND (NK.LSCapBacNhanVienID_=CASE WHEN @LSCapBacNhanVienID IS NULL THEN -1 ELSE @LSCapBacNhanVienID END)
                    and (NK.LSCapBacCongViecNoiBoID_=case when @LSCapBacCongViecNoiBoID is null then -1 else @LSCapBacCongViecNoiBoID end)
					and (NK.LSJobTitleID_=case when @LSJobTitleID is null then -1 else @LSJobTitleID end)
					and (NK.LSLoaiNhanVienID_=case when @LSLoaiNhanVienID is null then -1 else @LSLoaiNhanVienID end)
					and (NK.LSLoaiLaoDongID_=case when @LSLoaiLaoDongID is null then -1 else @LSLoaiLaoDongID end)
					and (NK.LSLocationID_=case when @LSLocationID is null then -1 else @LSLocationID end)
					and (NK.LSNhomNhanVienID_=case when @LSNhomNhanVienID is null then -1 else @LSNhomNhanVienID end)
					and (NK.LSChucVuID_ = case when @LSChucVuID is null then -1 else @LSChucVuID end)
					and (case when Nk.LSLoaiHinhNhanVienID is null then -1 else Nk.LSLoaiHinhNhanVienID end = case when @LSLoaiHinhNhanVienID is null then -1 else @LSLoaiHinhNhanVienID end)
					and (
							(
								(@dsLoaiHD = '' or @dsLoaiHD is null)
								and CT.LoaiHD is null
							)
							or
							(
								(@dsLoaiHD <> '' or @dsLoaiHD is not null)
								and ('@'+@dsLoaiHD like '%'+'@'+CT.LoaiHD+'@'+'%')
							)
						)
					)
				begin
					 set @ReturnCode = CASE WHEN @LanguageID='EN' THEN 'Data Duplicate' else N'Trùng dữ liệu' end
					 print @ReturnCode
					 return
				end
				---------------
				--Update Seq - 25/01/2019 - NhanHM4
				EXEC [dbo].[SYS_spGetAutoID_UpdateSeq] @TableName='HR_tblThietLapNguoiKyHD',@ColumnName='ThietLapID',@Seq=@ThietLapID OUTPUT

				--insert cha
				insert into HR_tblThietLapNguoiKyHD
				(
					ThietLapID,LSCompanyID, LSLevel1ID, 
					LSLevel2ID,LSLevel3ID,LSLevel4ID,LSLevel5ID,
					LSLevel6ID,LSLevel7ID,LSLevel8ID,LSLevel9ID,
					/*Start RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
					LSHLevel1ID,LSHLevel2ID,LSHLevel3ID,LSHLevel4ID,LSHLevel5ID,LSHLevel6ID,
					/*End   RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
					NgayHieuLuc, EmpID, TenNguoiKy, ChucDanh, NoiKy,
					GiayUyQuyen,Other1,Other2,Other3,Other4,Other5,Other6,Other7,Other8,Other9,Other10,
					LSCapBacNhanVienID,LSCapBacCongViecNoiBoID,LSJobTitleID,LSLoaiNhanVienID,LSLocationID, LSNhomNhanVienID,LSChucVuID,LSLoaiHinhNhanVienID, AuthorizationDate --Rlog 19909 22/09/2023
					,Creater, CreateDate /*TungTT83 bổ sung checkList đào tạo 02/12/2023*/
					,AttachFile
					,Reviewer1,Reviewer2,Reviewer3,Reviewer4
					,LSLoaiLaoDongID
				)
				values
				(
					@ThietLapID,@LSCompanyID, @LSLevel1ID, 
					@LSLevel2ID,@LSLevel3ID,@LSLevel4ID,@LSLevel5ID,
					@LSLevel6ID,@LSLevel7ID,@LSLevel8ID,@LSLevel9ID,
					/*Start RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
					@LSHLevel1ID,@LSHLevel2ID,@LSHLevel3ID,@LSHLevel4ID,@LSHLevel5ID,@LSHLevel6ID,
					/*End   RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
					CONVERT(datetime,@NgayHieuLuc,103), @EmpID, @TenNguoiKy, @ChucDanh, @NoiKy,
					@GiayUyQuyen,@Other1,@Other2,@Other3,@Other4,@Other5,@Other6,@Other7,@Other8,@Other9,@Other10,
					@LSCapBacNhanVienID,@LSCapBacCongViecNoiBoID,@LSJobTitleID,@LSLoaiNhanVienID,@LSLocationID,@LSNhomNhanVienID,@LSChucVuID,@LSLoaiHinhNhanVienID, @bAuthorizationDate --Rlog 19909 22/09/2023
					,@UserGroupID, GetDate() /*TungTT83 bổ sung checkList đào tạo 02/12/2023*/
					,@AttachFile
					,@Reviewer1,@Reviewer2,@Reviewer3,@Reviewer4
					,@LSLoaiLaoDongID
				)
				------------
				set @Current1 = 1
				--insert con
				WHILE (dbo.fnGetStringByToken(@dsLoaiHD,'@',@Current1) <> '')
				BEGIN					
					set @LoaiHD	= dbo.fnGetStringByToken(@dsLoaiHD,'@',@Current1)
					--TrangNT: 20151030: Không cần valid trùng vì đã valid ở activity ValidDuplicate
					--Update Seq - 25/01/2019 - NhanHM4
					EXEC [dbo].[SYS_spGetAutoID_UpdateSeq] @TableName='HR_tblThietLapNguoiKyHD_ChiTiet',@ColumnName='ThietLapChiTietID',@Seq=@ThietLapChiTietID OUTPUT

					INSERT INTO HR_tblThietLapNguoiKyHD_Chitiet
					(
						ThietLapChiTietID, ThietLapID, LoaiHD
					)
					VALUES
					(
						@ThietLapChiTietID, @ThietLapID, @LoaiHD
					)
					SET @iSuccess= @iSuccess+1
					set @Current1 = @Current1 + 1				
				END--end While
		
				IF @iSuccess=0 and not exists(select top 1 1 from HR_tblSetupHR where NoCheckContractType = 1)
				BEGIN
					DELETE HR_tblThietLapNguoiKyHD WHERE ThietLapID=@ThietLapID
				END
		
				if @iSuccess=0 and isnull(@ThietLapID,'') <> ''
					set @iSuccess = @iSuccess + 1
				SET @ReturnSuccessRows=@iSuccess
				SET @ReturnMess=''
				SET @ReturnCode='TL_0002'
			
			-------------
			fetch next from db_Cursor into @UserGroupID,@LSCompanyID,@LSLevel1ID, 
				@LSLevel2ID,@LSLevel3ID,@LSLevel4ID,@LSLevel5ID,
				@LSLevel6ID,@LSLevel7ID,@LSLevel8ID,@LSLevel9ID,
				/*Start RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
				@LSHLevel1ID, @LSHLevel2ID,@LSHLevel3ID,@LSHLevel4ID,@LSHLevel5ID,@LSHLevel6ID,
				/*End   RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
				@LSCapBacNhanVienID,@LSCapBacCongViecNoiBoID,@LSJobTitleID,@LSLoaiNhanVienID,@LSLoaiLaoDongID,@LSLocationID,@LSNhomNhanVienID,@LSChucVuID,
				@NgayHieuLuc,@dsLoaiHD,@EmpID, @TenNguoiKy, @ChucDanh, @NoiKy,
				@GiayUyQuyen,@Other1,@Other2,@Other3,@Other4,@Other5,@Other6,@Other7,@Other8,@Other9,@Other10,@LSLoaiHinhNhanVienID, @bAuthorizationDate --Rlog 19909 22/09/2023
			end
			close db_Cursor
			deallocate db_Cursor
		end
	END
END
else if @Activity='ValidDuplicate'
Begin
	Select	distinct Case when @dsLoaiHD <> '' and @dsLoaiHD is not null	then Case when @LanguageID='EN' then CTT.Name else CTT.VNName end 
				when @dsLoaiHD = '' or @dsLoaiHD is null		then Case when @LanguageID='EN' then N'Check contract type' else N'Kiểm tra loại hợp đồng' end 
			end as ContractTypeDup
	from (	Select	isnull(LSCompanyID,'') LSCompanyID_, isnull(LSLevel1ID,'') LSLevel1ID_,isnull(LSLevel2ID,'') LSLevel2ID_,isnull(LSLevel3ID,'') LSLevel3ID_,isnull(LSLevel4ID,'') LSLevel4ID_,isnull(LSLevel5ID,'') LSLevel5ID_,isnull(LSLevel6ID,'') LSLevel6ID_,isnull(LSLevel7ID,'') LSLevel7ID_,isnull(LSLevel8ID,'') LSLevel8ID_,isnull(LSLevel9ID,'') LSLevel9ID_,
						isnull(LSCapBacNhanVienID,'') LSCapBacNhanVienID_,isnull(LSCapBacCongViecNoiBoID,'') LSCapBacCongViecNoiBoID_,
						isnull(LSJobTitleID,'') LSJobTitleID_,isnull(LSLoaiNhanVienID,'') LSLoaiNhanVienID_, isnull(LSLoaiLaoDongID,'') LSLoaiLaoDongID_,
						isnull(LSLocationID,'') LSLocationID_,isnull(LSNhomNhanVienID,'') as LSNhomNhanVienID_,isnull(LSChucVuID,'') as LSChucVuID_,*
				From HR_tblThietLapNguoiKyHD(NoLock) 
			)NK
	left join HR_tblThietLapNguoiKyHD_Chitiet(NoLock)  CT  on NK.ThietLapID=CT.ThietLapID
	Left join LS_tblContractType(Nolock) CTT on CT.LoaiHD = CTT.LSContractTypeID
	where 1=1
		and (NK.ThietLapID<>@ThietLapID or @ThietLapID = '' or @ThietLapID is null)
		and NgayHieuLuc=@dNgayHieuLuc 
		and (NK.LSCompanyID_=@LSCompanyID) and (NK.LSLevel1ID_=@LSLevel1ID)  and (NK.LSLevel2ID_=@LSLevel2ID)  and (NK.LSLevel3ID_=@LSLevel3ID)  and (NK.LSLevel4ID_=@LSLevel4ID)  and (NK.LSLevel5ID_=@LSLevel5ID)  and (NK.LSLevel6ID_=@LSLevel6ID)  and (NK.LSLevel7ID_=@LSLevel7ID)  and (NK.LSLevel8ID_=@LSLevel8ID)  and (NK.LSLevel9ID_=@LSLevel9ID)  
		and (NK.LSCapBacNhanVienID_=@LSCapBacNhanVienID)
		and (NK.LSCapBacCongViecNoiBoID_=@LSCapBacCongViecNoiBoID)
		and (NK.LSJobTitleID_=@LSJobTitleID)
		and (NK.LSLoaiNhanVienID_=@LSLoaiNhanVienID)
		and (NK.LSLoaiLaoDongID_=@LSLoaiLaoDongID)
		and (NK.LSLocationID_=@LSLocationID)
		and (NK.LSNhomNhanVienID_=@LSNhomNhanVienID)
		and (NK.LSChucVuID_ = @LSChucVuID)
		and (case when Nk.LSLoaiHinhNhanVienID is null then -1 else Nk.LSLoaiHinhNhanVienID end = case when @LSLoaiHinhNhanVienID is null then -1 else @LSLoaiHinhNhanVienID end)
		and (
				(
					(@dsLoaiHD = '' or @dsLoaiHD is null)
					and CT.LoaiHD is null
				)
				or
				(
					(@dsLoaiHD <> '' or @dsLoaiHD is not null)
					and ('@'+@dsLoaiHD like '%'+'@'+CT.LoaiHD+'@'+'%')
				)
			)

End
else if @Activity= 'Update'
BEGIN		
	Update HR_tblThietLapNguoiKyHD
	set LSCompanyID=@LSCompanyID
		,LSLevel1ID=@LSLevel1ID
		,LSLevel2ID=@LSLevel2ID
		,LSLevel3ID=@LSLevel3ID
		,LSLevel4ID=@LSLevel4ID
		,LSLevel5ID=@LSLevel5ID
		,LSLevel6ID=@LSLevel6ID
		,LSLevel7ID=@LSLevel7ID
		,LSLevel8ID=@LSLevel8ID
		,LSLevel9ID=@LSLevel9ID
		/*Start RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
		,LSHLevel1ID=@LSHLevel1ID
		,LSHLevel2ID=@LSHLevel2ID
		,LSHLevel3ID=@LSHLevel3ID
		,LSHLevel4ID=@LSHLevel4ID
		,LSHLevel5ID=@LSHLevel5ID
		,LSHLevel6ID=@LSHLevel6ID
		/*End   RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
		,LSCapBacNhanVienID = @strLSCapBacNhanVienID
		,LSCapBacCongViecNoiBoID = @LSCapBacCongViecNoiBoID --Rlog 20571 THienLK4 - DXG - 21/12/2023
		,LSJobTitleID = @strLSJobTitleID
		,LSLoaiNhanVienID = @LSLoaiNhanVienID
		,LSLoaiLaoDongID = @LSLoaiLaoDongID
		,LSLocationID = @LSLocationID
		,NgayHieuLuc=@dNgayHieuLuc
		,EmpID=@EmpID
		,TenNguoiKy=@TenNguoiKy
		,ChucDanh=@ChucDanh
		,NoiKy=@NoiKy
		,GiayUyQuyen=@GiayUyQuyen
		,AttachFile=@AttachFile
		,Other1=@Other1
		,Other2=@Other2
		,Other3=@Other3
		,Other4=@Other4
		,Other5=@Other5
		,Other6=@Other6
		,Other7=@Other7
		,Other8=@Other8
		,Other9=@Other9
		,Other10=@Other10
		,LSNhomNhanVienID=@LSNhomNhanVienID
		,LSChucVuID = @strLSChucVuID
		,LSLoaiHinhNhanVienID=@LSLoaiHinhNhanVienID
		,AuthorizationDate = @bAuthorizationDate --Rlog 19909 22/09/2023
		/*Start TungTT83 bổ sung checkList đào tạo 02/12/2023*/
		,Editer = @UserGroupID
		,EditDate = GetDate()
		/*End TungTT83 bổ sung checkList đào tạo 02/12/2023*/
		/*START Rlog 21420 HaiNT181 26/06/2024*/
		,NguoiKyNhay = @NguoiKyNhay
		,EmailVanThu = @EmailVanThu
		,TaiKhoanVanThu = @TaiKhoanVanThu
		/*End Rlog 21420 HaiNT181 26/06/2024*/
		/*Tamnb rlog 21379 Vitadairy*/
		,Reviewer1 =@Reviewer1
		,Reviewer2 =@Reviewer2
		,Reviewer3 =@Reviewer3
		,Reviewer4 =@Reviewer4
		/*Tamnb rlog 21379 Vitadairy*/
	where ThietLapID=@ThietLapID
	--Update con
	--TrangNT: 20151030: Ko cần valid trùng nữa vì đã valid ở activity ValidDuplicate	
	delete from HR_tblThietLapNguoiKyHD_Chitiet where ThietLapID = @ThietLapID 
	WHILE (dbo.fnGetStringByToken(@dsLoaiHD,'@',@Current) <> '')
	BEGIN					
		set @LoaiHD	= dbo.fnGetStringByToken(@dsLoaiHD,'@',@Current)
		--Update Seq - 25/01/2019 - NhanHM4
		EXEC [dbo].[SYS_spGetAutoID_UpdateSeq] @TableName='HR_tblThietLapNguoiKyHD_ChiTiet',@ColumnName='ThietLapChiTietID',@Seq=@ThietLapChiTietID OUTPUT

		INSERT INTO HR_tblThietLapNguoiKyHD_Chitiet
		(
			ThietLapChiTietID, ThietLapID, LoaiHD
		)
		VALUES
		(
			@ThietLapChiTietID, @ThietLapID, @LoaiHD
		)
		set @Current = @Current + 1				
	END--end While
	
	delete from HR_tblThietLapNguoiKyHD_Chitiet where LoaiHD is null
END
else if (@Activity= 'Delete')--Xoa dong chi tiet
	BEGIN
		Print 'delete'
		
		DELETE FROM HR_tblThietLapNguoiKyHD_ChiTiet WHERE ThietLapID=@ThietLapID
		
		--xoa het con roi xoa cha
		IF(NOT EXISTS(SELECT top 1 1 FROM HR_tblThietLapNguoiKyHD_ChiTiet WHERE ThietLapID=@ThietLapID))
		BEGIN
			DELETE FROM HR_tblThietLapNguoiKyHD WHERE ThietLapID=@ThietLapID
		END
		
		SET @ReturnMess=''
		SET @ReturnCode='00002'--da ton tai
	END
ELSE if (@Activity = 'DeleteParent')--Xoa dong cha neu dong cha ko co dong con nao ca
begin
	DELETE FROM HR_tblThietLapNguoiKyHD WHERE ThietLapID IN (select items from dbo.Split(@dsThietLapID, '$'))
end
ELSE if (@Activity= 'Search')
BEGIN		
	set @dTuNgay	= case when isnull(@TuNgay,'') ='' then '1900-01-01' else convert(datetime,@TuNgay,103) end
	set @dDenNgay	= case when isnull(@DenNgay,'')='' then '2100-01-01' else convert(datetime,@DenNgay,103)end
	
	Select TL.ThietLapID,TL.EmpID,TL.LSCompanyID,TL.LSLevel1ID, 
		--,tlct.ThietLapChiTietID
		CASE WHEN @LanguageID='EN' THEN CP.[Name] ELSE CP.[VNName] END AS CompanyName,--cty ký
		CASE WHEN @LanguageID='EN' THEN L1.[Name] ELSE L1.[VNName] END AS Level1Name,--Don vi ký
		CASE WHEN @LanguageID='EN' THEN L2.[Name] ELSE L2.[VNName] END AS Level2Name,
		CASE WHEN @LanguageID='EN' THEN L3.[Name] ELSE L3.[VNName] END AS Level3Name,
		CASE WHEN @LanguageID='EN' THEN L4.[Name] ELSE L4.[VNName] END AS Level4Name,
		CASE WHEN @LanguageID='EN' THEN L5.[Name] ELSE L5.[VNName] END AS Level5Name,
		CASE WHEN @LanguageID='EN' THEN L6.[Name] ELSE L6.[VNName] END AS Level6Name,
		CASE WHEN @LanguageID='EN' THEN L7.[Name] ELSE L7.[VNName] END AS Level7Name,
		CASE WHEN @LanguageID='EN' THEN L8.[Name] ELSE L8.[VNName] END AS Level8Name,
		CASE WHEN @LanguageID='EN' THEN L9.[Name] ELSE L9.[VNName] END AS Level9Name,
		/*Start RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
		CASE WHEN @LanguageID='EN' THEN HL1.[Name] ELSE HL1.[VNName] END AS HLevel1Name,
		CASE WHEN @LanguageID='EN' THEN HL2.[Name] ELSE HL2.[VNName] END AS HLevel2Name,
		CASE WHEN @LanguageID='EN' THEN HL3.[Name] ELSE HL3.[VNName] END AS HLevel3Name,
		CASE WHEN @LanguageID='EN' THEN HL4.[Name] ELSE HL4.[VNName] END AS HLevel4Name,
		CASE WHEN @LanguageID='EN' THEN HL5.[Name] ELSE HL5.[VNName] END AS HLevel5Name,
		CASE WHEN @LanguageID='EN' THEN HL6.[Name] ELSE HL6.[VNName] END AS HLevel6Name,
		/*End   RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
		case when @LanguageID='VN' then D.VNName else D.Name end CapBacNhanVien,
		case when @LanguageID='VN' then H.VNName else H.Name end BacNhanVien, /*Rlog 20571 THienLK4 - DXG - 21/12/2023*/
		case when @LanguageID='VN' then E.VNName else E.Name end JobTitle,
		case when @LanguageID='VN' then F.VNName else F.Name end LoaiNhanVien,
		case when @LanguageID='VN' then LD.VNName else LD.Name end LoaiLaoDong,
		case when @LanguageID='VN' then G.VNName else G.Name end Location,
		case when @LanguageID='VN' then CV.TenChucVuV else CV.TenChucVuE end ChucVu,
		CONVERT(NVARCHAR,TL.NgayHieuLuc,103) AS NgayHieuLuc,
		TL.NoiKy, TL.GiayUyQuyen,
		V.EmpName AS TenNguoiKy,
		Case when @LanguageID='VN' then V.JobTitleVN else V.JobTitleEN end AS ChucDanh
		--,TLCT.LoaiHD
		--,CASE WHEN @LanguageID='EN' THEN CT.[Name] ELSE CT.[VNName] END AS TenLoaiHD
		,TL.Other1,TL.Other2,TL.Other3,TL.Other4,TL.Other5,TL.Other6,TL.Other7,TL.Other8,TL.Other9,TL.Other10
		--20151029: TrangNT: Bổ sung cột này, cộng chuỗi contract type name. Sửa lại lưới hiển thị 1 dòng cho 1 cấu hình, thay vì mỗi contract type là 1 dòng như hiện tại
		,dbo.HR_fnCongChuoiThietLapNguoiKy(TL.ThietLapID,@LanguageID,'ContractTypeName','- ',char(13)+char(10),'','','','','') as TenLoaiHD
		, '@' + @strLSChucVuID, '%@' + convert(nvarchar,TL.LSChucVuID) + '@%'
		,Case when @LanguageID='VN' then lhnv.VNName else lhnv.Name end AS LoaiHinhNhanVien
		, CONVERT(nvarchar(10),TL.AuthorizationDate,103) AuthorizationDate --Rlog 19909 26/09/2023 ThienLK4
		,TL.Creater, TL.CreateDate, TL.Editer, TL.EditDate
		,r1.EmpName Reviewer1,r2.EmpName Reviewer2,r3.EmpName Reviewer3,r4.EmpName Reviewer4 /*Tamnb rlog 21379 vitaidairy*/
		,kn.EmpName as TenNguoiKyNhay,tl.EmailVanThu,tl.TaiKhoanVanThu
	FROM HR_tblThietLapNguoiKyHD(NoLock) TL 
		LEFT JOIN dbo.HR_vEmp(NoLock) V ON V.empID=TL.EmpID
		--LEFT JOIN HR_tblThietLapNguoiKyHD_ChiTiet(NoLock) TLCT ON TL.ThietLapID=TLCT.ThietLapID
		LEFT JOIN dbo.LS_tblCompany(NoLock) CP ON TL.LSCompanyID=CP.LSCompanyID
		LEFT JOIN dbo.LS_tblLevel1(NoLock) L1 ON TL.LSLevel1ID=L1.LSLevel1ID
		LEFT JOIN dbo.LS_tblLevel2(NoLock) L2 ON TL.LSLevel2ID=L2.LSLevel2ID
		LEFT JOIN dbo.LS_tblLevel3(NoLock) L3 ON TL.LSLevel3ID=L3.LSLevel3ID
		LEFT JOIN dbo.LS_tblLevel4(NoLock) L4 ON TL.LSLevel4ID=L4.LSLevel4ID
		LEFT JOIN dbo.LS_tblLevel5(NoLock) L5 ON TL.LSLevel5ID=L5.LSLevel5ID
		LEFT JOIN dbo.LS_tblLevel6(NoLock) L6 ON TL.LSLevel6ID=L6.LSLevel6ID
		LEFT JOIN dbo.LS_tblLevel7(NoLock) L7 ON TL.LSLevel7ID=L7.LSLevel7ID
		LEFT JOIN dbo.LS_tblLevel8(NoLock) L8 ON TL.LSLevel8ID=L8.LSLevel8ID
		LEFT JOIN dbo.LS_tblLevel9(NoLock) L9 ON TL.LSLevel9ID=L9.LSLevel9ID
		left join LS_tblCapBacNhanVien(NoLock) D on TL.LSCapBacNhanVienID = D.LSCapBacNhanVienID
		left join LS_tblJobTitle(NoLock) E on TL.LSJobTitleID = E.LSJobTitleID
		left join LS_tblLoaiNhanVien(NoLock) F on TL.LSLoaiNhanVienID = F.LSLoaiNhanVienID
		left join LS_tblLoaiLaoDong(NoLock) LD on TL.LSLoaiLaoDongID = LD.LSLoaiLaoDongID
		LEFT JOIN dbo.LS_tblCapBacCongViecNoiBo (NOLOCK) H ON TL.LSCapBacCongViecNoiBoID = H.LSCapBacCongViecNoiBoID /*Rlog 20571 THienLK4 - DXG - 21/12/2023*/
		left join LS_tblLocation(NoLock) G on TL.LSLocationID = G.LSLocationID
		left join LS_tblChucVu(NoLock) CV on TL.LSChucVuID = CV.LSChucVuID
		--LEFT JOIN dbo.LS_tblContractType(NoLock) CT ON CT.LSContractTypeID=TLCT.LoaiHD
		--inner join dbo.fnGetAllLevel_Permission(@UserGroupID ,@FunctionID ,'Comp') B on B.strvalue = TL.LSCompanyID
		left join dbo.fnGetAllLevel_Permission(@UserGroupID ,@FunctionID ,'Comp') B on B.strvalue = TL.LSCompanyID
		left join dbo.fnGetAllLevel_Permission(@UserGroupID ,@FunctionID ,'Level1') C on C.strvalue = TL.LSLevel1ID
		--Join để lọc theo các loại hợp đồng được check
		Left join (
			Select Max(ThietLapChiTietID) ThietLapChiTietID, ThietLapID
			From HR_tblThietLapNguoiKyHD_ChiTiet(NoLock) A
			Where 1=1
			And (
					(@dsLoaiHDSearch <> '' and @dsLoaiHDSearch is not null  and ('@'+@dsLoaiHDSearch like '%@'+ A.LoaiHD+'@%'))
					or 
					(@dsLoaiHDSearch = '' or @dsLoaiHDSearch is null)
				)
			Group by ThietLapID
		) TLCT on TL.ThietLapID=TLCT.ThietLapID
		/*Start RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
		LEFT JOIN dbo.LS_tblHLevel1(NoLock) HL1 ON TL.LSHLevel1ID=HL1.LSHLevel1ID
		LEFT JOIN dbo.LS_tblHLevel2(NoLock) HL2 ON TL.LSHLevel2ID=HL2.LSHLevel2ID
		LEFT JOIN dbo.LS_tblHLevel3(NoLock) HL3 ON TL.LSHLevel3ID=HL3.LSHLevel3ID
		LEFT JOIN dbo.LS_tblHLevel4(NoLock) HL4 ON TL.LSHLevel4ID=HL4.LSHLevel4ID
		LEFT JOIN dbo.LS_tblHLevel5(NoLock) HL5 ON TL.LSHLevel5ID=HL5.LSHLevel5ID
		LEFT JOIN dbo.LS_tblHLevel6(NoLock) HL6 ON TL.LSHLevel6ID=HL6.LSHLevel6ID
		left join LS_tblLoaiHinhNhanVien(nolock) lhnv on TL.LSLoaiHinhNhanVienID = lhnv.LSLoaiHinhNhanVienID
		/*End   RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
		left join HR_vEmp (nolock) r1 on r1.EmpID = tl.Reviewer1
		left join HR_vEmp (nolock) r2 on r2.EmpID = tl.Reviewer2
		left join HR_vEmp (nolock) r3 on r3.EmpID = tl.Reviewer3
		left join HR_vEmp (nolock) r4 on r4.EmpID = tl.Reviewer4
		LEFT JOIN HR_vEmp (nolock) kn on kn.EmpID = tl.NguoiKyNhay
	where 1=1 and (B.strvalue is not null or TL.LSCompanyID is null)
		and NgayHieuLuc between @dTuNgay and @dDenNgay
		and(@LSCompanyID is null or TL.LSCompanyID = @LSCompanyID)
		and(@LSLevel1ID is null or TL.LSLevel1ID = @LSLevel1ID)
		and(@LSLevel2ID is null or TL.LSLevel2ID = @LSLevel2ID)
		and(@LSLevel3ID is null or TL.LSLevel3ID = @LSLevel3ID)
		and(@LSLevel4ID is null or TL.LSLevel4ID = @LSLevel4ID)
		and(@LSLevel5ID is null or TL.LSLevel5ID = @LSLevel5ID)
		and(@LSLevel6ID is null or TL.LSLevel6ID = @LSLevel6ID)
		and(@LSLevel7ID is null or TL.LSLevel7ID = @LSLevel7ID)
		and(@LSLevel8ID is null or TL.LSLevel8ID = @LSLevel8ID)
		and(@LSLevel9ID is null or TL.LSLevel9ID = @LSLevel9ID)
		/*Start RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
		and(@LSHLevel1ID is null or TL.LSHLevel1ID = @LSHLevel1ID)
		and(@LSHLevel2ID is null or TL.LSHLevel2ID = @LSHLevel2ID)
		and(@LSHLevel3ID is null or TL.LSHLevel3ID = @LSHLevel3ID)
		and(@LSHLevel4ID is null or TL.LSHLevel4ID = @LSHLevel4ID)
		and(@LSHLevel5ID is null or TL.LSHLevel5ID = @LSHLevel5ID)
		and(@LSHLevel6ID is null or TL.LSHLevel6ID = @LSHLevel6ID)
		/*End   RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
		and(TL.LSLevel1ID is null or C.strvalue is not null)
		and(@TenNguoiKy='' or @TenNguoiKy is null or V.EmpName like N'%'+@TenNguoiKy+'%')
		--and(@dsLoaiHDSearch='' or @dsLoaiHDSearch is null or charindex('@'+ convert(nvarchar(12), CT.LSContractTypeID) +'@','@'+@dsLoaiHDSearch) <> 0)
		and(@strLSCapBacNhanVienID = '' or @strLSCapBacNhanVienID is null or '@' + @strLSCapBacNhanVienID like '%@' + convert(nvarchar,TL.LSCapBacNhanVienID) + '@%') -- TanND35 rlogid 23254

		AND(@LSCapBacCongViecNoiBoID = '' or @LSCapBacCongViecNoiBoID is null or TL.LSCapBacCongViecNoiBoID = @LSCapBacCongViecNoiBoID)/*Rlog 20571 THienLK4 - DXG - 21/12/2023*/
		--and(@LSJobTitleID = '' or @LSJobTitleID is null or TL.LSJobTitleID = @LSJobTitleID)
		and(@LSLoaiNhanVienID = '' or @LSLoaiNhanVienID is null or TL.LSLoaiNhanVienID = @LSLoaiNhanVienID)
		and(@LSLoaiLaoDongID = '' or @LSLoaiLaoDongID is null or TL.LSLoaiLaoDongID = @LSLoaiLaoDongID)
		and(@LSLocationID = '' or @LSLocationID is null or TL.LSLocationID = @LSLocationID)
		and(@LSNhomNhanVienID = '' or @LSNhomNhanVienID is null or TL.LSNhomNhanVienID = @LSNhomNhanVienID)
		--and(@LSChucVuID = '' or @LSChucVuID is null or TL.LSChucVuID = @LSChucVuID)
		and(
				@dsLoaiHDSearch='' or @dsLoaiHDSearch is null 
				or TLCT.ThietLapChiTietID is  not null
			)
		and(@strLSJobTitleID = '' or @strLSJobTitleID is null or '@' + @strLSJobTitleID like '%@' + convert(nvarchar,TL.LSJobTitleID) + '@%')
		--and(@strLSChucVuID = '' or @strLSChucVuID is null or '@' + @strLSChucVuID like '%@' + convert(nvarchar,TL.LSChucVuID) + '@%')
		and(@LSLoaiHinhNhanVienID is null or TL.LSLoaiHinhNhanVienID = @LSLoaiHinhNhanVienID)
	ORDER BY TL.NgayHieuLuc DESC, TL.LSCompanyID, Tl.LSLevel1ID, V.VfirstName, V.VlastName
	
	SET @ReturnMess=''
	SET @ReturnCode=''			
	--and charindex( '@'+ convert(nvarchar(12), CT.LSContractTypeID) +'@', @strContractType ) != 0
END
ELSE if (@Activity= 'LoadDataExport')
BEGIN		
	set @dTuNgay	= case when isnull(@TuNgay,'') ='' then '1900-01-01' else convert(datetime,@TuNgay,103) end
	set @dDenNgay	= case when isnull(@DenNgay,'')='' then '2100-01-01' else convert(datetime,@DenNgay,103)end
	
	DECLARE @TenCot NVARCHAR(MAX),@TenCot_BangTam NVARCHAR(MAX) SET @TenCot='' SET @TenCot_BangTam =''
	SELECT	@TenCot = @TenCot + '[' + ControlID + '],' 
			,@TenCot_BangTam = @TenCot_BangTam + '[' + ControlID + '] NVARCHAR(1) NULL,'
	FROM sys_tblreportcaption (nolock)
	where functionid = @FunctionID 
	order by AutoID
	

	SET @TenCot = SUBSTRING(@TenCot,0,LEN(@TenCot))
	SET @TenCot_BangTam =SUBSTRING(@TenCot_BangTam,0,LEN(@TenCot_BangTam))

	if object_id('tempdb..##tmpCaption') is not null
		drop table ##tmpCaption
	
	DECLARE @SQL NVARCHAR(MAX)
	SET @SQL = 
	N'
		CREATE TABLE ##tmpCaption ('+@TenCot_BangTam+')

		insert into ##tmpCaption
		SELECT '+@TenCot+'
		FROM 
		(	SELECT p.ControlID, case when P.ShowName = 1 then 1 else 0 end ShowName
			FROM sys_tblreportcaption (nolock) P
			where functionid = '''+@FunctionID +'''
		) p
		PIVOT
		(				
			max (ShowName)
			FOR ControlID  IN
			('+@TenCot+')
		) AS pvt1
	
	'

	exec(@SQL)

	Select
		case when cap.[CptLSCompanyID] = 0 then CP.LSCompanyCode else CASE WHEN @LanguageID='EN' THEN CP.[Name] ELSE CP.[VNName] END END AS CompanyCode,--cty ký
		case when cap.[CptLSLevel1ID] = 0 then L1.LSLevel1Code else CASE WHEN @LanguageID='EN' THEN L1.[Name] ELSE L1.[VNName] END END AS DivisionCode,--Don vi ký
		case when cap.[CptLSLevel2ID] = 0 then L2.LSLevel2Code else CASE WHEN @LanguageID='EN' THEN L2.[Name] ELSE L2.[VNName] END END AS DeptCode,
		case when cap.[CptLSLevel3ID] = 0 then L3.LSLevel3Code else CASE WHEN @LanguageID='EN' THEN L3.[Name] ELSE L3.[VNName] END END AS SectionCode,
		case when cap.[CptLSLevel4ID] = 0 then L4.LSLevel4Code else CASE WHEN @LanguageID='EN' THEN L4.[Name] ELSE L4.[VNName] END END AS LSLevel4Code,
		case when cap.[CptLSLevel5ID] = 0 then L5.LSLevel5Code else CASE WHEN @LanguageID='EN' THEN L5.[Name] ELSE L5.[VNName] END END AS LSLevel5Code,
		case when cap.[CptLSLevel6ID] = 0 then L6.LSLevel6Code else CASE WHEN @LanguageID='EN' THEN L6.[Name] ELSE L6.[VNName] END END AS LSLevel6Code,
		case when cap.[CptLSLevel7ID] = 0 then L7.LSLevel7Code else CASE WHEN @LanguageID='EN' THEN L7.[Name] ELSE L7.[VNName] END END AS LSLevel7Code,
		case when cap.[CptLSLevel8ID] = 0 then L8.LSLevel8Code else CASE WHEN @LanguageID='EN' THEN L8.[Name] ELSE L8.[VNName] END END AS LSLevel8Code,
		case when cap.[CptLSLevel9ID] = 0 then L9.LSLevel9Code else CASE WHEN @LanguageID='EN' THEN L9.[Name] ELSE L9.[VNName] END END AS LSLevel9Code,
	
		case when cap.[CptLSCapBacNhanVienID] = 0 then D.LSCapBacNhanVienCode else case when @LanguageID='VN' then D.VNName else D.Name end END as LSCapBacNhanVienCode,
		case when cap.[CptLSCapBacCongViecNoiBoID] = 0 then H.LSCapBacCongViecNoiBoCode else case when @LanguageID='VN' then H.VNName else H.Name end END As LSCapBacCongViecNoiBoCode, /*Rlog 20571 THienLK4 - DXG - 21/12/2023*/

		case when cap.[CptStrLSChucVuID] = 0 then CV.MaChucVu else case when @LanguageID='VN' then CV.TenChucVuV else CV.TenChucVuE end end as LSChucVuCode,
		case when cap.[CptStrLSJobTitleID] = 0 then E.LSJobTitleCode else case when @LanguageID='VN' then E.VNName else E.Name end end LSJobTitleCode,
		case when cap.[CptLSLoaiNhanVienID] = 0 then F.LSLoaiNhanVienCode else case when @LanguageID='VN' then F.VNName else F.Name end end LSLoaiNhanVienCode,
		case when cap.[CptLSLoaiLaoDongID] = 0 then LD.LSLoaiLaoDongCode else case when @LanguageID='VN' then LD.VNName else LD.Name end end LSLoaiLaoDongCode,
		case when cap.[CptLSLocationID] = 0 then G.LSLocationCode else case when @LanguageID='VN' then G.VNName else G.Name end end LSLocationCode,
		case when cap.[CptLSLoaiHinhNhanVienID] = 0 then lhnv.LSLoaiHinhNhanVienCode else Case when @LanguageID='VN' then lhnv.VNName else lhnv.Name end end AS LSLoaiHinhNhanVienCode,
		CONVERT(NVARCHAR,TL.NgayHieuLuc,103) AS NgayHieuLuc,

		TL.NoiKy,
		TL.GiayUyQuyen as TheoGiayUyQuyen,
		case when cap.[CptNguoiKy] = 0 then V.EmpCode else V.EmpName End AS EmpCode_NguoiKy,
		Case when @LanguageID='VN' then V.JobTitleVN else V.JobTitleEN end AS ChucDanh,
		--,TLCT.LoaiHD
		--,CASE WHEN @LanguageID='EN' THEN CT.[Name] ELSE CT.[VNName] END AS TenLoaiHD
		TL.Other1 AS OtherInfo1,
		TL.Other2 AS OtherInfo2,
		TL.Other3 AS OtherInfo3,
		TL.Other4 AS OtherInfo4,
		TL.Other5 AS OtherInfo5,
		TL.Other6 AS OtherInfo6,
		TL.Other7 AS OtherInfo7,
		TL.Other8 AS OtherInfo8,
		TL.Other9 AS OtherInfo9,
		TL.Other10 AS OtherInfo10
		--20151029: TrangNT: Bổ sung cột này, cộng chuỗi contract type name. Sửa lại lưới hiển thị 1 dòng cho 1 cấu hình, thay vì mỗi contract type là 1 dòng như hiện tại
		,dbo.HR_fnCongChuoiThietLapNguoiKy(TL.ThietLapID,@LanguageID,'ContractTypeName','- ',char(13)+char(10),'','','','','') as TenLoaiHD
		,case when cap.[CptStrLSChucVuID] = 0 then dbo.HR_fnCongChuoiThietLapNguoiKy(TL.ThietLapID,@LanguageID,'ContractTypeName','',',','1','','','','') else 
		dbo.HR_fnCongChuoiThietLapNguoiKy(TL.ThietLapID,@LanguageID,'ContractTypeName','- ',char(13)+char(10),'','','','','') end as strLSLoaiHopDongID
		, '@' + @strLSChucVuID, '%@' + convert(nvarchar,TL.LSChucVuID) + '@%'
		
		, CONVERT(nvarchar(10),TL.AuthorizationDate,103) AuthorizationDate --Rlog 19909 26/09/2023 ThienLK4
		,TL.Creater, TL.CreateDate, TL.Editer, TL.EditDate
		,r1.EmpName Reviewer1,r2.EmpName Reviewer2,r3.EmpName Reviewer3,r4.EmpName Reviewer4 /*Tamnb rlog 21379 vitaidairy*/
		,r1.EmpCode EmpCode_Reviewer1,r2.EmpCode EmpCode_Reviewer2,r3.EmpCode EmpCode_Reviewer3,r4.EmpCode EmpCode_Reviewer4
		--TanND35 RLogID 22946
		,V.EmpName AS EmpNameNguoiKy
	FROM HR_tblThietLapNguoiKyHD(NoLock) TL 
		LEFT JOIN dbo.HR_vEmp(NoLock) V ON V.empID=TL.EmpID
		--LEFT JOIN HR_tblThietLapNguoiKyHD_ChiTiet(NoLock) TLCT ON TL.ThietLapID=TLCT.ThietLapID
		LEFT JOIN dbo.LS_tblCompany(NoLock) CP ON TL.LSCompanyID=CP.LSCompanyID
		LEFT JOIN dbo.LS_tblLevel1(NoLock) L1 ON TL.LSLevel1ID=L1.LSLevel1ID
		LEFT JOIN dbo.LS_tblLevel2(NoLock) L2 ON TL.LSLevel2ID=L2.LSLevel2ID
		LEFT JOIN dbo.LS_tblLevel3(NoLock) L3 ON TL.LSLevel3ID=L3.LSLevel3ID
		LEFT JOIN dbo.LS_tblLevel4(NoLock) L4 ON TL.LSLevel4ID=L4.LSLevel4ID
		LEFT JOIN dbo.LS_tblLevel5(NoLock) L5 ON TL.LSLevel5ID=L5.LSLevel5ID
		LEFT JOIN dbo.LS_tblLevel6(NoLock) L6 ON TL.LSLevel6ID=L6.LSLevel6ID
		LEFT JOIN dbo.LS_tblLevel7(NoLock) L7 ON TL.LSLevel7ID=L7.LSLevel7ID
		LEFT JOIN dbo.LS_tblLevel8(NoLock) L8 ON TL.LSLevel8ID=L8.LSLevel8ID
		LEFT JOIN dbo.LS_tblLevel9(NoLock) L9 ON TL.LSLevel9ID=L9.LSLevel9ID
		left join LS_tblCapBacNhanVien(NoLock) D on TL.LSCapBacNhanVienID = D.LSCapBacNhanVienID
		left join LS_tblJobTitle(NoLock) E on TL.LSJobTitleID = E.LSJobTitleID
		left join LS_tblLoaiNhanVien(NoLock) F on TL.LSLoaiNhanVienID = F.LSLoaiNhanVienID
		left join LS_tblLoaiLaoDong(NoLock) LD on TL.LSLoaiLaoDongID = LD.LSLoaiLaoDongID
		LEFT JOIN dbo.LS_tblCapBacCongViecNoiBo (NOLOCK) H ON TL.LSCapBacCongViecNoiBoID = H.LSCapBacCongViecNoiBoID /*Rlog 20571 THienLK4 - DXG - 21/12/2023*/
		left join LS_tblLocation(NoLock) G on TL.LSLocationID = G.LSLocationID
		left join LS_tblChucVu(NoLock) CV on TL.LSChucVuID = CV.LSChucVuID
		--LEFT JOIN dbo.LS_tblContractType(NoLock) CT ON CT.LSContractTypeID=TLCT.LoaiHD
		--inner join dbo.fnGetAllLevel_Permission(@UserGroupID ,@FunctionID ,'Comp') B on B.strvalue = TL.LSCompanyID
		left join dbo.fnGetAllLevel_Permission(@UserGroupID ,@FunctionID ,'Comp') B on B.strvalue = TL.LSCompanyID
		left join dbo.fnGetAllLevel_Permission(@UserGroupID ,@FunctionID ,'Level1') C on C.strvalue = TL.LSLevel1ID
		--Join để lọc theo các loại hợp đồng được check
		Left join (
			Select Max(ThietLapChiTietID) ThietLapChiTietID, ThietLapID
			From HR_tblThietLapNguoiKyHD_ChiTiet(NoLock) A
			Where 1=1
			And (
					(@dsLoaiHDSearch <> '' and @dsLoaiHDSearch is not null  and ('@'+@dsLoaiHDSearch like '%@'+ A.LoaiHD+'@%'))
					or 
					(@dsLoaiHDSearch = '' or @dsLoaiHDSearch is null)
				)
			Group by ThietLapID
		) TLCT on TL.ThietLapID=TLCT.ThietLapID
		/*Start RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
		LEFT JOIN dbo.LS_tblHLevel1(NoLock) HL1 ON TL.LSHLevel1ID=HL1.LSHLevel1ID
		LEFT JOIN dbo.LS_tblHLevel2(NoLock) HL2 ON TL.LSHLevel2ID=HL2.LSHLevel2ID
		LEFT JOIN dbo.LS_tblHLevel3(NoLock) HL3 ON TL.LSHLevel3ID=HL3.LSHLevel3ID
		LEFT JOIN dbo.LS_tblHLevel4(NoLock) HL4 ON TL.LSHLevel4ID=HL4.LSHLevel4ID
		LEFT JOIN dbo.LS_tblHLevel5(NoLock) HL5 ON TL.LSHLevel5ID=HL5.LSHLevel5ID
		LEFT JOIN dbo.LS_tblHLevel6(NoLock) HL6 ON TL.LSHLevel6ID=HL6.LSHLevel6ID
		left join LS_tblLoaiHinhNhanVien(nolock) lhnv on TL.LSLoaiHinhNhanVienID = lhnv.LSLoaiHinhNhanVienID
		/*End   RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
		left join HR_vEmp (nolock) r1 on r1.EmpID = tl.Reviewer1
		left join HR_vEmp (nolock) r2 on r2.EmpID = tl.Reviewer2
		left join HR_vEmp (nolock) r3 on r3.EmpID = tl.Reviewer3
		left join HR_vEmp (nolock) r4 on r4.EmpID = tl.Reviewer4
		left join ##tmpCaption(nolock) cap on 1=1
	where 1=1 and (B.strvalue is not null or TL.LSCompanyID is null)
		and NgayHieuLuc between @dTuNgay and @dDenNgay
		and(@LSCompanyID is null or TL.LSCompanyID = @LSCompanyID)
		and(@LSLevel1ID is null or TL.LSLevel1ID = @LSLevel1ID)
		and(@LSLevel2ID is null or TL.LSLevel2ID = @LSLevel2ID)
		and(@LSLevel3ID is null or TL.LSLevel3ID = @LSLevel3ID)
		and(@LSLevel4ID is null or TL.LSLevel4ID = @LSLevel4ID)
		and(@LSLevel5ID is null or TL.LSLevel5ID = @LSLevel5ID)
		and(@LSLevel6ID is null or TL.LSLevel6ID = @LSLevel6ID)
		and(@LSLevel7ID is null or TL.LSLevel7ID = @LSLevel7ID)
		and(@LSLevel8ID is null or TL.LSLevel8ID = @LSLevel8ID)
		and(@LSLevel9ID is null or TL.LSLevel9ID = @LSLevel9ID)
		/*Start RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
		and(@LSHLevel1ID is null or TL.LSHLevel1ID = @LSHLevel1ID)
		and(@LSHLevel2ID is null or TL.LSHLevel2ID = @LSHLevel2ID)
		and(@LSHLevel3ID is null or TL.LSHLevel3ID = @LSHLevel3ID)
		and(@LSHLevel4ID is null or TL.LSHLevel4ID = @LSHLevel4ID)
		and(@LSHLevel5ID is null or TL.LSHLevel5ID = @LSHLevel5ID)
		and(@LSHLevel6ID is null or TL.LSHLevel6ID = @LSHLevel6ID)
		/*End   RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
		and(TL.LSLevel1ID is null or C.strvalue is not null)
		and(@TenNguoiKy='' or @TenNguoiKy is null or V.EmpName like N'%'+@TenNguoiKy+'%')
		--and(@dsLoaiHDSearch='' or @dsLoaiHDSearch is null or charindex('@'+ convert(nvarchar(12), CT.LSContractTypeID) +'@','@'+@dsLoaiHDSearch) <> 0)
		and(@LSCapBacNhanVienID = '' or @LSCapBacNhanVienID is null or TL.LSCapBacNhanVienID = @LSCapBacNhanVienID)
		AND(@LSCapBacCongViecNoiBoID = '' or @LSCapBacCongViecNoiBoID is null or TL.LSCapBacCongViecNoiBoID = @LSCapBacCongViecNoiBoID)/*Rlog 20571 THienLK4 - DXG - 21/12/2023*/
		--and(@LSJobTitleID = '' or @LSJobTitleID is null or TL.LSJobTitleID = @LSJobTitleID)
		and(@LSLoaiNhanVienID = '' or @LSLoaiNhanVienID is null or TL.LSLoaiNhanVienID = @LSLoaiNhanVienID)
		and(@LSLoaiLaoDongID = '' or @LSLoaiLaoDongID is null or TL.LSLoaiLaoDongID = @LSLoaiLaoDongID)
		and(@LSLocationID = '' or @LSLocationID is null or TL.LSLocationID = @LSLocationID)
		and(@LSNhomNhanVienID = '' or @LSNhomNhanVienID is null or TL.LSNhomNhanVienID = @LSNhomNhanVienID)
		--and(@LSChucVuID = '' or @LSChucVuID is null or TL.LSChucVuID = @LSChucVuID)
		and(
				@dsLoaiHDSearch='' or @dsLoaiHDSearch is null 
				or TLCT.ThietLapChiTietID is  not null
			)
		and(@strLSJobTitleID = '' or @strLSJobTitleID is null or '@' + @strLSJobTitleID like '%@' + convert(nvarchar,TL.LSJobTitleID) + '@%')
		--and(@strLSChucVuID = '' or @strLSChucVuID is null or '@' + @strLSChucVuID like '%@' + convert(nvarchar,TL.LSChucVuID) + '@%')
		and(@LSLoaiHinhNhanVienID is null or TL.LSLoaiHinhNhanVienID = @LSLoaiHinhNhanVienID)
	ORDER BY TL.NgayHieuLuc DESC, TL.LSCompanyID, Tl.LSLevel1ID, V.VfirstName, V.VlastName
	
	SET @ReturnMess=''
	SET @ReturnCode=''			
	--and charindex( '@'+ convert(nvarchar(12), CT.LSContractTypeID) +'@', @strContractType ) != 0
END
ELSE
if (@Activity= 'GetDataByID')
	BEGIN		
		Select TL.ThietLapID,TL.EmpID,TL.LSCompanyID,tlct.ThietLapChiTietID,TL.LSLevel1ID, 
			TL.LSLevel2ID,TL.LSLevel3ID,TL.LSLevel4ID,TL.LSLevel5ID,
			TL.LSLevel6ID,TL.LSLevel7ID,TL.LSLevel8ID,TL.LSLevel9ID,
			CASE WHEN @LanguageID='EN' THEN CP.[Name] ELSE CP.[VNName] END AS CompanyName,--cty ký
			CASE WHEN @LanguageID='EN' THEN L1.[Name] ELSE L1.[VNName] END AS Level1Name,--Don vi ký
			CONVERT(NVARCHAR,TL.NgayHieuLuc,103) AS NgayHieuLuc,TL.NoiKy, TL.GiayUyQuyen,
			CASE WHEN ISNULL(TL.TenNguoiKy, '') <> '' THEN TL.TenNguoiKy ELSE V.EmpName  END  TenNguoiKy,
			TLCT.LoaiHD,
			Case when @LanguageID='VN' then V.JobTitleVN else V.JobTitleEN end AS ChucDanh,
			CASE WHEN @LanguageID='EN' THEN CT.[Name] ELSE CT.[VNName] END AS TenLoaiHD,
			TL.Other1,TL.Other2,TL.Other3,TL.Other4,TL.Other5,TL.Other6,TL.Other7,TL.Other8,TL.Other9,TL.Other10,
			TL.LSCapBacNhanVienID,TL.LSJobTitleID,TL.LSLoaiNhanVienID,TL.LSLoaiLaoDongID, TL.LSLocationID, TL.LSNhomNhanVienID,TL.LSChucVuID,
			/*Start RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
			TL.LSHLevel1ID,TL.LSHLevel2ID,TL.LSHLevel3ID,TL.LSHLevel4ID,TL.LSHLevel5ID,TL.LSHLevel6ID
			/*End   RlogID: 15345 - CVN - NhanHM4 - 05/08/2020*/
			,TL.LSLoaiHinhNhanVienID, CONVERT(NVARCHAR(10),TL.AuthorizationDate,103) AuthorizationDate, TL.LSCapBacCongViecNoiBoID /*Rlog 20571 THienLK4 - DXG - 21/12/2023*/
			,TL.AttachFile
			,NguoiKyNhay,EmailVanThu,TaiKhoanVanThu
			,TL.Reviewer1,TL.Reviewer2,TL.Reviewer3,TL.Reviewer4 /*Tamnb rlog 21379*/
		FROM HR_tblThietLapNguoiKyHD(NoLock) TL 
			LEFT JOIN dbo.HR_vEmp(NoLock) V ON V.empID=TL.EmpID
			LEFT JOIN HR_tblThietLapNguoiKyHD_ChiTiet(NoLock) TLCT ON TL.ThietLapID=TLCT.ThietLapID
			LEFT JOIN dbo.LS_tblCompany(NoLock) CP ON TL.LSCompanyID=CP.LSCompanyID
			LEFT JOIN dbo.LS_tblLevel1(NoLock) L1 ON TL.LSLevel1ID=L1.LSLevel1ID
			LEFT JOIN dbo.LS_tblContractType(NoLock) CT ON CT.LSContractTypeID=TLCT.LoaiHD
			--left join HR_vEmp (nolock) r1 on r1.EmpID = tl.Reviewer1
			--left join HR_vEmp (nolock) r2 on r2.EmpID = tl.Reviewer2
			--left join HR_vEmp (nolock) r3 on r3.EmpID = tl.Reviewer3
			--left join HR_vEmp (nolock) r4 on r4.EmpID = tl.Reviewer4
		where TL.ThietLapID=@ThietLapID 
		SET @ReturnMess=''
		SET @ReturnCode=''
	END
if (@Activity= 'GetContractTypeByMaster')
	BEGIN		
		Select TLCT.LoaiHD
		From HR_tblThietLapNguoiKyHD_ChiTiet(NoLock) TLCT
		Where ThietLapID = @ThietLapID
	End
IF( @@ERROR<>0)
BEGIN
	SET @ReturnMess=@@ERROR
	SET @ReturnCode='0034'
	ROLLBACK
END

