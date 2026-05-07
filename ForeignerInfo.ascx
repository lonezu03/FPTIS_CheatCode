<%@ Control Language="c#" AutoEventWireup="True" CodeBehind="ForeignerInfo.ascx.cs"
    Inherits="iHRPCore.MdlHR.ForeignerInfo" TargetSchema="http://schemas.microsoft.com/intellisense/ie5" %>
<%@ Register TagPrefix="uc1" TagName="EmpHeader" Src="../../Common/Form/EmpHeader.ascx" %>
<%@ Register TagPrefix="telerik" Namespace="Telerik.Web.UI" Assembly="Telerik.Web.UI" %>
<%@ Register Assembly="Common" Namespace="iHRPCore.Com" TagPrefix="core" %>
<%@ Register TagPrefix="uc" TagName="MultiAttachButton" Src="../../Common/Form/MultiAttachButton.ascx" %>

<%@ Import Namespace="iHRPCore.Com" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Web" %>
<%@ Import Namespace="System.Data.SqlClient" %>

<% 
    string HR_SoNamHLPassport = iHRPCore.Utils.Functions.GetParamValue("HR_SoNamHLPassport");
    //rlogID:12009
    string LuuVaTiepTuc_TTNV = "";
    //Start Coding RlogID: 14797 - NhanHM4 - 23/12/2019
    string MacDinhNgayHieuLucBangNgayCap_MHThongTinVisaPassport = string.Empty;
    //End   Coding RlogID: 14797 - NhanHM4 - 23/12/2019
    /*Start Rlog: 17300 - MOVI - NhanHM4 - 10/12/2021*/
    string KiemTraNgayCap_HieuLucNhoHonNgaySinh = string.Empty;
    /*End   Rlog: 17300 - MOVI - NhanHM4 - 10/12/2021*/
    string BoBatBuocNhapNoiCapTheTamTru_MHThongTinVisaPassport = string.Empty;
    string BatBuocNhapNgayHetHanVisaPassport = string.Empty; //Rlog 18834
    string BatBuocNhapLoaiGiayPhepLD = string.Empty; //Rlog 19658
    string BatBuocNhapNoiCapPassport = string.Empty; //Rlog 19659
    string BatBuocNhapLoaiPassport = string.Empty; //Rlog 19659
    //Start 19660
    string BatBuocNhapLoaiVisa = string.Empty;
    string BatBuocNhapNoiCapVisa = string.Empty;
    string BatBuocNhapQuocGiaDen = string.Empty;
    string BatBuocNhapNgayHieuLucVisa = string.Empty;
    //END 19660
    string BBNhapSoLyLichTuPhap = string.Empty; //RLOG 20358
    string TuDongTinVaHienThiNgayHetHieuLucGPLD = string.Empty; //RLOG 21049
    string ThoiHanHieuLuc = string.Empty; //RLOG 21049
    
    System.Data.DataRow dr = clsCacheData.HR_spfrmSetupHR();
    if (dr != null)
    {
        LuuVaTiepTuc_TTNV = dr["LuuVaTiepTuc_TTNV"].ToString().ToUpper();
        MacDinhNgayHieuLucBangNgayCap_MHThongTinVisaPassport = dr["MacDinhNgayHieuLucBangNgayCap_MHThongTinVisaPassport"].ToString().ToUpper();
        KiemTraNgayCap_HieuLucNhoHonNgaySinh = dr["KiemTraNgayCap_HieuLucNhoHonNgaySinh"].ToString().ToUpper();
        BoBatBuocNhapNoiCapTheTamTru_MHThongTinVisaPassport = dr["BoBatBuocNhapNoiCapTheTamTru_MHThongTinVisaPassport"].ToString().ToUpper();
        BatBuocNhapNgayHetHanVisaPassport = dr["BatBuocNhapNgayHetHanVisaPassport"].ToString().ToUpper();
        BatBuocNhapLoaiGiayPhepLD = dr["BatBuocNhapLoaiGiayPhepLD"].ToString().ToUpper();
        BatBuocNhapNoiCapPassport = dr["BatBuocNhapNoiCapPassport"].ToString().ToUpper();
        BatBuocNhapLoaiPassport = dr["BatBuocNhapLoaiPassport"].ToString().ToUpper();

        BatBuocNhapLoaiVisa = dr["BatBuocNhapLoaiVisa"].ToString().ToUpper();
        BatBuocNhapNoiCapVisa = dr["BatBuocNhapNoiCapVisa"].ToString().ToUpper();
        BatBuocNhapQuocGiaDen = dr["BatBuocNhapQuocGiaDen"].ToString().ToUpper();
        BatBuocNhapNgayHieuLucVisa = dr["BatBuocNhapNgayHieuLucVisa"].ToString().ToUpper();
        BBNhapSoLyLichTuPhap = dr["BBNhapSoLyLichTuPhap"].ToString().ToUpper();
        TuDongTinVaHienThiNgayHetHieuLucGPLD = dr["TuDongTinVaHienThiNgayHetHieuLucGPLD"].ToString().ToUpper(); //RLOG 21049
        ThoiHanHieuLuc = dr["ThoiHanHieuLuc"].ToString().ToUpper(); //RLOG 21049
    }

    string sQuery = "LS_spfrmLoaiGiayPhepLaoDong @Activity = 'GetDataCombo'";
    DataTable dtLoaiGiayPhepLaoDong = clsCommon.GetDataTable(sQuery);
    
%>
<script>
    var dtLoaiGiayPhepLaoDong = '<%=Newtonsoft.Json.JsonConvert.SerializeObject(dtLoaiGiayPhepLaoDong.Rows)%>'
</script>
<style type="text/css">
    .style1 {
        width: 15%;
    }

    .style2 {
        /*width: 19%;*/
    }
    /* anhtt189 rlog 20947*/
    .cssColumnTable_Center {
        font-size: 8pt;
        text-align: center;
        vertical-align: middle;
        border: 1px solid rgb(43, 87, 154);
        padding: 5px;
    }

    .cssColumnTable_Top {
        font-size: 8pt;
        vertical-align: top;
        border: 1px solid rgb(43, 87, 154);
        padding: 5px;
        overflow-wrap: break-word;
        white-space: pre-line;
    }
</style>

<%--RlogID: 11692 Chuyển về MH động--%>
<style>
    #DivColumn1 {
        overflow: hidden;
        margin-bottom: 5px;
    }

    .contentFormLabel {
        width: 155px;
        float: left;
    }

    .contentFormLabel_Sub {
        width: 145px;
        margin-left: 34px;
        float: left;
    }

    .contentFormLabel-60 {
        width: 60px;
        float: left;
    }

    .control {
        width: 83%;
        float: left;
    }

    .contentFormControl {
        width: 65%;
        float: left;
    }

    .control-TEXTBOX {
        width: 81.2%;
        float: left;
    }

    .contentFormControl_Sub {
        width: 49%;
        float: left;
    }

    .control-3 {
        width: 50%;
        float: left;
    }

    .control-full {
        width: 100%;
        float: left;
    }

    .element {
        float: left;
        margin: 1px 0;
        min-height: 26px;
    }
</style>

<div id="divlblError" runat="server" style="display: none; pause: T">
    <asp:Label ID="lblErr" runat="server" CssClass="lblErr"></asp:Label>
