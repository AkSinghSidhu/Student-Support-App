import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class OfflineBanner extends StatelessWidget {
  final bool isOffline;
  final Widget child;

  const OfflineBanner({
    super.key,
    required this.isOffline,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: isOffline ? 32 : 0,
          color: AppColors.warning,
          child: isOffline
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'No internet — showing cached data',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        Expanded(child: child),
      ],
    );
  }
}
