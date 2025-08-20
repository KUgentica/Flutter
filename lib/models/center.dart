import 'dart:convert';

// JSON 문자열을 List<Center>로 변환하는 헬퍼 함수
List<Center> centerFromJson(String str) =>
    List<Center>.from(json.decode(str).map((x) => Center.fromJson(x)));

// Center 객체를 JSON 문자열로 변환하는 헬퍼 함수
String centerToJson(List<Center> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Center {
  final String id;
  final String cntrSn;
  final String cntrNm;
  final String cntrAddr;
  final String cntrDaddr;
  final String cntrTelno;
  final String cntrUrlAddr;

  Center({
    required this.id,
    required this.cntrSn,
    required this.cntrNm,
    required this.cntrAddr,
    required this.cntrDaddr,
    required this.cntrTelno,
    required this.cntrUrlAddr,
  });

  // JSON 데이터를 Center 객체로 변환하는 factory 생성자
  factory Center.fromJson(Map<String, dynamic> json) => Center(
        // Java 컨트롤러에서 'id' 필드명으로 보내주므로 그대로 사용합니다.
        id: json["id"] ?? '', 
        cntrSn: json["cntrSn"] ?? '',
        cntrNm: json["cntrNm"] ?? '',
        cntrAddr: json["cntrAddr"] ?? '',
        cntrDaddr: json["cntrDaddr"] ?? '',
        cntrTelno: json["cntrTelno"] ?? '',
        cntrUrlAddr: json["cntrUrlAddr"] ?? '',
      );

  // Center 객체를 JSON 데이터로 변환하는 메서드
  Map<String, dynamic> toJson() => {
        "id": id,
        "cntrSn": cntrSn,
        "cntrNm": cntrNm,
        "cntrAddr": cntrAddr,
        "cntrDaddr": cntrDaddr,
        "cntrTelno": cntrTelno,
        "cntrUrlAddr": cntrUrlAddr,
      };
        factory Center.fromMap(Map<String, dynamic> map) {
    return Center(
      id: map['id']?.toString() ?? map['_id']?.toString() ?? '',
      cntrSn: map['cntrSn']?.toString() ?? '',
      cntrNm: map['cntrNm']?.toString() ?? '이름 없음',
      cntrAddr: map['cntrAddr']?.toString() ?? '',
      cntrDaddr: map['cntrDaddr']?.toString() ?? '',
      cntrTelno: map['cntrTelno']?.toString() ?? '',
      cntrUrlAddr: map['cntrUrlAddr']?.toString() ?? '',
    );
  }
}