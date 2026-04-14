import 'package:flutter/material.dart';
import '../config/theme.dart';

class CreateSecretForm extends StatelessWidget {
  static const List<String> categories = <String>['Personal', 'Work', 'Others'];

  final TextEditingController serviceController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final Future<void> Function() onSubmit;
  final bool isSubmitting;

  const CreateSecretForm({
    super.key,
    required this.serviceController,
    required this.usernameController,
    required this.passwordController,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onSubmit,
    this.isSubmitting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: UniVaultColors.formBackground,
        border: Border.all(color: UniVaultColors.formBorder, width: 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: UniVaultColors.primaryAction.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  UniVaultIcons.lock,
                  color: UniVaultColors.primaryAction,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Create New Secret',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _FormTextField(controller: serviceController, label: 'Service Name'),
          const SizedBox(height: 12),
          _FormTextField(controller: usernameController, label: 'Username'),
          const SizedBox(height: 12),
          _FormTextField(
            controller: passwordController,
            label: 'Password',
            obscureText: true,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: selectedCategory,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: UniVaultColors.textPrimary,
                ),
            decoration: InputDecoration(
              labelText: 'Category',
              labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: UniVaultColors.divider,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: UniVaultColors.divider,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: UniVaultColors.primaryAction,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
            ),
            items: categories
                .map(
                  (String category) => DropdownMenuItem<String>(
                    value: category,
                    child: Text(
                      category,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                  ),
                )
                .toList(),
            onChanged: isSubmitting
                ? null
                : (String? value) {
                    if (value != null) {
                      onCategoryChanged(value);
                    }
                  },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: FilledButton.icon(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      await onSubmit();
                    },
              style: FilledButton.styleFrom(
                backgroundColor: UniVaultColors.primaryAction,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      UniVaultIcons.add,
                      size: 18,
                    ),
              label: Text(
                isSubmitting ? 'Creating...' : 'Create Secret',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;

  const _FormTextField({
    required this.controller,
    required this.label,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
              labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: UniVaultColors.divider, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: UniVaultColors.divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: UniVaultColors.primaryAction,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}
