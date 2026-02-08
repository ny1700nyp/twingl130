/// DB/매칭용 canonical key와 화면 표시용 label. DB에는 key만 저장해 언어와 무관하게 매칭.
class CategoryItemEntry {
  final String key;
  final String label;

  CategoryItemEntry({required this.key, required this.label});
}

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
  final List<CategoryItemEntry> items;

  CategorySubItem({
    required this.name,
    required this.items,
  });
}
