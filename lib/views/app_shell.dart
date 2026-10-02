import 'package:flutter/material.dart';

import 'account_list_view.dart';
import 'home_view.dart';
import 'shopping_list_view.dart';
import 'tag_list_view.dart';

/// Navegação principal: barra inferior no celular e trilho lateral em telas largas.
/// As abas ficam em um [IndexedStack] para preservar o estado ao alternar.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _destinations = [
    (icon: Icons.home_outlined, selected: Icons.home, label: 'Início'),
    (icon: Icons.account_balance_outlined, selected: Icons.account_balance, label: 'Contas'),
    (icon: Icons.label_outline, selected: Icons.label, label: 'Tags'),
    (icon: Icons.shopping_bag_outlined, selected: Icons.shopping_bag, label: 'Compras'),
  ];

  static const _pages = [HomeView(), AccountListView(), TagListView(), ShoppingListView()];

  @override
  Widget build(BuildContext context) {
    final body = IndexedStack(index: _index, children: _pages);
    final wide = MediaQuery.sizeOf(context).width >= 900;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selected),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selected),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
