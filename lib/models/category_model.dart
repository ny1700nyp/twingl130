class CategoryItem {
  final String name;
  final String? emoji;
  final String? icon; // Material icon name
  final List<CategorySubItem> subItems;

  CategoryItem({
    required this.name,
    this.emoji,
    this.icon,
    required this.subItems,
  });
}

class CategorySubItem {
  final String name;
  final List<String> items;

  CategorySubItem({
    required this.name,
    required this.items,
  });
}
