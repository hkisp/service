import 'package:flutter/material.dart';

import '../services/vpn_controller.dart';
import '../theme/app_theme.dart';

class ConnectButton extends StatelessWidget {
  const ConnectButton({
    super.key,
    required this.phase,
    required this.onPressed,
  });

  final ConnPhase phase;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final busy =
        phase == ConnPhase.connecting || phase == ConnPhase.disconnecting;
    final connected = phase == ConnPhase.connected;

    Color ring;
    Color fill;
    String label;
    switch (phase) {
      case ConnPhase.connected:
        ring = IdcColors.ok;
        fill = const Color(0xFF14532D);
        label = '断开';
        break;
      case ConnPhase.connecting:
      case ConnPhase.disconnecting:
        ring = IdcColors.warn;
        fill = const Color(0xFF1E293B);
        label = phase.labelZh;
        break;
      case ConnPhase.error:
        ring = IdcColors.danger;
        fill = const Color(0xFF3F1D1D);
        label = '重试';
        break;
      case ConnPhase.disconnected:
        ring = IdcColors.cyan;
        fill = const Color(0xFF0E2A3A);
        label = '连接';
        break;
    }

    return Semantics(
      button: true,
      label: 'VPN $label',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: busy ? null : onPressed,
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 196,
            height: 196,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  fill,
                  connected ? const Color(0xFF052E16) : IdcColors.bg,
                ],
              ),
              border: Border.all(color: ring, width: 4),
              boxShadow: [
                BoxShadow(
                  color: ring.withValues(alpha: 0.35),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: busy
                  ? SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: ring,
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          connected
                              ? Icons.power_settings_new
                              : Icons.shield_outlined,
                          color: ring,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          style: TextStyle(
                            color: IdcColors.text,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
