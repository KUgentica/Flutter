import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PolicyDetailPage extends StatefulWidget {
  /// 정책 상세 데이터(정규화 맵 or 원본 plcy* 맵)
  final Map<String, dynamic> policy;

  const PolicyDetailPage({Key? key, required this.policy}) : super(key: key);

  @override
  State<PolicyDetailPage> createState() => _PolicyDetailPageState();
}

class _PolicyDetailPageState extends State<PolicyDetailPage> {
  // 문자열 안전 변환
  String _s(dynamic v, {String def = ''}) => (v == null ? def : v.toString());

  // YYYYMMDD → DateTime
  DateTime? _parseYMD(String v) {
    final s = v.trim();
    if (s.length != 8) return null;
    final y = int.tryParse(s.substring(0, 4));
    final m = int.tryParse(s.substring(4, 6));
    final d = int.tryParse(s.substring(6, 8));
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  // YYYY-MM-DD / YYYY.MM.DD / 기타 구분자 → DateTime
  DateTime? _parseFlexibleDate(String v) {
    final s = v.trim();
    if (s.isEmpty) return null;
    final normalized = s.replaceAll('.', '-').replaceAll(RegExp(r'[^0-9\-]'), '');
    try {
      final iso = normalized.length >= 10 ? normalized.substring(0, 10) : normalized;
      return DateTime.parse(iso);
    } catch (_) {
      return null;
    }
  }

  // 신청기간(YYYYMMDD ~ YYYYMMDD) 상태
  ({String label, Color bg, Color fg}) _statusByRange(String range) {
    final parts = range.split('~').map((e) => e.trim()).toList();
    if (parts.length != 2) {
      return (label: range.isEmpty ? '신청기간 정보 없음' : range, bg: Colors.grey[200]!, fg: Colors.grey[700]!);
    }
    final now = DateTime.now();
    final start = _parseYMD(parts[0]);
    final end = _parseYMD(parts[1]);
    if (start == null || end == null) {
      return (label: range, bg: Colors.grey[200]!, fg: Colors.grey[700]!);
    }
    final endInclusive = DateTime(end.year, end.month, end.day, 23, 59, 59);
    if (now.isBefore(start)) {
      return (label: '신청예정 (${parts[0]} ~ ${parts[1]})', bg: Colors.blue[100]!, fg: Colors.blue[700]!);
    } else if (now.isAfter(endInclusive)) {
      return (label: '마감 (${parts[0]} ~ ${parts[1]})', bg: Colors.grey[200]!, fg: Colors.grey[700]!);
    } else {
      return (label: '신청가능 (${parts[0]} ~ ${parts[1]})', bg: Colors.green[100]!, fg: Colors.green[700]!);
    }
  }

  // 마감일 1개만 있을 때 상태
  ({String label, Color bg, Color fg}) _statusByDeadline(String deadline) {
    final d = _parseFlexibleDate(deadline);
    if (d == null) {
      return (label: deadline.isEmpty ? '신청기간 정보 없음' : deadline, bg: Colors.grey[200]!, fg: Colors.grey[700]!);
    }
    final now = DateTime.now();
    final endInclusive = DateTime(d.year, d.month, d.day, 23, 59, 59);
    if (now.isAfter(endInclusive)) {
      return (label: '마감일: $deadline (마감)', bg: Colors.grey[200]!, fg: Colors.grey[700]!);
    } else {
      return (label: '마감일: $deadline (신청가능)', bg: Colors.green[100]!, fg: Colors.green[700]!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.policy;
    // PolicyListPage에서 n으로 넘긴 정규화 원본이 있으면 참고
    final raw = p['_raw'] is Map ? (p['_raw'] as Map).cast<String, dynamic>() : p;

    // 공통/정규화 우선, 없으면 원본 plcy* 폴백
    final id          = _s(p['id'].toString().isNotEmpty ? p['id'] : raw['plcyId']);
    final title       = _s(p['title'] ?? raw['plcyTitle'], def: '(제목 없음)');
    final description = _s(p['description'] ?? raw['plcyExplnCn'], def: '설명 없음');
    final location    = _s(p['location'] ?? raw['plcyLctr']);
    final keywords    = _s(p['plcyKywdNm'] ?? raw['plcyKywdNm']);
    final zipCd       = _s(p['zipCd'] ?? raw['zipCd']);

    // 기간/상태
    final aplyYmd     = _s(p['aplyYmd'] ?? raw['aplyYmd']);               // "YYYYMMDD ~ YYYYMMDD" 형식일 수 있음
    final deadline    = _s(p['deadline'] ?? raw['plcyDd']);

    // 금액
    final plcyAmt     = _s(p['amount'] ?? raw['plcyAmt']);
    final earnMin     = _s(raw['earnMinAmt']);
    final earnMax     = _s(raw['earnMaxAmt']);
    final amountText  = (() {
      if (plcyAmt.isNotEmpty) return plcyAmt;
      if (earnMin.isEmpty && earnMax.isEmpty) return '금액 정보 없음';
      if (earnMin == '0' && earnMax == '0') return '금액 정보 없음';
      if (earnMin.isEmpty) return '최대 $earnMax';
      if (earnMax.isEmpty) return '최소 $earnMin';
      return '$earnMin ~ $earnMax';
    })();

    // 연령
    final ageMin      = _s(raw['sprtTrgtMinAge']);
    final ageMax      = _s(raw['sprtTrgtMaxAge']);
    final ageText     = (() {
      if (ageMin.isEmpty && ageMax.isEmpty) return '연령 제한 없음';
      if (ageMin.isEmpty) return '~ $ageMax세';
      if (ageMax.isEmpty) return '$ageMin세 ~';
      return '$ageMin세 ~ $ageMax세';
    })();

    // 신청 방법
    final applyMethod = _s(p['applyMethod'] ?? raw['plcyAplyMthdCn']).replaceAll(r'\r\n', '\n').replaceAll(r'\n', '\n');

    // 상태 배지 계산: 기간(aplyYmd) > 단일 마감일(plcyDd)
    ({String label, Color bg, Color fg})? badge;
    if (aplyYmd.contains('~')) {
      badge = _statusByRange(aplyYmd);
    } else if (deadline.isNotEmpty) {
      badge = _statusByDeadline(deadline);
    }

    // 신청 관련 URL
    final aplyUrl = _s(p['applyUrl'] ?? raw['aplyUrlAddr']);
    final refUrl1 = _s(p['refUrl1'] ?? raw['refUrlAddr1']);
    final refUrl2 = _s(p['refUrl2'] ?? raw['refUrlAddr2']);
    final List<String> urls = [aplyUrl, refUrl1, refUrl2].where((u) => u.isNotEmpty).toList();
    // 지역(우편번호) 그대로 노출
    final zipRegion = zipCd.isNotEmpty ? zipCd : '-';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 상단 앱바
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.blue,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.blue[400] ?? Colors.blue, Colors.blue[600] ?? Colors.blue],
                  ),
                ),
                child: Center(
                  child: Icon(Icons.policy, size: 80, color: Colors.white.withOpacity(0.3)),
                ),
              ),
            ),
            // 공유 아이콘 제거: 의미 없는 액션 삭제
          ),

          // 본문
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: badge.bg, borderRadius: BorderRadius.circular(20)),
                      child: Text(badge.label, style: TextStyle(color: badge.fg, fontWeight: FontWeight.w600)),
                    ),

                  const SizedBox(height: 16),

                  const Text('정책 개요', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(description, style: const TextStyle(fontSize: 16, height: 1.5)),

                  const SizedBox(height: 24),

                  _buildInfoSection('기본 정보', [
                    {'label': '정책 ID',   'value': id.isEmpty ? '-' : id},
                    {'label': '신청 기간',  'value': aplyYmd.isNotEmpty ? aplyYmd : (deadline.isNotEmpty ? deadline : '-')},
                    {'label': '키워드',     'value': keywords.isEmpty ? '-' : keywords},
                    {'label': '지역',       'value': zipRegion}, // 우편번호 그대로
                  ]),

                  const SizedBox(height: 24),

                  _buildInfoSection('지원 조건/내용', [
                    {'label': '연령',     'value': ageText},
                    {'label': '지원 금액', 'value': amountText},
                  ]),

                  const SizedBox(height: 24),

                  const Text('신청 방법', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Builder(builder: (context) {
                    final bool hasMethod = applyMethod.trim().isNotEmpty && applyMethod.trim() != '-';
                    final bool hasUrls = urls.isNotEmpty;

                    Widget linkTile(String label, String url) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.link, size: 16, color: Colors.blue),
                          const SizedBox(width: 6),
                          Flexible(
                            child: GestureDetector(
                              onTap: () async {
                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(Uri.parse(url), mode: LaunchMode.inAppWebView);
                                }
                              },
                              child: Text(
                                '$label: $url',
                                style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );

                    List<Widget> children = [];
                    if (hasMethod) {
                      children.add(Text(applyMethod, style: const TextStyle(fontSize: 14, height: 1.6)));
                      if (hasUrls) {
                        children.add(const SizedBox(height: 12));
                        children.add(const Text('관련 링크', style: TextStyle(fontWeight: FontWeight.w600)));
                      }
                    } else if (!hasMethod && hasUrls) {
                      // 방법 내용이 없으면 링크만 명시적으로 노출
                      children.add(const Text('신청/안내 링크를 통해 확인하세요.', style: TextStyle(fontSize: 14)));
                    } else {
                      children.add(const Text('신청 방법 정보 없음', style: TextStyle(fontSize: 14)));
                    }

                    if (hasUrls) {
                      if (aplyUrl.isNotEmpty) children.add(linkTile('신청 URL', aplyUrl));
                      if (refUrl1.isNotEmpty) children.add(linkTile('안내 URL1', refUrl1));
                      if (refUrl2.isNotEmpty) children.add(linkTile('안내 URL2', refUrl2));
                    }

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200] ?? Colors.grey),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
                    );
                  }),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Map<String, String>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: items.map((item) {
              final label = item['label'] ?? '';
              final value = item['value'] ?? '';
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(label,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(value.isEmpty ? '-' : value,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