</div>
<div class="contentForm">
    <div id="DivColumn1" class="contentGroup">
        <div class="contentFormItem full onlyItem" id="divEmpHeader" data-note="EmpHeader">
            <uc1:empheader id="HR_EmpHeader" runat="server"></uc1:empheader>
        </div>
        <div id="divLoaiGiayPhep" data-note="Loại giấy phép" class="contentFormItem full onlyItem">
            <div class="contentFormLabel">
                &nbsp;
            </div>
            <div class="contentFormControl">
                <div id="divGiayPhepLD" runat="server" style="float: left; padding-left: 20px">
                    <asp:RadioButton ID="optPermit" runat="server" AutoPostBack="true" Text="W.Permit" GroupName="optTypeGroup" Checked="true"
                        OnCheckedChanged="optType_SelectedIndexChanged" Font-Bold="True" />
                </div>
                <div id="divPassport" runat="server" style="float: left; padding-left: 20px">
                    <asp:RadioButton ID="optPassport" runat="server" AutoPostBack="true" Text="Passport" GroupName="optTypeGroup"
                        OnCheckedChanged="optType_SelectedIndexChanged" Font-Bold="True" />
                </div>
                <div id="divVisa" runat="server" style="float: left; padding-left: 20px">
                    <asp:RadioButton ID="optVisa" runat="server" AutoPostBack="true" Text="Visa" GroupName="optTypeGroup"
                        OnCheckedChanged="optType_SelectedIndexChanged" Font-Bold="True" />
                </div>
                <div id="divGiayTamTru" runat="server" style="float: left; padding-left: 20px">
                    <asp:RadioButton ID="optTempLicence" runat="server" AutoPostBack="true" Text="Temp.Licence" GroupName="optTypeGroup"
                        OnCheckedChanged="optType_SelectedIndexChanged" Font-Bold="True" />
                </div>
                <div id="divHDThueNha" runat="server" style="float: left; padding-left: 20px">
                    <div id="divoptHDThueNha" runat="server" style="display: none; pause: T">
                        <asp:RadioButton ID="optHDThueNha" runat="server" AutoPostBack="true" Text="Hợp đồng Thuê nhà" GroupName="optTypeGroup"
                            OnCheckedChanged="optType_SelectedIndexChanged" Font-Bold="True" />
                    </div>
                </div>
                <div id="divGiayPhepLaiXe" runat="server" style="float: left; padding-left: 20px">
                    <div id="divoptGiayPhepLaiXe" runat="server" style="display: none; pause: T">
                        <asp:RadioButton ID="optGiayPhepLaiXe" runat="server" AutoPostBack="true" Text="Giấy phép lái xe" GroupName="optTypeGroup"
                            OnCheckedChanged="optType_SelectedIndexChanged" Font-Bold="True" />
                    </div>
                </div>
                <%--RLOG 19677--%>
                <div id="divLyLichTuPhap" runat="server" style="float: left; padding-left: 20px; display: none; pause: T">
                    <div id="divOptLyLichTuPhap" runat="server">
                        <asp:RadioButton ID="optLyLichTuPhap" runat="server" AutoPostBack="true" Text="Lý lịch tư pháp" GroupName="optTypeGroup"
                            OnCheckedChanged="optType_SelectedIndexChanged" Font-Bold="True" />
                    </div>
                </div>
                <%--END RLOG 19677--%>
            </div>
        </div>
        <%--Giấy phép lao động--%>
        <div class="contentGroupTitleHolder" id="divWP1" data-note="Work Permit" runat="server">
            <div class="contentGroupIcon"></div>
            <div class="contentGroupTitle" id="divWP1_lbl" data-note="Work Permit - lbl">
                <asp:Label ID="lblWP_Title" runat="server" CssClass="labelSubTitle">Work Permit</asp:Label>
            </div>
        </div>
        <%--Rlog 18751--%>
        <div id="divLoaiGiayPhepLaoDong" data-note="Loại giấy phép lao động" class="contentFormItem half" runat="server">
            <div id="divWP_LoaiGiayPhepLaoDong_lbl" data-note="Loại giấy phép lao động - lbl" class="contentFormLabel">
                <asp:Label ID="lblLoaiGiayPhepLaoDong" runat="server" CssClass="label">Loại giấy phép lao động</asp:Label>
            </div>
            <div id="divWP_LoaiGiayPhepLaoDong_ctl" data-note="Loại giấy phép lao động-ctl" class="contentFormControl">
                <telerik:RadComboBox ID="cboLoaiGiayPhepLaoDong" runat="server" Skin="Simple" Width="100%" Filter="Contains" AllowCustomText="true" OnClientSelectedIndexChanged="BindingExpireDate"/>
            </div>
        </div>
        <%--End Rlog 18751--%>
        <div id="divWP_Number" data-note="Số giấy phép lao động" class="contentFormItem half" runat="server">
            <div id="divWP_Number_lbl" data-note="Số giấy phép lao động - lbl" class="contentFormLabel">
                <asp:Label ID="lblWP_Number" runat="server" CssClass="labelRequire">Number</asp:Label>
            </div>
            <div id="divWP_Number_ctl" data-note="Số giấy phép lao động-ctl" class="contentFormControl">
                <asp:TextBox ID="txtWP_Number" runat="server" CssClass="input" Width="100%" MaxLength="30"></asp:TextBox>
            </div>
        </div>
        <div id="divThoiGianWP" data-note="Thời gian Work Permit" class="contentFormItem half range-date" runat="server">
            <div id="divIssusedDate_lbl" data-note="Thời gian Work Permit - lbl" class="contentFormLabel">
                <asp:Label ID="lblWP_IssusedDate" runat="server" CssClass="labelRequire">Issued date</asp:Label>
            </div>
            <div id="divIssusedDate_ctl" data-note="Thời gian Work Permit-ctl" class="contentFormControl">
                <div>
                    <asp:TextBox ID="txtWP_IssuedDate" onblur="JavaScript:CheckDate(this);SetEffByIssued(this);" runat="server" CssClass="inputcenter fpt-datetime-custom" Width="70px" MaxLength="10"></asp:TextBox>
                </div>
                <div id="divbtnIssuedDate" runat="server">
                    <input class="datePicker" onclick="javascript:popUpCalendar(<%=this.txtWP_IssuedDate.ClientID%>);" type="button">
                </div>
                <div style="float: left">
                    <asp:Label ID="lblWP_EffectDate" runat="server" CssClass="labelRequire" Style="float: left">Effect date</asp:Label>

                </div>
                <div id="divbtnWP_EffDate" runat="server" style="float: left">
                    <asp:TextBox ID="txtWP_EffDate" onblur="JavaScript:CheckDate(this);BindingExpireDate();ngayHieuLucCongTuThamSo();" runat="server" CssClass="inputcenter fpt-datetime-custom" Width="70px" MaxLength="10" Style="float: left"></asp:TextBox>
                    <input class="datePicker" onclick="javascript:popUpCalendar(<%=this.txtWP_EffDate.ClientID%>);" type="button">
                </div>
            </div>
        </div>
        <div id="divNgayHetHan" data-note="Ngày hết hạn" class="contentFormItem half" runat="server">
            <div id="divNgayHetHan_lbl" data-note="Ngày hết hạn-lbl" class="contentFormLabel">
                <asp:Label ID="lblWP_ExpiredDate" runat="server" CssClass="label">Expired date</asp:Label>
            </div>
            <div id="divNgayHetHan_ctl" data-note="Ngày hết hạn-ctl" class="contentFormControl">
                <asp:TextBox ID="txtWP_ExpiredDate" onblur="JavaScript:CheckDate(this);" runat="server" CssClass="inputcenter fpt-datetime-custom" Width="70px" MaxLength="10"></asp:TextBox>
                <input class="datePicker" onclick="javascript:popUpCalendar(<%=this.txtWP_ExpiredDate.ClientID%>);" type="button">
            </div>
        </div>
        <div id="divNoiCap" data-note="Nơi cấp" class="contentFormItem half" runat="server">
            <div id="divNoiCap_lbl" data-note="Nơi cấp-lbl" class="contentFormLabel">
                <asp:Label ID="lblWP_IssuedPlace" runat="server" CssClass="label">Issued place</asp:Label>
            </div>
            <div id="divNoiCap_ctl" data-note="Nơi cấp-ctl" class="contentFormControl">
                <asp:TextBox ID="txtWP_IssuedPlace" runat="server" CssClass="input" Width="100%" MaxLength="150"></asp:TextBox>
            </div>
        </div>
        <%--RlogID 16139 - VGU - 26/03/2021 - QuyenPV9--%>
        <div id="divNoiCap_EN" data-note="Nơi cấp Text (EN)" data-visible="0" class="contentFormItem half" runat="server">
            <div id="divNoiCap_EN_lbl" data-note="Nơi cấp Text (EN) - lbl" class="contentFormLabel">
                <asp:Label ID="lblWP_IssuedPlace_EN" runat="server" CssClass="label">Issued place (EN)</asp:Label>
            </div>
            <div id="divNoiCap_EN_ctl" data-note="Nơi cấp Text (EN) - ctl" class="contentFormControl">
                <asp:TextBox ID="txtWP_IssuedPlace_EN" runat="server" CssClass="input" Width="100%" MaxLength="255"></asp:TextBox>
            </div>
        </div>
        <%--End RlogID 16139--%>
        <%--Start Coding RlogID: 14821 - CVN - NhanHM4 - 30/12/2019--%>
        <div id="divNoiCap_CBO" data-note="Nơi cấp province" class="contentFormItem half" runat="server">
            <div id="divNoiCap_CBO_lbl" data-note="Nơi cấp province-lbl" class="contentFormLabel">
                <asp:Label ID="lblNoiCap_Province" runat="server" CssClass="label">Nơi cấp</asp:Label>
            </div>
            <div id="divNoiCap_CBO_ctl" data-note="Nơi cấp province-ctl" class="contentFormControl">
                <telerik:RadComboBox ID="cboWP_IssuedPlace" runat="server" Skin="Simple" Width="100%" Filter="Contains" AllowCustomText="true" />
            </div>
        </div>
        <%--End   Coding RlogID: 14821 - CVN - NhanHM4 - 30/12/2019--%>
        <div id="divTinhTrang" data-note="Tình trạng" class="contentFormItem half" runat="server">
            <div id="divTinhTrang_lbl" data-note="Tình trạng-lbl" class="contentFormLabel">
                <asp:Label ID="Label7" runat="server" CssClass="label">Status</asp:Label>
            </div>
            <div id="divTinhTrang_ctl" data-note="Tình trạng-ctl" class="contentFormControl">
                <telerik:RadComboBox ID="cboWP_Status" runat="server" Skin="Simple" Width="100%" Filter="Contains" AllowCustomText="true"></telerik:RadComboBox>
            </div>
        </div>

        <%--RlogID 25189 - KPMG_V34--%>
        <div id="divJobPositionForWorkPermit" data-note="Vị trí công việc GPLĐ" data-visible="0" class="contentFormItem half" runat="server">
            <div id="divJobPositionForWorkPermit_lbl" data-note="Vị trí công việc GPLĐ - lbl" class="contentFormLabel">
                <asp:Label ID="lblJobPositionForWorkPermit" runat="server" CssClass="label">Vị trí công việc GPLĐ</asp:Label>
            </div>
            <div id="divJobPositionForWorkPermit_ctl" data-note="Vị trí công việc GPLĐ - ctl" class="contentFormControl">
                <telerik:RadComboBox ID="cboJobPositionForWorkPermit" runat="server" Skin="Simple" Width="100%" Filter="Contains" AllowCustomText="true" />
            </div>
        </div>
        <%--End RlogID 25189--%>

        <div id="divGhiChu" data-note="Ghi chú" class="contentFormItem full onlyItem" runat="server">
            <div id="divGhiChu_lbl" data-note="Ghi chú-lbl" class="contentFormLabel">
                <asp:Label ID="Label10" runat="server" CssClass="label">Note</asp:Label>
            </div>
            <div id="divGhiChu_ctl" data-note="Ghi chú-ctl" class="contentFormControl">
                <asp:TextBox ID="txtWP_Note" runat="server" CssClass="input" Width="100%" MaxLength="255"></asp:TextBox>
            </div>
        </div>
        <div id="divCoLyLichTuPhap" data-note="Có lý lịch tư pháp" class="contentFormItem full onlyItem" runat="server">
            <div id="divCoLyLichTuPhap_lbl" data-note="Có lý lịch tư pháp-lbl" class="contentFormLabel">
                <asp:Label ID="Label16" runat="server" CssClass="label">Có lý lịch tư pháp</asp:Label>
            </div>
            <div id="divCoLyLichTuPhap_ctl" data-note="Có lý lịch tư pháp-ctl" class="contentFormControl">
                <asp:CheckBox ID="chkWPTuPhap" runat="server" />
            </div>
        </div>
        <div id="divReturnPermit" data-note="Return Permit" class="contentFormItem half" runat="server">
            <div id="divReturnPermit_lbl" data-note="Return Permit-lbl" class="contentFormLabel">
                <asp:Label ID="Label13" runat="server" CssClass="label">ReturnPermit</asp:Label>
            </div>
            <div id="divReturnPermit_ctl" data-note="Return Permit-ctl" class="contentFormControl">
                <asp:CheckBox ID="chkReturn" runat="server" onclick="ShowReturnDate_WP();" />
            </div>
        </div>
        <div id="divReturnDate" data-note="Return Date" class="contentFormItem half" runat="server">
            <div id="divReturnDate_lbl" data-note="Return Date-lbl" class="contentFormLabel">
                <asp:Label ID="Label14" runat="server" CssClass="labelrequire">ReturnDate</asp:Label>
            </div>
            <div id="divReturnDate_ctl" data-note="Return Date-ctl" class="contentFormControl">
                <asp:TextBox ID="txtReturnDate" runat="server" onblur="JavaScript:CheckDate(this)" CssClass="inputcenter fpt-datetime-custom" Width="70px" MaxLength="10"></asp:TextBox>
                <input class="datePicker" onclick="javascript:popUpCalendar(<%=this.txtReturnDate.ClientID%>);" type="button">
            </div>
        </div>
        <%--Passport--%>
        <div class="contentGroupTitleHolder" id="divPass_Title" data-note="Pass Title" runat="server">
            <div class="contentGroupIcon" id="divPass_Title_lbl" data-note="Work Permit - lbl"></div>
            <div class="contentGroupTitle" id="divPass_Title_ctl" data-note="Work Permit - ctl">
                <asp:Label ID="lblPass_Title" runat="server" CssClass="labelSubTitle">Passport</asp:Label>
            </div>
        </div>
        <div id="divNameOnPassport" data-note="Passport name" class="contentFormItem half" runat="server">
            <div id="divNameOnPassport_lbl" data-note="Passport name - lbl" class="contentFormLabel">
                <asp:Label ID="lblNameOnPassport" runat="server" CssClass="label">Tên trên hộ chiếu</asp:Label>
            </div>
            <div id="divNameOnPassport_ctl" data-note="Passport name-ctl" class="contentFormControl">
                <asp:TextBox ID="txtNameOnPassport" runat="server" CssClass="input" Width="100%" MaxLength="30"></asp:TextBox>
            </div>
        </div>
        <div id="divPassNumber" data-note="Passport Number" class="contentFormItem half" runat="server">
            <div id="divPassNumber_lbl" data-note="Passport Number - lbl" class="contentFormLabel">
                <asp:Label ID="lblPass_Number" runat="server" CssClass="labelRequire">Number</asp:Label>
            </div>
            <div id="divPassNumber_ctl" data-note="Passport Number-ctl" class="contentFormControl">
                <asp:TextBox ID="txtPass_Number" runat="server" CssClass="input" Width="150px" MaxLength="30"></asp:TextBox>
            </div>
        </div>
        <div id="divPass_IssusedDate" data-note="Thời gian Passport" class="contentFormItem half range-date" runat="server">
            <div id="divPass_IssusedDate_lbl" data-note="Thời gian Passportt - lbl" class="contentFormLabel">
                <asp:Label ID="lblPass_IssusedDate" runat="server" CssClass="labelRequire">Issued date</asp:Label>
            </div>
            <div id="divPass_IssusedDate_ctl" data-note="Thời gian Passport-ctl" class="contentFormControl">
                <div>
                    <div style="float: left">
                        <asp:TextBox ID="txtPass_IssuedDate" onblur="JavaScript:CheckDate(this);SetEffByIssued(this);" runat="server" CssClass="inputcenter fpt-datetime-custom" Width="70px" MaxLength="10"></asp:TextBox>
                    </div>
                    <div id="divBtnPassIssuedDate" runat="server" style="float: left">
                        <input class="datePicker" onclick="javascript:popUpCalendar(<%=this.txtPass_IssuedDate.ClientID%>);" type="button">
                    </div>
                    <div style="float: left;">
                        <asp:Label ID="lblPass_EffectDate" runat="server" CssClass="labelRequire fpt-date-between-label">Effect date</asp:Label>
                    </div>
                    <div id="divbtnPass_EffDate" runat="server" style="float: left">
                        <asp:TextBox ID="txtPass_EffDate" onblur="JavaScript:CheckDate(this);Check_SoNamHLPassport(this);" runat="server" CssClass="inputcenter fpt-datetime-custom" Width="70px" MaxLength="10"></asp:TextBox>
                        <input class="datePicker" onclick="javascript:popUpCalendar(<%=this.txtPass_EffDate.ClientID%>);" type="button">
                    </div>
                </div>
            </div>
        </div>
        <div id="divNgayHetHanPP" data-note="Ngày hết hạn Passport" class="contentFormItem half" runat="server">
            <div id="divNgayHetHanPP_lbl" data-note="Ngày hết hạn Passport-lbl" class="contentFormLabel">
                <asp:Label ID="Label6" runat="server" CssClass="label">End eff date</asp:Label>
            </div>
            <div id="divNgayHetHanPP_ctl" data-note="Ngày hết hạn Passport-ctl" class="contentFormControl">
                <asp:TextBox ID="txtPass_EndEffDate" onblur="JavaScript:CheckDate(this);Check_SoNamHLPassport(this);" runat="server" CssClass="inputcenter fpt-datetime-custom" Width="70px" MaxLength="10"></asp:TextBox>
                <input class="datePicker" onclick="javascript:popUpCalendar(<%=this.txtPass_EndEffDate.ClientID%>);" type="button">
                <asp:TextBox runat="server" ID="txtTempDate" Style="display: none"></asp:TextBox>
            </div>
        </div>
        <div id="divNoiCapPP" data-note="Nơi cấp Pasport" class="contentFormItem half" runat="server">
            <div id="divNoiCapPP_lbl" data-note="Nơi cấp Pasport-lbl" class="contentFormLabel">
                <asp:Label ID="lblPass_IssuedPlace" runat="server" CssClass="label">Issued place</asp:Label>
            </div>
            <div id="divNoiCapPP_ctl" data-note="Nơi cấp Pasport-ctl" class="contentFormControl">
                <asp:TextBox ID="txtPass_IssuedPlace" runat="server" CssClass="input" Width="100%" MaxLength="150" TextMode="SingleLine"></asp:TextBox>
            </div>
        </div>
        <%--RlogID 16139 - VGU - 26/03/2021 - QuyenPV9--%>
        <div id="divNoiCapPP_EN" data-note="Nơi cấp Pasport Text (EN)" data-visible="0" class="contentFormItem half" runat="server">
            <div id="divNoiCapPP_EN_lbl" data-note="Nơi cấp Pasport Text (EN) - lbl" class="contentFormLabel">
                <asp:Label ID="lblPass_IssuedPlace_EN" runat="server" CssClass="label">Issued place (EN)</asp:Label>
            </div>
            <div id="divNoiCapPP_EN_ctl" data-note="Nơi cấp Pasport Text (EN) - ctl" class="contentFormControl">
                <asp:TextBox ID="txtPass_IssuedPlace_EN" runat="server" CssClass="input" Width="100%" MaxLength="255"></asp:TextBox>
            </div>
        </div>
        <%--End RlogID 16139--%>
        <%--Start Coding RlogID: 14821 - CVN - NhanHM4 - 30/12/2019--%>
        <div id="divNoiCapPP_CBO" data-note="Nơi cấp Pasport province" class="contentFormItem half" runat="server">
            <div id="divNoiCapPP_CBO_lbl" data-note="Nơi cấp Pasport province-lbl" class="contentFormLabel">
                <asp:Label ID="lblPass_NoiCap_Province" runat="server" CssClass="label">Nơi cấp</asp:Label>
            </div>
            <div id="divNoiCapPP_CBO_ctl" data-note="Nơi cấp Pasport province-ctl" class="contentFormControl">
                <telerik:RadComboBox ID="cboPass_IssuedPlace" runat="server" Skin="Simple" Width="100%" Filter="Contains" AllowCustomText="true" />
            </div>
        </div>
        <%--End   Coding RlogID: 14821 - CVN - NhanHM4 - 30/12/2019--%>
        <div id="divTrangThaiPP" data-note="Tình trạng Pasport" class="contentFormItem half" runat="server">
            <div id="divTrangThaiPP_lbl" data-note="Tình trạng Pasport-lbl" class="contentFormLabel">
                <asp:Label ID="Label5" runat="server" CssClass="label">Passport status</asp:Label>
            </div>
            <div id="divTrangThaiPP_ctl" data-note="Tình trạng Pasport-ctl" class="contentFormControl">
                <telerik:RadComboBox ID="cboPass_Status" runat="server" Skin="Simple" Width="100%" Filter="Contains" AllowCustomText="true">
                </telerik:RadComboBox>
            </div>
        </div>

        <%--RlogID 25190 - KPMG_V34--%>
        <div id="divQuocGiaPP" data-note="Quốc gia Passport" data-visible="0" class="contentFormItem half" runat="server">
            <div id="divQuocGiaPP_lbl" data-note="Quốc gia Passport - lbl" class="contentFormLabel">
                <asp:Label ID="lblQuocGiaPP" runat="server" CssClass="label">Quốc gia Passport</asp:Label>
            </div>
            <div id="divQuocGiaPP_ctl" data-note="Quốc gia Passport - ctl" class="contentFormControl">
                <telerik:RadComboBox ID="cboQuocGiaPP" runat="server" Skin="Simple" Width="100%" Filter="Contains" AllowCustomText="true" />
            </div>
        </div>
        <%--End 25190 KPMG_V34--%>

        <div id="divGhiChuPP" data-note="Ghi chú Pasport" class="contentFormItem  full onlyItem" runat="server">
            <div id="divGhiChuPP_lbl" data-note="Ghi chú Pasport-lbl" class="contentFormLabel">
                <asp:Label ID="Label11" runat="server" CssClass="label">Note</asp:Label>
            </div>
            <div id="divGhiChuPP_ctl" data-note="Ghi chú Pasport-ctl" class="contentFormControl">
                <asp:TextBox ID="txtPass_Note" runat="server" CssClass="input" Width="100%" MaxLength="255"></asp:TextBox>
            </div>
        </div>

        <div id="divPassportType" data-note="Loại Pasport" class="contentFormItem half" runat="server">
            <div id="divPassportType_lbl" data-note="Loại Pasport-lbl" class="contentFormLabel">
                <asp:Label ID="Label2" runat="server" CssClass="label">Passport type</asp:Label>
            </div>
            <div id="divPassportType_ctl" data-note="Loại Pasport-ctl" class="contentFormControl">
                <telerik:RadComboBox ID="cboPass_Type" runat="server" Skin="Simple" Width="100%" Filter="Contains" MarkFirstMatch="true" />
            </div>
        </div>
        <%--Visa--%>
        <div class="contentGroupTitleHolder" id="divVisaTitle" data-note="Visa Title" runat="server">
            <div class="contentGroupIcon"></div>
            <div class="contentGroupTitle" id="divVisa_Title_lbl" data-note="Work Permit - lbl">
                <asp:Label ID="lblVisa_Title" runat="server">Visa</asp:Label>
            </div>
        </div>

        <div id="divVisaNumber" data-note="Visa Number" class="contentFormItem half" runat="server">
            <div id="divVisaNumber_lbl" data-note="Visa Number - lbl" class="contentFormLabel">
                <asp:Label ID="lblVisa_Number" runat="server" CssClass="labelRequire">Number</asp:Label>
            </div>
            <div id="divVisaNumber_ctl" data-note="Visa Number-ctl" class="contentFormControl">
                <asp:TextBox ID="txtVisa_Number" runat="server" CssClass="input" Width="150px" MaxLength="30"></asp:TextBox>
            </div>
        </div>
        <div id="divThoiGianVisa" data-note="Thời gian Visa" class="contentFormItem half range-date" runat="server">
            <div id="divThoiGianVisa_lbl" data-note="Thời gian Visa - lbl" class="contentFormLabel">
                <asp:Label ID="lblVisa_IssusedDate" runat="server" CssClass="labelRequire">Issued date</asp:Label>
            </div>
            <div id="divThoiGianVisa_ctl" data-note="Thời gian Visa-ctl" class="contentFormControl">
                <div>
                    <div style="float: left">
                        <asp:TextBox ID="txtVisa_IssuedDate" onblur="JavaScript:CheckDate(this);SetEffByIssued(this);" runat="server" CssClass="inputcenter fpt-datetime-custom" Width="70px" MaxLength="10"></asp:TextBox>
                    </div>
                    <div id="divBtnVisa_IssuedDate" runat="server" style="float: left">
                        <input class="datePicker" onclick="javascript:popUpCalendar(<%=this.txtVisa_IssuedDate.ClientID%>);" type="button">
                    </div>
                    <div style="float: left;">
                        <asp:Label ID="lblVisa_EffectDate" runat="server" CssClass="labelRequire">Effect date</asp:Label>
                    </div>
                    <div id="divBtnVisa_EffDate" runat="server" style="float: left">
                        <asp:TextBox ID="txtVisa_EffDate" onblur="JavaScript:CheckDate(this);" runat="server" CssClass="inputcenter fpt-datetime-custom" Width="70px" MaxLength="10"></asp:TextBox>
                        <input class="datePicker" onclick="javascript:popUpCalendar(<%=this.txtVisa_EffDate.ClientID%>);" type="button">
                    </div>
                </div>
            </div>
        </div>
        <div id="divNgayHetHanVisa" data-note="Ngày hết hạn Visa" class="contentFormItem half" runat="server">
            <div id="divNgayHetHanVisa_lbl" data-note="Ngày hết hạn Visa-lbl" class="contentFormLabel">
                <asp:Label ID="lblVisa_ExpiredDate" runat="server" CssClass="label">Expired date</asp:Label>
            </div>
            <div id="divNgayHetHanVisa_ctl" data-note="Ngày hết hạn Visa-ctl" class="contentFormControl">
                <asp:TextBox ID="txtVisa_ExpiredDate" onblur="JavaScript:CheckDate(this)" runat="server"
                    CssClass="inputcenter fpt-datetime-custom" Width="70px" MaxLength="10"></asp:TextBox>
                <input class="datePicker" onclick="javascript:popUpCalendar(<%=this.txtVisa_ExpiredDate.ClientID%>);" type="button">
            </div>
        </div>
        <%--Start Coding RlogID: 15988 - APOLLO - Bomnv - 08/02/2021--%>
        <div id="divLoaiVisa" data-note="Loại Visa" class="contentFormItem half" runat="server">
            <div id="divLoaiVisa_lbl" data-note="Loại Visa-lbl" class="contentFormLabel">
                <asp:Label ID="lblLoaiVisa" runat="server" CssClass="label">Loại Visa</asp:Label>
            </div>
            <div id="divLoaiVisa_ctl" data-note="Loại Visa-ctl" class="contentFormControl">
                <telerik:RadComboBox ID="cboLoaiVisaID" runat="server" Skin="Simple" Width="100%" Filter="Contains" AllowCustomText="true" />
            </div>
        </div>
        <%--End   Coding RlogID: 15988 - APOLLO - Bomnv - 08/02/2021--%>
        <div id="divNoiCapVisa" data-note="Nơi cấp Visa" class="contentFormItem half" runat="server">
            <div id="divNoiCapVisa_lbl" data-note="Nơi cấp Visa-lbl" class="contentFormLabel">
                <asp:Label ID="lblVisa_IssuedPlace" runat="server" CssClass="label">Issued place</asp:Label>
            </div>
            <div id="divNoiCapVisa_ctl" data-note="Nơi cấp Visa-ctl" class="contentFormControl">
                <asp:TextBox ID="txtVisa_IssuedPlace" runat="server" CssClass="input" Width="100%"
                    MaxLength="150"></asp:TextBox>
            </div>
        </div>
        <%--Start Rlog:18669 VuNH49 03/11/2022--%>
        <div id="divQuocGiaDen" data-note="Quốc gia đến" class="contentFormItem half" runat="server">
            <div id="divQuocGiaDen_lbl" data-note="Quốc gia đến-lbl" class="contentFormLabel">
                <asp:Label ID="lblQuocGiaDen" runat="server" CssClass="label">Quốc gia đến</asp:Label>
            </div>
            <div id="divQuocGiaDen_ctl" data-note="Quốc gia đến-ctl" class="contentFormControl">
                <telerik:RadComboBox ID="cboQuocGiaDenID" runat="server" Skin="Simple" Width="100%" Filter="Contains" AllowCustomText="true" />
            </div>
        </div>
        <%--End Rlog:18669 VuNH49 03/11/2022--%>
        
        <%--RlogID 16139 - VGU - 26/03/2021 - QuyenPV9--%>
        <div id="divNoiCapVisa_EN" data-note="Nơi cấp Visa Text (EN)" data-visible="0" class="contentFormItem half" runat="server">
            <div id="divNoiCapVisa_EN_lbl" data-note="Nơi cấp Visa Text (EN) - lbl" class="contentFormLabel">
                <asp:Label ID="lblVisa_IssuedPlace_EN" runat="server" CssClass="label">Issued place (EN)</asp:Label>
            </div>
            <div id="divNoiCapVisa_EN_ctl" data-note="Nơi cấp Visa Text (EN) - ctl" class="contentFormControl">
                <asp:TextBox ID="txtVisa_IssuedPlace_EN" runat="server" CssClass="input" Width="100%" MaxLength="255"></asp:TextBox>
            </div>
        </div>
        <%--End RlogID 16139--%>

        <%--Start Coding RlogID: 14821 - CVN - NhanHM4 - 30/12/2019--%>
        <div id="divNoiCapVisa_CBO" data-note="Nơi cấp Pasport province" class="contentFormItem half" runat="server">
            <div id="divNoiCapVisa_CBO_lbl" data-note="Nơi cấp Pasport province-lbl" class="contentFormLabel">
                <asp:Label ID="lblVisa_NoiCap_Province" runat="server" CssClass="label">Nơi cấp</asp:Label>
            </div>
            <div id="divNoiCapVisa_CBO_ctl" data-note="Nơi cấp Pasport province-ctl" class="contentFormControl">
                <telerik:RadComboBox ID="cboVisa_IssuedPlace" runat="server" Skin="Simple" Width="100%" Filter="Contains" AllowCustomText="true" />
            </div>
        </div>
        <%--End   Coding RlogID: 14821 - CVN - NhanHM4 - 30/12/2019--%>
        <div id="divTrangThaiVisa" data-note="Tình trạng Visa" class="contentFormItem half" runat="server">
            <div id="divTrangThaiVisa_lbl" data-note="Tình trạng Visa-lbl" class="contentFormLabel">
                <asp:Label ID="Label3" runat="server" CssClass="label">Status</asp:Label>
            </div>
            <div id="divTrangThaiVisa_ctl" data-note="Tình trạng Visa-ctl" class="contentFormControl">
                <telerik:RadComboBox ID="cboVisa_Status" runat="server" Skin="Simple" Width="100%" Filter="Contains" AllowCustomText="true">
                </telerik:RadComboBox>
            </div>
        </div>

        <%--RlogID 25190 - KPMG_V34--%>
        <div id="divQuocGiaVisa" data-note="Quốc gia Visa" data-visible="0" class="contentFormItem half" runat="server">
            <div id="divQuocGiaVisa_lbl" data-note="Quốc gia Visa - lbl" class="contentFormLabel">
                <asp:Label ID="lblQuocGiaVisa" runat="server" CssClass="label">Quốc gia Visa</asp:Label>
            </div>
            <div id="divQuocGiaVisa_ctl" data-note="Quốc gia Visa - ctl" class="contentFormControl">
                <telerik:RadComboBox ID="cboQuocGiaVisa" runat="server" Skin="Simple" Width="100%" Filter="Contains" AllowCustomText="true" />
            </div>
        </div>
        <%--End 25190 KPMG_V34--%>

        <div id="divFee" data-note="Fee" class="contentFormItem full onlyItem" runat="server">
            <div id="divFee_lbl" data-note="Ghi chú Pasport-lbl" class="contentFormLabel">
                <asp:Label ID="Label15" runat="server" CssClass="label">Fee</asp:Label>
            </div>
            <div id="divFee_ctl" data-note="Ghi chú Pasport-ctl" class="contentFormControl">
                <asp:TextBox ID="txtVisa_Fee" runat="server" CssClass="input" Width="100%" MaxLength="20" onkeyup="JavaScript:checkNumeric(this)" Style="text-align: right"></asp:TextBox>
            </div>
        </div>
        <div id="divChkPaidbyEmp" data-note="Nhân viên trả tiền Visa" class="contentFormItem half" runat="server">
            <div id="divChkPaidbyEmplbl" data-note="Nhân viên trả tiền-lbl" class="contentFormLabel">
                <asp:Label ID="Label12" runat="server" CssClass="label">PaidbyEmp</asp:Label>
            </div>
            <div id="divChkPaidbyEmp_ctl" data-note="Nhân viên trả tiền-ctl" class="contentFormControl">
                <asp:CheckBox ID="chkPaidbyEmp" runat="server" />
            </div>
        </div>
        <div id="divGhiChuVisa" data-note="Ghi chú Visa" class="contentFormItem half" runat="server">
            <div id="divGhiChuVisa_lbl" data-note="Ghi chú Pasport-lbl" class="contentFormLabel">
                <asp:Label ID="Label9" runat="server" CssClass="label">Note</asp:Label>
            </div>
            <div id="divGhiChuVisa_ctl" data-note="Ghi chú Pasport-ctl" class="contentFormControl">
                <asp:TextBox ID="txtVisa_Note" runat="server" CssClass="input" Width="100%" MaxLength="255"></asp:TextBox>
            </div>
        </div>

        <%--fix mail VGU MoTV - 07/04/2021 - QuyenPV9--%>
        <div id="divThongTinKhac1_Visa" data-note="Thông tin khác 1 Visa" class="contentFormItem full onlyItem" runat="server" data-visible="0">
            <div id="divThongTinKhac1_Visa_lbl" data-note="Thông tin khác 1 Visa-lbl" class="contentFormLabel">
                <asp:Label ID="lblVisa_OtherInfo1" runat="server" CssClass="label">Thông tin khác 1 Visa</asp:Label>
            </div>
            <div id="divThongTinKhac1_Visa_ctl" data-note="Thông tin khác 1 Visa-ctl" class="contentFormControl">
                <asp:TextBox ID="txtVisa_OtherInfo1" runat="server" CssClass="input" Style="width: 100%"
                    MaxLength="255"></asp:TextBox>
            </div>
        </div>
        <div id="divThongTinKhac2_Visa" data-note="Thông tin khác 2 Visa" class="contentFormItem full onlyItem" runat="server" data-visible="0">
            <div id="divThongTinKhac2_Visa_lbl" data-note="Thông tin khác 2 Visa-lbl" class="contentFormLabel">
                <asp:Label ID="lblVisa_OtherInfo2" runat="server" CssClass="label">Thông tin khác 2 Visa</asp:Label>
            </div>
            <div id="divThongTinKhac2_Visa_ctl" data-note="Thông tin khác 2 Visa-ctl" class="contentFormControl">
                <asp:TextBox ID="txtVisa_OtherInfo2" runat="server" CssClass="input" Style="width: 100%" MaxLength="255"></asp:TextBox>
            </div>
        </div>
        <div id="divThongTinKhac3_Visa" data-note="Thông tin khác 3 Visa" class="contentFormItem full onlyItem" runat="server" data-visible="0">
            <div id="divThongTinKhac3_Visa_lbl" data-note="Thông tin khác 3 Visa-lbl" class="contentFormLabel">
                <asp:Label ID="lblVisa_OtherInfo3" runat="server" CssClass="label">Thông tin khác 3 Visa</asp:Label>
            </div>
            <div id="divThongTinKhac3_Visa_ctl" data-note="Thông tin khác 3 Visa-ctl" class="contentFormControl">
                <asp:TextBox ID="txtVisa_OtherInfo3" runat="server" CssClass="input" Style="width: 100%"
                    MaxLength="255"></asp:TextBox>
            </div>
        </div>
        <%--End fix mail VGU--%>

        <%--Giấy tạm trú--%>
        <div class="contentGroupTitleHolder" id="divTempLic" data-note="Giấy tạm trú" runat="server">
            <div class="contentGroupIcon"></div>
            <div class="contentGroupTitle" id="divTempLic_lbl" data-note="Giấy tạm trú - lbl">
                <asp:Label ID="Label1" runat="server" CssClass="labelSubTitle">Temporary licence</asp:Label>
            </div>
        </div>
        <div id="divGiayTamTruSo" data-note="Giấy tạm trú số" class="contentFormItem half" runat="server">
            <div id="divGiayTamTruSo_lbl" data-note="Giấy tạm trú số - lbl" class="contentFormLabel">
                <asp:Label ID="Label36" runat="server" CssClass="label">No</asp:Label>
            </div>
            <div id="divGiayTamTruSo_ctl" data-note="Giấy tạm trú số-ctl" class="contentFormControl">
                <asp:TextBox ID="txtTempLic_Number" CssClass="input" MaxLength="30" runat="server" Width="150px"></asp:TextBox>
            </div>
        </div>
        <div id="divThoiGianTamTru" data-note="Thời gian tạm trú" class="contentFormItem half" runat="server">
            <div id="divThoiGianTamTru_lbl" data-note="Thời gian Visa - lbl" class="contentFormLabel">
                <asp:Label ID="Label18" runat="server" CssClass="labelRequire">Issued date</asp:Label>
            </div>
            <div id="divThoiGianTamTru_ctl" data-note="Thời gian Visa-ctl" class="contentFormControl">
                <div>
                    <div style="float: left">
                        <asp:TextBox ID="txtTempLic_IssuedDate" onblur="JavaScript:CheckDate(this);SetEffByIssued(this);" runat="server" CssClass="inputcenter fpt-datetime-custom" Width="70px" MaxLength="10"></asp:TextBox>
                    </div>
                    <div id="divBtnTempLic_IssuedDate" runat="server" style="float: left">
                        <input class="datePicker" onclick="javascript:popUpCalendar(<%=this.txtTempLic_IssuedDate.ClientID%>);" type="button">
                    </div>
                    <div style="float: left">
                        <asp:Label ID="lblTempLic_EffDate" Style="display: none" runat="server" CssClass="label">Effect date</asp:Label>
                        <div id="DIVTempLic_EffDate" runat="server" style="display: none">
                            <asp:TextBox ID="txtTempLic_EffDate" onblur="JavaScript:CheckDate(this)" runat="server" CssClass="inputcenter fpt-datetime-custom" Width="70px" MaxLength="10"></asp:TextBox>
                            <input class="datePicker" onclick="javascript:popUpCalendar(<%=this.txtTempLic_EffDate.ClientID%>);" type="button">
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div id="divNgayHetHanTamTru" data-note="Ngày hết hạn giấy tạm trú" class="contentFormItem half" runat="server">
            <div id="divNgayHetHanTamTru_lbl" data-note="Ngày hết hạn tạm trú-lbl" class="contentFormLabel">
                <asp:Label ID="Label20" runat="server" CssClass="label">Expired date</asp:Label>
            </div>
            <div id="divNgayHetHanTamTru_ctl" data-note="Ngày hết hạn tạm trú-ctl" class="contentFormControl">
                <asp:TextBox ID="txtTempLic_ExpiredDate" onblur="JavaScript:CheckDate(this)" runat="server" CssClass="inputcenter fpt-datetime-custom" Width="70px" MaxLength="10"></asp:TextBox>
                <input class="datePicker" onclick="javascript:popUpCalendar(<%=this.txtTempLic_ExpiredDate.ClientID%>);" type="button">
            </div>
        </div>
        <div id="divNoiCapTamTru" data-note="Nơi cấp tạm trú" class="contentFormItem half" runat="server">
            <div id="divNoiCapTamTru_lbl" data-note="Nơi cấp tạm trú-lbl" class="contentFormLabel">
                <asp:Label ID="Label21" runat="server" CssClass="label">Issued place</asp:Label>
            </div>
            <div id="divNoiCapTamTru_ctl" data-note="Nơi cấp tạm trú-ctl" class="contentFormControl">
                <asp:TextBox ID="txtTempLic_IssuedPlace" runat="server" CssClass="input" Width="100%" MaxLength="150"></asp:TextBox>
            </div>
        </div>
        <%--RlogID 16139 - VGU - 26/03/2021 - QuyenPV9--%>
        <div id="divNoiCapTamTru_EN" data-note="Nơi cấp tạm trú Text (EN)" data-visible="0" class="contentFormItem half" runat="server">
            <div id="divNoiCapTamTru_EN_lbl" data-note="Nơi cấp tạm trú Text (EN) - lbl" class="contentFormLabel">
                <asp:Label ID="lblTempLic_IssuedPlace_EN" runat="server" CssClass="label">Issued place (EN)</asp:Label>
            </div>
            <div id="divNoiCapTamTru_EN_ctl" data-note="Nơi cấp tạm trú Text (EN) - ctl" class="contentFormControl">
                <asp:TextBox ID="txtTempLic_IssuedPlace_EN" runat="server" CssClass="input" Width="100%" MaxLength="255"></asp:TextBox>
            </div>
        </div>
        <%--End RlogID 16139--%>
        <%--Start Coding RlogID: 14821 - CVN - NhanHM4 - 30/12/2019--%>
        <div id="divNoiCapTamTru_CBO" data-note="Nơi cấp tạm trụ province" class="contentFormItem half" runat="server" style="display: none; pause: T">
            <div id="divNoiCapTamTru_CBO_lbl" data-note="Nơi cấp tạm trụ province-lbl" class="contentFormLabel">
                <asp:Label ID="lblTamTru_NoiCap_Province" runat="server" CssClass="label">Nơi cấp</asp:Label>
            </div>
            <div id="divNoiCapTamTru_CBO_ctl" data-note="Nơi cấp tạm trụ province-ctl" class="contentFormControl">
                <telerik:RadComboBox ID="cboTempLic_IssuedPlace" runat="server" Skin="Simple" Width="100%" Filter="Contains" AllowCustomText="true" />
            </div>
        </div>
        <%--End   Coding RlogID: 14821 - CVN - NhanHM4 - 30/12/2019--%>
        <div id="divTrangThaiTamTru" data-note="Tình trạng tạm trú" class="contentFormItem half" runat="server">
            <div id="divTrangThaiTamTru_lbl" data-note="Tình trạng tạm trú-lbl" class="contentFormLabel">
                <asp:Label ID="Label22" runat="server" CssClass="label">Status</asp:Label>
            </div>
            <div id="divTrangThaiTamTru_ctl" data-note="Tình trạng tạm trú-ctl" class="contentFormControl">
                <telerik:RadComboBox ID="cboTempLic_Status" runat="server" Skin="Simple" Width="150px" Filter="Contains" MarkFirstMatch="true"></telerik:RadComboBox>
            </div>
        </div>

        <div id="divLoaiGiayTamTru" data-note="Loại giấy tạm trú" class="contentFormItem half" runat="server" style="display: none; pause: T;">
            <div id="divLoaiGiayTamTru_lbl" data-note="Loại giấy tạm trú-lbl" class="contentFormLabel">
                <asp:Label ID="lblLoaiGiayTamTru" runat="server" CssClass="label">Loại giấy tạm trú</asp:Label>
            </div>
            <div id="divLoaiGiayTamTru_ctl" data-note="Loại giấy tạm trú-ctl" class="contentFormControl">
                <telerik:RadComboBox ID="cboLoaiGiayTamTru" runat="server" Skin="Simple" Width="100%" Filter="Contains" MarkFirstMatch="true"></telerik:RadComboBox>
            </div>
        </div>

        <div id="divDiaChi" data-note="Địa chỉ tạm trú" class="contentFormItem half" runat="server">
            <div id="divDiaChiTamTru_lbl" data-note="Địa chỉ tạm trú-lbl" class="contentFormLabel">
                <asp:Label ID="Label4" runat="server" CssClass="label">Địa chỉ tạm trú</asp:Label>
            </div>
            <div id="divDiaChiTamTru_ctl" data-note="Địa chỉ tạm trú-ctl" class="contentFormControl">
                <asp:TextBox ID="txtTempLic_Add" runat="server" CssClass="input" Width="100%" MaxLength="200"></asp:TextBox>
            </div>
        </div>
        <div id="divGhiChuTamTru" data-note="Ghi chú tạm trú" class="contentFormItem half" runat="server">
            <div id="divGhiChuTamTru_lbl" data-note="Ghi chú tạm trú-lbl" class="contentFormLabel">
                <asp:Label ID="Label23" runat="server" CssClass="label">Note</asp:Label>
            </div>
            <div id="divGhiChuTamTru_ctl" data-note="Ghi chú tạm trú-ctl" class="contentFormControl">
                <asp:TextBox ID="txtTempLic_Note" runat="server" CssClass="input" Width="100%" MaxLength="255"></asp:TextBox>
            </div>
        </div>
        <%--Hợp đồng thuê nhà--%>
        <div class="contentGroupTitleHolder" id="divTenancy_Title" data-note="Tenancy Title" runat="server">
            <div class="contentGroupIcon" id="divTenancy_Title_lbl" data-note="Work Permit - lbl"></div>
            <div class="contentGroupTitle" id="divTenancy_Title_ctl" data-note="Work Permit - ctl">
                <asp:Label ID="lblTenancy_Title" runat="server" CssClass="labelSubTitle">Tenancy</asp:Label>
            </div>
        </div>
        <div id="divSoHDThueNha" data-note="Số HĐ thuê nhà" class="contentFormItem half" runat="server">
            <div id="divSoHDThueNha_lbl" data-note="Số HĐ thuê nhà-lbl" class="contentFormLabel">
                <asp:Label ID="Label24" runat="server" CssClass="label">Số hợp đồng</asp:Label>
            </div>
            <div id="divSoHDThueNha_ctl" data-note="Số HĐ thuê nhà-ctl" class="contentFormControl">
                <asp:TextBox ID="txtSoHopDong" runat="server" CssClass="input" Style="width: 100%" MaxLength="255"></asp:TextBox>
            </div>
        </div>
        <div id="divThoiGianThueNha" data-note="Thời gian thuê nhà" class="contentFormItem half" runat="server">
            <div id="divThoiGianThueNha_lbl" data-note="Thời gian Visa - lbl" class="contentFormLabel">
                <asp:Label ID="Label25" runat="server" CssClass="labelRequire">Thời hạn từ</asp:Label>
            </div>
            <div id="divThoiGianThueNha_ctl" data-note="Thời gian Visa-ctl" class="contentFormControl">
                <div class="w-100">
                    <div style="float: left">
                        <asp:TextBox ID="txtThoiHanTu" onblur="JavaScript:CheckDate(this)" runat="server" CssClass="inputcenter fpt-datetime-custom" MaxLength="10"></asp:TextBox>
                    </div>
                    <div id="divbtnThoiHanTu" runat="server" style="float: left">
                        <input class="datePicker" onclick="javascript:popUpCalendar(<%=this.txtThoiHanTu.ClientID%>);" type="button">
                    </div>
                    <div style="float: left; padding-left: 10px">
                        <asp:Label ID="Label26" runat="server" CssClass="labelRequire">Đến ngày</asp:Label>
                        <asp:TextBox ID="txtDenNgay" onblur="JavaScript:CheckDate(this)" runat="server" CssClass="inputcenter  fpt-datetime-custom" MaxLength="10" Style="margin-left: 20px; float: none"></asp:TextBox>
                    </div>
                    <div id="divBtnDenNgay">
                        <input class="datePicker" onclick="javascript:popUpCalendar(<%=this.txtDenNgay.ClientID%>);" type="button">
                    </div>
                </div>
            </div>
        </div>
        <div id="divChuCanHo" data-note="Chủ căn hộ" class="contentFormItem half" runat="server">
            <div id="divChuCanHo_lbl" data-note="Chủ căn hộ-lbl" class="contentFormLabel">
                <asp:Label ID="Label27" runat="server" CssClass="label">Chủ căn hộ</asp:Label>
            </div>
            <div id="divChuCanHo_ctl" data-note="Chủ căn hộ-ctl" class="contentFormControl">
                <asp:TextBox ID="txtChuCanHo" runat="server" CssClass="input" Style="width: 100%" MaxLength="255"></asp:TextBox>
            </div>
        </div>
        <div id="divSoDienThoai" data-note="Số điện thoại" class="contentFormItem half" runat="server">
            <div id="divSoDienThoai_lbl" data-note="Số điện thoại-lbl" class="contentFormLabel">
                <asp:Label ID="Label28" runat="server" CssClass="label">Số điện thoại</asp:Label>
            </div>
            <div id="divSoDienThoai_ctl" data-note="Số điện thoại-ctl" class="contentFormControl">
                <asp:TextBox ID="txtSoDienThoai" runat="server" CssClass="input" Style="width: 100%" MaxLength="255"></asp:TextBox>
            </div>
        </div>
        <div id="divDiaChiThueNha" data-note="Địa chỉ thuê nhà" class="contentFormItem half" runat="server">
            <div id="divDiaChiThueNha_lbl" data-note="Địa chỉ thuê nhà-lbl" class="contentFormLabel">
                <asp:Label ID="Label29" runat="server" CssClass="label">Địa chỉ</asp:Label>
            </div>
            <div id="divDiaChiThueNha_ctl" data-note="Địa chỉ thuê nhà-ctl" class="contentFormControl">
                <asp:TextBox ID="txtDiaChi" runat="server" CssClass="input" Style="width: 100%" MaxLength="255"></asp:TextBox>
            </div>
        </div>
        <div id="divTienDatCoc" data-note="Tiền đặt cọc" class="contentFormItem half" runat="server">
            <div id="divTienDatCoc_lbl" data-note="Tiền đặt cọc-lbl" class="contentFormLabel">
                <asp:Label ID="Label31" runat="server" CssClass="label">Tiền đặt cọc</asp:Label>
            </div>
            <div id="divTienDatCoc_ctl" data-note="Tiền đặt cọc-ctl" class="contentFormControl">
                <asp:TextBox ID="txtTienDatCoc" runat="server" CssClass="input" Style="width: 100%; text-align: right" MaxLength="15" onblur="JavaScript:checkNumeric(this)" onkeyup="javascript:FormatNumeric(this)"></asp:TextBox>
            </div>
        </div>
        <div id="divTienThueNha" data-note="Tiền thuê nhà" class="contentFormItem half" runat="server">
            <div id="divTienThueNha_lbl" data-note="Tiền thuê nhà-lbl" class="contentFormLabel">
                <asp:Label ID="Label32" runat="server" CssClass="labelRequire">Tiền thuê nhà</asp:Label>
            </div>
            <div id="divTienThueNha_ctl" data-note="Tiền thuê nhà-ctl" class="contentFormControl">
                <asp:TextBox ID="txtTienThueNha" runat="server" CssClass="input" Style="width: 78%; text-align: right" MaxLength="15" onblur="JavaScript:checkNumeric(this)" onkeyup="javascript:FormatNumeric(this)"></asp:TextBox>
                <telerik:RadComboBox ID="cboLSCurrencyTypeID" runat="server" Skin="Simple" Filter="Contains" MarkFirstMatch="true" Style="width: 20%; margin-left: 6px" />
            </div>
        </div>
        <%--anhdn23 - cap nhat giay phep lai xe --%>
        <div class="contentGroupTitleHolder" id="divGPLX_Title" data-note="Tenancy Title" runat="server">
            <div class="contentGroupIcon" id="divGPLX_Title_lbl" data-note="GPLX - lbl"></div>
            <div class="contentGroupTitle" id="divGPLX_Title_ctl" data-note="GPLX - ctl">
                <asp:Label ID="lblGPLX_Title" runat="server" CssClass="labelSubTitle">Giấy phép lái xe</asp:Label>
            </div>
        </div>
        <div id="divNameGPLX" data-note="Hang name" class="contentFormItem half" runat="server">
            <div id="divNameOnGPLX_lbl" data-note="Hang name - lbl" class="contentFormLabel">
                <asp:Label ID="lblHang" runat="server" CssClass="label">Hạng</asp:Label>
            </div>
            <div id="divNameOnGPLX_ctl" data-note="Hang name-ctl" class="contentFormControl">
                <asp:TextBox ID="txtNameOnGPLX" runat="server" CssClass="input" Width="100%" MaxLength="30"></asp:TextBox>
            </div>
        </div>
        <div id="divPass_IssusedDateGPLX" data-note="Thời gian GPLX" class="contentFormItem half range-date" runat="server">
            <div id="divPass_IssusedDateGPLX_lbl" data-note="Thời gian GPLX - lbl" class="contentFormLabel">
                <asp:Label ID="lblPass_IssusedDateGPLX" runat="server" CssClass="labelRequire">Ngày cấp</asp:Label>
            </div>
            <div id="divPass_IssusedDateGPLX_ctl" data-note="Thời gian GPLX-ctl" class="contentFormControl">
                <div>
                    <div style="float: left">
                        <asp:TextBox ID="txtPass_IssuedDateGPLX" onblur="JavaScript:CheckDate(this);" runat="server" CssClass="inputcenter fpt-datetime-custom" Width="70px" MaxLength="10"></asp:TextBox>
                    </div>
                    <div id="divBtnPassIssuedDateGPLX" runat="server" style="float: left">
                        <input class="datePicker" onclick="javascript:popUpCalendar(<%=this.txtPass_IssuedDateGPLX.ClientID%>);" type="button">
                    </div>
                    <div style="float: left;">
                        <asp:Label ID="lblPass_EffectDateGPLX" runat="server" CssClass="label fpt-date-between-label">Ngày hết hạn</asp:Label>
                    </div>
                    <div id="div1" runat="server" style="float: left">
                        <asp:TextBox ID="txtPass_EffDateGPLX" onblur="JavaScript:CheckDate(this);" runat="server" CssClass="inputcenter fpt-datetime-custom" Width="70px" MaxLength="10"></asp:TextBox>
                        <input class="datePicker" onclick="javascript:popUpCalendar(<%=this.txtPass_EffDateGPLX.ClientID%>);" type="button">
                    </div>
                </div>
            </div>
        </div>
        <div id="divCbGPLXPlace" data-note="Nơi cấp GPLX" class="contentFormItem half" runat="server">
            <div id="divNoiCapGPLX_lbl" data-note="Nơi cấp  GPLX-lbl" class="contentFormLabel">
                <asp:Label ID="lblNoiCap_GPLX" runat="server" CssClass="label">Nơi cấp</asp:Label>
            </div>
            <div id="divNoiCapGPLX_ctl" data-note="Nơi cấp GPLX-ctl" class="contentFormControl">
                <telerik:RadComboBox ID="cboGPLXPlace" runat="server" Skin="Simple" Width="100%" Filter="Contains" AllowCustomText="true" />
            </div>
        </div>
        <%--end anhdn23--%>
        <%--Rlog:7254--%>
        <div id="divAdvanced" data-note="Advanced notice time" data-visible="0" data-visiblefrmctlid_ref="trThueNha5" class="contentFormItem half" runat="server">
            <div id="divAdvanced_lbl" data-note="Advanced notice time-lbl" class="contentFormLabel">
                <asp:Label ID="Label99" runat="server" CssClass="label">Advanced notice time</asp:Label>
            </div>
            <div id="divAdvanced_ctl" data-note="Advanced notice time-ctl" class="contentFormControl">
                <asp:TextBox ID="txtAdvancedNoticeTime" runat="server" CssClass="input" Style="width: 100%"
                    MaxLength="500"></asp:TextBox>
            </div>
        </div>
        <div id="divTienThueNhaUSD" data-note="Tiền thuê nhà (USD)" data-visible="0" data-visiblefrmctlid_ref="trThueNha5" class="contentFormItem half" runat="server">
            <div id="divTienThueNhaUSD_lbl" data-note="Tiền thuê nhà (USD)-lbl" class="contentFormLabel">
                <asp:Label ID="Label30" runat="server" CssClass="label">Tiền thuê nhà (USD)</asp:Label>
            </div>
            <div id="divTienThueNhaUSD_ctl" data-note="Tiền thuê nhà (USD)-ctl" class="contentFormControl">
                <asp:TextBox ID="txtTienThueNhaUSD" runat="server" CssClass="input" Style="width: 100%; text-align: right" MaxLength="15" onblur="JavaScript:checkNumeric(this)" onkeyup="javascript:FormatNumeric(this)"></asp:TextBox>
            </div>
        </div>
        <div id="divTermination" data-note="Termination conditio" data-visible="0" data-visiblefrmctlid_ref="trThueNha6" class="contentFormItem half" runat="server">
            <div id="divTermination_lbl" data-note="Termination conditio-lbl" class="contentFormLabel">
                <asp:Label ID="Label37" runat="server" CssClass="label">Termination condition</asp:Label>
            </div>
            <div id="divTermination_ctl" data-note="Termination conditio-ctl" class="contentFormControl">
                <asp:TextBox ID="txtTerminationCondition" runat="server" CssClass="input" Style="width: 100%"
                    MaxLength="500"></asp:TextBox>
            </div>
        </div>
        <%--LY LICH TU PHAP RLOG 19677--%>
        <div class="contentGroupTitleHolder" id="divLLTP_Title" data-note="Lý lịch tư pháp" runat="server">
            <div class="contentGroupIcon" id="divLLTP_Title_lbl" data-note="LLTP - lbl"></div>
            <div class="contentGroupTitle" id="divLLTP_Title_ctr" data-note="LLTP - ctl">
                <asp:Label ID="lblLyLichTuPhap" runat="server" CssClass="labelSubTitle">Lý lịch tư pháp</asp:Label>
            </div>
        </div>
        <div id="divSoLyLichTuPhap" data-note="Số lý lịch tư pháp" class="contentFormItem half" runat="server">
            <div id="divSoLyLichTuPhap_lbl" data-note="Số lý lịch tư pháp - lbl" class="contentFormLabel">
                <asp:Label ID="lblSoLyLichTuPhap" runat="server" CssClass="label">Số lý lịch tư pháp</asp:Label>
            </div>
            <div id="divSoLyLichTuPhap_ctr" data-note="Số lý lịch tư pháp - ctl" class="contentFormControl">
                <asp:TextBox ID="txtSoLyLichTuPhap" runat="server" CssClass="input" Style="width: 100%"
                    MaxLength="50"></asp:TextBox>
            </div>
        </div>
        <div id="divLoaiLyLichTuPhap" data-note="Loại lý lịch tư pháp" class="contentFormItem half" runat="server">
            <div id="divLoaiLyLichTuPhap_lbl" data-note="Loại lý lịch tư pháp - lbl" class="contentFormLabel">
                <asp:Label ID="lblLoaiLyLichTuPhap" runat="server" CssClass="labelRequire">Loại lý lịch tư pháp</asp:Label>
            </div>
            <div id="divLoaiLyLichTuPhap_ctr" data-note="Loại lý lịch tư pháp - ctl" class="contentFormControl">
                <telerik:RadComboBox ID="cboLoaiLyLichTuPhap" runat="server" Skin="Simple" Width="100%" Filter="Contains" />
            </div>
        </div>
        <div id="divNgayCap_LyLichTuPhap" data-note="Ngày cấp lý lịch tư pháp" class="contentFormItem half" runat="server">
            <div id="divNgayCap_LyLichTuPhap_lbl" data-note="Ngày cấp lý lịch tư pháp - lbl" class="contentFormLabel">
                <asp:Label ID="lblNgayCap_LLTP" runat="server" CssClass="labelRequire">Ngày cấp </asp:Label>
            </div>
            <div id="divNgayCap_LyLichTuPhap_ctr" data-note="Ngày cấp lý lịch tư pháp - ctl" class="contentFormControl">
                <asp:TextBox ID="txtNgayCap_LLTP" onblur="JavaScript:CheckDate(this)" runat="server" CssClass="inputcenter fpt-datetime-custom" Width="70px" MaxLength="10"></asp:TextBox>
                <input class="datePicker" onclick="javascript:popUpCalendar(<%=this.txtNgayCap_LLTP.ClientID%>);" type="button">
            </div>
        </div>
        <div id="divNoiCap_LLTP" data-note="Nơi cấp lý lịch tư pháp" class="contentFormItem half" runat="server">
            <div id="divNoiCap_LLTP_lbl" data-note="Nơi cấp lý lịch tư pháp - lbl" class="contentFormLabel">
                <asp:Label ID="lblNoiCap_LLTP" runat="server" CssClass="labelRequire">Nơi cấp</asp:Label>
            </div>
            <div id="divNoiCap_LLTP_ctr" data-note="Nơi cấp lý lịch tư pháp - ctl" class="contentFormControl">
                <asp:TextBox ID="txtNoiCap_LLTP" runat="server" CssClass="input" Style="width: 100%" MaxLength="4000"></asp:TextBox>
            </div>
        </div>
        <div id="divTinhThanhNoiCap_LLTP" data-note="Tỉnh thành nơi cấp lý lịch tư pháp" class="contentFormItem half" runat="server">
            <div id="divTinhThanhNoiCap_LLTP_lbl" data-note="Tỉnh thành nơi cấp lý lịch tư pháp - lbl" class="contentFormLabel">
                <asp:Label ID="lblTinhThanhNoiCap_LLTP" runat="server" CssClass="label">Tỉnh thành nơi cấp</asp:Label>
            </div>
            <div id="divTinhThanhNoiCap_LLTP_ctr" data-note="Tỉnh thành nơi cấp lý lịch tư pháp - ctl" class="contentFormControl">
                <telerik:RadComboBox ID="cboNoiCap_LLTP" runat="server" Skin="Simple" Width="100%" Filter="Contains" />
            </div>
        </div>
        <div id="divTinhTrangAnTich" data-note="Tình trạng án tích" class="contentFormItem half" runat="server">
            <div id="divTinhTrangAnTich_lbl" data-note="Tình trạng án tích - lbl" class="contentFormLabel">
                <asp:Label ID="lblTinhTrangAnTich" runat="server" CssClass="labelRequire">Tình trạng án tích</asp:Label>
            </div>
            <div id="divTinhTrangAnTich_ctr" data-note="Tình trạng án tích - ctl" class="contentFormControl">
                <asp:TextBox ID="txtTinhTrangAnTich" runat="server" CssClass="input" Style="width: 100%"
                    MaxLength="4000"></asp:TextBox>
            </div>
        </div>
        <div id="divGhiChu_LLTP" data-note="Ghi chú LLTP" class="contentFormItem full onlyItem" runat="server">
            <div id="GhiChu_LLTP_lbl" data-note="Ghi chú LLTP - lbl" class="contentFormLabel">
                <asp:Label ID="lblGhiChu_LLTP" runat="server" CssClass="label">Ghi chú</asp:Label>
            </div>
            <div id="divGhiChu_LLTP_ctl" data-note="Ghi chú LLTP - ctl" class="contentFormControl">
                <asp:TextBox ID="txtGhiChu_LLTP" runat="server" CssClass="input" Width="100%" MaxLength="4000"></asp:TextBox>
            </div>
        </div>
        <%--END LY LICH TU PHAP RLOG 19677--%>
        <div id="divAttachFile" data-note="AttachFile" data-visible="0" data-visiblefrmctlid_ref="trThueNha6" class="contentFormItem full onlyItem" runat="server">
            <div id="divAttachFile_lbl" data-note="AttachFile-lbl" class="contentFormLabel">
                <asp:Label ID="Label17" runat="server" CssClass="label">AttachFile</asp:Label>
            </div>
            <div id="divAttachFile_ctl" data-note="AttachFile-ctl" class="contentFormControl">
                <uc:multiattachbutton id="MultiAttachButton1" runat="server" />
            </div>
        </div>

        <div id="divThongTinKhac1" data-note="Thông tin khác 1" class="contentFormItem full onlyItem" runat="server">
            <div id="divThongTinKhac1_lbl" data-note="Thông tin khác 1-lbl" class="contentFormLabel">
                <asp:Label ID="Label33" runat="server" CssClass="label">Thông tin khác 1</asp:Label>
            </div>
            <div id="divThongTinKhac1_ctl" data-note="Thông tin khác 1-ctl" class="contentFormControl">
                <asp:TextBox ID="txtOtherInfo1" runat="server" CssClass="input" Style="width: 100%"
                    MaxLength="255"></asp:TextBox>
            </div>
        </div>
        <div id="divThongTinKhac2" data-note="Thông tin khác 2" class="contentFormItem full onlyItem" runat="server">
            <div id="divThongTinKhac2_lbl" data-note="Thông tin khác 2-lbl" class="contentFormLabel">
                <asp:Label ID="Label34" runat="server" CssClass="label">Thông tin khác 2</asp:Label>
            </div>
            <div id="divThongTinKhac2_ctl" data-note="Thông tin khác 2-ctl" class="contentFormControl">
                <asp:TextBox ID="txtOtherInfo2" runat="server" CssClass="input" Style="width: 100%" MaxLength="255"></asp:TextBox>
            </div>
        </div>
        <div id="divThongTinKhac3" data-note="Thông tin khác 3" class="contentFormItem full onlyItem" runat="server">
            <div id="divThongTinKhac3_lbl" data-note="Thông tin khác 3-lbl" class="contentFormLabel">
                <asp:Label ID="Label35" runat="server" CssClass="label">Thông tin khác 3</asp:Label>
            </div>
            <div id="divThongTinKhac3_ctl" data-note="Thông tin khác 3-ctl" class="contentFormControl">
                <asp:TextBox ID="txtOtherInfo3" runat="server" CssClass="input" Style="width: 100%"
                    MaxLength="255"></asp:TextBox>
            </div>
        </div>

        <div id="divbtnDetail" data-note="Thông tin khác 3" class="contentFormItem full onlyItem" runat="server">
            <asp:LinkButton ID="btnDetail" OnClick="btnDetail_Click" AccessKey="N" runat="server" CssClass="link" ToolTip="Alt+N">Thông tin tình trạng giấy phép lao động</asp:LinkButton>
        </div>
        <%-- anhtt189 rlog 20947--%>
        <div id="divNgayNhapCanh" data-note="Ngày nhập cảnh Visa" class="contentFormItem half range-date" runat="server" data-visible="0">
            <div id="divNgayNhapCanhVisa_lbl" data-note="Ngày nhập cảnh Visa - lbl" class="contentFormLabel">
                <asp:Label ID="lblVisa_NgayNhapCanh" runat="server" CssClass="label">Ngày nhập cảnh</asp:Label>
            </div>
            <div id="divNgayNhapCanhVisa_ctl" data-note="Ngày nhập cảnh Visa-ctl" class="contentFormControl">
                <div>
                    <div style="float: left">
                        <asp:TextBox ID="txtVisa_NgayNhapCanh" onblur="JavaScript:CheckDate(this);" runat="server" CssClass="inputcenter fpt-datetime-custom" Width="70px" MaxLength="10"></asp:TextBox>
                    </div>
                    <div id="divBtnVisa_NgayNhapCanh" runat="server" style="float: left">
                        <input class="datePicker" onclick="javascript:popUpCalendar(<%=this.txtVisa_NgayNhapCanh.ClientID%>);" type="button">
                    </div>
                    <div style="float: left;">
                        <asp:Label ID="lblVisa_NgayXuatCanh" runat="server" CssClass="label">Ngày xuất cảnh</asp:Label>
                    </div>
                    <div id="divBtnVisa_NgayXuatCanh" runat="server" style="float: left">
                        <asp:TextBox ID="txtVisa_NgayXuatCanh" onblur="JavaScript:CheckDate(this);" runat="server" CssClass="inputcenter fpt-datetime-custom" Width="70px" MaxLength="10"></asp:TextBox>
                        <input class="datePicker" onclick="javascript:popUpCalendar(<%=this.txtVisa_NgayXuatCanh.ClientID%>);" type="button">
                    </div>
                    <div style="display: none">
                        <asp:TextBox ID="txtVisa_SoNgayLuuTruVN" runat="server"></asp:TextBox>
                    </div>
                </div>
            </div>
        </div>

        <div id="divNgayNhapCanh_Grid" data-index="" data-note="Các mối quan hệ trong vông việc - Grid" data-visible="0" class="contentFormItem full onlyItem" runat="server">
            <div class="contentFormItem full onlyItem">
                <div style="text-align: center">
                    <input class="search cmdAdd" id="cmdAddNgayNhapCanh" runat="server" onclick="javascript:InsertNgayNhapCanh();"
                        type="button" value="V" name="cmdAddNgayNhapCanh" style="margin-bottom: 5px">
                </div>
            </div>
            <div>
                <table id="tblNgayNhapCanh" class="fixed" style="border-collapse: collapse; border: solid 1px #5d8d8a !important; margin-bottom: 5px"
                    cellspacing="1" cellpadding="1" width="100%" border="1">
                    <tr>
                        <td style="width: 400px; height: 24px" align="center" class="gridHeader">
                            <asp:Label ID="lblNgayNhapCanh_Grid" CssClass="labeldata" runat="server" Height="16px" Text="Ngày nhập cảnh"></asp:Label>
                        </td>
                        <td style="width: 400px; height: 24px" align="center" class="gridHeader">
                            <asp:Label ID="lblNgayXuatCanh_Grid" CssClass="labeldata" runat="server" Height="16px" Text="Ngày xuất cảnh"></asp:Label>
                        </td>
                        <td style="width: 400px; height: 24px" align="center" class="gridHeader">
                            <asp:Label ID="lblNgayLuuTruVN" CssClass="labeldata" runat="server" Height="16px" Text="Số ngày lưu trú tại việt nam"></asp:Label>
                        </td>
                        <td style="width: 35px; height: 24px" align="center" class="gridHeader">
                            <asp:Label ID="lblNgayNhapCanh_Delete_Grid" CssClass="labeldata" runat="server" Height="16px" Text="Xóa"></asp:Label>
                        </td>
                        <%--anhtt189--%>
                        <td style="width: 35px; height: 24px" align="center" class="gridHeader">
                            <asp:Label ID="lblNgayNhapCanh_Edit" CssClass="labeldata" runat="server" Width="27px" Height="16px">Sửa</asp:Label>
                        </td>
                        <td style="width: 35px; height: 24px" align="center" class="gridHeader">
                            <asp:Label ID="lblNgayNhapCanh_Luu" CssClass="labeldata" runat="server" Width="27px" Height="16px">Lưu</asp:Label>
                        </td>
                        <td style="width: 35px; height: 24px" align="center" class="gridHeader">
                            <asp:Label ID="lblNgayNhapCanh_Huy" CssClass="labeldata" runat="server" Width="27px" Height="16px">Hủy</asp:Label>
                        </td>
                       
                        <td style="display: none" align="center" width="40" class="gridHeader"></td>
                        <td style="display: none" align="center" width="40" class="gridHeader"></td>
                    </tr>
                </table>
                <input id="hdNgayNhapCanh" type="hidden" size="1" name="hdNgayNhapCanh" runat="server" />
                <input id="hdNgayXuatCanh" type="hidden" size="1" name="hdNgayXuatCanh" runat="server">
                <input id="hdNgayLuuTruVN" type="hidden" size="1" name="hdNgayLuuTruVN" runat="server">
            </div>         
        </div>
        <%-- anhtt189 rlog 20947--%>
    </div>
    <div class="contentGroup" id="dvButton" data-index="" data-note="Các button">
        <div class="contentFormItem full">
            <hr />
        </div>
        <div class="contentFormItem full" id="divButton" data-index="" data-note="Các button">
            <table style="width: 100%">
                <tr>
                    <td align="center">
                        <span class="btn1">
                            <asp:LinkButton ID="btnAddNew" name="btnAddNew" AccessKey="A" ToolTip="ALT+A" runat="server"
                                OnClick="btnAddNew_Click">
                <span class="btnReset">Làm mới</span>
                            </asp:LinkButton>
                        </span><span class="btn1">
                            <asp:LinkButton ID="btnE_Save" name="btnSave" AccessKey="S" ToolTip="ALT+S" runat="server"
                                OnClick="btnE_Save_Click">
                <span class="btnSave">Lưu</span>
                            </asp:LinkButton>
                        </span><span class="btn1">
                            <asp:LinkButton ID="btnE_Delete" name="btnDelete" AccessKey="D" ToolTip="ALT+D" runat="server"
                                OnClick="btnE_Delete_Click">
                <span class="btnDelete">Xóa</span>
                            </asp:LinkButton>
                        </span><span class="btn1">
                            <asp:LinkButton ID="btnTransferNext" name="btnTransfer" AccessKey="N" ToolTip="ALT+N" OnClientClick="return transfernext__();"
                                runat="server"> 
            <span class="btnTransfer">Tiếp tục</span> </asp:LinkButton>
                        </span>
                        <span class="btn1">
                            <asp:LinkButton ID="btnClose" name="btnClose" AccessKey="B" runat="server" ToolTip="ALT+B" OnClick="btnClose_Click" Style="display: none; pause: T">
                    <span class="btnClose" style="font-weight:bold">Kết thúc</span></asp:LinkButton>
                        </span>
                        <span class="btn1">
                            <asp:LinkButton ID="btnSaveGetStringData_Dev" name="btnSave" AccessKey="N" runat="server" Visible="false" OnClick="btnGetStringData_Dev_Click"><span>Save StrData</span> 
                            </asp:LinkButton>
                        </span>
                    </td>
                </tr>
            </table>
        </div>
        <div class="gridHolder" id="divtgListGiayPhepLaoDong">
            <telerik:RadSplitter ID="RadSplitter1" Width="950px" runat="server" Orientation="Horizontal"
                Height="100%">
                <telerik:RadPane ID="gridPane" Height="300px" runat="server" Scrolling="None">
                    <core:iHRPCoreGrid ID="dtgListGiayPhepLaoDong" GridLines="None" Height="300px" Width="948px" AutoGenerateColumns="false"
                        AllowPaging="true" runat="server" OnNeedDataSource="dtgListGiayPhepLaoDong_NeedDataSource" OnItemCommand="dtgListGiayPhepLaoDong_ItemCommand" OnItemDataBound="dtgListGiayPhepLaoDong_ItemDataBound"
                        PageSize="15" Skin="Simple" ShowStatusBar="true" AllowSorting="true" PageSizeManual="true">
                        <PagerStyle Mode="NextPrevNumericAndAdvanced" AlwaysVisible="true" />
                        <MasterTableView TableLayout="Fixed" Width="100%" CommandItemDisplay="Top" AllowMultiColumnSorting="true"
                            GroupLoadMode="Client">
                            <CommandItemTemplate>
                                <asp:ImageButton ID="btnConfig" runat="server" ToolTip="Setting" CommandName="ConfigRadGrid"
                                    Width="10px" Height="10px" ImageUrl="~/Images/ConfigIcon.jpg" />
                            </CommandItemTemplate>
                            <Columns>
                                <telerik:GridTemplateColumn UniqueName="SelectCol" HeaderText="Chọn">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                    <HeaderTemplate>
                                        <asp:CheckBox ID="chkSelectAll" CssClass="checkbox" runat="server" onclick="CheckAll_RadGrid('_ctl0_dtgListGiayPhepLaoDong__ctl0__ctl2__ctl2_chkSelectAll', '_ctl0_dtgListGiayPhepLaoDong', 'chkSelect')"></asp:CheckBox>
                                    </HeaderTemplate>
                                    <ItemStyle VerticalAlign="Middle" HorizontalAlign="Center" />
                                    <ItemTemplate>
                                        <asp:CheckBox ID="chkSelect" CssClass="checkbox" runat="server"></asp:CheckBox>
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridTemplateColumn UniqueName="Edit" HeaderText="Sửa">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemTemplate>
                                        <asp:ImageButton CssClass="rgpointer" ID="Edit" runat="server" ImageUrl="~/Images/edit.png"
                                            CommandName="Edit_Data" />
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridTemplateColumn UniqueName="Seq" HeaderText="Seq">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemTemplate>
                                        <asp:Literal ID="glblItemSeqName" runat="server" Text='<%# Container.ItemIndex + 1 + dtgListGiayPhepLaoDong.PageSize * dtgListGiayPhepLaoDong.CurrentPageIndex%>' />
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridBoundColumn SortExpression="No" UniqueName="No" DataField="No" HeaderText="No">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="70px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IssueDate" UniqueName="IssueDate" DataField="IssueDate" HeaderText="IssueDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="70px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="ExpireDate" UniqueName="ExpireDate" DataField="ExpireDate" HeaderText="ExpireDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="70px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IssuePlace" UniqueName="IssuePlace" DataField="IssuePlace" HeaderText="IssuePlace">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IssuePlace_Province" UniqueName="IssuePlace_Province" DataField="IssuePlace_Province" HeaderText="IssuePlace_Province" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>

                                <telerik:GridBoundColumn SortExpression="StatusName" UniqueName="StatusName" DataField="StatusName" HeaderText="StatusName">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Note" UniqueName="Note" DataField="Note" HeaderText="Note">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="EffectiveDate" UniqueName="EffectiveDate" HeaderText="EffectiveDate"
                                    DataField="EffectiveDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="70px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="EndEffectDate" Visible="false" UniqueName="EndEffectDate" HeaderText="EndEffectDate"
                                    DataField="EndEffectDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="70px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="LSPassportTypeID" Visible="false" UniqueName="LSPassportTypeID" HeaderText="LSPassportTypeID"
                                    DataField="LSPassportTypeID">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Address" Visible="false" UniqueName="Address" HeaderText="Address"
                                    DataField="Address">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="OtherInfo1" Visible="false" UniqueName="OtherInfo1" HeaderText="OtherInfo1"
                                    DataField="OtherInfo1">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="OtherInfo2" Visible="false" UniqueName="OtherInfo2" HeaderText="OtherInfo2"
                                    DataField="OtherInfo2">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="OtherInfo3" Visible="false" UniqueName="OtherInfo3" HeaderText="OtherInfo3"
                                    DataField="OtherInfo3">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="LSCurrencyTypeID" Visible="false" UniqueName="LSCurrencyTypeID" HeaderText="LSCurrencyTypeID"
                                    DataField="LSCurrencyTypeID">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="PaidbyEmp" Visible="false" UniqueName="PaidbyEmp" HeaderText="PaidbyEmp"
                                    DataField="PaidbyEmp">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Return" Visible="false" UniqueName="Return" HeaderText="Return"
                                    DataField="Return">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="ReturnDate" Visible="false" UniqueName="ReturnDate" HeaderText="ReturnDate"
                                    DataField="ReturnDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <%--RlogID 25189 - KPMG_V34--%>
                                <telerik:GridBoundColumn SortExpression="JobPositionForWorkPermit" Visible="false" UniqueName="JobPositionForWorkPermit" HeaderText="JobPositionForWorkPermit"
                                    DataField="JobPositionForWorkPermit">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <%--END RlogID 25189 - KPMG_V34--%>
                                <telerik:GridBoundColumn SortExpression="Fee" Visible="false" UniqueName="Fee" DataField="Fee" HeaderText="Fee">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Right" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridTemplateColumn UniqueName="AttachFile" HeaderText="AttachFile" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" Width="200%"></HeaderStyle>
                                    <ItemStyle HorizontalAlign="Center"></ItemStyle>
                                    <ItemTemplate>
                                        <uc:multiattachbutton id="MultiAttachButton1" runat="server" width="95%">
                                        </uc:multiattachbutton>
                                        <asp:Label ID="lblAttachFile" runat="server" Visible="true" CssClass="Lable" Text='<%# DataBinder.Eval(Container, "DataItem.AttachFileID") %>'></asp:Label>
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <%--RlogID 16139 - VGU - 26/03/2021 - QuyenPV9--%>
                                <telerik:GridBoundColumn SortExpression="IssuePlace_EN" UniqueName="IssuePlace_EN" DataField="IssuePlace_EN"
                                    HeaderText="Issue Place EN" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <%--End RlogID 16139--%>
                                <%--RlogID 18751--%>
                                <telerik:GridBoundColumn SortExpression="LSLoaiGiayPhepLaoDongName" UniqueName="LSLoaiGiayPhepLaoDongName" DataField="LSLoaiGiayPhepLaoDongName"
                                    HeaderText="Loai giay phep lao dong" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <%--End RlogID 18751--%>
                                <telerik:GridBoundColumn Visible="false" UniqueName="PassportVisaID" DataField="PassportVisaID" HeaderText="PassportVisaID">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn Visible="false" UniqueName="Type" DataField="Type" HeaderText="Type">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn Visible="false" UniqueName="Status" DataField="Status" HeaderText="Status">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn Visible="false" UniqueName="IsTuPhap" DataField="IsTuPhap" HeaderText="IsTuPhap">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn Visible="false" UniqueName="AttachFileID" DataField="AttachFileID" HeaderText="AttachFileID">
                                </telerik:GridBoundColumn>
                            </Columns>
                        </MasterTableView>
                        <HeaderStyle Width="950px" />
                        <ClientSettings AllowGroupExpandCollapse="True">
                            <Scrolling AllowScroll="True" UseStaticHeaders="True" />
                            <Resizing AllowColumnResize="true" ResizeGridOnColumnResize="true" EnableRealTimeResize="true" />
                        </ClientSettings>
                    </core:iHRPCoreGrid>
                </telerik:RadPane>
            </telerik:RadSplitter>
        </div>
        <div class="gridHolder" id="divdtgListPassport">
            <telerik:RadSplitter ID="RadSplitter3" Width="950px" runat="server" Orientation="Horizontal"
                Height="100%">
                <telerik:RadPane ID="RadPane2" Height="300px" runat="server" Scrolling="None">
                    <core:iHRPCoreGrid ID="dtgListPassport" GridLines="None" Height="300px" Width="948px" AutoGenerateColumns="false"
                        AllowPaging="true" runat="server" OnNeedDataSource="dtgListPassport_NeedDataSource" OnItemCommand="dtgListPassport_ItemCommand" OnItemDataBound="dtgListPassport_ItemDataBound"
                        PageSize="15" Skin="Simple" ShowStatusBar="true" AllowSorting="true" PageSizeManual="true">
                        <PagerStyle Mode="NextPrevNumericAndAdvanced" AlwaysVisible="true" />
                        <MasterTableView TableLayout="Fixed" Width="100%" CommandItemDisplay="Top" AllowMultiColumnSorting="true"
                            GroupLoadMode="Client">
                            <CommandItemTemplate>
                                <asp:ImageButton ID="btnConfig" runat="server" ToolTip="Setting" CommandName="ConfigRadGrid"
                                    Width="10px" Height="10px" ImageUrl="~/Images/ConfigIcon.jpg" />
                            </CommandItemTemplate>
                            <Columns>
                                <telerik:GridTemplateColumn UniqueName="SelectCol" HeaderText="Chọn">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                    <HeaderTemplate>
                                        <asp:CheckBox ID="chkSelectAll" CssClass="checkbox" runat="server" onclick="CheckAll_RadGrid('_ctl0_dtgListPassport__ctl0__ctl2__ctl2_chkSelectAll', '_ctl0_dtgListPassport', 'chkSelect')"></asp:CheckBox>
                                    </HeaderTemplate>
                                    <ItemStyle VerticalAlign="Middle" HorizontalAlign="Center" />
                                    <ItemTemplate>
                                        <asp:CheckBox ID="chkSelect" CssClass="checkbox" runat="server"></asp:CheckBox>
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridTemplateColumn UniqueName="Edit" HeaderText="Sửa">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemTemplate>
                                        <asp:ImageButton CssClass="rgpointer" ID="Edit" runat="server" ImageUrl="~/Images/edit.png"
                                            CommandName="Edit_Data" />
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridTemplateColumn UniqueName="Seq" HeaderText="Seq">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemTemplate>
                                        <asp:Literal ID="glblItemSeqName" runat="server" Text='<%# Container.ItemIndex + 1 + dtgListPassport.PageSize * dtgListPassport.CurrentPageIndex%>' />
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridBoundColumn SortExpression="No" UniqueName="No" DataField="No" HeaderText="No">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="70px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IssueDate" UniqueName="IssueDate" DataField="IssueDate" HeaderText="IssueDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="70px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="ExpireDate" UniqueName="ExpireDate" DataField="ExpireDate" HeaderText="ExpireDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="70px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IssuePlace" UniqueName="IssuePlace" DataField="IssuePlace" HeaderText="IssuePlace">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IssuePlace_Province" UniqueName="IssuePlace_Province" DataField="IssuePlace_Province" HeaderText="IssuePlace_Province" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="StatusName" UniqueName="StatusName" DataField="StatusName" HeaderText="StatusName">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Note" UniqueName="Note" DataField="Note" HeaderText="Note">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="EffectiveDate" UniqueName="EffectiveDate" HeaderText="EffectiveDate"
                                    DataField="EffectiveDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="70px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="EndEffectDate" Visible="false" UniqueName="EndEffectDate" HeaderText="EndEffectDate"
                                    DataField="EndEffectDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="70px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="LSPassportTypeID" Visible="false" UniqueName="LSPassportTypeID" HeaderText="LSPassportTypeID"
                                    DataField="LSPassportTypeID">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="PassportTypeName" Visible="false" UniqueName="PassportTypeName" HeaderText="PassportTypeName"
                                    DataField="PassportTypeName">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <%--RlogID 25190 - KPMG_V34--%>
                                <telerik:GridBoundColumn SortExpression="QuocGia_1" Visible="false" UniqueName="QuocGia_1" HeaderText="QuocGia_1" DataField="QuocGia_1">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <%--END RlogID 25190 - KPMG_V34--%>
                                <telerik:GridBoundColumn SortExpression="Address" Visible="false" UniqueName="Address" HeaderText="Address"
                                    DataField="Address">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="OtherInfo1" Visible="false" UniqueName="OtherInfo1" HeaderText="OtherInfo1"
                                    DataField="OtherInfo1">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="OtherInfo2" Visible="false" UniqueName="OtherInfo2" HeaderText="OtherInfo2"
                                    DataField="OtherInfo2">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="OtherInfo3" Visible="false" UniqueName="OtherInfo3" HeaderText="OtherInfo3"
                                    DataField="OtherInfo3">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="LSCurrencyTypeID" Visible="false" UniqueName="LSCurrencyTypeID" HeaderText="LSCurrencyTypeID"
                                    DataField="LSCurrencyTypeID">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="PaidbyEmp" Visible="false" UniqueName="PaidbyEmp" HeaderText="PaidbyEmp"
                                    DataField="PaidbyEmp">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Return" Visible="false" UniqueName="Return" HeaderText="Return"
                                    DataField="Return">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="ReturnDate" Visible="false" UniqueName="ReturnDate" HeaderText="ReturnDate"
                                    DataField="ReturnDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Fee" Visible="false" UniqueName="Fee" DataField="Fee" HeaderText="Fee">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Right" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridTemplateColumn UniqueName="AttachFile" HeaderText="AttachFile" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" Width="200%"></HeaderStyle>
                                    <ItemStyle HorizontalAlign="Center"></ItemStyle>
                                    <ItemTemplate>
                                        <uc:multiattachbutton id="MultiAttachButton1" runat="server" width="95%">
                                        </uc:multiattachbutton>
                                        <asp:Label ID="lblAttachFile" runat="server" Visible="true" CssClass="Lable" Text='<%# DataBinder.Eval(Container, "DataItem.AttachFileID") %>'></asp:Label>
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <%--RlogID 16139 - VGU - 26/03/2021 - QuyenPV9--%>
                                <telerik:GridBoundColumn SortExpression="IssuePlace_EN" UniqueName="IssuePlace_EN" DataField="IssuePlace_EN"
                                    HeaderText="Issue Place EN" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <%--End RlogID 16139--%>
                                <telerik:GridBoundColumn SortExpression="NameOnPassport" UniqueName="NameOnPassport" DataField="NameOnPassport"
                                    HeaderText="Tên trên hộ chiếu" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn Visible="false" UniqueName="PassportVisaID" DataField="PassportVisaID" HeaderText="PassportVisaID">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn Visible="false" UniqueName="Type" DataField="Type" HeaderText="Type">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn Visible="false" UniqueName="Status" DataField="Status" HeaderText="Status">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn Visible="false" UniqueName="IsTuPhap" DataField="IsTuPhap" HeaderText="IsTuPhap">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn Visible="false" UniqueName="AttachFileID" DataField="AttachFileID" HeaderText="AttachFileID">
                                </telerik:GridBoundColumn>
                            </Columns>
                        </MasterTableView>
                        <HeaderStyle Width="950px" />
                        <ClientSettings AllowGroupExpandCollapse="True">
                            <Scrolling AllowScroll="True" UseStaticHeaders="True" />
                            <Resizing AllowColumnResize="true" ResizeGridOnColumnResize="true" EnableRealTimeResize="true" />
                        </ClientSettings>
                    </core:iHRPCoreGrid>
                </telerik:RadPane>
            </telerik:RadSplitter>
        </div>
        <div class="gridHolder" id="divdtgListVisa">
            <telerik:RadSplitter ID="RadSplitter4" Width="950px" runat="server" Orientation="Horizontal"
                Height="100%">
                <telerik:RadPane ID="RadPane3" Height="300px" runat="server" Scrolling="None">
                    <core:iHRPCoreGrid ID="dtgListVisa" GridLines="None" Height="300px" Width="948px" AutoGenerateColumns="false"
                        AllowPaging="true" runat="server" OnNeedDataSource="dtgListVisa_NeedDataSource" OnItemCommand="dtgListVisa_ItemCommand" OnItemDataBound="dtgListVisa_ItemDataBound"
                        PageSize="15" Skin="Simple" ShowStatusBar="true" AllowSorting="true" PageSizeManual="true">
                        <PagerStyle Mode="NextPrevNumericAndAdvanced" AlwaysVisible="true" />
                        <MasterTableView TableLayout="Fixed" Width="100%" CommandItemDisplay="Top" AllowMultiColumnSorting="true"
                            GroupLoadMode="Client">
                            <CommandItemTemplate>
                                <asp:ImageButton ID="btnConfig" runat="server" ToolTip="Setting" CommandName="ConfigRadGrid"
                                    Width="10px" Height="10px" ImageUrl="~/Images/ConfigIcon.jpg" />
                            </CommandItemTemplate>
                            <Columns>
                                <telerik:GridTemplateColumn UniqueName="SelectCol" HeaderText="Chọn">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                    <HeaderTemplate>
                                        <asp:CheckBox ID="chkSelectAll" CssClass="checkbox" runat="server" onclick="CheckAll_RadGrid('_ctl0_dtgListVisa__ctl0__ctl2__ctl2_chkSelectAll', '_ctl0_dtgListVisa', 'chkSelect')"></asp:CheckBox>
                                    </HeaderTemplate>
                                    <ItemStyle VerticalAlign="Middle" HorizontalAlign="Center" />
                                    <ItemTemplate>
                                        <asp:CheckBox ID="chkSelect" CssClass="checkbox" runat="server"></asp:CheckBox>
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridTemplateColumn UniqueName="Edit" HeaderText="Sửa">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemTemplate>
                                        <asp:ImageButton CssClass="rgpointer" ID="Edit" runat="server" ImageUrl="~/Images/edit.png"
                                            CommandName="Edit_Data" />
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridTemplateColumn UniqueName="Seq" HeaderText="Seq">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemTemplate>
                                        <asp:Literal ID="glblItemSeqName" runat="server" Text='<%# Container.ItemIndex + 1 + dtgListVisa.PageSize * dtgListVisa.CurrentPageIndex%>' />
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridBoundColumn SortExpression="No" UniqueName="No" DataField="No" HeaderText="No">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="70px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IssueDate" UniqueName="IssueDate" DataField="IssueDate" HeaderText="IssueDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="70px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="ExpireDate" UniqueName="ExpireDate" DataField="ExpireDate" HeaderText="ExpireDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="70px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IssuePlace" UniqueName="IssuePlace" DataField="IssuePlace" HeaderText="IssuePlace">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IssuePlace_Province" UniqueName="IssuePlace_Province" DataField="IssuePlace_Province" HeaderText="IssuePlace_Province" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="LoaiVisa" UniqueName="LoaiVisa" DataField="LoaiVisa" HeaderText="Loại visa" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="StatusName" UniqueName="StatusName" DataField="StatusName" HeaderText="StatusName">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Note" UniqueName="Note" DataField="Note" HeaderText="Note">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="EffectiveDate" UniqueName="EffectiveDate" HeaderText="EffectiveDate"
                                    DataField="EffectiveDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="70px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="EndEffectDate" Visible="false" UniqueName="EndEffectDate" HeaderText="EndEffectDate"
                                    DataField="EndEffectDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="70px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="LSPassportTypeID" Visible="false" UniqueName="LSPassportTypeID" HeaderText="LSPassportTypeID"
                                    DataField="LSPassportTypeID">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <%--RlogID 25190 - KPMG_V34--%>
                                <telerik:GridBoundColumn SortExpression="QuocGia_1" Visible="false" UniqueName="QuocGia_1" HeaderText="QuocGia_1" DataField="QuocGia_1">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <%--END RlogID 25190 - KPMG_V34--%>
                                <telerik:GridBoundColumn SortExpression="Address" Visible="false" UniqueName="Address" HeaderText="Address"
                                    DataField="Address">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="OtherInfo1" Visible="false" UniqueName="OtherInfo1" HeaderText="OtherInfo1"
                                    DataField="OtherInfo1">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="OtherInfo2" Visible="false" UniqueName="OtherInfo2" HeaderText="OtherInfo2"
                                    DataField="OtherInfo2">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="OtherInfo3" Visible="false" UniqueName="OtherInfo3" HeaderText="OtherInfo3"
                                    DataField="OtherInfo3">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="LSCurrencyTypeID" Visible="false" UniqueName="LSCurrencyTypeID" HeaderText="LSCurrencyTypeID"
                                    DataField="LSCurrencyTypeID">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="PaidbyEmp" Visible="false" UniqueName="PaidbyEmp" HeaderText="PaidbyEmp"
                                    DataField="PaidbyEmp">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Return" Visible="false" UniqueName="Return" HeaderText="Return"
                                    DataField="Return">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="ReturnDate" Visible="false" UniqueName="ReturnDate" HeaderText="ReturnDate"
                                    DataField="ReturnDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Fee" Visible="false" UniqueName="Fee" DataField="Fee" HeaderText="Fee">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Right" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridTemplateColumn UniqueName="AttachFile" HeaderText="AttachFile" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" Width="200%"></HeaderStyle>
                                    <ItemStyle HorizontalAlign="Center"></ItemStyle>
                                    <ItemTemplate>
                                        <uc:multiattachbutton id="MultiAttachButton1" runat="server" width="95%">
                                        </uc:multiattachbutton>
                                        <asp:Label ID="lblAttachFile" runat="server" Visible="true" CssClass="Lable" Text='<%# DataBinder.Eval(Container, "DataItem.AttachFileID") %>'></asp:Label>
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridBoundColumn SortExpression="NgayXuatNhapCanhVS" UniqueName="NgayXuatNhapCanhVS" DataField="NgayXuatNhapCanhVS" HeaderText="Thông tin xuất nhập cảnh" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <%--RlogID 16139 - VGU - 26/03/2021 - QuyenPV9--%>
                                <telerik:GridBoundColumn SortExpression="IssuePlace_EN" UniqueName="IssuePlace_EN" DataField="IssuePlace_EN"
                                    HeaderText="Issue Place EN" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <%--End RlogID 16139--%>
                                <%--Start Rlog:18669 VuNH49 03/11/2022--%>
                                <telerik:GridBoundColumn SortExpression="LSQuocGiaID" UniqueName="LSQuocGiaID" DataField="LSQuocGiaID" HeaderText="LSQuocGiaID" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <%--End Rlog:18669 VuNH49 03/11/2022--%>
                                <telerik:GridBoundColumn Visible="false" UniqueName="PassportVisaID" DataField="PassportVisaID" HeaderText="PassportVisaID">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn Visible="false" UniqueName="Type" DataField="Type" HeaderText="Type">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn Visible="false" UniqueName="Status" DataField="Status" HeaderText="Status">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn Visible="false" UniqueName="IsTuPhap" DataField="IsTuPhap" HeaderText="IsTuPhap">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn Visible="false" UniqueName="AttachFileID" DataField="AttachFileID" HeaderText="AttachFileID">
                                </telerik:GridBoundColumn>
                            </Columns>
                        </MasterTableView>
                        <HeaderStyle Width="950px" />
                        <ClientSettings AllowGroupExpandCollapse="True">
                            <Scrolling AllowScroll="True" UseStaticHeaders="True" />
                            <Resizing AllowColumnResize="true" ResizeGridOnColumnResize="true" EnableRealTimeResize="true" />
                        </ClientSettings>
                    </core:iHRPCoreGrid>
                </telerik:RadPane>
            </telerik:RadSplitter>
        </div>
        <div class="gridHolder" id="divdtgListTempLicence">
            <telerik:RadSplitter ID="RadSplitter5" Width="950px" runat="server" Orientation="Horizontal"
                Height="100%">
                <telerik:RadPane ID="RadPane4" Height="300px" runat="server" Scrolling="None">
                    <core:iHRPCoreGrid ID="dtgListTempLicence" GridLines="None" Height="300px" Width="948px" AutoGenerateColumns="false"
                        AllowPaging="true" runat="server" OnNeedDataSource="dtgListTempLicence_NeedDataSource" OnItemCommand="dtgListTempLicence_ItemCommand" OnItemDataBound="dtgListTempLicence_ItemDataBound"
                        PageSize="15" Skin="Simple" ShowStatusBar="true" AllowSorting="true" PageSizeManual="true">
                        <PagerStyle Mode="NextPrevNumericAndAdvanced" AlwaysVisible="true" />
                        <MasterTableView TableLayout="Fixed" Width="100%" CommandItemDisplay="Top" AllowMultiColumnSorting="true"
                            GroupLoadMode="Client">
                            <CommandItemTemplate>
                                <asp:ImageButton ID="btnConfig" runat="server" ToolTip="Setting" CommandName="ConfigRadGrid"
                                    Width="10px" Height="10px" ImageUrl="~/Images/ConfigIcon.jpg" />
                            </CommandItemTemplate>
                            <Columns>
                                <telerik:GridTemplateColumn UniqueName="SelectCol" HeaderText="Chọn">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                    <HeaderTemplate>
                                        <asp:CheckBox ID="chkSelectAll" CssClass="checkbox" runat="server" onclick="CheckAll_RadGrid('_ctl0_dtgListTempLicence__ctl0__ctl2__ctl2_chkSelectAll', '_ctl0_dtgListTempLicence', 'chkSelect')"></asp:CheckBox>
                                    </HeaderTemplate>
                                    <ItemStyle VerticalAlign="Middle" HorizontalAlign="Center" />
                                    <ItemTemplate>
                                        <asp:CheckBox ID="chkSelect" CssClass="checkbox" runat="server"></asp:CheckBox>
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridTemplateColumn UniqueName="Edit" HeaderText="Sửa">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemTemplate>
                                        <asp:ImageButton CssClass="rgpointer" ID="Edit" runat="server" ImageUrl="~/Images/edit.png"
                                            CommandName="Edit_Data" />
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridTemplateColumn UniqueName="Seq" HeaderText="Seq">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemTemplate>
                                        <asp:Literal ID="glblItemSeqName" runat="server" Text='<%# Container.ItemIndex + 1 + dtgListTempLicence.PageSize * dtgListTempLicence.CurrentPageIndex%>' />
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridBoundColumn SortExpression="No" UniqueName="No" DataField="No" HeaderText="No">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="70px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IssueDate" UniqueName="IssueDate" DataField="IssueDate" HeaderText="IssueDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="70px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="ExpireDate" UniqueName="ExpireDate" DataField="ExpireDate" HeaderText="ExpireDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="70px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IssuePlace" UniqueName="IssuePlace" DataField="IssuePlace" HeaderText="IssuePlace">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IssuePlace_Province" UniqueName="IssuePlace_Province" DataField="IssuePlace_Province" HeaderText="IssuePlace_Province" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="StatusName" UniqueName="StatusName" DataField="StatusName" HeaderText="StatusName">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Note" UniqueName="Note" DataField="Note" HeaderText="Note">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="EffectiveDate" UniqueName="EffectiveDate" HeaderText="EffectiveDate"
                                    DataField="EffectiveDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="70px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="EndEffectDate" Visible="false" UniqueName="EndEffectDate" HeaderText="EndEffectDate"
                                    DataField="EndEffectDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="70px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="LSPassportTypeID" Visible="false" UniqueName="LSPassportTypeID" HeaderText="LSPassportTypeID"
                                    DataField="LSPassportTypeID">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Address" Visible="false" UniqueName="Address" HeaderText="Address"
                                    DataField="Address">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="OtherInfo1" Visible="false" UniqueName="OtherInfo1" HeaderText="OtherInfo1"
                                    DataField="OtherInfo1">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="OtherInfo2" Visible="false" UniqueName="OtherInfo2" HeaderText="OtherInfo2"
                                    DataField="OtherInfo2">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="OtherInfo3" Visible="false" UniqueName="OtherInfo3" HeaderText="OtherInfo3"
                                    DataField="OtherInfo3">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="LSCurrencyTypeID" Visible="false" UniqueName="LSCurrencyTypeID" HeaderText="LSCurrencyTypeID"
                                    DataField="LSCurrencyTypeID">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="PaidbyEmp" Visible="false" UniqueName="PaidbyEmp" HeaderText="PaidbyEmp"
                                    DataField="PaidbyEmp">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Return" Visible="false" UniqueName="Return" HeaderText="Return"
                                    DataField="Return">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="ReturnDate" Visible="false" UniqueName="ReturnDate" HeaderText="ReturnDate"
                                    DataField="ReturnDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Fee" Visible="false" UniqueName="Fee" DataField="Fee" HeaderText="Fee">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Right" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridTemplateColumn UniqueName="AttachFile" HeaderText="AttachFile" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" Width="200%"></HeaderStyle>
                                    <ItemStyle HorizontalAlign="Center"></ItemStyle>
                                    <ItemTemplate>
                                        <uc:multiattachbutton id="MultiAttachButton1" runat="server" width="95%">
                                        </uc:multiattachbutton>
                                        <asp:Label ID="lblAttachFile" runat="server" Visible="true" CssClass="Lable" Text='<%# DataBinder.Eval(Container, "DataItem.AttachFileID") %>'></asp:Label>
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <%--START RlogID 25487--%>
                                <telerik:GridBoundColumn SortExpression="LoaiGiayTamTru" Visible="false" UniqueName="LoaiGiayTamTru" HeaderText="LoaiGiayTamTru" DataField="LoaiGiayTamTru">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <%--END RlogID 25487--%>
                                <%--RlogID 16139 - VGU - 26/03/2021 - QuyenPV9--%>
                                <telerik:GridBoundColumn SortExpression="IssuePlace_EN" UniqueName="IssuePlace_EN" DataField="IssuePlace_EN"
                                    HeaderText="Issue Place EN" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <%--End RlogID 16139--%>
                                <telerik:GridBoundColumn Visible="false" UniqueName="PassportVisaID" DataField="PassportVisaID" HeaderText="PassportVisaID">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn Visible="false" UniqueName="Type" DataField="Type" HeaderText="Type">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn Visible="false" UniqueName="Status" DataField="Status" HeaderText="Status">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn Visible="false" UniqueName="IsTuPhap" DataField="IsTuPhap" HeaderText="IsTuPhap">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn Visible="false" UniqueName="AttachFileID" DataField="AttachFileID" HeaderText="AttachFileID">
                                </telerik:GridBoundColumn>
                            </Columns>
                        </MasterTableView>
                        <HeaderStyle Width="950px" />
                        <ClientSettings AllowGroupExpandCollapse="True">
                            <Scrolling AllowScroll="True" UseStaticHeaders="True" />
                            <Resizing AllowColumnResize="true" ResizeGridOnColumnResize="true" EnableRealTimeResize="true" />
                        </ClientSettings>
                    </core:iHRPCoreGrid>
                </telerik:RadPane>
            </telerik:RadSplitter>
        </div>
        <div class="gridHolder" id="divdtgListThueNha">
            <telerik:RadSplitter ID="RadSplitter2" Width="950px" runat="server" Orientation="Horizontal"
                Height="100%">
                <telerik:RadPane ID="RadPane1" Height="300px" runat="server" Scrolling="None">
                    <core:iHRPCoreGrid ID="dtgListThueNha" GridLines="None" Height="300px" Width="948px" AutoGenerateColumns="false"
                        AllowPaging="true" runat="server" OnNeedDataSource="dtgListThueNha_NeedDataSource" OnItemCommand="dtgListThueNha_ItemCommand" OnItemDataBound="dtgListThueNha_ItemDataBound"
                        PageSize="15" Skin="Simple" ShowStatusBar="true" AllowSorting="true" PageSizeManual="true">
                        <PagerStyle Mode="NextPrevNumericAndAdvanced" AlwaysVisible="true" />
                        <MasterTableView TableLayout="Fixed" Width="100%" CommandItemDisplay="Top" AllowMultiColumnSorting="true"
                            GroupLoadMode="Client">
                            <CommandItemTemplate>
                                <asp:ImageButton ID="btnConfig" runat="server" ToolTip="Setting" CommandName="ConfigRadGrid"
                                    Width="10px" Height="10px" ImageUrl="~/Images/ConfigIcon.jpg" />
                            </CommandItemTemplate>
                            <Columns>
                                <telerik:GridTemplateColumn UniqueName="SelectCol" HeaderText="Chọn">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                    <HeaderTemplate>
                                        <asp:CheckBox ID="chkSelectAll" CssClass="checkbox" runat="server" onclick="CheckAll_RadGrid('_ctl0_dtgListThueNha__ctl0__ctl2__ctl2_chkSelectAll', '_ctl0_dtgList', 'chkSelect')"></asp:CheckBox>
                                    </HeaderTemplate>
                                    <ItemStyle VerticalAlign="Middle" HorizontalAlign="Center" />
                                    <ItemTemplate>
                                        <asp:CheckBox ID="chkSelect" CssClass="checkbox" runat="server"></asp:CheckBox>
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridTemplateColumn UniqueName="Edit" HeaderText="Sửa">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemTemplate>
                                        <asp:ImageButton CssClass="rgpointer" ID="Edit" runat="server" ImageUrl="~/Images/edit.png"
                                            CommandName="Edit_Data" />
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridTemplateColumn UniqueName="Seq" HeaderText="Seq">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemTemplate>
                                        <asp:Literal ID="glblItemSeqName" runat="server" Text='<%# Container.ItemIndex + 1 + dtgListThueNha.PageSize * dtgListThueNha.CurrentPageIndex%>' />
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridBoundColumn SortExpression="No" UniqueName="No" DataField="No" HeaderText="No">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="70px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="EffectiveDate" UniqueName="EffectiveDate" HeaderText="EffectiveDate"
                                    DataField="EffectiveDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="70px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="EndEffectDate" Visible="false" UniqueName="EndEffectDate" HeaderText="EndEffectDate"
                                    DataField="EndEffectDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="70px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="LSPassportTypeID" Visible="false" UniqueName="LSPassportTypeID" HeaderText="LSPassportTypeID"
                                    DataField="LSPassportTypeID">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IssueDate" UniqueName="IssueDateThueNha" HeaderText="IssueDateThueNha"
                                    DataField="IssueDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="70px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="ExpireDate" UniqueName="ExpireDateThueNha" HeaderText="ExpireDateThueNha"
                                    DataField="ExpireDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="70px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Address" Visible="false" UniqueName="Address" HeaderText="Address"
                                    DataField="Address">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="ChuCanHo" UniqueName="ChuCanHo" DataField="ChuCanHo" HeaderText="ChuCanHo">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="SoDienThoai" UniqueName="SoDienThoai" DataField="SoDienThoai" HeaderText="SoDienThoai">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="TienDatCoc" UniqueName="TienDatCoc" DataField="TienDatCoc" HeaderText="TienDatCoc">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Right" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="TienThueNha" UniqueName="TienThueNha" DataField="TienThueNha" HeaderText="TienThueNha">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Right" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="AdvancedNoticeTime" UniqueName="AdvancedNoticeTime" DataField="AdvancedNoticeTime" HeaderText="AdvancedNoticeTime"
                                    Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="TienThueNhaUSD" UniqueName="TienThueNhaUSD" DataField="TienThueNhaUSD" HeaderText="TienThueNhaUSD"
                                    Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="TerminationCondition" UniqueName="TerminationCondition" DataField="TerminationCondition" HeaderText="TerminationCondition"
                                    Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="LoaiTienTe" UniqueName="LoaiTienTe" DataField="LoaiTienTe" HeaderText="LoaiTienTe">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="OtherInfo1" Visible="false" UniqueName="OtherInfo1" HeaderText="OtherInfo1"
                                    DataField="OtherInfo1">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="OtherInfo2" Visible="false" UniqueName="OtherInfo2" HeaderText="OtherInfo2"
                                    DataField="OtherInfo2">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="OtherInfo3" Visible="false" UniqueName="OtherInfo3" HeaderText="OtherInfo3"
                                    DataField="OtherInfo3">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="LSCurrencyTypeID" Visible="false" UniqueName="LSCurrencyTypeID" HeaderText="LSCurrencyTypeID"
                                    DataField="LSCurrencyTypeID">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="PaidbyEmp" Visible="false" UniqueName="PaidbyEmp" HeaderText="PaidbyEmp"
                                    DataField="PaidbyEmp">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Return" Visible="false" UniqueName="Return" HeaderText="Return"
                                    DataField="Return">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="ReturnDate" Visible="false" UniqueName="ReturnDate" HeaderText="ReturnDate"
                                    DataField="ReturnDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Fee" Visible="false" UniqueName="Fee" DataField="Fee" HeaderText="Fee">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Right" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridTemplateColumn UniqueName="AttachFile" HeaderText="AttachFile" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" Width="200%"></HeaderStyle>
                                    <ItemStyle HorizontalAlign="Center"></ItemStyle>
                                    <ItemTemplate>
                                        <uc:multiattachbutton id="MultiAttachButton1" runat="server" width="95%">
                                        </uc:multiattachbutton>
                                        <asp:Label ID="lblAttachFile" runat="server" Visible="true" CssClass="Lable" Text='<%# DataBinder.Eval(Container, "DataItem.AttachFileID") %>'></asp:Label>
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridBoundColumn Visible="false" UniqueName="PassportVisaID" DataField="PassportVisaID" HeaderText="PassportVisaID">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn Visible="false" UniqueName="Type" DataField="Type" HeaderText="Type">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn Visible="false" UniqueName="Status" DataField="Status" HeaderText="Status">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn Visible="false" UniqueName="IsTuPhap" DataField="IsTuPhap" HeaderText="IsTuPhap">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn Visible="false" UniqueName="AttachFileID" DataField="AttachFileID" HeaderText="AttachFileID">
                                </telerik:GridBoundColumn>
                            </Columns>
                        </MasterTableView>
                        <HeaderStyle Width="950px" />
                        <ClientSettings AllowGroupExpandCollapse="True">
                            <Scrolling AllowScroll="True" UseStaticHeaders="True" />
                            <Resizing AllowColumnResize="true" ResizeGridOnColumnResize="true" EnableRealTimeResize="true" />
                        </ClientSettings>
                    </core:iHRPCoreGrid>
                </telerik:RadPane>
            </telerik:RadSplitter>
        </div>
        <div class="gridHolder" id="divdtgListGPLX">
            <telerik:RadSplitter ID="RadSplitter6" Width="950px" runat="server" Orientation="Horizontal"
                Height="100%">
                <telerik:RadPane ID="RadPane5" Height="300px" runat="server" Scrolling="None">
                    <core:iHRPCoreGrid ID="dtgListGPLX" GridLines="None" Height="300px" Width="948px" AutoGenerateColumns="false"
                        AllowPaging="true" runat="server" OnNeedDataSource="dtgListGPLX_NeedDataSource" OnItemCommand="dtgListGPLX_ItemCommand" OnItemDataBound="dtgListGPLX_ItemDataBound"
                        PageSize="15" Skin="Simple" ShowStatusBar="true" AllowSorting="true" PageSizeManual="true">
                        <PagerStyle Mode="NextPrevNumericAndAdvanced" AlwaysVisible="true" />
                        <MasterTableView TableLayout="Fixed" Width="100%" CommandItemDisplay="Top" AllowMultiColumnSorting="true"
                            GroupLoadMode="Client">
                            <CommandItemTemplate>
                                <asp:ImageButton ID="btnConfig" runat="server" ToolTip="Setting" CommandName="ConfigRadGrid"
                                    Width="10px" Height="10px" ImageUrl="~/Images/ConfigIcon.jpg" />
                            </CommandItemTemplate>
                            <Columns>
                                <telerik:GridTemplateColumn UniqueName="SelectCol" HeaderText="Chọn">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                    <HeaderTemplate>
                                        <asp:CheckBox ID="chkSelectAll" CssClass="checkbox" runat="server" onclick="CheckAll_RadGrid('_ctl0_dtgListGPLX__ctl0__ctl2__ctl2_chkSelectAll', '_ctl0_dtgListGPLX', 'chkSelect')"></asp:CheckBox>
                                    </HeaderTemplate>
                                    <ItemStyle VerticalAlign="Middle" HorizontalAlign="Center" />
                                    <ItemTemplate>
                                        <asp:CheckBox ID="chkSelect" CssClass="checkbox" runat="server"></asp:CheckBox>
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridTemplateColumn UniqueName="Edit" HeaderText="Sửa">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemTemplate>
                                        <asp:ImageButton CssClass="rgpointer" ID="Edit" runat="server" ImageUrl="~/Images/edit.png"
                                            CommandName="Edit_Data" />
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridTemplateColumn UniqueName="Seq" HeaderText="Seq">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemTemplate>
                                        <asp:Literal ID="glblItemSeqName" runat="server" Text='<%# Container.ItemIndex + 1 + dtgListGPLX.PageSize * dtgListGPLX.CurrentPageIndex%>' />
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridBoundColumn SortExpression="IssueDate" UniqueName="IssueDateGPLX" HeaderText="IssueDateGPLX"
                                    DataField="IssueDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="70px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="ExpireDate" UniqueName="ExpireDateGPLX" HeaderText="ExpireDateGPLX"
                                    DataField="ExpireDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="70px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="NameOnGPLX" Visible="false" UniqueName="NameOnGPLX" HeaderText="NameOnGPLX"
                                    DataField="NameOnGPLX">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IssuePlace_Province" Visible="false" UniqueName="IssuePlace_Province" HeaderText="IssuePlace_Province"
                                    DataField="IssuePlace_Province">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridTemplateColumn UniqueName="AttachFile" HeaderText="AttachFile" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" Width="200%"></HeaderStyle>
                                    <ItemStyle HorizontalAlign="Center"></ItemStyle>
                                    <ItemTemplate>
                                        <uc:multiattachbutton id="MultiAttachButton1" runat="server" width="95%">
                                        </uc:multiattachbutton>
                                        <asp:Label ID="lblAttachFile" runat="server" Visible="true" CssClass="Lable" Text='<%# DataBinder.Eval(Container, "DataItem.AttachFileID") %>'></asp:Label>
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridBoundColumn Visible="false" UniqueName="PassportVisaID" DataField="PassportVisaID" HeaderText="PassportVisaID">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn Visible="false" UniqueName="Type" DataField="Type" HeaderText="Type">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn Visible="false" UniqueName="AttachFileID" DataField="AttachFileID" HeaderText="AttachFileID">
                                </telerik:GridBoundColumn>
                            </Columns>
                        </MasterTableView>
                        <HeaderStyle Width="950px" />
                        <ClientSettings AllowGroupExpandCollapse="True">
                            <Scrolling AllowScroll="True" UseStaticHeaders="True" />
                            <Resizing AllowColumnResize="true" ResizeGridOnColumnResize="true" EnableRealTimeResize="true" />
                        </ClientSettings>
                    </core:iHRPCoreGrid>
                </telerik:RadPane>
            </telerik:RadSplitter>
        </div>
        <div class="gridHolder" id="divdtgListLLTP">
            <telerik:RadSplitter ID="RadSplitter7" Width="950px" runat="server" Orientation="Horizontal"
                Height="100%">
                <telerik:RadPane ID="RadPane6" Height="300px" runat="server" Scrolling="None">
                    <core:iHRPCoreGrid ID="dtgListLyLichTuPhap" GridLines="None" Height="300px" Width="948px" AutoGenerateColumns="false"
                        AllowPaging="true" runat="server" OnNeedDataSource="dtgListLLTP_NeedDataSource" OnItemCommand="dtgListLyLichTuPhap_ItemCommand" OnItemDataBound="dtgListLyLichTuPhap_ItemDataBound"
                        PageSize="15" Skin="Simple" ShowStatusBar="true" AllowSorting="true" PageSizeManual="true">
                        <PagerStyle Mode="NextPrevNumericAndAdvanced" AlwaysVisible="true" />
                        <MasterTableView TableLayout="Fixed" Width="100%" CommandItemDisplay="Top" AllowMultiColumnSorting="true"
                            GroupLoadMode="Client">
                            <CommandItemTemplate>
                                <asp:ImageButton ID="btnConfig" runat="server" ToolTip="Setting" CommandName="ConfigRadGrid"
                                    Width="10px" Height="10px" ImageUrl="~/Images/ConfigIcon.jpg" />
                            </CommandItemTemplate>
                            <Columns>
                                <telerik:GridTemplateColumn UniqueName="SelectCol" HeaderText="Chọn">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                    <HeaderTemplate>
                                        <asp:CheckBox ID="chkSelectAll" CssClass="checkbox" runat="server" onclick="CheckAll_RadGrid('_ctl0_dtgListLyLichTuPhap__ctl0__ctl2__ctl2_chkSelectAll', '_ctl0_dtgListLyLichTuPhap', 'chkSelect')"></asp:CheckBox>
                                    </HeaderTemplate>
                                    <ItemStyle VerticalAlign="Middle" HorizontalAlign="Center" />
                                    <ItemTemplate>
                                        <asp:CheckBox ID="chkSelect" CssClass="checkbox" runat="server"></asp:CheckBox>
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridTemplateColumn UniqueName="Edit" HeaderText="Sửa">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemTemplate>
                                        <asp:ImageButton CssClass="rgpointer" ID="Edit" runat="server" ImageUrl="~/Images/edit.png"
                                            CommandName="Edit_Data" />
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridTemplateColumn UniqueName="Seq" HeaderText="Seq">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemTemplate>
                                        <asp:Literal ID="glblItemSeqName" runat="server" Text='<%# Container.ItemIndex + 1 + dtgListLyLichTuPhap.PageSize * dtgListLyLichTuPhap.CurrentPageIndex%>' />
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridBoundColumn SortExpression="No" UniqueName="No" HeaderText="No"
                                    DataField="No">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IssueDate" UniqueName="IssueDate" HeaderText="IssueDate"
                                    DataField="IssueDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="70px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IssuePlace" UniqueName="IssuePlace" HeaderText="IssuePlace"
                                    DataField="IssuePlace">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="70px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="TinhTrangAnTich" Visible="false" UniqueName="TinhTrangAnTich" HeaderText="TinhTrangAnTich"
                                    DataField="TinhTrangAnTich">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="LoaiLyLichTuPhapName" Visible="false" UniqueName="LoaiLyLichTuPhapName" HeaderText="LoaiLyLichTuPhapName"
                                    DataField="LoaiLyLichTuPhapName">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Note" Visible="false" UniqueName="Note" HeaderText="Note"
                                    DataField="Note">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IssuePlace_Province" Visible="false" UniqueName="IssuePlace_Province" HeaderText="IssuePlace_Province"
                                    DataField="IssuePlace_Province">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridTemplateColumn UniqueName="AttachFile" HeaderText="AttachFile" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" Width="200%"></HeaderStyle>
                                    <ItemStyle HorizontalAlign="Center"></ItemStyle>
                                    <ItemTemplate>
                                        <uc:multiattachbutton id="MultiAttachButton1" runat="server" width="95%">
                                        </uc:multiattachbutton>
                                        <asp:Label ID="lblAttachFile" runat="server" Visible="true" CssClass="Lable" Text='<%# DataBinder.Eval(Container, "DataItem.AttachFileID") %>'></asp:Label>
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridBoundColumn SortExpression="OtherInfo1" Visible="false" UniqueName="OtherInfo1" HeaderText="OtherInfo1"
                                    DataField="OtherInfo1">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="OtherInfo2" Visible="false" UniqueName="OtherInfo2" HeaderText="OtherInfo2"
                                    DataField="OtherInfo2">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="OtherInfo3" Visible="false" UniqueName="OtherInfo3" HeaderText="OtherInfo3"
                                    DataField="OtherInfo3">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Creater" Visible="false" UniqueName="Creater" HeaderText="Creater"
                                    DataField="Creater">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="CreateTime" Visible="false" UniqueName="CreateTime" HeaderText="CreateTime"
                                    DataField="CreateTime">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="EditTime" Visible="false" UniqueName="EditTime" HeaderText="EditTime"
                                    DataField="EditTime">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Editer" Visible="false" UniqueName="Editer" HeaderText="Editer"
                                    DataField="Editer">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn Visible="false" UniqueName="PassportVisaID" DataField="PassportVisaID" HeaderText="PassportVisaID">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn Visible="false" UniqueName="Type" DataField="Type" HeaderText="Type">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn Visible="false" UniqueName="AttachFileID" DataField="AttachFileID" HeaderText="AttachFileID">
                                </telerik:GridBoundColumn>
                            </Columns>
                        </MasterTableView>
                        <HeaderStyle Width="950px" />
                        <ClientSettings AllowGroupExpandCollapse="True">
                            <Scrolling AllowScroll="True" UseStaticHeaders="True" />
                            <Resizing AllowColumnResize="true" ResizeGridOnColumnResize="true" EnableRealTimeResize="true" />
                        </ClientSettings>
                    </core:iHRPCoreGrid>
                </telerik:RadPane>
            </telerik:RadSplitter>
        </div>
    </div>
