import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDarkMode ? Colors.orange.withValues(alpha: 0.2) : Colors.amber.shade100,
      child: Row(
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 16,
            color: isDarkMode ? Colors.orange : Colors.orange.shade800,
          ),
          const SizedBox(width: 8),
          Text(
            'You are offline — showing saved data',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.orange : Colors.orange.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
