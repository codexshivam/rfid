import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'backend/backend_config.dart';
import 'backend/backend_session_manager.dart';
import 'config/theme.dart';
import 'models/user_profile.dart';
import 'models/password_secret.dart';
import 'widgets/auth_panel.dart';
import 'screens/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}
  runApp(const UniVaultApp());
}

class UniVaultApp extends StatelessWidget {
  const UniVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RFID Project',
      theme: UniVaultTheme.lightTheme,
      home: const UniVaultDashboard(),
    );
  }
}

class UniVaultDashboard extends StatefulWidget {
  const UniVaultDashboard({super.key});

  @override
  State<UniVaultDashboard> createState() => _UniVaultDashboardState();
}

class _UniVaultDashboardState extends State<UniVaultDashboard> {
  static const bool _enableDemoLoginInPublishedBuild = true;

  bool isLoggedIn = false;
  bool _isBootLoading = true;
  BackendSessionManager? _backend;

  UserProfile activeProfile = UserProfile(
    name: '',
    orgUnit: '',
    lastLogin: '',
  );

  List<PasswordSecret> secrets = <PasswordSecret>[];

  @override
  void initState() {
    super.initState();
    _initBackend();
  }

  Future<void> _initBackend() async {
    try {
      final BackendConfig config = BackendConfig.fromEnv();
      if (!config.isConfigured) {
        return;
      }

      final BackendSessionManager manager = BackendSessionManager(config);
      _backend = manager;

      await manager.startHardwareListener(
        onLogin: (UserProfile profile, List<PasswordSecret> loadedSecrets) async {
          if (!mounted) {
            return;
          }
          setState(() {
            activeProfile = profile;
            secrets = loadedSecrets;
            isLoggedIn = true;
          });
        },
        onLogout: () async {
          if (!mounted) {
            return;
          }
          setState(() {
            activeProfile = UserProfile(name: '', orgUnit: '', lastLogin: '');
            secrets = <PasswordSecret>[];
            isLoggedIn = false;
          });
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBootLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _backend?.dispose();
    super.dispose();
  }

  void _toggleAuthState() {
    setState(() {
      isLoggedIn = !isLoggedIn;
    });
  }

  String _timeGreeting() {
    final int hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 17) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    if (_isBootLoading) {
      return const Scaffold(
        body: _HeartbeatLoadingView(),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 75,
            child: isLoggedIn
                ? DashboardScreen(
                    secrets: secrets,
                    onCreateSecret: _backend == null
                        ? null
                        : (String service, String username, String password, String category) async {
                            final BackendSessionManager manager = _backend!;
                            await manager.createSecret(
                              serviceName: service,
                              username: username,
                              plainPassword: password,
                              category: category,
                            );
                            final List<PasswordSecret> refreshed =
                                await manager.fetchActiveSecrets();
                            if (mounted) {
                              setState(() {
                                secrets = refreshed;
                              });
                            }
                            return refreshed;
                          },
                    onEditSecret: _backend == null
                        ? null
                        : (
                            PasswordSecret secret,
                            String service,
                            String username,
                            String password,
                            String category,
                          ) async {
                            if (secret.id.trim().isEmpty) {
                              throw StateError('Cannot edit a secret without a document id');
                            }
                            final BackendSessionManager manager = _backend!;
                            await manager.updateSecret(
                              secretId: secret.id,
                              serviceName: service,
                              username: username,
                              plainPassword: password,
                              category: category,
                            );
                            final List<PasswordSecret> refreshed =
                                await manager.fetchActiveSecrets();
                            if (mounted) {
                              setState(() {
                                secrets = refreshed;
                              });
                            }
                            return refreshed;
                          },
                    onDeleteSecret: _backend == null
                        ? null
                        : (PasswordSecret secret) async {
                            if (secret.id.trim().isEmpty) {
                              throw StateError('Cannot delete a secret without a document id');
                            }
                            final BackendSessionManager manager = _backend!;
                            await manager.deleteSecret(secretId: secret.id);
                            final List<PasswordSecret> refreshed =
                                await manager.fetchActiveSecrets();
                            if (mounted) {
                              setState(() {
                                secrets = refreshed;
                              });
                            }
                            return refreshed;
                          },
                  )
                : const _LoggedOutBrandingView(),
          ),
          Expanded(
            flex: 25,
            child: AuthProfilePanel(
              isLoggedIn: isLoggedIn,
              greeting: _timeGreeting(),
              profile: activeProfile,
              onToggleAuth: _toggleAuthState,
              onDemoLogin: !_enableDemoLoginInPublishedBuild
                  ? null
                  : () async {
                      final BackendSessionManager? manager = _backend;
                      if (manager == null) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Demo login is unavailable until backend configuration is loaded.',
                              ),
                              duration: Duration(milliseconds: 1400),
                            ),
                          );
                        }
                        return;
                      }

                      await manager.demoLogin(
                        onLogin: (UserProfile profile, List<PasswordSecret> loadedSecrets) async {
                          if (!mounted) {
                            return;
                          }
                          setState(() {
                            activeProfile = profile;
                            secrets = loadedSecrets;
                            isLoggedIn = true;
                          });
                        },
                      );
                    },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeartbeatLoadingView extends StatefulWidget {
  const _HeartbeatLoadingView();

  @override
  State<_HeartbeatLoadingView> createState() => _HeartbeatLoadingViewState();
}

class _HeartbeatLoadingViewState extends State<_HeartbeatLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.9, end: 1.12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.32, end: 0.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
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
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 190,
                  height: 190,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.scale(
                        scale: _pulseScale.value,
                        child: Container(
                          width: 148,
                          height: 148,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                UniVaultColors.primaryAction.withValues(alpha: 0.2),
                                UniVaultColors.primaryAction.withValues(alpha: 0.06),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 114,
                        height: 114,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: UniVaultColors.primaryAction.withValues(alpha: 0.16),
                            width: 1.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: UniVaultColors.primaryAction.withValues(alpha: 0.16),
                              blurRadius: 28,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              UniVaultColors.primaryAction,
                              UniVaultColors.primaryAction.withValues(alpha: 0.84),
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
                          size: 32,
                        ),
                      ),
                      Opacity(
                        opacity: _pulseOpacity.value,
                        child: Container(
                          width: 176,
                          height: 176,
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
                  'Initializing RFID Project',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: UniVaultColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Preparing secure vault session...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: UniVaultColors.textSecondary,
                      ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoggedOutBrandingView extends StatelessWidget {
  const _LoggedOutBrandingView();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 980;

        return Container(
          color: const Color(0xFFFFFFFF),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Container(
                  padding: EdgeInsets.all(compact ? 20 : 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _GoogleAccentBar(),
                      const SizedBox(height: 22),
                      Text(
                        'RFID based password app',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF202124),
                          fontWeight: FontWeight.w600,
                          fontSize: compact ? 24 : 30,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Designed as part of practical evaluation for Emerging & Disruptive Technologies workshop',
                        style: GoogleFonts.openSans(
                          color: const Color(0xFF5F6368),
                          fontWeight: FontWeight.w400,
                          fontSize: compact ? 14 : 16,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBFDFF),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE3E7EE)),
                        ),
                        child: Column(
                          children: const [
                            _TeamHeaderRow(),
                            Divider(height: 1, color: Color(0xFFE3E7EE)),
                            _TeamRow(index: '01', name: 'Preeti Kumari Ray', uid: '25BCS13595'),
                            Divider(height: 1, color: Color(0xFFE3E7EE)),
                            _TeamRow(index: '02', name: 'Ram Pandey', uid: '25BCS13599'),
                            Divider(height: 1, color: Color(0xFFE3E7EE)),
                            _TeamRow(index: '03', name: 'Arman Mehboob', uid: '25BCS13601'),
                            Divider(height: 1, color: Color(0xFFE3E7EE)),
                            _TeamRow(index: '04', name: 'Shivam Yadav', uid: '25BCS12535'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GoogleAccentBar extends StatelessWidget {
  const _GoogleAccentBar();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        width: 220,
        height: 8,
        child: Row(
          children: const [
            Expanded(child: ColoredBox(color: Color(0xFF4285F4))),
            Expanded(child: ColoredBox(color: Color(0xFFEA4335))),
            Expanded(child: ColoredBox(color: Color(0xFFFBBC05))),
            Expanded(child: ColoredBox(color: Color(0xFF34A853))),
          ],
        ),
      ),
    );
  }
}

class _TeamHeaderRow extends StatelessWidget {
  const _TeamHeaderRow();

  @override
  Widget build(BuildContext context) {
    final TextStyle style = GoogleFonts.openSans(
      color: const Color(0xFF5F6368),
      fontWeight: FontWeight.w600,
      fontSize: 13,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Row(
        children: [
          SizedBox(width: 52, child: Text('S.N.', style: style)),
          Expanded(flex: 4, child: Text('Name', style: style)),
          Expanded(flex: 3, child: Text('UID', style: style)),
        ],
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  final String index;
  final String name;
  final String uid;

  const _TeamRow({
    required this.index,
    required this.name,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle valueStyle = GoogleFonts.openSans(
      color: const Color(0xFF202124),
      fontWeight: FontWeight.w500,
      fontSize: 14,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Row(
        children: [
          SizedBox(width: 52, child: Text(index, style: valueStyle)),
          Expanded(flex: 4, child: Text(name, style: valueStyle)),
          Expanded(flex: 3, child: Text(uid, style: valueStyle)),
        ],
      ),
    );
  }
}
