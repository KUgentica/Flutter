// lib/models/bookmark_item.dart
import 'policy.dart'; // Policy 모델 import
import 'center.dart'; // Center 모델 import

class BookmarkItem {
  bool isPinned;
  final DateTime createdAt;
  final String itemType; // "POLICY" 또는 "CENTER"
  final dynamic item;    // Policy 또는 Center 객체가 담길 필드

  BookmarkItem({
    required this.isPinned,
    required this.createdAt,
    required this.itemType,
    required this.item,
  });

  /// 서버 응답으로부터 BookmarkItem 객체를 생성하는 팩토리
  factory BookmarkItem.fromServerMap(Map<String, dynamic> map) {
    final bookmarkData = map['bookmark'] as Map<String, dynamic>?;
    final detailItemData = map['detailItem'] as Map<String, dynamic>?;

    if (bookmarkData == null || detailItemData == null) {
      // 데이터 오류 시 기본 객체 반환
      return BookmarkItem(
        isPinned: false,
        createdAt: DateTime.now(),
        itemType: 'UNKNOWN',
        item: null,
      );
    }

    final String itemType = bookmarkData['itemType']?.toString() ?? 'UNKNOWN';
    dynamic item;

    // itemType에 따라 각각의 모델 객체를 생성
    if (itemType == 'POLICY') {
      item = Policy.fromMap(detailItemData);
    } else if (itemType == 'CENTER') {
      item = Center.fromMap(detailItemData);
    }

    return BookmarkItem(
      isPinned: bookmarkData['pinned'] ?? false,
      createdAt: DateTime.tryParse(bookmarkData['createdAt'] ?? '') ?? DateTime.now(),
      itemType: itemType,
      item: item, // 생성된 Policy 또는 Center 객체를 할당
    );
  }
}