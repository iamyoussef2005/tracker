import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../models/user_profile.dart';
import '../widgets/responsive_page.dart';
import 'auth_screen.dart';
import 'appearance_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _photoController = TextEditingController();

  String _preferredCurrency = 'USD';

  static const _currencies = ['USD', 'EUR', 'GBP', 'SYP', 'TRY'];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.user;
    _nameController.text = user?.displayName ?? '';
    _photoController.text = user?.photoPath ?? '';
    _preferredCurrency = user?.preferredCurrency ?? 'USD';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _photoController.dispose();
    super.dispose();
  }

  void _save(UserProfile user) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final photoPath = _photoController.text.trim();
    context.read<AuthBloc>().add(
      AuthProfileUpdateRequested(
        user.copyWith(
          displayName: _nameController.text.trim(),
          photoPath: photoPath.isEmpty ? null : photoPath,
          clearPhotoPath: photoPath.isEmpty,
          preferredCurrency: _preferredCurrency,
        ),
      ),
    );
  }

  Future<void> _openAppearanceScreen() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AppearanceScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) => previous.message != current.message,
      listener: (context, state) {
        final message = state.message;
        if (message == null) {
          return;
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        context.read<AuthBloc>().add(const AuthMessageCleared());
      },
      builder: (context, state) {
        final user = state.user;
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isSaving = state.status == AuthStatus.loading;

        return Scaffold(
          appBar: AppBar(title: const Text('Profile')),
          body: SafeArea(
            child: ResponsivePage(
              maxWidth: 760,
              children: [
                _ProfileHeader(user: user),
                const SizedBox(height: 16),
                _ProfileActionTile(
                  icon: FontAwesomeIcons.palette,
                  title: 'Appearance',
                  subtitle: 'Theme mode, colors, and wide screen layout',
                  onTap: _openAppearanceScreen,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Display name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) => (value ?? '').trim().isEmpty
                              ? 'Enter your display name.'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          initialValue: user.email,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.alternate_email),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _photoController,
                          decoration: const InputDecoration(
                            labelText: 'Profile photo URL or path',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.photo_camera_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _preferredCurrency,
                          decoration: const InputDecoration(
                            labelText: 'Preferred currency',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.payments_outlined),
                          ),
                          items: _currencies
                              .map(
                                (currency) => DropdownMenuItem<String>(
                                  value: currency,
                                  child: Text(currency),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _preferredCurrency = value;
                            });
                          },
                        ),
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          onPressed: isSaving ? null : () => _save(user),
                          icon: isSaving
                              ? const SizedBox.shrink()
                              : const FaIcon(
                                  FontAwesomeIcons.circleCheck,
                                  size: 16,
                                ),
                          label: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Save Profile'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: isSaving
                              ? null
                              : () {
                                  context.read<AuthBloc>().add(
                                    const AuthLogoutRequested(),
                                  );
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (_) => const AuthScreen(),
                                    ),
                                    (route) => false,
                                  );
                                },
                          icon: const FaIcon(
                            FontAwesomeIcons.rightFromBracket,
                            size: 15,
                          ),
                          label: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: FaIcon(
                  icon,
                  color: colorScheme.onPrimaryContainer,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final photo = user.photoPath;
    final showNetworkPhoto =
        photo != null &&
        (photo.startsWith('http://') || photo.startsWith('https://'));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3D5A80), Color(0xFF98C1D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withValues(alpha: 0.22),
            backgroundImage: showNetworkPhoto ? NetworkImage(photo) : null,
            child: showNetworkPhoto
                ? null
                : Text(
                    _initials(user.displayName),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${user.email} | ${user.preferredCurrency}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
