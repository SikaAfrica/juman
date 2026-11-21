import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/widgets/auth_modal.dart';
import '../../../../core/widgets/djuman_app_bar.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: const DjumanAppBar(
        title: 'Mon Profil',
      ),
      body: authState.status == AuthStatus.authenticated
          ? _buildAuthenticatedProfile(context, ref, authState)
          : _buildUnauthenticatedProfile(context, ref),
    );
  }

  Widget _buildAuthenticatedProfile(BuildContext context, WidgetRef ref, AuthState authState) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.blue[100],
          child: Text(
            authState.displayName?.substring(0, 1).toUpperCase() ?? 'U',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          authState.displayName ?? 'Utilisateur',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          authState.email ?? '',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _buildMenuItem(
          context,
          icon: Icons.person,
          title: 'Mon profil professionnel',
          onTap: () {
            context.go('/profile/professional');
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.settings,
          title: 'Paramètres',
          onTap: () {},
        ),
        _buildMenuItem(
          context,
          icon: Icons.help,
          title: 'Aide',
          onTap: () {},
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {
            ref.read(authProvider.notifier).logout();
          },
          icon: const Icon(Icons.logout),
          label: const Text('Déconnexion'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildUnauthenticatedProfile(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Connectez-vous pour accéder à votre profil',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              showAuthModal(context);
            },
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