</div>

<div style="display: none">
    <input id="txtID" style="width: 9px; height: 22px" type="hidden" size="10" name="txtID" runat="server">
    <input id="txtStatus" style="width: 9px; height: 22px" type="hidden" size="10" name="txtStatus" runat="server">
    <input id="txtKiemTraNgayTra" style="width: 9px; height: 22px" type="hidden" size="10" name="txtID" runat="server" />
    <asp:CheckBox ID="chkNgayHetHan" runat="server" />
    <asp:TextBox ID="txtAttach" runat="server"></asp:TextBox>
    <asp:HiddenField ID="txtStringData_Dev" runat="server" />
    <asp:TextBox ID="txtPassportVisaID" runat="server"></asp:TextBox>
    <asp:TextBox ID="txtHNgayNhapCanh" runat="server" Width="100px"/>
    <asp:TextBox ID="txtHNgayXuatCanh" runat="server" Width="100px"/>
    <asp:TextBox ID="txtHNgayLuuTruVN" runat="server" Width="100px"/>

</div>

<% 
    DataTable dtDivs = clsCommon.GetRankAndStyleOfDivs(iHRPCore.Mession.DecryptFunctionID);
    int TotalDivs = dtDivs.Rows.Count;
%>
<script>
    var DSDivs = new Array(6);
    DSDivs[0] = new Array(<%=TotalDivs%>);																
    DSDivs[1] = new Array(<%=TotalDivs%>);
    DSDivs[2] = new Array(<%=TotalDivs%>);
    DSDivs[3] = new Array(<%=TotalDivs%>);
    DSDivs[4] = new Array(<%=TotalDivs%>);
    DSDivs[5] = new Array(<%=TotalDivs%>);
    
    <% for (int i = 0; i < TotalDivs; i++)
       {
           DataTable dtDivsCap2 = clsCommon.GetRankAndStyleOfDivsCap2(iHRPCore.Mession.DecryptFunctionID, dtDivs.Rows[i]["DivID"].ToString());
           int TotalDivsCap2 = dtDivsCap2.Rows.Count;
        %>
    var DSDivsCap2 = new Array(5);
    DSDivsCap2[0] = new Array(<%=TotalDivsCap2%>);																
    DSDivsCap2[1] = new Array(<%=TotalDivsCap2%>);
    DSDivsCap2[2] = new Array(<%=TotalDivsCap2%>);
    DSDivsCap2[3] = new Array(<%=TotalDivsCap2%>);
    DSDivsCap2[4] = new Array(<%=TotalDivsCap2%>);
        <%     
           for (int j = 0; j < TotalDivsCap2; j++)
           {
        %>
    DSDivsCap2[0][<%=j%>]="<%=dtDivsCap2.Rows[j]["DivID"]%>";
    DSDivsCap2[1][<%=j%>]="<%=dtDivsCap2.Rows[j]["Rank_Row"]%>";			
    DSDivsCap2[2][<%=j%>]="";	
    DSDivsCap2[3][<%=j%>]="<%=dtDivsCap2.Rows[j]["Visible"]%>";			
    DSDivsCap2[4][<%=j%>]="<%=dtDivsCap2.Rows[j]["VisibleAll"]%>";
    <%
           }
    %>		
    DSDivs[0][<%=i%>]="<%=dtDivs.Rows[i]["DivID"]%>";
    DSDivs[1][<%=i%>]="<%=dtDivs.Rows[i]["Rank_Row"]%>";			
    DSDivs[2][<%=i%>]="";	
    DSDivs[3][<%=i%>]="<%=dtDivs.Rows[i]["Visible"]%>";			
    DSDivs[4][<%=i%>]="<%=dtDivs.Rows[i]["VisibleAll"]%>";
    DSDivs[5][<%=i%>]=DSDivsCap2;

    <%}%>	
