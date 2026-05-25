<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="TongHopPhanBoChiPhiTheoCostCenter_CustomerID163.ascx.cs" Inherits="Projects.PMC.Form.TongHopPhanBoChiPhiTheoCostCenter_CustomerID163" %>
<%@ Register TagPrefix="telerik" Namespace="Telerik.Web.UI" Assembly="Telerik.Web.UI" %>
<%@ Register Assembly="Common" Namespace="iHRPCore.Com" TagPrefix="core" %>

<div class="contentForm">
    <div class="contentGroup">
        <div class="contentFormItem half" id="divMonth" runat="server">
            <div class="contentFormLabel">
                <asp:Label ID="lblMonth" CssClass="labelRequire" runat="server">Tháng hiệu lực</asp:Label>
            </div>
            <div class="contentFormControl">
                <telerik:RadComboBox ID="cboMonth" runat="server" Skin="Simple" Width="80px" Filter="Contains" MarkFirstMatch="true" />
            </div>
        </div>
        <div class="contentFormItem half">
            <div class="contentFormLabel">
                <asp:Label ID="lblCostCenter" runat="Server" CssClass="label">Cost Center</asp:Label>
            </div>
            <div class="contentFormControl">
                <telerik:RadComboBox ID="cboLSCostCenterID" runat="server" Skin="Simple" Width="100%" Filter="Contains" MarkFirstMatch="true" />
            </div>
        </div>
        <div class="contentFormItem half">
            <div class="contentFormLabel">
                <asp:Label ID="lblTinhTrang" runat="server" CssClass="label">Tình trạng</asp:Label>
            </div>
            <div class="contentFormControl">
                <asp:RadioButtonList ID="rbtTinhTrang" runat="server" RepeatDirection="Horizontal" CssClass="RadioCss100">
                    <asp:ListItem Value="0" Selected="True">Chưa chuyển</asp:ListItem>
                    <asp:ListItem Value="1">Đã chuyển</asp:ListItem>
                    <asp:ListItem Value="2">Tất cả</asp:ListItem>
                </asp:RadioButtonList>
            </div>
        </div>
        <div class="contentFormItem half">
            <div class="contentFormLabel">
                <asp:Label ID="lbl2" CssClass="label" runat="server">Loại nhân viên</asp:Label>
            </div>
            <div class="contentFormControl">
                <telerik:RadComboBox ID="cboLSLoaiNhanVien" runat="server" Skin="Simple" Width="100%"
                    OnClientSelectedIndexChanged="chkComboChangeSelect_Search" Filter="Contains" EnableLoadOnDemand="true">
                    <ItemTemplate>
                        <asp:CheckBox runat="server" ID="chkSelectItem" Text='<%#Eval("Name")%>' onclick="chkComboShowSelectedItem('cboLSLoaiNhanVien')" />
                    </ItemTemplate>
                    <FooterTemplate>
                        <asp:CheckBox runat="server" ID="chkSelectAll" Text='All' onclick="chkComboSelectAllCombo(this, 'cboLSLoaiNhanVien')" />
                    </FooterTemplate>
                </telerik:RadComboBox>
            </div>
        </div>

        <div class="contentGroup">
            <div class="contentFormItem full">
                <hr />
            </div>

            <div class="contentFormItem full">
                <table style="width: 100%">
                    <tr>
                        <td align="center">
                            <span class="btn1">
                                <asp:LinkButton ID="btnSearch" name="btnSearch" runat="server" OnClick="btnSearch_Click" OnClientClick="return CheckSearch();">
                                <span class="btnSearch">Tìm kiếm</span>
                                </asp:LinkButton>
                                <asp:LinkButton ID="btnReset" name="btnReset" runat="server" OnClick="btnReset_Click">
                                <span class="btnReset">Làm mới</span>
                                </asp:LinkButton>
                                <asp:LinkButton ID="btnCreate" name="btnCreate" runat="server" OnClick="btnCreate_Click" OnClientClick="return CheckCreate();">
                                <span class="btnCreate">Tổng hợp</span>
                                </asp:LinkButton>
                                <asp:LinkButton ID="btnExport" name="btnExport" AccessKey="E" ToolTip="ALT+E" runat="server" OnClick="btnExport_Click">
                                <span class="btnExport">Xuất DL</span>
                                </asp:LinkButton>
                                <asp:LinkButton ID="btnTransfer" name="btnTransfer" AccessKey="F" runat="server" ToolTip="ALT+F" OnClick="btnTransfer_Click" OnClientClick="return CheckTransfer();">
                                <span class="btnSearch">Chuyển SAP</span>
                                </asp:LinkButton>
                            </span>
                        </td>
                    </tr>
                </table>
            </div>


            <div class="gridHolder">
                <telerik:RadSplitter ID="RadSplitter1" Width="100%" runat="server" Orientation="Horizontal" Height="100%">
                    <telerik:RadPane ID="gridPane" Height="500px" runat="server" Scrolling="None">
                        <core:iHRPCoreGrid ID="dtgList" GridLines="None" Height="500px" Width="100%"
                            AutoGenerateColumns="false" AllowPaging="true" runat="server"
                            OnNeedDataSource="dtgList_NeedDataSource"
                            PageSize="15" Skin="Office2007" ShowStatusBar="true" AllowSorting="true">
                            <PagerStyle Mode="NextPrevNumericAndAdvanced" AlwaysVisible="true" />
                            <MasterTableView TableLayout="Fixed" Width="100%" CommandItemDisplay="Top" AllowMultiColumnSorting="true" GroupLoadMode="Client">
                                <CommandItemTemplate>
                                    <asp:ImageButton ID="btnConfig" runat="server" ToolTip="Setting" CommandName="ConfigRadGrid" Width="10px" Height="10px" ImageUrl="~/Images/ConfigIcon.jpg" />
                                </CommandItemTemplate>
                                <Columns>
                                    <telerik:GridTemplateColumn UniqueName="Seq" DataField="" HeaderText="Seq">
                                        <HeaderStyle Width="40px" HorizontalAlign="Center" VerticalAlign="Middle" />
                                        <ItemStyle HorizontalAlign="Center" />
                                        <ItemTemplate>
                                            <asp:Literal ID="glblItemSeqName" runat="server"
                                                Text='<%# Container.ItemIndex + 1 + dtgList.PageSize * dtgList.CurrentPageIndex%>' />
                                        </ItemTemplate>
                                    </telerik:GridTemplateColumn>
                                    <telerik:GridBoundColumn SortExpression="PRMonth" UniqueName="PRMonth" DataField="PRMonth" HeaderText="Tháng">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                        <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>

                                    <telerik:GridBoundColumn SortExpression="CostCenter" UniqueName="CostCenter" DataField="CostCenter" HeaderText="Cost center">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                        <ItemStyle HorizontalAlign="Left" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>

                                    <telerik:GridBoundColumn SortExpression="TT_TienCom" UniqueName="TT_TienCom" DataField="TT_TienCom" HeaderText="TT_TienCom" DataFormatString="{0:#,###.##}">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                        <ItemStyle HorizontalAlign="Right" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>
                                    <telerik:GridBoundColumn SortExpression="TT_TienXangThang" UniqueName="TT_TienXangThang" DataField="TT_TienXangThang" HeaderText="TT_TienXangThang" DataFormatString="{0:#,###.##}">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                        <ItemStyle HorizontalAlign="Right" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>
                                    <telerik:GridBoundColumn SortExpression="Add52_3" UniqueName="Add52_3" DataField="Add52_3" HeaderText="Add52_3" DataFormatString="{0:#,###.##}">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                        <ItemStyle HorizontalAlign="Right" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>
                                    <telerik:GridBoundColumn SortExpression="Add15_3" UniqueName="Add15_3" DataField="Add15_3" HeaderText="Add15_3" DataFormatString="{0:#,###.##}">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                        <ItemStyle HorizontalAlign="Right" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>
                                    <telerik:GridBoundColumn SortExpression="Add53_3" UniqueName="Add53_3" DataField="Add53_3" HeaderText="Add53_3" DataFormatString="{0:#,###.##}">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                        <ItemStyle HorizontalAlign="Right" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>
                                    <telerik:GridBoundColumn SortExpression="Add39_3" UniqueName="Add39_3" DataField="Add39_3" HeaderText="Add39_3" DataFormatString="{0:#,###.##}">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                        <ItemStyle HorizontalAlign="Right" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>
                                    <telerik:GridBoundColumn SortExpression="Add54_3" UniqueName="Add54_3" DataField="Add54_3" HeaderText="Add54_3" DataFormatString="{0:#,###.##}">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                        <ItemStyle HorizontalAlign="Right" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>
                                    <telerik:GridBoundColumn SortExpression="Add55_3" UniqueName="Add55_3" DataField="Add55_3" HeaderText="Add55_3" DataFormatString="{0:#,###.##}">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                        <ItemStyle HorizontalAlign="Right" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>
                                    <telerik:GridBoundColumn SortExpression="SIEmp" UniqueName="SIEmp" DataField="SIEmp" HeaderText="SIEmp" DataFormatString="{0:#,###.##}">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                        <ItemStyle HorizontalAlign="Right" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>
                                    <telerik:GridBoundColumn SortExpression="HIEmp" UniqueName="HIEmp" DataField="HIEmp" HeaderText="HIEmp" DataFormatString="{0:#,###.##}">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                        <ItemStyle HorizontalAlign="Right" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>
                                    <telerik:GridBoundColumn SortExpression="UIEmp" UniqueName="UIEmp" DataField="UIEmp" HeaderText="UIEmp" DataFormatString="{0:#,###.##}">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                        <ItemStyle HorizontalAlign="Right" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>
                                    <telerik:GridBoundColumn SortExpression="TT_DoanPhi" UniqueName="TT_DoanPhi" DataField="TT_DoanPhi" HeaderText="TT_DoanPhi" DataFormatString="{0:#,###.##}">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                        <ItemStyle HorizontalAlign="Right" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>
                                    <telerik:GridBoundColumn SortExpression="TaxLiability" UniqueName="TaxLiability" DataField="TaxLiability" HeaderText="TaxLiability" DataFormatString="{0:#,###.##}">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                        <ItemStyle HorizontalAlign="Right" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>
                                    <telerik:GridBoundColumn SortExpression="HT_TroCapThoiViec" UniqueName="HT_TroCapThoiViec" DataField="HT_TroCapThoiViec" HeaderText="HT_TroCapThoiViec" DataFormatString="{0:#,###.##}">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                        <ItemStyle HorizontalAlign="Right" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>
                                    <telerik:GridBoundColumn SortExpression="HT_TroCapThoiViec_2" UniqueName="HT_TroCapThoiViec_2" DataField="HT_TroCapThoiViec_2" HeaderText="HT_TroCapThoiViec_2" DataFormatString="{0:#,###.##}">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                        <ItemStyle HorizontalAlign="Right" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>
                                    <telerik:GridBoundColumn SortExpression="HT_TruyThuTheBHYT" UniqueName="HT_TruyThuTheBHYT" DataField="HT_TruyThuTheBHYT" HeaderText="HT_TruyThuTheBHYT">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="90px" />
                                        <ItemStyle HorizontalAlign="Left" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>
                                    <telerik:GridBoundColumn SortExpression="SICom" UniqueName="SICom" DataField="SICom" HeaderText="SICom" DataFormatString="{0:#,###.##}">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                        <ItemStyle HorizontalAlign="Right" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>
                                    <telerik:GridBoundColumn SortExpression="TT_BHTN_BNN" UniqueName="TT_BHTN_BNN" DataField="TT_BHTN_BNN" HeaderText="TT_BHTN_BNN" DataFormatString="{0:#,###.##}">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                        <ItemStyle HorizontalAlign="Right" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>
                                    <telerik:GridBoundColumn SortExpression="HICom" UniqueName="HICom" DataField="HICom" HeaderText="HICom" DataFormatString="{0:#,###.##}">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                        <ItemStyle HorizontalAlign="Right" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>
                                    <telerik:GridBoundColumn SortExpression="UICom" UniqueName="UICom" DataField="UICom" HeaderText="UICom" DataFormatString="{0:#,###.##}">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="50px" />
                                        <ItemStyle HorizontalAlign="Right" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>
                                    <telerik:GridBoundColumn SortExpression="TT_KinhPhiCongDoan" UniqueName="TT_KinhPhiCongDoan" DataField="TT_KinhPhiCongDoan" HeaderText="TT_KinhPhiCongDoan">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="90px" />
                                        <ItemStyle HorizontalAlign="Left" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>

                                    <%--TriTV 11-12-2025 RLog 24957--%>
                                    <telerik:GridBoundColumn SortExpression="BHYT_NVDC" UniqueName="BHYT_NVDC" DataField="BHYT_NVDC" HeaderText="BHYT_NVDC">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="90px" />
                                        <ItemStyle HorizontalAlign="Left" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>
                                    <telerik:GridBoundColumn SortExpression="BHXH_NVDC" UniqueName="BHXH_NVDC" DataField="BHXH_NVDC" HeaderText="BHXH_NVDC">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="90px" />
                                        <ItemStyle HorizontalAlign="Left" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>
                                    <telerik:GridBoundColumn SortExpression="BHTN_NVDC" UniqueName="BHTN_NVDC" DataField="BHTN_NVDC" HeaderText="BHTN_NVDC">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="90px" />
                                        <ItemStyle HorizontalAlign="Left" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>
                                    <telerik:GridBoundColumn SortExpression="DoanPhi_NVDC" UniqueName="DoanPhi_NVDC" DataField="DoanPhi_NVDC" HeaderText="DoanPhi_NVDC">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="90px" />
                                        <ItemStyle HorizontalAlign="Left" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>
                                    <telerik:GridBoundColumn SortExpression="BHYT_CTDC" UniqueName="BHYT_CTDC" DataField="BHYT_CTDC" HeaderText="BHYT_CTDC">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="90px" />
                                        <ItemStyle HorizontalAlign="Left" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>
                                    <telerik:GridBoundColumn SortExpression="BHXH_CTDC" UniqueName="BHXH_CTDC" DataField="BHXH_CTDC" HeaderText="BHXH_CTDC">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="90px" />
                                        <ItemStyle HorizontalAlign="Left" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>
                                    <telerik:GridBoundColumn SortExpression="BHTN_CTDC" UniqueName="BHTN_CTDC" DataField="BHTN_CTDC" HeaderText="BHTN_CTDC">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="90px" />
                                        <ItemStyle HorizontalAlign="Left" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>
                                    <telerik:GridBoundColumn SortExpression="DoanPhi_CTDC" UniqueName="DoanPhi_CTDC" DataField="DoanPhi_CTDC" HeaderText="DoanPhi_CTDC">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="90px" />
                                        <ItemStyle HorizontalAlign="Left" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>
                                    <%--End TriTV 11-12-2025 RLog 24957--%>

                                    <telerik:GridBoundColumn SortExpression="ChuyenSAP" UniqueName="ChuyenSAP" DataField="ChuyenSAP" HeaderText="ChuyenSAP">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="90px" />
                                        <ItemStyle HorizontalAlign="Left" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>

                                    <telerik:GridBoundColumn SortExpression="ResponseAPI" UniqueName="ResponseAPI" DataField="ResponseAPI" HeaderText="Kết quả tích hợp">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="90px" />
                                        <ItemStyle HorizontalAlign="Left" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>

                                    <telerik:GridBoundColumn SortExpression="NgayTichHop" UniqueName="NgayTichHop" DataField="NgayTichHop" HeaderText="Thời gian tích hợp" DataFormatString="{0:dd/MM/yyyy HH:mm:ss}">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="90px" />
                                        <ItemStyle HorizontalAlign="Left" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>

                                    <%--  --%>
                                    <telerik:GridBoundColumn SortExpression="Creater" UniqueName="Creater" DataField="Creater" HeaderText="Người tạo" Visible="false">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                        <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>
                                    <telerik:GridBoundColumn SortExpression="CreateTime" UniqueName="CreateTime" DataField="CreateTime" HeaderText="Ngày tạo"
                                        DataFormatString="{0:dd/MM/yyyy HH:mm:ss}" Visible="false">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="80px" />
                                        <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>
                                    <telerik:GridBoundColumn SortExpression="Editer" UniqueName="Editer" DataField="Editer" HeaderText="Người sửa" Visible="false">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="100px" />
                                        <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>
                                    <telerik:GridBoundColumn SortExpression="EditTime" UniqueName="EditTime" DataField="EditTime" HeaderText="Ngày sửa"
                                        DataFormatString="{0:dd/MM/yyyy HH:mm:ss}" Visible="false">
                                        <HeaderStyle HorizontalAlign="Center" VerticalAlign="Middle" Width="80px" />
                                        <ItemStyle HorizontalAlign="Center" VerticalAlign="Middle" />
                                    </telerik:GridBoundColumn>

                                    <telerik:GridBoundColumn UniqueName="PRTongHopPhanBoChiPhiTheoCostCenterID" DataField="PRTongHopPhanBoChiPhiTheoCostCenterID" Visible="false" />
                                    <telerik:GridBoundColumn UniqueName="LSCostCenterID" DataField="LSCostCenterID" Visible="false" />
                                </Columns>
                            </MasterTableView>
                            <HeaderStyle Width="100%" />
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
</div>
<script type="text/javascript">
    function CheckSearch() {
        if (CheckIsNull_RCB("cboMonth", "0003") == false) return false;

        return true;
    }

    function CheckCreate() {
        if (CheckIsNull_RCB("cboMonth", "0003") == false) return false;

        return true;
    }

    function CheckTransfer() {
        if (CheckIsNull_RCB("cboMonth", "0003") == false) return false;

        return true;
    }

    function allReady() {
        chkComboShowSelectedItem("cboLSLoaiNhanVien");
    }

    function chkComboChangeSelect_Search(sender, eventArgs) {
        chkComboShowSelectedItem('cboLSLoaiNhanVien');
    }
</script>
