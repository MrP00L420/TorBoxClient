
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/theme_provider.dart';

class ThemeSwitcher extends StatelessWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final themeData = Theme.of(context);

    final themeOptions = {
      AppTheme.system: {'icon': Icons.brightness_auto, 'label': 'System'},
      AppTheme.light: {'icon': Icons.light_mode, 'label': 'Light'},
      AppTheme.dark: {'icon': Icons.dark_mode, 'label': 'Dark'},
      AppTheme.black: {'icon': Icons.star, 'label': 'Black'},
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Theme',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            color: themeData.colorScheme.surfaceContainerHighest.withAlpha(128),
            borderRadius: BorderRadius.circular(24.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Make the Row wrap its content
            children: themeOptions.entries.map((entry) {
              final theme = entry.key;
              final details = entry.value;
              final isSelected = themeProvider.theme == theme;

              return InkWell(
                onTap: () => themeProvider.setTheme(theme),
                borderRadius: BorderRadius.circular(20.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: isSelected 
                      ? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0) 
                      : const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: isSelected ? themeData.colorScheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        details['icon'] as IconData,
                        size: 20,
                        color: isSelected ? themeData.colorScheme.onPrimary : themeData.colorScheme.onSurface,
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: isSelected
                            ? Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  details['label'] as String,
                                  style: TextStyle(
                                    color: isSelected ? themeData.colorScheme.onPrimary : Colors.transparent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
