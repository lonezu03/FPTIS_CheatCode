import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../auth/auth_session.dart';

Future<void> showUserGuideSheet(BuildContext context, AuthUser user) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => FractionallySizedBox(
      heightFactor: .94,
      child: UserGuideSheet(user: user),
    ),
  );
}

class UserGuideSheet extends StatefulWidget {
  const UserGuideSheet({super.key, required this.user});

  final AuthUser user;

  @override
  State<UserGuideSheet> createState() => _UserGuideSheetState();
}

class _UserGuideSheetState extends State<UserGuideSheet> {
  String selectedId = 'overview';
  int stepIndex = 0;

  List<_GuideModule> get modules => _guideModules
      .where((module) => module.isAvailable(widget.user))
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = modules;
    final module = available.firstWhere(
      (item) => item.id == selectedId,
      orElse: () => available.first,
    );
    final step = module.steps[math.min(stepIndex, module.steps.length - 1)];

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: 42,
            height: 4,
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 8, 10),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  child: const Icon(Icons.help_outline_rounded),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hướng dẫn sử dụng FitTrack',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Nội dung được lọc theo quyền tài khoản của bạn.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Đóng',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 58,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              scrollDirection: Axis.horizontal,
              itemCount: available.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = available[index];
                final selected = item.id == module.id;
                return ChoiceChip(
                  selected: selected,
                  avatar: Icon(item.icon, size: 17),
                  label: Text(item.title),
                  onSelected: (_) => setState(() {
                    selectedId = item.id;
                    stepIndex = 0;
                  }),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${module.title.toUpperCase()} · BƯỚC ${stepIndex + 1}/${module.steps.length}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .7,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _GuideIllustration(
                    visual: step.visual,
                    focusLabel: step.focusLabel,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    step.description,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: .48,
                      ),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: .24),
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 19,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Thao tác: ',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                                TextSpan(text: step.action),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: stepIndex == 0
                      ? null
                      : () => setState(() => stepIndex -= 1),
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Trước'),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    module.steps.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: index == stepIndex ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: index == stepIndex
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                if (stepIndex < module.steps.length - 1)
                  FilledButton.icon(
                    onPressed: () => setState(() => stepIndex += 1),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('Tiếp'),
                  )
                else
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đã hiểu'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _GuidePermission { lunch, fitness, health, todo, schedule, admin }

class _GuideModule {
  const _GuideModule({
    required this.id,
    required this.title,
    required this.icon,
    required this.steps,
    this.permission,
  });

  final String id;
  final String title;
  final IconData icon;
  final _GuidePermission? permission;
  final List<_GuideStep> steps;

  bool isAvailable(AuthUser user) {
    if (permission == null) return true;
    if (user.isAdmin) return true;
    return switch (permission!) {
      _GuidePermission.lunch => user.lunchEnabled,
      _GuidePermission.fitness => user.fitnessEnabled,
      _GuidePermission.health => user.healthEnabled,
      _GuidePermission.todo => user.todoEnabled,
      _GuidePermission.schedule => user.scheduleEnabled,
      _GuidePermission.admin => false,
    };
  }
}

class _GuideStep {
  const _GuideStep({
    required this.title,
    required this.description,
    required this.action,
    required this.visual,
    required this.focusLabel,
  });

  final String title;
  final String description;
  final String action;
  final _GuideVisual visual;
  final String focusLabel;
}

enum _GuideVisual {
  navigation,
  lunch,
  todo,
  schedule,
  fitness,
  health,
  notifications,
  profile,
  admin,
}

