import 'package:flutter/material.dart';

import '../../../core/utils/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../shell/presentation/widgets/header.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Header(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.defaultPadding * 1.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome & Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Welcome, Admin", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("You have 200+ Orders, Today", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text("02/09/2026 - 08/09/2026", style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: AppTheme.defaultPadding * 1.5),

                    // Alert Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                                children: const [
                                  TextSpan(text: "Your Product "),
                                  TextSpan(text: "Apple Iphone 15 is running Low, ", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                  TextSpan(text: "already below 5 Pcs., "),
                                  TextSpan(text: "Add Stock", style: TextStyle(color: Colors.red, decoration: TextDecoration.underline)),
                                ],
                              ),
                            ),
                          ),
                          const Icon(Icons.close, color: Colors.grey, size: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.defaultPadding * 1.5),

                    // Primary Stats
                    Responsive(
                      mobile: _PrimaryStatsGrid(crossAxisCount: 1, childAspectRatio: 2.5),
                      tablet: _PrimaryStatsGrid(crossAxisCount: 2, childAspectRatio: 2),
                      desktop: _PrimaryStatsGrid(crossAxisCount: 4, childAspectRatio: 2.5),
                    ),
                    const SizedBox(height: AppTheme.defaultPadding),

                    // Secondary Stats
                    Responsive(
                      mobile: _SecondaryStatsGrid(crossAxisCount: 1, childAspectRatio: 2.5),
                      tablet: _SecondaryStatsGrid(crossAxisCount: 2, childAspectRatio: 2),
                      desktop: _SecondaryStatsGrid(crossAxisCount: 4, childAspectRatio: 2.2),
                    ),
                    const SizedBox(height: AppTheme.defaultPadding * 1.5),

                    // Charts Row 1
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _PlaceholderCard("Sales & Purchase Chart (Bar Chart)"),
                        ),
                        if (!Responsive.isMobile(context)) const SizedBox(width: AppTheme.defaultPadding),
                        if (!Responsive.isMobile(context))
                          Expanded(
                            flex: 3,
                            child: _PlaceholderCard("Overall Information (Radial Chart)"),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.defaultPadding * 1.5),

                    // Lists Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _PlaceholderCard("Top Selling Products")),
                        const SizedBox(width: AppTheme.defaultPadding),
                        Expanded(child: _PlaceholderCard("Low Stock Products")),
                        const SizedBox(width: AppTheme.defaultPadding),
                        Expanded(child: _PlaceholderCard("Recent Sales")),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryStatsGrid extends StatelessWidget {
  final int crossAxisCount;
  final double childAspectRatio;

  const _PrimaryStatsGrid({required this.crossAxisCount, required this.childAspectRatio});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: AppTheme.defaultPadding,
      mainAxisSpacing: AppTheme.defaultPadding,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _PrimaryStatCard(
          title: "Total Sales",
          amount: "\$48,988,078",
          percentage: "+22%",
          isPositive: true,
          color: const Color(0xFFFF9F43), // Orange
          icon: Icons.description_outlined,
        ),
        _PrimaryStatCard(
          title: "Total Sales Return",
          amount: "\$16,478,145",
          percentage: "-22%",
          isPositive: false,
          color: const Color(0xFF1F385B), // Dark Blue
          icon: Icons.sync_alt,
        ),
        _PrimaryStatCard(
          title: "Total Purchase",
          amount: "\$24,145,789",
          percentage: "+22%",
          isPositive: true,
          color: const Color(0xFF28C76F), // Teal/Green
          icon: Icons.inventory_2_outlined,
        ),
        _PrimaryStatCard(
          title: "Total Purchase Return",
          amount: "\$18,458,747",
          percentage: "+22%",
          isPositive: true,
          color: const Color(0xFF2E65F3), // Blue
          icon: Icons.verified_user_outlined,
        ),
      ],
    );
  }
}

class _PrimaryStatCard extends StatelessWidget {
  final String title, amount, percentage;
  final bool isPositive;
  final Color color;
  final IconData icon;

  const _PrimaryStatCard({
    required this.title,
    required this.amount,
    required this.percentage,
    required this.isPositive,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(amount, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward, size: 10, color: isPositive ? Colors.green : Colors.red),
                          Text(percentage, style: TextStyle(fontSize: 10, color: isPositive ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryStatsGrid extends StatelessWidget {
  final int crossAxisCount;
  final double childAspectRatio;

  const _SecondaryStatsGrid({required this.crossAxisCount, required this.childAspectRatio});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: AppTheme.defaultPadding,
      mainAxisSpacing: AppTheme.defaultPadding,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _SecondaryStatCard(
          title: "Profit",
          amount: "\$8,458,798",
          percentage: "+35%",
          icon: Icons.layers,
          iconColor: Colors.teal,
        ),
        _SecondaryStatCard(
          title: "Invoice Due",
          amount: "\$48,988,78",
          percentage: "+35%",
          icon: Icons.pie_chart,
          iconColor: Colors.teal,
        ),
        _SecondaryStatCard(
          title: "Total Expenses",
          amount: "\$8,980,097",
          percentage: "+41%",
          icon: Icons.donut_large,
          iconColor: Colors.redAccent,
        ),
        _SecondaryStatCard(
          title: "Total Payment Returns",
          amount: "\$78,458,798",
          percentage: "-20%",
          isPositive: false,
          icon: Icons.grid_view,
          iconColor: Colors.deepPurple,
        ),
      ],
    );
  }
}

class _SecondaryStatCard extends StatelessWidget {
  final String title, amount, percentage;
  final bool isPositive;
  final IconData icon;
  final Color iconColor;

  const _SecondaryStatCard({
    required this.title,
    required this.amount,
    required this.percentage,
    this.isPositive = true,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(amount, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(percentage, style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                  Text(" vs Last Month", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
              Text("View All", style: TextStyle(color: Colors.grey[700], decoration: TextDecoration.underline, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  final String title;
  const _PlaceholderCard(this.title);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Center(child: Text(title)),
    );
  }
}
