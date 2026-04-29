import 'package:android_front_upm/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppRowItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const AppRowItem({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text(value),
        ],
      ),
    );
  }
}
