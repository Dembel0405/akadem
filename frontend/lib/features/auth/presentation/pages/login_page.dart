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

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  String? _emailError;
  String? _passwordError;

  late final AnimationController _ctrl;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<Offset> _formSlide;
  late final Animation<double> _formFade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );
    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.55, curve: Curves.elasticOut)),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 0.85, curve: Curves.easeOutCubic)),
    );
    _formFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 0.75, curve: Curves.easeIn)),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
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
          : !RegExp(r'^[\w-.]+@[\w-]+\.[a-z]{2,}$')
                  .hasMatch(_emailController.text)
              ? 'Неверный формат email'
              : null;
      _passwordError =
          _passwordController.text.isEmpty ? 'Введите пароль' : null;
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
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;

          if (isWide) {
            return Row(
              children: [
                _buildLeftPanel(),
                Expanded(child: _buildFormSection(loading, showLogo: false)),
              ],
            );
          }

          return Stack(
            children: [
              CustomPaint(
                painter: _MobileBgPainter(),
                child: const SizedBox.expand(),
              ),
              _buildFormSection(loading, showLogo: true),
            ],
          );
        },
      ),
    );
  }

  // ── Left decorative panel (wide screens only) ──────────────────────────────
  Widget _buildLeftPanel() {
    return SizedBox(
      width: 420,
      child: Container(
        color: const Color(0xFFEEF5FF),
        child: Stack(
          children: [
            CustomPaint(
              painter: _LeftPanelPainter(),
              child: const SizedBox.expand(),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: _logoWidget(size: 68),
                      ),
                    ),
                    const SizedBox(height: 36),
                    FadeTransition(
                      opacity: _formFade,
                      child: SlideTransition(
                        position: _formSlide,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Учебный\nпортал',
                              style: AppTextStyles.h1.copyWith(
                                fontSize: 32,
                                height: 1.2,
                                color: AppColors.gray900,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Система управления\nучебным процессом колледжа',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.gray500,
                                height: 1.7,
                              ),
                            ),
                            const SizedBox(height: 44),
                            _featureBullet(Icons.school_outlined, 'Успеваемость и оценки'),
                            const SizedBox(height: 14),
                            _featureBullet(Icons.calendar_month_outlined, 'Расписание занятий'),
                            const SizedBox(height: 14),
                            _featureBullet(Icons.campaign_outlined, 'Объявления и новости'),
                            const SizedBox(height: 14),
                            _featureBullet(Icons.how_to_reg_outlined, 'Контроль посещаемости'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureBullet(IconData icon, String label) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: AppColors.primaryBlue),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: AppTextStyles.body.copyWith(color: AppColors.gray700),
        ),
      ],
    );
  }

  // ── Form section (both layouts) ────────────────────────────────────────────
  Widget _buildFormSection(bool loading, {required bool showLogo}) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showLogo) ...[
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: _logoWidget(size: 72),
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // Heading
              FadeTransition(
                opacity: _logoFade,
                child: Column(
                  children: [
                    Text('Вход в систему', style: AppTextStyles.h2),
                    const SizedBox(height: 6),
                    Text(
                      'Введите ваш email и пароль',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.gray500),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Form card
              FadeTransition(
                opacity: _formFade,
                child: SlideTransition(
                  position: _formSlide,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.gray200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
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
                          onEditingComplete: () =>
                              _passwordFocus.requestFocus(),
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            size: 20,
                            color: AppColors.gray500,
                          ),
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
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            size: 20,
                            color: AppColors.gray500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () =>
                                context.push(AppRoutes.forgotPassword),
                            child: Text(
                              'Забыли пароль?',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.primaryBlue),
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
                ),
              ),

              const SizedBox(height: 28),

              FadeTransition(
                opacity: _formFade,
                child: Text(
                  'Система управления учебным процессом',
                  style: AppTextStyles.label,
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Logo widget (image with icon fallback) ─────────────────────────────────
  Widget _logoWidget({required double size}) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.27),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Image.asset(
        'assets/img/logo.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.primaryBlue,
          child: Icon(
            Icons.school_outlined,
            size: size * 0.55,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Background painters ──────────────────────────────────────────────────────

class _LeftPanelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;

    // Top-right arc (partially off-screen)
    p.color = const Color(0xFF2563EB).withValues(alpha: 0.08);
    canvas.drawCircle(Offset(size.width + 50, -50), 240, p);

    // Bottom-left arc
    p.color = const Color(0xFF2563EB).withValues(alpha: 0.06);
    canvas.drawCircle(Offset(-50, size.height + 50), 200, p);

    // Mid-right small accent
    p.color = const Color(0xFF2563EB).withValues(alpha: 0.05);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.52), 90, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MobileBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;

    // Top-right
    p.color = const Color(0xFF2563EB).withValues(alpha: 0.06);
    canvas.drawCircle(Offset(size.width + 40, -20), 210, p);

    // Bottom-left
    p.color = const Color(0xFF2563EB).withValues(alpha: 0.04);
    canvas.drawCircle(Offset(-30, size.height + 30), 170, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