</script>


<script type="text/javascript">
    if (document.getElementById("<%= txtStringData_Dev.ClientID %>") != null)
        sortChildrenDivsById('DivColumn1', false,'txtStringData_Dev');

    setIndexAndStyle('DivColumn1',DSDivs, '<%=strUserGroupID%>');
    function checkisnull(obj) {
        if (document.getElementById('_ctl0_' + obj).value == "") {
            GetAlertError(iTotal, DSAlert, "0003");
            document.getElementById('_ctl0_' + obj).focus();
            return false;
        }
        else
            return true;
    }

    function isStrNullOrUndifinedOrEmpty(str) {
        return str === null ||  str === undefined || str === '' || str === 'null'
    }

    function checkempty(obj) {
        if (document.getElementById('_ctl0_' + obj).value == "")
            return true;
        else
            return false;
    }



    //kiem tra User co nhap cac gia tri bat buoc truoc khi Save
    function checksave() {
        if (!checkisnull('HR_EmpHeader_txtEmpID')) return false;
        


        if (document.getElementById('_ctl0_optPermit').checked) // Gi?y phép lao d?ng
        {
            if (checkisnull('txtWP_Number') == false) return false;
            if (checkisnull('txtWP_IssuedDate') == false) return false;
            if (checkisnull('txtWP_EffDate') == false) return false;
            
            if (FromSmallOrEqualToDate(document.getElementById('_ctl0_txtWP_IssuedDate'), document.getElementById('_ctl0_txtWP_EffDate')) == false) {
                GetAlertError(iTotal, DSAlert, "009900994")
                document.getElementById('_ctl0_txtWP_IssuedDate').focus();
                return false;
            }

            if (!checkempty('txtWP_ExpiredDate')) {
                //Check IssuedDate <= ExpiredDate
                if (FromSmallOrEqualToDate(document.getElementById('_ctl0_txtWP_IssuedDate'), document.getElementById('_ctl0_txtWP_ExpiredDate')) == false) {
                    GetAlertError(iTotal, DSAlert, "00990099")
                    document.getElementById('_ctl0_txtWP_ExpiredDate').focus();
                    return false;
                }
                //Check EffDate <= ExpiredDate
                if (FromSmallOrEqualToDate(document.getElementById('_ctl0_txtWP_EffDate'), document.getElementById('_ctl0_txtWP_ExpiredDate')) == false) {
                    GetAlertError(iTotal, DSAlert, "0021")
                    document.getElementById('_ctl0_txtWP_ExpiredDate').focus();
                    return false;
                }
            }
            //           
            if (document.getElementById("<%=chkNgayHetHan.ClientID %>").checked) {
                if (checkisnull('txtWP_ExpiredDate') == false) return false;
            }
            //
            if (document.getElementById("<%=chkWPTuPhap.ClientID %>").checked) {
                // alert(document.getElementById("_ctl0_MultiAttachButton1_txtAttachFileParentID").value);
                
                if (document.getElementById("_ctl0_MultiAttachButton1_txtAttachFileParentID").value == '&nbsp;') {
                    GetAlertError(iTotal, DSAlert, "Visa_0101")
                    return false;
                }
            }
            ///_ctl0_MultiAttachButton1_txtAttachFileParentID
            if (document.getElementById('<%=chkReturn.ClientID %>').checked) {
                var bol = document.getElementById('_ctl0_txtKiemTraNgayTra').value;
                if (checkisnull('txtReturnDate') == false) return false;
                if (bol == 'False') {
                    if (FromSmallOrEqualToDate(document.getElementById('_ctl0_txtWP_ExpiredDate'), document.getElementById('_ctl0_txtReturnDate')) == false) {
                        GetAlertError(iTotal, DSAlert, "01201")
                        document.getElementById('_ctl0_txtReturnDate').focus();
                        return false;
                    }
                }
                else {
                    if (FromSmallOrEqualToDate(document.getElementById('_ctl0_txtWP_EffDate'), document.getElementById('_ctl0_txtReturnDate')) == false) {
                        GetAlertError(iTotal, DSAlert, "0214")
                        document.getElementById('_ctl0_txtReturnDate').focus();
                        return false;
                    }
                }


            }

            if('<%=KiemTraNgayCap_HieuLucNhoHonNgaySinh%>'=='TRUE'){
                if (KiemTraNgayCap_HieuLucNhoHonNgaySinh_() == false)
                    return false;
            }

            if('<%=BatBuocNhapNgayHetHanVisaPassport%>'=='TRUE'){
                if (checkisnull('txtWP_ExpiredDate') == false) return false;
            }

            if('<%=BatBuocNhapLoaiGiayPhepLD%>' == 'TRUE') {
                if (CheckIsNull_RCB('cboLoaiGiayPhepLaoDong') == false) return false;
            }

            DisableAllButton('_ctl0:btnE_Save'); 
            return true;
        }
        else if (document.getElementById('_ctl0_optPassport').checked) // H? chi?u
        {
            if (checkisnull('txtPass_Number') == false) return false;
            if (checkisnull('txtPass_IssuedDate') == false) return false;
            if (checkisnull('txtPass_EffDate') == false) return false;
            if (document.getElementById("<%=chkNgayHetHan.ClientID %>").checked) {
                if (checkisnull('txtPass_EndEffDate') == false) return false;
            }
            if (!checkempty('txtPass_EffDate')) {
                if (FromSmallOrEqualToDate(document.getElementById('_ctl0_txtPass_IssuedDate'), document.getElementById('_ctl0_txtPass_EffDate')) == false) {
                    GetAlertError(iTotal, DSAlert, "00201")
                    document.getElementById('_ctl0_txtPass_EffDate').focus();
                    return false;
                }
            }

            //Check IssuedDate <= End EffectDate
            if (!checkempty('txtPass_EndEffDate')) {
                if (FromSmallOrEqualToDate(document.getElementById('_ctl0_txtPass_IssuedDate'), document.getElementById('_ctl0_txtPass_EndEffDate')) == false) {
                    GetAlertError(iTotal, DSAlert, "00214")
                    document.getElementById('_ctl0_txtPass_EndEffDate').focus();
                    return false;
                }
            }

            //Check Effect Date <= End EffectDate
            if (!checkempty('txtPass_EffDate') && !checkempty('txtPass_EndEffDate')) {
                if (FromSmallOrEqualToDate(document.getElementById('_ctl0_txtPass_EffDate'), document.getElementById('_ctl0_txtPass_EndEffDate')) == false) {
                    GetAlertError(iTotal, DSAlert, "0021")
                    document.getElementById('_ctl0_txtPass_EndEffDate').focus();
                    return false;
                }
            }

            if('<%=KiemTraNgayCap_HieuLucNhoHonNgaySinh%>'=='TRUE'){
                if (KiemTraNgayCap_HieuLucNhoHonNgaySinh_() == false)
                    return false;
            }
            if('<%=BatBuocNhapNgayHetHanVisaPassport%>'=='TRUE'){
                if (checkisnull('txtPass_EndEffDate') == false) return false;
            }

            if('<%=BatBuocNhapNoiCapPassport%>' == 'TRUE') {
                if (CheckIsNull_RCB('cboPass_IssuedPlace') == false) return false;
            }

            if('<%=BatBuocNhapLoaiPassport%>' == 'TRUE') { 
                if (CheckIsNull_RCB('cboPass_Type') == false) return false;
            }
            DisableAllButton('_ctl0:btnE_Save'); 
            return true;
        }
        else if (document.getElementById('_ctl0_optVisa').checked) // Th? th?c
        {
            if (checkisnull('txtVisa_Number') == false) return false;
            if (checkisnull('txtVisa_IssuedDate') == false) return false;
            if (checkisnull('txtVisa_EffDate') == false) return false;
            if (FromSmallOrEqualToDate(document.getElementById('_ctl0_txtVisa_IssuedDate'), document.getElementById('_ctl0_txtVisa_EffDate')) == false) {
                GetAlertError(iTotal, DSAlert, "00201")
                document.getElementById('_ctl0_txtVisa_EffDate').focus();
                return false;
            }

            if (document.getElementById("<%=chkNgayHetHan.ClientID %>").checked) {
                if (checkisnull('txtVisa_ExpiredDate') == false) return false;
            }

            if (!checkempty('txtVisa_ExpiredDate')) {
                if (FromSmallOrEqualToDate(document.getElementById('_ctl0_txtVisa_IssuedDate'), document.getElementById('_ctl0_txtVisa_ExpiredDate')) == false) {
                    GetAlertError(iTotal, DSAlert, "00214")
                    document.getElementById('_ctl0_txtVisa_ExpiredDate').focus();
                    return false;
                }
                if (FromSmallOrEqualToDate(document.getElementById('_ctl0_txtVisa_EffDate'), document.getElementById('_ctl0_txtVisa_ExpiredDate')) == false) {
                    GetAlertError(iTotal, DSAlert, "0021")
                    document.getElementById('_ctl0_txtVisa_ExpiredDate').focus();
                    return false;
                }
            }

            if('<%=KiemTraNgayCap_HieuLucNhoHonNgaySinh%>'=='TRUE'){
                if (KiemTraNgayCap_HieuLucNhoHonNgaySinh_() == false)
                    return false;
            }

            if('<%=BatBuocNhapNgayHetHanVisaPassport%>'=='TRUE'){
                if (checkisnull('txtVisa_ExpiredDate') == false) return false;
            }

            if('<%=BatBuocNhapLoaiVisa%>'=='TRUE'){
                if (CheckIsNull_RCB('cboLoaiVisaID') == false) return false;
            }

            if('<%=BatBuocNhapNoiCapVisa%>'=='TRUE'){
                if (CheckIsNull_RCB('cboVisa_IssuedPlace') == false) return false;
            }

            if('<%=BatBuocNhapQuocGiaDen%>'=='TRUE'){
                if (CheckIsNull_RCB('cboQuocGiaDenID') == false) return false;
            }


            DisableAllButton('_ctl0:btnE_Save'); 
            return true;
        }
        else if (document.getElementById('_ctl0_optTempLicence').checked) // Gi?y t?m trú
        {
            // if (checkisnull('txtTempLic_Number') == false) return false;
            if (checkisnull('txtTempLic_IssuedDate') == false) return false;
            if('<%=BoBatBuocNhapNoiCapTheTamTru_MHThongTinVisaPassport%>'=='FALSE'){
                document.getElementById('<%=Label21.ClientID %>').className = 'LabelRequire';
                if (checkisnull('txtTempLic_IssuedPlace') == false) return false;
            }
            if (document.getElementById('_ctl0_txtTempLic_IssuedDate').value != "") {
            }
            //
            if (document.getElementById("<%=chkNgayHetHan.ClientID %>").checked) {
                if (checkisnull('txtTempLic_ExpiredDate') == false) return false;
            }
            //Check IssuedDate <= ExpiredDate
            if (!checkempty('txtTempLic_ExpiredDate')) {
                if (FromSmallOrEqualToDate(document.getElementById('_ctl0_txtTempLic_IssuedDate'), document.getElementById('_ctl0_txtTempLic_ExpiredDate')) == false) {
                    GetAlertError(iTotal, DSAlert, "00990099")
                    document.getElementById('_ctl0_txtTempLic_ExpiredDate').focus();
                    return false;
                }
            }

            if('<%=KiemTraNgayCap_HieuLucNhoHonNgaySinh%>'=='TRUE'){
                if (KiemTraNgayCap_HieuLucNhoHonNgaySinh_() == false)
                    return false;
            }

            if('<%=BatBuocNhapNgayHetHanVisaPassport%>'=='TRUE'){
                if (checkisnull('txtTempLic_ExpiredDate') == false) return false;
            }

            DisableAllButton('_ctl0:btnE_Save'); 
            return true;
        }
        else if (document.getElementById('_ctl0_optHDThueNha').checked) // Thuê nhà
        {
            if (checkisnull('txtThoiHanTu') == false) return false;
            if (checkisnull('txtDenNgay') == false) return false;
            if (checkisnull('txtTienThueNha') == false) return false;

            //Check IssuedDate <= ExpiredDate
            if (!checkempty('txtTienThueNha')) {
                if (FromSmallOrEqualToDate(document.getElementById('_ctl0_txtThoiHanTu'), document.getElementById('_ctl0_txtDenNgay')) == false) {
                    GetAlertError(iTotal, DSAlert, "00990099")
                    document.getElementById('_ctl0_txtThoiHanTu').focus();
                    return false;
                }
            }
            DisableAllButton('_ctl0:btnE_Save'); 
            return true;
        }
        else if (document.getElementById('_ctl0_optGiayPhepLaiXe').checked) // GPLX
        {
            if (checkisnull('txtPass_IssuedDateGPLX') == false) return false;

            //Check IssuedDate <= ExpiredDate
            if (FromSmallOrEqualToDate(document.getElementById('_ctl0_txtPass_IssuedDateGPLX'), document.getElementById('_ctl0_txtPass_EffDateGPLX')) == false) {
                GetAlertError(iTotal, DSAlert, "00990099")
                document.getElementById('_ctl0_txtThoiHanTu').focus();
                return false;
            }
            DisableAllButton('_ctl0:btnE_Save'); 
            return true;
        } else if (document.getElementById('_ctl0_optLyLichTuPhap').checked) { //LLTP
            if('<%=BBNhapSoLyLichTuPhap%>' == 'TRUE') {
                    if (checkisnull('txtSoLyLichTuPhap') == false) return false;
                }
                if (checkisnull('txtTinhTrangAnTich') == false) return false;
                if (checkisnull('txtNgayCap_LLTP') == false) return false;
                if (checkisnull('txtNoiCap_LLTP') == false) return false;
                if (CheckIsNull_RCB('cboLoaiLyLichTuPhap') == false) return false;
            }



    return true;
}

