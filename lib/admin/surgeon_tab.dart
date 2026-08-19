import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:doc/utils/app_config.dart';

import 'package:doc/admin/surgeon_profile_screen.dart';
import 'package:doc/healthcare/hospital_profile.dart';
import 'package:doc/utils/session_manager.dart';

/// SurgeonTab displays the list of surgeons for healthcare and admin management.
class SurgeonTab extends StatefulWidget {
  final Map<String, dynamic>? adminData;
  final Map<String, dynamic>? hospitalData;
  final String? healthcareId;
  final VoidCallback? onHospitalNameTap;
  final bool showAppBar;

  const SurgeonTab({
    super.key,
    this.adminData,
    this.hospitalData,
    this.healthcareId,
    this.onHospitalNameTap,
    this.showAppBar = false,
  });

  @override
  State<SurgeonTab> createState() => _SurgeonTabState();
}

class _SurgeonTabState extends State<SurgeonTab> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _surgeons = [];
  List<Map<String, dynamic>> _filteredSurgeons = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  Color get primaryColor {
    if (widget.adminData != null && widget.adminData!.isNotEmpty) {
      return const Color(0xFF1E3A5F); // Admin dark navy
    }
    return const Color(0xFF117BDD); // Healthcare / Surgeon Search signature blue
  }

  // Hospital Header State
  String _hospitalName = '';
  String? _hospitalLogoUrl;

  // Filter options
  String _selectedSpeciality = 'All';
  String _selectedState = 'All';
  final List<String> _specialities = [
    'All',
    'General Surgery',
    'Neurosurgery',
    'Cardiothoracic Surgery',
    'Orthopedic Surgery',
    'Plastic Surgery',
    'Pediatric Surgery',
    'Urology',
    'Oncology Surgery',
  ];
  List<String> _states = ['All'];

  @override
  void initState() {
    super.initState();
    _loadSurgeons();
    _fetchHospitalHeader();
  }

  Future<void> _fetchHospitalHeader() async {
    if (widget.hospitalData != null && widget.hospitalData!.isNotEmpty) {
      final name = widget.hospitalData!['hospitalName'] ??
          widget.hospitalData!['name'] ??
          widget.hospitalData!['organizationName'];
      final logo = widget.hospitalData!['hospitalLogo'];

      if (name != null && name.toString().isNotEmpty) {
        _hospitalName = name.toString();
      }
      if (logo != null && logo.toString().isNotEmpty) {
        _hospitalLogoUrl = logo.toString();
      }
    }

    if (_hospitalName.isEmpty) {
      try {
        String? id = widget.healthcareId;
        if (id == null || id.isEmpty) {
          id = await SessionManager.getHealthcareId();
        }
        if (id == null || id.isEmpty) {
          id = await SessionManager.getProfileId();
        }

        if (id != null && id.isNotEmpty) {
          final uri = Uri.parse('${AppConfig.apiBaseUrl}/healthcare/healthcare-profile/$id');
          final response = await http.get(uri);
          if (response.statusCode == 200) {
            final body = jsonDecode(response.body);
            final data = body is Map && body['data'] != null ? body['data'] : body;
            if (data is Map) {
              final name = data['hospitalName'] ?? data['name'] ?? data['organizationName'];
              final logo = data['hospitalLogo'];
              if (mounted) {
                setState(() {
                  if (name != null && name.toString().isNotEmpty) {
                    _hospitalName = name.toString();
                  }
                  if (logo != null && logo.toString().isNotEmpty) {
                    _hospitalLogoUrl = logo.toString();
                  }
                });
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching hospital header in SurgeonTab: $e');
      }
    }
  }

  Widget _buildHospitalHeaderCard() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Hospital Logo
            ClipOval(
              child: Container(
                height: 40,
                width: 40,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: (_hospitalLogoUrl != null && _hospitalLogoUrl!.isNotEmpty)
                    ? Image.network(
                        _hospitalLogoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            "assets/logo2.png",
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Image.asset(
                        "assets/logo2.png",
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Hospital Name (tappable to view hospital profile)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (widget.onHospitalNameTap != null) {
                    widget.onHospitalNameTap!();
                  } else if (widget.hospitalData != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HospitalProfile(
                          data: widget.hospitalData!,
                          showBottomBar: false,
                        ),
                      ),
                    );
                  }
                },
                child: Text(
                  _hospitalName.isNotEmpty ? _hospitalName : "Hospital",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),

            // Notification Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue, width: 1.2),
              ),
              child: const Icon(
                Icons.notifications_none,
                color: Colors.blue,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSurgeons() async {
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/admin/surgeons');

      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'];

        setState(() {
          if (data is List) {
            _surgeons = data.map((e) => Map<String, dynamic>.from(e)).toList();
            // Extract unique states for filter
            final statesSet = <String>{'All'};
            for (var surgeon in _surgeons) {
              final state = (surgeon['state'] ?? '').toString();
              if (state.isNotEmpty) statesSet.add(state);
            }
            _states = statesSet.toList()..sort();
            if (_states.first != 'All') {
              _states.remove('All');
              _states.insert(0, 'All');
            }
          } else {
            _surgeons = [];
          }
          _applyFilters();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _surgeons = [];
          _filteredSurgeons = [];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load surgeons')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading surgeons: $e');
      setState(() {
        _isLoading = false;
        _surgeons = [];
        _filteredSurgeons = [];
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
      _filteredSurgeons = _surgeons.where((surgeon) {
        // Search filter
        if (_searchQuery.isNotEmpty) {
          final name = (surgeon['fullName'] ?? surgeon['name'] ?? '').toString().toLowerCase();
          final email = (surgeon['email'] ?? '').toString().toLowerCase();
          final speciality = (surgeon['speciality'] ?? '').toString().toLowerCase();
          final phone = (surgeon['phoneNumber'] ?? '').toString().toLowerCase();
          final state = (surgeon['state'] ?? '').toString().toLowerCase();
          final district = (surgeon['district'] ?? '').toString().toLowerCase();

          final matchesSearch = name.contains(_searchQuery) ||
              email.contains(_searchQuery) ||
              speciality.contains(_searchQuery) ||
              phone.contains(_searchQuery) ||
              state.contains(_searchQuery) ||
              district.contains(_searchQuery);

          if (!matchesSearch) return false;
        }

        // Speciality filter
        if (_selectedSpeciality != 'All') {
          final speciality = (surgeon['speciality'] ?? '').toString();
          if (speciality != _selectedSpeciality) return false;
        }

        // State filter
        if (_selectedState != 'All') {
          final state = (surgeon['state'] ?? '').toString();
          if (state != _selectedState) return false;
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
          height: MediaQuery.of(context).size.height * 0.6,
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
                    Text(
                      'Filter Options',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          _selectedSpeciality = 'All';
                          _selectedState = 'All';
                        });
                        Navigator.pop(context);
                        setState(() {});
                        _applyFilters();
                      },
                      child: Text('Reset', style: TextStyle(color: primaryColor)),
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
                      // Speciality Filter
                      Text(
                        'Speciality',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _specialities.map((speciality) {
                          final isSelected = _selectedSpeciality == speciality;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() => _selectedSpeciality = speciality);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryColor
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? primaryColor
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                speciality,
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
                      // State Filter
                      Text(
                        'State',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _states.map((state) {
                          final isSelected = _selectedState == state;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() => _selectedState = state);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryColor
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? primaryColor
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                state,
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
                      backgroundColor: primaryColor,
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
    final hasActiveFilters = _selectedSpeciality != 'All' || _selectedState != 'All';
    
    final bodyContent = SafeArea(
      top: true,
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _loadSurgeons,
        color: const Color(0xFF094277),
        child: Column(
          children: [
            const SizedBox(height: 6),
            // Hospital Profile Header Card (Logo, Name, Notification Icon)
            _buildHospitalHeaderCard(),
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
                          hintText: 'Search surgeons...',
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
                      color: hasActiveFilters
                          ? const Color(0xFF2E7D32)
                          : primaryColor,
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
                        if (hasActiveFilters)
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
            if (!_isLoading && _surgeons.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                alignment: Alignment.centerLeft,
                child: Text(
                  _searchQuery.isEmpty && !hasActiveFilters
                      ? 'Showing ${_filteredSurgeons.length} surgeons'
                      : 'Found ${_filteredSurgeons.length} of ${_surgeons.length} surgeons',
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
                  ? Center(
                      child: CircularProgressIndicator(
                        color: primaryColor,
                      ),
                    )
                  : _filteredSurgeons.isEmpty
                      ? _buildEmptyState(hasActiveFilters)
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredSurgeons.length,
                          itemBuilder: (context, index) {
                            return _buildSurgeonCard(_filteredSurgeons[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );

    if (widget.showAppBar) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Surgeons',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: bodyContent,
      );
    }

    return bodyContent;
  }

  Widget _buildEmptyState(bool hasFilters) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medical_services_outlined,
              size: 60,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty || hasFilters
                ? 'No Results Found'
                : 'No Surgeons Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || hasFilters
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

  Widget _buildSurgeonCard(Map<String, dynamic> surgeon) {
    final name = surgeon['fullName'] ?? surgeon['name'] ?? 'Unknown';
    final email = surgeon['email'] ?? '';
    final phone = surgeon['phoneNumber'] ?? '';
    final speciality = surgeon['speciality'] ?? '';
    final subSpeciality = surgeon['subSpeciality'] ?? '';
    final degree = surgeon['degree'] ?? '';
    final state = surgeon['state'] ?? '';
    final district = surgeon['district'] ?? '';
    final profilePicture = surgeon['profilePicture'] ?? '';
    final experience = surgeon['yearsOfExperience'];

    String locationText = '';
    if (district.isNotEmpty && state.isNotEmpty) {
      locationText = '$district, $state';
    } else if (state.isNotEmpty) {
      locationText = state;
    } else if (district.isNotEmpty) {
      locationText = district;
    }

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
          onTap: () => _showSurgeonDetails(surgeon),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        image: profilePicture.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(profilePicture),
                                fit: BoxFit.cover,
                                onError: (_, __) {},
                              )
                            : null,
                      ),
                      child: profilePicture.isEmpty
                          ? Icon(
                              Icons.person,
                              color: primaryColor,
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
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          if (degree.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              degree,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (speciality.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subSpeciality.isNotEmpty
                                  ? '$speciality • $subSpeciality'
                                  : speciality,
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
                    // Experience badge
                    if (experience != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$experience yrs',
                          style: TextStyle(
                            fontSize: 11,
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
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
                    if (email.isNotEmpty)
                      _buildInfoChip(Icons.email_outlined, email),
                    if (phone.toString().isNotEmpty)
                      _buildInfoChip(Icons.phone_outlined, phone.toString()),
                    if (locationText.isNotEmpty)
                      _buildInfoChip(Icons.location_on_outlined, locationText),
                  ],
                ),
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

  void _showSurgeonDetails(Map<String, dynamic> surgeon) {
    final profileId = (surgeon['profile_id'] ??
            surgeon['profileId'] ??
            surgeon['_id'] ??
            surgeon['id'] ??
            '')
        .toString();

    if (profileId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load surgeon profile')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurgeonProfileScreen(
          profileId: profileId,
          initialData: surgeon,
        ),
      ),
    );
  }
}
