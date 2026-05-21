import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, danger }

enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Widget? icon;
  final bool loading;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.loading = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final height = switch (size) {
      AppButtonSize.small => 32.0,
      AppButtonSize.medium => 40.0,
      AppButtonSize.large => 48.0,
    };

    final textStyle = switch (size) {
      AppButtonSize.small => AppTextStyles.buttonSmall,
      AppButtonSize.medium => AppTextStyles.button,
      AppButtonSize.large => AppTextStyles.buttonLarge,
    };

    final child = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _getForegroundColor(),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 8)],
              Text(label, style: textStyle.copyWith(color: _getForegroundColor())),
            ],
          );

    final style = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return AppColors.gray100;
        }
        if (states.contains(WidgetState.pressed)) {
          return _getPressedBgColor();
        }
        return _getBackgroundColor();
      }),
      foregroundColor: WidgetStateProperty.all(_getForegroundColor()),
      side: variant == AppButtonVariant.outline
          ? WidgetStateProperty.all(
              const BorderSide(color: AppColors.primaryBlue, width: 1.5),
            )
          : variant == AppButtonVariant.danger
              ? WidgetStateProperty.all(
                  const BorderSide(color: AppColors.error, width: 1.5),
                )
              : WidgetStateProperty.all(BorderSide.none),
      minimumSize: WidgetStateProperty.all(
        fullWidth ? Size(double.infinity, height) : Size(0, height),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      elevation: WidgetStateProperty.all(0),
      padding: WidgetStateProperty.all(
        EdgeInsets.symmetric(
          horizontal: size == AppButtonSize.small ? 12 : 16,
          vertical: 0,
        ),
      ),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return AppColors.gray900.withOpacity(0.04);
        }
        return null;
      }),
    );

    final btn = variant == AppButtonVariant.outline || variant == AppButtonVariant.ghost
        ? OutlinedButton(
            onPressed: loading ? null : onPressed,
            style: style,
            child: child,
          )
        : ElevatedButton(
            onPressed: loading ? null : onPressed,
            style: style,
            child: child,
          );

    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }

  Color _getBackgroundColor() => switch (variant) {
        AppButtonVariant.primary => AppColors.primaryBlue,
        AppButtonVariant.secondary => AppColors.lightBlue,
        AppButtonVariant.danger => AppColors.error,
        _ => Colors.transparent,
      };

  Color _getPressedBgColor() => switch (variant) {
        AppButtonVariant.primary => AppColors.primaryDark,
        AppButtonVariant.secondary => AppColors.accentBlue.withOpacity(0.2),
        AppButtonVariant.danger => const Color(0xFFDC2626),
        _ => AppColors.gray50,
      };

  Color _getForegroundColor() => switch (variant) {
        AppButtonVariant.primary || AppButtonVariant.danger => AppColors.white,
        AppButtonVariant.secondary => AppColors.primaryBlue,
        AppButtonVariant.outline => AppColors.primaryBlue,
        AppButtonVariant.ghost => AppColors.gray700,
      };
}