const _guideModules = <_GuideModule>[
  _GuideModule(
    id: 'overview',
    title: 'Bắt đầu',
    icon: Icons.dashboard_outlined,
    steps: [
      _GuideStep(
        title: 'Chọn chức năng từ thanh điều hướng',
        description: 'Thanh dưới chỉ hiển thị các module tài khoản đã được cấp. Các mục ít dùng nằm trong “Thêm”. Nếu thiếu quyền, hãy liên hệ quản trị viên.',
        action: 'Nhấn biểu tượng module; dùng “Thêm” để mở phần còn lại.',
        visual: _GuideVisual.navigation,
        focusLabel: 'Thanh chức năng',
      ),
      _GuideStep(
        title: 'Tổng quan được cá nhân hóa theo quyền',
        description: 'Màn Tổng quan chỉ tổng hợp dữ liệu bạn được phép dùng. Thẻ trống sẽ chỉ rõ dữ liệu nào cần bổ sung thay vì tính thành số 0.',
        action: 'Nhấn thẻ hoặc gợi ý để mở chức năng liên quan.',
        visual: _GuideVisual.health,
        focusLabel: 'Thẻ tổng quan',
      ),
    ],
  ),
  _GuideModule(
    id: 'lunch',
    title: 'Đặt cơm',
    icon: Icons.lunch_dining_outlined,
    permission: _GuidePermission.lunch,
    steps: [
      _GuideStep(
        title: 'Chọn menu và đúng người nhận',
        description: 'Nếu có nhiều quán, chọn menu trước. Có thể đặt cho bản thân hoặc đồng nghiệp; người nhận là người được trừ quỹ hoặc ghi công nợ.',
        action: 'Kiểm tra menu và người nhận trước khi chọn món.',
        visual: _GuideVisual.lunch,
        focusLabel: 'Menu & người nhận',
      ),
      _GuideStep(
        title: 'Chọn đủ món cho từng phần',
        description: 'Cơm thường cần đúng 2 món phía trên dấu + và có thể chọn trùng. Món đơn chỉ cần 1 món phía dưới dấu +. Món thêm được cộng theo giá.',
        action: 'Chọn món rồi nhấn “Thêm phần vào giỏ”.',
        visual: _GuideVisual.lunch,
        focusLabel: 'Vùng chọn món',
      ),
      _GuideStep(
        title: 'Kiểm tra giỏ trước khi đặt',
        description: 'Bạn có thể đặt nhiều phần cùng lúc. Thiếu quỹ không chặn đặt món; quỹ còn lại được dùng trước, phần thiếu ghi vào công nợ người nhận.',
        action: 'Đọc lại người nhận, món, món thêm và tổng tiền.',
        visual: _GuideVisual.lunch,
        focusLabel: 'Giỏ đặt cơm',
      ),
    ],
  ),
  _GuideModule(
    id: 'todo',
    title: 'Việc cần làm',
    icon: Icons.checklist_outlined,
    permission: _GuidePermission.todo,
    steps: [
      _GuideStep(
        title: 'Phân biệt bắt đầu, hạn chót và nhắc nhở',
        description: 'Ba mốc này độc lập. Điền đúng giúp ứng dụng phân loại Hôm nay, Sắp tới và Quá hạn chính xác.',
        action: 'Nhập nội dung, các mốc thời gian, danh mục rồi lưu.',
        visual: _GuideVisual.todo,
        focusLabel: 'Mốc thời gian',
      ),
      _GuideStep(
        title: 'Dùng checklist và việc lặp lại',
        description: 'Chia việc lớn thành các việc con. Khi hoàn thành việc lặp lại, lần hiện tại vẫn được giữ và ứng dụng tạo lần kế tiếp.',
        action: 'Đánh dấu việc con rồi hoàn thành hoặc bỏ qua lần này.',
        visual: _GuideVisual.todo,
        focusLabel: 'Checklist',
      ),
    ],
  ),
  _GuideModule(
    id: 'schedule',
    title: 'Thời khóa biểu',
    icon: Icons.calendar_month_outlined,
    permission: _GuidePermission.schedule,
    steps: [
      _GuideStep(
        title: 'Chọn chế độ Ngày, Tuần hoặc Tháng',
        description: 'Lịch hiển thị sự kiện và cả Todo có thời gian. Chọn góc nhìn phù hợp để tránh bỏ sót lịch.',
        action: 'Đổi chế độ xem rồi chuyển tới ngày cần kiểm tra.',
        visual: _GuideVisual.schedule,
        focusLabel: 'Chế độ xem',
      ),
      _GuideStep(
        title: 'Chỉ tạo lịch hẹn ở Thời khóa biểu',
        description: 'Todo có giờ sẽ tự xuất hiện trên lịch. Không cần tạo trùng Todo thành một sự kiện mới.',
        action: 'Tạo sự kiện, đặt giờ bắt đầu/kết thúc và nhắc trước.',
        visual: _GuideVisual.schedule,
        focusLabel: 'Sự kiện',
      ),
    ],
  ),
  _GuideModule(
    id: 'fitness',
    title: 'Rèn luyện',
    icon: Icons.fitness_center_outlined,
    permission: _GuidePermission.fitness,
    steps: [
      _GuideStep(
        title: 'Xem kỹ bài tập trước khi dùng',
        description: 'Kho bài tập có nhóm cơ, dụng cụ, mô tả và ảnh. Bài do người dùng thêm cần admin duyệt trước khi dùng chung.',
        action: 'Mở bài tập để xem ảnh và hướng dẫn kỹ thuật.',
        visual: _GuideVisual.fitness,
        focusLabel: 'Chi tiết bài tập',
      ),
      _GuideStep(
        title: 'Tạo giáo án theo từng ngày',
        description: 'Mỗi ngày có danh sách bài, số hiệp, lần lặp, mức tạ và RIR. Kiểm tra ảnh để tránh chọn nhầm bài cùng tên.',
        action: 'Thêm ngày, chọn bài và nhập mục tiêu từng bài.',
        visual: _GuideVisual.fitness,
        focusLabel: 'Mục tiêu bài tập',
      ),
      _GuideStep(
        title: 'Ghi dữ liệu tập thực tế',
        description: 'Hãy lưu từng hiệp thực hiện để lịch sử, thành tích và báo cáo phản ánh đúng tiến độ thay vì chỉ dựa vào giáo án.',
        action: 'Bắt đầu buổi tập, ghi từng hiệp rồi hoàn thành.',
        visual: _GuideVisual.fitness,
        focusLabel: 'Hiệp đang tập',
      ),
    ],
  ),
  _GuideModule(
    id: 'health',
    title: 'Sức khỏe',
    icon: Icons.favorite_outline,
    permission: _GuidePermission.health,
    steps: [
      _GuideStep(
        title: 'Ghi đúng lượng thực phẩm',
        description: 'Chọn khẩu phần, gram hoặc ml. Gram/ml cần thông tin khối lượng khẩu phần để quy đổi chính xác.',
        action: 'Thêm món đúng bữa, nhập lượng và kiểm tra dinh dưỡng.',
        visual: _GuideVisual.health,
        focusLabel: 'Bữa ăn & số lượng',
      ),
      _GuideStep(
        title: 'Xác nhận trạng thái cuối ngày',
        description: 'Ngày mới ghi một phần chưa được dùng cho điểm sức khỏe. Chỉ ngày Hoàn tất hoặc Nhịn ăn mới tham gia thống kê tin cậy.',
        action: 'Rà soát nhật ký rồi xác nhận trạng thái ngày.',
        visual: _GuideVisual.health,
        focusLabel: 'Trạng thái ngày',
      ),
      _GuideStep(
        title: 'Theo dõi xu hướng dài hạn',
        description: 'Cập nhật chỉ số cơ thể đều đặn và chú ý mức độ tin cậy của báo cáo. Dữ liệu thiếu không bị hiểu là bằng 0.',
        action: 'Đọc biểu đồ xu hướng thay vì kết luận từ một lần đo.',
        visual: _GuideVisual.health,
        focusLabel: 'Biểu đồ xu hướng',
      ),
    ],
  ),
  _GuideModule(
    id: 'notifications',
    title: 'Thông báo',
    icon: Icons.notifications_outlined,
    steps: [
      _GuideStep(
        title: 'Theo dõi tin chưa đọc',
        description: 'Thông báo có thể liên quan đến menu, chốt đơn, thanh toán, lời nhắc hoặc yêu cầu quyền. Huy hiệu cho biết số tin chưa đọc.',
        action: 'Mở Thông báo và nhấn nội dung cần xử lý.',
        visual: _GuideVisual.notifications,
        focusLabel: 'Tin chưa đọc',
      ),
      _GuideStep(
        title: 'Cho phép thông báo trên thiết bị',
        description: 'Nếu chưa thấy hộp xin quyền, vào Thêm → Quyền ứng dụng → Thông báo. Bạn có thể bật âm thanh trong cài đặt Android.',
        action: 'Nhấn “Cho phép” hoặc mở Cài đặt của hệ thống.',
        visual: _GuideVisual.profile,
        focusLabel: 'Quyền thông báo',
      ),
    ],
  ),
  _GuideModule(
    id: 'profile',
    title: 'Cá nhân',
    icon: Icons.person_outline,
    steps: [
      _GuideStep(
        title: 'Kiểm tra hồ sơ và quyền module',
        description: 'Hồ sơ hiển thị các module tài khoản đang được dùng. Liên hệ quản trị viên nếu quyền chưa đúng với nhu cầu công việc.',
        action: 'Mở Cá nhân để kiểm tra thông tin và đăng xuất an toàn.',
        visual: _GuideVisual.profile,
        focusLabel: 'Danh sách quyền',
      ),
    ],
  ),
  _GuideModule(
    id: 'admin',
    title: 'Quản trị',
    icon: Icons.admin_panel_settings_outlined,
    permission: _GuidePermission.admin,
    steps: [
      _GuideStep(
        title: 'Cấp đúng quyền cho tài khoản',
        description: 'Tài khoản mới chỉ có Đặt cơm. Admin bật từng module theo nhu cầu, kiểm tra trạng thái và vai trò trước khi lưu.',
        action: 'Tìm đúng người dùng rồi bật các quyền được phê duyệt.',
        visual: _GuideVisual.admin,
        focusLabel: 'Công tắc quyền',
      ),
      _GuideStep(
        title: 'Điều phối menu cơm',
        description: 'Import menu, kiểm tra món, giá, ảnh và giờ chốt trước khi gửi thông báo. Cuối phiên hãy tổng hợp đúng menu/quán.',
        action: 'Kiểm tra menu rồi mới mở nhận đơn và thông báo.',
        visual: _GuideVisual.lunch,
        focusLabel: 'Quy trình menu',
      ),
      _GuideStep(
        title: 'Gửi thông báo đúng người',
        description: 'Nội dung cá nhân hoặc nhạy cảm nên chọn người nhận cụ thể. Chỉ gửi toàn bộ khi áp dụng cho mọi tài khoản active.',
        action: 'Xem lại đối tượng, nội dung và thời điểm trước khi gửi.',
        visual: _GuideVisual.admin,
        focusLabel: 'Nhóm nhận tin',
      ),
    ],
  ),
];

