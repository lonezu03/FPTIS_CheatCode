    USE [iHRP_V34_KPMG]
    GO
    /****** Object:  StoredProcedure [dbo].[HR_spfrmPASSPORTVISA]    Script Date: 5/5/2026 3:10:12 PM ******/
    SET ANSI_NULLS ON
    GO
    SET QUOTED_IDENTIFIER ON
    GO
    /*20160111_093251:QuangPNV-PC.fissoft.com(::1) Replace hàng loạt: "UserGroupID\s*NVARCHAR*\s*\(\d\d\)" thành "UserGroupID nvarchar(50)"*/


    ALTER PROCEDURE [dbo].[HR_spfrmPASSPORTVISA]	
    @UserGroupID nvarchar(50) = null,
    @FunctionID		nvarchar(20) = null,--nhac nho
    @IsThongBao		nvarchar(1) = null,--nhac nho
    @ThoiHanThongBao nvarchar(50) = null,--nhac nho

    @Activity		varchar(50),
    @LanguageID		nchar(2) = 'EN',
    @CountValue		INT	= 0 OUT, --QuangPNV : Tong hong bao cao
    @ReturnMess		nvarchar(500) = null out,
    @Where			nvarchar(4000) = null,

    @PassportVisaID	nvarchar(15) = null,
    @EmpID int = null,
    @EmpCode NVARCHAR(150) = null,
    @Type			tinyint = null,
    @No				nvarchar(50) = null,
    @IssueDate		nvarchar(10) = null,
    @ExpireDate		nvarchar(10) = null,
    @IssuePlace		nvarchar(150) = null,
    @PaidbyEmp		bit=null,
    @Note			nvarchar(4000) = null,
    @EffectiveDate	nvarchar(10) = null,
    @EndEffectDate	nvarchar(10) = null,
    @Status			NVARCHAR(12) = null,
    -----Visa----
    @Fee			nvarchar(50)=null,
    -----WP------
    @WPReturn		bit=null,
    @WPReturnDate	nvarchar(10)=null,
    -------------
    --bo sung theo UAT
    @LSPassportTypeID	nvarchar(15) = null,
    @Address			nvarchar(150) = NULL,
    @FromDate		NVARCHAR(10) = NULL,
    @ToDate			NVARCHAR(10) = NULL,
    @ChuCanHo		nvarchar(100) = NULL,
    @SoDienThoai    nvarchar(100) = NULL,
    @TienThueNha	nvarchar(50) = NULL,
    @LSCurrencyTypeID int = null,
    @TienDatCoc		nvarchar(50) = NULL,
    @AdvancedNoticeTime		nvarchar(255) = NULL,
    @TienThueNhaUSD		nvarchar(50) = NULL,
    @TerminationCondition		nvarchar(255) = NULL,
    @OtherInfo1		NVARCHAR(255) = NULL,
    @OtherInfo2		NVARCHAR(255) = NULL,
    @OtherInfo3		NVARCHAR(255) = NULL,
    @IsTuPhap		bit = null,
    @AttachFileID	nvarchar(20) = null,
    @IsWarningList			bit = 0,
    --Start Coding RlogID: 14819 - CVN - NhanHM4 - 30/12/2019
    @IssuePlace_Province INT = NULL
    --End   Coding RlogID: 14819 - CVN - NhanHM4 - 30/12/2019
    ,@LSLoaiVisaID  int = null --Rlog 15988 Bomnv 08/02/2021
    ,@IssuePlace_EN NVARCHAR(500) = NULL /*RlogID 16139 - VGU - 26/03/2021 - QuyenPV9*/
    ,@LSJobPositionForWorkPermitID INT = NULL /*RlogID 25189 - KPMG_V34*/
    ,@LSQuocGiaID_1 INT = NULL /*RlogID 25190 - KPMG_V34*/
    , @NameOnPassport NVARCHAR(500) = NULL
    ,@NameOnGPLX NVARCHAR(500) = NULL
    ,@LSQuocGiaID	NVARCHAR(500) = NULL --Rlog:18669 VuNH49 03/11/2022
    ,@LSLoaiGiayPhepLaoDongId nvarchar(12) = null --Rlog 18751,
    ,@LSLoaiLyLichTuPhapID nvarchar(12) = null --RL 19677 
    ,@TinhTrangAnTich nvarchar(4000) = null --RL 19677
    -- s anhtt189 rlog 20947
    ,@PassportVisaNCanhXCanhID		nvarchar(20) = null
    ,@NgayNhapCanh		NVARCHAR(100) = NULL
    ,@NgayXuatCanh		NVARCHAR(100) = NULL
    ,@ReturnID		nvarchar(12) =null output
    ,@ReturnMessCode		nvarchar(1) = null out
    ,@NgayLuuTruVN	int = null
    --e anhtt189 rlog 20947
    ,@LSLoaiGiayTamTruID		INT = NULL
    AS
    declare @ParamValue nvarchar(12),@dFromDate	datetime,
            @dToDate	datetime	,@dDateNow	datetime,
            @dEffDate	datetime	,@dExpDate	datetime,
            @dIssueDate	datetime	,@dNgayNhapCanh datetime,
            @dNgayXuatCanh datetime,
            @FeeMoney money,
            @FeeClean nvarchar(255)

    SET @dDateNow = CONVERT(DATETIME,CONVERT(NVARCHAR(10),GETDATE(),103),103)
    SET @dFromDate = CASE WHEN ISNULL(@FromDate,'') = '' THEN CONVERT(DATETIME,'01/01/1900',103) else CONVERT(DATETIME,@FromDate,103) end
    SET @dToDate = CASE WHEN ISNULL(@ToDate,'') = '' THEN CONVERT(DATETIME,'01/01/2100',103) else CONVERT(DATETIME,@ToDate,103) end
    set @dIssueDate = convert(datetime,@IssueDate,103)

    -- Normalize Fee input so it can be saved from UI formatted strings
    SET @FeeMoney = NULL
    SET @FeeClean = UPPER(LTRIM(RTRIM(ISNULL(@Fee, ''))))
    SET @FeeClean = REPLACE(@FeeClean, N'VNĐ', '')
    SET @FeeClean = REPLACE(@FeeClean, 'VND', '')
    SET @FeeClean = REPLACE(@FeeClean, N'Đ', '')
    SET @FeeClean = REPLACE(@FeeClean, N'₫', '')
    SET @FeeClean = REPLACE(@FeeClean, NCHAR(160), '')
    SET @FeeClean = REPLACE(@FeeClean, CHAR(9), '')
    SET @FeeClean = REPLACE(@FeeClean, ' ', '')

    IF ISNULL(@FeeClean, '') <> ''
    BEGIN
        SET @FeeMoney = COALESCE(
            TRY_CONVERT(money, @FeeClean),
            -- 1,234,567
            TRY_CONVERT(money, REPLACE(@FeeClean, ',', '')),
            -- 1.234.567
            TRY_CONVERT(money, REPLACE(@FeeClean, '.', '')),
            -- 1.234.567,89 -> 1234567.89
            TRY_CONVERT(money, REPLACE(REPLACE(@FeeClean, '.', ''), ',', '.')),
            -- fallback: remove both separators (works for integer VND)
            TRY_CONVERT(money, REPLACE(REPLACE(@FeeClean, '.', ''), ',', ''))
        )
    END
    if @LSPassportTypeID = '' SET @LSPassportTypeID = null 	
    if @Status = '' SET @Status = null
    if isnull(@LSCurrencyTypeID,'')='' set @LSCurrencyTypeID=null
    SET @IssuePlace_Province = CASE WHEN @IssuePlace_Province = '' THEN NULL ELSE @IssuePlace_Province END

    if isnull(@LSLoaiGiayPhepLaoDongId,'')='' set @LSLoaiGiayPhepLaoDongId=null

    set @LSLoaiVisaID  =  case when isnull(@LSLoaiVisaID,'')  ='' then NULL  else @LSLoaiVisaID end 
    set @LSQuocGiaID  =  case when isnull(@LSQuocGiaID,'')  ='' then NULL  else @LSQuocGiaID end 
    SET @dEffDate = convert(datetime,@EffectiveDate,103)

    SET @dNgayNhapCanh = convert(datetime,@NgayNhapCanh,103)
    SET @dNgayXuatCanh = convert(datetime,@NgayXuatCanh,103)

    IF OBJECT_ID('tempdb..#NgayXuatCanhNhapCanh') IS NOT NULL DROP TABLE #NgayXuatCanhNhapCanh -- anhtt189

    if @Activity = 'GetDataAll'
    begin
        Select * from HR_TBLPASSPORTVISA(NoLock)
    end	
        
    else if @Activity = 'UpdateNhacNhoHDThueNha'
        begin
            UPDATE dbo.SYS_tblParameters
            SET ParamValue=@IsThongBao
            where ParamName='HR_IsThongBaoHDThueNha'
            
            UPDATE dbo.SYS_tblParameters
            SET ParamValue=@ThoiHanThongBao
            where ParamName='HR_ThoiHanThongBaoHDThueNha'
        end
        
    else if @Activity = 'NhacNho'
    begin	
        DECLARE @isNhacNho	   int
        DECLARE @SoNgayNhacNho INT
        select @isNhacNho= tb.ParamValue from dbo.SYS_tblParameters(NoLock) tb where ParamName='HR_IsThongBaoHDThueNha'
        select @SoNgayNhacNho= tb.ParamValue from dbo.SYS_tblParameters(NoLock) tb where ParamName='HR_ThoiHanThongBaoHDThueNha'
        
        select @ParamValue=ParamValue from SYS_tblParameters(NoLock) where ParamName='HREmpID'
        select @EmpID=EmpID from UMS_tblUserAccount(NoLock) where UserGroupID=@UserGroupID
                        
        select count(*) as CountEmp --b.EmpID 
            from
            (
                select EmpID, max(EffectiveDate) EffectiveDate 
                from HR_TBLPASSPORTVISA
                where [type]=4
                Group by EmpID
            )B 
            inner join HR_TBLPASSPORTVISA(NoLock) C ON  C.EffectiveDate = B.EffectiveDate and C.EmpID = B.EmpID
            join HR_tblEmp(NOLOCK) CV  on CV.EmpID = C.EmpID
            inner join dbo.fnGetAllEmp_Permission(@UserGroupID,@FunctionID) D on B.EmpID = D.EmpID
        where CV.Active = 1
            and @isNhacNho=1	
            --QuangPNV : Phải dùng cách này để lấy ngày hiện tại 						
            and ISNULL(C.ExpireDate, C.EndEffectDate) between @dDateNow and dateadd(day,@SoNgayNhacNho,@dDateNow) 
            and  @ParamValue = @EmpID		
    end
    else if @Activity = 'DSHetHanHDThueNha'
    begin				
        select @SoNgayNhacNho= tb.ParamValue from dbo.SYS_tblParameters(NoLock) tb where ParamName='HR_ThoiHanThongBaoHDThueNha'
            
        /************
        SonPQ: Neu co thay doi so luong tham so trong activity nay thi vui long update tuong ung trong store HR_spfrmWarningList @Activity = 'LoadData'
        ************/	
        select * into #tempWaring from (
        select top 10000000

            B.EmpID, cv.EmpCode, cv.EmpName,
                cv.CompanyVN,cv.LSLevel1Code, CV.LSLevel2Code, CV.LSLevel3Code,
                case when @LanguageID= 'VN' then Com.VNName else Com.Name end AS LSCompanyName,
                case when @LanguageID= 'VN' then l1.VNName else l1.Name end AS LSLevel1Name,
                case when @LanguageID= 'VN' then l2.VNName else l2.Name end AS LSLevel2Name,
                case when @LanguageID= 'VN' then l3.VNName else l3.Name end AS LSLevel3Name,
                CONVERT(VARCHAR,B.EffectiveDate,103) AS EffectiveDate, convert(VARCHAR,B.ExpireDate,103) AS ExpireDate,
                B.[No] AS ContractNo,
                case when @LanguageID='VN' then N'Sắp đến ngày hết hạn hợp đồng thuê nhà' else N'Be about to house rental contract termination' end Warning,
                case when @LanguageID='VN' then N'Ngày hết hạn : ' else 'Effective to : ' end + convert(nvarchar,B.ExpireDate,103) WarningInfo,
                @SoNgayNhacNho WarningBefore
        /************
        SonPQ: Neu co thay doi so luong tham so trong activity nay thi vui long update tuong ung trong store HR_spfrmWarningList @Activity = 'LoadData'
        ************/		
        from
            (
                select EmpID, MAX([No]) AS [No], max(EffectiveDate) EffectiveDate, MAX(ExpireDate)  AS ExpireDate
                from HR_TBLPASSPORTVISA (Nolock) 
                where [type]=4
                Group by EmpID
            )B 
            left join HR_TBLPASSPORTVISA (Nolock) C ON  C.EffectiveDate = B.EffectiveDate and C.EmpID = B.EmpID and C.[Type]=4
            left join HR_vEmp (Nolock) CV  on CV.EmpID = C.EmpID		
            inner join dbo.fnGetAllEmp_Permission(@UserGroupID,@FunctionID) D on B.EmpID = D.EmpID
            left join LS_tblCompany(NoLock) com ON cv.LSCompanyID=com.LSCompanyID
            left join dbo.LS_tblLevel1(NoLock) l1 ON l1.LSLevel1ID=cv.LSLevel1ID
            left join dbo.LS_tblLevel2(Nolock) l2 ON l2.LSLevel2ID=cv.LSLevel2ID
            left join dbo.LS_tblLevel3(NoLock) l3 ON l3.LSLevel3ID=cv.LSLevel3ID
        where CV.Status = 1		
            --QuangPNV : Phải dùng cách này để lấy ngày hiện tại 			
            and ISNULL(C.ExpireDate, C.EndEffectDate) between @dDateNow and @dDateNow + @SoNgayNhacNho
            and 
            (
                B.EffectiveDate between @dFromDate and @dToDate 
                OR
                @dFromDate between B.EffectiveDate and B.ExpireDate
            )
            --DanL : 20120419 ==> Chỉ lấy NV được truyền vào (Sử dụng cho MyPage)
            and
            (
                @EmpID is null or @EmpID = '' or B.EmpID = @EmpID
            )
        ) AAA
            
        if (isnull(@IsWarningList, 0) = 0)
        begin
            select * from #tempWaring
        End
        else
        Begin
            select @CountValue = count(*) from #tempWaring
            select @CountValue CountEmp
        end
        
        drop table #tempWaring
    end
    --QuangPNV : Đếm số lượng danh sách nhân viên sắp hết hạn hợp đồng thuê nhà : Áp dụng cho tổng hợp cảnh báo
    else if @Activity = 'CountDSHetHanHDThueNha'
        begin				
            select @SoNgayNhacNho= tb.ParamValue from dbo.SYS_tblParameters (Nolock) tb where ParamName='HR_ThoiHanThongBaoHDThueNha'
                                    
            select  @CountValue = COUNT(B.EmpID) 
            from
            (
                select EmpID, MAX([No]) AS [No], max(EffectiveDate) EffectiveDate, MAX(ExpireDate)  AS ExpireDate
                from HR_TBLPASSPORTVISA (Nolock)
                where [type]=4
                Group by EmpID
            )B 
            left join HR_TBLPASSPORTVISA (Nolock) C ON  C.EffectiveDate = B.EffectiveDate and C.EmpID = B.EmpID
            left join HR_vEmp (Nolock) CV  on CV.EmpID = C.EmpID		
            inner join dbo.fnGetAllEmp_Permission(@UserGroupID,@FunctionID) D on B.EmpID = D.EmpID								
            where CV.Status = 1			
                --QuangPNV : Phải dùng cách này để lấy ngày hiện tại 			
                and ISNULL(C.ExpireDate, C.EndEffectDate) between @dDateNow and @dDateNow + @SoNgayNhacNho	
                --and ISNULL(C.ExpireDate, C.EndEffectDate) between getdate() and getdate()+@SoNgayNhacNho	
            GROUP BY B.EmpID					
        end	
    --End QuangPNV
    else if @Activity = 'CheckValid'
    Begin
        select	@dEffDate = convert(datetime,@EffectiveDate,103),
                @dExpDate = case when isnull(@ExpireDate,'')='' then '2100-01-01' else convert(datetime,@ExpireDate,103) end,
                @PassportVisaID = isnull(@PassportVisaID,'')
        ------------------
        if @Type = '0' or @Type = '1' or @Type = '2' 
        begin
            --Kiểm tra ngày cấp
            if exists
            (
                select top 1 1
                from HR_tblPassportVisa(NoLock)
                where 1=1
                    and EmpID = @EmpID
                    and [Type] = @Type
                    and IssueDate = @dIssueDate
                    and PassportVisaID <> @PassportVisaID
            )
            begin
            
                set @ReturnMess = case	when @LanguageID = 'VN' then N'Ngày cấp này đã tồn tại. Vui lòng kiểm tra lại'
                                        else N'This issued date already existed. Please check again'
                                end
                return
            end
            -------------------
            declare @NoCheckDuplicateViSaPassport bit,
                    @ReturnMess1	nvarchar(255),
                    @ReturnMess2	nvarchar(255)

            select	@NoCheckDuplicateViSaPassport = NoCheckDuplicateViSaPassport from HR_tblSetupHR(NoLock)
            set		@NoCheckDuplicateViSaPassport = isnull(@NoCheckDuplicateViSaPassport,0)
            --------------------------------
            
            if exists
            (
                select top 1 1
                from HR_TBLPASSPORTVISA(NoLock)
                where 1=1
                    and [No] = @No
                    and [Type] = @Type
                    and PassportVisaID <> isnull(@PassportVisaID,'')
            )
            begin
                if @LanguageID = 'VN'
                    set @ReturnMess1 = N'Mã này đã tồn tại. Xin nhập vào mã khác.'
                else
                    set @ReturnMess1 = N'This code was existed. Please check again.'

                if @NoCheckDuplicateViSaPassport = 0
                begin
                    set @ReturnMess = @ReturnMess1
                    return
                end
            end
            
                
            If exists
            (
                select top 1 1 from HR_TBLPASSPORTVISA(NoLock)
                where 1=1
                    and EmpID = @EmpID 
                    and [Type] = @Type
                    and PassportVisaID <> @PassportVisaID
                    and 
                    (
                        (EffectiveDate between @dEffDate and @dExpDate)
                        or
                        (case when [ExpireDate] is null then '2100-01-01' else [ExpireDate] end between @dEffDate and @dExpDate)
                    )	
            )
            Begin
                set @ReturnMess2 = dbo.SYS_fnGetMess('0024', @LanguageID)

                if @NoCheckDuplicateViSaPassport = 0
                begin
                    set @ReturnMess = @ReturnMess2
                    return
                end
            End
            
            if @NoCheckDuplicateViSaPassport = 1 and isnull(@ReturnMess1,'')<>'' and isnull(@ReturnMess2,'')<>''
            begin
                set @ReturnMess = @ReturnMess2
                return
            end
        end
        ------------------------------------------------------------------------
        else
        begin
            If exists(	select top 1 1 from HR_TBLPASSPORTVISA
                        where EmpID = @EmpID and Type = @Type
                            and IssueDate = @dIssueDate
                            and PassportVisaID <> @PassportVisaID
                        )
            Begin
                set @ReturnMess = dbo.SYS_fnGetMess('0024', @LanguageID)
                return
            End	
            
            If exists(	select top 1 1 from HR_TBLPASSPORTVISA(NoLock)
                            where EmpID = @EmpID and Type = @Type
                                and EffectiveDate = @dEffDate
                                and PassportVisaID <> @PassportVisaID
                        ) 
            Begin
                set @ReturnMess = dbo.SYS_fnGetMess('V2_PC_0001', @LanguageID)
                return
            End	
        end
        IF @Type = '6' 
            BEGIN
                if exists
                (
                    select top 1 1
                    from HR_TBLPASSPORTVISA(NoLock)
                    where 1=1
                        and [No] = @No
                        and [Type] = @Type
                        and PassportVisaID <> isnull(@PassportVisaID,'')
                )
                BEGIN
                    SET @ReturnMess = CASE WHEN @LanguageID = 'VN' THEN  N'Mã này đã tồn tại. Xin nhập vào mã khác.' ELSE  N'This code was existed. Please check again.' END
                    RETURN
                END
            END
        print(@ReturnMess)
    End
    else if @Activity = 'AddNew'
    begin
        --Update Seq - 25/01/2019 - NhanHM4
        EXEC [dbo].[SYS_spGetAutoID_UpdateSeq] @TableName='HR_TBLPASSPORTVISA',@ColumnName='PassportVisaID',@Seq=@PassportVisaID OUTPUT

            insert into HR_TBLPASSPORTVISA		
            (
                PassportVisaID,EmpID,Type,No,IssueDate,ExpireDate,IssuePlace,Note,EffectiveDate,EndEffectDate,Status,LSPassportTypeID,
                Address, ChuCanHo, SoDienThoai,TienThueNha,LSCurrencyTypeID, TienDatCoc,OtherInfo1,OtherInfo2,OtherInfo3,PaidbyEmp,
                [Return],ReturnDate,Fee,IsTuPhap,AttachFileID, Creater, CreateTime, TienThueNhaUSD, AdvancedNoticeTime, TerminationCondition
                ,IssuePlace_Province ,LSLoaiVisaID, IssuePlace_EN, NameOnPassport,NameOnGPLX
                ,LSQuocGiaID, LSLoaiGiayPhepLaoDongID, LSLoaiLyLichTuPhapID, TinhTrangAnTich
                ,LSJobPositionForWorkPermitID
                ,LSQuocGiaID_1
                ,LSLoaiGiayTamTruID
            )
            values
            (
                @PassportVisaID,
                @EmpID,
                @Type,
                @No,
                (
                    case when @IssueDate<>'' then @dIssueDate else null end
                ), 
                (
                    case when @ExpireDate<>'' then convert(datetime,@ExpireDate,103) else null end
                ), 			
                @IssuePlace,
                @Note,
                (	
                    case when @EffectiveDate<>'' then convert(datetime,@EffectiveDate,103) else null end
                ), 
                (
                    case when @EndEffectDate<>'' then convert(datetime,@EndEffectDate,103) else null end
                ), 
                @Status,
                --
                @LSPassportTypeID,
                @Address,
                @ChuCanHo, @SoDienThoai, 
                convert(money, @TienThueNha),@LSCurrencyTypeID, convert(money,@TienDatCoc),
                @OtherInfo1,@OtherInfo2,@OtherInfo3,@PaidbyEmp,
                @WPReturn,
                case when @WPReturn=1 then convert(datetime,@WPReturnDate,103) else null end,
                @FeeMoney,
                @IsTuPhap,@AttachFileID, @UserGroupID, getdate(),
                convert(money,@TienThueNhaUSD), @AdvancedNoticeTime, @TerminationCondition
                ,@IssuePlace_Province ,@LSLoaiVisaID, @IssuePlace_EN, @NameOnPassport,@NameOnGPLX
                ,@LSQuocGiaID
                ,@LSLoaiGiayPhepLaoDongId
                , @LSLoaiLyLichTuPhapID
                , @TinhTrangAnTich
                ,@LSJobPositionForWorkPermitID
                ,@LSQuocGiaID_1
                ,@LSLoaiGiayTamTruID
            )	

            SET @ReturnID = @PassportVisaID
            SET @ReturnMessCode = '1'
            SET @ReturnMess = dbo.SYS_fnGetMess('0046', @LanguageID)
        end

    else If @Activity ='Save'
        begin
        
            if exists (select * from HR_TBLPASSPORTVISA where No = @No and EmpID<>@EmpID )
            begin
                if @LanguageID='VN'
                    set @ReturnMess=N'Số hộ chiếu / visa  này đã tồn tại. Xin nhập vào số khác.'
                else if @LanguageID='EN'
                    set @ReturnMess=N'This number was existed. Please check again.'
                Return
            end
            
            If exists
                (
                    select top 1 1 from HR_TBLPASSPORTVISA
                    where 1=1
                        and EmpID = @EmpID
                        and Type = @Type
                        and PassportVisaID <> @PassportVisaID
                        and
                        (
                            IssueDate = @dIssueDate
                            or
                            EffectiveDate = convert(datetime, @EffectiveDate, 103)
                        )
                )
            Begin
                set @ReturnMess = dbo.SYS_fnGetMess('0024', @LanguageID)
                return
            End
                
            --Update Seq - 25/01/2019 - NhanHM4
            EXEC [dbo].[SYS_spGetAutoID_UpdateSeq] @TableName='HR_TBLPASSPORTVISA',@ColumnName='PassportVisaID',@Seq=@PassportVisaID OUTPUT

            INSERT INTO HR_TBLPASSPORTVISA
            (
                PassportVisaID,EmpID,Type,[No],IssueDate,EffectiveDate,ExpireDate,IssuePlace,
                ChuCanHo, SoDienThoai, TienThueNha,TienDatCoc,Creater, CreateTime, Address
                ,TienThueNhaUSD, AdvancedNoticeTime, TerminationCondition, IssuePlace_Province,LSLoaiVisaID,IssuePlace_EN, NameOnPassport
                ,LSQuocGiaID, LSLoaiGiayPhepLaoDongID, LSLoaiLyLichTuPhapID, TinhTrangAnTich,LSJobPositionForWorkPermitID,LSQuocGiaID_1
                ,LSLoaiGiayTamTruID, Fee
            )
            VALUES
            (
                @PassportVisaID,@EmpID,@Type,@No,@dIssueDate,convert(datetime,@EffectiveDate,103), convert(datetime,@ExpireDate,103), @IssuePlace,
                @ChuCanHo, @SoDienThoai, convert(money, @TienThueNha), convert(money,@TienDatCoc),@UserGroupID, getdate(), @Address
                ,convert(money, @TienThueNhaUSD), @AdvancedNoticeTime, @TerminationCondition, @IssuePlace_Province,@LSLoaiVisaID,@IssuePlace_EN, @NameOnPassport
                ,@LSQuocGiaID, @LSLoaiGiayPhepLaoDongID, @LSLoaiLyLichTuPhapID, @TinhTrangAnTich,@LSJobPositionForWorkPermitID,@LSQuocGiaID_1
                ,@LSLoaiGiayTamTruID,
                @FeeMoney
            )	
            
            SET @ReturnID = @PassportVisaID
            SET @ReturnMessCode = '1'
            SET @ReturnMess = dbo.SYS_fnGetMess('0044', @LanguageID)
            --HuyenHB : Ghi log ------------------------------------------------------------
            Declare @IsWriteLog_ bit
            Declare @IDLog_Update nvarchar(20)
            Declare @IDLog nvarchar(20)
            Declare @XML_Insert nvarchar(max), @XML_Update nvarchar(max)
                    set @XML_Insert = ''
                    set @XML_Update = ''
            
            if exists(select top 1 1 from SYS_tblLogDataTableName(NoLock) where TableName='HR_TBLPASSPORTVISA' and IsWriteLog=1)
                set @IsWriteLog_ = 1
            --##### End HuyenHB------------------------------------------	
            --LamNT22-11062015-5897: Ghi log
            --HuyenHB: ghi Log 
            if (@IsWriteLog_ = 1)
            begin
                Set @Xml_Insert = 
                    (
                        select convert(varchar(12),B.PassportVisaID) + ','
                        from dbo.HR_TBLPASSPORTVISA (Nolock) B
                        where B.PassportVisaID = @PassportVisaID
                        For XML Path('')				
                    )
                
                exec [dbo].[TS_spfrmLogData_Save] @UserID=@UserGroupID,@TableName='HR_TBLPASSPORTVISALog',@Action='Save',@IsLogNew=0,@Xml=@Xml_Insert,@IDLog=@IDLog OUTPUT
                exec [dbo].[TS_spfrmLogData_Save] @UserID=@UserGroupID,@TableName='HR_TBLPASSPORTVISALog',@Action='Save',@IsLogNew=1,@Xml=@Xml_Insert,@IDLog=@IDLog									 
            end												
            --------------------------------------------------------------------------------------
        end

    else If @Activity = 'Update'
    begin
        --LamNT22-11062015-5897: Ghi log 
        if exists(select top 1 1 from SYS_tblLogDataTableName(NoLock) where TableName='HR_TBLPASSPORTVISA' and IsWriteLog=1)
                set @IsWriteLog_ = 1
        --HuyenHB: Ghi log
        if (@IsWriteLog_ = 1)
        begin
            Set @Xml_Update = 
                (
                    select convert(varchar(12),B.PassportVisaID) + ','
                    from dbo.HR_TBLPASSPORTVISA (Nolock) B
                    where B.PassportVisaID = @PassportVisaID
                    For XML Path('')
                )						
                
            if(isnull(@Xml_Update,'') <> '')
            begin
                exec [dbo].[TS_spfrmLogData_Save] @UserID=@UserGroupID,@TableName='HR_TBLPASSPORTVISALog',@Action='Update',@IsLogNew=0,@Xml=@Xml_Update,@IDLog=@IDLog_Update OUTPUT
            end
        end	
        if @Type = 0 -- Type = 0 :work permit			
            begin
                UPDATE HR_TBLPASSPORTVISA
                SET			
                    Type = @Type,
                    No = @No,
                    IssueDate = @dIssueDate,
                    EffectiveDate=(case when @EffectiveDate<>'' then convert(datetime,@EffectiveDate,103)
                                    else null
                                end),
                    ExpireDate = (case when @ExpireDate<>'' then convert(datetime,@ExpireDate,103)
                                    else null
                                end)
                    ,IssuePlace = @IssuePlace
                    ,IssuePlace_Province = @IssuePlace_Province
                    ,Note = @Note						
                    ,Status=@Status
                    ,OtherInfo1 = @OtherInfo1
                    ,OtherInfo2=@OtherInfo2
                    ,OtherInfo3=@OtherInfo3
                    ,[Return]=@WPReturn
                    ,ReturnDate=case when @WPReturn=1 then convert(datetime,@WPReturnDate,103) else null end
                    ,IsTuPhap = @IsTuPhap
                    ,AttachFileID = @AttachFileID
                    ,Editer = @UserGroupID
                    ,IssuePlace_EN = @IssuePlace_EN
                    ,LSJobPositionForWorkPermitID = @LSJobPositionForWorkPermitID				
                    ,EditTime = getdate()
                    ,LSLoaiGiayPhepLaoDongID = @LSLoaiGiayPhepLaoDongID
                where PassportVisaID = @PassportVisaID
            end			
        if @Type = 1 -- Type = 1 :passport				
            begin
                UPDATE HR_TBLPASSPORTVISA
                SET			
                    Type = @Type,
                    No = @No,
                    IssueDate = @dIssueDate,
                    EffectiveDate = (case when @EffectiveDate<>'' then convert(datetime,@EffectiveDate,103)
                                    else null
                                end),
                    ExpireDate = case when isnull(@ExpireDate,'')='' then null else convert(datetime,@ExpireDate,103) end,
                    EndEffectDate = (case when @EndEffectDate<>'' then convert(datetime,@EndEffectDate,103)
                                    else null
                                end),
                    
                    IssuePlace = @IssuePlace,
                    IssuePlace_Province = @IssuePlace_Province,
                    Status=@Status,
                    Note = @Note,
                    LSPassportTypeID=@LSPassportTypeID,
                    OtherInfo1 = @OtherInfo1
                    ,OtherInfo2=@OtherInfo2
                    ,OtherInfo3=@OtherInfo3
                    ,AttachFileID = @AttachFileID
                    ,IssuePlace_EN = @IssuePlace_EN
                    ,LSQuocGiaID_1 = @LSQuocGiaID_1
                    ,Editer = @UserGroupID
                    ,NameOnPassport = @NameOnPassport
                    ,EditTime = getdate()											
                where PassportVisaID = @PassportVisaID
            end
        if @Type = 2 -- Type = 2 :Visa				
            begin
                UPDATE HR_TBLPASSPORTVISA
                SET			
                    Type = @Type,
                    No = @No,
                    IssueDate = @dIssueDate,
                    EffectiveDate = (case when @EffectiveDate<>'' then convert(datetime,@EffectiveDate,103)
                                    else null
                                end),
                    ExpireDate = (case when @ExpireDate<>'' then convert(datetime,@ExpireDate,103)
                                    else null
                                end)
                    ,IssuePlace = @IssuePlace
                    ,IssuePlace_Province = @IssuePlace_Province
                    ,Note = @Note
                    ,Status=@Status
                    ,OtherInfo1 = @OtherInfo1
                    ,OtherInfo2=@OtherInfo2
                    ,OtherInfo3=@OtherInfo3		
                    ,PaidbyEmp=@PaidbyEmp
                    ,Fee=@FeeMoney
                    ,AttachFileID = @AttachFileID
                    ,LSQuocGiaID_1 = @LSQuocGiaID_1
                    ,Editer = @UserGroupID
                    ,EditTime = getdate()
                    ,LSLoaiVisaID = @LSLoaiVisaID
                    ,IssuePlace_EN = @IssuePlace_EN
                    ,LSQuocGiaID = @LSQuocGiaID
                where PassportVisaID = @PassportVisaID
            end	
        if @Type = 3 -- Type = 3 :temp licence		
            UPDATE HR_TBLPASSPORTVISA
            SET	
                No = @No,
                Type = @Type,					
                IssueDate = @dIssueDate,
                EffectiveDate = (case when @EffectiveDate<>'' then convert(datetime,@EffectiveDate,103)
                                    else null
                                end),
                ExpireDate = (case when @ExpireDate<>'' then convert(datetime,@ExpireDate,103)
                                    else null
                                end),
                IssuePlace = @IssuePlace,
                IssuePlace_Province = @IssuePlace_Province,
                Note = @Note,						
                Status=@Status,
                Address=@Address,		
                OtherInfo1 = @OtherInfo1
                ,OtherInfo2=@OtherInfo2
                ,OtherInfo3=@OtherInfo3		
                ,AttachFileID = @AttachFileID
                ,Editer = @UserGroupID
                ,EditTime = getdate()
                ,IssuePlace_EN = @IssuePlace_EN
                ,LSLoaiGiayTamTruID = @LSLoaiGiayTamTruID
            where PassportVisaID = @PassportVisaID
        --Select * from HR_TBLPASSPORTVISA
        if(@Type=4)--Loai Thue nha
            UPDATE HR_TBLPASSPORTVISA
            SET No = @No, 
                Type = @Type,
                EffectiveDate=convert(datetime,@EffectiveDate,103),
                IssueDate = @dIssueDate,
                ExpireDate = (case when @ExpireDate<>'' then convert(datetime,@ExpireDate,103) else NULL end),
                Note = @Note,						
                Status=@Status,
                Address=@Address,	
                ChuCanHo=@ChuCanHo, 
                SoDienThoai=@SoDienThoai, 
                TienThueNha=convert(money, @TienThueNha), 
                LSCurrencyTypeID = @LSCurrencyTypeID,
                TienDatCoc=convert(money,@TienDatCoc)
                ,		

                    OtherInfo1 = @OtherInfo1
                    ,OtherInfo2=@OtherInfo2
                    ,OtherInfo3=@OtherInfo3
                    ,AttachFileID = @AttachFileID
                    ,Editer = @UserGroupID
                    ,EditTime = getdate()
                    , TienThueNhaUSD=convert(money, @TienThueNhaUSD)
                    , AdvancedNoticeTime = @AdvancedNoticeTime
                    , TerminationCondition = @TerminationCondition
            where PassportVisaID = @PassportVisaID
        if(@Type=5)
            UPDATE HR_TBLPASSPORTVISA
            SET IssueDate = @dIssueDate
                ,IssuePlace_Province = @IssuePlace_Province
                ,ExpireDate = (case when @ExpireDate<>'' then convert(datetime,@ExpireDate,103) else NULL end)
                ,Editer = @UserGroupID
                ,NameONGPLX = @NameONGPLX
                ,AttachFileID = @AttachFileID
                ,EditTime = getdate()
            where PassportVisaID = @PassportVisaID
        if(@Type = 6)
        BEGIN
            UPDATE HR_TBLPASSPORTVISA
            SET IssueDate = @dIssueDate
                ,IssuePlace = @IssuePlace
                ,IssuePlace_Province = @IssuePlace_Province
                ,TinhTrangAnTich = @TinhTrangAnTich
                ,LSLoaiLyLichTuPhapID = @LSLoaiLyLichTuPhapID
                ,No = @No
                ,Note = @Note	
                ,OtherInfo1 = @OtherInfo1
                ,OtherInfo2=@OtherInfo2
                ,OtherInfo3=@OtherInfo3
                ,Editer = @UserGroupID
                ,AttachFileID = @AttachFileID
                ,EditTime = getdate()
            WHERE PassportVisaID = @PassportVisaID
        END
        SET @ReturnID = @PassportVisaID
        SET @ReturnMessCode = '1'
        SET @ReturnMess = dbo.SYS_fnGetMess('0044', @LanguageID)
        --HuyenHB: Ghi log
        if (@IsWriteLog_ = 1 and isnull(@Xml_Update,'') <> '')
        begin
            exec [dbo].[TS_spfrmLogData_Save] @UserID=@UserGroupID,@TableName='HR_TBLPASSPORTVISALog',@Action='Update',@IsLogNew=1,@Xml=@Xml_Update,@IDLog=@IDLog_Update
        end
    end

    else If @Activity = 'GetDataByID'
        begin
            select
                A.PassportVisaID, EmpID, Type, No, convert(varchar(10),IssueDate, 103) as IssueDate, convert(varchar(10),EffectiveDate, 103) as EffectiveDate, convert(varchar(10),ExpireDate, 103) as ExpireDate, IssuePlace,
                ChuCanHo, SoDienThoai, convert(Decimal(20,2),TienThueNha) as TienThueNha, convert(Decimal(20,2),TienDatCoc) as TienDatCoc, Status, Note, LSPassportTypeID, Address
                ,A.OtherInfo1, A.OtherInfo2, A.OtherInfo3, A.LSCurrencyTypeID, isnull(PaidbyEmp,0) PaidbyEmp, isnull([Return],0) [Return],convert(varchar(10),[ReturnDate], 103) [ReturnDate],
                CASE
                    WHEN Fee IS NULL THEN NULL
                    WHEN Fee < 0 THEN '-' + dbo.fnConvertNumber(ABS(Fee))
                    ELSE dbo.fnConvertNumber(Fee)
                END AS Fee,
                AttachFileID, isnull(IsTuPhap,0) IsTuPhap
                ,convert(Decimal(20,2),TienThueNhaUSD) as TienThueNhaUSD, AdvancedNoticeTime, TerminationCondition, IssuePlace_Province, LSLoaiVisaID, IssuePlace_EN, NameOnPassport,NameOnGPLX
                ,LSQuocGiaID, LSLoaiGiayPhepLaoDongID as LSLoaiGiayPhepLaoDong
                ,TinhTrangAnTich
                ,LSLoaiLyLichTuPhapID
                ,B.NgayNhapCanh, B.NgayXuatCanh, A.LSJobPositionForWorkPermitID, A.LSQuocGiaID_1
                ,A.LSLoaiGiayTamTruID
            from HR_TBLPASSPORTVISA(NOLOCK) A
            left join HR_tblPassportVisaNgayNhapCanh B (nolock) ON  B.PassportVisaID = A.PassportVisaID
            where A.PassportVisaID = @PassportVisaID
        end
        
    else If @Activity = 'GetDataByEmpID'
        begin
            
            select  NXC.PassportVisaID, NXC.NgayNhapCanh, NXC.NgayXuatCanh,
                    ROW_NUMBER() over(order by NXC.PassportVisaID, convert(date,NXC.NgayNhapCanh,103) asc) STT
            into	#tmpData
            from	HR_TBLPASSPORTVISA (Nolock) A
                    LEFT JOIN HR_tblPassportVisaNgayNhapCanh (nolock) NXC ON NXC.PassportVisaID = A.PassportVisaID
            where	1=1
                    and EmpID = @EmpID 
                    and Type = @Type	
            
            select
                A.PassportVisaID, 			
                A.Type, 						
                (case when A.Status<>0 then A.Status
                    else ''
                end) as Status,No,
                convert(varchar(10),A.IssueDate, 103) as IssueDate, 
                convert(varchar(10),A.ExpireDate, 103) as ExpireDate,
                A.IssuePlace,
                A.Note,
                convert(varchar(10),A.EffectiveDate, 103) as EffectiveDate,
                convert(varchar(10),A.EndEffectDate, 103) as EndEffectDate,
                --
                A.LSPassportTypeID,
                A.Address,
                A.ChuCanHo, A.SoDienThoai
                , dbo.fnConvertNumber(A.TienThueNhaUSD) AS TienThueNhaUSD
                , A.AdvancedNoticeTime
                , A.TerminationCondition
                , dbo.fnConvertNumber(A.TienThueNha) AS TienThueNha
                , dbo.fnConvertNumber(A.TienDatCoc) AS TienDatCoc		,
                A.OtherInfo1,A.OtherInfo2,A.OtherInfo3	, 
                A.LSCurrencyTypeID,case when @LanguageID='VN' then B.VNName when @LanguageID='CN' then B.CNName else B.Name end as LoaiTienTe,
                case when isnull(PaidbyEmp,0)=1 then 'x' else '' end PaidbyEmp,
                case when isnull([Return],0)=1 then 'x' else '' end [Return],
                convert(nvarchar,ReturnDate,103) ReturnDate,
                CASE
                    WHEN Fee IS NULL THEN NULL
                    WHEN Fee < 0 THEN '-' + dbo.fnConvertNumber(ABS(Fee))
                    ELSE dbo.fnConvertNumber(Fee)
                END Fee,
                case when @LanguageID='VN' then C.VNName when @LanguageID='CN' then C.CNName else C.Name end StatusName,
                case when isnull(A.IsTuPhap,0)=1 then 'x' else '' end IsTuPhap, A.AttachFileID,
                case when @LanguageID='VN' then D.VNName when @LanguageID='CN' then D.CNName else D.Name end PassportTypeName,
                case when @LanguageID='VN' then IS_P.VNName when @LanguageID='CN' then IS_P.CNName else IS_P.Name end IssuePlace_Province
                ,case when @LanguageID='VN' then LVS.VNName  else LVS.Name end LoaiVisa, A.IssuePlace_EN, A.NameOnPassport, A.NameOnGPLX
                ,case when @LanguageID='VN' then QG.VNName  else QG.Name end LSQuocGiaID
                ,case when @LanguageID='VN' then QG.VNName  else QG.Name end QuocGia
                ,case when @LanguageID='VN' then LGPLD.VNName  else LGPLD.Name end LSLoaiGiayPhepLaoDongName
                ,case when @LanguageID='VN' then LLTP.VNName  else LLTP.Name end LoaiLyLichTuPhapName
                ,case when @LanguageID='VN' then JPW.VNName  else JPW.Name end JobPositionForWorkPermit
                ,case when @LanguageID='VN' then QG1.VNName  else QG1.Name end QuocGia_1
                ,TinhTrangAnTich
                , A.Editer
                , Convert(Nvarchar(10), A.EditTime, 103) EditTime
                , A.Creater
                , Convert(Nvarchar(10), A.CreateTime, 103) CreateTime
                ,NgayXuatNhapCanh.NgayXuatNhapCanh  as NgayXuatNhapCanhVS--anhtt189 rlog 20947
                ,CASE @LanguageID WHEN 'VN' THEN GTT.VNName ELSE GTT.[Name] END LoaiGiayTamTru
            from HR_TBLPASSPORTVISA (Nolock) A
                left join dbo.LS_tblCurrencyType(NoLock) B on A.LSCurrencyTypeID = B.LSCurrencyTypeID
                left join LS_tblForeignerInfoStatus(NoLock) C on A.Status = C.ForeignerInfoStatusID
                left join LS_tblPassportType (nolock) D on D.LSPassportTypeID = A.LSPassportTypeID
                LEFT JOIN dbo.LS_tblProvince(NOLOCK) IS_P ON IS_P.LSProvinceID = A.IssuePlace_Province
                LEFT JOIN LS_tblLoaiVisa  (NOLOCK) LVS ON LVS.LSLoaiVisaID = A.LSLoaiVisaID
                LEFT JOIN LS_TBLQuocGia (NOLOCK) QG ON QG.LSQuocGiaID = A.LSQuocGiaID
                LEFT JOIN LS_TBLLoaiGiayPhepLaoDong (NOLOCK) LGPLD ON LGPLD.LSLoaiGiayPhepLaoDongID = A.LSLoaiGiayPhepLaoDongID
                LEFT JOIN LS_tblLoaiLyLichTuPhap (NOLOCK) LLTP ON LLTP.LSLoaiLyLichTuPhapID = A.LSLoaiLyLichTuPhapID
                LEFT JOIN LS_tblJobPositionForWorkPermit (NOLOCK) JPW ON JPW.LSJobPositionForWorkPermitID = A.LSJobPositionForWorkPermitID
                LEFT JOIN LS_tblQuocGia (NOLOCK) QG1 ON QG1.LSQuocGiaID = A.LSQuocGiaID_1
                LEFT JOIN dbo.LS_tblLoaiGiayTamTru (NOLOCK) GTT ON GTT.LSLoaiGiayTamTruID = A.LSLoaiGiayTamTruID
                OUTER APPLY (
                --anhtt189 rlog 20947
                SELECT
                    STRING_AGG(
                        '- ' + CONVERT(NVARCHAR(10), CONVERT(DATE, NXC.NgayNhapCanh, 103), 103) +
                        CASE
                            WHEN NXC.NgayXuatCanh IS NOT NULL THEN ' - ' + CONVERT(NVARCHAR(10), CONVERT(DATE, NXC.NgayXuatCanh, 103), 103)
                            ELSE ''
                        END +
                        N': Ngày: ' +
                        CONVERT(
                            NVARCHAR(10), 
                            DATEDIFF(DAY, 
                                CONVERT(DATE, NXC.NgayNhapCanh, 103), 
                                COALESCE(CONVERT(DATE, NXC.NgayXuatCanh, 103), CONVERT(DATE, NXC.NgayNhapCanh, 103))
                            ) + CASE
                                    WHEN NXC.NgayXuatCanh IS NOT NULL THEN 1
                                    ELSE 0
                                END
                        ),
                        CHAR(13) + CHAR(10)
                    ) AS NgayXuatNhapCanh
                FROM	#tmpData NXC
                WHERE	NXC.PassportVisaID = A.PassportVisaID
            ) AS NgayXuatNhapCanh
            --e anhtt189 rlog 20947
            where 1=1
                and EmpID = @EmpID 
                and Type = @Type	
            order by A.IssueDate DESC 	
        end

    else If @Activity = 'Delete'
        begin
            --LamNT22-11062015-5897: Ghi log 
            --HuyenHB: Ghi log
            if exists(select top 1 1 from SYS_tblLogDataTableName (NoLock) where TableName='HR_TBLPASSPORTVISA' and IsWriteLog=1)
            begin
                Set @Xml_Update = 
                    (
                        select convert(varchar(12),B.PassportVisaID) + ','
                        from dbo.HR_TBLPASSPORTVISA (Nolock) B
                        where B.PassportVisaID = @PassportVisaID
                        For XML Path('')
                    )						
                
                if(isnull(@Xml_Update,'') <> '')
                begin
                    exec [dbo].[TS_spfrmLogData_Save] @UserID=@UserGroupID,@TableName='HR_TBLPASSPORTVISALog',@Action='Delete',@IsLogNew=0,@Xml=@Xml_Update,@IDLog=@IDLog_Update OUTPUT
                    exec [dbo].[TS_spfrmLogData_Save] @UserID=@UserGroupID,@TableName='HR_TBLPASSPORTVISALog',@Action='Delete',@IsLogNew=1,@Xml=@Xml_Update,@IDLog=@IDLog_Update		
                end
            end	
            DELETE FROM HR_tblPassportVisaNgayNhapCanh
            WHERE PassportVisaID = @PassportVisaID

            DELETE from HR_TBLPASSPORTVISA where PassportVisaID = @PassportVisaID
        end		
    else if @Activity= 'GetSetup'
        begin
            select CheckNgayHH_Visa from HR_tblSetupHR
        end	
    else if @Activity='CheckIsNotNullPassport'
    begin
        select Top 1 "No" from HR_TBLPASSPORTVISA where EmpID = @EmpID and Type = 1 and "No" is not null
    END
    /*Start Rlog: 17300 - MOVI - NhanHM4 - 10/12/2021*/
    ELSE IF @Activity = 'KiemTraNgayCap_HieuLucNhoHonNgaySinh'
    BEGIN
        DECLARE @dDOB DATETIME
        SELECT @EmpID = EmpID, @dDOB = DOB FROM dbo.HR_vEmp WHERE EmpCode = @EmpCode

        --SELECT @dIssueDate, @dEffDate, @dDOB

        IF ISNULL(@IssueDate, '') <> '' AND @dIssueDate < @dDOB
        BEGIN
            SELECT 1 AS Status
            RETURN
        END

        IF ISNULL(@EffectiveDate, '') <> '' AND @dEffDate < @dDOB
        BEGIN
            SELECT -1 AS Status
            RETURN
        END

        SELECT 0 AS Status
    END
    ELSE IF @Activity='getNgayNhapCanh'--anhtt189 rklog 20947
    BEGIN
        SELECT 
            convert(varchar(10), A.NgayNhapCanh, 103) as NgayNhapCanh,
            convert(varchar(10), A.NgayXuatCanh, 103)as NgayXuatCanh,
            ROW_NUMBER() over(order by PassportVisaID, convert(date,NgayNhapCanh,103) asc) STT
        FROM dbo.HR_tblPassportVisaNgayNhapCanh(NOLOCK) A
        WHERE A.PassportVisaID = @PassportVisaID
    END
    ELSE IF @Activity='SaveNgayNhapCanh' --anhtt189 rklog 20947
    BEGIN

    IF EXISTS (
        SELECT TOP 1 1 
        FROM HR_tblPassportVisaNgayNhapCanh (NOLOCK)
        WHERE PassportVisaID = @PassportVisaID
            AND (CONVERT(DATETIME, @NgayNhapCanh, 103) BETWEEN CONVERT(DATETIME, NgayNhapCanh, 103) AND CONVERT(DATETIME, NgayXuatCanh, 103)))
    BEGIN
        SET @ReturnMessCode = '0'
        SET @ReturnMess = dbo.SYS_fnGetMess('0024', @LanguageID)
        RETURN
    END

    -- Check if @NgayNhapCanh is null or empty
        IF @NgayNhapCanh IS NOT NULL AND LTRIM(RTRIM(@NgayNhapCanh)) <> ''
        BEGIN
            INSERT INTO dbo.HR_tblPassportVisaNgayNhapCanh
                    ( PassportVisaID ,
                    NgayNhapCanh ,
                    NgayXuatCanh		
                    )
            VALUES  ( @PassportVisaID,	          		
                    CONVERT(nvarchar(10), @NgayNhapCanh, 101),
                    CONVERT(nvarchar(10), @NgayXuatCanh, 101)              
                    )
            SET @ReturnMessCode = '1'
            SET @ReturnMess = dbo.SYS_fnGetMess('0046', @LanguageID)
        END
    END
    ELSE IF @Activity='DeleteDetail'
    BEGIN
        DELETE HR_tblPassportVisaNgayNhapCanh 
        WHERE PassportVisaID = @PassportVisaID
    END
    /*End   Rlog: 17300 - MOVI - NhanHM4 - 10/12/2021*/
    if @@Error <> 0
        begin
            set	@PassportVisaID = -1
            set	@ReturnMess = ''		
        end
