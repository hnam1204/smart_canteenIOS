import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../theme/text_styles.dart';

class CustomButton extends StatefulWidget {
  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.color,
    this.textColor,
    this.width = double.infinity,
    this.height = 54,
    this.borderRadius = 18,
    this.icon,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? color;
  final Color? textColor;
  final double width;
  final double height;
  final double borderRadius;
  final Widget? icon;

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primary;
    final foreground =
        widget.textColor ?? (widget.isOutlined ? color : Colors.white);
    final enabled = widget.onPressed != null && !widget.isLoading;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: SizedBox(
          height: widget.height,
          width: widget.width,
          child: widget.isOutlined
              ? OutlinedButton(
                  onPressed: enabled ? widget.onPressed : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: foreground,
                    side: BorderSide(color: color),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                    ),
                  ),
                  child: _content(foreground),
                )
              : ElevatedButton(
                  onPressed: enabled ? widget.onPressed : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    disabledBackgroundColor: color.withValues(alpha: 0.42),
                    foregroundColor: foreground,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                    ),
                  ),
                  child: _content(foreground),
                ),
        ),
      ),
    );
  }

  Widget _content(Color color) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: widget.isLoading
          ? SizedBox(
              key: const ValueKey('button_loading'),
              height: 21,
              width: 21,
              child: CircularProgressIndicator(strokeWidth: 2.3, color: color),
            )
          : Row(
              key: const ValueKey('button_label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  widget.icon!,
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.text,
                  style: AppTextStyles.button.copyWith(color: color),
                ),
              ],
            ),
    );
  }
}