//kiem tra User co check chon truoc khi Delete
function checkdelete() {
    
    var dtgList = "";
    if(document.getElementById('_ctl0_optHDThueNha').checked)
        dtgList = "_ctl0_dtgListThueNha";
    else if (document.getElementById('_ctl0_optPermit').checked)
        dtgList = "_ctl0_dtgListGiayPhepLaoDong";
    else if (document.getElementById('_ctl0_optPassport').checked)
        dtgList = "_ctl0_dtgListPassport";
    else if (document.getElementById('_ctl0_optVisa').checked)
        dtgList = "_ctl0_dtgListVisa";
    else if (document.getElementById('_ctl0_optTempLicence').checked)
        dtgList = "_ctl0_dtgListTempLicence";
    else if (document.getElementById('_ctl0_optGiayPhepLaiXe').checked)
        dtgList = "_ctl0_dtgListGPLX";
    else if (document.getElementById('_ctl0_optLyLichTuPhap').checked)
        dtgList = "_ctl0_dtgListLyLichTuPhap";
    if (dtgList!="") {
        if (GridCheck_RadGrid(dtgList, 'chkSelect') == false) {
            GetAlertError(iTotal, DSAlert, "0001");
            return false;
        }
    }
    
    if (confirm(GetAlertText(iTotal, DSAlert, "0002")) == false) {
        return false;
    }
    DisableAllButton('_ctl0:btnE_Delete'); 
}

