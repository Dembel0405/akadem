import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _sent = false;
  bool _loading = false;
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    setState(() {
      _emailError = email.isEmpty ? 'Введите email' : null;
    });
    if (_emailError != null) return;

    setState(() => _loading = true);
    // Имитируем запрос — реальный запрос к API добавить при реализации модуля
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _loading = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray700),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _sent ? _buildSuccessState() : _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.lightBlue,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.lock_reset_outlined, size: 32, color: AppColors.primaryBlue),
        ),
        const SizedBox(height: 24),
        Text('Восстановление пароля', style: AppTextStyles.h2, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Введите email — мы отправим ссылку для сброса пароля',
          style: AppTextStyles.body.copyWith(color: AppColors.gray500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Column(
            children: [
              AppTextField(
                label: 'Email',
                hint: 'example@college.kz',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                errorText: _emailError,
                prefixIcon: const Icon(Icons.email_outlined, size: 20, color: AppColors.gray500),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Отправить ссылку',
                onPressed: _submit,
                loading: _loading,
                fullWidth: true,
                size: AppButtonSize.large,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.check_circle_outline, size: 32, color: AppColors.success),
        ),
        const SizedBox(height: 24),
        Text('Ссылка отправлена', style: AppTextStyles.h2, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Проверьте почту ${_emailController.text} и перейдите по ссылке в письме',
          style: AppTextStyles.body.copyWith(color: AppColors.gray500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        AppButton(
          label: 'Вернуться ко входу',
          variant: AppButtonVariant.outline,
          onPressed: () => context.pop(),
          fullWidth: true,
        ),
      ],
    );
  }
}
