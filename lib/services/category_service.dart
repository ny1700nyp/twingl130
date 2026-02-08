import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart';
import '../models/category_model.dart';

class CategoryService {
  static final Map<String, List<CategoryItem>> _cache = {};
  /// 로케일별 key → 표시 문자열. DB에는 key만 저장하고, 표시할 때 이 맵으로 현지어 조회.
  static final Map<String, Map<String, String>> _keyToLabelByLocale = {};

  /// 로케일별 카테고리 로드. [locale]이 null이면 'en' 사용. 해당 로케일 파일 없으면 categories.xml 폴백.
  static Future<List<CategoryItem>> loadCategories([Locale? locale]) async {
    final languageCode = locale?.languageCode ?? 'en';
    if (_cache.containsKey(languageCode)) {
      return _cache[languageCode]!;
    }

    try {
      // 1) 로케일별 XML 시도: categories_ko.xml, categories_ja.xml 등
      try {
        final String xmlData =
            await rootBundle.loadString('assets/categories_$languageCode.xml');
        final list = _parseXmlCategories(xmlData);
        _cache[languageCode] = list;
        _buildKeyToLabel(languageCode, list);
        return list;
      } catch (_) {}
      // 2) 공통 XML 폴백
      try {
        final String xmlData = await rootBundle.loadString('assets/categories.xml');
        final list = _parseXmlCategories(xmlData);
        _cache[languageCode] = list;
        _buildKeyToLabel(languageCode, list);
        return list;
      } catch (e) {
        print('Failed to load XML categories: $e');
      }
      // 3) 텍스트 폴백
      try {
        final String data = await rootBundle.loadString('assets/category.txt');
        final list = _parseCategories(data);
        _cache[languageCode] = list;
        _buildKeyToLabel(languageCode, list);
        return list;
      } catch (_) {}
    } catch (e) {
      print('Failed to load categories: $e');
    }
    final fallback = _getDefaultCategories();
    _cache[languageCode] = fallback;
    _buildKeyToLabel(languageCode, fallback);
    return fallback;
  }

  static void _buildKeyToLabel(String languageCode, List<CategoryItem> categories) {
    final map = <String, String>{};
    for (final c in categories) {
      for (final sub in c.subItems) {
        for (final entry in sub.items) {
          map[entry.key] = entry.label;
        }
      }
    }
    _keyToLabelByLocale[languageCode] = map;
  }

  /// DB에 저장된 key를 현재 로케일의 표시 문자열로 변환. key가 없으면 입력값 그대로 반환(구 데이터/커스텀 항목).
  static String getDisplayLabel(String keyOrLabel, Locale? locale) {
    final code = locale?.languageCode ?? 'en';
    final map = _keyToLabelByLocale[code];
    if (map != null && map.containsKey(keyOrLabel)) return map[keyOrLabel]!;
    return keyOrLabel;
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
          
          // Item 요소 찾기: key 속성 있으면 매칭용 키, 없으면 innerText를 키로 사용(영문 XML 호환)
          final itemElements = subCategoryElement.findAllElements('Item');
          final List<CategoryItemEntry> items = [];
          for (final e in itemElements) {
            final label = e.innerText.trim();
            if (label.isEmpty) continue;
            final key = e.getAttribute('key')?.trim() ?? label;
            items.add(CategoryItemEntry(key: key, label: label));
          }

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
            items: <CategoryItemEntry>[],
          );
        } else if (currentSubItem != null) {
          if (!currentSubItem.items.any((e) => e.key == line)) {
            currentSubItem.items.add(CategoryItemEntry(key: line, label: line));
          }
        } else {
          if (nextLine.isNotEmpty && !RegExp(r'^[🎵🏃🎨💃🍳🎓💼🧸]').hasMatch(nextLine)) {
            currentSubItem = CategorySubItem(
              name: line,
              items: <CategoryItemEntry>[],
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
            items: ['Piano', 'Guitar', 'Violin', 'Drums']
                .map((s) => CategoryItemEntry(key: s, label: s))
                .toList(),
          ),
        ],
      ),
    ];
  }

  /// 모든 항목의 canonical key를 평면 리스트로 (DB 저장/랜덤 선택용)
  static List<String> getAllKeysFlat(List<CategoryItem> categories) {
    final List<String> keys = [];
    for (final category in categories) {
      for (final subItem in category.subItems) {
        for (final entry in subItem.items) {
          keys.add(entry.key);
        }
      }
    }
    return keys;
  }
}
