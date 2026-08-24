import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_client.dart';
import '../../core/widgets/common_widgets.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});
  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  bool _otpSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_email.text.contains('@')) {
      return showMessage(context, 'Nhập email hợp lệ.', error: true);
    }
    setState(() => _busy = true);
    try {
      await context.read<ApiClient>().post(
        '/auth/forgot-password',
        data: {'email': _email.text.trim()},
      );
      if (mounted) {
        setState(() => _otpSent = true);
        showMessage(
          context,
          'Nếu email tồn tại, mã OTP đã được gửi đến hộp thư.',
        );
      }
    } catch (error) {
      if (mounted) showMessage(context, displayError(error), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (_otp.text.trim().isEmpty || _password.text.length < 6) {
      return showMessage(
        context,
        'Nhập OTP và mật khẩu mới từ 6 ký tự.',
        error: true,
      );
    }
    setState(() => _busy = true);
    try {
      await context.read<ApiClient>().post(
        '/auth/reset-password',
        data: {
          'email': _email.text.trim(),
          'otp': _otp.text.trim(),
          'newPassword': _password.text,
        },
      );
      if (!mounted) return;
      showMessage(context, 'Đổi mật khẩu thành công. Hãy đăng nhập lại.');
      Navigator.pop(context);
    } catch (error) {
      if (mounted) showMessage(context, displayError(error), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Khôi phục mật khẩu')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageIntro(
          title: 'Quên mật khẩu',
          subtitle: 'OTP chỉ được gửi tới đúng email đã đăng ký, không thể dùng username của người khác.',
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _email,
          enabled: !_otpSent,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email đã đăng ký'),
        ),
        if (_otpSent) ...[
          const SizedBox(height: 14),
          TextField(
            controller: _otp,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Mã OTP',
              helperText: 'Nhập mã nhận được trong email',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
          ),
        ],
        const SizedBox(height: 22),
        FilledButton(
          onPressed: _busy ? null : (_otpSent ? _reset : _sendOtp),
          child: Text(
            _busy
                ? 'Đang xử lý...'
                : (_otpSent ? 'Đặt lại mật khẩu' : 'Gửi mã OTP'),
          ),
        ),
        if (_otpSent)
          TextButton(
            onPressed: _busy ? null : _sendOtp,
            child: const Text('Gửi lại OTP'),
          ),
      ],
    ),
  );
}
