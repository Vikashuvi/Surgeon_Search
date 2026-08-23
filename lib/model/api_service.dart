import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:doc/utils/app_config.dart';


class ApiService {
  static String get baseUrl =>
      '${AppConfig.apiBaseUrl}/sugeon';
  static String get healthcareBase =>
      '${AppConfig.apiBaseUrl}/healthcare';


  static Future<Map<String, dynamic>> createProfile({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String location,
    required String degree,
    required String speciality,
    required String subSpeciality,
    required String summaryProfile,
    required bool termsAccepted,
    required String profileId,
    required String portfolioLinks,
    required List<Map<String, dynamic>> workExperience,
    required List<String> departmentsAvailable,
    String yearsOfExperience = '',
    String surgicalExperience = '',
    String state = '',
    String district = '',
    File? imageFile,
    File? cvFile,
    File? highestDegreeFile,
    File? logBookFile,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/create-profile');
      debugPrint('🔗 Creating profile at URL: $uri');
      var request = http.MultipartRequest('POST', uri);

      // ✅ Normal fields
      request.fields['fullName'] = fullName;
      request.fields['phoneNumber'] = phoneNumber;
      request.fields['email'] = email;
      request.fields['location'] = location;
      request.fields['degree'] = degree;
      request.fields['speciality'] = speciality;
      request.fields['subSpeciality'] = subSpeciality;
      request.fields['summaryProfile'] = summaryProfile;
      request.fields['termsAccepted'] = termsAccepted.toString();
      request.fields['profile_id'] = profileId;
      request.fields['portfolioLinks'] = portfolioLinks;
      if (yearsOfExperience.isNotEmpty) {
        request.fields['yearsOfExperience'] = yearsOfExperience;
      }
      if (surgicalExperience.isNotEmpty) {
        request.fields['surgicalExperience'] = surgicalExperience;
      }
      if (state.isNotEmpty) request.fields['state'] = state;
      if (district.isNotEmpty) request.fields['district'] = district;

      // ✅ Free Trial for 2 Months (Default for new signups)
      request.fields['freetrail2month'] = 'true';

      // ✅ Add workExperience like array indices
      for (int i = 0; i < workExperience.length; i++) {
        final exp = workExperience[i];
        request.fields['workExperience[$i][designation]'] =
            exp['designation'] ?? '';
        request.fields['workExperience[$i][healthcareOrganization]'] =
            exp['healthcareOrganization'] ?? '';
        request.fields['workExperience[$i][from]'] = exp['from'] ?? '';
        request.fields['workExperience[$i][to]'] = exp['to'] ?? '';
        request.fields['workExperience[$i][location]'] = exp['location'] ?? '';
      }

      // ✅ Add departmentsAvailable like array indices
      for (int i = 0; i < departmentsAvailable.length; i++) {
        request.fields['departmentsAvailable[$i]'] = departmentsAvailable[i];
      }

      // ✅ Attach files
      if (imageFile != null) {
        // Determine content type based on extension
        final ext = imageFile.path.split('.').last.toLowerCase();
        final contentType = (ext == 'png') 
            ? MediaType('image', 'png') 
            : MediaType('image', 'jpeg');

        request.files.add(
          await http.MultipartFile.fromPath(
            'profilePicture', 
            imageFile.path,
            contentType: contentType,
          ),
        );
      }

      if (cvFile != null) {
        request.files.add(await http.MultipartFile.fromPath('cv', cvFile.path));
      }

      if (highestDegreeFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('highestDegree', highestDegreeFile.path),
        );
      }

      if (logBookFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('uploadLogBook', logBookFile.path),
        );
      }

      // ✅ Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📩 API Response (${response.statusCode}): ${response.body}');

      final body = response.body;
      final ct = response.headers['content-type'] ?? '';
      final trimmed = body.trimLeft();
      final isJson = ct.contains('application/json') ||
          trimmed.startsWith('{') ||
          trimmed.startsWith('[');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (isJson) {
          try {
            final data = jsonDecode(body);
            return {'success': true, 'data': data};
          } catch (_) {
            return {'success': true, 'data': {'raw': body}};
          }
        } else {
          return {'success': true, 'data': {'raw': body}};
        }
      } else {
        if (isJson) {
          try {
            final err = jsonDecode(body);
            return {'success': false, 'message': err['message'] ?? body};
          } catch (_) {
            return {'success': false, 'message': body};
          }
        } else {
          final snippet = body.length > 200 ? body.substring(0, 200) : body;
          return {
            'success': false,
            'message': 'HTTP ${response.statusCode}: $snippet'
          };
        }
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Fetch profile information by ID
  static Future<Map<String, dynamic>> fetchProfileInfo(String profileId) async {
    try {
      final url = Uri.parse('$baseUrl/profile-info/$profileId');
      final response = await http.get(url);

      debugPrint('📩 Fetch Profile Info Response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': 'Failed to fetch profile info'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}