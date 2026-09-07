import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shell_screen.dart';

class SideMenu extends ConsumerWidget {
  const SideMenu({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String location = GoRouterState.of(context).uri.path;
    final isSidebarOpen = ref.watch(sidebarOpenProvider);

    return Container(
      color: Theme.of(context).cardColor,
      child: ListView(
        children: [
          DrawerHeader(
            child: isSidebarOpen 
              ? Row(
                  children: [
                    const Icon(Icons.shopping_bag, color: Color(0xFF2A2D3E), size: 36), // Dummy logo
                    const SizedBox(width: 8),
                    Text(
                      "dreams", 
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F385B),
                      )
                    ),
                  ],
                )
              : const Icon(Icons.shopping_bag, color: Color(0xFF2A2D3E), size: 36),
          ),
          
          if (isSidebarOpen)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text("Main", style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey)),
            ),
            
          DrawerListTile(
            title: "Dashboard",
            svgSrc: "assets/icons/menu_dashboard.svg",
            isActive: location == '/dashboard',
            isOpen: isSidebarOpen,
            press: () {
              if (Scaffold.of(context).hasDrawer && Scaffold.of(context).isDrawerOpen) {
                Scaffold.of(context).closeDrawer();
              }
              context.go('/dashboard');
            },
          ),
          
          if (isSidebarOpen)
            DrawerListTile(
              title: "Admin Dashboard",
              svgSrc: "assets/icons/menu_dashboard.svg", // Same for now
              isActive: location == '/admin',
              isOpen: isSidebarOpen,
              isSubItem: true,
              press: () {},
            ),

          DrawerListTile(
            title: "Sales/POS",
            svgSrc: "assets/icons/menu_tran.svg",
            isActive: location.startsWith('/sales'),
            isOpen: isSidebarOpen,
            press: () {
              if (Scaffold.of(context).hasDrawer && Scaffold.of(context).isDrawerOpen) {
                Scaffold.of(context).closeDrawer();
              }
              context.go('/sales');
            },
          ),
          
          if (isSidebarOpen)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text("Inventory", style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey)),
            ),

          DrawerListTile(
            title: "Products",
            svgSrc: "assets/icons/menu_store.svg",
            isActive: location.startsWith('/inventory'),
            isOpen: isSidebarOpen,
            press: () {
              if (Scaffold.of(context).hasDrawer && Scaffold.of(context).isDrawerOpen) {
                Scaffold.of(context).closeDrawer();
              }
              context.go('/inventory');
            },
          ),
          DrawerListTile(
            title: "Purchases",
            svgSrc: "assets/icons/menu_task.svg",
            isActive: location.startsWith('/purchases'),
            isOpen: isSidebarOpen,
            press: () {
              if (Scaffold.of(context).hasDrawer && Scaffold.of(context).isDrawerOpen) {
                Scaffold.of(context).closeDrawer();
              }
              context.go('/purchases/new');
            },
          ),
          DrawerListTile(
            title: "Reports",
            svgSrc: "assets/icons/menu_doc.svg",
            isActive: location.startsWith('/reports'),
            isOpen: isSidebarOpen,
            press: () {
              if (Scaffold.of(context).hasDrawer && Scaffold.of(context).isDrawerOpen) {
                Scaffold.of(context).closeDrawer();
              }
              context.go('/reports');
            },
          ),
          DrawerListTile(
            title: "Settings",
            svgSrc: "assets/icons/menu_setting.svg",
            isActive: location.startsWith('/settings'),
            isOpen: isSidebarOpen,
            press: () {}, 
          ),
        ],
      ),
    );
  }
}

class DrawerListTile extends StatelessWidget {
  const DrawerListTile({
    super.key,
    required this.title,
    required this.svgSrc,
    required this.press,
    this.isActive = false,
    this.isOpen = true,
    this.isSubItem = false,
  });

  final String title, svgSrc;
  final VoidCallback press;
  final bool isActive, isOpen, isSubItem;

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).primaryColor;
    final inactiveColor = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5) ?? Colors.white54;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isOpen ? 12.0 : 4.0, vertical: 4.0),
      child: ListTile(
        onTap: press,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        horizontalTitleGap: 0.0,
        selected: isActive,
        selectedTileColor: activeColor.withOpacity(0.1),
        contentPadding: EdgeInsets.symmetric(horizontal: isOpen ? (isSubItem ? 32.0 : 16.0) : 16.0),
        leading: isSubItem 
          ? Icon(Icons.circle, size: 8, color: isActive ? activeColor : inactiveColor)
          : SvgPicture.asset(
              svgSrc,
              colorFilter: ColorFilter.mode(
                  isActive ? activeColor : inactiveColor,
                  BlendMode.srcIn),
              height: 16,
            ),
        title: isOpen 
          ? Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(
                title,
                style: TextStyle(
                    color: isActive ? activeColor : inactiveColor,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
              ),
            ) 
          : null,
      ),
    );
  }
}
