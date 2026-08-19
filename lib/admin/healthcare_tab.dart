import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:doc/utils/app_config.dart';

import 'package:doc/admin/healthcare_profile_screen.dart';

/// HealthcareTab displays the list of healthcare/hospitals for admin management.
class HealthcareTab extends StatefulWidget {
  final Map<String, dynamic> adminData;

  const HealthcareTab({super.key, required this.adminData});

  @override
  State<HealthcareTab> createState() => _HealthcareTabState();
}

class _HealthcareTabState extends State<HealthcareTab> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _healthcareList = [];
  List<Map<String, dynamic>> _filteredHealthcareList = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Filter options
  String _selectedCategory = 'All';
  bool _showVerifiedOnly = false;
  final List<String> _categories = [
    'All',
    'Hospitals / Government-Aided Hospitals',
    'Private Hospitals',
    'Clinics',
    'Nursing Homes',
    'Medical Colleges',
  ];

  @override
  void initState() {
    super.initState();
    _loadHealthcareList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHealthcareList() async {
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/admin/healthcare');

      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'];

        setState(() {
          if (data is List) {
            _healthcareList = data.map((e) => Map<String, dynamic>.from(e)).toList();
          } else {
            _healthcareList = [];
          }
          _applyFilters();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _healthcareList = [];
          _filteredHealthcareList = [];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load healthcare list')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading healthcare: $e');
      setState(() {
        _isLoading = false;
        _healthcareList = [];
        _filteredHealthcareList = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredHealthcareList = _healthcareList.where((healthcare) {
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final name = (healthcare['hospitalName'] ?? healthcare['name'] ?? '').toString().toLowerCase();
          final email = (healthcare['email'] ?? '').toString().toLowerCase();
          final location = (healthcare['location'] ?? '').toString().toLowerCase();
          final phone = (healthcare['phoneNumber'] ?? '').toString().toLowerCase();
          final category = (healthcare['facilityCategory'] ?? '').toString().toLowerCase();
          
          final matchesSearch = name.contains(_searchQuery) ||
              email.contains(_searchQuery) ||
              location.contains(_searchQuery) ||
              phone.contains(_searchQuery) ||
              category.contains(_searchQuery);
          
          if (!matchesSearch) return false;
        }
        
        // Category filter
        if (_selectedCategory != 'All') {
          final category = (healthcare['facilityCategory'] ?? '').toString();
          if (category != _selectedCategory) return false;
        }
        
        // Verified filter
        if (_showVerifiedOnly) {
          final isVerified = healthcare['isKYCVerified'] == true;
          if (!isVerified) return false;
        }
        
        return true;
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Filter Options',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          _selectedCategory = 'All';
                          _showVerifiedOnly = false;
                        });
                        Navigator.pop(context);
                        setState(() {});
                        _applyFilters();
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Filter
                      const Text(
                        'Facility Category',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3A5F),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((category) {
                          final isSelected = _selectedCategory == category;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() => _selectedCategory = category);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF1E3A5F)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF1E3A5F)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isSelected ? Colors.white : Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      // KYC Verified Filter
                      Row(
                        children: [
                          const Text(
                            'Show Verified Only',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E3A5F),
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: _showVerifiedOnly,
                            onChanged: (value) {
                              setModalState(() => _showVerifiedOnly = value);
                            },
                            activeColor: const Color(0xFF1E3A5F),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Apply Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {});
                      _applyFilters();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A5F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadHealthcareList,
      color: const Color(0xFF1E3A5F),
      child: Column(
        children: [
          // Stats Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                // Total Healthcare Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF2E7D32),
                          Color(0xFF43A047),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.local_hospital,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Healthcare Directory',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Explore Hospitals & Healthcare Organizations',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Search and Filter Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search hospitals...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade500,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Colors.grey.shade500,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 45,
                  width: 45,
                  decoration: BoxDecoration(
                    color: (_selectedCategory != 'All' || _showVerifiedOnly)
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF1E3A5F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      IconButton(
                        onPressed: _showFilterDialog,
                        icon: const Icon(
                          Icons.filter_list,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      if (_selectedCategory != 'All' || _showVerifiedOnly)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Results count
          if (!_isLoading && _healthcareList.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Text(
                _searchQuery.isEmpty && _selectedCategory == 'All' && !_showVerifiedOnly
                    ? 'Showing ${_filteredHealthcareList.length} hospitals'
                    : 'Found ${_filteredHealthcareList.length} of ${_healthcareList.length} hospitals',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          // Content Area
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2E7D32),
                    ),
                  )
                : _filteredHealthcareList.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredHealthcareList.length,
                        itemBuilder: (context, index) {
                          return _buildHealthcareCard(_filteredHealthcareList[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_hospital_outlined,
              size: 60,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty || _selectedCategory != 'All' || _showVerifiedOnly
                ? 'No Results Found'
                : 'No Hospitals Found',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedCategory != 'All' || _showVerifiedOnly
                ? 'Try adjusting your filters'
                : 'Pull down to refresh.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthcareCard(Map<String, dynamic> healthcare) {
    final name = healthcare['hospitalName'] ?? healthcare['name'] ?? 'Unknown Hospital';
    final location = healthcare['location'] ?? '';
    final email = healthcare['email'] ?? '';
    final phone = healthcare['phoneNumber'] ?? '';
    final category = healthcare['facilityCategory'] ?? '';
    final isKYCVerified = healthcare['isKYCVerified'] == true;
    final logo = healthcare['hospitalLogo'] ?? '';
    final departments = healthcare['departmentsAvailable'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToProfile(healthcare),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Hospital Logo
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        image: logo.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(logo),
                                fit: BoxFit.cover,
                                onError: (_, __) {},
                              )
                            : null,
                      ),
                      child: logo.isEmpty
                          ? const Icon(
                              Icons.local_hospital,
                              color: Color(0xFF2E7D32),
                              size: 28,
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E3A5F),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isKYCVerified)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified,
                                        size: 12,
                                        color: Colors.green.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Verified',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          if (category.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              category,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Contact Info Row
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (location.isNotEmpty)
                      _buildInfoChip(Icons.location_on_outlined, location),
                    if (email.isNotEmpty)
                      _buildInfoChip(Icons.email_outlined, email),
                    if (phone.toString().isNotEmpty)
                      _buildInfoChip(Icons.phone_outlined, phone.toString()),
                  ],
                ),
                // Departments
                if (departments is List && departments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: departments.take(4).map<Widget>((dept) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A5F).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          dept.toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF1E3A5F),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList()
                      ..addAll(departments.length > 4
                          ? [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '+${departments.length - 4} more',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            ]
                          : []),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey.shade500,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _navigateToProfile(Map<String, dynamic> healthcare) {
    final healthcareId = (healthcare['healthcare_id'] ??
            healthcare['healthcareId'] ??
            healthcare['_id'] ??
            healthcare['id'] ??
            '')
        .toString();

    if (healthcareId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load hospital profile')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HealthcareProfileScreen(
          healthcareId: healthcareId,
          initialData: healthcare,
        ),
      ),
    );
  }
}
