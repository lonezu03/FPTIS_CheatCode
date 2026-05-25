USE [iHRP_V34_TanLong_KH_UAT]
GO
/****** Object:  StoredProcedure [dbo].[RE_spfrmDynamicCanList]    Script Date: 5/12/2026 4:45:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[RE_spfrmDynamicCanList]
@Action as nvarchar(40) = null,
@Activity as nvarchar(40) = null,
@Condition as nvarchar(max) = null,
@LanguageID as nvarchar(10) = 'VN',
@Language as nvarchar(10) = 'VN',
@UserGroupID nvarchar(50)=null,
@UserAccountID	nvarchar(50) = null,
@ProjectID		varchar(12) = null,
@ProjectCode nvarchar(15) =null,
@ProjectName nvarchar(30) =null,
@FunctionID nvarchar(12)=null,
--rlogID: 5823
@KeyWord nvarchar(max)=null,
@ThamGia	nvarchar(1) = null,/*LamNT22-11122015-7100*/
@rownumber varchar(12) = 15,
@page varchar(12) = 1,
@XemChiTietCV	nvarchar(1) = '0',
@URLParam_Return nvarchar(50)=null,--param này để lấy 1 số cột thêm
@GridName nvarchar(255) = NULL,
--Start RlogID: 14382 TiKi - NhanHM4 - 11/07/2019
@ChuyenNV NVARCHAR(1) = NULL
--End   RlogID: 14382 TiKi - NhanHM4 - 11/07/2019
,@FromFunctionID NVARCHAR(12) = NULL /*Dùng cho các màn hình gọi store lấy dữ liệu ds ứng viên*/

AS
if @Activity is not null SET @Action = @Activity
SET @Language = @LanguageID
--QuyenPV9 - 17/10/2019 - TIKI - bổ sung tạm để fix lỗi khi ManhVH tách màn hình
declare @Ascx nvarchar(200)
select @Ascx = a.ascx
from sys_tblfunctionlist (nolock) a
where a.functionid = @FunctionID
if(@Ascx like N'%MdlRE/Form/CanList.ascx%')
	set @FunctionID = '7001'
--End

if(@ThamGia is null) set @ThamGia = '2'
If isnull(@UserAccountID,'')='' Set @UserAccountID = @UserGroupID
If @UserAccountID = '' or @UserAccountID is null Set @UserAccountID = 'admin'
If @UserGroupID is null Set @UserGroupID = ''
--rlogID:6023
Declare @YCTD_PQDacBiet bit, @CanhBaoKhongTuyenLaiUV bit/*RL 6478*/
Select	@YCTD_PQDacBiet = isnull(YCTD_PQDacBiet,0) ,
		@CanhBaoKhongTuyenLaiUV = isnull(CanhBaoKhongTuyenLaiUV,0)
From RE_tblSetupRE(NoLock)
print @YCTD_PQDacBiet
Declare @sEmpIDLogin nvarchar(20)
Select @sEmpIDLogin = isnull(convert(nvarchar,EmpID),'') From UMS_tblUserAccount Where UserGroupID = @UserAccountID

--RL 6478 
Declare @LSJobTitleID int 
Select @LSJobTitleID = b.LSJobTitleID 
From RE_tblProject(NoLock) a 
Left join RE_tblDemand(nolock)b on a.DemandID = b.DemandID
where a.ProjectID = @ProjectID

declare @strViewHistory nvarchar(50) set @strViewHistory = Case when @Language = 'EN' then N'View history' else N'Xem lịch sử' end

DECLARE @iRowNumber	INT, @iPage	INT
SET @iRowNumber = CONVERT(INT, @rownumber)
SET @iPage = CONVERT(INT, @page)

If @Action = 'GetCriteria'
	begin
		Select ColumnName CriteriaID,
			Case When @Language = 'EN' then Eng Else Viet end Criteria, Rank,xtypeColumn 
		From UMS_tblVietEng 
		Where TableName='HR_vDynamicCanList' and Display = 1
		order by Criteria
	end


