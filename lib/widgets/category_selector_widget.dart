import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategorySelectorWidget extends StatefulWidget {
  final List<String> selectedItems;
  final Function(List<String>) onSelectionChanged;
  final String title;
  final String hint;

  const CategorySelectorWidget({
    super.key,
    required this.selectedItems,
    required this.onSelectionChanged,
    required this.title,
    required this.hint,
  });

  @override
  State<CategorySelectorWidget> createState() => _CategorySelectorWidgetState();
}

class _CategorySelectorWidgetState extends State<CategorySelectorWidget> {
  List<CategoryItem> _categories = [];
  bool _isLoading = true;
  final TextEditingController _customItemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _customItemController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await CategoryService.loadCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      print('Failed to load categories: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleItem(String item) {
    final newSelection = List<String>.from(widget.selectedItems);
    if (newSelection.contains(item)) {
      newSelection.remove(item);
    } else {
      // 최대 6개까지만 선택 가능
      if (newSelection.length >= 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can select up to 6 items. Please remove an item first.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      newSelection.add(item);
    }
    widget.onSelectionChanged(newSelection);
  }

  Future<void> _showCustomItemDialog() async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Other / Suggest a topic'),
          content: TextField(
            controller: _customItemController,
            decoration: const InputDecoration(
              hintText: 'Enter a new topic or skill',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                _customItemController.clear();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final itemName = _customItemController.text.trim();
                if (itemName.isNotEmpty) {
                  // DB에 추가
                  try {
                    final userId = Supabase.instance.client.auth.currentUser?.id;
                    if (userId != null) {
                      await Supabase.instance.client
                          .from('custom_categories')
                          .insert({
                            'item_name': itemName,
                            'created_by': userId,
                            'status': 'pending',
                          });
                    }
                    
                    // 선택 목록에 추가 (최대 6개 제한)
                    final newSelection = List<String>.from(widget.selectedItems);
                    if (!newSelection.contains(itemName)) {
                      if (newSelection.length >= 6) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('You can select up to 6 items. Please remove an item first.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                        _customItemController.clear();
                        Navigator.of(context).pop();
                        return;
                      }
                      newSelection.add(itemName);
                      widget.onSelectionChanged(newSelection);
                    }
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('"$itemName" has been added! It will be reviewed.'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    // 테이블이 없어도 로컬에만 추가
                    final newSelection = List<String>.from(widget.selectedItems);
                    if (!newSelection.contains(itemName)) {
                      newSelection.add(itemName);
                      widget.onSelectionChanged(newSelection);
                    }
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('"$itemName" has been added! It will be reviewed.'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                  
                  _customItemController.clear();
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.title.isNotEmpty) ...[
          Text(
            widget.title,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
        ],
        if (widget.hint.isNotEmpty) ...[
          Text(
            widget.hint,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
        ],
        // Step content가 SingleChildScrollView로 감싸져 있으므로 고정 높이 사용
        SizedBox(
          height: 400,
          child: ListView.builder(
            shrinkWrap: false,
            itemCount: _categories.length + 1, // +1 for "Other" button
            itemBuilder: (context, index) {
              if (index == _categories.length) {
                // "Other / Suggest a topic" 버튼
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: OutlinedButton.icon(
                    onPressed: _showCustomItemDialog,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Can\'t find? Other / Suggest a topic'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                );
              }

              final category = _categories[index];
              return _buildCategoryItem(category);
            },
          ),
        ),
        // 선택된 항목 표시
        if (widget.selectedItems.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Selected:',
                style: TextStyle(fontSize: 12),
              ),
              Text(
                '${widget.selectedItems.length}/6',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: widget.selectedItems.length >= 6 
                      ? AppTheme.secondaryGold 
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selectedItems.map((item) {
              final scheme = Theme.of(context).colorScheme;
              return Chip(
                backgroundColor: scheme.surfaceContainerHighest,
                label: Text(
                  item,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onDeleted: () => _toggleItem(item),
                deleteIcon: Icon(
                  Icons.close,
                  size: 18,
                  color: scheme.onSurfaceVariant.withOpacity(0.85),
                ),
                side: BorderSide(
                  color: scheme.outlineVariant,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryItem(CategoryItem category) {
    // Icon 이름을 Material Icon으로 변환
    IconData? iconData;
    if (category.icon != null) {
      final iconMap = {
        'music_note': Icons.music_note,
        'directions_run': Icons.directions_run,
        'palette': Icons.palette,
        'theater_comedy': Icons.theater_comedy,
        'restaurant': Icons.restaurant,
        'school': Icons.school,
        'work': Icons.work,
        'child_care': Icons.child_care,
      };
      iconData = iconMap[category.icon];
    }

    // 카테고리별 색상 매핑
    Color getCategoryColor(String? iconName) {
      switch (iconName) {
        case 'music_note':
          return AppTheme.tertiaryGreen; // Emerald-500
        case 'directions_run':
          return AppTheme.secondaryGold; // Amber-500 (Gold)
        case 'palette':
          return AppTheme.primaryGreen; // Emerald-500
        case 'theater_comedy':
          return Colors.red;
        case 'restaurant':
          return Colors.brown;
        case 'school':
          return AppTheme.tertiaryGreen; // Emerald-500
        case 'work':
          return Colors.indigo;
        case 'child_care':
          return AppTheme.twinglGreen;
        default:
          return Colors.grey;
      }
    }

    final categoryColor = getCategoryColor(category.icon);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          // Remove the default expansion divider/outline lines.
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: Colors.transparent),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          collapsedShape: const RoundedRectangleBorder(
            side: BorderSide(color: Colors.transparent),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          leading: iconData != null
              ? Icon(iconData, size: 24, color: categoryColor)
              : Text(
                  category.emoji ?? '📁',
                  style: const TextStyle(fontSize: 20),
                ),
          title: Text(
            category.name,
            style: const TextStyle(fontSize: 14),
          ),
          children: category.subItems.map((subItem) {
            return _buildSubItem(category.name, subItem);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSubItem(String categoryName, CategorySubItem subItem) {
    // Indent sub-categories like a tabbed hierarchy under the main category.
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        // Remove the default expansion divider/outline lines.
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Colors.transparent),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        collapsedShape: const RoundedRectangleBorder(
          side: BorderSide(color: Colors.transparent),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        tilePadding: const EdgeInsets.only(left: 44, right: 16),
        childrenPadding: const EdgeInsets.only(left: 56, right: 16, bottom: 12),
        title: Text(
          subItem.name,
          style: const TextStyle(fontSize: 13),
        ),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: subItem.items.map((item) {
              final isSelected = widget.selectedItems.contains(item);
              final scheme = Theme.of(context).colorScheme;

              return FilterChip(
                label: Text(
                  item,
                  style: TextStyle(
                    fontSize: 12,
                    // Always set explicit label color so it stays readable in light/dark mode.
                    color: isSelected ? scheme.onPrimary : scheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _toggleItem(item);
                  });
                },
                backgroundColor: scheme.surfaceContainerHighest,
                selectedColor: scheme.primary,
                checkmarkColor: scheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                side: BorderSide(
                  color: isSelected
                      ? scheme.primary
                      : scheme.outlineVariant,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
