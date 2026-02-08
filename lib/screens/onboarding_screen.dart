import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
import '../services/category_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import '../widgets/category_selector_widget.dart';

enum _OnboardingStepKey { basic, topics, lessonInfo, goals, photos, waivers }

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
  String _userType = 'student'; // tutor | student | twiner (dummy: user can choose Tutor or Student)
  String _gender = 'Prefer not to say';
  DateTime? _birthdateLocal;
  final _nameController = TextEditingController();

  // Editable
  List<String> _talentsOrGoals = [];
  /// Twiner 전용: "What do you want to learn?" (Lesson info 다음 스텝)
  List<String> _goalsForTwiner = [];
  final Set<String> _lessonLocations = <String>{}; // onsite/online
  final _aboutMeController = TextEditingController();
  final _aboutLessonController = TextEditingController(); // maps to experience_description
  final _rateController = TextEditingController(); // tutor only
  bool _parentParticipationWelcomed = false; // tutor only

  // Photo: single required profile photo (data URL)
  final List<String> _profilePhotos = []; // max 1

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
  bool get _isTutor => _userType == 'tutor' || _userType == 'twiner';

  /// Tutor→Twiner 전환: goals만 추가, Lesson info 스킵. Save 전까지 DB에 user_type 저장 안 함.
  bool get _isTwinerFromTutor {
    if (!_isEdit || _userType != 'twiner') return false;
    final existing = widget.existingProfile;
    if (existing == null) return false;
    final initType = (widget.initialUserType ?? '').trim().toLowerCase();
    final existingType = (existing['user_type'] as String?)?.trim().toLowerCase() ?? '';
    return initType == 'twiner' && existingType == 'tutor';
  }

  /// Student→Twiner 전환: talents + Lesson info 추가. Save 전까지 DB에 user_type 저장 안 함.
  bool get _isTwinerFromStudent {
    if (!_isEdit || _userType != 'twiner') return false;
    final existing = widget.existingProfile;
    if (existing == null) return false;
    final initType = (widget.initialUserType ?? '').trim().toLowerCase();
    final existingType = (existing['user_type'] as String?)?.trim().toLowerCase() ?? '';
    return initType == 'twiner' && existingType == 'student';
  }

  /// Twiner 전환 플로우 전체 (Tutor→Twiner 또는 Student→Twiner)
  bool get _isTwinerConversion => _isTwinerFromTutor || _isTwinerFromStudent;

  @override
  void initState() {
    super.initState();

    final initType = (widget.initialUserType ?? '').trim().toLowerCase();
    if (initType == 'tutor' || initType == 'student' || initType == 'twiner') {
      _userType = initType;
    }

    final existing = widget.existingProfile;
    if (existing != null) {
      final t = (existing['user_type'] as String?)?.trim().toLowerCase();
      if (t == 'tutor' || t == 'student' || t == 'twiner') {
        // Twiner 전환 플로우: initialUserType twiner이고 기존이 tutor/student면 UI는 twiner 유지(Save 시에만 DB 반영)
        if (initType == 'twiner' && (t == 'tutor' || t == 'student')) {
          _userType = 'twiner';
        } else {
          _userType = t!;
        }
      }
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

      // Student: goals; Tutor: talents; Twiner: talents. Student→Twiner 전환 시 talents용(비어 있음), Tutor→Twiner 시 goals용
      final userType = (existing['user_type'] as String?)?.trim().toLowerCase() ?? '';
      if (userType == 'student') {
        if (initType == 'twiner') {
          // Student→Twiner: "What can you teach?"(talents) 입력. 학생은 talents 없음; goals는 다음 스텝에서 입력
          _talentsOrGoals = (existing['talents'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
          final goals = (existing['goals'] as List<dynamic>?)?.map((e) => e.toString()).toList();
          if (goals != null) _goalsForTwiner = goals;
        } else {
          final goals = (existing['goals'] as List<dynamic>?) ?? (existing['talents'] as List<dynamic>?);
          if (goals != null) _talentsOrGoals = goals.map((e) => e.toString()).toList();
        }
      } else if (userType == 'twiner') {
        final talents = existing['talents'] as List<dynamic>?;
        final goals = existing['goals'] as List<dynamic>?;
        final addingStudentSide = (talents != null && talents.isNotEmpty) && (goals == null || goals.isEmpty);
        if (addingStudentSide) {
          if (goals != null && goals.isNotEmpty) _talentsOrGoals = goals.map((e) => e.toString()).toList();
        } else {
          if (talents != null) _talentsOrGoals = talents.map((e) => e.toString()).toList();
        }
        if (goals != null) _goalsForTwiner = goals.map((e) => e.toString()).toList();
      } else if (userType == 'tutor' && initType == 'twiner') {
        // Tutor→Twiner 전환: "What do you want to learn?"(goals)만 입력. 기존 goals 있으면 로드
        final goals = (existing['goals'] as List<dynamic>?)?.map((e) => e.toString()).toList();
        if (goals != null) _talentsOrGoals = goals;
      } else {
        final talents = (existing['talents'] as List<dynamic>?)?.map((e) => e.toString()).toList();
        if (talents != null) _talentsOrGoals = talents;
      }

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

      // photo: single required
      final profilePhotos = existing['profile_photos'] as List<dynamic>?;
      final main = (existing['main_photo_path'] as String?)?.trim();
      if (profilePhotos != null && profilePhotos.isNotEmpty) {
        final list = profilePhotos.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
        if (list.isNotEmpty) {
          _profilePhotos
            ..clear()
            ..add(list.first);
        }
      } else if (main != null && main.isNotEmpty) {
        _profilePhotos
          ..clear()
          ..add(main);
      }
      if (_profilePhotos.length > 1) _profilePhotos.removeRange(1, _profilePhotos.length);

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
        // Dummy profiles: prefill with current role (default student); user can switch Tutor/Student and regenerate.
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

    // Dummy: use current _userType (Tutor or Student). Non-dummy regenerate: force student.
    final pickedUserType = _isDummy ? _userType : (regenerate ? 'student' : _userType);

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
      if (_userType == 'tutor' || _userType == 'twiner') {
        _lessonLocations
          ..clear()
          ..add('online')
          ..add(_dummyRng.nextBool() ? 'onsite' : 'online');
        _aboutLessonController.text = aboutLesson;
      } else {
        _lessonLocations.clear();
        _aboutLessonController.text = '';
      }
      if (_userType == 'tutor' || _userType == 'twiner') {
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

  /// Max longest edge for saved profile photo (reduces storage).
  static const int _profilePhotoMaxSize = 300;
  static const int _profilePhotoQuality = 80;

  Future<String?> _pickSinglePhotoAsDataUrl() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file == null) return null;
      final bytes = await file.readAsBytes();

      final Uint8List outBytes = await _compressProfilePhoto(bytes);
      return 'data:image/jpeg;base64,${base64Encode(outBytes)}';
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.failedToPickPhoto(e.toString()))),
      );
      return null;
    }
  }

  /// Resize and compress image for profile photo (max 800px, JPEG 80%).
  Future<Uint8List> _compressProfilePhoto(Uint8List bytes) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: _profilePhotoMaxSize,
        minHeight: _profilePhotoMaxSize,
        quality: _profilePhotoQuality,
        format: CompressFormat.jpeg,
      );
      return result;
    } catch (_) {
      return bytes;
    }
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
    if (b == null) return AppLocalizations.of(context)!.selectBirthdate;
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
    final isTutor = type == 'tutor' || type == 'twiner';
    // Tutor→Twiner 전환 시에만 Lesson info 스킵. Student→Twiner는 Lesson info 포함
    final includeLessonInfo = isTutor && !_isTwinerFromTutor;
    // Twiner(기존 편집·Student→Twiner): Lesson info 다음에 "What do you want to learn?" 스텝
    final includeGoalsForTwiner = type == 'twiner' && includeLessonInfo;
    return <_OnboardingStepKey>[
      _OnboardingStepKey.basic,
      _OnboardingStepKey.topics,
      if (includeLessonInfo) _OnboardingStepKey.lessonInfo,
      if (includeGoalsForTwiner) _OnboardingStepKey.goals,
      _OnboardingStepKey.photos,
      if (!_isEdit || _isTwinerConversion) _OnboardingStepKey.waivers,
    ];
  }

  /// Waivers 단계에서 표시할 역할: Student→Twiner는 Tutor waiver, Tutor→Twiner는 Student waiver
  bool get _showTutorWaiverInStep =>
      _isTwinerFromStudent ? true : (_isTwinerFromTutor ? false : _isTutor);

  bool _validateStepKey(_OnboardingStepKey key) {
    final l10n = AppLocalizations.of(context)!;
    switch (key) {
      case _OnboardingStepKey.basic:
        if ((_nameController.text.trim()).isEmpty) {
          _snack(l10n.nameRequired);
          return false;
        }
        if (_birthdateLocal == null) {
          _snack(l10n.birthdateRequired);
          return false;
        }
        return true;
      case _OnboardingStepKey.topics:
        if (_talentsOrGoals.isEmpty) {
          _snack(l10n.selectAtLeastOneTopic);
          return false;
        }
        return true;
      case _OnboardingStepKey.lessonInfo:
        if (_lessonLocations.isEmpty) {
          _snack(l10n.selectLessonLocation);
          return false;
        }
        final rate = _rateController.text.trim();
        if (rate.isEmpty) {
          _snack(l10n.tutoringRateRequired);
          return false;
        }
        if (double.tryParse(rate) == null) {
          _snack(l10n.tutoringRateMustBeNumber);
          return false;
        }
        return true;
      case _OnboardingStepKey.goals:
        if (_goalsForTwiner.isEmpty) {
          _snack(l10n.selectAtLeastOneTopicToLearn);
          return false;
        }
        return true;
      case _OnboardingStepKey.photos:
        if (_profilePhotos.isEmpty) {
          _snack(l10n.selectOneProfilePhoto);
          return false;
        }
        return true;
      case _OnboardingStepKey.waivers:
        if (_isEdit && !_isTwinerConversion) return true;
        if (!_agreeRoleWaiver) {
          _snack(_showTutorWaiverInStep ? l10n.pleaseAgreeToTutorWaiver : l10n.pleaseAgreeToStudentWaiver);
          return false;
        }
        if (_requiresParentalConsent && !_agreeParentalConsent) {
          _snack(l10n.parentalConsentRequiredForMinors);
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
      _snack(AppLocalizations.of(context)!.notLoggedIn);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final existing = widget.existingProfile;
      // Twiner 전환 플로우에서 Save 시에만 user_type을 twiner로 DB에 저장
      final fixedUserType = _isTwinerConversion
          ? 'twiner'
          : ((_isEdit ? (existing?['user_type'] as String?) : _userType) ?? _userType);
      final isTutorProfile = fixedUserType.trim().toLowerCase() == 'tutor' || fixedUserType.trim().toLowerCase() == 'twiner';
      final fixedName = _isEdit ? (existing?['name'] as String?) : _nameController.text.trim();
      final fixedGender = _isEdit ? (existing?['gender'] as String?) : _gender;

      final birth = _birthdateLocal;
      final age = _computedAge();

      // Student: "What do you want to learn?" → goals; Tutor/Twiner: "What can you teach?" → talents
      final isStudentProfile = fixedUserType.trim().toLowerCase() == 'student';
      final payload = <String, dynamic>{
        'user_id': user.id,
        'user_type': fixedUserType,
        'name': fixedName?.trim(),
        'gender': fixedGender,
        'age': age,
        'latitude': _latitude,
        'longitude': _longitude,
        'talents': isTutorProfile ? _talentsOrGoals : <String>[],
        // Tutor only: lesson info. Students should not keep these fields.
        'teaching_methods': isTutorProfile ? _lessonLocations.toList() : <String>[],
        'about_me': _aboutMeController.text.trim().isEmpty ? null : _aboutMeController.text.trim(),
        // Reuse existing schema column (per MIGRATE_PROFILES_UNIFY_TALENTS.sql comment).
        'experience_description': isTutorProfile
            ? (_aboutLessonController.text.trim().isEmpty ? null : _aboutLessonController.text.trim())
            : null,
        'parent_participation_welcomed': isTutorProfile ? _parentParticipationWelcomed : false,
        'tutoring_rate': isTutorProfile ? _rateController.text.trim() : null,
        // Single required profile photo
        'main_photo_path': _profilePhotos.isNotEmpty ? _profilePhotos.first : null,
        'profile_photos': null,
        'certificate_photos': null,
        'updated_at': TimeUtils.nowUtcIso(),
      };

      if (isStudentProfile) payload['goals'] = _talentsOrGoals;

      // Tutor→Twiner 전환: goals만 새로 넣고, talents·Lesson info는 기존 값 유지
      if (_isTwinerFromTutor && existing != null) {
        payload['talents'] = existing['talents'] ?? <dynamic>[];
        payload['goals'] = _talentsOrGoals;
        payload['teaching_methods'] = existing['teaching_methods'] ?? <dynamic>[];
        payload['experience_description'] = existing['experience_description'];
        payload['parent_participation_welcomed'] = existing['parent_participation_welcomed'] ?? false;
        payload['tutoring_rate'] = existing['tutoring_rate'];
      }

      // Student→Twiner 전환: talents + Lesson info + goals(What do you want to learn?) 새로 넣기
      if (_isTwinerFromStudent && existing != null) {
        payload['talents'] = _talentsOrGoals;
        payload['goals'] = _goalsForTwiner;
        payload['teaching_methods'] = _lessonLocations.toList();
        payload['experience_description'] = _aboutLessonController.text.trim().isEmpty ? null : _aboutLessonController.text.trim();
        payload['parent_participation_welcomed'] = _parentParticipationWelcomed;
        payload['tutoring_rate'] = _rateController.text.trim().isEmpty ? null : _rateController.text.trim();
      }

      // 기존 Twiner 편집: goals 스텝 값 반영
      if (fixedUserType == 'twiner' && !_isTwinerFromTutor && !_isTwinerFromStudent) {
        payload['goals'] = _goalsForTwiner;
      }

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

      // Agreements: 신규 온보딩 또는 Twiner 전환 시 해당 waiver 저장
      if (!_isEdit || _isTwinerConversion) {
        // Student→Twiner: Tutor waiver; Tutor→Twiner: Student waiver; 그 외: 역할별 waiver
        final agreementType = _isTwinerFromStudent
            ? 'trainer_terms'
            : (_isTwinerFromTutor ? 'trainee_waiver' : (_isTutor ? 'trainer_terms' : 'trainee_waiver'));
        await SupabaseService.saveUserAgreement(
          agreementType: agreementType,
          version: 'v1.0',
        );
        if (!_isEdit) {
          if (_requiresParentalConsent) {
            await SupabaseService.saveUserAgreement(
              agreementType: 'parental_consent',
              version: 'v1.0',
            );
          }
        }
      }

      if (!mounted) return;
      final savedAsTwiner = fixedUserType.trim().toLowerCase() == 'twiner';
      if (_isEdit) {
        // Twiner 저장 후에는 메인 화면으로 전환
        if (savedAsTwiner) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          Navigator.of(context).pop(true);
        }
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (!mounted) return;
      _snack(AppLocalizations.of(context)!.failedToSaveProfile(e.toString()));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _sectionTitle(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(s, style: Theme.of(context).textTheme.titleMedium),
      );

  Widget _singlePhotoPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_profilePhotos.isEmpty)
          SizedBox(
            width: 160,
            height: 160,
            child: OutlinedButton(
              onPressed: _isSaving ? null : () async {
                final one = await _pickSinglePhotoAsDataUrl();
                if (one == null) return;
                if (!mounted) return;
                setState(() {
                  _profilePhotos.clear();
                  _profilePhotos.add(one);
                });
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_outlined, size: 40),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context)!.addPhoto),
                ],
              ),
            ),
          )
        else
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  base64Decode(_profilePhotos.first.split(',').last),
                  width: 160,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                right: -8,
                top: -8,
                child: IconButton(
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                  onPressed: _isSaving
                      ? null
                      : () async {
                          final one = await _pickSinglePhotoAsDataUrl();
                          if (one == null) return;
                          if (!mounted) return;
                          setState(() {
                            _profilePhotos.clear();
                            _profilePhotos.add(one);
                          });
                        },
                  icon: const Icon(Icons.edit, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                  ),
                ),
              ),
              Positioned(
                right: -8,
                bottom: -8,
                child: IconButton(
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                  onPressed: _isSaving ? null : () => setState(() => _profilePhotos.clear()),
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  List<Step> _buildSteps() {
    final l10n = AppLocalizations.of(context)!;
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
              title: Text(l10n.roleAndBasicInfo),
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
                          Expanded(
                            child: Text(l10n.demoModeRandomData),
                          ),
                          TextButton(
                            onPressed: _isSaving ? null : () => _prefillDummyOnboardingData(regenerate: true),
                            child: Text(l10n.regenerate),
                          ),
                        ],
                      ),
                    ),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'tutor', label: Text(l10n.tutor)),
                      ButtonSegment(value: 'student', label: Text(l10n.student)),
                    ],
                    selected: {_userType},
                    onSelectionChanged: _isEdit
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
                            // Dummy: regenerate prefilled data for the new role.
                            if (_isDummy) {
                              _prefillDummyOnboardingData(regenerate: true);
                            }
                          },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    enabled: !_isEdit,
                    decoration: InputDecoration(
                      labelText: l10n.name,
                      border: const OutlineInputBorder(),
                      filled: _isEdit,
                      fillColor: _isEdit ? disabledFill : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration: InputDecoration(
                      labelText: l10n.gender,
                      border: const OutlineInputBorder(),
                      filled: _isEdit,
                      fillColor: _isEdit ? disabledFill : null,
                    ),
                    items: [
                      DropdownMenuItem(value: 'man', child: Text(l10n.man)),
                      DropdownMenuItem(value: 'woman', child: Text(l10n.woman)),
                      DropdownMenuItem(value: 'non-binary', child: Text(l10n.nonBinary)),
                      DropdownMenuItem(value: 'Prefer not to say', child: Text(l10n.preferNotToSay)),
                    ],
                    onChanged: _isEdit ? null : (v) => setState(() => _gender = v ?? 'Prefer not to say'),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: (_isSaving || _isEdit) ? null : _pickBirthdate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: l10n.birthdate,
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
                      AppLocalizations.of(context)!.ageLabel((_computedAge() ?? '').toString()),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                          ),
                    ),
                  const SizedBox(height: 16),
                  _sectionTitle(l10n.aboutMeOptional),
                  TextField(
                    controller: _aboutMeController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: l10n.tellOthersAboutYou,
                    ),
                  ),
                ],
              ),
            ),
          );
          break;

        case _OnboardingStepKey.topics:
          final topicsLabel = _isTwinerFromTutor
              ? l10n.whatDoYouWantToLearn
              : (_isTwinerFromStudent ? l10n.whatCanYouTeach : (_isTutor ? l10n.whatCanYouTeach : l10n.whatDoYouWantToLearn));
          steps.add(
            Step(
              title: Text(topicsLabel),
              isActive: isActive,
              state: state,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategorySelectorWidget(
                    selectedItems: _talentsOrGoals,
                    onSelectionChanged: (v) => setState(() => _talentsOrGoals = v),
                    title: topicsLabel,
                    hint: l10n.selectTopicsHint,
                  ),
                ],
              ),
            ),
          );
          break;

        case _OnboardingStepKey.lessonInfo:
          steps.add(
            Step(
              title: Text(l10n.lessonInfo),
              isActive: isActive,
              state: state,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(l10n.aboutTheLessonOptional),
                  TextField(
                    controller: _aboutLessonController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: l10n.shareLessonDetails,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle(l10n.lessonLocationRequired),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: Text(
                          l10n.onsite,
                          style: TextStyle(
                            color: _lessonLocations.contains('onsite')
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: _lessonLocations.contains('onsite')
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                        selected: _lessonLocations.contains('onsite'),
                        onSelected: (v) => setState(() {
                          v ? _lessonLocations.add('onsite') : _lessonLocations.remove('onsite');
                        }),
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        selectedColor: Theme.of(context).colorScheme.primary,
                        checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                        side: BorderSide(
                          color: _lessonLocations.contains('onsite')
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline.withOpacity(0.5),
                        ),
                      ),
                      FilterChip(
                        label: Text(
                          l10n.online,
                          style: TextStyle(
                            color: _lessonLocations.contains('online')
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: _lessonLocations.contains('online')
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                        selected: _lessonLocations.contains('online'),
                        onSelected: (v) => setState(() {
                          v ? _lessonLocations.add('online') : _lessonLocations.remove('online');
                        }),
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        selectedColor: Theme.of(context).colorScheme.primary,
                        checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                        side: BorderSide(
                          color: _lessonLocations.contains('online')
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle(l10n.tutoringRatePerHourRequired),
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
                    title: Text(l10n.parentParticipationOptional),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          );
          break;

        case _OnboardingStepKey.goals:
          steps.add(
            Step(
              title: Text(l10n.whatDoYouWantToLearn),
              isActive: isActive,
              state: state,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategorySelectorWidget(
                    selectedItems: _goalsForTwiner,
                    onSelectionChanged: (v) => setState(() => _goalsForTwiner = v),
                    title: l10n.whatDoYouWantToLearn,
                    hint: l10n.selectTopicsHint,
                  ),
                ],
              ),
            ),
          );
          break;

        case _OnboardingStepKey.photos:
          steps.add(
            Step(
              title: Text(l10n.profilePhoto),
              isActive: isActive,
              state: state,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(l10n.profilePhotoRequired),
                  _singlePhotoPicker(),
                ],
              ),
            ),
          );
          break;

        case _OnboardingStepKey.waivers:
          steps.add(
            Step(
              title: Text(l10n.waivers),
              isActive: isActive,
              state: state,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.waiversRequiredBeforeFinishing,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _showTutorWaiverInStep ? l10n.tutorWaiverTitle : l10n.studentWaiverTitle,
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
                      child: SelectableText.rich(
                        TextSpan(
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(height: 1.4),
                          children: AppTheme.textSpansWithTwinglHighlight(
                            _showTutorWaiverInStep
                                ? l10n.tutorWaiverText
                                : l10n.studentWaiverText,
                            baseStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(height: 1.4) ??
                                const TextStyle(height: 1.4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: _agreeRoleWaiver,
                    onChanged: (v) => setState(() => _agreeRoleWaiver = v ?? false),
                    title: Text(
                      _showTutorWaiverInStep
                          ? l10n.agreeToTutorWaiverCheckbox
                          : l10n.agreeToStudentWaiverCheckbox,
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 10),
                  if (_requiresParentalConsent) ...[
                    Text(
                      l10n.parentalConsentTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
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
                        child: SelectableText.rich(
                          TextSpan(
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(height: 1.4),
                            children: AppTheme.textSpansWithTwinglHighlight(
                              l10n.parentalConsentText,
                              baseStyle: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(height: 1.4) ??
                                  const TextStyle(height: 1.4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _agreeParentalConsent,
                      onChanged: (v) => setState(() => _agreeParentalConsent = v ?? false),
                      title: Text(l10n.agreeToParentalConsentCheckbox),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ] else ...[
                    Text(
                      l10n.parentalConsentOnlyForMinors,
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
        title: Text(_isTwinerConversion ? AppLocalizations.of(context)!.addingMoreInfo : (_isEdit ? AppLocalizations.of(context)!.editProfile : AppLocalizations.of(context)!.onboardingTitle)),
      ),
      body: SafeArea(
        child: Stepper(
          // IMPORTANT: Stepper asserts that the number of steps does not change across updates.
          // Our onboarding flow changes step count depending on Tutor/Student (lesson info step).
          // Use a key that changes when the flow shape changes to force a fresh Stepper instance.
          key: ValueKey<String>('stepper:${_isEdit ? 'edit' : 'new'}:$_userType:${_stepKeys().length}'),
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
                      child: Text(AppLocalizations.of(context)!.back),
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
                          : Text(isLast ? (_isEdit ? AppLocalizations.of(context)!.save : AppLocalizations.of(context)!.finish) : AppLocalizations.of(context)!.next),
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

