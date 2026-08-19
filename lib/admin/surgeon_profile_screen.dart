import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:doc/utils/app_config.dart';

import 'package:url_launcher/url_launcher.dart';

/// SurgeonProfileScreen displays detailed information about a surgeon.
class SurgeonProfileScreen extends StatefulWidget {
  final String profileId;
  final Map<String, dynamic>? initialData;

  const SurgeonProfileScreen({
    super.key,
    required this.profileId,
    this.initialData,
  });

  @override
  State<SurgeonProfileScreen> createState() => _SurgeonProfileScreenState();
}

class _SurgeonProfileScreenState extends State<SurgeonProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _profileData = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _profileData = Map<String, dynamic>.from(widget.initialData!);
    }
    _loadProfileDetails();
  }

  Future<void> _loadProfileDetails() async {
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse(
        '${AppConfig.apiBaseUrl}/surgeon/profile-info/${widget.profileId}',

      );
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] ?? body['profile'] ?? body;

        setState(() {
          if (data is Map) {
            _profileData = Map<String, dynamic>.from(data);
          }
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load profile details';
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading profile: $e';
      });
    }
  }

  Future<void> _openUrl(String url) async {
    if (url.isEmpty) return;

    String fullUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      fullUrl = '${AppConfig.serverUrl}/$url';

    }

    try {
      final uri = Uri.parse(fullUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Profile Header
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            backgroundColor: const Color(0xFF117BDD),
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: _loadProfileDetails,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(background: _buildProfileHeader()),
          ),
          // Content
          SliverToBoxAdapter(
            child: _isLoading && _profileData.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(50),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF117BDD),
                      ),
                    ),
                  )
                : _errorMessage != null && _profileData.isEmpty
                ? _buildErrorState()
                : _buildProfileDetails(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final name =
        _profileData['fullName'] ?? _profileData['name'] ?? 'Loading...';
    final degree = _profileData['degree'] ?? '';
    final speciality = _profileData['speciality'] ?? '';
    final subSpeciality = _profileData['subSpeciality'] ?? '';
    final profilePicture = _profileData['profilePicture'] ?? '';
    final experience = _profileData['yearsOfExperience'];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF117BDD), Color(0xFF117BDD), Color(0xFF00AFF4)],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Profile Picture
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                image: profilePicture.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(profilePicture),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      )
                    : null,
              ),
              child: profilePicture.isEmpty
                  ? const Icon(Icons.person, color: Colors.white, size: 50)
                  : null,
            ),
            const SizedBox(height: 16),
            // Name
            Text(
              name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            if (degree.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                degree,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (speciality.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subSpeciality.isNotEmpty
                    ? '$speciality • $subSpeciality'
                    : speciality,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (experience != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$experience years experience',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            // Bottom spacing to prevent overflow
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadProfileDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF117BDD),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDetails() {
    final email = _profileData['email'] ?? '';
    final phone = _profileData['phoneNumber'] ?? '';
    final location = _profileData['location'] ?? '';
    final state = _profileData['state'] ?? '';
    final district = _profileData['district'] ?? '';
    final summary = _profileData['summaryProfile'] ?? '';
    final experience = _profileData['yearsOfExperience'];
    final surgicalExperience = _profileData['surgicalExperience'] ?? '';
    final portfolioLinks = _profileData['portfolioLinks'] ?? '';
    final workExperience = _profileData['workExperience'] ?? [];
    final cv = _profileData['cv'] ?? '';
    final highestDegree = _profileData['highestDegree'] ?? '';
    final uploadLogBook = _profileData['uploadLogBook'] ?? '';

    // Build location string
    String locationText = location;
    if (locationText.isEmpty) {
      if (district.isNotEmpty && state.isNotEmpty) {
        locationText = '$district, $state';
      } else if (state.isNotEmpty) {
        locationText = state;
      } else if (district.isNotEmpty) {
        locationText = district;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contact Information Card
          _buildSectionCard(
            title: 'Contact Information',
            icon: Icons.contact_phone,
            iconColor: const Color(0xFF117BDD),
            children: [
              if (email.isNotEmpty)
                _buildInfoRow(Icons.email_outlined, 'Email', email),
              if (phone.toString().isNotEmpty)
                _buildInfoRow(Icons.phone_outlined, 'Phone', phone.toString()),
              if (locationText.isNotEmpty)
                _buildInfoRow(
                  Icons.location_on_outlined,
                  'Location',
                  locationText,
                ),
              if (state.isNotEmpty && location.isEmpty)
                _buildInfoRow(Icons.map_outlined, 'State', state),
              if (district.isNotEmpty && location.isEmpty)
                _buildInfoRow(Icons.place_outlined, 'District', district),
            ],
          ),
          const SizedBox(height: 16),

          // Professional Information Card
          _buildSectionCard(
            title: 'Professional Information',
            icon: Icons.work,
            iconColor: const Color(0xFF2E7D32),
            children: [
              if (experience != null)
                _buildInfoRow(
                  Icons.timeline,
                  'Years of Experience',
                  '$experience years',
                ),
              if (surgicalExperience.isNotEmpty)
                _buildInfoRow(
                  Icons.medical_services,
                  'Surgical Cases',
                  surgicalExperience,
                ),
              if (portfolioLinks.isNotEmpty)
                _buildInfoRow(Icons.link, 'Portfolio', portfolioLinks),
            ],
          ),
          const SizedBox(height: 16),

          // Summary Card
          if (summary.isNotEmpty) ...[
            _buildSectionCard(
              title: 'About',
              icon: Icons.person_outline,
              iconColor: const Color(0xFF7B1FA2),
              children: [
                Text(
                  summary,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Work Experience Card
          if (workExperience is List && workExperience.isNotEmpty) ...[
            _buildSectionCard(
              title: 'Work Experience',
              icon: Icons.business_center_outlined,
              iconColor: const Color(0xFFE65100),
              children: workExperience.map<Widget>((work) {
                if (work is Map) {
                  final designation =
                      work['designation'] ?? work['title'] ?? '';
                  final organization =
                      work['healthcareOrganization'] ??
                      work['company'] ??
                      work['hospital'] ??
                      '';
                  final from = work['from'] ?? '';
                  final to = work['to'] ?? 'Present';
                  final workLocation = work['location'] ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (designation.toString().isNotEmpty)
                          Text(
                            designation.toString(),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF117BDD),
                            ),
                          ),
                        if (organization.toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.business,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  organization.toString(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$from - $to',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (workLocation.toString().isNotEmpty) ...[
                              const SizedBox(width: 16),
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  workLocation.toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Documents Card
          if (cv.isNotEmpty ||
              highestDegree.isNotEmpty ||
              uploadLogBook.isNotEmpty) ...[
            _buildSectionCard(
              title: 'Documents',
              icon: Icons.folder_outlined,
              iconColor: const Color(0xFF1976D2),
              children: [
                if (cv.isNotEmpty)
                  _buildDocumentRow(
                    icon: Icons.description_outlined,
                    title: 'CV / Resume',
                    onTap: () => _openUrl(cv),
                  ),
                if (highestDegree.isNotEmpty)
                  _buildDocumentRow(
                    icon: Icons.school_outlined,
                    title: 'Highest Degree Certificate',
                    onTap: () => _openUrl(highestDegree),
                  ),
                if (uploadLogBook.isNotEmpty)
                  _buildDocumentRow(
                    icon: Icons.book_outlined,
                    title: 'Log Book',
                    onTap: () => _openUrl(uploadLogBook),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Account Information Card
          _buildSectionCard(
            title: 'Account Information',
            icon: Icons.settings_outlined,
            iconColor: Colors.grey.shade600,
            children: [
              if (_profileData['createdAt'] != null)
                _buildInfoRow(
                  Icons.calendar_today_outlined,
                  'Registered On',
                  _formatDate(_profileData['createdAt']),
                ),
              _buildInfoRow(
                Icons.verified_user_outlined,
                'Terms Accepted',
                _profileData['termsAccepted'] == true ? 'Yes' : 'No',
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return date.toString();
    }
  }

  Widget _buildDocumentRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF1976D2).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF1976D2), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1976D2),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.open_in_new,
                  color: Color(0xFF1976D2),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    final filteredChildren = children
        .where((w) => w is! SizedBox || w.height != 0)
        .toList();

    if (filteredChildren.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF117BDD),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...filteredChildren,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF117BDD),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
