import 'package:flutter/material.dart';

import '../models/password_secret.dart';
import '../widgets/create_form.dart';
import '../widgets/search_bar.dart';
import '../widgets/secrets_table.dart';

class DashboardScreen extends StatefulWidget {
  final List<PasswordSecret> secrets;
  final Future<List<PasswordSecret>?> Function(
    String service,
    String username,
    String password,
    String category,
  )?
  onCreateSecret;
  final Future<List<PasswordSecret>?> Function(
    PasswordSecret secret,
    String service,
    String username,
    String password,
    String category,
  )?
  onEditSecret;
  final Future<List<PasswordSecret>?> Function(PasswordSecret secret)? onDeleteSecret;

  const DashboardScreen({
    super.key,
    required this.secrets,
    this.onCreateSecret,
    this.onEditSecret,
    this.onDeleteSecret,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final TextEditingController _searchController;
  late final TextEditingController _createServiceController;
  late final TextEditingController _createUsernameController;
  late final TextEditingController _createPasswordController;
  late List<PasswordSecret> _allSecrets;
  bool _isCreateFormOpen = false;
  bool _isSubmittingCreate = false;
  String _selectedCategory = 'Personal';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _createServiceController = TextEditingController();
    _createUsernameController = TextEditingController();
    _createPasswordController = TextEditingController();
    _allSecrets = List<PasswordSecret>.from(widget.secrets);
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _allSecrets = List<PasswordSecret>.from(widget.secrets);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _createServiceController.dispose();
    _createUsernameController.dispose();
    _createPasswordController.dispose();
    super.dispose();
  }

  void _showCreateForm() {
    setState(() {
      _isCreateFormOpen = true;
    });
  }

  void _hideCreateForm() {
    setState(() {
      _isCreateFormOpen = false;
      _createServiceController.clear();
      _createUsernameController.clear();
      _createPasswordController.clear();
      _selectedCategory = 'Personal';
    });
  }

  Future<void> _submitCreate() async {
    if (_isSubmittingCreate) {
      return;
    }

    final String service = _createServiceController.text.trim();
    final String username = _createUsernameController.text.trim();
    final String password = _createPasswordController.text.trim();
    final String category = _selectedCategory;

    if (service.isEmpty || username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          duration: Duration(milliseconds: 1200),
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingCreate = true;
    });

    try {
      if (widget.onCreateSecret != null) {
        final List<PasswordSecret>? updatedSecrets = await widget.onCreateSecret!(
          service,
          username,
          password,
          category,
        );
        if (updatedSecrets != null) {
          setState(() {
            _allSecrets = List<PasswordSecret>.from(updatedSecrets);
          });
        }
      } else {
        final DateTime now = DateTime.now();
        final String dateStr = 'Apr ${now.day}, ${now.year}';
        setState(() {
          _allSecrets.insert(
            0,
            PasswordSecret(
              service,
              username,
              dateStr,
              password: password,
              category: category,
            ),
          );
        });
      }

      _hideCreateForm();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Secret "$service" created successfully'),
          duration: const Duration(milliseconds: 1200),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to create secret right now. Please try again.'),
          duration: Duration(milliseconds: 1500),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingCreate = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    final EdgeInsets padding = isSmallScreen
        ? const EdgeInsets.all(16)
        : const EdgeInsets.fromLTRB(28, 28, 20, 24);

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SecretsSearchBar(
            controller: _searchController,
            onChanged: (String query) {
              setState(() {
                _searchQuery = query.trim();
              });
            },
            onCreatePressed: _isCreateFormOpen
                ? _hideCreateForm
                : _showCreateForm,
            isCreateFormOpen: _isCreateFormOpen,
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          if (_isCreateFormOpen)
            CreateSecretForm(
              serviceController: _createServiceController,
              usernameController: _createUsernameController,
              passwordController: _createPasswordController,
              selectedCategory: _selectedCategory,
              onCategoryChanged: (String value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
              onSubmit: _submitCreate,
              isSubmitting: _isSubmittingCreate,
            ),
          Expanded(
            child: SecretsTable(
              secrets: _allSecrets,
              searchQuery: _searchQuery,
              onEditSecret: widget.onEditSecret,
              onDeleteSecret: widget.onDeleteSecret,
            ),
          ),
        ],
      ),
    );
  }
}