function ShowReturnDate_WP() {
    var chkReturn = document.getElementById('<%=chkReturn.ClientID%>');
    if (chkReturn.checked) {
        document.getElementById('<%=divReturnDate.ClientID %>').style.display = "";
    }
    else {
        document.getElementById('<%=divReturnDate.ClientID %>').style.display = "none";
    }
}

function ShowHideLuoi() {        
    if (document.getElementById('_ctl0_optPermit').checked) {
        document.getElementById("divtgListGiayPhepLaoDong").style.display = "";
        document.getElementById("divdtgListPassport").style.display = "none";
        document.getElementById("divdtgListVisa").style.display = "none";
        document.getElementById("divdtgListTempLicence").style.display = "none";
        document.getElementById("divdtgListThueNha").style.display = "none";
        document.getElementById("divdtgListGPLX").style.display = "none";
        document.getElementById("divdtgListLLTP").style.display = "none";

        //document.getElementById('_ctl0_trThueNha5').style.display = 'none';
        document.getElementById('_ctl0_divAdvanced').style.display = 'none';
        document.getElementById('_ctl0_divTienThueNhaUSD').style.display = 'none';

        //document.getElementById('_ctl0_trThueNha6').style.display = 'none';
        document.getElementById('_ctl0_divTermination').style.display = 'none';
        document.getElementById("_ctl0_divLoaiGiayTamTru").style.display = 'none';
    }
    else if (document.getElementById('_ctl0_optPassport').checked) {
        document.getElementById("divdtgListPassport").style.display = "";
        document.getElementById("divtgListGiayPhepLaoDong").style.display = "none";
        document.getElementById("divdtgListVisa").style.display = "none";
        document.getElementById("divdtgListTempLicence").style.display = "none";
        document.getElementById("divdtgListThueNha").style.display = "none";
        document.getElementById("divdtgListGPLX").style.display = "none";
        document.getElementById("divdtgListLLTP").style.display = "none";

        //document.getElementById('_ctl0_trThueNha5').style.display = 'none';
        document.getElementById('_ctl0_divAdvanced').style.display = 'none';
        document.getElementById('_ctl0_divTienThueNhaUSD').style.display = 'none';

        //document.getElementById('_ctl0_trThueNha6').style.display = 'none';
        document.getElementById('_ctl0_divTermination').style.display = 'none';
        document.getElementById("_ctl0_divLoaiGiayTamTru").style.display = 'none';
    }
    else if (document.getElementById('_ctl0_optVisa').checked) {
        document.getElementById("divdtgListVisa").style.display = "";
        document.getElementById("divdtgListPassport").style.display = "none";
        document.getElementById("divtgListGiayPhepLaoDong").style.display = "none";
        document.getElementById("divdtgListTempLicence").style.display = "none";
        document.getElementById("divdtgListThueNha").style.display = "none";
        document.getElementById("divdtgListGPLX").style.display = "none";
        document.getElementById("divdtgListLLTP").style.display = "none";

        //document.getElementById('_ctl0_trThueNha5').style.display = 'none';
        document.getElementById('_ctl0_divAdvanced').style.display = 'none';
        document.getElementById('_ctl0_divTienThueNhaUSD').style.display = 'none';

        //document.getElementById('_ctl0_trThueNha6').style.display = 'none';
        document.getElementById('_ctl0_divTermination').style.display = 'none';
        document.getElementById("_ctl0_divLoaiGiayTamTru").style.display = 'none';
    }
    else if (document.getElementById('_ctl0_optTempLicence').checked) {
        document.getElementById("divdtgListTempLicence").style.display = "";
        document.getElementById("divdtgListVisa").style.display = "none";
        document.getElementById("divdtgListPassport").style.display = "none";
        document.getElementById("divtgListGiayPhepLaoDong").style.display = "none";
        document.getElementById("divdtgListThueNha").style.display = "none";
        document.getElementById("divdtgListGPLX").style.display = "none";
        document.getElementById("divdtgListLLTP").style.display = "none";

        //document.getElementById('_ctl0_trThueNha5').style.display = 'none';
        document.getElementById('_ctl0_divAdvanced').style.display = 'none';
        document.getElementById('_ctl0_divTienThueNhaUSD').style.display = 'none';

        //document.getElementById('_ctl0_trThueNha6').style.display = 'none';
        document.getElementById('_ctl0_divTermination').style.display = 'none';
        if('<%=BoBatBuocNhapNoiCapTheTamTru_MHThongTinVisaPassport%>'=='FALSE'){
            document.getElementById('<%=Label21.ClientID %>').className = 'LabelRequire';
        }
        document.getElementById("_ctl0_divLoaiGiayTamTru").style.display = '';
    }
    else if (document.getElementById('_ctl0_optGiayPhepLaiXe').checked) {
        document.getElementById("divdtgListGPLX").style.display = "";
        document.getElementById("divdtgListVisa").style.display = "none";
        document.getElementById("divdtgListPassport").style.display = "none";
        document.getElementById("divtgListGiayPhepLaoDong").style.display = "none";
        document.getElementById("divdtgListTempLicence").style.display = "none";
        document.getElementById("divdtgListThueNha").style.display = "none";
        document.getElementById("divdtgListLLTP").style.display = "none";

        document.getElementById('_ctl0_divAdvanced').style.display = 'none';
        document.getElementById('_ctl0_divTienThueNhaUSD').style.display = 'none';


        document.getElementById('_ctl0_divTermination').style.display = 'none';
        document.getElementById('_ctl0_divThongTinKhac1').style.display = 'none';
        document.getElementById('_ctl0_divThongTinKhac2').style.display = 'none';
        document.getElementById('_ctl0_divThongTinKhac3').style.display = 'none';
        document.getElementById("_ctl0_divLoaiGiayTamTru").style.display = 'none';
    }
    else if (document.getElementById('_ctl0_optLyLichTuPhap').checked) {
        document.getElementById("divdtgListLLTP").style.display = "";
        document.getElementById("divdtgListGPLX").style.display = "none";
        document.getElementById("divdtgListVisa").style.display = "none";
        document.getElementById("divdtgListPassport").style.display = "none";
        document.getElementById("divtgListGiayPhepLaoDong").style.display = "none";
        document.getElementById("divdtgListTempLicence").style.display = "none";
        document.getElementById("divdtgListThueNha").style.display = "none";
        
        document.getElementById('_ctl0_divAdvanced').style.display = 'none';
        document.getElementById('_ctl0_divTienThueNhaUSD').style.display = 'none';
        document.getElementById('_ctl0_divTermination').style.display = 'none';
        document.getElementById("_ctl0_divLoaiGiayTamTru").style.display = 'none';
    }
    else {
        document.getElementById("divdtgListThueNha").style.display = "";
        document.getElementById("divdtgListTempLicence").style.display = "none";
        document.getElementById("divdtgListVisa").style.display = "none";
        document.getElementById("divdtgListPassport").style.display = "none";
        document.getElementById("divtgListGiayPhepLaoDong").style.display = "none";
        document.getElementById("divdtgListGPLX").style.display = "none";
        document.getElementById("divdtgListLLTP").style.display = "none";
        //document.getElementById('_ctl0_trThueNha5').style.display = '';
        document.getElementById('_ctl0_divAdvanced').style.display = '';
        document.getElementById('_ctl0_divTienThueNhaUSD').style.display = '';

        //document.getElementById('_ctl0_trThueNha6').style.display = '';
        document.getElementById('_ctl0_divTermination').style.display = '';
        document.getElementById("_ctl0_divLoaiGiayTamTru").style.display = 'none';
    }
}
ShowHideLuoi();
</script>

