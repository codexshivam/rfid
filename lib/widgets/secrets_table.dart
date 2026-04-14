import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';
import '../models/password_secret.dart';

class SecretsTable extends StatefulWidget {
  final List<PasswordSecret> secrets;
  final String searchQuery;
  final Future<List<PasswordSecret>?> Function(
    PasswordSecret secret,
    String service,
    String username,
    String password,
    String category,
  )?
  onEditSecret;
  final Future<List<PasswordSecret>?> Function(PasswordSecret secret)? onDeleteSecret;

  const SecretsTable({
    super.key,
    required this.secrets,
    this.searchQuery = '',
    this.onEditSecret,
    this.onDeleteSecret,
  });

  @override
  State<SecretsTable> createState() => _SecretsTableState();
}

class _SecretsTableState extends State<SecretsTable> {
  static const List<String> _allowedCategories = <String>[
    'Personal',
    'Work',
    'Others',
  ];

  late List<PasswordSecret> _allSecrets;
  late List<PasswordSecret> _visibleSecrets;
  String _searchQuery = '';
  final Set<String> _revealedPasswordKeys = <String>{};
  int? _sortColumnIndex;
  bool _sortAscending = true;
  late final ScrollController _verticalScrollController;

  @override
  void initState() {
    super.initState();
    _verticalScrollController = ScrollController();
    _allSecrets = List<PasswordSecret>.from(widget.secrets);
    _searchQuery = widget.searchQuery.trim().toLowerCase();
    _sortColumnIndex = 0;
    _sortAscending = true;
    _refreshVisibleSecrets();
  }

  @override
  void didUpdateWidget(covariant SecretsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String nextQuery = widget.searchQuery.trim().toLowerCase();
    final bool queryChanged = nextQuery != _searchQuery;
    final bool secretsChanged = oldWidget.secrets != widget.secrets;

    if (!queryChanged && !secretsChanged) {
      return;
    }

    setState(() {
      if (secretsChanged) {
        _allSecrets = List<PasswordSecret>.from(widget.secrets);
      }
      if (queryChanged) {
        _searchQuery = nextQuery;
      }
      _refreshVisibleSecrets();
    });
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    super.dispose();
  }

  String _secretKey(PasswordSecret item) {
    if (item.id.trim().isNotEmpty) {
      return item.id;
    }
    return '${item.service}|${item.username}|${item.lastModified}';
  }

  bool _isPasswordVisible(PasswordSecret item) {
    return _revealedPasswordKeys.contains(_secretKey(item));
  }

  String _passwordOrPlaceholder(PasswordSecret item) {
    final String value = item.password.trim();
    if (value.isEmpty) {
      return 'Unavailable';
    }
    return value;
  }

  void _togglePasswordVisibility(PasswordSecret item) {
    final String key = _secretKey(item);
    setState(() {
      if (_revealedPasswordKeys.contains(key)) {
        _revealedPasswordKeys.remove(key);
      } else {
        _revealedPasswordKeys.add(key);
      }
    });
  }

  String _categoryFor(PasswordSecret item) {
    final String value = item.category.trim().toLowerCase();
    if (value == 'personal') {
      return 'Personal';
    }
    if (value == 'work') {
      return 'Work';
    }
    if (value == 'others' || value == 'other') {
      return 'Others';
    }
    return 'Others';
  }

  int _lastModifiedSortValue(String label) {
    final List<String> parts = label.split(' ');
    if (parts.length < 3) {
      return 0;
    }
    const Map<String, int> monthOrder = <String, int>{
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };
    final int month = monthOrder[parts[0].toLowerCase()] ?? 0;
    final int day = int.tryParse(parts[1].replaceAll(',', '')) ?? 0;
    final int year = int.tryParse(parts[2]) ?? 0;
    return (year * 10000) + (month * 100) + day;
  }

  bool _matchesSearch(PasswordSecret item) {
    if (_searchQuery.isEmpty) {
      return true;
    }

    return item.service.toLowerCase().contains(_searchQuery) ||
        item.username.toLowerCase().contains(_searchQuery) ||
        item.lastModified.toLowerCase().contains(_searchQuery) ||
        _categoryFor(item).toLowerCase().contains(_searchQuery);
  }

