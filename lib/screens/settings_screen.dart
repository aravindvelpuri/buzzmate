import 'package:buzzmate/main.dart';
import 'package:flutter/material.dart';

/// Reusable Settings content (can be embedded in ProfileScreen safely)
class SettingsContent extends StatefulWidget {
  final VoidCallback? onLogout; // 👈 optional logout callback

  const SettingsContent({super.key, this.onLogout});

  @override
  State<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<SettingsContent> {
  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _isDark = themeProvider.isDark;
  }

  void _onToggle(bool value) {
    setState(() => _isDark = value);
    themeProvider.toggleTheme(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(5),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Section header
        Text(
          "Appearance",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),

        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          child: SwitchListTile(
            secondary: Icon(
              Icons.dark_mode,
              color: _isDark ? theme.colorScheme.primary : theme.disabledColor,
            ),
            title: const Text('Dark Theme'),
            value: _isDark,
            onChanged: _onToggle,
            activeColor: theme.colorScheme.primary,
          ),
        ),

        const SizedBox(height: 24),

        if (widget.onLogout != null) ...[
          Text(
            "Account",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Logout",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.red,
              ),
              onTap: widget.onLogout,
            ),
          ),
        ],
      ],
    );
  }
}

/// Full Settings Screen (for navigation via AppBar, etc.)
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: const SettingsContent(),
    );
  }
}
