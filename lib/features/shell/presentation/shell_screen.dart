import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/responsive.dart';
import 'widgets/side_menu.dart';
import 'widgets/header.dart'; // import header because the original UI has a header on top, but the screenshot has it in the content area

final sidebarOpenProvider = StateProvider<bool>((ref) => true);

class ShellScreen extends ConsumerWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSidebarOpen = ref.watch(sidebarOpenProvider);
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);

    // On mobile/tablet, the sidebar is usually a Drawer.
    // But we also want a collapsible sidebar on desktop.
    final double sidebarWidth = isSidebarOpen ? 250.0 : 80.0;

    return Scaffold(
      drawer: (!isDesktop) ? const Drawer(child: SideMenu()) : null,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isDesktop || (isTablet && isSidebarOpen))
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: sidebarWidth,
                child: const SideMenu(),
              ),
            Expanded(
              child: child, // This will be DashboardScreen, SalesScreen, etc.
            ),
          ],
        ),
      ),
    );
  }
}
