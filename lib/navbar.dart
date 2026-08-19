import 'package:flutter/material.dart';
import 'package:doc/hospital/my_jobs_screen.dart' as myjobs_screen;
import 'package:doc/hospital/my_jobs_page.dart' as postjob_screen;
import 'package:doc/hospital/manage_job_listings.dart';
import 'package:doc/healthcare/hospital_profile.dart';
import 'package:doc/hospital/scheduled_interviews.dart';

class Navbar extends StatefulWidget {
  final Map<String, dynamic> hospitalData;

  const Navbar({super.key, required this.hospitalData});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  int selectedIndex = 0;

  late final List<Widget> pages;
  late final String healthcareId;

  @override
  void initState() {
    super.initState();
    healthcareId = (widget.hospitalData['healthcare_id'] ??
            widget.hospitalData['healthcareId'] ??
            widget.hospitalData['_id'] ??
            widget.hospitalData['id'] ??
            '')
        .toString();
    
    debugPrint('🏥 Navbar: healthcareId = $healthcareId');
    debugPrint('🏥 Navbar: hospitalData = ${widget.hospitalData}');
    
    pages = [
      myjobs_screen.MyJobsPage(
        healthcareId: healthcareId,
        hospitalData: widget.hospitalData,
        onHospitalNameTap: _openHospitalProfile,
      ),
      ManageJobListings(hospitalData: widget.hospitalData),
      postjob_screen.MyJobsPage(
        healthcareId: healthcareId,
        hospitalData: widget.hospitalData,
        onHospitalNameTap: _openHospitalProfile,
      ),
      ScheduledInterviewScreen(healthcareId: healthcareId),
    ];
  }

  void _openHospitalProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HospitalProfile(
          data: widget.hospitalData,
          showBottomBar: false,
        ),
      ),
    );
  }

  void onTabSelected(int index) {
    setState(() => selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: pages[selectedIndex],

      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(color: Colors.white),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(index: 0, icon: Icons.bookmark, label: "My Jobs"),
            _navItem(index: 1, icon: Icons.group, label: "Applicants"),
            _navItem(index: 2, icon: Icons.add, label: "Post Job"),
            _navItem(index: 3, icon: Icons.calendar_month, label: "Interviews"),
          ],
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = selectedIndex == index;

    const Color selectedColor = Color(0xFF094277); // Dark Blue
    const Color unselectedColor = Color(0xFF117BDD); // Light Blue

    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 28,
            color: isSelected ? selectedColor : unselectedColor,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? selectedColor : unselectedColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
