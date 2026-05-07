<%@ Control Language="c#" AutoEventWireup="True" CodeBehind="DSThongTinVisaPassport.ascx.cs"
    Inherits="iHRPCore.MdlHR.DSThongTinVisaPassport" TargetSchema="http://schemas.microsoft.com/intellisense/ie5" %>
<%@ Register TagPrefix="uc1" TagName="EmpHeaderSearch" Src="../../Common/Form/EmpHeaderSearch.ascx" %>
<%@ Register TagPrefix="telerik" Namespace="Telerik.Web.UI" Assembly="Telerik.Web.UI" %>
<%@ Register Assembly="Common" Namespace="iHRPCore.Com" TagPrefix="core" %>
<%@ Register TagPrefix="uc" TagName="MultiAttachButton" Src="../../Common/Form/MultiAttachButton.ascx" %>

<div class="contentForm">
    <div class="contentGroup">
        <asp:Label ID="lblErr" runat="server" CssClass="lblErr"></asp:Label>
    </div>
    <div class="contentGroup">
        <uc1:empheadersearch id="EmpHeaderSearch1" runat="server"></uc1:empheadersearch>
    </div>
    <div class="contentGroup">
        <div class="contentFormItem full onlyItem">
            <div class="contentFormLabel">
            </div>
            <div class="contentFormControl">
                <div id="divGiayPhepLD" runat="server" style="float: left;" class="Radio150">
                    <asp:RadioButton ID="optPermit" runat="server" AutoPostBack="true" Text="W.Permit" GroupName="optTypeGroup" Checked="true"
                        OnCheckedChanged="optType_SelectedIndexChanged" Font-Bold="True" />
                </div>
                <div id="divPassport" runat="server" style="float: left;" class="Radio150">
                    <asp:RadioButton ID="optPassport" runat="server" AutoPostBack="true" Text="Passport" GroupName="optTypeGroup"
                        OnCheckedChanged="optType_SelectedIndexChanged" Font-Bold="True" />
                </div>
                <div id="divVisa" runat="server" style="float: left;" class="Radio150">
                    <asp:RadioButton ID="optVisa" runat="server" AutoPostBack="true" Text="Visa" GroupName="optTypeGroup"
                        OnCheckedChanged="optType_SelectedIndexChanged" Font-Bold="True" />
                </div>
                <div id="divGiayTamTru" runat="server" style="float: left;" class="Radio150">
                    <asp:RadioButton ID="optTempLicence" runat="server" AutoPostBack="true" Text="Temp.Licence" GroupName="optTypeGroup"
                        OnCheckedChanged="optType_SelectedIndexChanged" Font-Bold="True" />
                </div>
                <div id="divHDThueNha" runat="server" style="float: left;" class="Radio150">
                    <asp:RadioButton ID="optHDThueNha" runat="server" AutoPostBack="true" Text="Hợp đồng Thuê nhà" GroupName="optTypeGroup"
                        OnCheckedChanged="optType_SelectedIndexChanged" Font-Bold="True" />
                </div>
                <%--RLOG 19677--%>
                <div id="divLyLichTuPhap" runat="server" style="float: left; display: none; pause: T" class="Radio150">
                    <asp:RadioButton ID="optLyLichTuPhap" runat="server" AutoPostBack="true" Text="Lý lịch tư pháp" GroupName="optTypeGroup"
                        OnCheckedChanged="optType_SelectedIndexChanged" Font-Bold="True" />
                </div>
                <%--END RLOG 19677--%>
            </div>
        </div>
    </div>

    <div class="contentGroupTitleHolder">
        <div class="contentGroupIcon"></div>
        <div class="contentGroupTitle">
            <div id="trGPLD">
                <asp:Label ID="lblTitle" runat="server" CssClass="label">Giấy phép lao động</asp:Label>
            </div>
            <div id="trPP">
                <asp:Label ID="Label1" runat="server" CssClass="label">Passport</asp:Label>
            </div>
            <div id="trVS">
                <asp:Label ID="Label3" runat="server" CssClass="label">Visa</asp:Label>
            </div>
            <div id="trGTT">
                <asp:Label ID="Label4" runat="server" CssClass="label">Giấy tạm trú</asp:Label>
            </div>
            <div id="trHDTN">
                <asp:Label ID="Label5" runat="server" CssClass="label">Hợp đồng thuê nhà</asp:Label>
            </div>
             <div id="trLLTP">
                <asp:Label ID="Label6" runat="server" CssClass="label">Lý lịch tư pháp</asp:Label>
            </div>
        </div>
    </div>


    <div class="contentGroup">
        <div class="contentFormItem full" style="display: none">
            <input id="txtID" style="width: 9px; height: 22px" type="hidden" size="10" name="txtID" runat="server">
            <input id="txtStatus" style="width: 9px; height: 22px" type="hidden" size="10" name="txtStatus" runat="server">
        </div>

        <div class="contentFormItem half">
            <div class="contentFormLabel">
                <asp:Label ID="lblNumber" runat="server" CssClass="label">Số</asp:Label>
            </div>
            <div class="contentFormControl">
                <asp:TextBox ID="txtNumber" runat="server" CssClass="input" Width="150px" MaxLength="30"></asp:TextBox>
            </div>
        </div>

        <div class="contentFormItem half">
            <div class="contentFormLabel">
                <asp:Label ID="lblFromDate" runat="server" CssClass="">Từ ngày cấp</asp:Label>
            </div>
            <div class="contentFormControl">
                <asp:TextBox ID="txtFromDate" onblur="JavaScript:CheckDate(this)" runat="server"
                    CssClass="InputCenter fpt-datetime-custom" Width="70px" MaxLength="10"></asp:TextBox>
                <input class="datePicker" onclick="javascript:popUpCalendar(<%=this.txtFromDate.ClientID%>);" type="button">
                <asp:Label ID="lblToDate" runat="server" CssClass="label" Style="height: 18px; float: left; padding: 4px 10px 0 10px">Đến ngày cấp</asp:Label>
                <asp:TextBox ID="txtToDate" onblur="JavaScript:CheckDate(this)" runat="server"
                    CssClass="InputCenter fpt-datetime-custom" Width="70px" MaxLength="10"></asp:TextBox>
                <input class="datePicker" onclick="javascript:popUpCalendar(<%=this.txtToDate.ClientID%>);" type="button">
            </div>
        </div>
        <%--Start Coding RlogID: 15988 - APOLLO - Bomnv - 08/02/2021--%>
        <div id="divLoaiVisa"  class="contentFormItem half">
            <div  class="contentFormLabel" >
                <asp:Label ID="lblLoaiVisa" runat="server" CssClass="label"  style="display:none;pause: T" >Loại Visa</asp:Label>
            </div>
            <div class="contentFormControl">
                <telerik:RadComboBox ID="cboLoaiVisaID" runat="server" style="display:none;pause: T" Skin="Simple" Width="100%" Filter="Contains" AllowCustomText="true" />
            </div>
        </div>
        <%--End   Coding RlogID: 15988 - APOLLO - Bomnv - 08/02/2021--%>
        <div class="contentFormItem half" id="divTinhTrang">
            <div class="contentFormLabel">
                <asp:Label ID="lblStatus" runat="server" CssClass="label">Status</asp:Label>
            </div>
            <div class="contentFormControl">
                <telerik:RadComboBox ID="cboStatus" runat="server" Skin="Simple" Width="100%" Filter="Contains" AllowCustomText="true">
                </telerik:RadComboBox>
            </div>
        </div>
        <%--RlogID 25189 - KPMG_V34--%>
        <div id="divJobPositionForWorkPermit" class="contentFormItem half" style="display:none;">
            <div id="divJobPositionForWorkPermit_lbl" runat="server" class="contentFormLabel" style="display:none;pause: T">
                <asp:Label ID="lblJobPositionForWorkPermit" runat="server" CssClass="label">Vị trí công việc GPLĐ</asp:Label>
            </div>
            <div id="divJobPositionForWorkPermit_ctl" runat="server" class="contentFormControl" style="display:none;pause: T">
                <telerik:RadComboBox ID="cboJobPositionForWorkPermit" runat="server" Skin="Simple" Width="100%" Filter="Contains" AllowCustomText="true" />
            </div>
        </div>
         <%--END RlogID 25189 - KPMG_V34--%>

        <%--RlogID 25190 - KPMG_V34--%>
        <div id="divQuocGiaPP" class="contentFormItem half" style="display:none;">
            <div id="divQuocGiaPP_lbl" runat="server" class="contentFormLabel" style="display:none;pause: T">
                <asp:Label ID="lblQuocGiaPP" runat="server" CssClass="label">Quốc gia Passport</asp:Label>
            </div>
            <div id="divQuocGiaPP_ctl" runat="server" class="contentFormControl" style="display:none;pause: T">
                <telerik:RadComboBox ID="cboQuocGiaPP" runat="server" Skin="Simple" Width="100%" Filter="Contains" AllowCustomText="true" />
            </div>
        </div>

        <div id="divQuocGiaVisa" class="contentFormItem half" style="display:none;">
            <div id="divQuocGiaVisa_lbl" runat="server" class="contentFormLabel" style="display:none;pause: T">
                <asp:Label ID="lblQuocGiaVisa" runat="server" CssClass="label">Quốc gia Visa</asp:Label>
            </div>
            <div id="divQuocGiaVisa_ctl" runat="server" class="contentFormControl" style="display:none;pause: T">
                <telerik:RadComboBox ID="cboQuocGiaVisa" runat="server" Skin="Simple" Width="100%" Filter="Contains" AllowCustomText="true" />
            </div>
        </div>
         <%--END RlogID 25190 - KPMG_V34--%>

        <div class="contentFormItem half" id="trPassportType">
            <div class="contentFormLabel">
                <asp:Label ID="Label2" runat="server" CssClass="label">Passport type</asp:Label>
            </div>
            <div class="contentFormControl">
                <telerik:RadComboBox ID="cboPass_Type" runat="server" Skin="Simple" Width="100%"
                    Filter="Contains" MarkFirstMatch="true" />
            </div>
        </div>
    </div>
    <div class="contentGroup">
        <div class="contentFormItem full">
            <hr />
        </div>
        <div class="contentFormItem full">
            <table>
                <tr>
                    <td align="center">
                        <span class="btn1">
                            <asp:LinkButton ID="btnSearch" name="btnSearch" AccessKey="F" ToolTip="ALT+F" runat="server"
                                OnClientClick="return CheckSearch();" OnClick="btnSearch_Click">
                        <span class="btnSearch">Tìm kiếm</span>
                            </asp:LinkButton>
                        </span><span class="btn1">
                            <asp:LinkButton ID="btnDelete" name="btnDelete" AccessKey="F" ToolTip="ALT+F" runat="server"
                                OnClick="btnDelete_Click" OnClientClick="return CheckDelete();">
                        <span class="btnDelete">Xóa</span>
                            </asp:LinkButton>
                        </span><span class="btn1">
                            <asp:LinkButton ID="btnExport" name="btnExport" AccessKey="E" ToolTip="ALT+E" runat="server"
                                OnClick="btnExport_Click">
                        <span class="btnExport">Xuất DL</span>
                            </asp:LinkButton>
                        </span><span class="btn1">
                            <asp:LinkButton ID="btnImport" name="btnImport" AccessKey="I" ToolTip="ALT+I" runat="server">
                        <span class="btnImport">Nhập DL</span>
                            </asp:LinkButton>
                        </span>
                    </td>
                </tr>
            </table>
        </div>
        <div class="gridHolder" id="trdtgListGiayPhepLaoDong">
            <telerik:RadSplitter ID="RadSplitter2" Width="100%" runat="server" Orientation="Horizontal"
                Height="100%">
                <telerik:RadPane ID="RadPane1" Height="500px" Width="100%" runat="server" Scrolling="None">
                    <core:iHRPCoreGrid ID="dtgListGiayPhepLaoDong" GridLines="None" Width="100%" Height="500px" runat="server"
                        AutoGenerateColumns="false" AllowPaging="true" PageSize="15" Skin="Simple"
                        ShowStatusBar="true" AllowSorting="true"
                        OnItemCommand="dtgListGiayPhepLaoDong_ItemCommand"
                         OnItemDataBound="dtgListGiayPhepLaoDong_ItemDataBound"
                        OnNeedDataSource="dtgListGiayPhepLaoDong_NeedDataSource" PageSizeManual="true">
                        <PagerStyle Mode="NextPrevNumericAndAdvanced" AlwaysVisible="true" />
                        <MasterTableView GroupLoadMode="Client" Width="100%" CommandItemDisplay="Top" AllowMultiColumnSorting="true">
                            <CommandItemTemplate>
                                <asp:ImageButton ID="btnConfig" runat="server" CommandName="ConfigRadGrid" Width="10px"
                                    Height="10px" ImageUrl="~/Images/ConfigIcon.jpg" />
                            </CommandItemTemplate>
                            <Columns>
                                <telerik:GridBoundColumn UniqueName="PassportVisaID" Visible="false" DataField="PassportVisaID">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn UniqueName="Type" Visible="false" DataField="Type">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn UniqueName="LSPassportTypeID" Visible="false" DataField="LSPassportTypeID">
                                </telerik:GridBoundColumn>
                                <%--============================================--%>
                                <telerik:GridTemplateColumn UniqueName="SelectCol" HeaderText="Chọn">
                                    <HeaderStyle Width="50px" VerticalAlign="Middle" HorizontalAlign="Center"></HeaderStyle>
                                    <HeaderTemplate>
                                        <asp:CheckBox ID="chkSelectAll" CssClass="checkbox" runat="server"
                                            onclick="CheckAll_RadGrid('_ctl0_dtgListGiayPhepLaoDong__ctl0__ctl2__ctl2_chkSelectAll', '_ctl0_dtgListGiayPhepLaoDong', 'chkSelect')"></asp:CheckBox>
                                    </HeaderTemplate>
                                    <ItemStyle VerticalAlign="Middle" Width="50px" HorizontalAlign="Center" />
                                    <ItemTemplate>
                                        <asp:CheckBox ID="chkSelect" CssClass="checkbox" runat="server"></asp:CheckBox>
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridTemplateColumn UniqueName="Edit" HeaderText="Sửa">
                                    <HeaderStyle Width="50px" VerticalAlign="Middle" HorizontalAlign="Center"></HeaderStyle>
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemTemplate>
                                        <asp:ImageButton CssClass="rgpointer" ID="Edit" runat="server" ImageUrl="~/Images/edit.png" CommandName="EDIT_DATA" />
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridTemplateColumn UniqueName="No" DataField="" HeaderText="Seq">
                                    <HeaderStyle Width="50px" VerticalAlign="Middle" HorizontalAlign="Center"></HeaderStyle>
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemTemplate>
                                        <asp:Literal ID="glblItemSeqName" runat="server" Text='<%# Container.ItemIndex + 1 + dtgListGiayPhepLaoDong.PageSize * dtgListGiayPhepLaoDong.CurrentPageIndex%>' />
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridBoundColumn SortExpression="EmpID" UniqueName="EmpID" DataField="EmpID"
                                    Visible="false" HeaderText="EmpID">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="EmpCode" UniqueName="EmpCode" DataField="EmpCode"
                                    HeaderText="EmpCode">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="EmpName" UniqueName="EmpName" DataField="EmpName"
                                    HeaderText="EmpName">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Company" UniqueName="Company" DataField="Company"
                                    HeaderText="Company">
                                    <%--1--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Division" UniqueName="Division" DataField="Division"
                                    HeaderText="Division">
                                    <%--2--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Department" UniqueName="Department" DataField="Department"
                                    HeaderText="Department">
                                    <%--3--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Section" UniqueName="Section" DataField="Section"
                                    HeaderText="Section">
                                    <%--4--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="JobTitle" UniqueName="JobTitle" DataField="JobTitle"
                                    HeaderText="JobTitle">
                                    <%--5--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <%--<telerik:GridBoundColumn SortExpression="NgayVaoLam" UniqueName="NgayVaoLam" DataField="NgayVaoLam"
                            HeaderText="NgayVaoLam"> 
                            <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                        </telerik:GridBoundColumn>--%>
                                <%----rlogID:7956-----%>
                                <telerik:GridTemplateColumn UniqueName="NgayVaoLam" DataField="NgayVaoLam_Date" HeaderText="NgayVaoLam">
                                    <HeaderStyle HorizontalAlign="Center" Width="100px"></HeaderStyle>
                                    <ItemStyle HorizontalAlign="Center"></ItemStyle>
                                    <ItemTemplate>
                                        <asp:Label ID="lblNgayVaoLam" runat="server" Text='<%# DataBinder.Eval(Container, "DataItem.NgayVaoLam") %>'></asp:Label>
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <%--0--%>
                                <telerik:GridBoundColumn SortExpression="No" UniqueName="SoNo" DataField="No" HeaderText="No">
                                    <%--1--%>
                                    <HeaderStyle Width="50px" VerticalAlign="Middle" HorizontalAlign="Center"></HeaderStyle>
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>

                                <telerik:GridBoundColumn SortExpression="IssueDate" UniqueName="IssueDate" DataField="IssueDate" DataFormatString="{0: dd/MM/yyyy}"
                                    HeaderText="IssueDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="ExpireDate" UniqueName="ExpireDate" DataField="ExpireDate" DataFormatString="{0: dd/MM/yyyy}"
                                    HeaderText="ExpireDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IssuePlace" UniqueName="IssuePlace" DataField="IssuePlace"
                                    HeaderText="IssuePlace">
                                    <%--2--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IssuePlace_Province" UniqueName="IssuePlace_Province" DataField="IssuePlace_Province" HeaderText="IssuePlace_Province" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="TinhTrang" UniqueName="TinhTrang" DataField="TinhTrang"
                                    HeaderText="Tình trạng">
                                    <%--2--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IsTuPhap" UniqueName="IsTuPhap" DataField="IsTuPhap" HeaderText="Có lý lịch tư pháp">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Return" UniqueName="Return" DataField="Return" HeaderText="Trả GP cho sở LD">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Note" UniqueName="Note" DataField="Note"
                                    HeaderText="Note">
                                    <%--3--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <%--RlogID 25189 - KPMG_V34--%>
                                <telerik:GridBoundColumn SortExpression="JobPositionForWorkPermit" Visible="false" UniqueName="JobPositionForWorkPermit" HeaderText="JobPositionForWorkPermit"
                                    DataField="JobPositionForWorkPermit">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <%--END RlogID 25189 - KPMG_V34--%>

                                <%-- rlogID:5794--%>
                                <telerik:GridBoundColumn SortExpression="Level4" UniqueName="Level4" DataField="Level4" Visible="false"
                                    HeaderText="Level4">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Level5" UniqueName="Level5" DataField="Level5" Visible="false"
                                    HeaderText="Level5">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Level6" UniqueName="Level6" DataField="Level6" Visible="false"
                                    HeaderText="Level6">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Level7" UniqueName="Level7" DataField="Level7" Visible="false"
                                    HeaderText="Level7">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Level8" UniqueName="Level8" DataField="Level8" Visible="false"
                                    HeaderText="Level8">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Level9" UniqueName="Level9" DataField="Level9" Visible="false"
                                    HeaderText="Level9">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Creater" UniqueName="Creater" DataField="Creater"
                                    HeaderText="Creater">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="CreateTime" UniqueName="CreateTime" DataField="CreateTime"
                                    HeaderText="CreateTime" DataFormatString="{0: dd/MM/yyyy HH:mm:ss}">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Editer" UniqueName="Editer" DataField="Editer"
                                    HeaderText="Editer">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="EditTime" UniqueName="EditTime" DataField="EditTime"
                                    HeaderText="EditTime" DataFormatString="{0: dd/MM/yyyy HH:mm:ss}">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="HLevel1" UniqueName="HLevel1" DataField="HLevel1Name"
                                    HeaderText="HLevel1" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="HLevel2" UniqueName="HLevel2" DataField="HLevel2Name"
                                    HeaderText="HLevel2" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="HLevel3" UniqueName="HLevel3" DataField="HLevel3Name"
                                    HeaderText="HLevel3" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="HLevel4" UniqueName="HLevel4" DataField="HLevel4Name"
                                    HeaderText="HLevel4" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="HLevel5" UniqueName="HLevel5" DataField="HLevel5Name"
                                    HeaderText="HLevel5" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="HLevel6" UniqueName="HLevel6" DataField="HLevel6Name"
                                    HeaderText="HLevel6" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                 <%--RlogID 19658 --%>
                                <telerik:GridBoundColumn SortExpression="LSLoaiGiayPhepLaoDongName" UniqueName="LSLoaiGiayPhepLaoDongName" DataField="LSLoaiGiayPhepLaoDongName" HeaderText="LSLoaiGiayPhepLaoDongName" Visible="false">
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
                                <%--END RlogID 19658 --%>
                            </Columns>
                        </MasterTableView>
                        <HeaderStyle Width="200px" />
                        <ClientSettings AllowGroupExpandCollapse="True">
                            <Scrolling AllowScroll="True" UseStaticHeaders="True" />
                            <Resizing AllowColumnResize="true" ResizeGridOnColumnResize="true" EnableRealTimeResize="true" />
                            <ClientEvents OnGroupExpanded="groupExpanded" OnGroupCollapsed="groupCollapsed" />
                        </ClientSettings>
                    </core:iHRPCoreGrid>
                </telerik:RadPane>
            </telerik:RadSplitter>
        </div>
        <div class="gridHolder" id="trdtgListPassport">
            <telerik:RadSplitter ID="RadSplitter3" Width="100%" runat="server" Orientation="Horizontal"
                Height="100%">
                <telerik:RadPane ID="RadPane2" Height="500px" Width="100%" runat="server" Scrolling="None">
                    <core:iHRPCoreGrid ID="dtgListPassport" GridLines="None" Width="100%" Height="500px" runat="server"
                        AutoGenerateColumns="false" AllowPaging="true" PageSize="15" Skin="Simple"
                        ShowStatusBar="true" AllowSorting="true"
                        OnItemCommand="dtgListPassport_ItemCommand"
                        OnItemDataBound="dtgListPassport_ItemDataBound"
                        OnNeedDataSource="dtgListPassport_NeedDataSource" PageSizeManual="true">
                        <PagerStyle Mode="NextPrevNumericAndAdvanced" AlwaysVisible="true" />
                        <MasterTableView GroupLoadMode="Client" Width="100%" CommandItemDisplay="Top" AllowMultiColumnSorting="true">
                            <CommandItemTemplate>
                                <asp:ImageButton ID="btnConfig" runat="server" CommandName="ConfigRadGrid" Width="10px"
                                    Height="10px" ImageUrl="~/Images/ConfigIcon.jpg" />
                            </CommandItemTemplate>
                            <Columns>
                                <telerik:GridBoundColumn UniqueName="PassportVisaID" Visible="false" DataField="PassportVisaID">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn UniqueName="Type" Visible="false" DataField="Type">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn UniqueName="LSPassportTypeID" Visible="false" DataField="LSPassportTypeID">
                                </telerik:GridBoundColumn>
                                <%--============================================--%>
                                <telerik:GridTemplateColumn UniqueName="SelectCol" HeaderText="Chọn">
                                    <HeaderStyle Width="50px" VerticalAlign="Middle" HorizontalAlign="Center"></HeaderStyle>
                                    <HeaderTemplate>
                                        <asp:CheckBox ID="chkSelectAll" CssClass="checkbox" runat="server"
                                            onclick="CheckAll_RadGrid('_ctl0_dtgListPassport__ctl0__ctl2__ctl2_chkSelectAll', '_ctl0_dtgListPassport', 'chkSelect')"></asp:CheckBox>
                                    </HeaderTemplate>
                                    <ItemStyle VerticalAlign="Middle" Width="50px" HorizontalAlign="Center" />
                                    <ItemTemplate>
                                        <asp:CheckBox ID="chkSelect" CssClass="checkbox" runat="server"></asp:CheckBox>
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridTemplateColumn UniqueName="Edit" HeaderText="Sửa">
                                    <HeaderStyle Width="40px" HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemTemplate>
                                        <asp:ImageButton CssClass="rgpointer" ID="Edit" runat="server" ImageUrl="~/Images/edit.png" CommandName="EDIT_DATA" />
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridTemplateColumn UniqueName="No" DataField="" HeaderText="Seq">
                                    <HeaderStyle Width="50px" VerticalAlign="Middle" HorizontalAlign="Center"></HeaderStyle>
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemTemplate>
                                        <asp:Literal ID="glblItemSeqName" runat="server" Text='<%# Container.ItemIndex + 1 + dtgListPassport.PageSize * dtgListPassport.CurrentPageIndex%>' />
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridBoundColumn SortExpression="EmpID" UniqueName="EmpID" DataField="EmpID"
                                    Visible="false" HeaderText="EmpID">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="EmpCode" UniqueName="EmpCode" DataField="EmpCode"
                                    HeaderText="EmpCode">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="EmpName" UniqueName="EmpName" DataField="EmpName"
                                    HeaderText="EmpName">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Company" UniqueName="Company" DataField="Company"
                                    HeaderText="Company">
                                    <%--1--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Division" UniqueName="Division" DataField="Division"
                                    HeaderText="Division">
                                    <%--2--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Department" UniqueName="Department" DataField="Department"
                                    HeaderText="Department">
                                    <%--3--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Section" UniqueName="Section" DataField="Section"
                                    HeaderText="Section">
                                    <%--4--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="JobTitle" UniqueName="JobTitle" DataField="JobTitle"
                                    HeaderText="JobTitle">
                                    <%--5--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <%--<telerik:GridBoundColumn SortExpression="NgayVaoLam" UniqueName="NgayVaoLam" DataField="NgayVaoLam"
                            HeaderText="NgayVaoLam"> 
                            <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                        </telerik:GridBoundColumn>--%>
                                <%----rlogID:7956-----%>
                                <telerik:GridTemplateColumn UniqueName="NgayVaoLam" DataField="NgayVaoLam_Date" HeaderText="NgayVaoLam">
                                    <HeaderStyle HorizontalAlign="Center" Width="100px"></HeaderStyle>
                                    <ItemStyle HorizontalAlign="Center"></ItemStyle>
                                    <ItemTemplate>
                                        <asp:Label ID="lblNgayVaoLam" runat="server" Text='<%# DataBinder.Eval(Container, "DataItem.NgayVaoLam") %>'></asp:Label>
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <%--0--%>
                                <telerik:GridBoundColumn SortExpression="No" UniqueName="SoNo" DataField="No" HeaderText="No">
                                    <%--1--%>
                                    <HeaderStyle Width="50px" VerticalAlign="Middle" HorizontalAlign="Center"></HeaderStyle>
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IssueDate" UniqueName="IssueDate" DataField="IssueDate" DataFormatString="{0: dd/MM/yyyy}"
                                    HeaderText="IssueDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="ExpireDate" UniqueName="ExpireDate" DataField="ExpireDate" DataFormatString="{0: dd/MM/yyyy}"
                                    HeaderText="ExpireDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>

                                <telerik:GridBoundColumn SortExpression="LoaiPassport" UniqueName="LoaiPassport" DataField="LoaiPassport" 
                                    HeaderText="Loại Passport">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>

                                <%--RlogID 25190 - KPMG_V34--%>
                                <telerik:GridBoundColumn SortExpression="QuocGia_1" Visible="false" UniqueName="QuocGia_1" HeaderText="QuocGia_1" DataField="QuocGia_1">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <%--END RlogID 25190 - KPMG_V34--%>

                                <telerik:GridBoundColumn SortExpression="IssuePlace" UniqueName="IssuePlace" DataField="IssuePlace"
                                    HeaderText="IssuePlace">
                                    <%--2--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IssuePlace_Province" UniqueName="IssuePlace_Province" DataField="IssuePlace_Province" HeaderText="IssuePlace_Province" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="TinhTrang" UniqueName="TinhTrang" DataField="TinhTrang"
                                    HeaderText="Tình trạng">
                                    <%--2--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Note" UniqueName="Note" DataField="Note"
                                    HeaderText="Note">
                                    <%--3--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>

                                <%-- rlogID:5794--%>
                                <telerik:GridBoundColumn SortExpression="Level4" UniqueName="Level4" DataField="Level4" Visible="false"
                                    HeaderText="Level4">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Level5" UniqueName="Level5" DataField="Level5" Visible="false"
                                    HeaderText="Level5">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Level6" UniqueName="Level6" DataField="Level6" Visible="false"
                                    HeaderText="Level6">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Level7" UniqueName="Level7" DataField="Level7" Visible="false"
                                    HeaderText="Level7">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Level8" UniqueName="Level8" DataField="Level8" Visible="false"
                                    HeaderText="Level8">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Level9" UniqueName="Level9" DataField="Level9" Visible="false"
                                    HeaderText="Level9">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <%--rlogID:7393--%>
                                <telerik:GridBoundColumn SortExpression="EffectiveDate" UniqueName="EffectiveDate" DataField="EffectiveDate" Visible="false" DataFormatString="{0: dd/MM/yyyy}"
                                    HeaderText="EffectiveDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Creater" UniqueName="Creater" DataField="Creater"
                                    HeaderText="Creater">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="CreateTime" UniqueName="CreateTime" DataField="CreateTime"
                                    HeaderText="CreateTime" DataFormatString="{0: dd/MM/yyyy HH:mm:ss}">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Editer" UniqueName="Editer" DataField="Editer"
                                    HeaderText="Editer">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="EditTime" UniqueName="EditTime" DataField="EditTime"
                                    HeaderText="EditTime" DataFormatString="{0: dd/MM/yyyy HH:mm:ss}">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="HLevel1" UniqueName="HLevel1" DataField="HLevel1Name"
                                    HeaderText="HLevel1" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="HLevel2" UniqueName="HLevel2" DataField="HLevel2Name"
                                    HeaderText="HLevel2" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="HLevel3" UniqueName="HLevel3" DataField="HLevel3Name"
                                    HeaderText="HLevel3" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="HLevel4" UniqueName="HLevel4" DataField="HLevel4Name"
                                    HeaderText="HLevel4" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="HLevel5" UniqueName="HLevel5" DataField="HLevel5Name"
                                    HeaderText="HLevel5" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="HLevel6" UniqueName="HLevel6" DataField="HLevel6Name"
                                    HeaderText="HLevel6" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <%--RlogID 19659 --%>
                                <telerik:GridTemplateColumn UniqueName="AttachFileName" HeaderText="AttachFileName" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" Width="200%"></HeaderStyle>
                                    <ItemStyle HorizontalAlign="Center"></ItemStyle>
                                    <ItemTemplate>
                                        <uc:multiattachbutton id="MultiAttachButton1" runat="server" width="95%"></uc:multiattachbutton>
                                        <asp:Label ID="lblAttachFile" runat="server" Visible="true" CssClass="Lable d-none" Text='<%# DataBinder.Eval(Container, "DataItem.AttachFileID") %>'></asp:Label>
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <%--RlogID 19659 --%>
                            </Columns>
                        </MasterTableView>
                        <HeaderStyle Width="200px" />
                        <ClientSettings AllowGroupExpandCollapse="True">
                            <Scrolling AllowScroll="True" UseStaticHeaders="True" />
                            <Resizing AllowColumnResize="true" ResizeGridOnColumnResize="true" EnableRealTimeResize="true" />
                            <ClientEvents OnGroupExpanded="groupExpanded" OnGroupCollapsed="groupCollapsed" />
                        </ClientSettings>
                    </core:iHRPCoreGrid>
                </telerik:RadPane>
            </telerik:RadSplitter>
        </div>
        <div class="gridHolder" id="trdtgListVisa">
            <telerik:RadSplitter ID="RadSplitter4" Width="100%" runat="server" Orientation="Horizontal"
                Height="100%">
                <telerik:RadPane ID="RadPane3" Height="500px" Width="100%" runat="server" Scrolling="None">
                    <core:iHRPCoreGrid ID="dtgListVisa" GridLines="None" Width="100%" Height="500px" runat="server"
                        AutoGenerateColumns="false" AllowPaging="true" PageSize="15" Skin="Simple"
                        ShowStatusBar="true" AllowSorting="true"
                        OnItemCommand="dtgListVisa_ItemCommand"
                        OnItemDataBound="dtgListVisa_ItemDataBound"
                        OnNeedDataSource="dtgListVisa_NeedDataSource" PageSizeManual="true">
                        <PagerStyle Mode="NextPrevNumericAndAdvanced" AlwaysVisible="true" />
                        <MasterTableView GroupLoadMode="Client" Width="100%" CommandItemDisplay="Top" AllowMultiColumnSorting="true">
                            <CommandItemTemplate>
                                <asp:ImageButton ID="btnConfig" runat="server" CommandName="ConfigRadGrid" Width="10px"
                                    Height="10px" ImageUrl="~/Images/ConfigIcon.jpg" />
                            </CommandItemTemplate>
                            <Columns>
                                <telerik:GridBoundColumn UniqueName="PassportVisaID" Visible="false" DataField="PassportVisaID">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn UniqueName="Type" Visible="false" DataField="Type">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn UniqueName="LSPassportTypeID" Visible="false" DataField="LSPassportTypeID">
                                </telerik:GridBoundColumn>
                                <%--============================================--%>
                                <telerik:GridTemplateColumn UniqueName="SelectCol" HeaderText="Chọn">
                                    <HeaderStyle Width="50px" VerticalAlign="Middle" HorizontalAlign="Center"></HeaderStyle>
                                    <HeaderTemplate>
                                        <asp:CheckBox ID="chkSelectAll" CssClass="checkbox" runat="server"
                                            onclick="CheckAll_RadGrid('_ctl0_dtgListVisa__ctl0__ctl2__ctl2_chkSelectAll', '_ctl0_dtgListVisa', 'chkSelect')"></asp:CheckBox>
                                    </HeaderTemplate>
                                    <ItemStyle VerticalAlign="Middle" Width="5%" HorizontalAlign="Center" />
                                    <ItemTemplate>
                                        <asp:CheckBox ID="chkSelect" CssClass="checkbox" runat="server"></asp:CheckBox>
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridTemplateColumn UniqueName="Edit" HeaderText="Sửa">
                                    <HeaderStyle Width="40px" HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemTemplate>
                                        <asp:ImageButton CssClass="rgpointer" ID="Edit" runat="server" ImageUrl="~/Images/edit.png" CommandName="EDIT_DATA" />
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridTemplateColumn UniqueName="No" DataField="" HeaderText="Seq">
                                    <HeaderStyle Width="50px" VerticalAlign="Middle" HorizontalAlign="Center"></HeaderStyle>
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemTemplate>
                                        <asp:Literal ID="glblItemSeqName" runat="server" Text='<%# Container.ItemIndex + 1 + dtgListVisa.PageSize * dtgListVisa.CurrentPageIndex%>' />
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridBoundColumn SortExpression="EmpID" UniqueName="EmpID" DataField="EmpID"
                                    Visible="false" HeaderText="EmpID">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="EmpCode" UniqueName="EmpCode" DataField="EmpCode"
                                    HeaderText="EmpCode">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="EmpName" UniqueName="EmpName" DataField="EmpName"
                                    HeaderText="EmpName">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Company" UniqueName="Company" DataField="Company"
                                    HeaderText="Company">
                                    <%--1--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Division" UniqueName="Division" DataField="Division"
                                    HeaderText="Division">
                                    <%--2--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Department" UniqueName="Department" DataField="Department"
                                    HeaderText="Department">
                                    <%--3--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Section" UniqueName="Section" DataField="Section"
                                    HeaderText="Section">
                                    <%--4--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="JobTitle" UniqueName="JobTitle" DataField="JobTitle"
                                    HeaderText="JobTitle">
                                    <%--5--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <%--RlogID 25190 - KPMG_V34--%>
                                <telerik:GridBoundColumn SortExpression="QuocGia_1" Visible="false" UniqueName="QuocGia_1" HeaderText="QuocGia_1" DataField="QuocGia_1">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <%--END RlogID 25190 - KPMG_V34--%>
                                <%--<telerik:GridBoundColumn SortExpression="NgayVaoLam" UniqueName="NgayVaoLam" DataField="NgayVaoLam"
                            HeaderText="NgayVaoLam"> 
                            <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                        </telerik:GridBoundColumn>--%>
                                <%----rlogID:7956-----%>
                                <telerik:GridTemplateColumn UniqueName="NgayVaoLam" DataField="NgayVaoLam_Date" HeaderText="NgayVaoLam">
                                    <HeaderStyle HorizontalAlign="Center" Width="100px"></HeaderStyle>
                                    <ItemStyle HorizontalAlign="Center"></ItemStyle>
                                    <ItemTemplate>
                                        <asp:Label ID="lblNgayVaoLam" runat="server" Text='<%# DataBinder.Eval(Container, "DataItem.NgayVaoLam") %>'></asp:Label>
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <%--0--%>
                                <telerik:GridBoundColumn SortExpression="No" UniqueName="SoNo" DataField="No" HeaderText="No">
                                    <%--1--%>
                                    <HeaderStyle Width="50px" VerticalAlign="Middle" HorizontalAlign="Center"></HeaderStyle>
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IssueDate" UniqueName="IssueDate" DataField="IssueDate" DataFormatString="{0: dd/MM/yyyy}"
                                    HeaderText="IssueDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="ExpireDate" UniqueName="ExpireDate" DataField="ExpireDate" DataFormatString="{0: dd/MM/yyyy}"
                                    HeaderText="ExpireDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IssuePlace" UniqueName="IssuePlace" DataField="IssuePlace"
                                    HeaderText="IssuePlace">
                                    <%--2--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IssuePlace_Province" UniqueName="IssuePlace_Province" DataField="IssuePlace_Province" HeaderText="IssuePlace_Province" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="TinhTrang" UniqueName="TinhTrang" DataField="TinhTrang"
                                    HeaderText="Tình trạng">
                                    <%--2--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Note" UniqueName="Note" DataField="Note"
                                    HeaderText="Note">
                                    <%--3--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>

                                <%-- rlogID:5794--%>
                                <%--Start Rlog:18669 VuNH49 03/11/2022--%>
                                <telerik:GridBoundColumn SortExpression="LSQuocGiaID" UniqueName="LSQuocGiaID" DataField="LSQuocGiaID" HeaderText="LSQuocGiaID" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <%--End Rlog:18669 VuNH49 03/11/2022--%>
                                <telerik:GridBoundColumn SortExpression="Level4" UniqueName="Level4" DataField="Level4" Visible="false"
                                    HeaderText="Level4">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Level5" UniqueName="Level5" DataField="Level5" Visible="false"
                                    HeaderText="Level5">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Level6" UniqueName="Level6" DataField="Level6" Visible="false"
                                    HeaderText="Level6">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Level7" UniqueName="Level7" DataField="Level7" Visible="false"
                                    HeaderText="Level7">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Level8" UniqueName="Level8" DataField="Level8" Visible="false"
                                    HeaderText="Level8">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Level9" UniqueName="Level9" DataField="Level9" Visible="false"
                                    HeaderText="Level9">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Creater" UniqueName="Creater" DataField="Creater"
                                    HeaderText="Creater">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="CreateTime" UniqueName="CreateTime" DataField="CreateTime"
                                    HeaderText="CreateTime" DataFormatString="{0: dd/MM/yyyy HH:mm:ss}">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Editer" UniqueName="Editer" DataField="Editer"
                                    HeaderText="Editer">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="EditTime" UniqueName="EditTime" DataField="EditTime"
                                    HeaderText="EditTime" DataFormatString="{0: dd/MM/yyyy HH:mm:ss}">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="HLevel1" UniqueName="HLevel1" DataField="HLevel1Name"
                                    HeaderText="HLevel1" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="HLevel2" UniqueName="HLevel2" DataField="HLevel2Name"
                                    HeaderText="HLevel2" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="HLevel3" UniqueName="HLevel3" DataField="HLevel3Name"
                                    HeaderText="HLevel3" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="HLevel4" UniqueName="HLevel4" DataField="HLevel4Name"
                                    HeaderText="HLevel4" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="HLevel5" UniqueName="HLevel5" DataField="HLevel5Name"
                                    HeaderText="HLevel5" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="HLevel6" UniqueName="HLevel6" DataField="HLevel6Name"
                                    HeaderText="HLevel6" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="LoaiVisa" UniqueName="LoaiVisa" DataField="LoaiVisa" 
                                    HeaderText="Loại Visa">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <%--RlogID 19660 --%>
                                <telerik:GridTemplateColumn UniqueName="AttachFileName" HeaderText="AttachFileName" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" Width="200%"></HeaderStyle>
                                    <ItemStyle HorizontalAlign="Center"></ItemStyle>
                                    <ItemTemplate>
                                        <uc:multiattachbutton id="MultiAttachButton1" runat="server" width="95%"></uc:multiattachbutton>
                                        <asp:Label ID="lblAttachFile" runat="server" Visible="true" CssClass="Lable d-none" Text='<%# DataBinder.Eval(Container, "DataItem.AttachFileID") %>'></asp:Label>
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridBoundColumn SortExpression="EffectiveDate" UniqueName="EffectiveDate" DataField="EffectiveDate" DataFormatString="{0: dd/MM/yyyy}"
                                    HeaderText="EffectiveDate" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <%--RlogID 19660 --%>
                                <telerik:GridBoundColumn SortExpression="NgayXuatNhapCanh" UniqueName="NgayXuatNhapCanh" DataField="NgayXuatNhapCanh" HeaderText="Thông tin xuất nhập cảnh">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                            </Columns>
                        </MasterTableView>
                        <HeaderStyle Width="200px" />
                        <ClientSettings AllowGroupExpandCollapse="True">
                            <Scrolling AllowScroll="True" UseStaticHeaders="True" />
                            <Resizing AllowColumnResize="true" ResizeGridOnColumnResize="true" EnableRealTimeResize="true" />
                            <ClientEvents OnGroupExpanded="groupExpanded" OnGroupCollapsed="groupCollapsed" />
                        </ClientSettings>
                    </core:iHRPCoreGrid>
                </telerik:RadPane>
            </telerik:RadSplitter>
        </div>
        <div class="gridHolder" id="trdtgListTempLicence">
            <telerik:RadSplitter ID="RadSplitter5" Width="100%" runat="server" Orientation="Horizontal"
                Height="100%">
                <telerik:RadPane ID="RadPane4" Height="500px" Width="100%" runat="server" Scrolling="None">
                    <core:iHRPCoreGrid ID="dtgListTempLicence" GridLines="None" Width="100%" Height="500px" runat="server"
                        AutoGenerateColumns="false" AllowPaging="true" PageSize="15" Skin="Simple"
                        ShowStatusBar="true" AllowSorting="true"
                        OnItemCommand="dtgListTempLicence_ItemCommand"
                        OnItemDataBound="dtgListTempLicence_ItemDataBound"
                        OnNeedDataSource="dtgListTempLicence_NeedDataSource" PageSizeManual="true">
                        <PagerStyle Mode="NextPrevNumericAndAdvanced" AlwaysVisible="true" />
                        <MasterTableView GroupLoadMode="Client" Width="100%" CommandItemDisplay="Top" AllowMultiColumnSorting="true">
                            <CommandItemTemplate>
                                <asp:ImageButton ID="btnConfig" runat="server" CommandName="ConfigRadGrid" Width="10px"
                                    Height="10px" ImageUrl="~/Images/ConfigIcon.jpg" />
                            </CommandItemTemplate>
                            <Columns>
                                <telerik:GridBoundColumn UniqueName="PassportVisaID" Visible="false" DataField="PassportVisaID">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn UniqueName="Type" Visible="false" DataField="Type">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn UniqueName="LSPassportTypeID" Visible="false" DataField="LSPassportTypeID">
                                </telerik:GridBoundColumn>
                                <%--============================================--%>
                                <telerik:GridTemplateColumn UniqueName="SelectCol" HeaderText="Chọn">
                                    <HeaderStyle Width="50px" VerticalAlign="Middle" HorizontalAlign="Center"></HeaderStyle>
                                    <HeaderTemplate>
                                        <asp:CheckBox ID="chkSelectAll" CssClass="checkbox" runat="server"
                                            onclick="CheckAll_RadGrid('_ctl0_dtgListTempLicence__ctl0__ctl2__ctl2_chkSelectAll', '_ctl0_dtgListTempLicence', 'chkSelect')"></asp:CheckBox>
                                    </HeaderTemplate>
                                    <ItemStyle VerticalAlign="Middle" Width="5%" HorizontalAlign="Center" />
                                    <ItemTemplate>
                                        <asp:CheckBox ID="chkSelect" CssClass="checkbox" runat="server"></asp:CheckBox>
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridTemplateColumn UniqueName="Edit" HeaderText="Sửa">
                                    <HeaderStyle Width="40px" HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemTemplate>
                                        <asp:ImageButton CssClass="rgpointer" ID="Edit" runat="server" ImageUrl="~/Images/edit.png" CommandName="EDIT_DATA" />
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridTemplateColumn UniqueName="No" DataField="" HeaderText="Seq">
                                    <HeaderStyle Width="50px" VerticalAlign="Middle" HorizontalAlign="Center"></HeaderStyle>
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemTemplate>
                                        <asp:Literal ID="glblItemSeqName" runat="server" Text='<%# Container.ItemIndex + 1 + dtgListTempLicence.PageSize * dtgListTempLicence.CurrentPageIndex%>' />
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridBoundColumn SortExpression="EmpID" UniqueName="EmpID" DataField="EmpID"
                                    Visible="false" HeaderText="EmpID">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="EmpCode" UniqueName="EmpCode" DataField="EmpCode"
                                    HeaderText="EmpCode">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="EmpName" UniqueName="EmpName" DataField="EmpName"
                                    HeaderText="EmpName">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Company" UniqueName="Company" DataField="Company"
                                    HeaderText="Company">
                                    <%--1--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Division" UniqueName="Division" DataField="Division"
                                    HeaderText="Division">
                                    <%--2--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Department" UniqueName="Department" DataField="Department"
                                    HeaderText="Department">
                                    <%--3--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Section" UniqueName="Section" DataField="Section"
                                    HeaderText="Section">
                                    <%--4--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="JobTitle" UniqueName="JobTitle" DataField="JobTitle"
                                    HeaderText="JobTitle">
                                    <%--5--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <%--<telerik:GridBoundColumn SortExpression="NgayVaoLam" UniqueName="NgayVaoLam" DataField="NgayVaoLam"
                            HeaderText="NgayVaoLam"> 
                            <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                        </telerik:GridBoundColumn>--%>
                                <%----rlogID:7956-----%>
                                <telerik:GridTemplateColumn UniqueName="NgayVaoLam" DataField="NgayVaoLam_Date" HeaderText="NgayVaoLam">
                                    <HeaderStyle HorizontalAlign="Center" Width="100px"></HeaderStyle>
                                    <ItemStyle HorizontalAlign="Center"></ItemStyle>
                                    <ItemTemplate>
                                        <asp:Label ID="lblNgayVaoLam" runat="server" Text='<%# DataBinder.Eval(Container, "DataItem.NgayVaoLam") %>'></asp:Label>
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <%--0--%>
                                <telerik:GridBoundColumn SortExpression="No" UniqueName="SoNo" DataField="No" HeaderText="No">
                                    <HeaderStyle Width="50px" VerticalAlign="Middle" HorizontalAlign="Center"></HeaderStyle>
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <%--1--%>
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IssueDate" UniqueName="IssueDate" DataField="IssueDate" DataFormatString="{0: dd/MM/yyyy}"
                                    HeaderText="IssueDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="ExpireDate" UniqueName="ExpireDate" DataField="ExpireDate" DataFormatString="{0: dd/MM/yyyy}"
                                    HeaderText="ExpireDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IssuePlace" UniqueName="IssuePlace" DataField="IssuePlace"
                                    HeaderText="IssuePlace">
                                    <%--2--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IssuePlace_Province" UniqueName="IssuePlace_Province" DataField="IssuePlace_Province" HeaderText="IssuePlace_Province" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="TinhTrang" UniqueName="TinhTrang" DataField="TinhTrang"
                                    HeaderText="Tình trạng">
                                    <%--2--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Note" UniqueName="Note" DataField="Note"
                                    HeaderText="Note">
                                    <%--3--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>

                                <%-- rlogID:5794--%>
                                <telerik:GridBoundColumn SortExpression="Level4" UniqueName="Level4" DataField="Level4" Visible="false"
                                    HeaderText="Level4">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Level5" UniqueName="Level5" DataField="Level5" Visible="false"
                                    HeaderText="Level5">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Level6" UniqueName="Level6" DataField="Level6" Visible="false"
                                    HeaderText="Level6">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Level7" UniqueName="Level7" DataField="Level7" Visible="false"
                                    HeaderText="Level7">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Level8" UniqueName="Level8" DataField="Level8" Visible="false"
                                    HeaderText="Level8">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Level9" UniqueName="Level9" DataField="Level9" Visible="false"
                                    HeaderText="Level9">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Creater" UniqueName="Creater" DataField="Creater"
                                    HeaderText="Creater">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="CreateTime" UniqueName="CreateTime" DataField="CreateTime"
                                    HeaderText="CreateTime" DataFormatString="{0: dd/MM/yyyy HH:mm:ss}">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Editer" UniqueName="Editer" DataField="Editer"
                                    HeaderText="Editer">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="EditTime" UniqueName="EditTime" DataField="EditTime"
                                    HeaderText="EditTime" DataFormatString="{0: dd/MM/yyyy HH:mm:ss}">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="HLevel1" UniqueName="HLevel1" DataField="HLevel1Name"
                                    HeaderText="HLevel1" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="HLevel2" UniqueName="HLevel2" DataField="HLevel2Name"
                                    HeaderText="HLevel2" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="HLevel3" UniqueName="HLevel3" DataField="HLevel3Name"
                                    HeaderText="HLevel3" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="HLevel4" UniqueName="HLevel4" DataField="HLevel4Name"
                                    HeaderText="HLevel4" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="HLevel5" UniqueName="HLevel5" DataField="HLevel5Name"
                                    HeaderText="HLevel5" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="HLevel6" UniqueName="HLevel6" DataField="HLevel6Name"
                                    HeaderText="HLevel6" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridTemplateColumn UniqueName="AttachFileName" HeaderText="AttachFileName" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" Width="200%"></HeaderStyle>
                                    <ItemStyle HorizontalAlign="Center"></ItemStyle>
                                    <ItemTemplate>
                                        <uc:multiattachbutton id="MultiAttachButton1" runat="server" width="95%"></uc:multiattachbutton>
                                        <asp:Label ID="lblAttachFile" runat="server" Visible="true" CssClass="Lable d-none" Text='<%# DataBinder.Eval(Container, "DataItem.AttachFileID") %>'></asp:Label>
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <%--START RlogID 25487--%>
                                <telerik:GridBoundColumn SortExpression="LoaiGiayTamTru" Visible="false" UniqueName="LoaiGiayTamTru" HeaderText="LoaiGiayTamTru" DataField="LoaiGiayTamTru">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <%--END RlogID 25487--%>
                            </Columns>
                        </MasterTableView>
                        <HeaderStyle Width="200px" />
                        <ClientSettings AllowGroupExpandCollapse="True">
                            <Scrolling AllowScroll="True" UseStaticHeaders="True" />
                            <Resizing AllowColumnResize="true" ResizeGridOnColumnResize="true" EnableRealTimeResize="true" />
                            <ClientEvents OnGroupExpanded="groupExpanded" OnGroupCollapsed="groupCollapsed" />
                        </ClientSettings>
                    </core:iHRPCoreGrid>
                </telerik:RadPane>
            </telerik:RadSplitter>
        </div>
        <div class="gridHolder" id="trdtgListThueNha">
            <telerik:RadSplitter ID="RadSplitter1" Width="100%" runat="server" Orientation="Horizontal"
                Height="100%">
                <telerik:RadPane ID="gridPane" Height="500px" Width="100%" runat="server" Scrolling="None">
                    <core:iHRPCoreGrid ID="dtgListThueNha" GridLines="None" Width="100%" Height="500px" runat="server"
                        AutoGenerateColumns="false" AllowPaging="true" PageSize="15" Skin="Simple"
                        ShowStatusBar="true" AllowSorting="true"
                        OnItemCommand="dtgListThueNha_ItemCommand"
                        OnItemDataBound="dtgListThueNha_ItemDataBound"
                        OnNeedDataSource="dtgListThueNha_NeedDataSource" PageSizeManual="true">
                        <PagerStyle Mode="NextPrevNumericAndAdvanced" AlwaysVisible="true" />
                        <MasterTableView GroupLoadMode="Client" Width="100%" CommandItemDisplay="Top" AllowMultiColumnSorting="true">
                            <CommandItemTemplate>
                                <asp:ImageButton ID="btnConfig" runat="server" CommandName="ConfigRadGrid" Width="10px"
                                    Height="10px" ImageUrl="~/Images/ConfigIcon.jpg" />
                            </CommandItemTemplate>
                            <Columns>
                                <telerik:GridBoundColumn UniqueName="PassportVisaID" Visible="false" DataField="PassportVisaID">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn UniqueName="Type" Visible="false" DataField="Type">
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn UniqueName="LSPassportTypeID" Visible="false" DataField="LSPassportTypeID">
                                </telerik:GridBoundColumn>
                                <%--============================================--%>
                                <telerik:GridTemplateColumn UniqueName="SelectCol" HeaderText="Chọn">
                                    <HeaderStyle Width="50px" VerticalAlign="Middle" HorizontalAlign="Center"></HeaderStyle>
                                    <HeaderTemplate>
                                        <asp:CheckBox ID="chkSelectAll" CssClass="checkbox" runat="server"
                                            onclick="CheckAll_RadGrid('_ctl0_dtgListThueNha__ctl0__ctl2__ctl2_chkSelectAll', '_ctl0_dtgListThueNha', 'chkSelect')"></asp:CheckBox>
                                    </HeaderTemplate>
                                    <ItemStyle VerticalAlign="Middle" Width="5%" HorizontalAlign="Center" />
                                    <ItemTemplate>
                                        <asp:CheckBox ID="chkSelect" CssClass="checkbox" runat="server"></asp:CheckBox>
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridTemplateColumn UniqueName="Edit" HeaderText="Sửa">
                                    <HeaderStyle Width="40px" HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemTemplate>
                                        <asp:ImageButton CssClass="rgpointer" ID="Edit" runat="server" ImageUrl="~/Images/edit.png" CommandName="EDIT_DATA" />
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridTemplateColumn UniqueName="No" DataField="" HeaderText="Seq">
                                    <HeaderStyle Width="50px" VerticalAlign="Middle" HorizontalAlign="Center"></HeaderStyle>
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemTemplate>
                                        <asp:Literal ID="glblItemSeqName" runat="server" Text='<%# Container.ItemIndex + 1 + dtgListThueNha.PageSize * dtgListThueNha.CurrentPageIndex%>' />
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <telerik:GridBoundColumn SortExpression="EmpID" UniqueName="EmpID" DataField="EmpID"
                                    Visible="false" HeaderText="EmpID">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="EmpCode" UniqueName="EmpCode" DataField="EmpCode"
                                    HeaderText="EmpCode">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="EmpName" UniqueName="EmpName" DataField="EmpName"
                                    HeaderText="EmpName">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Company" UniqueName="Company" DataField="Company"
                                    HeaderText="Company">
                                    <%--1--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Division" UniqueName="Division" DataField="Division"
                                    HeaderText="Division">
                                    <%--2--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Department" UniqueName="Department" DataField="Department"
                                    HeaderText="Department">
                                    <%--3--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Section" UniqueName="Section" DataField="Section"
                                    HeaderText="Section">
                                    <%--4--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="JobTitle" UniqueName="JobTitle" DataField="JobTitle"
                                    HeaderText="JobTitle">
                                    <%--5--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <%--<telerik:GridBoundColumn SortExpression="NgayVaoLam" UniqueName="NgayVaoLam" DataField="NgayVaoLam"
                            HeaderText="NgayVaoLam"> 
                            <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                        </telerik:GridBoundColumn>--%>
                                <%----rlogID:7956-----%>
                                <telerik:GridTemplateColumn UniqueName="NgayVaoLam" DataField="NgayVaoLam_Date" HeaderText="NgayVaoLam">
                                    <HeaderStyle HorizontalAlign="Center" Width="100px"></HeaderStyle>
                                    <ItemStyle HorizontalAlign="Center"></ItemStyle>
                                    <ItemTemplate>
                                        <asp:Label ID="lblNgayVaoLam" runat="server" Text='<%# DataBinder.Eval(Container, "DataItem.NgayVaoLam") %>'></asp:Label>
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                <%--0--%>
                                <telerik:GridBoundColumn SortExpression="No" UniqueName="SoNo" DataField="No" HeaderText="No">
                                    <%--1--%>
                                    <HeaderStyle Width="50px" VerticalAlign="Middle" HorizontalAlign="Center"></HeaderStyle>
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IssueDate" UniqueName="IssueDate" DataField="IssueDate" DataFormatString="{0: dd/MM/yyyy}"
                                    HeaderText="IssueDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="ExpireDate" UniqueName="ExpireDate" DataField="ExpireDate" DataFormatString="{0: dd/MM/yyyy}"
                                    HeaderText="ExpireDate">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IssuePlace" UniqueName="IssuePlace" DataField="IssuePlace"
                                    HeaderText="IssuePlace">
                                    <%--2--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="TinhTrang" UniqueName="TinhTrang" DataField="TinhTrang"
                                    HeaderText="Tình trạng">
                                    <%--2--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Note" UniqueName="Note" DataField="Note"
                                    HeaderText="Note">
                                    <%--3--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>

                                <telerik:GridBoundColumn SortExpression="ChuCanHo" UniqueName="ChuCanHo" DataField="ChuCanHo"
                                    HeaderText="ChuCanHo">
                                    <%--3--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="SoDienThoai" UniqueName="SoDienThoai" DataField="SoDienThoai"
                                    HeaderText="SoDienThoai">
                                    <%--3--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="TienDatCoc" UniqueName="TienDatCoc" DataField="TienDatCoc"
                                    HeaderText="TienDatCoc">
                                    <%--3--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="TienThueNha" UniqueName="TienThueNha" DataField="TienThueNha"
                                    HeaderText="TienThueNha">
                                    <%--3--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="LoaiTienTe" UniqueName="LoaiTienTe" DataField="LoaiTienTe"
                                    HeaderText="LoaiTienTe">
                                    <%--3--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <%-- rlogID:5794--%>
                                <telerik:GridBoundColumn SortExpression="Level4" UniqueName="Level4" DataField="Level4" Visible="false"
                                    HeaderText="Level4">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Level5" UniqueName="Level5" DataField="Level5" Visible="false"
                                    HeaderText="Level5">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Level6" UniqueName="Level6" DataField="Level6" Visible="false"
                                    HeaderText="Level6">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Level7" UniqueName="Level7" DataField="Level7" Visible="false"
                                    HeaderText="Level7">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Level8" UniqueName="Level8" DataField="Level8" Visible="false"
                                    HeaderText="Level8">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Level9" UniqueName="Level9" DataField="Level9" Visible="false"
                                    HeaderText="Level9">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Creater" UniqueName="Creater" DataField="Creater"
                                    HeaderText="Creater">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="CreateTime" UniqueName="CreateTime" DataField="CreateTime"
                                    HeaderText="CreateTime" DataFormatString="{0: dd/MM/yyyy HH:mm:ss}">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Editer" UniqueName="Editer" DataField="Editer"
                                    HeaderText="Editer">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="EditTime" UniqueName="EditTime" DataField="EditTime"
                                    HeaderText="EditTime" DataFormatString="{0: dd/MM/yyyy HH:mm:ss}">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="HLevel1" UniqueName="HLevel1" DataField="HLevel1Name"
                                    HeaderText="HLevel1" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="HLevel2" UniqueName="HLevel2" DataField="HLevel2Name"
                                    HeaderText="HLevel2" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="HLevel3" UniqueName="HLevel3" DataField="HLevel3Name"
                                    HeaderText="HLevel3" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="HLevel4" UniqueName="HLevel4" DataField="HLevel4Name"
                                    HeaderText="HLevel4" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="HLevel5" UniqueName="HLevel5" DataField="HLevel5Name"
                                    HeaderText="HLevel5" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="HLevel6" UniqueName="HLevel6" DataField="HLevel6Name"
                                    HeaderText="HLevel6" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridTemplateColumn UniqueName="AttachFileName" HeaderText="AttachFileName" Visible="false">
                                    <HeaderStyle HorizontalAlign="Center" Width="200%"></HeaderStyle>
                                    <ItemStyle HorizontalAlign="Center"></ItemStyle>
                                    <ItemTemplate>
                                        <uc:multiattachbutton id="MultiAttachButton1" runat="server" width="95%"></uc:multiattachbutton>
                                        <asp:Label ID="lblAttachFile" runat="server" Visible="true" CssClass="Lable d-none" Text='<%# DataBinder.Eval(Container, "DataItem.AttachFileID") %>'></asp:Label>
                                    </ItemTemplate>
                                </telerik:GridTemplateColumn>
                                   <%-- Tamnb rlog 25532 --%>
                                <telerik:GridBoundColumn SortExpression="DiaChi" Visible="false" UniqueName="DiaChi" HeaderText="Địa chỉ"
                                    DataField="DiaChi">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="AdvancedNoticeTime" Visible="false" UniqueName="AdvancedNoticeTime" HeaderText="Kỳ thanh toán"
                                    DataField="AdvancedNoticeTime">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                 <telerik:GridBoundColumn SortExpression="TerminationCondition" Visible="false" UniqueName="TerminationCondition" HeaderText="Hạn gửi chứng từ nộp thuế"
                                    DataField="TerminationCondition">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="OtherInfo1" Visible="false" UniqueName="OtherInfo1" HeaderText="Thông tin khác 1"
                                    DataField="OtherInfo1">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <%-- Tamnb rlog 25532 --%>
                            </Columns>
                        </MasterTableView>
                        <HeaderStyle Width="200px" />
                        <ClientSettings AllowGroupExpandCollapse="True">
                            <Scrolling AllowScroll="True" UseStaticHeaders="True" />
                            <Resizing AllowColumnResize="true" ResizeGridOnColumnResize="true" EnableRealTimeResize="true" />
                            <ClientEvents OnGroupExpanded="groupExpanded" OnGroupCollapsed="groupCollapsed" />
                        </ClientSettings>
                    </core:iHRPCoreGrid>
                </telerik:RadPane>
            </telerik:RadSplitter>
        </div>
        <%--RLOG 19677--%>
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
                                <telerik:GridBoundColumn SortExpression="EmpID" UniqueName="EmpID" DataField="EmpID"
                                    Visible="false" HeaderText="EmpID">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="EmpCode" UniqueName="EmpCode" DataField="EmpCode"
                                    HeaderText="EmpCode">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="EmpName" UniqueName="EmpName" DataField="EmpName"
                                    HeaderText="EmpName">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Company" UniqueName="Company" DataField="Company"
                                    HeaderText="Company">
                                    <%--1--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Division" UniqueName="Division" DataField="Division"
                                    HeaderText="Division">
                                    <%--2--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Department" UniqueName="Department" DataField="Department"
                                    HeaderText="Department">
                                    <%--3--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Section" UniqueName="Section" DataField="Section"
                                    HeaderText="Section">
                                    <%--4--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="JobTitle" UniqueName="JobTitle" DataField="JobTitle"
                                    HeaderText="JobTitle">
                                    <%--5--%>
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Level4" UniqueName="Level4" DataField="Level4" Visible="false"
                                    HeaderText="Level4">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Level5" UniqueName="Level5" DataField="Level5" Visible="false"
                                    HeaderText="Level5">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Level6" UniqueName="Level6" DataField="Level6" Visible="false"
                                    HeaderText="Level6">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Level7" UniqueName="Level7" DataField="Level7" Visible="false"
                                    HeaderText="Level7">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Level8" UniqueName="Level8" DataField="Level8" Visible="false"
                                    HeaderText="Level8">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="Level9" UniqueName="Level9" DataField="Level9" Visible="false"
                                    HeaderText="Level9">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="No" UniqueName="No" HeaderText="No"
                                    DataField="No">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IssueDate" UniqueName="IssueDate" HeaderText="IssueDate"
                                    DataField="IssueDate" DataFormatString="{0: dd/MM/yyyy}">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="70px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="IssuePlace" UniqueName="IssuePlace" HeaderText="IssuePlace"
                                    DataField="IssuePlace">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="70px" />
                                    <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="TinhTrangAnTich" Visible="false" UniqueName="TinhTrangAnTich" HeaderText="TinhTrangAnTich"
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
                                        <asp:Label ID="lblAttachFile" runat="server" Visible="true" CssClass="Lable d-none" Text='<%# DataBinder.Eval(Container, "DataItem.AttachFileID") %>'></asp:Label>
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
                                    DataField="CreateTime" DataFormatString="{0: dd/MM/yyyy HH:mm:ss}">
                                    <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                </telerik:GridBoundColumn>
                                <telerik:GridBoundColumn SortExpression="EditTime" Visible="false" UniqueName="EditTime" HeaderText="EditTime"
                                    DataField="EditTime" DataFormatString="{0: dd/MM/yyyy HH:mm:ss}">
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
        <%--END RLOG 19677--%>
    </div>
