import 'package:flutter/material.dart';

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final VoidCallback? onTap;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: labelStyle ?? const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
          Text(
            value,
            style: valueStyle ?? const TextStyle(fontSize: 16, color: Colors.black87),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );

    return onTap != null
        ? InkWell(
            onTap: onTap,
            child: row,
          )
        : row;
  }
}
