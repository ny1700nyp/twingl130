import 'package:flutter/services.dart';
import 'package:xml/xml.dart';
import '../models/category_model.dart';

class CategoryService {
  static List<CategoryItem>? _cachedCategories;

  /// 카테고리 데이터 로드 및 파싱 (XML 형식)
  static Future<List<CategoryItem>> loadCategories() async {
    if (_cachedCategories != null) {
      return _cachedCategories!;
    }

    try {
      // 먼저 XML 파일 시도
      try {
        final String xmlData = await rootBundle.loadString('assets/categories.xml');
        _cachedCategories = _parseXmlCategories(xmlData);
        return _cachedCategories!;
      } catch (e) {
        print('Failed to load XML categories: $e');
        // Fallback: 텍스트 파일 시도
        final String data = await rootBundle.loadString('assets/category.txt');
        _cachedCategories = _parseCategories(data);
        return _cachedCategories!;
      }
    } catch (e) {
      print('Failed to load categories: $e');
      // Fallback: 기본 카테고리 반환
      return _getDefaultCategories();
    }
  }

  /// XML 형식 카테고리 파싱
  static List<CategoryItem> _parseXmlCategories(String xmlData) {
    final List<CategoryItem> categories = [];
    
    try {
      final document = XmlDocument.parse(xmlData);
      final rootElement = document.rootElement;
      
      // Icon 이름을 이모지로 매핑
      final iconToEmoji = {
        'music_note': '🎵',
        'directions_run': '🏃',
        'palette': '🎨',
        'theater_comedy': '💃',
        'restaurant': '🍳',
        'school': '🎓',
        'work': '💼',
        'child_care': '🧸',
      };

      // 모든 Category 요소 찾기
      final categoryElements = rootElement.findAllElements('Category');
      
      for (final categoryElement in categoryElements) {
        final categoryName = categoryElement.getAttribute('name') ?? '';
        final iconName = categoryElement.getAttribute('icon') ?? '';
        final emoji = iconToEmoji[iconName];

        // SubCategory 요소 찾기
        final subCategoryElements = categoryElement.findAllElements('SubCategory');
        final List<CategorySubItem> subItems = [];

        for (final subCategoryElement in subCategoryElements) {
          final subCategoryName = subCategoryElement.getAttribute('name') ?? '';
          
          // Item 요소 찾기
          final itemElements = subCategoryElement.findAllElements('Item');
          final List<String> items = itemElements.map((e) => e.innerText.trim()).where((text) => text.isNotEmpty).toList();

          subItems.add(CategorySubItem(
            name: subCategoryName,
            items: items,
          ));
        }

        categories.add(CategoryItem(
          name: categoryName,
          emoji: emoji,
          icon: iconName,
          subItems: subItems,
        ));
      }
    } catch (e) {
      print('XML parsing error: $e');
      rethrow;
    }

    return categories;
  }

  /// 카테고리 텍스트 파싱 (기존 방식 - Fallback)
  static List<CategoryItem> _parseCategories(String data) {
    final List<CategoryItem> categories = [];
    final lines = data.split('\n');
    
    CategoryItem? currentCategory;
    CategorySubItem? currentSubItem;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (line.isEmpty) {
        if (currentSubItem != null && currentCategory != null) {
          if (!currentCategory.subItems.contains(currentSubItem)) {
            currentCategory.subItems.add(currentSubItem);
          }
          currentSubItem = null;
        }
        continue;
      }

      if (RegExp(r'^[🎵🏃🎨💃🍳🎓💼🧸]').hasMatch(line)) {
        if (currentCategory != null) {
          if (currentSubItem != null) {
            if (!currentCategory.subItems.contains(currentSubItem)) {
              currentCategory.subItems.add(currentSubItem);
            }
            currentSubItem = null;
          }
          categories.add(currentCategory);
        }

        final emojiMatch = RegExp(r'^([🎵🏃🎨💃🍳🎓💼🧸])').firstMatch(line);
        final emoji = emojiMatch?.group(1);
        final name = line.replaceFirst(RegExp(r'^[🎵🏃🎨💃🍳🎓💼🧸]\s*'), '').trim();
        
        currentCategory = CategoryItem(
          name: name,
          emoji: emoji,
          subItems: [],
        );
        currentSubItem = null;
      }
      else if (currentCategory != null && !RegExp(r'^[🎵🏃🎨💃🍳🎓💼🧸]').hasMatch(line)) {
        final nextLine = i + 1 < lines.length ? lines[i + 1].trim() : '';
        final isNextLineEmpty = nextLine.isEmpty;
        final isNextLineEmoji = RegExp(r'^[🎵🏃🎨💃🍳🎓💼🧸]').hasMatch(nextLine);
        
        if (isNextLineEmpty || isNextLineEmoji) {
          if (currentSubItem != null) {
            if (!currentCategory.subItems.contains(currentSubItem)) {
              currentCategory.subItems.add(currentSubItem);
            }
          }
          
          currentSubItem = CategorySubItem(
            name: line,
            items: [],
          );
        } else if (currentSubItem != null) {
          if (!currentSubItem.items.contains(line)) {
            currentSubItem.items.add(line);
          }
        } else {
          if (nextLine.isNotEmpty && !RegExp(r'^[🎵🏃🎨💃🍳🎓💼🧸]').hasMatch(nextLine)) {
            currentSubItem = CategorySubItem(
              name: line,
              items: [],
            );
          }
        }
      }
    }

    if (currentCategory != null) {
      if (currentSubItem != null) {
        if (!currentCategory.subItems.contains(currentSubItem)) {
          currentCategory.subItems.add(currentSubItem);
        }
      }
      categories.add(currentCategory);
    }

    return categories;
  }

  /// 기본 카테고리 (파일 로드 실패 시)
  static List<CategoryItem> _getDefaultCategories() {
    return [
      CategoryItem(
        name: 'Music & Audio',
        emoji: '🎵',
        icon: 'music_note',
        subItems: [
          CategorySubItem(
            name: 'Instruments',
            items: ['Piano', 'Guitar', 'Violin', 'Drums'],
          ),
        ],
      ),
    ];
  }

  /// 모든 항목을 평면 리스트로 변환 (검색용)
  static List<String> getAllItemsFlat(List<CategoryItem> categories) {
    final List<String> items = [];
    for (final category in categories) {
      for (final subItem in category.subItems) {
        items.addAll(subItem.items);
      }
    }
    return items;
  }
}
