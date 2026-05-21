import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/router/app_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _emailError = _emailController.text.isEmpty
          ? 'Введите email'
          : !RegExp(r'^[\w-.]+@[\w-]+\.[a-z]{2,}$').hasMatch(_emailController.text)
              ? 'Неверный формат email'
              : null;
      _passwordError = _passwordController.text.isEmpty ? 'Введите пароль' : null;
    });
    return _emailError == null && _passwordError == null;
  }

  void _submit() {
    if (!_validate()) return;
    context.read<AuthBloc>().add(AuthLoginRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Логотип
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.school_outlined, size: 36, color: AppColors.white),
                    ),
                    const SizedBox(height: 24),
                    Text('Вход в систему', style: AppTextStyles.h2),
                    const SizedBox(height: 8),
                    Text(
                      'Введите ваш email и пароль',
                      style: AppTextStyles.body.copyWith(color: AppColors.gray500),
                    ),
                    const SizedBox(height: 32),

                    // Форма
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.gray200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTextField(
                            label: 'Email',
                            hint: 'example@college.kz',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            focusNode: _emailFocus,
                            errorText: _emailError,
                            onEditingComplete: () => _passwordFocus.requestFocus(),
                            prefixIcon: const Icon(Icons.email_outlined, size: 20, color: AppColors.gray500),
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Пароль',
                            hint: '••••••••',
                            controller: _passwordController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            focusNode: _passwordFocus,
                            errorText: _passwordError,
                            onEditingComplete: _submit,
                            prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppColors.gray500),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push(AppRoutes.forgotPassword),
                              child: Text(
                                'Забыли пароль?',
                                style: AppTextStyles.caption.copyWith(color: AppColors.primaryBlue),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          AppButton(
                            label: 'Войти',
                            onPressed: loading ? null : _submit,
                            loading: loading,
                            fullWidth: true,
                            size: AppButtonSize.large,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Система управления учебным процессом',
                      style: AppTextStyles.label,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