  void _refreshVisibleSecrets() {
    _visibleSecrets = _allSecrets
        .where((PasswordSecret item) => _matchesSearch(item))
        .toList();
    _sortVisibleSecrets();
  }

  void _sortVisibleSecrets() {
    int compareByService(PasswordSecret a, PasswordSecret b) {
      return a.service.compareTo(b.service);
    }

    int compareByUsername(PasswordSecret a, PasswordSecret b) {
      return a.username.compareTo(b.username);
    }

    int compareByCategory(PasswordSecret a, PasswordSecret b) {
      return _categoryFor(a).compareTo(_categoryFor(b));
    }

    int compareByModified(PasswordSecret a, PasswordSecret b) {
      return _lastModifiedSortValue(a.lastModified).compareTo(
        _lastModifiedSortValue(b.lastModified),
      );
    }

    int Function(PasswordSecret a, PasswordSecret b) comparator;

    switch (_sortColumnIndex) {
      case 1:
        comparator = compareByUsername;
        break;
      case 3:
        comparator = compareByCategory;
        break;
      case 4:
        comparator = compareByModified;
        break;
      case 0:
      default:
        comparator = compareByService;
        break;
    }

    _visibleSecrets.sort((PasswordSecret a, PasswordSecret b) {
      final int result = comparator(a, b);
      return _sortAscending ? result : -result;
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _sortVisibleSecrets();
    });
  }

