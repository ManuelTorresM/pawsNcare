import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../accent_left_card.dart';
import '../../screens/nutrition/nutrition_screen.dart';

class NutritionReminderCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isEnabled;
  final ValueChanged<bool> onToggleChanged;
  final VoidCallback onAddPressed;
  final List<ReminderItem> items;
  final Color accentColor;
  final Function(ReminderItem item) onDeleteItem;
  final Function(ReminderItem item) onEditItem;

  const NutritionReminderCard({
    super.key,
    required this.title,
    required this.icon,
    required this.isEnabled,
    required this.onToggleChanged,
    required this.onAddPressed,
    required this.items,
    required this.accentColor,
    required this.onDeleteItem,
    required this.onEditItem,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isEnabled ? 1.0 : 0.5,
      child: AccentLeftCard(
        accentColor: accentColor,
        backgroundColor: AppTheme.surfaceContainerLowest,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: accentColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: isEnabled,
                  activeThumbColor: accentColor,
                  onChanged: onToggleChanged,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Add Reminders Button
            IgnorePointer(
              ignoring: !isEnabled,
              child: OutlinedButton.icon(
                onPressed: onAddPressed,
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  'Add ${title == 'Hydration' ? 'Hydration' : 'Meal'}',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accentColor,
                  backgroundColor: accentColor.withValues(alpha: 0.1),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // List Items
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No reminders active.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontStyle: FontStyle.italic,
                    color: AppTheme.secondary,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final r = items[index];
                  return AccentLeftCard(
                    accentColor: accentColor,
                    backgroundColor: AppTheme.surfaceContainerLow,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    borderRadius: 12.0,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.title,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                r.subtitle,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                              if (r.notes.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.sticky_note_2_outlined,
                                      size: 13,
                                      color: accentColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        r.notes,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: AppTheme.secondary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 4,
                                children: r.targetPets.map((p) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF383634)
                                          : AppTheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      p.toUpperCase(),
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9,
                                        color: isDark
                                            ? Colors.white
                                            : AppTheme.onSurface,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppTheme.secondary,
                          ),
                          onPressed: () => onEditItem(r),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => onDeleteItem(r),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
