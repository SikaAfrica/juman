import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DjumanShellPage extends ConsumerStatefulWidget {
  final Widget child;
  
  const DjumanShellPage({super.key, required this.child});

  @override
  ConsumerState<DjumanShellPage> createState() => _DjumanShellPageState();
}

class _DjumanShellPageState extends ConsumerState<DjumanShellPage> {
  int _selectedIndex = 0;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.search,
      label: 'Recherche',
      route: '/search',
    ),
    NavigationItem(
      icon: Icons.people,
      label: 'Professionnels',
      route: '/professionals',
    ),
    NavigationItem(
      icon: Icons.calendar_today,
      label: 'Réservations',
      route: '/bookings',
    ),
    NavigationItem(
      icon: Icons.message,
      label: 'Messages',
      route: '/messages',
    ),
    NavigationItem(
      icon: Icons.person,
      label: 'Profil',
      route: '/profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    
    _selectedIndex = _navigationItems.indexWhere(
      (item) => location.startsWith(item.route),
    );
    if (_selectedIndex == -1) _selectedIndex = 0;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          context.go(_navigationItems[index].route);
        },
        items: _navigationItems.map((item) {
          return BottomNavigationBarItem(
            icon: Icon(item.icon),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