  Future<void> _editSecret(PasswordSecret item) async {
    final TextEditingController serviceController = TextEditingController(
      text: item.service,
    );
    final TextEditingController usernameController = TextEditingController(
      text: item.username,
    );
    final TextEditingController passwordController = TextEditingController(
      text: '',
    );
    final TextEditingController modifiedController = TextEditingController(
      text: item.lastModified,
    );
    String selectedCategory = _categoryFor(item);

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                UniVaultIcons.edit,
                color: UniVaultColors.primaryAction,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Edit Secret',
                style: TextStyle(
                  color: UniVaultColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setStateDialog) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DialogTextField(
                        controller: serviceController,
                        label: 'Service Name',
                      ),
                      const SizedBox(height: 12),
                      _DialogTextField(
                        controller: usernameController,
                        label: 'Username',
                      ),
                      const SizedBox(height: 12),
                      _DialogTextField(
                        controller: passwordController,
                        label: 'Password',
                        obscureText: true,
                      ),
                      const SizedBox(height: 6),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Leave password empty to keep the existing value.',
                          style: TextStyle(
                            color: UniVaultColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
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
                          labelStyle: const TextStyle(
                            color: UniVaultColors.textSecondary,
                            fontSize: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: UniVaultColors.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: UniVaultColors.divider),
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
                        items: _allowedCategories
                            .map(
                              (String category) => DropdownMenuItem<String>(
                                value: category,
                                child: Text(
                                  category,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w400),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (String? value) {
                          if (value != null) {
                            setStateDialog(() {
                              selectedCategory = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _DialogTextField(
                        controller: modifiedController,
                        label: 'Last Modified',
                        readOnly: true,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: UniVaultColors.divider, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    UniVaultIcons.close,
                    size: 16,
                    color: UniVaultColors.textPrimary,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Cancel',
                    style: TextStyle(
                      color: UniVaultColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: UniVaultColors.primaryAction,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    UniVaultIcons.check,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Continue',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    if (shouldSave != true) {
      serviceController.dispose();
      usernameController.dispose();
      passwordController.dispose();
      modifiedController.dispose();
      return;
    }

    if (!mounted) {
      serviceController.dispose();
      usernameController.dispose();
      passwordController.dispose();
      modifiedController.dispose();
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                UniVaultIcons.check,
                color: UniVaultColors.primaryAction,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Confirm Update',
                style: TextStyle(
                  color: UniVaultColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: const Text(
            'Apply changes to this secret?',
            style: TextStyle(color: UniVaultColors.textPrimary, fontSize: 14),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: UniVaultColors.divider, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    UniVaultIcons.close,
                    size: 16,
                    color: UniVaultColors.textPrimary,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'No',
                    style: TextStyle(
                      color: UniVaultColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: UniVaultColors.primaryAction,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    UniVaultIcons.check,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Yes, Update',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      if (!mounted) {
        serviceController.dispose();
        usernameController.dispose();
        passwordController.dispose();
        modifiedController.dispose();
        return;
      }
      final String nextService = serviceController.text.trim().isEmpty
          ? item.service
          : serviceController.text.trim();
      final String nextUsername = usernameController.text.trim().isEmpty
          ? item.username
          : usernameController.text.trim();
      final String nextPassword = passwordController.text.trim();

      if (widget.onEditSecret != null) {
        try {
          final List<PasswordSecret>? updated = await widget.onEditSecret!(
            item,
            nextService,
            nextUsername,
            nextPassword,
            selectedCategory,
          );
          if (updated != null && mounted) {
            setState(() {
              _allSecrets = List<PasswordSecret>.from(updated);
              _refreshVisibleSecrets();
            });
          }
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unable to update secret right now.'),
                duration: Duration(milliseconds: 1400),
              ),
            );
          }
        }
      } else {
        final int index = _allSecrets.indexOf(item);
        if (index >= 0) {
          final String previousKey = _secretKey(item);
          final bool wasVisible = _revealedPasswordKeys.contains(previousKey);
          setState(() {
            _revealedPasswordKeys.remove(previousKey);
            _allSecrets[index] = PasswordSecret(
              nextService,
              nextUsername,
              item.lastModified,
              id: item.id,
              password: nextPassword.isEmpty ? item.password : nextPassword,
              category: selectedCategory,
            );
            if (wasVisible) {
              _revealedPasswordKeys.add(_secretKey(_allSecrets[index]));
            }
            _refreshVisibleSecrets();
          });
        }
      }
    }

    serviceController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    modifiedController.dispose();
  }

  Future<void> _deleteSecret(PasswordSecret item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                UniVaultIcons.warning,
                color: Colors.red.shade600,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Delete Secret',
                style: TextStyle(
                  color: UniVaultColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete ${item.service}? This action cannot be undone.',
            style: const TextStyle(
              color: UniVaultColors.textPrimary,
              fontSize: 14,
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: UniVaultColors.divider, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    UniVaultIcons.close,
                    size: 16,
                    color: UniVaultColors.textPrimary,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Cancel',
                    style: TextStyle(
                      color: UniVaultColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    UniVaultIcons.delete,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  const Text('Delete'),
                ],
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      if (widget.onDeleteSecret != null) {
        try {
          final List<PasswordSecret>? updated = await widget.onDeleteSecret!(item);
          if (updated != null && mounted) {
            setState(() {
              _allSecrets = List<PasswordSecret>.from(updated);
              _refreshVisibleSecrets();
            });
          }
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unable to delete secret right now.'),
                duration: Duration(milliseconds: 1400),
              ),
            );
          }
        }
      } else {
        setState(() {
          _revealedPasswordKeys.remove(_secretKey(item));
          _allSecrets.remove(item);
          _refreshVisibleSecrets();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: UniVaultColors.background,
            border: Border.all(color: UniVaultColors.divider, width: 1),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Scrollbar(
              controller: _verticalScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _verticalScrollController,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      sortColumnIndex: _sortColumnIndex,
                      sortAscending: _sortAscending,
                      headingRowHeight: 52,
                      dataRowMinHeight: 50,
                      dataRowMaxHeight: 56,
                      columnSpacing: 20,
                      horizontalMargin: 14,
                      dividerThickness: 1,
                      dataRowColor: WidgetStateProperty.resolveWith<Color?>((
                        Set<WidgetState> states,
                      ) {
                        if (states.contains(WidgetState.hovered)) {
                          return UniVaultColors.hoverColor;
                        }
                        return Colors.white;
                      }),
                      headingTextStyle: const TextStyle(
                        color: UniVaultColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                      columns: [
                        DataColumn(
                          label: const Text('Service Name'),
                          onSort: _onSort,
                        ),
                        DataColumn(
                          label: const Text('Username'),
                          onSort: _onSort,
                        ),
                        const DataColumn(label: Text('Password')),
                        DataColumn(
                          label: const Text('Category'),
                          onSort: _onSort,
                        ),
                        DataColumn(
                          label: const Text('Last Modified'),
                          onSort: _onSort,
                        ),
                        const DataColumn(label: Text('')),
                      ],
                      rows: _visibleSecrets.isEmpty
                          ? <DataRow>[
                              DataRow(
                                cells: [
                                  DataCell(
                                    Row(
                                      children: [
                                        const Icon(
                                          UniVaultIcons.search,
                                          size: 16,
                                          color: UniVaultColors.textSecondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _searchQuery.isEmpty
                                              ? 'No secrets available yet.'
                                              : 'No results found for "$_searchQuery".',
                                          style: const TextStyle(
                                            color: UniVaultColors.textSecondary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const DataCell(SizedBox.shrink()),
                                  const DataCell(SizedBox.shrink()),
                                  const DataCell(SizedBox.shrink()),
                                  const DataCell(SizedBox.shrink()),
                                  const DataCell(SizedBox.shrink()),
                                ],
                              ),
                            ]
                          : _visibleSecrets
                                .map(
                                  (PasswordSecret item) => DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          item.service,
                                          style: const TextStyle(
                                            color: UniVaultColors.textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          item.username,
                                          style: const TextStyle(
                                            color: UniVaultColors.textSecondary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _isPasswordVisible(item)
                                                  ? _passwordOrPlaceholder(item)
                                                  : '************',
                                              style: const TextStyle(
                                                color: UniVaultColors.textSecondary,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(width: 3),
                                            IconButton(
                                              tooltip: _isPasswordVisible(item)
                                                  ? 'Hide Password'
                                                  : 'Show Password',
                                              visualDensity: VisualDensity.compact,
                                              onPressed: () =>
                                                  _togglePasswordVisibility(item),
                                              icon: Icon(
                                                _isPasswordVisible(item)
                                                    ? UniVaultIcons.visibilityOff
                                                    : UniVaultIcons.visibilityOn,
                                                size: 16.0,
                                                color: UniVaultColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(width: 2),
                                            IconButton(
                                              tooltip: 'Copy Password',
                                              visualDensity: VisualDensity.compact,
                                              onPressed: () {
                                                final String password =
                                                    _passwordOrPlaceholder(item);
                                                if (password == 'Unavailable') {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Password not available for this record',
                                                      ),
                                                      duration: Duration(
                                                        milliseconds: 900,
                                                      ),
                                                    ),
                                                  );
                                                  return;
                                                }
                                                Clipboard.setData(
                                                  ClipboardData(
                                                    text: password,
                                                  ),
                                                );
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Password copied'),
                                                    duration: Duration(
                                                      milliseconds: 800,
                                                    ),
                                                  ),
                                                );
                                              },
                                              icon: const Icon(
                                                UniVaultIcons.copy,
                                                size: 16.0,
                                                color: UniVaultColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          _categoryFor(item),
                                          style: const TextStyle(
                                            color: UniVaultColors.textSecondary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          item.lastModified,
                                          style: const TextStyle(
                                            color: UniVaultColors.textSecondary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        PopupMenuButton<String>(
                                          tooltip: 'Actions',
                                          icon: const Icon(
                                            UniVaultIcons.more,
                                            size: 18,
                                            color: UniVaultColors.textSecondary,
                                          ),
                                          onSelected: (String action) async {
                                            if (action == 'edit') {
                                              await _editSecret(item);
                                            } else if (action == 'delete') {
                                              await _deleteSecret(item);
                                            }
                                          },
                                          itemBuilder: (BuildContext context) =>
                                              const [
                                                PopupMenuItem<String>(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        UniVaultIcons.edit,
                                                        size: 18,
                                                        color: UniVaultColors.textPrimary,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text('Edit'),
                                                    ],
                                                  ),
                                                ),
                                                PopupMenuItem<String>(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        UniVaultIcons.delete,
                                                        size: 18,
                                                        color: UniVaultColors.errorColor,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        'Delete',
                                                        style: TextStyle(
                                                          color: UniVaultColors.errorColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DialogTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final bool readOnly;

  const _DialogTextField({
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      style: const TextStyle(color: UniVaultColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: UniVaultColors.textSecondary,
          fontSize: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: UniVaultColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: UniVaultColors.divider),
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
