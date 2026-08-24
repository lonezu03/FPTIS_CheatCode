import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/common_widgets.dart';
import 'auth_session.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_next.text.length < 6 || _next.text != _confirm.text) {
      return showMessage(
        context,
        'Mật khẩu mới cần từ 6 ký tự và phần xác nhận phải trùng khớp.',
        error: true,
      );
    }
    setState(() => _busy = true);
    try {
      await context.read<AuthSession>().changePassword(
        _current.text,
        _next.text,
      );
      if (mounted) {
        showMessage(context, 'Đã đổi mật khẩu và tạo phiên đăng nhập mới.');
      }
    } catch (error) {
      if (mounted) showMessage(context, displayError(error), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Đổi mật khẩu lần đầu')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const PageIntro(
          title: 'Bảo vệ tài khoản',
          subtitle: 'Bạn cần đổi mật khẩu tạm trước khi dùng ứng dụng. Backend sẽ trả token mới sau khi đổi thành công.',
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _current,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _next,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Mật khẩu mới',
            helperText: 'Tối thiểu 6 ký tự',
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _confirm,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Nhập lại mật khẩu mới'),
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(_busy ? 'Đang đổi...' : 'Đổi mật khẩu'),
        ),
        TextButton(
          onPressed: _busy ? null : () => context.read<AuthSession>().logout(),
          child: const Text('Đăng xuất'),
        ),
      ],
    ),
  );
}
