import 'package:flutter/material.dart';
import '../config/theme.dart';

class SecretsSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onCreatePressed;
  final bool isCreateFormOpen;

  const SecretsSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onCreatePressed,
    required this.isCreateFormOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: UniVaultColors.searchBackground,
              border: Border.all(color: UniVaultColors.searchBorder, width: 1),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search service, username, category',
                hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 13.50,
                ),
                prefixIcon: Icon(
                  UniVaultIcons.search,
                  color: UniVaultColors.textSecondary,
                  size: 18.50,
                ),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          UniVaultIcons.clear,
                          color: UniVaultColors.textSecondary,
                          size: 18,
                        ),
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(top: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        SizedBox(
          height: 44,
          child: FilledButton.icon(
            onPressed: onCreatePressed,
            style: FilledButton.styleFrom(
              backgroundColor: isCreateFormOpen
                  ? Colors.grey.shade400
                  : UniVaultColors.primaryAction,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              elevation: 0,
            ),
            icon: Icon(
              isCreateFormOpen ? UniVaultIcons.close : UniVaultIcons.add,
              size: 18,
            ),
            label: Text(
              isCreateFormOpen ? 'Cancel' : 'Create Secret',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
