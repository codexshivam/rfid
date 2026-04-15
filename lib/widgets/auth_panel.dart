import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/user_profile.dart';

class AuthProfilePanel extends StatefulWidget {
  final bool isLoggedIn;
  final String greeting;
  final UserProfile profile;
  final VoidCallback onToggleAuth;
  final VoidCallback? onDemoLogin;

  const AuthProfilePanel({
    super.key,
    required this.isLoggedIn,
    required this.greeting,
    required this.profile,
    required this.onToggleAuth,
    this.onDemoLogin,
  });

  @override
  State<AuthProfilePanel> createState() => _AuthProfilePanelState();
}

class _AuthProfilePanelState extends State<AuthProfilePanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.32, end: 0.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF8FAFD),
            Color(0xFFF2F5FA),
          ],
        ),
        border: Border(
          left: BorderSide(color: UniVaultColors.divider, width: 1),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -60,
            child: _DecorGlow(
              size: 180,
              color: UniVaultColors.primaryAction.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -40,
            child: _DecorGlow(
              size: 120,
              color: UniVaultColors.successColor.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusHeader(isLoggedIn: widget.isLoggedIn),
                const SizedBox(height: 18),
                Expanded(
                  child: widget.isLoggedIn
                      ? _LoggedInStateCard(
                          greeting: widget.greeting,
                          profile: widget.profile,
                        )
                      : _LoggedOutStateCard(
                          pulseController: _pulseController,
                          pulseScale: _pulseScale,
                          pulseOpacity: _pulseOpacity,
                          onDemoLogin: widget.onDemoLogin,
                        ),
                ),
                const SizedBox(height: 14),
                _FooterInstruction(
                  isLoggedIn: widget.isLoggedIn,
                  onToggleAuth: widget.onToggleAuth,
                  onDemoLogin: widget.onDemoLogin,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final bool isLoggedIn;

  const _StatusHeader({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    final Color accent = isLoggedIn
        ? UniVaultColors.successColor
        : UniVaultColors.primaryAction;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: UniVaultColors.divider.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.32),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isLoggedIn ? 'Session active' : 'RFID state ready',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Text(
            isLoggedIn ? 'Unlocked' : 'Locked',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _LoggedOutStateCard extends StatelessWidget {
  final AnimationController pulseController;
  final Animation<double> pulseScale;
  final Animation<double> pulseOpacity;
  final VoidCallback? onDemoLogin;

  const _LoggedOutStateCard({
    required this.pulseController,
    required this.pulseScale,
    required this.pulseOpacity,
    this.onDemoLogin,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (BuildContext context, Widget? child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: UniVaultColors.divider.withValues(alpha: 0.75)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 170,
                height: 170,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: pulseScale.value,
                      child: Container(
                        width: 132,
                        height: 132,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              UniVaultColors.primaryAction.withValues(alpha: 0.18),
                              UniVaultColors.primaryAction.withValues(alpha: 0.06),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: UniVaultColors.primaryAction.withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: UniVaultColors.primaryAction.withValues(alpha: 0.14),
                            blurRadius: 26,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            UniVaultColors.primaryAction,
                            UniVaultColors.primaryAction.withValues(alpha: 0.85),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: UniVaultColors.primaryAction.withValues(alpha: 0.34),
                            blurRadius: 22,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        UniVaultIcons.rfid,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    Opacity(
                      opacity: pulseOpacity.value,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: UniVaultColors.primaryAction.withValues(alpha: 0.45),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Waiting for RFID tap',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap your card to unlock the vault and reveal the session controls.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LoggedInStateCard extends StatelessWidget {
  final String greeting;
  final UserProfile profile;

  const _LoggedInStateCard({
    required this.greeting,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: UniVaultColors.divider.withValues(alpha: 0.75)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: UniVaultColors.successColor,
                    ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              UniVaultColors.successColor.withValues(alpha: 0.18),
                              UniVaultColors.primaryAction.withValues(alpha: 0.12),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: UniVaultColors.successColor.withValues(alpha: 0.28),
                          ),
                        ),
                        child: const Icon(
                          UniVaultIcons.profile,
                          color: UniVaultColors.primaryAction,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.orgUnit,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: UniVaultColors.divider.withValues(alpha: 0.7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ProfileDetailTile(
                  label: 'Organization',
                  value: profile.orgUnit,
                ),
                const SizedBox(height: 12),
                _ProfileDetailTile(
                  label: 'Last login',
                  value: profile.lastLogin,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileDetailTile extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileDetailTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: UniVaultColors.sidebar.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: UniVaultColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}

class _FooterInstruction extends StatelessWidget {
  final bool isLoggedIn;
  final VoidCallback onToggleAuth;
  final VoidCallback? onDemoLogin;

  const _FooterInstruction({
    required this.isLoggedIn,
    required this.onToggleAuth,
    this.onDemoLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: UniVaultColors.divider.withValues(alpha: 0.72)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isLoggedIn ? UniVaultIcons.logout : UniVaultIcons.security,
                size: 18,
                color: isLoggedIn
                    ? UniVaultColors.errorColor
                    : UniVaultColors.primaryAction,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isLoggedIn
                      ? 'Tap your RFID card again to lock the vault and end the session.'
                      : 'Tap the RFID card to unlock your vault.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.4,
                        color: UniVaultColors.textSecondary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoggedIn)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onToggleAuth,
                style: FilledButton.styleFrom(
                  backgroundColor: UniVaultColors.errorColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(
                  UniVaultIcons.logout,
                  size: 18,
                ),
                label: Text(
                  'Logout',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onDemoLogin,
                style: FilledButton.styleFrom(
                  backgroundColor: UniVaultColors.primaryAction,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(
                  UniVaultIcons.security,
                  size: 18,
                ),
                label: Text(
                  'Demo Login',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DecorGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _DecorGlow({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
