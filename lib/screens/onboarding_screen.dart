import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/category_service.dart';
import '../services/supabase_service.dart';
import '../utils/time_utils.dart';
import '../widgets/category_selector_widget.dart';

enum _OnboardingStepKey { basic, topics, lessonInfo, photos, waivers }

class OnboardingScreen extends StatefulWidget {
  final String? initialUserType;
  final Map<String, dynamic>? existingProfile;

  const OnboardingScreen({
    super.key,
    this.initialUserType,
    this.existingProfile,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  bool _isSaving = false;

  // Immutable (after initial onboarding)
  String _userType = 'student'; // tutor | student | stutor (dummy: student only)
  String _gender = 'Prefer not to say';
  DateTime? _birthdateLocal;
  final _nameController = TextEditingController();

  // Editable
  List<String> _talentsOrGoals = [];
  final Set<String> _lessonLocations = <String>{}; // onsite/online
  final _aboutMeController = TextEditingController();
  final _aboutLessonController = TextEditingController(); // maps to experience_description
  final _rateController = TextEditingController(); // tutor only
  bool _parentParticipationWelcomed = false; // tutor only

  // Photos (data URLs)
  // - 1 main photo required
  // - optional 3 additional
  // Stored as: main_photo_path + profile_photos (includes main first)
  final List<String> _profilePhotos = [];
  final List<String> _certificatePhotos = []; // up to 3

  // Agreements (required for onboarding only)
  bool _agreeRoleWaiver = false;
  bool _agreeParentalConsent = false;

  // Location (optional for onboarding; used later for nearby)
  double? _latitude;
  double? _longitude;

  // Dummy support
  bool _dummyLocationOffsetApplied = false;
  bool _dummyDataPrefilled = false;
  final math.Random _dummyRng = math.Random();
  /// Fallback GPS when device location fails (dummy profiles must have coordinates).
  static const double _dummyFallbackLat = 37.5665;
  static const double _dummyFallbackLon = 126.9780;

  bool get _isEdit => widget.existingProfile != null;
  bool get _isDummy => !_isEdit && _isAnonymousSession();
  bool get _isTutor => _userType == 'tutor' || _userType == 'stutor';

  static const String _tutorWaiverTitle = 'Tutor Agreement & Liability Waiver';
  static const String _tutorWaiverText = '''
Professional Conduct: I certify that the information provided in my profile regarding my skills and qualifications is accurate and truthful. I agree to conduct all sessions with professionalism and respect.

Independent Status: I understand that Twingl is a matching platform and I am not an employee, agent, or contractor of Twingl. I am solely responsible for my actions and the content of my sessions.

Safety & Zero Tolerance: I agree to adhere to Twingl's strict safety guidelines. I understand that any form of harassment, discrimination, or inappropriate behavior will result in immediate termination of my account and potential legal action.

Release of Liability: I hereby release and hold harmless Twingl, its owners, and affiliates from any and all liability, claims, or demands arising out of my participation as a tutor.
''';

  static const String _studentWaiverTitle = 'Student Assumption of Risk & Waiver';
  static const String _studentWaiverText = '''
Voluntary Participation: I am voluntarily participating in activities (running, learning sessions, etc.) connected through Twingl.

Assumption of Risk: I understand that certain activities, particularly physical ones like running or hiking, carry inherent risks of injury. I knowingly assume all such risks, both known and unknown.

Personal Responsibility: I acknowledge that Twingl does not conduct background checks on every user and I am responsible for taking necessary safety precautions when meeting others.

Waiver of Claims: I waive any right to sue Twingl or its affiliates for any injury, loss, or damage associated with my participation.
''';

  static const String _parentalConsentTitle = 'Parental Consent & Guardian Release';
  static const String _parentalConsentText = '''
Guardian Authority: I represent that I am the parent or legal guardian of the minor registering for Twingl.

Consent to Participate: I hereby give permission for my child to participate in activities and connect with other users on Twingl.

Supervision & Responsibility: I understand that Twingl is an open community platform. I agree to supervise my child's use of the app and assume full responsibility for their safety and actions.

Emergency Medical Treatment: In the event of an emergency during a Twingl-related activity, I authorize necessary medical treatment for my child if I cannot be reached.
''';

  @override
  void initState() {
    super.initState();

    final initType = (widget.initialUserType ?? '').trim().toLowerCase();
    if (initType == 'tutor' || initType == 'student' || initType == 'stutor') {
      _userType = initType;
    }

    final existing = widget.existingProfile;
    if (existing != null) {
      final t = (existing['user_type'] as String?)?.trim().toLowerCase();
      if (t == 'tutor' || t == 'student' || t == 'stutor') _userType = t!;
      _nameController.text = (existing['name'] as String?) ?? '';
      _gender = (existing['gender'] as String?) ?? _gender;

      // birthdate (optional schema); fallback to approximate from stored age
      final b = (existing['birthdate'] as String?)?.trim();
      if (b != null && b.isNotEmpty) {
        final dt = DateTime.tryParse(b);
        if (dt != null) _birthdateLocal = DateTime(dt.year, dt.month, dt.day);
      } else {
        final age = existing['age'];
        if (age is int && age > 0) {
          final now = TimeUtils.nowLocal();
          _birthdateLocal = DateTime(now.year - age, now.month, now.day);
        }
      }

      final talents =
          (existing['talents'] as List<dynamic>?)?.map((e) => e.toString()).toList();
      if (talents != null) _talentsOrGoals = talents;

      final methods =
          (existing['teaching_methods'] as List<dynamic>?)?.map((e) => e.toString()).toList();
      if (methods != null) {
        _lessonLocations
          ..clear()
          ..addAll(methods.map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty));
      }

      _aboutMeController.text = (existing['about_me'] as String?) ?? '';
      _aboutLessonController.text = (existing['experience_description'] as String?) ?? '';

      final rate = (existing['tutoring_rate'] as String?)?.trim();
      if (rate != null && rate.isNotEmpty) _rateController.text = rate;
      _parentParticipationWelcomed =
          (existing['parent_participation_welcomed'] as bool?) ?? false;

      // photos
      final profilePhotos = existing['profile_photos'] as List<dynamic>?;
      final main = (existing['main_photo_path'] as String?)?.trim();
      if (profilePhotos != null && profilePhotos.isNotEmpty) {
        _profilePhotos
          ..clear()
          ..addAll(profilePhotos.map((e) => e.toString()).where((e) => e.trim().isNotEmpty));
      } else if (main != null && main.isNotEmpty) {
        _profilePhotos
          ..clear()
          ..add(main);
      }
      if (_profilePhotos.length > 4) _profilePhotos.removeRange(4, _profilePhotos.length);

      final certs = existing['certificate_photos'] as List<dynamic>?;
      if (certs != null && certs.isNotEmpty) {
        _certificatePhotos
          ..clear()
          ..addAll(certs.map((e) => e.toString()).where((e) => e.trim().isNotEmpty));
      }
      if (_certificatePhotos.length > 3) {
        _certificatePhotos.removeRange(3, _certificatePhotos.length);
      }

      final lat = existing['latitude'];
      final lon = existing['longitude'];
      if (lat is num) _latitude = lat.toDouble();
      if (lon is num) _longitude = lon.toDouble();
    }

    // Student profiles should not have "Lesson info". Clear any legacy fields loaded from older versions.
    if (_userType == 'student') {
      _lessonLocations.clear();
      _aboutLessonController.text = '';
      _rateController.text = '';
      _parentParticipationWelcomed = false;
    }

    _maybeLoadCurrentLocation();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_isDummy) {
        // Ensure dummy has GPS (try device first, then fallback).
        await _ensureDummyHasLocation();
        if (!mounted) return;
        // Dummy profiles: student only (initial and on regenerate).
        _prefillDummyOnboardingData(regenerate: false);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutMeController.dispose();
    _aboutLessonController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  bool _isAnonymousSession() {
    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null || token.isEmpty) return false;
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(decoded);
      return map is Map<String, dynamic> && map['is_anonymous'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _maybeLoadCurrentLocation() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final p = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      final adjusted = _maybeApplyDummyLocationOffset(p);
      if (!mounted) return;
      setState(() {
        _latitude = adjusted.latitude;
        _longitude = adjusted.longitude;
      });

      await SupabaseService.setLastKnownLocationForCurrentUser(
        lat: adjusted.latitude,
        lon: adjusted.longitude,
      );
    } catch (_) {
      // optional; for dummy we set fallback in _ensureDummyHasLocation / _prefillDummyOnboardingData
    }
  }

  /// For dummy flow only: ensure _latitude/_longitude are set (device GPS or fallback).
  Future<void> _ensureDummyHasLocation() async {
    if (!_isDummy) return;
    await _maybeLoadCurrentLocation();
    if (!mounted) return;
    if (_latitude == null || _longitude == null) {
      setState(() {
        _latitude = _dummyFallbackLat;
        _longitude = _dummyFallbackLon;
      });
    }
  }

  Position _maybeApplyDummyLocationOffset(Position original) {
    if (!_isDummy) return original;
    if (_dummyLocationOffsetApplied) return original;

    // 1..12 km random offset
    final distanceKm = 1 + _dummyRng.nextInt(12);
    final bearing = _dummyRng.nextDouble() * 2 * math.pi;

    const earthRadiusKm = 6371.0;
    final lat1 = original.latitude * (math.pi / 180.0);
    final lon1 = original.longitude * (math.pi / 180.0);
    final dr = distanceKm / earthRadiusKm;

    final lat2 = math.asin(
      math.sin(lat1) * math.cos(dr) + math.cos(lat1) * math.sin(dr) * math.cos(bearing),
    );
    final lon2 = lon1 +
        math.atan2(
          math.sin(bearing) * math.sin(dr) * math.cos(lat1),
          math.cos(dr) - math.sin(lat1) * math.sin(lat2),
        );

    double wrapLon(double lonRad) {
      var x = lonRad;
      while (x > math.pi) {
        x -= 2 * math.pi;
      }
      while (x < -math.pi) {
        x += 2 * math.pi;
      }
      return x;
    }

    final newLat = lat2 * (180.0 / math.pi);
    final newLon = wrapLon(lon2) * (180.0 / math.pi);

    _dummyLocationOffsetApplied = true;
    return Position(
      latitude: newLat,
      longitude: newLon,
      timestamp: original.timestamp,
      accuracy: original.accuracy,
      altitude: original.altitude,
      altitudeAccuracy: original.altitudeAccuracy,
      heading: original.heading,
      headingAccuracy: original.headingAccuracy,
      speed: original.speed,
      speedAccuracy: original.speedAccuracy,
    );
  }

  Future<List<String>> _loadAllCategoryItemsFlat() async {
    final categories = await CategoryService.loadCategories();
    final out = <String>[];
    for (final c in categories) {
      for (final sub in c.subItems) {
        out.addAll(sub.items);
      }
    }
    return out.where((e) => e.trim().isNotEmpty).toList();
  }

  List<String> _pickRandomUnique(List<String> items, int count) {
    final unique = items.toSet().toList();
    unique.shuffle(_dummyRng);
    final maxN = math.min(6, unique.length);
    final n = math.max(1, math.min(count, maxN));
    return unique.take(n).toList();
  }

  Future<void> _prefillDummyOnboardingData({required bool regenerate}) async {
    if (_dummyDataPrefilled && !regenerate) return;
    _dummyDataPrefilled = true;

    // Dummy flow: always student. Otherwise use current role or force student on regenerate.
    final pickedUserType = _isDummy ? 'student' : (regenerate ? 'student' : _userType);

    const firstNames = <String>[
      'John','Michael','David','James','Robert','William','Christopher','Daniel','Matthew','Joshua',
      'Andrew','Joseph','Anthony','Ryan','Nicholas','Samuel','Benjamin','Jonathan','Brandon','Kevin',
    ];
    const lastNames = <String>[
      'Smith','Johnson','Williams','Brown','Jones','Garcia','Miller','Davis','Rodriguez','Martinez',
      'Hernandez','Lopez','Gonzalez','Wilson','Anderson','Thomas','Taylor','Moore','Jackson','Martin',
    ];
    final first = firstNames[_dummyRng.nextInt(firstNames.length)];
    final last = lastNames[_dummyRng.nextInt(lastNames.length)];
    final baseName = '$first $last';
    final name = pickedUserType == 'student' ? '$baseName ST' : baseName;

    const genders = ['man', 'woman', 'non-binary', 'Prefer not to say'];
    final gender = genders[_dummyRng.nextInt(genders.length)];
    final age = 18 + _dummyRng.nextInt(38); // 18..55
    final now = TimeUtils.nowLocal();
    final birth = DateTime(now.year - age, now.month, now.day);

    final allItems = await _loadAllCategoryItemsFlat();
    final picked = _pickRandomUnique(allItems, 1 + _dummyRng.nextInt(6));

    final aboutTemplates = <String>[
      'Friendly tutor who loves helping beginners.',
      'Patient and structured lessons, focused on progress.',
      'I tailor sessions to your goals and schedule.',
      'Let’s build skills with practical exercises.',
      'Supportive coaching with clear feedback.',
    ];
    final about = aboutTemplates[_dummyRng.nextInt(aboutTemplates.length)];

    final aboutLessonTemplates = <String>[
      'We will set clear goals and track progress every session.',
      'Beginner-friendly lessons with step-by-step guidance.',
      'Flexible sessions tailored to your pace.',
    ];
    final aboutLesson = aboutLessonTemplates[_dummyRng.nextInt(aboutLessonTemplates.length)];

    if (!mounted) return;
    setState(() {
      // Dummy profiles must have GPS; use fallback if still missing (e.g. permission denied).
      if (_isDummy && (_latitude == null || _longitude == null)) {
        _latitude = _dummyFallbackLat;
        _longitude = _dummyFallbackLon;
      }
      _userType = pickedUserType;
      _nameController.text = name;
      _gender = gender;
      _birthdateLocal = birth;
      _talentsOrGoals = picked;
      _aboutMeController.text = about;
      if (_userType == 'tutor' || _userType == 'stutor') {
        _lessonLocations
          ..clear()
          ..add('online')
          ..add(_dummyRng.nextBool() ? 'onsite' : 'online');
        _aboutLessonController.text = aboutLesson;
      } else {
        _lessonLocations.clear();
        _aboutLessonController.text = '';
      }
      if (_userType == 'tutor' || _userType == 'stutor') {
        _rateController.text = (20 + _dummyRng.nextInt(81)).toString(); // 20..100
        _parentParticipationWelcomed = _dummyRng.nextBool();
      } else {
        _rateController.text = '';
        _parentParticipationWelcomed = false;
      }

      // If the role changes, waiver requirements change too. Keep agreement state clean.
      _agreeRoleWaiver = false;
      _agreeParentalConsent = false;

      // Role change can change step count; keep current index valid.
      final last = _stepKeys(userTypeOverride: _userType).length - 1;
      _step = _step.clamp(0, last);
      // Photos intentionally NOT filled; user attaches manually.
    });
  }

  Future<String?> _pickSinglePhotoAsDataUrl() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (file == null) return null;
      final bytes = await file.readAsBytes();
      final mime = _guessMimeType(file.name);
      return 'data:$mime;base64,${base64Encode(bytes)}';
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick photo: $e')),
      );
      return null;
    }
  }

  Future<List<String>> _pickMultiPhotosAsDataUrls({required int maxAdd}) async {
    try {
      final picker = ImagePicker();
      final files = await picker.pickMultiImage(imageQuality: 70);
      if (files.isEmpty) return [];
      final out = <String>[];
      for (final f in files.take(maxAdd)) {
        final bytes = await f.readAsBytes();
        final mime = _guessMimeType(f.name);
        out.add('data:$mime;base64,${base64Encode(bytes)}');
      }
      return out;
    } catch (e) {
      if (!mounted) return [];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick photos: $e')),
      );
      return [];
    }
  }

  String _guessMimeType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  int? _computedAge() {
    final b = _birthdateLocal;
    if (b == null) return null;
    final now = TimeUtils.nowLocal();
    int age = now.year - b.year;
    final hasHadBirthday = (now.month > b.month) || (now.month == b.month && now.day >= b.day);
    if (!hasHadBirthday) age -= 1;
    return age.clamp(0, 130);
  }

  bool get _requiresParentalConsent {
    final age = _computedAge();
    if (age == null) return false;
    return age < 18;
  }

  String _birthdateLabel() {
    final b = _birthdateLocal;
    if (b == null) return 'Select birthdate';
    return DateFormat('yyyy-MM-dd').format(b);
  }

  Future<void> _pickBirthdate() async {
    if (_isEdit) return; // immutable
    final now = TimeUtils.nowLocal();
    final initial = _birthdateLocal ?? DateTime(now.year - 20, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime(now.year - 5, 12, 31),
    );
    if (picked == null) return;
    setState(() => _birthdateLocal = DateTime(picked.year, picked.month, picked.day));
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  List<_OnboardingStepKey> _stepKeys({String? userTypeOverride}) {
    final type = (userTypeOverride ?? _userType).trim().toLowerCase();
    final isTutor = type == 'tutor' || type == 'stutor';
    return <_OnboardingStepKey>[
      _OnboardingStepKey.basic,
      _OnboardingStepKey.topics,
      if (isTutor) _OnboardingStepKey.lessonInfo,
      _OnboardingStepKey.photos,
      if (!_isEdit) _OnboardingStepKey.waivers,
    ];
  }

  bool _validateStepKey(_OnboardingStepKey key) {
    switch (key) {
      case _OnboardingStepKey.basic:
        if ((_nameController.text.trim()).isEmpty) {
          _snack('Name is required.');
          return false;
        }
        if (_birthdateLocal == null) {
          _snack('Birthdate is required.');
          return false;
        }
        return true;
      case _OnboardingStepKey.topics:
        if (_talentsOrGoals.isEmpty) {
          _snack('Please select at least 1 topic.');
          return false;
        }
        return true;
      case _OnboardingStepKey.lessonInfo:
        if (_lessonLocations.isEmpty) {
          _snack('Please select at least one lesson location (Online/Onsite).');
          return false;
        }
        final rate = _rateController.text.trim();
        if (rate.isEmpty) {
          _snack('Tutoring rate per hour is required.');
          return false;
        }
        if (int.tryParse(rate) == null) {
          _snack('Tutoring rate must be a number.');
          return false;
        }
        return true;
      case _OnboardingStepKey.photos:
        if (_profilePhotos.isEmpty) {
          _snack('Please select 1 profile photo (required).');
          return false;
        }
        return true;
      case _OnboardingStepKey.waivers:
        if (_isEdit) return true;
        if (!_agreeRoleWaiver) {
          _snack(_isTutor ? 'Please agree to the Tutor waiver.' : 'Please agree to the Student waiver.');
          return false;
        }
        if (_requiresParentalConsent && !_agreeParentalConsent) {
          _snack('Parental consent is required for minors.');
          return false;
        }
        return true;
    }
  }

  bool _validateStep(int step) {
    final keys = _stepKeys();
    if (step < 0 || step >= keys.length) return true;
    return _validateStepKey(keys[step]);
  }

  Future<void> _save() async {
    if (_isSaving) return;

    // Validate all required steps.
    final keys = _stepKeys();
    for (int i = 0; i < keys.length; i++) {
      if (!_validateStepKey(keys[i])) {
        setState(() => _step = i);
        return;
      }
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _snack('You are not logged in.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final existing = widget.existingProfile;
      final fixedUserType = (_isEdit ? (existing?['user_type'] as String?) : _userType) ?? _userType;
      final isTutorProfile = fixedUserType.trim().toLowerCase() == 'tutor' || fixedUserType.trim().toLowerCase() == 'stutor';
      final fixedName = _isEdit ? (existing?['name'] as String?) : _nameController.text.trim();
      final fixedGender = _isEdit ? (existing?['gender'] as String?) : _gender;

      final birth = _birthdateLocal;
      final age = _computedAge();

      final payload = <String, dynamic>{
        'user_id': user.id,
        'user_type': fixedUserType,
        'name': fixedName?.trim(),
        'gender': fixedGender,
        'age': age,
        'latitude': _latitude,
        'longitude': _longitude,
        'talents': _talentsOrGoals,
        // Tutor only: lesson info. Students should not keep these fields.
        'teaching_methods': isTutorProfile ? _lessonLocations.toList() : <String>[],
        'about_me': _aboutMeController.text.trim().isEmpty ? null : _aboutMeController.text.trim(),
        // Reuse existing schema column (per MIGRATE_PROFILES_UNIFY_TALENTS.sql comment).
        'experience_description': isTutorProfile
            ? (_aboutLessonController.text.trim().isEmpty ? null : _aboutLessonController.text.trim())
            : null,
        'parent_participation_welcomed': isTutorProfile ? _parentParticipationWelcomed : false,
        'tutoring_rate': isTutorProfile ? _rateController.text.trim() : null,
        // Photos
        'main_photo_path': _profilePhotos.isNotEmpty ? _profilePhotos.first : null,
        'profile_photos': _profilePhotos.isNotEmpty ? _profilePhotos : null,
        'certificate_photos': _certificatePhotos.isNotEmpty ? _certificatePhotos : null,
        'updated_at': TimeUtils.nowUtcIso(),
      };

      // Optional: if DB has birthdate column, store it.
      if (!_isEdit && birth != null) {
        payload['birthdate'] = DateFormat('yyyy-MM-dd').format(birth);
      } else if (_isEdit && birth != null && (existing?.containsKey('birthdate') == true)) {
        payload['birthdate'] = DateFormat('yyyy-MM-dd').format(birth);
      }

      try {
        await SupabaseService.upsertProfile(payload);
      } catch (e) {
        final msg = e.toString();
        // If birthdate column doesn't exist, retry without it (age is still stored).
        if (msg.contains('PGRST204') && msg.toLowerCase().contains('birthdate')) {
          payload.remove('birthdate');
          await SupabaseService.upsertProfile(payload);
        } else {
          rethrow;
        }
      }

      if (_latitude != null && _longitude != null) {
        await SupabaseService.updateUserLocation(
          latitude: _latitude!,
          longitude: _longitude!,
        );
      }

      // Agreements (only for onboarding)
      if (!_isEdit) {
        // Role-specific waiver
        await SupabaseService.saveUserAgreement(
          agreementType: _isTutor ? 'trainer_terms' : 'trainee_waiver',
          version: 'v1.0',
        );
        // Parental consent only when applicable (minor)
        if (_requiresParentalConsent) {
          await SupabaseService.saveUserAgreement(
            agreementType: 'parental_consent',
            version: 'v1.0',
          );
        }
      }

      if (!mounted) return;
      if (_isEdit) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (!mounted) return;
      _snack('Failed to save profile: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _sectionTitle(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(s, style: Theme.of(context).textTheme.titleMedium),
      );

  Widget _photoGrid({
    required List<String> photos,
    required int maxCount,
    required VoidCallback onAdd,
    required void Function(int index) onRemove,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              helperText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                  ),
            ),
          ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (int i = 0; i < photos.length; i++)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      base64Decode(photos[i].split(',').last),
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: -8,
                    top: -8,
                    child: IconButton(
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                      onPressed: _isSaving ? null : () => onRemove(i),
                      icon: const Icon(Icons.cancel, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            if (photos.length < maxCount)
              SizedBox(
                width: 92,
                height: 92,
                child: OutlinedButton(
                  onPressed: _isSaving ? null : onAdd,
                  child: const Icon(Icons.add),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${photos.length}/$maxCount',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
              ),
        ),
      ],
    );
  }

  List<Step> _buildSteps() {
    final keys = _stepKeys();
    final steps = <Step>[];

    for (int i = 0; i < keys.length; i++) {
      final key = keys[i];
      final isActive = _step >= i;
      final state = _step > i ? StepState.complete : StepState.indexed;

      switch (key) {
        case _OnboardingStepKey.basic:
          final disabledFill = Theme.of(context).colorScheme.surfaceContainerHighest;
          steps.add(
            Step(
              title: const Text('Role & Basic info'),
              isActive: isActive,
              state: state,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isDummy)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text('Demo mode: random data is filled (photos skipped).'),
                          ),
                          TextButton(
                            onPressed: _isSaving ? null : () => _prefillDummyOnboardingData(regenerate: true),
                            child: const Text('Regenerate'),
                          ),
                        ],
                      ),
                    ),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'tutor', label: Text('Tutor')),
                      ButtonSegment(value: 'student', label: Text('Student')),
                    ],
                    selected: {_userType},
                    onSelectionChanged: (_isDummy || _isEdit)
                        ? null
                        : (s) {
                            final nextType = s.first;
                            setState(() {
                              _userType = nextType;
                              if (_userType == 'student') {
                                // Students don't have Lesson info.
                                _lessonLocations.clear();
                                _aboutLessonController.text = '';
                                _rateController.text = '';
                                _parentParticipationWelcomed = false;
                              }
                              final last = _stepKeys(userTypeOverride: _userType).length - 1;
                              _step = _step.clamp(0, last);
                            });
                          },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    enabled: !_isEdit,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: const OutlineInputBorder(),
                      filled: _isEdit,
                      fillColor: _isEdit ? disabledFill : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration: InputDecoration(
                      labelText: 'Gender',
                      border: const OutlineInputBorder(),
                      filled: _isEdit,
                      fillColor: _isEdit ? disabledFill : null,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'man', child: Text('Man')),
                      DropdownMenuItem(value: 'woman', child: Text('Woman')),
                      DropdownMenuItem(value: 'non-binary', child: Text('Non-binary')),
                      DropdownMenuItem(value: 'Prefer not to say', child: Text('Prefer not to say')),
                    ],
                    onChanged: _isEdit ? null : (v) => setState(() => _gender = v ?? 'Prefer not to say'),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: (_isSaving || _isEdit) ? null : _pickBirthdate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Birthdate',
                        border: const OutlineInputBorder(),
                        filled: _isEdit,
                        fillColor: _isEdit ? disabledFill : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _birthdateLabel(),
                              style: TextStyle(
                                color: _birthdateLocal == null
                                    ? Theme.of(context).colorScheme.onSurface.withAlpha(150)
                                    : null,
                              ),
                            ),
                          ),
                          const Icon(Icons.calendar_month),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_birthdateLocal != null)
                    Text(
                      'Age: ${_computedAge() ?? ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                          ),
                    ),
                  const SizedBox(height: 16),
                  _sectionTitle('About me (optional)'),
                  TextField(
                    controller: _aboutMeController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Tell others about you…',
                    ),
                  ),
                ],
              ),
            ),
          );
          break;

        case _OnboardingStepKey.topics:
          steps.add(
            Step(
              title: Text(_isTutor ? 'What can you teach?' : 'What do you want to learn?'),
              isActive: isActive,
              state: state,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategorySelectorWidget(
                    selectedItems: _talentsOrGoals,
                    onSelectionChanged: (v) => setState(() => _talentsOrGoals = v),
                    title: _isTutor ? 'What can you teach?' : 'What do you want to learn?',
                    hint: 'Select 1–6.',
                  ),
                ],
              ),
            ),
          );
          break;

        case _OnboardingStepKey.lessonInfo:
          steps.add(
            Step(
              title: const Text('Lesson info'),
              isActive: isActive,
              state: state,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('About the lesson (optional)'),
                  TextField(
                    controller: _aboutLessonController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Share lesson details, expectations, goals…',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle('Lesson Location (required)'),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Onsite'),
                        selected: _lessonLocations.contains('onsite'),
                        onSelected: (v) => setState(() {
                          v ? _lessonLocations.add('onsite') : _lessonLocations.remove('onsite');
                        }),
                      ),
                      FilterChip(
                        label: const Text('Online'),
                        selected: _lessonLocations.contains('online'),
                        onSelected: (v) => setState(() {
                          v ? _lessonLocations.add('online') : _lessonLocations.remove('online');
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle('Tutoring Rate per Hour (required)'),
                  TextField(
                    controller: _rateController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'e.g. 40',
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: _parentParticipationWelcomed,
                    onChanged: (v) => setState(() => _parentParticipationWelcomed = v ?? false),
                    title: const Text('Parent participation welcomed (optional)'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          );
          break;

        case _OnboardingStepKey.photos:
          steps.add(
            Step(
              title: const Text('Photos'),
              isActive: isActive,
              state: state,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Profile photos'),
                  _photoGrid(
                    photos: _profilePhotos,
                    maxCount: 4,
                    helperText: '1 required + up to 3 optional. (Can be changed later)',
                    onAdd: () async {
                      // If none, pick single as main; otherwise multi-add.
                      if (_profilePhotos.isEmpty) {
                        final one = await _pickSinglePhotoAsDataUrl();
                        if (one == null) return;
                        if (!mounted) return;
                        setState(() => _profilePhotos.add(one));
                      } else {
                        final remaining = 4 - _profilePhotos.length;
                        final added = await _pickMultiPhotosAsDataUrls(maxAdd: remaining);
                        if (!mounted) return;
                        setState(() => _profilePhotos.addAll(added));
                      }
                    },
                    onRemove: (idx) => setState(() => _profilePhotos.removeAt(idx)),
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle('Certificates / Awards / Degrees (optional)'),
                  _photoGrid(
                    photos: _certificatePhotos,
                    maxCount: 3,
                    helperText: 'Up to 3 (optional). (Can be changed later)',
                    onAdd: () async {
                      final remaining = 3 - _certificatePhotos.length;
                      final added = await _pickMultiPhotosAsDataUrls(maxAdd: remaining);
                      if (!mounted) return;
                      setState(() => _certificatePhotos.addAll(added));
                    },
                    onRemove: (idx) => setState(() => _certificatePhotos.removeAt(idx)),
                  ),
                ],
              ),
            ),
          );
          break;

        case _OnboardingStepKey.waivers:
          steps.add(
            Step(
              title: const Text('Waivers'),
              isActive: isActive,
              state: state,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Required before finishing.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isTutor ? _tutorWaiverTitle : _studentWaiverTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 220,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _isTutor ? _tutorWaiverText : _studentWaiverText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: _agreeRoleWaiver,
                    onChanged: (v) => setState(() => _agreeRoleWaiver = v ?? false),
                    title: Text(
                      _isTutor
                          ? 'I have read and agree to the Tutor Agreement & Liability Waiver'
                          : 'I have read and agree to the Student Assumption of Risk & Waiver',
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 10),
                  if (_requiresParentalConsent) ...[
                    Text(
                      _parentalConsentTitle,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 220,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _parentalConsentText,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _agreeParentalConsent,
                      onChanged: (v) => setState(() => _agreeParentalConsent = v ?? false),
                      title: const Text('I have read and agree to the Parental Consent & Guardian Release'),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ] else ...[
                    Text(
                      'Parental consent is only required for minors (under 18).',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                          ),
                    ),
                  ],
                ],
              ),
            ),
          );
          break;
      }
    }

    return steps;
  }

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps();
    final lastStep = steps.length - 1;
    final canGoBack = _step > 0;
    final isLast = _step == lastStep;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Profile' : 'Onboarding'),
      ),
      body: SafeArea(
        child: Stepper(
          // IMPORTANT: Stepper asserts that the number of steps does not change across updates.
          // Our onboarding flow changes step count depending on Tutor/Student (lesson info step).
          // Use a key that changes when the flow shape changes to force a fresh Stepper instance.
          key: ValueKey<String>('stepper:${_isEdit ? 'edit' : 'new'}:${_userType}:${_stepKeys().length}'),
          currentStep: _step.clamp(0, lastStep),
          steps: steps,
          onStepTapped: (i) {
            // Allow jumping backwards freely; forward only if previous steps are valid.
            if (i <= _step) {
              setState(() => _step = i);
              return;
            }
            for (int k = _step; k < i; k++) {
              if (!_validateStep(k)) return;
            }
            setState(() => _step = i);
          },
          onStepContinue: _isSaving
              ? null
              : () async {
                  if (!_validateStep(_step)) return;
                  if (isLast) {
                    await _save();
                    return;
                  }
                  setState(() => _step = (_step + 1).clamp(0, lastStep));
                },
          onStepCancel: _isSaving
              ? null
              : () {
                  if (!canGoBack) return;
                  setState(() => _step = (_step - 1).clamp(0, lastStep));
                },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: canGoBack ? details.onStepCancel : null,
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: details.onStepContinue,
                      child: _isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isLast ? (_isEdit ? 'Save' : 'Finish') : 'Next'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