<script language="javascript">
    if (document.getElementById('_ctl0_optPermit').checked)
        ShowReturnDate_WP();
        
    if (document.getElementById("<%=chkNgayHetHan.ClientID %>").checked == true || "<%= BatBuocNhapNgayHetHanVisaPassport %>" == "TRUE"){
        if(document.getElementById('<%=lblWP_ExpiredDate.ClientID %>') != null)
            document.getElementById('<%=lblWP_ExpiredDate.ClientID %>').className = 'LabelRequire';
        if(document.getElementById('<%=Label6.ClientID %>') != null)
            document.getElementById('<%=Label6.ClientID %>').className = 'LabelRequire';
        if(document.getElementById('<%=lblVisa_ExpiredDate.ClientID %>') != null)
            document.getElementById('<%=lblVisa_ExpiredDate.ClientID %>').className = 'LabelRequire';
        if(document.getElementById('<%=Label20.ClientID %>') != null)
            document.getElementById('<%=Label20.ClientID %>').className = 'LabelRequire';
        
    }

    if('<%=BatBuocNhapLoaiGiayPhepLD%>' == 'TRUE') {
        document.getElementById("_ctl0_lblLoaiGiayPhepLaoDong").className = 'LabelRequire';
    }

    if('<%=BatBuocNhapNoiCapPassport%>' == 'TRUE') {
        document.getElementById("_ctl0_lblPass_NoiCap_Province").className = 'LabelRequire';
    }

    if('<%=BatBuocNhapLoaiPassport%>' == 'TRUE') {
        document.getElementById("_ctl0_Label2").className = 'LabelRequire';
    }

    if('<%=BatBuocNhapLoaiVisa%>' == 'TRUE') {
        document.getElementById("_ctl0_lblLoaiVisa").className = 'LabelRequire';
    }

    if('<%=BatBuocNhapNoiCapVisa%>' == 'TRUE') {
        document.getElementById("_ctl0_lblVisa_NoiCap_Province").className = 'LabelRequire';
    }

    if('<%=BatBuocNhapQuocGiaDen%>' == 'TRUE') {
        document.getElementById("_ctl0_lblQuocGiaDen").className = 'LabelRequire';
    }

    if('<%=BatBuocNhapNgayHieuLucVisa%>' == 'TRUE') {
        document.getElementById("_ctl0_Label2").className = 'LabelRequire';
    }

    if('<%=BBNhapSoLyLichTuPhap%>' == 'TRUE') {
        document.getElementById("_ctl0_lblSoLyLichTuPhap").className = 'LabelRequire';
    }

    //20150527 - TrangNT - RL 5830
    function Check_SoNamHLPassport(obj)
    {
        var HR_SoNamHLPassport = '<%= HR_SoNamHLPassport%>';
        if (HR_SoNamHLPassport != "" && HR_SoNamHLPassport != "0")
        {
            var FD = document.getElementById('_ctl0_txtPass_EffDate');
            var TD = document.getElementById('_ctl0_txtPass_EndEffDate');
            if(FD.value !='' && TD.value !='')
            {
                var reVal = CountYear(FD, TD, HR_SoNamHLPassport);
                if(reVal == false)
                {
                    //Số năm tối đa hiệu lực Passport không được quá $$$
                    GetAlertError_Replace(iTotal, DSAlert, "NTT_0043", "$$$", HR_SoNamHLPassport)
                    obj.value="";
                    obj.focus();
                    return false;
                }
            }
            
        }
    }

    function CountYear(FromDate,ToDate,HR_SoNamHLPassport)
    {
        var reVal=true;
        document.getElementById('_ctl0_txtTempDate').value = "";
        var From =  FromDate.value.split('/');
        var df= new Date(From[2], parseInt(From[1])-1, From[0]);

        //Tăng số năm lên
        df.setFullYear(parseInt(df.getFullYear())+parseInt(HR_SoNamHLPassport));
        //Giảm đi 1 ngày cho tròn năm
        df.setDate(df.getDate()-1);

        var sDate = df.getDate().toString();
        var sMonth = (df.getMonth()+1).toString();
        var sYear = (df.getFullYear()).toString();

        if(sDate.length <2)
            sDate = '0'+sDate.toString();
        if(sMonth.length <2)
            sMonth = '0'+sMonth.toString();
       
        document.getElementById('_ctl0_txtTempDate').value= sDate+'/'+sMonth+'/'+sYear;

        if(FromSmallOrEqualToDate(ToDate,document.getElementById('_ctl0_txtTempDate'))==false)
            reVal = false;
        return reVal;
    }
    function transfernext__() {
        if('<%=LuuVaTiepTuc_TTNV%>'=='TRUE'){
            if(checksave()==false) return false;
            DisableAllButton('_ctl0:btnE_Save'); 
        }
        ForeignerInfo.TransferNext("", transfer);
        return false;
    }

    function KiemTraNgayCap_HieuLucNhoHonNgaySinh_() {

        var Chon;
        var NgayCap = "", NgayHieuLuc = "", EmpID = "";
        EmpCode = document.getElementById('_ctl0_HR_EmpHeader_txtEmpID');


        if (document.getElementById('_ctl0_optPermit').checked){
            NgayCap = document.getElementById('_ctl0_txtWP_IssuedDate');
            NgayHieuLuc = document.getElementById('_ctl0_txtWP_EffDate');
            Chon = "optPermit";
        }
        if (document.getElementById('_ctl0_optPassport').checked){
            NgayCap = document.getElementById('_ctl0_txtPass_IssuedDate');
            NgayHieuLuc = document.getElementById('_ctl0_txtPass_EffDate');
            Chon = "Passport";
        }
        if (document.getElementById('_ctl0_optVisa').checked){
            NgayCap = document.getElementById('_ctl0_txtVisa_IssuedDate');
            NgayHieuLuc = document.getElementById('_ctl0_txtVisa_EffDate');
            Chon = "Visa";
        }
        if (document.getElementById('_ctl0_optTempLicence').checked){
            NgayCap = document.getElementById('_ctl0_txtTempLic_IssuedDate');
            NgayHieuLuc = document.getElementById('_ctl0_txtTempLic_EffDate');
            Chon = "TempLicence";
        }
        
        if (EmpCode.value != "" && (NgayCap.value != "" || NgayHieuLuc.value != ""))
        {
            var data = ForeignerInfo.KiemTraNgayCap_HieuLucNhoHonNgaySinh(EmpCode.value, NgayCap.value, NgayHieuLuc.value);
            if(data.value > 0) {
                GetAlertError(iTotal,DSAlert,"10122021_1");		
                NgayCap.focus();
                return false;
            }
            if(data.value < 0) {
                GetAlertError(iTotal,DSAlert,"10122021_1");		
                NgayHieuLuc.focus();
                return false;
            }
            //if (Chon == "optPermit")
            //{
            //    if(data.value > 0) {
            //        GetAlertError(iTotal,DSAlert,"10122021_1");		
            //        document.getElementById('_ctl0_txtWP_IssuedDate').focus();
            //        return false;
            //    }
            //    if(data.value < 0) {
            //        GetAlertError(iTotal,DSAlert,"10122021_1");		
            //        document.getElementById('_ctl0_txtWP_IssuedDate').focus();
            //        return false;
            //    }
            //}
            //if (Chon == "Passport")
            //{
            //    if(data.value > 0) {
            //        GetAlertError(iTotal,DSAlert,"10122021_1");		
            //        document.getElementById('_ctl0_txtPass_IssuedDate').focus();
            //        return false;
            //    }
            //    if(data.value < 0) {
            //        GetAlertError(iTotal,DSAlert,"10122021_1");		
            //        document.getElementById('_ctl0_txtPass_EffDate').focus();
            //        return false;
            //    }
            //}
            //if (Chon == "Visa")
            //{
            //    if(data.value > 0) {
            //        GetAlertError(iTotal,DSAlert,"10122021_1");		
            //        document.getElementById('_ctl0_txtVisa_IssuedDate').focus();
            //        return false;
            //    }
            //    if(data.value < 0) {
            //        GetAlertError(iTotal,DSAlert,"10122021_1");		
            //        document.getElementById('_ctl0_txtVisa_EffDate').focus();
            //        return false;
            //    }
            //}
            //if (Chon == "TempLicence")
            //{
            //    if(data.value > 0) {
            //        GetAlertError(iTotal,DSAlert,"10122021_1");		
            //        document.getElementById('_ctl0_txtTempLic_IssuedDate').focus();
            //        return false;
            //    }
            //    if(data.value < 0) {
            //        GetAlertError(iTotal,DSAlert,"10122021_1");		
            //        document.getElementById('_ctl0_txtTempLic_EffDate').focus();
            //        return false;
            //    }
            //}
        }
        return true;
    }

    function transfer(result) {
        window.document.location.href = result.value.replace("~/", "");
        return false;
    }

    //Start Coding RlogID: 14797 - NhanHM4 - 23/12/2019
    function SetEffByIssued(obj)
    {
        var Chon;
        if (document.getElementById('_ctl0_optPassport').checked)
            Chon = 'Passport'
        if (document.getElementById('_ctl0_optVisa').checked)
            Chon = 'Visa'
        if (document.getElementById('_ctl0_optPermit').checked)
            Chon = 'Permit'
        if (document.getElementById('_ctl0_optTempLicence').checked)
            Chon = 'TempLicence'

        if('<%=MacDinhNgayHieuLucBangNgayCap_MHThongTinVisaPassport%>'=='TRUE'){
            if (Chon == 'Passport'){
                document.getElementById('_ctl0_txtPass_EffDate').value =  document.getElementById('_ctl0_txtPass_IssuedDate').value;
            }
            if (Chon == 'Visa'){
                document.getElementById('_ctl0_txtVisa_EffDate').value =  document.getElementById('_ctl0_txtVisa_IssuedDate').value;
            }
            if (Chon == 'Permit'){
                document.getElementById('_ctl0_txtWP_EffDate').value =  document.getElementById('_ctl0_txtWP_IssuedDate').value;
            }
            if (Chon == 'TempLicence'){
                document.getElementById('_ctl0_txtTempLic_EffDate').value =  document.getElementById('_ctl0_txtTempLic_IssuedDate').value;
            }

            ngayHieuLucCongTuThamSo();

        }
    }
    //End   Coding RlogID: 14797 - NhanHM4 - 23/12/2019
    
    function BindingExpireDate() {
        if (document.getElementById('_ctl0_optPermit').checked && $find("_ctl0_cboLoaiGiayPhepLaoDong") != null) {
            var txtExpireDate = document.getElementById("_ctl0_txtWP_ExpiredDate");
            var txtNgayHieuLuc = document.getElementById("_ctl0_txtWP_EffDate");
            var cboLoaiGiayPhepLaoDong = $find("_ctl0_cboLoaiGiayPhepLaoDong");
            var loaiGiayPhepLDValue  = cboLoaiGiayPhepLaoDong.get_value();
            if(loaiGiayPhepLDValue != null && loaiGiayPhepLDValue != "" && txtNgayHieuLuc.value != "") {
                var month = 0;
                var dataLoaiGiayPhepLaoDong = JSON.parse(dtLoaiGiayPhepLaoDong);
                if(dataLoaiGiayPhepLaoDong && dataLoaiGiayPhepLaoDong.length > 0) {
                    var dt = dataLoaiGiayPhepLaoDong[0]["Table"];
                    if(dt && dt.length > 0) {
                        for(var i = 0; i < dt.length; i++) {
                            if(dt[i]["Ma"] && dt[i]["Ma"] == loaiGiayPhepLDValue) {
                                month = dt[i]["month"] != null ? dt[i]["month"] : 0;
                            }
                        }
                    }
                }
                var newExpireDate = "";
                var strConvertDate = txtNgayHieuLuc.value.split("/");
                var date = new Date(strConvertDate[1]+"/"+strConvertDate[0]+"/"+strConvertDate[2]);

                if(month == "0" || month.length == 0) {
                    txtExpireDate.value = "";
                    return;
                } else {
                    var newDate = date.setDate(date.getDate() - 1);
                    newDate = new Date(newDate);
                    newExpireDate = newDate.setMonth(newDate.getMonth() + parseInt(month));
                }
                
                var strDate = new Date(newExpireDate).toLocaleDateString('en-US');
                var arrDate = strDate.split("/");

                txtExpireDate.value = arrDate[1].padStart(2, "0")+"/"+arrDate[0].padStart(2, "0")+"/"+arrDate[2]
            } else {
                txtExpireDate.value = "";
            }
        }
    }
    <%-- s anhtt189 rlog 20947--%>
    function chuyenDoiNgay(strNgay) {
        var parts = strNgay.split('/');
        if (parts.length === 3) {
            return parts[2] + '/' + parts[1] + '/' + parts[0];
        } else {
            return strNgay;
        }
    }

    LoadNgayNhapCanh();

    function LoadNgayNhapCanh() {
        var prefix = '_ctl0_';
        var txtHNgayNhapCanh = document.getElementById('_ctl0_txtHNgayNhapCanh').value;
        var txtHNgayXuatCanh = document.getElementById('_ctl0_txtHNgayXuatCanh').value;
        var txtHNgayLuuTruVN = document.getElementById('_ctl0_txtHNgayLuuTruVN').value;
        
        var strArrNgayNhapCanh = txtHNgayNhapCanh === '' ? [] : txtHNgayNhapCanh.split('|')
        var strArrNgayXuatCanh = txtHNgayXuatCanh === '' ? [] : txtHNgayXuatCanh.split('|')
        var strArrNgayLuuTruVN = txtHNgayLuuTruVN === '' ? [] : txtHNgayLuuTruVN.split('|')
        var countRow = strArrNgayNhapCanh.length;

        for (var i = 0; i < strArrNgayNhapCanh.length - 1; i++) {
        
            //var countRow = tblNgayNhapCanh.rows.length;
            var row_ = tblNgayNhapCanh.insertRow();
            var nItemID = i + 1;

            var cell0 = row_.insertCell(0);
            var cell1 = row_.insertCell(1);
            var cell0_1 = row_.insertCell(2);
            var cell1_1 = row_.insertCell(3);
            var cell2 = row_.insertCell(4);

            var cell3 = row_.insertCell(5);
            var cell4 = row_.insertCell(6);
            var cell5 = row_.insertCell(7);
            var cell6 = row_.insertCell(8);

            var cell7 = row_.insertCell(9);
            var cell8 = row_.insertCell(10);

            row_.style.backgroundColor = '#ffffcc';

            var dateNhapCanh = parseDate(strArrNgayNhapCanh[i]);

            var dateXuatCanh = parseDate(strArrNgayXuatCanh[i]);

            if (strArrNgayXuatCanh[i] === '') {
                // Nếu ngày xuất cảnh không được nhập, sử dụng ngày nhập cảnh
                dateXuatCanh = dateNhapCanh;
            } else {
                // Nếu có giá trị cho ngày xuất cảnh, chuyển đổi thành đối tượng Date
                dateXuatCanh = parseDate(strArrNgayXuatCanh[i]);
            }

            var diffTime = Math.abs(dateXuatCanh - dateNhapCanh);
            //var diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1;
            var diffDays;
            if (strArrNgayXuatCanh[i] === "") {
                diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
            } else {
                diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1;
            }

            strArrNgayLuuTruVN[i] = diffDays.toString();

            cell0.innerHTML = strArrNgayNhapCanh[i]; // Chuyển đổi ngày nhập cảnh
            cell0.className = "cssColumnTable_Center";
            cell1.innerHTML = strArrNgayXuatCanh[i]; // Chuyển đổi ngày xuất cảnh
            cell1.className = "cssColumnTable_Center";

            cell2.className = strArrNgayLuuTruVN[i];
            cell2.className = "cssColumnTable_Center";

            cell3.className = "cssColumnTable_Center";
            cell4.className = "cssColumnTable_Center";
            cell5.className = "cssColumnTable_Center";
            cell6.className = "cssColumnTable_Center";

            // s Bố sung border cho lưới      
            cell7.style.display = 'none';
            cell8.style.display = 'none';
            // e Bố sung border cho lưới

            cell0.id = "tdNgayNhapCanh0_" + nItemID;
            cell1.id = "tdNgayNhapCanh1_" + nItemID;
            cell0_1.id = "tdNgayNhapCanh0_1_" + nItemID;
            cell1_1.id = "tdNgayNhapCanh1_1_" + nItemID;

            cell2.id = "tdNgayNhapCanh2_" + nItemID;
          
            cell0_1.style.display = 'none';
            cell1_1.style.display = 'none';

            var oNewNode0_1 = document.createElement("input");
            oNewNode0_1.type = "text";
            oNewNode0_1.name = "txtNgayNhapCanh_" + nItemID;
            oNewNode0_1.id = "txtNgayNhapCanh_" + nItemID;
            oNewNode0_1.width = "99%";
            oNewNode0_1.className = "input";
            oNewNode0_1.value = strArrNgayNhapCanh[i];
            oNewNode0_1.style.textAlign = "center";
            cell0_1.appendChild(oNewNode0_1);

            var oNewNode1_1 = document.createElement("input");
            oNewNode1_1.type = "text";
            oNewNode1_1.name = "txtNgayXuatCanh_" + nItemID;
            oNewNode1_1.id = "txtNgayXuatCanh_" + nItemID;
            oNewNode1_1.width = "99%";
            oNewNode1_1.className = "input";
            oNewNode1_1.value = strArrNgayXuatCanh[i];
            oNewNode1_1.style.textAlign = "center";
            cell1_1.appendChild(oNewNode1_1);

            var oNewNode2 = document.createElement("input");
            oNewNode2.type = "text";
            oNewNode2.name = "txtNgayLuuTruVN_" + nItemID;
            oNewNode2.id = "txtNgayLuuTruVN_" + nItemID;
            oNewNode2.width = "99%";
            oNewNode2.className = "input";
            oNewNode2.value = strArrNgayLuuTruVN[i];
            oNewNode2.readOnly = true;
            oNewNode2.style.backgroundColor = "#f0f0f0";
            oNewNode2.style.textAlign = "center";
            cell2.appendChild(oNewNode2);

            //Tao cac textbox tam de chua dua lieu cũ
            var oNewNode0_1_temp = document.createElement("input");
            oNewNode0_1_temp.type = "hidden";
            oNewNode0_1_temp.name = "txtNgayNhapCanh_temp_" + nItemID;
            oNewNode0_1_temp.id = "txtNgayNhapCanh_temp_" + nItemID;
            oNewNode0_1_temp.value = strArrNgayNhapCanh[i];
            cell0_1.appendChild(oNewNode0_1_temp);

            var oNewNode1_1_temp = document.createElement("input");
            oNewNode1_1_temp.type = "hidden";
            oNewNode1_1_temp.name = "txtNgayXuatCanh_temp_" + nItemID;
            oNewNode1_1_temp.id = "txtNgayXuatCanh_temp_" + nItemID;
            oNewNode1_1_temp.value = strArrNgayXuatCanh[i];
            cell1_1.appendChild(oNewNode1_1_temp);

            var oNewNode2temp = document.createElement("input");
            oNewNode2temp.type = "hidden";
            oNewNode2temp.name = "txtNgayLuuTruVN_temp_" + nItemID;
            oNewNode2temp.id = "txtNgayLuuTruVN_temp_" + nItemID;
            oNewNode2temp.value = strArrNgayLuuTruVN[i];
            cell2.appendChild(oNewNode2temp);

            var oNewNode = document.createElement("input");
            oNewNode.type = "button";
            oNewNode.name = "btLanguage_" + nItemID;
            oNewNode.className = "DeleteFile";
            oNewNode.style.cursor = "pointer";
            oNewNode.onclick = new Function("DeleteRow_NgayNhapCanh(" + nItemID + ")");
            cell3.appendChild(oNewNode);
            cell3.style.textAlign = 'center';

            var oNewNode3 = document.createElement("input");
            oNewNode3.type = "button";
            oNewNode3.name = "btEdit_NgayNhapCanh_" + nItemID;
            oNewNode3.id = "btEdit_NgayNhapCanh_" + nItemID;
            oNewNode3.className = "EditFile";
            oNewNode3.style.cursor = "pointer";
            oNewNode3.onclick = new Function("EditRow_NgayNhapCanh(this, " + nItemID + ")");
            cell4.appendChild(oNewNode3);
            cell4.style.textAlign = 'center';

            var oNewNode4 = document.createElement("input");
            oNewNode4.type = "button";
            oNewNode4.name = "btSave_NgayNhapCanh_" + nItemID;
            oNewNode4.id = "btSave_NgayNhapCanh_" + nItemID;
            oNewNode4.className = "SaveFile";
            oNewNode4.style.display = "none";
            oNewNode4.style.cursor = "pointer";
            oNewNode4.onclick = new Function("SaveRow_NgayNhapCanh(this, " + nItemID + ")");
            cell5.appendChild(oNewNode4);
            cell5.style.textAlign = 'center';

            var oNewNode5 = document.createElement("input");
            oNewNode5.type = "button";
            oNewNode5.name = "btCancel_NgayNhapCanh_" + nItemID;
            oNewNode5.id = "btCancel_NgayNhapCanh_" + nItemID;
            oNewNode5.className = "CancelFile";
            oNewNode5.style.display = "none";
            oNewNode5.style.cursor = "pointer";
            oNewNode5.onclick = new Function("CancelRow_NgayNhapCanh(this, " + nItemID + ")");
            cell6.appendChild(oNewNode5);
            cell6.style.textAlign = 'center';
            //Luu du lieu cho hdLanguageID
            document.getElementById(prefix + "hdNgayNhapCanh").value = document.getElementById('_ctl0_txtHNgayNhapCanh').value;
            document.getElementById(prefix + "hdNgayXuatCanh").value = document.getElementById('_ctl0_txtHNgayXuatCanh').value;
        }
    }


    function checkNewArrivalOverlapWithPreviousDateRange(newNgayNhapCanh, newNgayXuatCanh, arrNgayNhapCanh, arrNgayXuatCanh) {
        var newArrivalStart = parseDate(newNgayNhapCanh);
        var newArrivalEnd = parseDate(newNgayXuatCanh);

        for (var i = 0; i < arrNgayNhapCanh.length; i++) {
            var existingStart = parseDate(arrNgayNhapCanh[i]);
            var existingEnd = parseDate(arrNgayXuatCanh[i]);

            // Check if the new date range overlaps with any existing date range
            if ((newArrivalStart <= existingEnd) && (newArrivalEnd >= existingStart)) {
                return true;
            }
        }
        return false;
    }

    function checkNewArrivalBeforeArrivalDates(arrivalDate, arrivalDates, ignoreIndex) {
        var inputDate = parseDate(arrivalDate); // Parse input arrivalDate to Date object

        for (var i = 0; i < arrivalDates.length; i++) {
            if (ignoreIndex !== undefined && ignoreIndex !== null && !isNaN(Number(ignoreIndex)) && ignoreIndex === i) {
                continue;
            }

            var arrival = parseDate(arrivalDates[i]); // Parse arrival date
        
            if (inputDate <= arrival) {
                return true; // Overlap found, return true
            }
        }
        return false; // No overlap found, return false
    }

    function checkIsAlreadyHadEmptyDepartureDate(inputArrivalDateStr, inputDepartureDateStr, arrivalDatesStr, departureDatesStr, ignoreIndex) {
        for (var i = 0; i < arrivalDatesStr.length; i++) {
            if (ignoreIndex !== undefined && ignoreIndex !== null && !isNaN(Number(ignoreIndex)) && ignoreIndex === i) {
                continue;
            }

            if(!isStrNullOrUndifinedOrEmpty(arrivalDatesStr[i]) && isStrNullOrUndifinedOrEmpty(departureDatesStr[i])){
                var inputArrivalDate = parseDate(inputArrivalDateStr);
                var arrivalDate = parseDate(arrivalDatesStr[i]); // Parse arrival date

                if(inputArrivalDate !== arrivalDate && isStrNullOrUndifinedOrEmpty(inputDepartureDateStr)){
                    return true
                }

                var inputDepartureDate = parseDate(inputDepartureDateStr);


                if(inputArrivalDate < arrivalDate){
                    if(!isStrNullOrUndifinedOrEmpty(inputDepartureDateStr) && inputDepartureDate > arrivalDate){
                        return true
                    }

                    // var inputDepartureDate = parseDate(inputDepartureDateStr); // Parse arrival date
                    //// var departureDate = parseDate(departureDatesStr[i]); // Parse arrival date


                    // if(!isStrNullOrUndifinedOrEmpty(arrivalDatesStr[i + 1])){
                    //     var nextArrivalDate = parseDate(arrivalDatesStr[i + 1]); 
                    //     if(inputDepartureDate > nextArrivalDate ){
                    //         return true
                    //     }
                    // }

                    
                    // if(!isStrNullOrUndifinedOrEmpty(arrivalDatesStr[i - 1])){
                    //     var previousArrivalDate = parseDate(arrivalDatesStr[i + 1]);
                    //     if(inputDepartureDate > nextArrivalDate ){
                    //         return true
                    //     }
                    // }
                } else {
                    // if(!isStrNullOrUndifinedOrEmpty(inputDepartureDateStr) && inputDepartureDate < arrivalDate){
                    return true
                    //}
                }
            }
        }

        return false; // No already define empty deperture date found, return false
    }

    function checkDateInExistingRange(date, arrNgayNhapCanh, arrNgayXuatCanh) {
        var checkDate = parseDate(date);

        for (var i = 0; i < arrNgayNhapCanh.length; i++) {
            var startDate = parseDate(arrNgayNhapCanh[i]);
            var endDate = parseDate(arrNgayXuatCanh[i]);

            if (checkDate >= startDate && checkDate <= endDate) {
                return true;
            }
        }
        return false;
    }

    // Function to parse date string in 'dd/mm/yyyy' format to Date object
    function parseDate(dateString) {
        var parts = dateString.split('/');
        var day = parseInt(parts[0], 10);
        var month = parseInt(parts[1], 10) - 1; // Month in JavaScript Date object is 0-indexed
        var year = parseInt(parts[2], 10);
        return new Date(year, month, day);
    }

    function InsertNgayNhapCanh() {
        // kiem tra null
        if (checkisnull('txtVisa_NgayNhapCanh') == false) return false;
        var prefix = '_ctl0_'
        var txtNgayNhapCanh = document.getElementById(prefix + "txtVisa_NgayNhapCanh");
        var txtNgayXuatCanh = document.getElementById(prefix + "txtVisa_NgayXuatCanh");
        var txtNgayLuuTruVN = document.getElementById(prefix + "txtVisa_SoNgayLuuTruVN");

        var hdNgayNhapCanh = document.getElementById(prefix + "hdNgayNhapCanh");
        var hdNgayXuatCanh = document.getElementById(prefix + "hdNgayXuatCanh");
        var hdNgayLuuTruVN = document.getElementById(prefix + "hdNgayLuuTruVN");

        //var strArrNgayNhapCanh = hdNgayNhapCanh.value.split('|').filter(Boolean);
        //var strArrNgayXuatCanh = hdNgayXuatCanh.value.split('|').filter(Boolean);
        //var strArrNgayXuatCanh = hdNgayXuatCanh.value ? hdNgayXuatCanh.value.split('|') : null;
        var strArrNgayNhapCanh = hdNgayNhapCanh.value ? hdNgayNhapCanh.value.split('|') : [];
        var strArrNgayXuatCanh = hdNgayXuatCanh.value ? hdNgayXuatCanh.value.split('|') : [];
        var resultArr = [];
        var xuatCanhIndex = 0; // Biến đếm vị trí trong mảng strArrNgayXuatCanh

        for (var i = 0; i < strArrNgayNhapCanh.length; i++) {
            var trimmedItem = strArrNgayNhapCanh[i].trim(); // Loại bỏ các khoảng trắng không cần thiết
            if (trimmedItem !== '') { // Kiểm tra nếu phần tử không rỗng
                if (strArrNgayXuatCanh[i] !== undefined) { // Kiểm tra xem vị trí có hợp lệ không
                    resultArr.push(strArrNgayXuatCanh[i]);
                }
            }
        }
        var strArrNgayLuuTruVN = hdNgayLuuTruVN.value.split('|');

        var sNgayNhapCanh = txtNgayNhapCanh.value;
        var sNgayXuatCanh = txtNgayXuatCanh.value;

        var sEffDate = document.getElementById("_ctl0_txtPass_EffDate").value;// Ngay hieu luc _ctl0_txtPass_EffDate
        var sExpiredDate = document.getElementById("_ctl0_txtVisa_ExpiredDate").value; //Ngay het han _ctl0_txtVisa_ExpiredDate
        var sVisa_EffDate = document.getElementById("_ctl0_txtVisa_EffDate").value; // Ngay hieu luc _ctl0_txtVisa_EffDate

        // Chuyển đổi các giá trị ngày thành đối tượng Date
        var ngayNhapCanh = parseDate(sNgayNhapCanh);
        var ngayXuatCanh = parseDate(sNgayXuatCanh);
        var effDate = parseDate(sEffDate);
        var ngayhethan = parseDate(sExpiredDate);
        var visaEffDate = parseDate(sVisa_EffDate);

        // Kiểm tra nếu ngày xuất cảnh nhỏ hơn ngày nhập cảnh
        if (ngayXuatCanh < ngayNhapCanh) {          
            GetAlertError(iTotal, DSAlert, "NNC_02");
            document.getElementById("_ctl0_txtVisa_NgayXuatCanh").value = "";
            return false;
        }

        // Kiểm tra nếu ngày nhập cảnh nhỏ hơn ngày hiệu lực
        if (ngayNhapCanh < effDate) {
            GetAlertError(iTotal, DSAlert, "NNC_03");
            document.getElementById("_ctl0_txtVisa_NgayNhapCanh").value = "";
            return false;
        }

        // Kiểm tra nếu ngày nhập cảnh nhỏ hơn ngày hiệu lực
        if (effDate < ngayNhapCanh) {
            GetAlertError(iTotal, DSAlert, "NNC_03");
            document.getElementById("_ctl0_txtVisa_NgayNhapCanh").value = "";
            return false;
        }

        // Kiểm tra nếu ngày nhập cảnh nhỏ hơn ngày hieu luc
        if (ngayNhapCanh < visaEffDate) {
            GetAlertError(iTotal, DSAlert, "NNC_03");
            document.getElementById("_ctl0_txtVisa_NgayNhapCanh").value = "";
            return false;
        }

        // Kiểm tra nếu ngày XUAT cảnh ko dc lớn hơn ngày het han 
        if (ngayXuatCanh > ngayhethan) {
            GetAlertError(iTotal, DSAlert, "NNC_10");
            document.getElementById("_ctl0_txtVisa_NgayXuatCanh").value = "";
            return false;
        }

        //if(checkNewArrivalBeforeArrivalDates(txtNgayNhapCanh.value, strArrNgayNhapCanh)) {
        //    GetAlertError(iTotal, DSAlert, "NNC_09");
        //    return false;
        //}

        if (checkDateInExistingRange(sNgayNhapCanh, strArrNgayNhapCanh, strArrNgayXuatCanh)) {
            GetAlertError(iTotal, DSAlert, "NNC_09");
            return false;
        }


        // Check overlap with existing data ranges
        if (checkNewArrivalOverlapWithPreviousDateRange(sNgayNhapCanh, sNgayXuatCanh, strArrNgayNhapCanh, strArrNgayXuatCanh)) {
            GetAlertError(iTotal, DSAlert, "NNC_09");
            return false;
        }

        var strArrNgayNhapCanh = hdNgayNhapCanh.value.split('|');
        var strArrNgayXuatCanh = hdNgayXuatCanh.value.split('|');

        if(checkIsAlreadyHadEmptyDepartureDate(txtNgayNhapCanh.value, txtNgayXuatCanh.value, strArrNgayNhapCanh, strArrNgayXuatCanh)){
            GetAlertError(iTotal, DSAlert, "NNC_01");
            return false;
        }

        var ngayNhapCanhArrStr = document.getElementById('_ctl0_txtHNgayNhapCanh').value

        var countRow = 0;

        if(ngayNhapCanhArrStr !== '' ) {
            countRow = ngayNhapCanhArrStr.split('|').length;
        }

        //var countRow = tblNgayNhapCanh.rows.length;
        var row_ = tblNgayNhapCanh.insertRow();
        var nItemID = countRow + 1;

        var cell0 = row_.insertCell(0);

        var cell1 = row_.insertCell(1);
        var cell0_1 = row_.insertCell(2);
        var cell1_1 = row_.insertCell(3);
        var cell2 = row_.insertCell(4);

        var cell3 = row_.insertCell(5);
        var cell4 = row_.insertCell(6);
        var cell5 = row_.insertCell(7);
        var cell6 = row_.insertCell(8);

        var cell7 = row_.insertCell(9);
        var cell8 = row_.insertCell(10);

        row_.style.backgroundColor = '#ffffcc';

        cell0.innerHTML = txtNgayNhapCanh.value;
        cell0.className = "cssColumnTable_Center";

        cell1.innerHTML = txtNgayXuatCanh.value;
        cell1.className = "cssColumnTable_Center";


        if (sNgayXuatCanh === "") {
            // Nếu ngày xuất cảnh không được nhập, sử dụng ngày nhập cảnh
            ngayXuatCanh = ngayNhapCanh;
        } else {
            // Nếu có giá trị cho ngày xuất cảnh, chuyển đổi thành đối tượng Date
            ngayXuatCanh = parseDate(sNgayXuatCanh);
        }


        // Tính toán số ngày lưu trú dựa trên ngày xuất cảnh và ngày nhập cảnh
        var diffTime = Math.abs(ngayXuatCanh - ngayNhapCanh);
        // var diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1;
        if (sNgayXuatCanh === "") {
            diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        } else {
            diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1;
        }

        // Cập nhật giá trị cho cột cell2
        cell2.className = diffDays.toString();

        //cell2.className = txtNgayXuatCanh.value;
        cell2.className = "cssColumnTable_Center";

        cell3.className = "cssColumnTable_Center";
        cell4.className = "cssColumnTable_Center";
        cell5.className = "cssColumnTable_Center";
        cell6.style.display = "cssColumnTable_Center";

        // s Bố sung border cho lưới      
        cell7.style.display = 'none';
        cell8.style.display = 'none';
        // e Bố sung border cho lưới

        cell0.id = "tdNgayNhapCanh0_" + nItemID;
        cell1.id = "tdNgayNhapCanh1_" + nItemID;
        cell0_1.id = "tdNgayNhapCanh0_1_" + nItemID;
        cell1_1.id = "tdNgayNhapCanh1_1_" + nItemID;

        cell2.id = "tdNgayNhapCanh2_" + nItemID;
        cell6.id = "tdNgayNhapCanh6_" + nItemID;

        cell0_1.style.display = 'none';
        cell1_1.style.display = 'none';
        // cell2.style.display   = 'none';

        var oNewNode0_1 = document.createElement("input");
        oNewNode0_1.type = "text";
        oNewNode0_1.name = "txtNgayNhapCanh_" + nItemID;
        oNewNode0_1.id = "txtNgayNhapCanh_" + nItemID;
        oNewNode0_1.width = "99%";
        oNewNode0_1.className = "input";
        oNewNode0_1.value = txtNgayNhapCanh.value;
        oNewNode0_1.style.textAlign = "center";
        cell0_1.appendChild(oNewNode0_1);

        var oNewNode1_1 = document.createElement("input");
        oNewNode1_1.type = "text";
        oNewNode1_1.name = "txtNgayXuatCanh_" + nItemID;
        oNewNode1_1.id = "txtNgayXuatCanh_" + nItemID;
        oNewNode1_1.width = "99%";
        oNewNode1_1.className = "input";
        oNewNode1_1.value = txtNgayXuatCanh.value;
        oNewNode1_1.style.textAlign = "center";
        cell1_1.appendChild(oNewNode1_1);

        var oNewNode2 = document.createElement("input");
        oNewNode2.type = "text";
        oNewNode2.name = "txtNgayLuuTruVN_" + nItemID;
        oNewNode2.id = "txtNgayLuuTruVN_" + nItemID;
        oNewNode2.width = "99%";
        oNewNode2.className = "input";
        oNewNode2.value = diffDays.toString();
        oNewNode2.readOnly = true;
        oNewNode2.style.backgroundColor = "#f0f0f0";
        oNewNode2.style.textAlign = "center";
        cell2.appendChild(oNewNode2);

        //Tao cac textbox tam de chua dua lieu cũ
        var oNewNode0_1_temp = document.createElement("input");
        oNewNode0_1_temp.type = "hidden";
        oNewNode0_1_temp.name = "txtNgayNhapCanh_temp_" + nItemID;
        oNewNode0_1_temp.id = "txtNgayNhapCanh_temp_" + nItemID;
        oNewNode0_1_temp.value = txtNgayNhapCanh.value;
        cell0_1.appendChild(oNewNode0_1_temp);

        var oNewNode1_1_temp = document.createElement("input");
        oNewNode1_1_temp.type = "hidden";
        oNewNode1_1_temp.name = "txtNgayXuatCanh_temp_" + nItemID;
        oNewNode1_1_temp.id = "txtNgayXuatCanh_temp_" + nItemID;
        oNewNode1_1_temp.value = txtNgayXuatCanh.value;
        cell1_1.appendChild(oNewNode1_1_temp);

        var oNewNode2temp = document.createElement("input");
        oNewNode2temp.type = "hidden";
        oNewNode2temp.name = "txtNgayLuuTruVN_temp_" + nItemID;
        oNewNode2temp.id = "txtNgayLuuTruVN_temp_" + nItemID;
        oNewNode2temp.value = diffDays.toString();
        cell2.appendChild(oNewNode2temp);

        var oNewNode = document.createElement("input");
        oNewNode.type = "button";
        oNewNode.name = "btLanguage_" + nItemID;
        oNewNode.className = "DeleteFile";
        oNewNode.style.cursor = "pointer";
        oNewNode.onclick = new Function("DeleteRow_NgayNhapCanh(" + nItemID + ")");

        cell3.appendChild(oNewNode);
        cell3.style.textAlign = 'center';

        var oNewNode3 = document.createElement("input");
        oNewNode3.type = "button";
        oNewNode3.name = "btEdit_NgayNhapCanh_" + nItemID;
        oNewNode3.id = "btEdit_NgayNhapCanh_" + nItemID;
        oNewNode3.className = "EditFile";
        oNewNode3.style.cursor = "pointer";
        oNewNode3.onclick = new Function("EditRow_NgayNhapCanh(this, " + nItemID + ")");
        cell4.appendChild(oNewNode3);
        cell4.style.textAlign = 'center';

        var oNewNode4 = document.createElement("input");
        oNewNode4.type = "button";
        oNewNode4.name = "btSave_NgayNhapCanh_" + nItemID;
        oNewNode4.id = "btSave_NgayNhapCanh_" + nItemID;
        oNewNode4.className = "SaveFile";
        oNewNode4.style.display = "none";
        oNewNode4.style.cursor = "pointer";
        oNewNode4.onclick = new Function("SaveRow_NgayNhapCanh(this, " + nItemID + ")");
        cell5.appendChild(oNewNode4);
        cell5.style.textAlign = 'center';

        var oNewNode5 = document.createElement("input");
        oNewNode5.type = "button";
        oNewNode5.name = "btCancel_NgayNhapCanh_" + nItemID;
        oNewNode5.id = "btCancel_NgayNhapCanh_" + nItemID;
        oNewNode5.className = "CancelFile";
        oNewNode5.style.display = "none";
        oNewNode5.style.cursor = "pointer";
        oNewNode5.onclick = new Function("CancelRow_NgayNhapCanh(this, " + nItemID + ")");
        cell6.appendChild(oNewNode5);
        cell6.style.textAlign = 'center';
        
        var ngayXuatCanhVal = isStrNullOrUndifinedOrEmpty(txtNgayXuatCanh.value) ? null : txtNgayXuatCanh.value
        var ngayNhapCanhVal = isStrNullOrUndifinedOrEmpty(txtNgayNhapCanh.value) ? null : txtNgayNhapCanh.value
        var ngayLuuTruVNVal = isStrNullOrUndifinedOrEmpty(txtNgayLuuTruVN.value) ? null : txtNgayLuuTruVN.value

        hdNgayNhapCanh.value += hdNgayNhapCanh && hdNgayNhapCanh.value === '' ?  ngayNhapCanhVal : '|' + ngayNhapCanhVal;
        hdNgayXuatCanh.value += hdNgayXuatCanh && hdNgayXuatCanh.value === '' ?  ngayXuatCanhVal : '|' + ngayXuatCanhVal;
        //hdNgayLuuTruVN.value += hdNgayLuuTruVN && hdNgayLuuTruVN.value === '' ? txtNgayLuuTruVN.value : '|' + txtNgayLuuTruVN.value;
        hdNgayLuuTruVN.value += hdNgayLuuTruVN && hdNgayLuuTruVN.value === '' ? ngayLuuTruVNVal : '|' + ngayLuuTruVNVal;

        document.getElementById('_ctl0_txtHNgayNhapCanh').value = hdNgayNhapCanh.value;
        document.getElementById('_ctl0_txtHNgayXuatCanh').value = hdNgayXuatCanh.value;
        document.getElementById('_ctl0_txtHNgayLuuTruVN').value = hdNgayLuuTruVN.value;
    }

    function DeleteRow_NgayNhapCanh(pID) {
        if (confirm(GetAlertText(iTotal, DSAlert, "0002"))) {
            removedata_NgayNhapCanh(pID);
            for (i = pID; i < tblNgayNhapCanh.rows.length - 1; i++) {
                tblNgayNhapCanh.rows[i].cells[0].innerHTML = tblNgayNhapCanh.rows[i + 1].cells[0].innerHTML;
                tblNgayNhapCanh.rows[i].cells[1].innerHTML = tblNgayNhapCanh.rows[i + 1].cells[1].innerHTML;
            }
            tblNgayNhapCanh.deleteRow(tblNgayNhapCanh.rows.length - 1);
            return true;
        }
        else return false;
    }

    function EditRow_NgayNhapCanh(obj, pID) {
        obj.style.display = 'none';
        document.getElementById(obj.id.replace('btEdit', 'btSave')).style.display = '';
        document.getElementById(obj.id.replace('btEdit', 'btCancel')).style.display = '';

        var txtNgayNhapCanh = document.getElementById('txtNgayNhapCanh_' + pID);
        var txtNgayXuatCanh = document.getElementById(obj.id.replace('btEdit_NgayXuatCanh', 'txtNgayXuatCanh'));
        var txtNgayLuuTruVN = document.getElementById(obj.id.replace('btEdit_NgayNhapCanh', 'txtNgayLuuTruVN'));

        var txtNgayNhapCanh_temp = document.getElementById(obj.id.replace('btEdit_NgayNhapCanh', 'txtNgayNhapCanh_temp'));
        var txtNgayXuatCanh_temp = document.getElementById(obj.id.replace('btEdit_NgayNhapCanh', 'txtNgayXuatCanh_temp'));
        var txtNgayLuuTruVN_temp = document.getElementById(obj.id.replace('btEdit_NgayNhapCanh', 'txtNgayLuuTruVN_temp'));

        var cell0 = document.getElementById(obj.id.replace('btEdit_NgayNhapCanh', 'tdNgayNhapCanh0'));
        var cell1 = document.getElementById(obj.id.replace('btEdit_NgayNhapCanh', 'tdNgayNhapCanh1'));
        var cell0_1 = document.getElementById(obj.id.replace('btEdit_NgayNhapCanh', 'tdNgayNhapCanh0_1'));
        var cell1_1 = document.getElementById(obj.id.replace('btEdit_NgayNhapCanh', 'tdNgayNhapCanh1_1'));
        var cell2 = document.getElementById(obj.id.replace('btEdit_NgayNhapCanh', 'tdNgayNhapCanh2_'));
        var cell6 = document.getElementById(obj.id.replace('btEdit_NgayNhapCanh', 'tdNgayNhapCanh6_'));

        cell0.style.display = 'none';
        cell1.style.display = 'none';
        cell0_1.style.display = '';
        cell1_1.style.display = '';

    }

    function SaveRow_NgayNhapCanh(obj, pID) {
        var currentArrIndex = pID - 1;
        var hdNgayNhapCanhEle = document.getElementById('_ctl0_hdNgayNhapCanh');
        var hdNgayXuatCanhEle = document.getElementById('_ctl0_hdNgayXuatCanh');
        var hdNgayLuuTruVNEle = document.getElementById('_ctl0_hdNgayLuuTruVN');

        var hdNgayNhapCanh = hdNgayNhapCanhEle.value;
        var hdNgayXuatCanh = hdNgayXuatCanhEle.value;
        var hdNgayLuuTruVN = hdNgayLuuTruVNEle.value;

        var strArrNgayNhapCanh = hdNgayNhapCanh === '' ? [] : hdNgayNhapCanh.split('|');
        var strArrNgayXuatCanh = hdNgayXuatCanh === '' ? [] : hdNgayXuatCanh.split('|');
        var strArrNgayLuuTruVN = hdNgayLuuTruVN === '' ? [] : hdNgayLuuTruVN.split('|');

        var txtNgayNhapCanh = document.getElementById('txtNgayNhapCanh_' + pID);
        var txtNgayXuatCanh = document.getElementById('txtNgayXuatCanh_' + pID);

        var NgayNhapCanh = txtNgayNhapCanh.value;
        var NgayXuatCanh = txtNgayXuatCanh.value;

        if (!CheckDate(txtNgayNhapCanh) || !CheckDate(txtNgayXuatCanh)){
            return;
        }

        if (!NgayNhapCanh || NgayNhapCanh.trim() === "") {
            GetAlertError(iTotal, DSAlert, "0003");
            //txtNgayNhapCanh.focus();
            return; // ngay xuat canh null o luoi
        }
    
        var dateFormat = /^\d{2}\/\d{2}\/\d{4}$/;
        if (!NgayNhapCanh.match(dateFormat)) {
            GetAlertError(iTotal, DSAlert, "NNC_06");
            return; // Dừng hàm nếu có lỗi
        }
   
        if (NgayXuatCanh && NgayXuatCanh.trim() !== "") {
            if (!NgayXuatCanh.match(dateFormat)) {
                GetAlertError(iTotal, DSAlert, "NNC_06");
                return; // Dừng hàm nếu có lỗi
            }
        }

        // Kiểm tra nếu ngày xuất cảnh nhỏ hơn ngày nhập cảnh
        if (parseDate(NgayXuatCanh) < parseDate(NgayNhapCanh)) {          
            GetAlertError(iTotal, DSAlert, "NNC_02");
            document.getElementById("_ctl0_txtVisa_NgayXuatCanh").value = "";
            return false;
        }

        var sExpiredDate = document.getElementById("_ctl0_txtVisa_ExpiredDate").value; //Ngay het han _ctl0_txtVisa_ExpiredDate

        if (parseDate(NgayXuatCanh) > parseDate(sExpiredDate)) {          
            GetAlertError(iTotal, DSAlert, "NNC_10");
            return false;
        }

        var sVisa_EffDate = document.getElementById("_ctl0_txtVisa_EffDate").value; // Ngay hieu luc _ctl0_txtVisa_EffDate

        if (parseDate(NgayNhapCanh) < parseDate(sVisa_EffDate)) {
            GetAlertError(iTotal, DSAlert, "NNC_03");
            return false;
        }


        // Function to check overlap while excluding the current row being edited
        function checkOverlapExcludingCurrent(newArrival, newDeparture, arrivalDates, departureDates, currentIndex) {
            var newArrivalDate = parseDate(newArrival);
            var newDepartureDate = parseDate(newDeparture);

            for (var i = 0; i < arrivalDates.length; i++) {
                if (i === currentIndex) continue; // Skip the current row being edited
                if (isStrNullOrUndifinedOrEmpty(departureDates[i])) continue;

                var arrivalDate = parseDate(arrivalDates[i]);
                var departureDate = parseDate(departureDates[i]);

                // Check if there is any overlap
                if ((newArrivalDate >= arrivalDate && newArrivalDate <= departureDate) ||
                    (newDepartureDate >= arrivalDate && newDepartureDate <= departureDate) ||
                    (newArrivalDate <= arrivalDate && newDepartureDate >= departureDate)) {
                    return true; // Overlap found
                }
            }
            return false; // No overlap found
        }

        if (checkOverlapExcludingCurrent(NgayNhapCanh, NgayXuatCanh, strArrNgayNhapCanh, strArrNgayXuatCanh, currentArrIndex)) {
            GetAlertError(iTotal, DSAlert, "NNC_09");
            return false;
        }

        if (checkIsAlreadyHadEmptyDepartureDate(NgayNhapCanh, NgayXuatCanh, strArrNgayNhapCanh, strArrNgayXuatCanh, currentArrIndex)) {
            GetAlertError(iTotal, DSAlert, "NNC_01");
            return false;
        }

        obj.style.display = 'none';
        document.getElementById(obj.id.replace('btSave', 'btEdit')).style.display = '';
        document.getElementById(obj.id.replace('btSave', 'btCancel')).style.display = 'none';

        var strNgayNhapCanh = "";
        var strNgayXuatCanh = "";     
    
        var cell0 = document.getElementById(obj.id.replace('btSave_NgayNhapCanh', 'tdNgayNhapCanh0'));
        var cell1 = document.getElementById(obj.id.replace('btSave_NgayNhapCanh', 'tdNgayNhapCanh1'));
        var cell0_1 = document.getElementById(obj.id.replace('btSave_NgayNhapCanh', 'tdNgayNhapCanh0_1'));
        var cell1_1 = document.getElementById(obj.id.replace('btSave_NgayNhapCanh', 'tdNgayNhapCanh1_1'));

        cell0.innerHTML = NgayNhapCanh;
        cell1.innerHTML = NgayXuatCanh;
        cell0.style.display = '';
        cell1.style.display = '';

        cell0.style.verticalAlign = "middle";
        cell1.style.verticalAlign = "middle";

        cell0_1.style.display = 'none';
        cell1_1.style.display = 'none';

        if (strArrNgayNhapCanh.length > 0) {
            strArrNgayNhapCanh[currentArrIndex] = NgayNhapCanh;
            hdNgayNhapCanhEle.value = strArrNgayNhapCanh.join('|');
        }

        if (strArrNgayXuatCanh.length > 0) {
            strArrNgayXuatCanh[currentArrIndex] = NgayXuatCanh;
            hdNgayXuatCanhEle.value = strArrNgayXuatCanh.join('|');
        }

        var diffTime;
        if (!NgayXuatCanh || NgayXuatCanh.trim() === "") {
            diffTime = Math.abs(parseDate(NgayNhapCanh) - parseDate(NgayNhapCanh));
        } else {
            diffTime = Math.abs(parseDate(NgayNhapCanh) - parseDate(NgayXuatCanh));
        }

        var diffDays;
        if (NgayXuatCanh === "") {
            diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        } else {
            diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1;
        }
        document.getElementById('txtNgayLuuTruVN_'+ pID).value = diffDays;
    }

    function CancelRow_NgayNhapCanh(obj, pID) {
        obj.style.display = 'none';
        document.getElementById(obj.id.replace('btCancel', 'btEdit')).style.display = '';
        document.getElementById(obj.id.replace('btCancel', 'btSave')).style.display = 'none';

        var cell0 = document.getElementById(obj.id.replace('btCancel_NgayNhapCanh', 'tdNgayNhapCanh0'));
        var cell1 = document.getElementById(obj.id.replace('btCancel_NgayNhapCanh', 'tdNgayNhapCanh1'));
        var cell0_1 = document.getElementById(obj.id.replace('btCancel_NgayNhapCanh', 'tdNgayNhapCanh0_1'));
        var cell1_1 = document.getElementById(obj.id.replace('btCancel_NgayNhapCanh', 'tdNgayNhapCanh1_1'));

        cell0.style.display = '';
        cell1.style.display = '';
        cell0_1.style.display = 'none';
        cell1_1.style.display = 'none';
    }

    function removedata_NgayNhapCanh(pID) {
        var prefix = '_ctl0_';
        var hdNgayNhapCanh = document.getElementById(prefix + "hdNgayNhapCanh");
        var hdNgayXuatCanh = document.getElementById(prefix + "hdNgayXuatCanh");

        var arr_NgayNhapCanh = document.getElementById(prefix + "hdNgayNhapCanh").value.split('|');
        var arr_NgayXuatCanh = document.getElementById(prefix + "hdNgayXuatCanh").value.split('|');

        var arr_txtNgayNhapCanh = document.getElementById('_ctl0_txtHNgayNhapCanh').value.split("|");
        var arr_txtNgayXuatCanh = document.getElementById('_ctl0_txtHNgayXuatCanh').value.split("|");

        hdNgayNhapCanh.value = "";
        hdNgayXuatCanh.value = "";

        document.getElementById('_ctl0_txtHNgayNhapCanh').value = "";
        document.getElementById('_ctl0_txtHNgayXuatCanh').value = "";

        for (i = 0; i < arr_NgayNhapCanh.length - 1; i++) {
            if (i != pID - 1) {
                hdNgayNhapCanh.value += arr_NgayNhapCanh[i] + "|";
                hdNgayXuatCanh.value += arr_NgayXuatCanh[i] + "|";

                document.getElementById('_ctl0_txtHNgayNhapCanh').value += arr_txtNgayNhapCanh[i] + "|";
                document.getElementById('_ctl0_txtHNgayXuatCanh').value += arr_txtNgayXuatCanh[i] + "|";
            }
        }
    }
    <%-- e anhtt189 rlog 20947--%>
    //Rlog 21049
    function ngayHieuLucCongTuThamSo(){
        if('<%=TuDongTinVaHienThiNgayHetHieuLucGPLD%>' == 'TRUE') {
            var NgayHieuLuc = document.getElementById('_ctl0_txtWP_EffDate').value;
            var SoNamHieuLuc = "<%=ThoiHanHieuLuc%>";
            if(NgayHieuLuc != ""){
                document.getElementById('_ctl0_txtWP_ExpiredDate').value=addYearsToDate(NgayHieuLuc,SoNamHieuLuc);
            }
        }
    }
    function isLeapYear(year) {
        return (year % 4 === 0 && year % 100 !== 0) || (year % 400 === 0);
    }

    // Hàm cộng ngày với số năm (bao gồm năm nhuận)
    function addYearsToDate(inputDate, yearsToAdd) {
        // Tách ngày, tháng, năm từ định dạng dd/MM/yyyy
        const parts = inputDate.split('/');
        const day = parseInt(parts[0], 10);
        const month = parseInt(parts[1], 10);
        const year = parseInt(parts[2], 10);

        // Thêm số năm nguyên vào năm hiện tại
        const fullYearsToAdd = Math.floor(yearsToAdd);
        const decimalYearsToAdd = yearsToAdd - fullYearsToAdd;

        let newYear = year + fullYearsToAdd;

        // Thêm số năm nguyên vào ngày tháng
        const currentDate = new Date(newYear, month - 1, day);

        // Xử lý số năm thập phân (phần thập phân của yearsToAdd)
        const daysInDecimalYear = Math.floor(365 * decimalYearsToAdd);
        currentDate.setDate(currentDate.getDate() + daysInDecimalYear);

        // Kiểm tra xem năm ban đầu có phải là năm nhuận hay không
        const isInitialYearLeap = isLeapYear(year);

        // Kiểm tra xem năm mới sau khi cộng có phải là năm nhuận hay không
        const isNewYearLeap = isLeapYear(newYear);

        // Nếu năm ban đầu là năm nhuận và năm mới không phải là năm nhuận,
        // và tháng là tháng 2 và ngày là 29 (ngày của năm nhuận), thì chuyển thành 28
        if (isInitialYearLeap && !isNewYearLeap && month === 2 && day === 29) {
            currentDate.setDate(28);
        }

        // Lấy ngày, tháng, năm mới sau khi thêm số năm
        const newDay = currentDate.getDate();
        let newMonth = currentDate.getMonth() + 1; // Tháng trong Date được đếm từ 0
        newYear = currentDate.getFullYear();

        // Thêm một ngày vào currentDate
        currentDate.setDate(currentDate.getDate() + 1);

        // Lấy ngày, tháng, năm mới sau khi thêm một ngày
        const newDayAfterIncrement = currentDate.getDate();
        let newMonthAfterIncrement = currentDate.getMonth() + 1;
        const newYearAfterIncrement = currentDate.getFullYear();

        // Format lại ngày để đảm bảo luôn là hai chữ số (thêm '0' nếu cần)
        const formattedDay = newDayAfterIncrement < 10 ? `0${newDayAfterIncrement}` : `${newDayAfterIncrement}`;
        // Format lại tháng để đảm bảo luôn là hai chữ số (thêm '0' nếu cần)
        newMonthAfterIncrement = newMonthAfterIncrement < 10 ? `0${newMonthAfterIncrement}` : `${newMonthAfterIncrement}`;

        // Format lại thành chuỗi dd/MM/yyyy
        const newDate = `${formattedDay}/${newMonthAfterIncrement}/${newYearAfterIncrement}`;

        return newDate;
    }
    //Rlog 21049
</script>

