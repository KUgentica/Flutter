import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/policy.dart';
import '../services/policy_service.dart';
import 'detail.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  // --- State Variables ---
  List<String> _searchHistory = [];
  // ★ 검색 결과를 이제 Policy 객체 목록으로 관리합니다.
  List<Policy> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false; // 검색을 한 번이라도 수행했는지 여부

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _searchFocusNode.requestFocus();
    _loadRecommendedPolicies(); // 초기 화면에 추천 정책 로드
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // --- Data Handling ---

  /// SharedPreferences에서 검색 기록을 로드합니다.
  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('search_history') ?? [];
    });
  }

  /// 검색어를 SharedPreferences에 저장합니다.
  Future<void> _saveSearchHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    _searchHistory.remove(query);
    _searchHistory.insert(0, query);
    if (_searchHistory.length > 10) {
      _searchHistory = _searchHistory.sublist(0, 10);
    }
    await prefs.setStringList('search_history', _searchHistory);
    setState(() {});
  }

  /// 추천 정책을 로드하여 초기 화면에 표시합니다.
  Future<void> _loadRecommendedPolicies() async {
    setState(() => _isLoading = true);
    try {
      final policies = await PolicyService.getRecommendedPolicies();
      if (_searchController.text.trim().isEmpty && mounted) {
        setState(() {
          _searchResults = policies;
          _hasSearched = true; // 추천도 검색 결과로 간주
        });
      }
    } catch (e) {
      print('추천 정책 로드 실패: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 입력된 검색어로 실제 검색을 수행합니다.
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      _loadRecommendedPolicies();
      return;
    }

    setState(() => _isLoading = true);
    await _saveSearchHistory(query);

    try {
      // ★ PolicyService를 통해 Policy 객체 목록을 직접 받습니다.
      final policies = await PolicyService.searchPolicies(query);
      if (query == _searchController.text && mounted) {
        setState(() {
          _searchResults = policies;
          _hasSearched = true;
        });
      }
    } catch (e) {
      print('검색 실패: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- UI Building ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('정책 검색'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 검색창
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: '정책명, 키워드로 검색',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onSubmitted: _performSearch, // 엔터 키를 누르면 검색 실행
            ),
          ),
          // 검색 결과 또는 검색 기록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasSearched
                    ? _buildSearchResults()
                    : _buildSearchHistory(),
          ),
        ],
      ),
    );
  }

  /// 최근 검색어 목록을 보여주는 위젯
  Widget _buildSearchHistory() {
    // ... (검색 기록 UI는 기존 코드와 거의 동일)
    return ListView.builder(
      itemCount: _searchHistory.length,
      itemBuilder: (context, index) {
        final query = _searchHistory[index];
        return ListTile(
          leading: const Icon(Icons.history),
          title: Text(query),
          onTap: () {
            _searchController.text = query;
            _performSearch(query);
          },
        );
      },
    );
  }

  /// 검색 결과를 보여주는 위젯
  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(child: Text('검색 결과가 없습니다.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        // ★ 이제 _searchResults의 각 항목은 Policy 객체입니다.
        final policy = _searchResults[index];
        return _buildPolicyCard(policy);
      },
    );
  }

  /// 정책 정보를 표시하는 카드 위젯
  Widget _buildPolicyCard(Policy policy) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // ★ policy.toMap()을 사용하여 상세 페이지로 데이터를 전달합니다.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PolicyDetailPage(policy: policy.toMap()),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                policy.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                policy.description,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    policy.deadline,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