</div>


<script language="javascript">
    //kiem tra User co nhap cac gia tri bat buoc truoc khi Save
    function checksave() 
    {
        if (!checkempty('txtFromDate') && !checkempty('txtToDate')) 
        {
            if (FromSmallOrEqualToDate(document.getElementById('_ctl0_txtFromDate'), document.getElementById('_ctl0_txtToDate')) == false) 
            {
                GetAlertError(iTotal, DSAlert, "00188")
                document.getElementById('_ctl0_txtToDate').focus();
                return false;
            }
        }
        return true;
    }

    //kiem tra User co check chon truoc khi Delete
    function CheckDelete() {

        if(document.getElementById('_ctl0_optHDThueNha').checked)
        {
            if (GridCheck_RadGrid('_ctl0_dtgListThueNha', 'chkSelect') == false) {
                GetAlertError(iTotal, DSAlert, "0001");
                return false;
            }
        }
        else if (document.getElementById('_ctl0_optPermit').checked)
        {
            if (GridCheck_RadGrid('_ctl0_dtgListGiayPhepLaoDong', 'chkSelect') == false) {
                GetAlertError(iTotal, DSAlert, "0001");
                return false;
            }
        }
        else if (document.getElementById('_ctl0_optPassport').checked)
        {
            if (GridCheck_RadGrid('_ctl0_dtgListPassport', 'chkSelect') == false) {
                GetAlertError(iTotal, DSAlert, "0001");
                return false;
            }
        }
        else if (document.getElementById('_ctl0_optVisa').checked)
        {
            if (GridCheck_RadGrid('_ctl0_dtgListVisa', 'chkSelect') == false) {
                GetAlertError(iTotal, DSAlert, "0001");
                return false;
            }
        }
        else if (document.getElementById('_ctl0_optTempLicence').checked)
        {
            if (GridCheck_RadGrid('_ctl0_dtgListTempLicence', 'chkSelect') == false) {
                GetAlertError(iTotal, DSAlert, "0001");
                return false;
            }
        }
        else if (document.getElementById('_ctl0_optLyLichTuPhap').checked)
        {
            if (GridCheck_RadGrid('_ctl0_dtgListLyLichTuPhap', 'chkSelect') == false) {
                GetAlertError(iTotal, DSAlert, "0001");
                return false;
            }
        }
        if (confirm(GetAlertText(iTotal, DSAlert, "0002")) == false) {
            return false;
        }
        DisableAllButton('_ctl0:btnDelete'); 
        return true;
    }

    //NamHQ create on 290108
    //   Show/Hide cac Div tuy theo radiobutton list

    function allReady() {
        ShowHideDIV();
    }

    ShowHideDIV();
    function ShowHideDIV() 
    {
        if (document.getElementById('_ctl0_optPermit').checked)
        {
            document.getElementById("trGPLD").style.display = '';
            document.getElementById("divJobPositionForWorkPermit").style.display = '';
            document.getElementById("divQuocGiaPP").style.display = 'none';
            document.getElementById("divQuocGiaVisa").style.display = 'none';
            document.getElementById("trPP").style.display = 'none';
            document.getElementById("trVS").style.display = 'none';
            document.getElementById("trGTT").style.display = 'none';
            document.getElementById("trHDTN").style.display = 'none';
            document.getElementById("trPassportType").style.display = 'none';
            document.getElementById("divLoaiVisa").style.display = 'none';
            document.getElementById("trLLTP").style.display = 'none';
        }
        else if (document.getElementById('_ctl0_optPassport').checked) 
        {
            document.getElementById("trPassportType").style.display = '';
            document.getElementById("divQuocGiaPP").style.display = '';
            document.getElementById("divQuocGiaVisa").style.display = 'none';
            document.getElementById("trGPLD").style.display = 'none';
            document.getElementById("divJobPositionForWorkPermit").style.display = 'none';
            document.getElementById("trPP").style.display = '';
            document.getElementById("trVS").style.display = 'none';
            document.getElementById("trGTT").style.display = 'none';
            document.getElementById("trHDTN").style.display = 'none';
            document.getElementById("divLoaiVisa").style.display = 'none';
            document.getElementById("trLLTP").style.display = 'none';
        }
        else if (document.getElementById('_ctl0_optVisa').checked)
        {
            document.getElementById("trGPLD").style.display = 'none';
            document.getElementById("divQuocGiaPP").style.display = 'none';
            document.getElementById("divQuocGiaVisa").style.display = '';
            document.getElementById("divJobPositionForWorkPermit").style.display = 'none';
            document.getElementById("trPP").style.display = 'none';
            document.getElementById("trVS").style.display = '';
            document.getElementById("trGTT").style.display = 'none';
            document.getElementById("trHDTN").style.display = 'none';
            document.getElementById("trPassportType").style.display = 'none';
            document.getElementById("divLoaiVisa").style.display = '';
            document.getElementById("trLLTP").style.display = 'none';

        }
        else if (document.getElementById('_ctl0_optTempLicence').checked)
        {
            document.getElementById("trGPLD").style.display = 'none';
            document.getElementById("divQuocGiaPP").style.display = 'none';
            document.getElementById("divQuocGiaVisa").style.display = 'none';
            document.getElementById("divJobPositionForWorkPermit").style.display = 'none';
            document.getElementById("trPP").style.display = 'none';
            document.getElementById("trVS").style.display = 'none';
            document.getElementById("trGTT").style.display = '';
            document.getElementById("trHDTN").style.display = 'none';
            document.getElementById("trPassportType").style.display = 'none';
            document.getElementById("divLoaiVisa").style.display = 'none';
            document.getElementById("trLLTP").style.display = 'none';
        }
        else if (document.getElementById('_ctl0_optLyLichTuPhap').checked)
        {
            document.getElementById("trGPLD").style.display = 'none';
            document.getElementById("divQuocGiaPP").style.display = 'none';
            document.getElementById("divQuocGiaVisa").style.display = 'none';
            document.getElementById("divJobPositionForWorkPermit").style.display = 'none';
            document.getElementById("trPP").style.display = 'none';
            document.getElementById("trVS").style.display = 'none';
            document.getElementById("trGTT").style.display = 'none';
            document.getElementById("trHDTN").style.display = 'none';
            document.getElementById("trPassportType").style.display = 'none';
            document.getElementById("divLoaiVisa").style.display = 'none';
            document.getElementById("divTinhTrang").style.display = 'none';
            document.getElementById("trLLTP").style.display = '';
        }
        else {
            document.getElementById("trGPLD").style.display = 'none';
            document.getElementById("divQuocGiaPP").style.display = 'none';
            document.getElementById("divQuocGiaVisa").style.display = 'none';
            document.getElementById("divJobPositionForWorkPermit").style.display = 'none';
            document.getElementById("trPP").style.display = 'none';
            document.getElementById("trVS").style.display = 'none';
            document.getElementById("trGTT").style.display = 'none';
            document.getElementById("trHDTN").style.display = '';
            document.getElementById("trPassportType").style.display = 'none';
            document.getElementById("divLoaiVisa").style.display = 'none';
            document.getElementById("trLLTP").style.display = 'none';
        }
    }
    function ShowExcelSelectPage() {
        var HouseRental = document.getElementById('_ctl0_optHDThueNha');
        var param;
        if (HouseRental.checked == false)
            param = 'tpl=../../MdlHR/Template/HR_ForeignerInfo_Import.xls&Store=HR_spfrmForeignerInfo_Import';
        else
            param = 'tpl=../../MdlHR/Template/HR_HouseRental_Import.xls&Store=HR_spfrmHouseRental_Import';
        var eparam = '~/../Common/Form/FileSelect.aspx' + '?Param=' + clsCommonGetEncryptString(clsCommomHref(), param);
        window.open(eparam, 'SelectFile', 'status=1,toolbar=0,scrollbars=1,resizable=0,alwaysRaised=Yes, top=20, left=30, width=1200, height=600,1 ,align=center');
        return false;
    }
    function CheckSearch(){
        if (FromSmallToDateValue(document.getElementById('_ctl0_txtFromDate').value, document.getElementById('_ctl0_txtToDate').value) == false) {
            GetAlertError(iTotal, DSAlert, "0007");
            document.getElementById('_ctl0_txtFromDate').focus();
            return false;
        }
	    
        DisableAllButton('_ctl0:btnSearch');
        return true;
    }
    function ShowHideLuoi() {        
        if (document.getElementById('_ctl0_optPermit').checked) {
            document.getElementById("trdtgListGiayPhepLaoDong").style.display = "";
            document.getElementById("trdtgListPassport").style.display = "none";
            document.getElementById("trdtgListVisa").style.display = "none";
            document.getElementById("trdtgListTempLicence").style.display = "none";
            document.getElementById("trdtgListThueNha").style.display = "none";
            document.getElementById("divdtgListLLTP").style.display = "none"; 
        }
        else if (document.getElementById('_ctl0_optPassport').checked) {
            document.getElementById("trdtgListPassport").style.display = "";
            document.getElementById("trdtgListGiayPhepLaoDong").style.display = "none";
            document.getElementById("trdtgListVisa").style.display = "none";
            document.getElementById("trdtgListTempLicence").style.display = "none";
            document.getElementById("trdtgListThueNha").style.display = "none";
            document.getElementById("divdtgListLLTP").style.display = "none"; 
        }
        else if (document.getElementById('_ctl0_optVisa').checked) {
            document.getElementById("trdtgListVisa").style.display = "";
            document.getElementById("trdtgListPassport").style.display = "none";
            document.getElementById("trdtgListGiayPhepLaoDong").style.display = "none";
            document.getElementById("trdtgListTempLicence").style.display = "none";
            document.getElementById("trdtgListThueNha").style.display = "none";
            document.getElementById("divdtgListLLTP").style.display = "none"; 
        }
        else if (document.getElementById('_ctl0_optTempLicence').checked) {
            document.getElementById("trdtgListTempLicence").style.display = "";
            document.getElementById("trdtgListVisa").style.display = "none";
            document.getElementById("trdtgListPassport").style.display = "none";
            document.getElementById("trdtgListGiayPhepLaoDong").style.display = "none";
            document.getElementById("trdtgListThueNha").style.display = "none";
            document.getElementById("divdtgListLLTP").style.display = "none"; 
        }
        else if (document.getElementById('_ctl0_optLyLichTuPhap').checked) {
            document.getElementById("divdtgListLLTP").style.display = "";
            document.getElementById("trdtgListTempLicence").style.display = "none";
            document.getElementById("trdtgListVisa").style.display = "none";
            document.getElementById("trdtgListPassport").style.display = "none";
            document.getElementById("trdtgListGiayPhepLaoDong").style.display = "none";
            document.getElementById("trdtgListThueNha").style.display = "none";
        }
        else {
            document.getElementById("trdtgListThueNha").style.display = "";
            document.getElementById("trdtgListTempLicence").style.display = "none";
            document.getElementById("trdtgListVisa").style.display = "none";
            document.getElementById("trdtgListPassport").style.display = "none";
            document.getElementById("trdtgListGiayPhepLaoDong").style.display = "none";
            document.getElementById("divdtgListLLTP").style.display = "none"; 
        }
    }
    ShowHideLuoi();
</script>


