import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/common_widgets.dart';
import 'auth_session.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final result = await context.read<AuthSession>().register({
        'fullName': _name.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
      });
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.mark_email_read_outlined, size: 42),
          title: const Text('Kiểm tra email'),
          content: Text(
            result['message']?.toString() ?? 'Tài khoản đã được tạo. Hãy mở email để xác thực trước khi đăng nhập.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) showMessage(context, displayError(error), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tạo tài khoản')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PageIntro(
                  title: 'Bắt đầu cùng FitTrack',
                  subtitle: 'Tài khoản mới mặc định chỉ được dùng module đặt cơm. Admin có thể cấp thêm quyền sau.',
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',
                    helperText: 'Tên hiển thị trong danh sách đặt cơm',
                  ),
                  validator: (v) => v == null || v.trim().length < 2
                      ? 'Nhập họ và tên'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    helperText: 'Email dùng để xác thực và khôi phục mật khẩu',
                  ),
                  validator: (v) => v == null || !v.contains('@')
                      ? 'Nhập email hợp lệ'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu',
                    helperText: 'Tối thiểu 6 ký tự',
                  ),
                  validator: (v) => v == null || v.length < 6
                      ? 'Mật khẩu cần ít nhất 6 ký tự'
                      : null,
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(_busy ? 'Đang tạo...' : 'Đăng ký'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
