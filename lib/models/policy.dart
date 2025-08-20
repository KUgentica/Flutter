// lib/models/policy.dart

class Policy {
  final String id;                // MongoDB의 고유 ID (_id)
  final String policyId;          // 정책 ID (plcyId)
  final String title;             // 정책명 (plcyTitle)
  final String description;       // 정책 설명 (plcyExplnCn)
  final String category;          // 키워드 (plcyKywdNm)
  final String deadline;          // 신청 기간 (aplyYmd)
  final String applicationMethod; // 신청 방법 (plcyAplyMthdCn)
  final String applicationUrl;    // 신청 페이지 URL (aplyUrlAddr)
  final String referenceUrl;      // 참고 URL (refUrlAddr1)
  final int minAge;               // 지원 최소 연령 (sprtTrgtMinAge)
  final int maxAge;               // 지원 최대 연령 (sprtTrgtMaxAge)
  final String location;          // 지역 (zipCd 기반)
  final String amount;            // 지원 금액 (earnMinAmt, earnMaxAmt 기반)

  Policy({
    required this.id,
    required this.policyId,
    required this.title,
    required this.description,
    required this.category,
    required this.deadline,
    required this.applicationMethod,
    required this.applicationUrl,
    required this.referenceUrl,
    required this.minAge,
    required this.maxAge,
    required this.location,
    required this.amount,
  });

  /// 서버에서 받은 JSON(Map) 데이터로부터 Policy 객체를 생성하는 팩토리 생성자
  factory Policy.fromMap(Map<String, dynamic> map) {
    return Policy(
       id: map['id']?.toString() ?? map['_id']?.toString() ?? '',
      policyId: map['plcyId']?.toString() ?? '',
      title: map['plcyTitle']?.toString() ?? '제목 없음',
      description: map['plcyExplnCn']?.toString() ?? '설명 없음',
      category: map['plcyKywdNm']?.toString() ?? '미분류',
      deadline: map['aplyYmd']?.toString() ?? '상시 모집',
      applicationMethod: map['plcyAplyMthdCn']?.toString() ?? '정보 없음',
      applicationUrl: map['aplyUrlAddr']?.toString() ?? '',
      referenceUrl: map['refUrlAddr1']?.toString() ?? '',
      minAge: int.tryParse(map['sprtTrgtMinAge']?.toString() ?? '0') ?? 0,
      maxAge: int.tryParse(map['sprtTrgtMaxAge']?.toString() ?? '0') ?? 0,
      location: map['zipCd']?.toString() ?? '전국',
      amount: _formatAmount(map['earnMinAmt'], map['earnMaxAmt']),
    );
  }

  /// Policy 객체를 다시 Map 형태로 변환하는 메서드
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plcyId': policyId,
      'plcyTitle': title,
      'plcyExplnCn': description,
      'plcyKywdNm': category,
      'aplyYmd': deadline,
      'plcyAplyMthdCn': applicationMethod,
      'aplyUrlAddr': applicationUrl,
      'refUrlAddr1': referenceUrl,
      'sprtTrgtMinAge': minAge,
      'sprtTrgtMaxAge': maxAge,
      'zipCd': location,
      'amount': amount,
    };
  }

  /// 최소/최대 금액을 받아 사람이 읽기 좋은 문자열로 변환하는 static 헬퍼 함수
  static String _formatAmount(dynamic min, dynamic max) {
    String minStr = min?.toString() ?? "0";
    String maxStr = max?.toString() ?? "0";

    if (minStr == "0" && maxStr == "0") {
      return '내용 확인';
    }
    return '$minStr ~ $maxStr';
  }
}