Else If @Action = 'GetCriteria_frmREDymamicEmplist'
--Lay tieu chi cho form DynamicEmplist-Tim kiem ung vien noi bo- (Phan he Re)
--Bo sung: khong lay ngay nop ho so, khong lay muc luong mong muon
	begin
		--Declare @Language nvarchar(2)
		--Set		@Language ='VN'
		Select ColumnName CriteriaID
		
		,Case When @Language = 'EN' then Eng Else Viet end Criteria, Rank,xtypeColumn 
		From UMS_tblVietEng 
		Where TableName='HR_vDynamicCanList' and Display = 1
			and ColumnName <> 'ApplyForJobDate'--Ngay nop ho so
			and ColumnName <> 'ExpectationSalary'--Muc luong mong muon
		order by Rank
	end



	Else If @Action = 'GetOperator'
	begin
		Select OperatorID, Operator From UMS_tblOperator
		order by Rank
	end
	
	Else If @Action = 'GetColumnView'
	begin
		--Select * From SYS_tblColumnView order by ColumnViewID
		Select 	Case When @Language ='VN' then ColumnViewVN Else ColumnView end as ColumnView,
			ColumnViewID, ViewDefault 
		From 	SYS_tblColumnView order by ColumnViewID
	end
	Else If @Action = 'GetColumnView_RE'
	begin
		--Select * From SYS_tblColumnView order by ColumnViewID
		Select 	Case When @Language ='VN' then ColumnViewVN Else ColumnView end as ColumnView,
			ColumnViewID, ViewDefault,UniqueName
		From 	SYS_tblColumnView_RE order by ColumnViewID
	end
	--RL 14149
	ELSE IF @Action = 'GetCanList'
	BEGIN
		--SET @startindex = @startindex + 1 
		If OBJECT_ID('tempdb..#tblTempUngVien') is not null drop table  #tblTempUngVien
		Create table #tblTempUngVien(CandidateID int, CandidateCode nvarchar(20), CandidateName nvarchar(200), FilePhoto nvarchar(max),  STT int)
		/*nếu tìm cho PATD thì enable không cho bấm chuyến vào đợt bổ sung xử lý cho rlogID:5911*/
		declare @isEnabled1 varchar(12) set @isEnabled1='0'
		if CHARINDEX('A.Can_ProjectID', @Condition) > 0 set @isEnabled1='1'
		if(@XemChiTietCV = '1')
		begin
			select @rownumber = count(*)
			from re_Tblcandidate (nolock)
		end

		------2017/04/25: TrangNT tách store để tăng tốc. Thử nghiệm trên mh DS ứng viên trước
		if @FunctionID='7001' and 1=1/*tạm thời chưa dùng store này*/
		Begin
			Exec	RE_spfrmCanList_Search @Action='GetListCanGeneral', @Language=@Language,@UserGroupID=@UserGroupID,@FunctionID=@FunctionID,@Condition=@Condition,@KeyWord=@KeyWord,
					@URLParam_Return=@URLParam_Return,@rownumber = @rownumber, @page = @page, @GridName = @GridName,@isEnabled=@isEnabled1,@FromFunctionID=@FromFunctionID
			return
		End
		-----------
		---rlogID:5823
		If OBJECT_ID('tempdb..#TableCandidateLst') is not null drop table  #TableCandidateLst
		Create table #TableCandidateLst(CandidateID int)
		If OBJECT_ID('tempdb..#TableTempIDLst1') is not null drop table  #TableTempIDLst1
		Create table #TableTempIDLst1(ID nvarchar(12))
		If isnull(@KeyWord,'') <> ''
		begin
			 --ly lich
			 insert into #TableCandidate 
			 exec RE_sprptSearchWithKeyWord @Table_Name = 're_tblcandidate', @SearchString = @KeyWord
			 -- kinh nghiem
			 insert into #TableTempID 
			 exec RE_sprptSearchWithKeyWord @Table_Name = 'RE_tblCandidateWorkingBkgr', @SearchString = @KeyWord
			 --
			  insert into #TableCandidate
			 Select A.ID
			 From #TableTempID A
			 left join #TableCandidate(nolock) B on A.ID = B.CandidateID
			 Where B.CandidateID is null
			 delete From #TableTempID
			 --ky nang - ky nang khac 
			 insert into #TableTempID 
			 exec RE_sprptSearchWithKeyWord @Table_Name = 'RE_tblCandidateSkill', @SearchString = @KeyWord
			 --
			 insert into #TableCandidate
			 Select A.ID
			 From #TableTempID A
			 left join #TableCandidate(nolock) B on A.ID = B.CandidateID
			 Where B.CandidateID is null
			 delete From #TableTempID

			 insert into #TableTempID 
			 exec RE_sprptSearchWithKeyWord @Table_Name = 'RE_tblCandidate_OtherSkill', @SearchString = @KeyWord
			 --
			 insert into #TableCandidate
			 Select A.ID
			 From #TableTempID A
			 left join #TableCandidate(nolock) B on A.ID = B.CandidateID
			 Where B.CandidateID is null
			 delete From #TableTempID
			 --bang cap chung chi 
			 insert into #TableTempID 
			 exec RE_sprptSearchWithKeyWord @Table_Name = 'HR_TBLQUALIfICATION1', @SearchString = @KeyWord
			 --
			insert into #TableCandidate
			 Select A.ID
			 From #TableTempID A
			 left join #TableCandidate(nolock) B on A.ID = B.CandidateID
			 Where B.CandidateID is null
			 delete From #TableTempID
			 --nguoi tham khao 
			 insert into #TableTempID 
			 exec RE_sprptSearchWithKeyWord @Table_Name = 'RE_tblCanReferrer', @SearchString = @KeyWord
			 --
			 insert into #TableCandidate
			 Select A.ID
			 From #TableTempID A
			 left join #TableCandidate(nolock) B on A.ID = B.CandidateID
			 Where B.CandidateID is null
			 delete From #TableTempID
			 --QH gia dinh 
			 insert into #TableTempID 
			 exec RE_sprptSearchWithKeyWord @Table_Name = 'RE_tblCanRelative', @SearchString = @KeyWord
			 --
			insert into #TableCandidate
			 Select A.ID
			 From #TableTempID A
			 left join #TableCandidate(nolock) B on A.ID = B.CandidateID
			 Where B.CandidateID is null
			 delete From #TableTempID
			 --Hashtag
			 insert into #TableTempID 
			 exec RE_sprptSearchWithKeyWord @Table_Name = 'RE_tblHashTag', @SearchString = @KeyWord
			 --
			insert into #TableCandidate
			 Select A.ID
			 From #TableTempID A
			 left join #TableCandidate(nolock) B on A.ID = B.CandidateID
			 Where B.CandidateID is null
			 delete From #TableTempID
			  /*rlogID:14136*/
			 if FULLTEXTSERVICEPROPERTY('IsFullTextInstalled') =1
			 BEGIN
				set @KeyWord = '"*' + replace(@KeyWord,' ','" and "') + '*"'
				
				declare @stringSQL nvarchar(max)
				set @stringSQL = '
									SELECT CandidateID
									FROM [dbo].[RE_tblCandidate_CanCV]
									WHERE contains(Content, '''+@KeyWord+''');'
				
				insert into #TableTempID
				exec(@stringSQL)
			
				 insert into #TableCandidate
				 Select A.ID
				 From #TableTempID A
				 left join #TableCandidate(nolock) B on A.ID = B.CandidateID
				 Where B.CandidateID is null 
				delete From #TableTempID 
			 END
		end
		--Select * From #TableCandidateLst
		Declare @strJoinLst nvarchar(max) Set @strJoinLst = ''
		If isnull(@KeyWord,'') <> '' Set @strJoinLst = 'Inner join #TableCandidateLst(nolock) temp on A.CandidateID = temp.CandidateID'
		/**/
		/*rlogID:7357*/
		declare @sNgayCapNhatHoSoLst nvarchar(max), @sJoinNgayCapNhatHoSoLst nvarchar(max)
		set @sNgayCapNhatHoSoLst = ' convert(nvarchar,A_NTT.NgayThaoTacMoiNhat,103) NgayCapNhatHoSo,'
		set @sJoinNgayCapNhatHoSoLst='left join (
											select distinct CandidateID, max(NgayThaoTac) NgayThaoTacMoiNhat
											from (
											select CandidateID, 
											case when isnull(EditTime,'''') ='''' then convert(datetime,convert(nvarchar,CreateTime,103),103) else convert(datetime,convert(nvarchar,EditTime,103),103)  end NgayThaoTac
											from RE_tblCandidate (nolock)
											union
											select CandidateID, 
											case when isnull(EditTime,'''') ='''' then convert(datetime,convert(nvarchar,CreateTime,103),103) else convert(datetime,convert(nvarchar,EditTime,103),103)  end NgayThaoTac
											from RE_tblCandidateWorkingBkgr (nolock)
											union
											select EmpID as CandidateID, 
											case when isnull(EditTime,'''') ='''' then convert(datetime,convert(nvarchar,CreateTime,103),103) else convert(datetime,convert(nvarchar,EditTime,103),103)  end NgayThaoTac
											from HR_TBLQUALIFICATION1 (nolock)
											union
											select CandidateID, 
											case when isnull(EditTime,'''') ='''' then convert(datetime,convert(nvarchar,CreateTime,103),103) else convert(datetime,convert(nvarchar,EditTime,103),103)  end NgayThaoTac
											from RE_tblCanRelative (nolock)
											union
											select CandidateID, 
											case when isnull(EditTime,'''') ='''' then convert(datetime,convert(nvarchar,CreateTime,103),103) else convert(datetime,convert(nvarchar,EditTime,103),103)  end NgayThaoTac
											from RE_tblCandidate_OtherSkill (nolock)
											union
											select CandidateID, 
											case when isnull(EditTime,'''') ='''' then convert(datetime,convert(nvarchar,CreateTime,103),103) else convert(datetime,convert(nvarchar,EditTime,103),103)  end NgayThaoTac
											from RE_tblCandidateSkill (nolock)
											union
											select EmpID as CandidateID, 
											case when isnull(EditTime,'''') ='''' then convert(datetime,convert(nvarchar,CreateTime,103),103) else convert(datetime,convert(nvarchar,EditTime,103),103)  end NgayThaoTac
											from RE_tblCanReferrer (nolock)
											union
											select CandidateID, 
											convert(datetime,convert(nvarchar,CreateTime,103),103) NgayThaoTac
											from RE_tblCandidateDocument (nolock)
											) A
											group by A.CandidateID
							)A_NTT on A.CandidateID = A_NTT.CandidateID
							'
		Declare @SqlLst nvarchar(max)
		/*
			quanbm2 : chi lay cac cot su dung, dung them bang tam (performance)		
		*/
		
		--Delete RE_tblPermissionByUser
		--Where UserGroupID = @UserAccountID and FunctionID = @FunctionID

		--Insert into dbo.RE_tblPermissionByUser(UserGroupID, FunctionID, CandidateID)
		--Select distinct @UserAccountID, @FunctionID, CandidateID
		--From dbo.fnGetAllCan_Permission(@UserAccountID, @FunctionID)	

		

		Set @SqlLst = N'
						select '''+ @UserGroupID + ''' AS UserGroupID, ''' + @FunctionID + ''' AS FunctionID, CandidateID
						into #tmpPermissionByUser
						from dbo.fnGetAllCan_Permission('''+ @UserGroupID + ''', ''' + @FunctionID + ''')

						Select A.CandidateID, CandidateCode, CandidateName, CAA.FilePhoto, row_number() over (order by A.CandidateID desc) as STT'
		If @Condition like '%Can_DemandID%' SET @SqlLst = @SqlLst + 
		N',A_Demand.Can_DemandID'
		If @Condition like '%Can_ProjectID%' SET @SqlLst = @SqlLst + 
		N',A_Project.Can_ProjectID'
		
		Set @SqlLst = @SqlLst + ' 
							From RE_vDynamicCanList(NoLock) A
							outer apply
							(
								select FilePhoto
								from RE_tblCandidate (Nolock)
								where CandidateID = A.CandidateID
							) CAA
							Inner join #tmpPermissionByUser(NoLock) B on A.CandidateID = B.CandidateID and UserGroupID = ''' + @UserAccountID + ''' and FunctionID = ''' + @FunctionID + '''
							Left join (Select Max(LSDocumentID) LSDocumentID,CandidateID From RE_tblCandidateDocument(NoLock) Group by CandidateID) C_tmp on A.CandidateID = C_tmp.CandidateID
							Left join RE_tblCandidateDocument (NoLock) C on C.CandidateID = C_tmp.CandidateID and C.LSDocumentID = C_tmp.LSDocumentID
							Left join LS_tblDocument (NoLock) D on C.LSDocumentID = D.LSDocumentID
							/*RL 5911 - TrangNT - 20150622 - Bổ sung đk lọc theo YC và PA mà ƯV đã được gán vào.*/
							Cross Apply (Select ReVal as Can_DemandID From dbo.RE_fnLayProjectDaThamGia(A.CandidateID,''DemandID'','''','','','''','''','''','''','''')) A_Demand
							Cross Apply (Select ReVal as Can_ProjectID From dbo.RE_fnLayProjectDaThamGia(A.CandidateID,''ProjectID'','''','','','''','''','''','''','''')) A_Project
							/*RL 6055 - TrangNT - 20150720 - Bổ sung các cột dùng riêng cho RLOG này.*/
							Left join (	Select max(NgayThaoTac) as NgayThaoTac, CandidateID as CanID_TTTD
										From (Select isnull(EditDate,CreateDate) as NgayThaoTac,CandidateID From RE_tblThongTinTuyenDung_GhiNhan(NoLock) Where LoaiGhiNhan=''UV'')A
										Group by CandidateID
									)GN_tmp on GN_tmp.CanID_TTTD = A.CandidateID
							Left join (Select CandidateID as CanID_TTTD,TinhTrang, CreateDate,EditDate From RE_tblThongTinTuyenDung_GhiNhan(Nolock)) GN on GN.CanID_TTTD = GN_tmp.CanID_TTTD and Case When GN.EditDate is not null then GN.EditDate Else GN.CreateDate end = GN_tmp.NgayThaoTac
							'+@strJoinLst+'
							'+@sJoinNgayCapNhatHoSoLst+'
						'
		
		If(isnull(@ProjectCode,'')<>'' or isnull(@ProjectName,'')<>'' )
			begin
				If not(isnull(@Condition,'')='')
					Set @SqlLst = @SqlLst + ' Where ' + @Condition + 'and A.CandidateID in (Select A.CandidateID
																					From RE_TBLPROJECTCANDIDATE(NoLock) A
																					Left join RE_tblProject(NoLock) B on A.ProjectID = B.ProjectID
																					Where ('''+@ProjectCode+''' = '''' or B.ProjectCode like N''%'+ @ProjectCode + '%'')
																					and ('''+@ProjectName+''' = '''' or B.ProjectName like N''%'+ @ProjectName + '%'')
																					) order by A.ApplyForJobDate desc,A.vFirstName,A.CandidateCode'
				Else 
					Set @SqlLst = @SqlLst + 'Where A.CandidateID in (Select A.CandidateID 
															From RE_TBLPROJECTCANDIDATE(NoLock) A 
															Left join RE_tblProject(NoLock) B on A.ProjectID = B.ProjectID 
															Where ('''+@ProjectCode+''' = '''' or B.ProjectCode like N''%'+ @ProjectCode + '%'')
															and ('''+@ProjectName+''' = '''' or B.ProjectName like N''%'+ @ProjectName + '%'')
															)  order by  A.ApplyForJobDate desc,A.vFirstName,A.CandidateCode'
			end
		Else
			begin
				If not(isnull(@Condition,'')='')
					Set @SqlLst = @SqlLst + ' Where ' + @Condition
			end
		--Select @SqlLst
		exec sp_executeSql @SqlLst
		--print @SqlLst
	END
	--eND RL 14149
	Else If @Action = 'GetListCanGeneral'
	BEGIN
			/*nếu tìm cho PATD thì enable không cho bấm chuyến vào đợt bổ sung xử lý cho rlogID:5911*/
		declare @isEnabled varchar(12) set @isEnabled='0'
		if CHARINDEX('A.Can_ProjectID', @Condition) > 0 set @isEnabled='1'
		------2017/04/25: TrangNT tách store để tăng tốc. Thử nghiệm trên mh DS ứng viên trước
		if @FunctionID='7001' and 1=1/*tạm thời chưa dùng store này*/
		Begin
			Exec	RE_spfrmCanList_Search @Action='GetListCanGeneral', @Language=@Language,@UserGroupID=@UserGroupID,@FunctionID=@FunctionID,@Condition=@Condition,@KeyWord=@KeyWord,
					@URLParam_Return=@URLParam_Return,@rownumber = @rownumber, @page = @page, @GridName = @GridName,@isEnabled=@isEnabled
			return
		End
		-----------

		---rlogID:5823
		If OBJECT_ID('tempdb..#TableCandidate') is not null drop table  #TableCandidate
		Create table #TableCandidate(CandidateID int)
		If OBJECT_ID('tempdb..#TableTempID') is not null drop table  #TableTempID
		Create table #TableTempID(ID nvarchar(12))
		If isnull(@KeyWord,'') <> ''
		begin
			 --ly lich
			 insert into #TableCandidate 
			 exec RE_sprptSearchWithKeyWord @Table_Name = 're_tblcandidate', @SearchString = @KeyWord
			 -- kinh nghiem
			 insert into #TableTempID 
			 exec RE_sprptSearchWithKeyWord @Table_Name = 'RE_tblCandidateWorkingBkgr', @SearchString = @KeyWord
			 --
			 insert into #TableCandidate
			 Select CandidateID
			 From #TableTempID A
			 Left join RE_tblCandidateWorkingBkgr B on A.ID = B.CandidateWorkingBkgrID
			 Where B.CandidateID not in (Select CandidateID From #TableCandidate)
			 delete From #TableTempID
			 --ky nang - ky nang khac 
			 insert into #TableTempID 
			 exec RE_sprptSearchWithKeyWord @Table_Name = 'RE_tblCandidateSkill', @SearchString = @KeyWord
			 --
			 insert into #TableCandidate
			 Select CandidateID
			 From #TableTempID A
			 Left join RE_tblCandidateSkill B on A.ID = B.LSEmpSkillID
			 Where B.CandidateID not in (Select CandidateID From #TableCandidate)
			 delete From #TableTempID

			 insert into #TableTempID 
			 exec RE_sprptSearchWithKeyWord @Table_Name = 'RE_tblCandidate_OtherSkill', @SearchString = @KeyWord
			 --
			 insert into #TableCandidate
			 Select CandidateID
			 From #TableTempID A
			 Left join RE_tblCandidate_OtherSkill B on A.ID = B.CanOtherSkillID
			 Where B.CandidateID not in (Select CandidateID From #TableCandidate)
			 delete From #TableTempID
			 --bang cap chung chi 
			 insert into #TableTempID 
			 exec RE_sprptSearchWithKeyWord @Table_Name = 'HR_TBLQUALIfICATION1', @SearchString = @KeyWord
			 --
			 insert into #TableCandidate
			 Select EmpID
			 From #TableTempID A
			 Left join HR_TBLQUALIfICATION1 B on A.ID = B.QualIficationID
			 Where B.EmpID not in (Select CandidateID From #TableCandidate)
			 delete From #TableTempID
			 --nguoi tham khao 
			 insert into #TableTempID 
			 exec RE_sprptSearchWithKeyWord @Table_Name = 'RE_tblCanReferrer', @SearchString = @KeyWord
			 --
			 insert into #TableCandidate
			 Select EmpID
			 From #TableTempID A
			 Left join RE_tblCanReferrer B on A.ID = B.ReferrerID
			 Where B.EmpID not in (Select CandidateID From #TableCandidate)
			 delete From #TableTempID
			 --QH gia dinh 
			 insert into #TableTempID 
			 exec RE_sprptSearchWithKeyWord @Table_Name = 'RE_tblCanRelative', @SearchString = @KeyWord
			 --
			 insert into #TableCandidate
			 Select CandidateID
			 From #TableTempID A
			 Left join RE_tblCanRelative B on A.ID = B.RelativeID
			 Where B.CandidateID not in (Select CandidateID From #TableCandidate)
			 delete From #TableTempID
		end
		--Select * From #TableCandidate
		Declare @strJoin nvarchar(max) Set @strJoin = ''
		If isnull(@KeyWord,'') <> '' Set @strJoin = 'Inner join #TableCandidate(nolock) temp on A.CandidateID = temp.CandidateID'
		/**/
		/*rlogID:7357*/
		declare @sNgayCapNhatHoSo nvarchar(max), @sJoinNgayCapNhatHoSo nvarchar(max)
		set @sNgayCapNhatHoSo = ' convert(nvarchar,A_NTT.NgayThaoTacMoiNhat,103) NgayCapNhatHoSo,'
		set @sJoinNgayCapNhatHoSo='left join (
											select distinct CandidateID, max(NgayThaoTac) NgayThaoTacMoiNhat
											from (
											select CandidateID, 
											case when isnull(EditTime,'''') ='''' then convert(datetime,convert(nvarchar,CreateTime,103),103) else convert(datetime,convert(nvarchar,EditTime,103),103)  end NgayThaoTac
											from RE_tblCandidate (nolock)
											union
											select CandidateID, 
											case when isnull(EditTime,'''') ='''' then convert(datetime,convert(nvarchar,CreateTime,103),103) else convert(datetime,convert(nvarchar,EditTime,103),103)  end NgayThaoTac
											from RE_tblCandidateWorkingBkgr (nolock)
											union
											select EmpID as CandidateID, 
											case when isnull(EditTime,'''') ='''' then convert(datetime,convert(nvarchar,CreateTime,103),103) else convert(datetime,convert(nvarchar,EditTime,103),103)  end NgayThaoTac
											from HR_TBLQUALIFICATION1 (nolock)
											union
											select CandidateID, 
											case when isnull(EditTime,'''') ='''' then convert(datetime,convert(nvarchar,CreateTime,103),103) else convert(datetime,convert(nvarchar,EditTime,103),103)  end NgayThaoTac
											from RE_tblCanRelative (nolock)
											union
											select CandidateID, 
											case when isnull(EditTime,'''') ='''' then convert(datetime,convert(nvarchar,CreateTime,103),103) else convert(datetime,convert(nvarchar,EditTime,103),103)  end NgayThaoTac
											from RE_tblCandidate_OtherSkill (nolock)
											union
											select CandidateID, 
											case when isnull(EditTime,'''') ='''' then convert(datetime,convert(nvarchar,CreateTime,103),103) else convert(datetime,convert(nvarchar,EditTime,103),103)  end NgayThaoTac
											from RE_tblCandidateSkill (nolock)
											union
											select EmpID as CandidateID, 
											case when isnull(EditTime,'''') ='''' then convert(datetime,convert(nvarchar,CreateTime,103),103) else convert(datetime,convert(nvarchar,EditTime,103),103)  end NgayThaoTac
											from RE_tblCanReferrer (nolock)
											union
											select CandidateID, 
											convert(datetime,convert(nvarchar,CreateTime,103),103) NgayThaoTac
											from RE_tblCandidateDocument (nolock)
											) A
											group by A.CandidateID
							)A_NTT on A.CandidateID = A_NTT.CandidateID
							'
		Declare @Sql nvarchar(max)
		/*
			quanbm2 : chi lay cac cot su dung, dung them bang tam (performance)		
		*/
		
		--Delete RE_tblPermissionByUser
		--Where UserGroupID = @UserAccountID and FunctionID = @FunctionID

		--Insert into dbo.RE_tblPermissionByUser(UserGroupID, FunctionID, CandidateID)
		--Select @UserAccountID, @FunctionID, CandidateID
		--From dbo.fnGetAllCan_Permission(@UserAccountID, @FunctionID)	
		
		Set @Sql = N'
						select '''+ @UserGroupID + ''' AS UserGroupID, ''' + @FunctionID + ''' AS FunctionID, CandidateID
						into #tmpPermissionByUser
						from dbo.fnGetAllCan_Permission('''+ @UserGroupID + ''', ''' + @FunctionID + ''')

						Select A.CandidateID, CandidateCode, CandidateName, VLastName, VFirstName,IsConNhanVienHienThi,
						IDNo, Demand, DOB_D, Major, A.LSCandidateStatusCode,
						Weight, Height, MobIfone, phone, Email, AddressStr, AddressStr_T,
						Experience, Duty, NoiLamViecQuaKhu, ApplyForJobDate_D, IntroducePerson,ChucDanhQuaKhu, NguoiNhapUngVien,--rlogID:6035
						MiddleName,
						DiemThiOnlineSTB, YearG, Status_D, CanStatus, Age, EndDateStr,LyDoCapNhat AS Note, convert(nvarchar,SoNamKinhNghiem) + N'' năm '' + convert(nvarchar,SoThangKinhNghiem) + N'' tháng''  KinhNghiem,
						/*RL 6055 - Bổ sung 1 số cột dùng riêng cho RLOG này*/
						Case When '''+@Language+N'''=''VN'' then N''Xem'' Else N''View'' end as GhiNhan,
						Case When GN.TinhTrang=''TaoMoi'' then Case When '''+@Language+N'''=''EN'' then N''New'' Else N''Tạo mới'' end
							 When GN.TinhTrang=''DaXem'' then Case When '''+@Language+N'''=''EN'' then N''Viewed'' Else N''Đã xem'' end
							 end as GhiNhan_TinhTrang,'+@sNgayCapNhatHoSo+'
					'		
		Set @Sql = @Sql + Case When @Language = 'VN' then 'A.VNCurrencyType' Else 'A.ENCurrencyType' end + ' as CurrencyType,' --loại tiền
		Set @Sql = @Sql + Case When @Language = 'VN' then 'A.VNRecruitSourceType' Else 'A.ENRecruitSourceType' end + ' as RecruitSourceType,' --loại nguồn tuyển dụng
		Set @Sql = @Sql + Case When @Language = 'VN' then 'A.VNRecruitSource' Else 'A.ENRecruitSource' end + ' as RecruitSource,' --nguồn tuyển dụng
		Set @Sql = @Sql + Case When @Language = 'VN' then 'A.Position' Else 'A.ENPosition' end + ' as Position,' 
		Set @Sql = @Sql + Case When @Language = 'VN' then 'A.VNJobTitle' Else 'A.ENJobTitle' end + ' as JobTitle,' 
		Set @Sql = @Sql + Case When @Language = 'VN' then 'A.VNJobTitle' Else 'A.ENJobTitle' end + ' as VNJobTitle,' 
		Set @Sql = @Sql + Case When @Language = 'VN' then 'A.LocationVN1' Else 'A.LocationEN1' end + ' as LocationVN1,'		
		Set @Sql = @Sql + Case When @Language = 'VN' then 'A.GenderStr' Else 'A.GenderStrEN' end + ' as GenderStr,'
		Set @Sql = @Sql + Case When @Language = 'VN' then 'A.EthnicName' Else 'A.ENEthnicName' end + ' as EthnicName,' 	
		Set @Sql = @Sql + Case When @Language = 'VN' then 'A.AddressProvince' Else 'A.ENAddressProvince' end + ' as ProvinceName,'	--Tỉnh thường trú	
		Set @Sql = @Sql + Case When @Language = 'VN' then 'A.AddressProvince_T' Else 'A.ENAddressProvince_T' end + ' as ProvinceName_T,'	--Tỉnh tạm trú	
		Set @Sql = @Sql + Case When @Language = 'VN' then 'A.P_PhuongXa' Else 'A.P_PhuongXaEN' end + ' as Ward,'	--Phường/Xã thường trú
		Set @Sql = @Sql + Case When @Language = 'VN' then 'A.T_PhuongXa' Else 'A.T_PhuongXaEN' end + ' as WardT,'	--Phường/Xã tạm trú
		Set @Sql = @Sql + Case When @Language = 'VN' then 'A.District' Else 'A.ENDistrict' end + ' as District,'	--Quận/Huyện thường trú
		Set @Sql = @Sql + Case When @Language = 'VN' then 'A.District_T' Else 'A.ENDistrict_T' end + ' as DistrictT,'	--Quận/Huyện tạm trú
		Set @Sql = @Sql + Case When @Language = 'VN' then 'A.VNCultureLevel' Else 'A.ENCultureLevel' end + ' as CultureLevel,'	--Trình độ học vấn				
		Set @Sql = @Sql + Case When @Language = 'VN' then 'A.VNMajorLevel' Else 'A.ENMajorLevel' end + ' as VNMajorLevel,'
		Set @Sql = @Sql + Case When @Language = 'VN' then 'A.VNMajorLevel' Else 'A.ENMajorLevel' end + ' as MajorLevel,'
		Set @Sql = @Sql + Case When @Language = 'VN' then 'A.Major' Else 'A.ENMajor' end + ' as RMajor,'	--Chuyên ngành		
		Set @Sql = @Sql + Case When @Language = 'VN' then 'A.School' Else 'A.ENSchool' end + ' as School,'
		Set @Sql = @Sql + Case When @Language = 'VN' then 'A.TrainingForm' Else 'A.TrainingFormEN' end + ' as TrainingForm,'
		Set @Sql = @Sql + Case When @Language = 'VN' then 'A.PassWithLevelName' Else 'A.ENPassWithLevelName' end + ' as PassWithLevelName,'
		Set @Sql = @Sql + Case When @Language = 'VN' then 'A.CandidateStatusVN' Else 'A.CandidateStatusEN' end + ' as CandidateStatus,' 
		Set @Sql = @Sql + Case When @Language = 'VN' then 'A.NoiBoBenNgoaiVN' Else 'A.NoiBoBenNgoaiEN' end + ' as NoiBoBenNgoai,' 
		Set @Sql = @Sql + Case When @Language = 'VN' then 'A.NguonUngVienVN' Else 'A.NguonUngVienEN' end + ' as NguonUngVien,'
		Set @Sql = @Sql + 'Case When IsJoinProject is null or IsJoinProject = 0 then '''' Else ''X'' end as IsJoinProject_X,'
		Set @Sql = @Sql + 'A.Status'+ ' as Status,' 
		Set @Sql = @Sql + Case When @Language = 'VN' then 'A.TrangThaiRangBuocVN_UV_PA' Else 'A.TrangThaiRangBuocEN_UV_PA' end + ' as TrangThaiRangBuoc_UV_PA,' 
		Set @Sql = @Sql + 'dbo.fnConvertNumber(A.ExpectationSalary) as Salary,' 
		Set @Sql = @Sql + 'A.YearG as YearGraduation, '
		Set @Sql = @Sql + Case When @Language = 'VN' then '''In CV''' Else '''Print''' end + ' as PrintCV,'		
		Set @Sql = @Sql + Case When @Language = 'VN' then 'A.StatusCV' Else 'A.ENStatusCV' end + ' as StatusCV,' 
		Set @Sql = @Sql + Case When @Language = 'VN' then '''ReSet MK''' Else '''ReSet pass''' end + ' as ReSetPass,' 
		Set @Sql = @Sql + Case When @Language = 'VN' then N'N''Xem hồ sơ''' Else '''View document''' end + ' as ViewDocText,' 
		Set @Sql = @Sql + Case When @Language = 'VN' then 'D.VNName' Else 'D.Name' end + ' as DocumentName,' 
		--rlogID:6035
		Set @Sql = @Sql + Case When @Language = 'VN' then 'A.LocationVN2' Else 'A.LocationEN2' end + ' as KhuVucLamViec1,' 
		Set @Sql = @Sql + Case When @Language = 'VN' then 'A.LocationVN3' Else 'A.LocationEN3' end + ' as KhuVucLamViec2,' 
		Set @Sql = @Sql + 'C.AttachFile as OneDocFileName,'
		--rl 11681
		Set @Sql = @Sql + Case When @Language = 'VN' then N'''Xem''' Else N'''View''' end + ' as YCTDDaUngTuyen,' 
		--RL 6953
		Set @Sql = @Sql + 'A.KQTuyenDungMoiNhat as KQTuyenDungMoiNhat,'
		Set @Sql = @Sql + N'N'''+@strViewHistory +''' as ViewHistory'
		--
		Set @Sql = @Sql + ' 
							From RE_vDynamicCanList(NoLock) A
							Inner join #tmpPermissionByUser(NoLock) B on A.CandidateID = B.CandidateID and UserGroupID = ''' + @UserAccountID + ''' and FunctionID = ''' + @FunctionID + '''
							Left join (Select Max(LSDocumentID) LSDocumentID,CandidateID From RE_tblCandidateDocument(NoLock) Group by CandidateID) C_tmp on A.CandidateID = C_tmp.CandidateID
							Left join RE_tblCandidateDocument (NoLock) C on C.CandidateID = C_tmp.CandidateID and C.LSDocumentID = C_tmp.LSDocumentID
							Left join LS_tblDocument (NoLock) D on C.LSDocumentID = D.LSDocumentID
							/*RL 5911 - TrangNT - 20150622 - Bổ sung đk lọc theo YC và PA mà ƯV đã được gán vào.*/
							Cross Apply (Select ReVal as Can_DemandID From dbo.RE_fnLayProjectDaThamGia(A.CandidateID,''DemandID'','''','','','''','''','''','''','''')) A_Demand
							Cross Apply (Select ReVal as Can_ProjectID From dbo.RE_fnLayProjectDaThamGia(A.CandidateID,''ProjectID'','''','','','''','''','''','''','''')) A_Project
							/*RL 6055 - TrangNT - 20150720 - Bổ sung các cột dùng riêng cho RLOG này.*/
							Left join (	Select max(NgayThaoTac) as NgayThaoTac, CandidateID as CanID_TTTD
										From (Select isnull(EditDate,CreateDate) as NgayThaoTac,CandidateID From RE_tblThongTinTuyenDung_GhiNhan(NoLock) Where LoaiGhiNhan=''UV'')A
										Group by CandidateID
									)GN_tmp on GN_tmp.CanID_TTTD = A.CandidateID
							Left join (Select CandidateID as CanID_TTTD,TinhTrang, CreateDate,EditDate From RE_tblThongTinTuyenDung_GhiNhan(Nolock)) GN on GN.CanID_TTTD = GN_tmp.CanID_TTTD and Case When GN.EditDate is not null then GN.EditDate Else GN.CreateDate end = GN_tmp.NgayThaoTac
							'+@strJoin+'
							'+@sJoinNgayCapNhatHoSo+'
						'
		
		If(isnull(@ProjectCode,'')<>'' or isnull(@ProjectName,'')<>'' )
			begin
				If not(isnull(@Condition,'')='')
					Set @Sql = @Sql + ' Where ' + @Condition + 'and A.CandidateID in (Select A.CandidateID
																					From RE_TBLPROJECTCANDIDATE(NoLock) A
																					Left join RE_tblProject(NoLock) B on A.ProjectID = B.ProjectID
																					Where ('''+@ProjectCode+''' = '''' or B.ProjectCode like N''%'+ @ProjectCode + '%'')
																					and ('''+@ProjectName+''' = '''' or B.ProjectName like N''%'+ @ProjectName + '%'')
																					) order by A.ApplyForJobDate desc,A.vFirstName,A.CandidateCode'
				Else 
					Set @Sql = @Sql + 'Where A.CandidateID in (Select A.CandidateID 
															From RE_TBLPROJECTCANDIDATE(NoLock) A 
															Left join RE_tblProject(NoLock) B on A.ProjectID = B.ProjectID 
															Where ('''+@ProjectCode+''' = '''' or B.ProjectCode like N''%'+ @ProjectCode + '%'')
															and ('''+@ProjectName+''' = '''' or B.ProjectName like N''%'+ @ProjectName + '%'')
															)  order by  A.ApplyForJobDate desc,A.vFirstName,A.CandidateCode'
			end
		Else
			begin
				If not(isnull(@Condition,'')='')
					Set @Sql = @Sql + ' Where ' + @Condition + ' order by  A.ApplyForJobDate desc,A.vFirstName,A.CandidateCode'
				Else 
					Set @Sql = @Sql + ' /*Where Active = 1*/ order by  A.ApplyForJobDate desc,A.vFirstName,A.CandidateCode'
			end
		--Select @Sql
		exec sp_executeSql @Sql
		print @Sql
	end
---------------------------------------
--quanbm2 : de lai cho bao cao
Else If @Action = 'GetListCanGeneralReport'
	begin
		---rlogID:5823
		If OBJECT_ID('tempdb..#TableCandidate2') is not null drop table  #TableCandidate2
		Create table #TableCandidate2(CandidateID int)
		If isnull(@KeyWord,'') <> ''
		begin
				insert into #TableCandidate2 
				exec RE_sprptSearchWithKeyWord @Table_Name = 're_tblcandidate', @SearchString = @KeyWord
		END
        
		/*Fix mail NhiNU - 24/01/2022 - bỏ xử lý rlogid 17361 ở báo cáo này*/
		--RlogID 17361 - SOVICO - 17/12/2021
		--DECLARE @PhanQuyenDuLieuTheoYCTD_BaoCaoCanhBao BIT
		--SELECT @PhanQuyenDuLieuTheoYCTD_BaoCaoCanhBao = ISNULL(PhanQuyenDuLieuTheoYCTD_BaoCaoCanhBao, 0) FROM dbo.RE_tblSetupRE (NOLOCK) 

		--DECLARE @tID tID
		--INSERT INTO @tID(ID)
		--SELECT DISTINCT A.DemandID
		--FROM RE_tblDemand(nolock) A

		--SELECT DemandID
		--INTO #tmpDemandOrgPQ
		--FROM [dbo].[RE_fnPhanQuyenYCTD_RLog17361](@tID,@UserGroupID,null,null,null,null)
		--End RlogID 17361 - SOVICO - 17/12/2021

		/*Rlogid 17533 - SOVICO - 20/01/2022*/
		If OBJECT_ID('tempdb..#temp_tblCanSearch_ProjectList') is not null drop table  #temp_tblCanSearch_ProjectList
		Create table #temp_tblCanSearch_ProjectList(CandidateID INT, ProjectID INT, DemandID INT)
		DECLARE @LayTTYCTDMoiNhat BIT = 0
		DECLARE @strJoin_RL17533 NVARCHAR(MAX) SET @strJoin_RL17533 = ''
		DECLARE @strSQL_RL17533 NVARCHAR(MAX) SET @strSQL_RL17533 = ''

		IF EXISTS 
		(
			SELECT TOP 1 1 
			FROM dbo.SYS_tblReportCaption (NOLOCK) A 
			WHERE A.FunctionID = 82451
			AND
			(
				(A.ControlID = 'CptJobTileYCTD' AND ISNULL(A.Status, 0) = 0) OR
				(A.ControlID = 'CptLevel1NameYCTD' AND ISNULL(A.Status, 0) = 0) OR
				(A.ControlID = 'CptLevel2NameYCTD' AND ISNULL(A.Status, 0) = 0) OR
				(A.ControlID = 'CptLevel3NameYCTD' AND ISNULL(A.Status, 0) = 0) OR
				(A.ControlID = 'CptMaPATD' AND ISNULL(A.Status, 0) = 0) OR
				(A.ControlID = 'CptTinhTrangUV2' AND ISNULL(A.Status, 0) = 0)
			)
		)
		BEGIN
			SET @LayTTYCTDMoiNhat = 1
			/*lấy yêu cầu tuyển dụng mới nhất theo ngày yêu cầu*/
			INSERT INTO #temp_tblCanSearch_ProjectList(CandidateID, ProjectID, DemandID)
			SELECT TOP 1 WITH TIES PC.CandidateID, PC.ProjectID, DD.DemandID
			FROM RE_tblProjectCandidate (NOLOCK) PC
			INNER JOIN dbo.RE_tblProject (NOLOCK) CC ON CC.ProjectID = PC.ProjectID
			INNER JOIN dbo.RE_tblDemand (NOLOCK) DD ON DD.DemandID = CC.DemandID
			OUTER APPLY
			(
				SELECT TOP 1 TourCan.RETournamentStatusID AS RETournamentStatusID
				FROM dbo.RE_tblTournamentCandidate (NOLOCK) TourCan
				INNER JOIN dbo.RE_tblProjectTournament (NOLOCK) ProjectTour ON ProjectTour.ProjectTournamentID = TourCan.ProjectTournamentID
				WHERE TourCan.CandidateID = PC.CandidateID AND ProjectTour.ProjectID = PC.ProjectID
				ORDER BY ProjectTour.Seq desc
			) TourCan_MoiNhat
			GROUP BY PC.CandidateID, DD.DemandID, PC.ProjectID, PC.ApplyDate, DD.DemandDate, CC.ProjectCreateDate, TourCan_MoiNhat.RETournamentStatusID
			ORDER BY ROW_NUMBER() OVER (PARTITION BY PC.CandidateID ORDER BY (CASE WHEN TourCan_MoiNhat.RETournamentStatusID = 2 THEN 999 ELSE 9 END) ASC, PC.ApplyDate DESC, DD.DemandDate DESC, CC.ProjectCreateDate desc)

			SET @strSQL_RL17533 = '
				,ThongTinYCTD.JobTitle_YCTD as JobTileYCTD
				,ThongTinYCTD.Level1_YCTD as Level1NameYCTD
				,ThongTinYCTD.Level2_YCTD as Level2NameYCTD
				,ThongTinYCTD.Level3_YCTD as Level3NameYCTD
				,ThongTinYCTD.MaPATD
				,ThongTinYCTD.NguoiPhuTrach
				,CASE WHEN ThongTinYCTD.CandidateID_ThongTinYCTD IS NULL 
					THEN dbo.SYS_fnGetMess(''YCTD_MoiNhat_CX'', ''' + @Language + ''') 
					ELSE CASE WHEN ThongTinYCTD.KetQuaVongMoiNhat IS NULL THEN dbo.SYS_fnGetMess(''YCTD_MoiNhat_DX'', ''' + @Language + ''') ELSE ThongTinYCTD.KetQuaVongMoiNhat END 
				END AS TinhTrangUV2
			'

			SET @strJoin_RL17533 = '

				LEFT JOIN
				(
					SELECT A.CandidateID AS CandidateID_ThongTinYCTD, TourCan_MoiNhat.KetQuaVongMoiNhat, TourCan_CuoiCung.Editer as NguoiPhuTrach,
						Case when ''' + @Language + N'''=''EN'' then JT.Name ELSE JT.VNName end as JobTitle_YCTD,
						Case when ''' + @Language + N'''=''EN'' then LV1.Name ELSE LV1.VNName end as Level1_YCTD,
						Case when ''' + @Language + N'''=''EN'' then LV2.Name ELSE LV2.VNName end as Level2_YCTD,
						Case when ''' + @Language + N'''=''EN'' then LV3.Name ELSE LV3.VNName end as Level3_YCTD, P.ProjectCode AS MaPATD, D.DemandName AS Demand2
					FROM #temp_tblCanSearch_ProjectList A
					OUTER APPLY
					(
						SELECT TOP 1 TourCan.RETournamentStatusID, ProjectTour.LSTournamentID, TourCan.ProjectTournamentID,
							Case when ''' + @Language + N'''=''EN'' then TourStatus.RETournamentStatusName ELSE TourStatus.RETournamentStatusNameVN end as KetQuaVongMoiNhat,
							Case when ''' + @Language + N'''=''EN'' then Tour.Name ELSE Tour.VNName end as VongTuyenDungMoiNhat,
							ProjectTour.Seq
						FROM dbo.RE_tblTournamentCandidate (NOLOCK) TourCan
						INNER JOIN dbo.RE_tblProjectTournament (NOLOCK) ProjectTour ON ProjectTour.ProjectTournamentID = TourCan.ProjectTournamentID
						LEFT JOIN dbo.LS_tblTournament (NOLOCK) Tour ON Tour.LSTournamentID = ProjectTour.LSTournamentID
						LEFT JOIN dbo.LS_tblRETournamentStatus (NOLOCK) TourStatus ON TourStatus.RETournamentStatusID = TourCan.RETournamentStatusID
						WHERE TourCan.CandidateID = A.CandidateID AND ProjectTour.ProjectID = A.ProjectID
						ORDER BY ProjectTour.Seq desc
					) TourCan_MoiNhat
					OUTER APPLY
					(
						SELECT TOP 1 CASE WHEN TourCan.Editer IS NULL THEN TourCan.Creater END AS Editer
						FROM dbo.RE_tblProjectTournament (NOLOCK) ProjectTour
						LEFT JOIN dbo.RE_tblTournamentCandidate (NOLOCK) TourCan ON ProjectTour.ProjectTournamentID = TourCan.ProjectTournamentID
						WHERE TourCan.CandidateID = A.CandidateID AND ProjectTour.ProjectID = A.ProjectID
						ORDER BY ProjectTour.Seq desc
					) TourCan_CuoiCung
					LEFT JOIN dbo.RE_tblDemand (NOLOCK) D ON D.DemandID = A.DemandID
					LEFT JOIN dbo.RE_tblProject (NOLOCK) P ON P.ProjectID = A.ProjectID
					LEFT JOIN dbo.LS_tblJobTitle (NOLOCK) JT ON JT.LSJobTitleID = D.LSJobTitleID
					LEFT JOIN dbo.LS_tblLevel1 (NOLOCK) LV1 ON LV1.LSLevel1ID = D.LSLevel1ID
					LEFT JOIN dbo.LS_tblLevel2 (NOLOCK) LV2 ON LV2.LSLevel2ID = D.LSLevel2ID
					LEFT JOIN dbo.LS_tblLevel3 (NOLOCK) LV3 ON LV3.LSLevel3ID = D.LSLevel3ID
				) ThongTinYCTD ON ThongTinYCTD.CandidateID_ThongTinYCTD = A.CandidateID

			'
		END
		/*End Rlogid 17533 - SOVICO - 20/01/2022*/

		--Select * From #TableCandidate
		Declare @strJoin2 nvarchar(max) Set @strJoin2 = ''
		If isnull(@KeyWord,'') <> '' Set @strJoin2 = 'Inner join #TableCandidate2(nolock) temp on A.CandidateID = temp.CandidateID'
		/**/
		Set @Sql = 'Select Born_District'		
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then N''In CV'' Else N''Print'' end as PrintCV'		 --QuangPNV
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.Position Else A.ENPosition end as Position'					
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.VNMajorLevel Else A.ENMajorLevel end as MajorLevel'			
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.Major Else A.ENMajor end as RMajor'	--Chuyên ngành
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.VNJobTitle Else A.ENJobTitle end as JobTitle'
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.VNJobTitle Else A.ENJobTitle end as VNJobTitle'					
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.LocationVN1 Else A.LocationEN1 end as LocationVN1'
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.GenderStr Else A.GenderStrEN end as GenderStr'	
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.EthnicName Else A.ENEthnicName end as EthnicName'						
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.PassWithLevelName Else A.ENPassWithLevelName end as PassWithLevelName'
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.TrainingForm Else A.TrainingFormEN end as TrainingForm'								
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.TrangThaiRangBuocVN_UV_PA Else A.TrangThaiRangBuocEN_UV_PA end as TrangThaiRangBuoc_UV_PA'
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then LTRIM(ISNULL(A.Born_District,'''')+ ISNULL('' '' + A.NoiSinhTTVN,''''))  Else LTRIM(ISNULL(A.Born_District,'''') + ISNULL('' '' + A.NoiSinhTTEN,'' '')) end AS NSTinhThanh' --QuangPNV
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then LTRIM(ISNULL(A.Native_District,'''')+ ISNULL('' '' + A.QueQuanTTVN,''''))  Else LTRIM(ISNULL(A.Native_District,'''') + ISNULL('' '' + A.QueQuanTTEN,'' '')) end AS NQTinhThanh' --QuangPNV
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.QueQuanUVVN Else A.QueQuanUVEN end as QueQuanUVTinhThanh' -- ThoLD6: Tách riêng quê quán ứng viên text và tỉnh thành
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.HonNhanVN Else A.HonNhanEN end as HonNhan' --QuangPNV
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.TonGiaoVN Else A.TonGiaoEN end as TonGiao' --QuangPNV
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.QuocTichVN Else A.QuoCTichEN end as QuocTich' --QuangPNV								
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.DCThuongTruVN Else A.DCThuongTruEN end as DCThuongTru' --QuangPNV
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.DCTamTruVN Else A.DCTamTruVN end as DCTamTru' --QuangPNV
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.TPGiaDinhVN Else A.TPGiaDinhEN end as TPGiaDinh' --QuangPNV
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.TPBanThanVN Else A.TPBanThanEN end as TPBanThan' --QuangPNV
		Set @Sql = @Sql + ',CONVERT(NVARCHAR(10),A.IDIssuedDate,103) as NgayCapCMND' --QuangPNV
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.NoiCapCMNDVN Else A.NoiCapCMNDEN end as NoiCapCMND' --QuangPNV
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.VNCultureLevel Else A.ENCultureLevel end as TrinhDo' --QuangPNV
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.VNMajorLevel Else A.ENMajorLevel end as BangCap' --QuangPNV		
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.VNMajorLevel Else A.ENMajorLevel end as VNMajorLevel' --Bằng cấp		
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.School Else A.ENSchool end as School' --Trường
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.TrainingForm Else A.TrainingFormEN end as HinhThucDaoTao' --Trường
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.PassWithLevelName Else A.ENPassWithLevelName end as PassWithLevelName' --Xếp loại
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.CandidateStatusVN Else A.CandidateStatusEN end as CandidateStatus' -- Tình trạng ứng viên
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.VNRecruitSource Else A.ENRecruitSource end as NguonTuyenDung' -- Nguồn tuyển dụng
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.LoaiNhanVienVN Else A.LoaiNhanVienEN end as LoaiNhanVien' -- Loại nhân viên
		Set @Sql = @Sql + ',Case When dbo.RE_fnCongChuoiNhiemVu(A.CandidateID,''-'',CHAR(10)) = '''' THEN '''' Else '''' + dbo.RE_fnCongChuoiNhiemVu(A.CandidateID,''-'',CHAR(10)) end AS DutyExcel' -- nhiệm vụ xuất theo Excel
		Set @Sql = @Sql + ',Case When dbo.RE_fnCongChuoiNoiLamViecQuaKhu(A.CandidateID,''-'',CHAR(10)) = '''' THEN '''' Else '''' + dbo.RE_fnCongChuoiNoiLamViecQuaKhu(A.CandidateID,''-'',CHAR(10)) end  AS NoiLamViecQuaKhuExcel' -- nhiệm vụ xuất theo Excel				
		Set @Sql = @Sql + ',Case When dbo.RE_fnCongChuoiBangCap(A.CandidateID,''' + @Language + ''',''-'',CHAR(10)) = '''' THEN '''' Else '''' + dbo.RE_fnCongChuoiBangCap(A.CandidateID,''' + @Language + ''',''-'',CHAR(10)) end AS ThongTinBangCap' --DSUV_ChiTiet		
		Set @Sql = @Sql + ',convert(nvarchar,A.YearG,103) as YearGraduation'
		Set @Sql = @Sql + ',dbo.fnConvertNumber(A.ExpectationSalary) as Salary' 
		Set @Sql = @Sql + ',convert(nvarchar,B.Fromdate,103) +'' - ''+ Convert(nvarchar,B.Todate,103)+'': ''+Convert(nvarchar(5),B.Mark) as DiemThiOnlineSTB '
		/*Rlogid 17428 - SOVICO - 28/12/2021*/
		Set @Sql = @Sql + ',case when ''' + @Language + N''' = ''VN'' then  CompanyVN else CompanyEN end as Company '
		Set @Sql = @Sql + ',case when ''' + @Language + N''' = ''VN'' then  Level1VN else Level1EN end as Level1Name '
		Set @Sql = @Sql + ',case when ''' + @Language + N''' = ''VN'' then  Level2VN else Level2EN end as Level2Name '
		SET @Sql = @Sql + ',case when ''' + @Language + N''' = ''VN'' then  Level3VN else Level3EN end as Level3Name '
		/*End Rlogid 17428 - SOVICO - 28/12/2021*/
		/*Rlogid 17533 - SOVICO - 20/01/2022*/
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.P_TinhThanh Else A.P_TinhThanhEN end as P_LSProvince'
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.P_QuanHuyen Else A.P_QuanHuyenEN end as P_District'
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.P_PhuongXa Else A.P_PhuongXaEN end as P_Ward'
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.AddressProvince_T Else A.ENAddressProvince_T end as T_LSProvince'
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.District_T Else A.ENDistrict_T end as T_District'
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.T_PhuongXa Else A.T_PhuongXaEN end as T_Ward'
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then A.VNRecruitSourceType Else A.ENRecruitSourceType end as LoaiNguonTuyenDung'
		Set @Sql = @Sql + @strSQL_RL17533
		/*End Rlogid 17533 - SOVICO - 20/01/2022*/

		Set @Sql = @Sql + ',*' 
		Set @Sql = @Sql + ' From RE_vDynamicCanList(nolock) A 
							Inner join dbo.fnGetAllCan_Permission('''+@UserAccountID+''','''+@FunctionID+''') PQ on A.CandidateID = PQ.CandidateID
							'+@strJoin2+'
							'+@strJoin_RL17533+' /*Rlogid 17533 - SOVICO - 20/01/2022*/
							Left join (Select top 1 * From RE_tblCanOnlineTest order by Fromdate DESC)B on A.CandidateID = B.CandidateID
							Left join (
											Select *, '','' + NhanSuDuocXemYCTD + '','' as StrNhanSuDuocXemYCTD
											From RE_tblDemand(nolock) 
									)D on A.DemandID=D.DemandID'

		--rlogID:6023
		Set @Sql = @Sql + ' Where
							 (
									D.IsBaoMat = 0 or D.IsBaoMat is null  or '''+@FunctionID+''' not in (''82451'')
									or
									(
										D.IsBaoMat = ''1'' and '''+@FunctionID+''' in (''82451'')
										and
										(
											'''+@UserAccountID+''' = D.Creater
											or
											(
												D.StrNhanSuDuocXemYCTD like ''%,'' + '''+@sEmpIDLogin+''' + '',%''
											)
										)
									)
								)
		'

		If not(isnull(@Condition,'')='')
			Set @Sql = @Sql + ' and ' + @Condition + ' order by  A.ApplyForJobDate desc,A.vFirstName,A.CandidateCode'
		Else 
			Set @Sql = @Sql + ' /*Where Active = 1*/ order by  A.ApplyForJobDate desc,A.vFirstName,A.CandidateCode'

		exec sp_executeSql @Sql
		--Select @Sql
	end
---------------------------------------
	Else If @Action ='GetListCanProject'
	BEGIN
		
		Exec	RE_spfrmCanList_Search @Action='GetListCanGeneral', @Language=@Language,@UserGroupID=@UserGroupID,@FunctionID=@FunctionID,@Condition=@Condition,@KeyWord=@KeyWord,
				@URLParam_Return='GetListCanProject',@rownumber = @rownumber, @page = @page, @GridName = @GridName,@isEnabled='0', @FromGetListCanProject = 1,@ThamGia=@ThamGia,@ChuyenNV=@ChuyenNV
		return
		/*NHANNH2 tuning PNJ xử lý tương tự mành hình danh sách ứng viên*/
		IF object_id('tempdb..#RE_spfrmDynamicCanList_GetListCanProject_Per') is not null
			DROP table [dbo].[#RE_spfrmDynamicCanList_GetListCanProject_Per]

		SELECT *
		INTO [#RE_spfrmDynamicCanList_GetListCanProject_Per]
		FROM dbo.fnGetAllCan_Permission(@UserAccountID, @FunctionID)

		CREATE INDEX IX_RE_spfrmDynamicCanList_GetListCanProject_Per_CandidateID ON dbo.[#RE_spfrmDynamicCanList_GetListCanProject_Per] (CandidateID)

		---rlogID:5823
		If OBJECT_ID('tempdb..#TableCandidate1') is not null drop table  #TableCandidate1
		Create table #TableCandidate1(CandidateID int)
		If isnull(@KeyWord,'') <> ''
		begin
			 insert into #TableCandidate1 
			 exec RE_sprptSearchWithKeyWord @Table_Name = 're_tblcandidate', @SearchString = @KeyWord
			  /*rlogID:14136*/
			 if FULLTEXTSERVICEPROPERTY('IsFullTextInstalled') =1
			 BEGIN
				If OBJECT_ID('tempdb..#TableTempID1') is not null drop table  #TableTempID1
				Create table #TableTempID1(ID nvarchar(12))

				set @KeyWord = '"*' + replace(@KeyWord,' ','" and "') + '*"'
				
				declare @stringSQL2 nvarchar(max)
				set @stringSQL2 = '
									SELECT CandidateID
									FROM [dbo].[RE_tblCandidate_CanCV]
									WHERE contains(Content, '''+@KeyWord+''');'
				
				insert into #TableTempID1
				exec(@stringSQL2)
			
				insert into #TableCandidate1 
				Select A.ID 
				From #TableTempID1 A
				Where A.ID not in (Select CandidateID From #TableCandidate1) 
				delete From #TableTempID1 
			 END
		end
		--Select * From #TableCandidate
		Declare @strJoin1 nvarchar(4000),@strKoTuyenLai_Join nvarchar(4000) Set @strJoin1 = '' Set @strKoTuyenLai_Join = ''
		Declare @strKoTuyenLai_SelectCol nvarchar(100) Set @strKoTuyenLai_SelectCol = ','''' as KoTuyenLai_JobTitle'

		If isnull(@KeyWord,'') <> '' Set @strJoin1 = 'Inner join #TableCandidate1(nolock) temp on A.CandidateID = temp.CandidateID'
		/*RL 6478*/
		If isnull(@CanhBaoKhongTuyenLaiUV,0)=1
		Begin
			Set @strKoTuyenLai_SelectCol=',Case when KoTuyenLai.CandidateID is not null then ''X'' else '''' end as KoTuyenLai_JobTitle'
			Set @strKoTuyenLai_Join ='
					Left join (
					Select distinct CandidateID 
					From RE_tblTournamentCandidate(NoLock) a 
					Left join RE_tblProjectTournament(noLock) b on a.ProjectTournamentID = B.ProjectTournamentID
					Left join RE_tblProject(NoLock) c on b.ProjectID = c.ProjectID
					Left join RE_tblDemand(NoLock) d on d.DemandID = C.DemandID
					Where a.RETournamentStatusID=''8''
					And D.LSJobTitleID = '''+isnull(convert(varchar(20),@LSJobTitleID),'')+''' 
					) as KoTuyenLai on A.CandidateID = KoTuyenLai.CandidateID'
		End
		/**/
		Declare @sql1 nvarchar(Max)		
		Set @sql1=''	
		Select @Sql = @Sql + N',Case When ''' + @Language + ''' = ''VN'' then VNJobTitle Else ENJobTitle end as VNJobTitle'	
		Select @sql1 = @sql1 + N'Select Case When ''' + @Language + ''' = ''VN'' then VNJobTitle Else ENJobTitle end as VNJobTitle,
		Case When ''' + @Language + ''' = ''VN'' then LocationVN1 Else LocationEN1 end as LocationVN1,
		Case When ''' + @Language + ''' = ''VN'' then GenderStr Else GenderStrEN end as GenderStr,
		Case When ''' + @Language + ''' = ''VN'' then EthnicName Else ENEthnicName end as EthnicName,
		Case When ''' + @Language + ''' = ''VN'' then NguonUngVienVN Else NguonUngVienEN end as NguonUngVien,
		Case When IsJoinProject is null or IsJoinProject = 0 then '''' Else ''X'' end as IsJoinProject_X,
		dbo.fnConvertNumber(A.ExpectationSalary) as ExpectationSalary,
		A.CandidateID,A.CandidateCode,A.CandidateName,A.DOB_D,
		A.Weight,A.Height,A.MobIfone,A.phone,A.Email,A.AddressStr,A.JobTitleVN1,
		A.JobTitleVN2,A.JobTitleVN3,A.LocationVN2,A.LocationVN3,A.VNMajorLevel,A.Major,A.School,A.TrainingForm,
		A.YearG,A.PassWithLevelName,A.Experience,A.Duty,A.NoiLamViecQuaKhu,A.DemandCode,
		A.ApplyForJobDate_D,A.IntroducePerson, A.LSCandidateStatusCode,A.KQTuyenDungMoiNhat,A.Status,
		/*Start RlogID: 14487 - TiKi - NhanHM4 - 12/09/2019*/
		A.FilePhoto, A.AttachFileCV,
        /*End   RlogID: 14487 - TiKi - NhanHM4 - 12/09/2019*/
		N'''+@strViewHistory+''' as ViewHistory
		'+@strKoTuyenLai_SelectCol/*RL 6478*/+'
		, row_number() over (order by case when A.CanEditTime is null or A.CanEditTime = '''' then A.CanCreateTime else A.CanEditTime end desc /*RlogID 14658*/,A.ApplyForJobDate desc,A.vFirstName,A.CandidateCode) as STT
		
		into [#RE_spfrmDynamicCanList_GetListCanProject]
		From RE_vDynamicCanList(NoLock)  A	
		Inner join [#RE_spfrmDynamicCanList_GetListCanProject_Per] (Nolock) B on A.CandidateID = B.CandidateID	
		'+@strJoin1+'		
		'+@strKoTuyenLai_Join/*RL 6478*/+'
		Where case when inProgess is null then 0 else inProgess end =0 
		/*and case when statusis null then 0 else statusis end in (0,3,5)*/
		and ('''+@ThamGia+'''=''2'' or A.IsJoinProject='''+@ThamGia+''')
		/*Start RlogID: 14382 TiKi - NhanHM4 - 11/07/2019*/
		and ('''+@ChuyenNV+'''=''2'' or A.Status='''+@ChuyenNV+''')
		/*End   RlogID: 14382 TiKi - NhanHM4 - 11/07/2019*/
		'
		
		
		If not(isnull(@Condition,'')='')
			Set @Sql1 = @Sql1 + ' and ' + @Condition
		Else 
			Set @Sql1 = @Sql1 + ' Where Active = 1'

		Set @Sql1 = @Sql1 + '
			declare @totalpages float, @totalrecords bigint

			select  @totalpages = ceiling(cast(count(*) as float)/cast(' + CASE WHEN ISNULL(@rownumber,'') = '' THEN '20' ELSE @rownumber END + ' as float)),
					@totalrecords = count(*)
			from [#RE_spfrmDynamicCanList_GetListCanProject](NOlock)

			select *, @totalpages totalpages, @totalrecords totalrecords
			from [#RE_spfrmDynamicCanList_GetListCanProject](NOlock) ' +
			CASE WHEN ISNULL(@page,'') <> '' AND ISNULL(@rownumber,'') <> '' THEN '
			where STT between ' + CONVERT(NVARCHAR(20), (@iPage - 1) * @iRowNumber + 1) + ' and ' +CONVERT(NVARCHAR(20), @iPage * @iRowNumber) 
			ELSE '' END + N'
			order by STT'

		exec sp_executeSql @Sql1
		print @Sql1
	END
---------------------------------------	
	Else If @Action ='GetListCanDemand'
	BEGIN
		Declare @sql3 nvarchar(4000)
		Set @sql3=''
		Select @sql3 = @sql3 + 'Select A.* From RE_tblProjectCandidate (nolock) B
					Left join RE_vDynamicCanList(nolock) A on A.CandidateID=B.CandidateID
					Where 1=1 and DemandID is null'
		If not(isnull(@Condition,'')='')
			Set @Sql3 = @Sql3 + ' and ' + @Condition + ' order by  A.ApplyForJobDate desc,A.vFirstName,A.CandidateCode'
		Else 
			Set @Sql3 = @Sql3 + ' Where Active = 1 order by  A.ApplyForJobDate desc,A.vFirstName,A.CandidateCode'
		exec sp_executeSql @Sql3
		print @Sql1
	END
	
	Else If @Action ='GetListResultByProject'
	BEGIN
		Declare @sql2 nvarchar(4000)
		Set @sql2=''
		Select @sql2 = @sql2 + 'Select distinct B.CandidateID, A.CandidateCode, A.CandidateName, A.VNJobTitle ,
					A.DocumentStatus_D as DocumentStatus, A.Status_D as Status, D.ProjectCode ,
					dbo.RE_fnGetProjectTourList(B.ProjectID,'''',0) as TourList,A.PhoneNumber,
					--dbo.RE_fnGetProjectDemandList(B.ProjectID) as DemandList,
					DE.DemandCode as DemandList,
					dbo.RE_fnGetProjectTourList(B.ProjectID,B.CandidateID,1) as TourListPass,
					dbo.RE_fnGetTourPassLastOfCan(B.CandidateID,B.ProjectID) as PassLast,
					dbo.RE_fnGetTypePassLastOfCan(B.CandidateID,B.ProjectID) as PassType,
					dbo.RE_fnGetSeqPassLastOfCan(B.CandidateID,B.ProjectID) as PassSeq,
					 Case B.Especial When 1 then ''X'' Else '''' end as Especial 
					From RE_tblProjectCandidate(nolock)  B
					Left join RE_vDynamicCanList(nolock) A on A.CandidateID=B.CandidateID
					--Left join RE_tblcandidateTournament(nolock) C on B.CandidateID=C.CandidateID
					Left join RE_tblDemand(nolock) DE on DE.DemandID=B.DemandID
					Left join RE_tblProject(nolock) D on D.ProjectID=B.ProjectID Where 1=1 and D.Closed=0 and B.Especial=0'
		If not(isnull(@Condition,'')='')
			Set @Sql2 = @Sql2 + ' and ' + replace(@Condition,'Gender = ','A.Gender = ') + ' order by  A.ApplyForJobDate desc,A.vFirstName,A.CandidateCode'
		Else 
			Set @Sql2 = @Sql2 + ' Where Active = 1 order by  A.ApplyForJobDate desc,A.vFirstName,A.CandidateCode'
		exec sp_executeSql @Sql2
		print @Sql2
	END
	Else If @Action='GetListCanDelete'
	BEGIN
		Declare @sql4 nvarchar(4000)
		Set @sql4=''
		Select @sql4=@sql4 + 'Select A.CandidateID, CandidateCode, CandidateName, 
		DOB_D, convert(datetime, DOB_D, 103) as Sort_DOB, GenderStr, 
		Case When ''' + @Language + '''= ''VN'' then VNJobTitle Else ENJobTitle end as JobTitle,
		ApplyForJobDate_D as ApplyForJobDate, DocumentStatus_D as DocumentStatus,		
		C.ProjectCode, A.Status_D as Status
		From RE_vDynamicCanList(nolock) A
		Left join RE_tblProjectCandidate(nolock) B on A.CandidateID=B.CandidateID 
		Left join RE_tblProject(nolock) C on C.ProjectID=B.ProjectID
		Where 1=1 and Status<>1'
		If not(isnull(@Condition,'')='')
			Set @sql4 = @sql4 + ' and ' + @Condition + ' order by  A.ApplyForJobDate desc,A.vFirstName,A.CandidateCode'
		Else 
			Set @sql4 = @sql4 + ' Where Active = 1 order by  A.ApplyForJobDate desc,A.vFirstName,A.CandidateCode'
		exec sp_executeSql @sql4
		print @sql4
	END
	Else If @Action = 'GetcboLS'
	begin
		Select	 A.*, B.Table_Name TableLS,Case @language When 'EN' then  B.TextView Else B.TextView_VN end as TextView, B.ValueView 
		From UMS_tblVietEng A 
		Left join SYS_tblcboDynamic B on A.ColumnName = B.Column_Name
		--Where 	A.TableName in ('HR_vDynamicEmpList')
	end

	Else If @Action = 'GetListCanOnlineTest'
	BEGIN
		Set @Sql = ''
		Set @Sql = 'Select distinct A.CanDidateID, A.CandidateCode,A.ApplyForJobDate,A.vFirstName, A.CandidateName, A.Demand,convert(nvarchar,B.FromDate,8) +'' - ''+ Convert(nvarchar,B.FromDate,103) as FromDate'
		Set @Sql = @Sql + ',convert(nvarchar,B.Todate,8) +'' - ''+ Convert(nvarchar,B.Todate,103) as ToDate '
		Set @Sql = @Sql + ',DOB_D,MobIfone,Email,ExpectationSalary,B.Mark '
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then JobTitleVN1 Else JobTitleEN1 end as ExpectJobTitle'	
		Set @Sql = @Sql + ',Case When ''' + @Language + ''' = ''VN'' then Position Else ENPosition end as Position'
		Set @Sql = @Sql + ' From RE_vDynamicCanList(nolock) A Inner join RE_tblCanOnlineTest(nolock) B on A.CandidateID = B.CandidateID'
		If not(isnull(@Condition,'')='')
			Set @Sql = @Sql + ' Where ' + @Condition + ' order by  A.ApplyForJobDate desc,A.vFirstName,A.CandidateCode'
		Else 
			Set @Sql = @Sql + ' /*Where Active = 1*/ order by  A.ApplyForJobDate desc,A.vFirstName,A.CandidateCode'
		print @Sql
		exec sp_executeSql @Sql
		
	END	
