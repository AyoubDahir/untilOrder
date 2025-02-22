import 'package:flutter/material.dart';
import 'flutter_flow_theme.dart';

class FFButtonWidget extends StatelessWidget {
  const FFButtonWidget({
    Key? key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.iconData,
    this.options = const FFButtonOptions(),
    this.showLoadingIndicator = true,
  }) : super(key: key);

  final String text;
  final Widget? icon;
  final IconData? iconData;
  final Function()? onPressed;
  final FFButtonOptions options;
  final bool showLoadingIndicator;

  @override
  Widget build(BuildContext context) {
    Widget textWidget = Text(
      text,
      style: options.textStyle?.copyWith(color: options.textColor) ??
          TextStyle(color: options.textColor),
      maxLines: 1,
    );
    if (icon != null || iconData != null) {
      textWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) icon!,
          if (iconData != null) Icon(iconData, size: 20),
          const SizedBox(width: 8),
          textWidget,
        ],
      );
    }
    return Container(
      height: options.height,
      width: options.width,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: options.color,
          padding: options.padding,
          elevation: options.elevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(options.borderRadius ?? 8),
            side: BorderSide(
              color: options.borderSide?.color ?? Colors.transparent,
              width: options.borderSide?.width ?? 0,
            ),
          ),
        ),
        child: textWidget,
      ),
    );
  }
}

class FFButtonOptions {
  const FFButtonOptions({
    this.textStyle,
    this.elevation = 2.0,
    this.height = 40.0,
    this.width = double.infinity,
    this.padding = const EdgeInsets.symmetric(horizontal: 24.0),
    this.color = const Color(0xFF4B39EF),
    this.textColor = Colors.white,
    this.borderSide,
    this.borderRadius,
    this.disabledColor,
    this.disabledTextColor,
  });

  final TextStyle? textStyle;
  final double elevation;
  final double height;
  final double width;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color textColor;
  final BorderSide? borderSide;
  final double? borderRadius;
  final Color? disabledColor;
  final Color? disabledTextColor;
}