class _GuideIllustration extends StatelessWidget {
  const _GuideIllustration({required this.visual, required this.focusLabel});

  final _GuideVisual visual;
  final String focusLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1.6,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.surfaceContainerLow, colors.primaryContainer],
          ),
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 34, 14, 14),
                child: _MockScreen(visual: visual),
              ),
            ),
            Positioned(
              left: 12,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: .92),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  'ẢNH MINH HỌA',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _ArrowPainter(colors.tertiary)),
              ),
            ),
            Positioned(
              right: 17,
              bottom: 18,
              child: IgnorePointer(
                child: Container(
                  width: 74,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: colors.tertiary, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: colors.tertiary.withValues(alpha: .22),
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 9,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 145),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.tertiary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(blurRadius: 8, color: Colors.black26),
                  ],
                ),
                child: Text(
                  focusLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockScreen extends StatelessWidget {
  const _MockScreen({required this.visual});

  final _GuideVisual visual;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final (title, icon, rows) = switch (visual) {
      _GuideVisual.navigation => (
        'Thanh chức năng',
        Icons.apps_outlined,
        ['Tổng quan', 'Đặt cơm', 'Rèn luyện'],
      ),
      _GuideVisual.lunch => (
        'Giỏ đặt cơm',
        Icons.lunch_dining_outlined,
        ['Chọn menu & người nhận', 'Chọn đủ món', 'Xác nhận tổng tiền'],
      ),
      _GuideVisual.todo => (
        'Việc hôm nay',
        Icons.checklist,
        ['Chuẩn bị báo cáo', 'Họp lúc 15:00', 'Tập luyện'],
      ),
      _GuideVisual.schedule => (
        'Lịch tuần',
        Icons.calendar_month_outlined,
        ['Thứ Hai · Họp nhóm', 'Thứ Tư · Khám sức khỏe', 'Thứ Sáu · Báo cáo'],
      ),
      _GuideVisual.fitness => (
        'Buổi tập',
        Icons.fitness_center,
        ['Nhóm cơ & dụng cụ', '3 hiệp · 10 lần', '20 kg · RIR 2'],
      ),
      _GuideVisual.health => (
        'Sức khỏe hôm nay',
        Icons.favorite_outline,
        ['1.850 kcal', '102 g chất đạm', '1,8 lít nước'],
      ),
      _GuideVisual.notifications => (
        'Thông báo',
        Icons.notifications_outlined,
        ['Menu trưa đã mở', 'Nhắc lịch 15:00', 'Thanh toán đã duyệt'],
      ),
      _GuideVisual.profile => (
        'Quyền tài khoản',
        Icons.person_outline,
        ['Đặt cơm · Đã bật', 'Rèn luyện · Đã bật', 'Sức khỏe · Chưa bật'],
      ),
      _GuideVisual.admin => (
        'Quản trị',
        Icons.admin_panel_settings_outlined,
        ['Chọn người dùng', 'Bật quyền module', 'Kiểm tra & lưu'],
      ),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: color.withValues(alpha: .12),
                foregroundColor: color,
                child: Icon(icon, size: 17),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ...rows.asMap().entries.map(
            (entry) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              decoration: BoxDecoration(
                color: entry.key == 0
                    ? color.withValues(alpha: .1)
                    : Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(entry.value, style: const TextStyle(fontSize: 10)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final start = Offset(size.width - 58, 40);
    final end = Offset(size.width - 52, size.height - 70);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        size.width - 105,
        size.height * .34,
        size.width - 28,
        size.height * .58,
        end.dx,
        end.dy,
      );
    canvas.drawPath(path, paint);
    canvas.drawLine(end, Offset(end.dx - 10, end.dy - 9), paint);
    canvas.drawLine(end, Offset(end.dx + 7, end.dy - 11), paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) =>
      oldDelegate.color != color;
}
