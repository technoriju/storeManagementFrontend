import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../core/sync/sync_manager.dart';
import '../../../../core/theme/app_theme.dart';
import '../shell_screen.dart';

class Header extends ConsumerWidget {
  const Header({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          // Sidebar Toggle Button
          InkWell(
            onTap: () {
              if (Responsive.isDesktop(context) || Responsive.isTablet(context)) {
                ref.read(sidebarOpenProvider.notifier).state = !ref.read(sidebarOpenProvider);
              } else {
                Scaffold.of(context).openDrawer();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.keyboard_double_arrow_right, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          
          // Search Field
          if (!Responsive.isMobile(context)) 
            const Expanded(
              flex: 1, 
              child: SearchField()
            ),
          
          if (!Responsive.isMobile(context))
            const Spacer(flex: 1),

          // Right side actions
          Row(
            children: [
              if (Responsive.isDesktop(context)) ...[
                // Store Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.store, size: 18, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      const Text("Freshmart", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, size: 18),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // Add New Button
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text("Add New"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(width: 16),

                // POS Button
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.point_of_sale, size: 18),
                  label: const Text("POS"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F385B),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(width: 24),
              ],

              // Icons Row
              _buildIconButton(Icons.language),
              _buildIconButton(Icons.fullscreen),
              _buildBadgeIconButton(Icons.mail_outline, "1"),
              _buildIconButton(Icons.notifications_none),
              _buildIconButton(Icons.settings_outlined),
              
              const SizedBox(width: 16),
              const ProfileCard(),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.withOpacity(0.1),
          ),
          child: Icon(icon, size: 20, color: Colors.grey[700]),
        ),
      ),
    );
  }

  Widget _buildBadgeIconButton(IconData icon, String badgeText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          InkWell(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.withOpacity(0.1),
              ),
              child: Icon(icon, size: 20, color: Colors.grey[700]),
            ),
          ),
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                badgeText, 
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
              ),
            ),
          )
        ],
      ),
    );
  }
}

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).primaryColor, width: 2),
        ),
        child: const CircleAvatar(
          radius: 18,
          backgroundColor: Colors.grey,
          child: Icon(Icons.person, color: Colors.white),
        ),
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: "Search",
        fillColor: Theme.of(context).cardColor,
        filled: true,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        suffixIcon: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.keyboard_command_key, size: 14, color: Colors.grey),
              Text(" K", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
