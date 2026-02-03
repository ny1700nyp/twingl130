import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:convert';
import '../services/supabase_service.dart';
import 'training_history_screen.dart';
import 'chat_screen.dart';
import '../utils/distance_formatter.dart';
import '../theme/app_theme.dart';

class ProfileDetailScreen extends StatelessWidget {
  final Map<String, dynamic> profile;
  final bool hideAppBar;
  final Map<String, dynamic>? currentUserProfile;
  final bool hideActionButtons;
  /// When true (e.g. in chat profile sheet), do not show name/age/gender block in body.
  final bool hideNameAgeGenderInBody;

  const ProfileDetailScreen({
    super.key,
    required this.profile,
    this.hideAppBar = false,
    this.currentUserProfile,
    this.hideActionButtons = false,
    this.hideNameAgeGenderInBody = false,
  });

  String _getPronouns(String? gender) {
    if (gender == null) return '';
    switch (gender) {
      case 'man':
        return 'he/him';
      case 'woman':
        return 'she/her';
      case 'non-binary':
        return 'they/them';
      default:
        return '';
    }
  }

  String _genderLabel(String? gender) {
    if (gender == null) return '';
    final g = gender.trim();
    if (g.isEmpty) return '';
    if (g == 'Prefer not to say') return '';
    switch (g) {
      case 'man':
        return 'Man';
      case 'woman':
        return 'Woman';
      case 'non-binary':
        return 'Non-binary';
      default:
        return g;
    }
  }

  double? _distanceMetersToProfile(Map<String, dynamic> otherProfile, Map<String, dynamic>? currentUserProfile) {
    final cached = SupabaseService.lastKnownLocation.value;
    final myLat = cached?.lat ?? (currentUserProfile?['latitude'] as num?)?.toDouble();
    final myLon = cached?.lon ?? (currentUserProfile?['longitude'] as num?)?.toDouble();
    if (myLat == null || myLon == null) return null;

    final lat = (otherProfile['latitude'] as num?)?.toDouble();
    final lon = (otherProfile['longitude'] as num?)?.toDouble();
    if (lat == null || lon == null) return null;

    return Geolocator.distanceBetween(myLat, myLon, lat, lon);
  }

  String _norm(String s) => s.trim().toLowerCase();

  // 나이를 "30대", "40대" 형식으로 변환하는 헬퍼 함수
  String _formatAgeRange(int? age, String? createdAt) {
    if (age == null) return '';
    
    // 가입 년도와 현재 년도 차이 계산
    int currentYear = DateTime.now().year;
    int registrationYear = currentYear;
    
    if (createdAt != null) {
      try {
        final createdDate = DateTime.parse(createdAt);
        registrationYear = createdDate.year;
      } catch (e) {
        // 파싱 실패 시 현재 년도 사용
        registrationYear = currentYear;
      }
    }
    
    // 현재 나이 계산: 저장된 나이 + (현재 년도 - 가입 년도)
    int currentAge = age + (currentYear - registrationYear);
    
    // 10대 단위로 변환 (예: 25 -> 20대, 35 -> 30대)
    int ageRange = (currentAge ~/ 10) * 10;
    
    return '${ageRange}s';
  }

  Widget _buildProfileChip(
    BuildContext context,
    String label, {
    required bool highlighted,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: highlighted ? scheme.onPrimary : scheme.onSurface,
          fontWeight: highlighted ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      backgroundColor: highlighted
          ? scheme.primary
          : scheme.surfaceContainerHighest,
      side: BorderSide(
        color: highlighted
            ? scheme.primary
            : scheme.surfaceContainerHighest,
      ),
    );
  }

  ButtonStyle _profilePrimaryActionStyle({double verticalPadding = 16}) {
    // Brand color requested by user: #FF6363
    const brand = Color(0xFFFF6363);
    return ElevatedButton.styleFrom(
      backgroundColor: brand,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  String _formatDistance(double distanceMeters) => formatDistanceMeters(distanceMeters);

  Widget _buildProfileImage(BuildContext context, String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        height: 300,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.person,
          size: 100,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    // base64 data URL인 경우 (cover로 채워서 라운드 클립이 보이도록)
    if (imagePath.startsWith('data:image')) {
      return Image.memory(
        base64Decode(imagePath.split(',')[1]),
        fit: BoxFit.cover,
        height: 300,
        width: double.infinity,
        errorBuilder: (ctx, error, stackTrace) {
          return Container(
            height: 300,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.person,
              size: 100,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        },
      );
    }
    
    // 네트워크 URL인 경우
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        height: 300,
        width: double.infinity,
        errorBuilder: (ctx, error, stackTrace) {
          return Container(
            height: 300,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.person,
              size: 100,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        },
      );
    }
    
    // 로컬 파일 경로인 경우 (모바일만)
    if (!kIsWeb) {
      try {
        return Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          height: 300,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 300,
              color: Colors.grey[300],
              child: const Icon(Icons.person, size: 100),
            );
          },
        );
      } catch (e) {
        return Container(
          height: 300,
          color: Colors.grey[300],
          child: const Icon(Icons.person, size: 100),
        );
      }
    }
    
    // 기본값
    return Container(
      height: 300,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.person,
        size: 100,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildCertificateImage(BuildContext context, String imagePath) {
    if (imagePath.isEmpty) {
      return Container(
        width: 150,
        height: 200,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.image,
          size: 50,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    // base64 data URL인 경우
    if (imagePath.startsWith('data:image')) {
      return Image.memory(
        base64Decode(imagePath.split(',')[1]),
        fit: BoxFit.cover,
        width: 150,
        height: 200,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 150,
            height: 200,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.image,
              size: 50,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        },
      );
    }
    
    // 네트워크 URL인 경우
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        width: 150,
        height: 200,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 150,
            height: 200,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.image,
              size: 50,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        },
      );
    }
    
    // 로컬 파일 경로인 경우 (모바일만)
    if (!kIsWeb) {
      try {
        return Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          width: 150,
          height: 200,
        errorBuilder: (ctx, error, stackTrace) {
          return Container(
            width: 150,
            height: 200,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.image,
              size: 50,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        },
        );
      } catch (e) {
        return Container(
          width: 150,
          height: 200,
          color: Colors.grey[300],
          child: const Icon(Icons.image, size: 50),
        );
      }
    }
    
    // 기본값
    return Container(
      width: 150,
      height: 200,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.image,
        size: 50,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  // 프로필 링크 생성
  String _generateProfileLink() {
    final userId = profile['user_id'] as String?;
    if (userId == null) return '';
    // TODO: 실제 도메인으로 변경
    return 'https://twingl.app/profile/$userId';
  }

  // 프로필 링크 복사
  Future<void> _copyProfileLink(BuildContext context) async {
    final link = _generateProfileLink();
    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to generate profile link.')),
      );
      return;
    }
    
    await Clipboard.setData(ClipboardData(text: link));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile link copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // 프로필 공유
  Future<void> _shareProfile(BuildContext context) async {
    final link = _generateProfileLink();
    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to generate profile link.')),
      );
      return;
    }
    
    final name = profile['name'] as String? ?? 'Trainer';
    final shareText = 'Check out $name\'s profile on Twingl!\n$link';
    
    try {
      await Share.share(shareText);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    }
  }

  Widget _buildPhotoSlider(BuildContext context, List<String> photos) {
    final userType = (profile['user_type'] as String?)?.trim().toLowerCase() ?? '';
    final isTutorOrTwiner = userType == 'tutor' || userType == 'twiner';

    if (photos.isEmpty) {
      return Container(
        height: 300,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.person,
                size: 100,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            // Tutor/Stutor인 경우에만 공유 버튼 표시
            if (isTutorOrTwiner)
              Positioned(
                top: 8,
                right: 8,
                child: _buildShareButton(context),
              ),
          ],
        ),
      );
    }

    // 사진이 1장이면 슬라이더 없이 단순 이미지 표시 (공유 버튼 포함)
    if (photos.length == 1) {
      return Stack(
        children: [
          _buildProfileImage(context, photos[0]),
          // Trainer인 경우에만 공유 버튼 표시 (오른쪽 상단)
          if (isTutorOrTwiner)
            Positioned(
              top: 8,
              right: 8,
              child: _buildShareButton(context),
            ),
        ],
      );
    }

    // 여러 사진이면 PageView 슬라이더 사용 (공유 버튼 포함)
    return Stack(
      children: [
        _PhotoSliderWidget(
          photos: photos,
          buildImage: (imagePath) => _buildProfileImage(context, imagePath),
        ),
        // Trainer인 경우에만 공유 버튼 표시 (오른쪽 상단)
        if (isTutorOrTwiner)
          Positioned(
            top: 8,
            right: 8,
            child: _buildShareButton(context),
          ),
      ],
    );
  }

  // Request Train 모달 표시
  void _showRequestTrainModal(BuildContext context) {
    final trainerId = profile['user_id'] as String?;
    final trainerName = profile['name'] as String? ?? 'Trainer';
    final talents = profile['talents'] as List<dynamic>? ?? [];
    final teachingMethods = profile['teaching_methods'] as List<dynamic>? ?? [];
    
    if (trainerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to send request.')),
      );
      return;
    }
    
    // Capture parent navigator/messenger (safer than using bottom-sheet context after pop)
    final parentNavigator = Navigator.of(context);
    final parentMessenger = ScaffoldMessenger.of(context);

    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RequestTrainModal(
        trainerId: trainerId,
        trainerName: trainerName,
        availableSkills: talents.map((e) => e.toString()).toList(),
        availableMethods: teachingMethods.map((e) => e.toString()).toList(),
      ),
    ).then((conversationId) {
      if (conversationId == null) return;
      final otherUserId = trainerId;

      // Show feedback on the parent scaffold (avoids "no ScaffoldMessenger" errors).
      parentMessenger.showSnackBar(
        const SnackBar(
          content: Text('Sent'),
          duration: Duration(seconds: 2),
        ),
      );

      // Refresh chat dashboard cache in background so the conversation appears immediately.
      final me = Supabase.instance.client.auth.currentUser;
      if (me != null) {
        SupabaseService.refreshChatConversationsIfChanged(me.id);
      }

      parentNavigator.push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversationId,
            otherUserId: otherUserId,
            otherProfile: profile,
          ),
        ),
      );
    });
  }

  // 공유 버튼 위젯
  Widget _buildShareButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.share,
          color: Colors.white,
          size: 20,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'copy',
          child: Row(
            children: [
              const Icon(Icons.copy, size: 20),
              const SizedBox(width: 12),
              const Text('Copy Link'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              const Icon(Icons.share, size: 20),
              const SizedBox(width: 12),
              const Text('Share'),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'copy') {
          _copyProfileLink(context);
        } else if (value == 'share') {
          _shareProfile(context);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = profile['name'] as String? ?? 'No name';
    final age = profile['age'] as int?;
    final gender = profile['gender'] as String?;
    final userType = (profile['user_type'] as String?)?.trim().toLowerCase() ?? '';
    final talents = profile['talents'] as List<dynamic>?;
    final experienceDescription = profile['experience_description'] as String?;
    final teachingMethods = profile['teaching_methods'] as List<dynamic>?;
    final parentParticipationWelcomed = profile['parent_participation_welcomed'] as bool? ?? false;
    final tutoringRate = profile['tutoring_rate'] as String?;
    final certificatePhotos = profile['certificate_photos'] as List<dynamic>?;
    final aboutMe = (profile['about_me'] as String?)?.trim();

    // Student: goals; Twiner: goals or talents
    final traineeGoals = (userType == 'student' || userType == 'twiner')
        ? (profile['goals'] as List<dynamic>?) ?? (profile['talents'] as List<dynamic>?)
        : null;
    final mainPhotoPath = profile['main_photo_path'] as String?;
    final profilePhotos = profile['profile_photos'] as List<dynamic>?;
    
    // 현재 사용자의 goals (student/twiner) 가져오기
    final currentUserType = (currentUserProfile?['user_type'] as String?)?.trim().toLowerCase();
    final List<String> currentUserGoals = (currentUserType == 'student' || currentUserType == 'twiner')
        ? ((currentUserProfile?['goals'] as List<dynamic>?) ??
                (currentUserProfile?['talents'] as List<dynamic>?) ??
                const <dynamic>[])
            .map((e) => e.toString())
            .toList()
        : const <String>[];
    final List<String> currentUserTalents = (currentUserType == 'tutor' || currentUserType == 'twiner')
        ? (currentUserProfile?['talents'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            const <String>[]
        : const <String>[];

    // Normalized sets for robust matching (case/whitespace insensitive)
    final currentUserGoalsNorm = currentUserGoals.map(_norm).where((e) => e.isNotEmpty).toSet();
    final currentUserTalentsNorm = currentUserTalents.map(_norm).where((e) => e.isNotEmpty).toSet();

    // profile_photos가 있으면 사용, 없으면 main_photo_path 사용 (호환성)
    List<String> photos = [];
    if (profilePhotos != null && profilePhotos.isNotEmpty) {
      photos = profilePhotos.map((p) => p.toString()).toList();
    } else if (mainPhotoPath != null && mainPhotoPath.isNotEmpty) {
      photos = [mainPhotoPath];
    }

    // My Profile인지 확인
    // - 일반 프로필 화면에서는 currentUserProfile이 null일 수 있으므로(auth 기반으로 fallback)
    final currentUserId =
        (currentUserProfile?['user_id'] as String?) ?? Supabase.instance.client.auth.currentUser?.id;
    final profileUserId = profile['user_id'] as String?;
    final isMyProfile = currentUserId != null && profileUserId != null && currentUserId == profileUserId;
    
    final effectiveCurrentUserProfile = currentUserProfile ?? SupabaseService.currentUserProfileCache.value;
    final distanceMeters = (profile['distance_meters'] as num?)?.toDouble() ??
        _distanceMetersToProfile(profile, effectiveCurrentUserProfile);
    final distanceLabel = distanceMeters == null ? null : _formatDistance(distanceMeters);

    // My Profile이 아닐 때 AppBar에 이름, 나이대, 성별 표시 (tutor/twiner/student 모두)
    final shouldShowCustomAppBar = !hideAppBar && !isMyProfile;
    
    // AppBar 제목 생성
    Widget? appBarTitle;
    if (shouldShowCustomAppBar) {
      final ageText = age != null ? _formatAgeRange(age, profile['created_at'] as String?) : null;
      final genderText = _genderLabel(gender);
      final ageGenderText = <String>[
        if (ageText != null && ageText.isNotEmpty) ageText,
        if (genderText.isNotEmpty) genderText,
      ].join(' • ');
      
      appBarTitle = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (ageGenderText.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              ageGenderText,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ],
      );
    } else {
      appBarTitle = const Text('Profile Details');
    }

    final isSignedIn = Supabase.instance.client.auth.currentUser != null;
    // 다른 사람 프로필(My Favorite 등)에서는 버튼·타이틀·행간을 더 컴팩트하게
    final compactLayout = !isMyProfile;
    final sectionTitleFontSize = compactLayout ? 16.0 : 20.0;
    final sectionSpacing = compactLayout ? 14.0 : 24.0;
    final buttonVerticalPadding = compactLayout ? 12.0 : 16.0;
    // Tudent의 "I want to learn"용 goals (DB goals 컬럼)
    final twinerGoals = userType == 'twiner' ? (profile['goals'] as List<dynamic>?) ?? const <dynamic>[] : null;

    return Scaffold(
      appBar: hideAppBar ? null : AppBar(
        title: appBarTitle,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 이미지 슬라이더 (카드 내 아바타와 동일: 20px 라운드 + 좌우 여백)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                clipBehavior: Clip.antiAlias,
                child: _buildPhotoSlider(context, photos),
              ),
            ),

            // Request Training 버튼 (로그인 상태에서 다른 Trainer 프로필을 볼 때 표시)
            if (!hideActionButtons && !isMyProfile && (userType == 'tutor' || userType == 'twiner') && isSignedIn)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: compactLayout ? 16.0 : 20.0, vertical: compactLayout ? 10.0 : 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showRequestTrainModal(context),
                    icon: const Icon(Icons.school),
                    label: const Text('Request Training'),
                    style: _profilePrimaryActionStyle(verticalPadding: buttonVerticalPadding),
                  ),
                ),
              ),
            
            // Chat history 버튼 (로그인 상태에서 다른 Trainer 프로필을 볼 때 표시)
            if (!hideActionButtons && !isMyProfile && (userType == 'tutor' || userType == 'twiner') && isSignedIn)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: compactLayout ? 16.0 : 20.0, vertical: compactLayout ? 4.0 : 0.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final otherUserId = profile['user_id'] as String?;
                      if (otherUserId != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => TrainingHistoryScreen(
                              otherUserId: otherUserId,
                              otherProfile: profile,
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Chat history'),
                    style: _profilePrimaryActionStyle(verticalPadding: buttonVerticalPadding),
                  ),
                ),
              ),

            // Distance (privacy-friendly) just below photo (tutor/twiner/student, My Favorite 등)
            if (!hideActionButtons && !isMyProfile && (userType == 'tutor' || userType == 'twiner' || userType == 'student') && isSignedIn && distanceLabel != null)
              Padding(
                padding: EdgeInsets.fromLTRB(compactLayout ? 16 : 20, compactLayout ? 6 : 10, compactLayout ? 16 : 20, 0),
                child: Center(
                  child: Text(
                    distanceLabel,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.twinglGreen,
                    ),
                  ),
                ),
              ),
            
            // 프로필 정보
            Padding(
              padding: EdgeInsets.all(compactLayout ? 16.0 : 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AppBar에 이름/나이/성별을 넣지 않을 때만 본문에 표시 (My Profile 또는 hideAppBar일 때). 시트 등 외부 헤더 사용 시 생략.
                  if ((isMyProfile || hideAppBar) && !hideNameAgeGenderInBody) ...[
                    // 이름, 거리
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!isMyProfile && distanceLabel != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            distanceLabel,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (gender != null && gender != 'Prefer not to say') ...[
                          const SizedBox(width: 8),
                          Text(
                            _getPronouns(gender),
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                        if (age != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            _formatAgeRange(age, profile['created_at'] as String?),
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: sectionSpacing),
                  ] else ...[
                    // 다른 사람 프로필: 이름·나이대·성별은 AppBar에 표시되므로 본문 생략
                    SizedBox(height: sectionSpacing),
                  ],

                  // About me (Trainer / Trainee 공통)
                  if (aboutMe != null && aboutMe.isNotEmpty) ...[
                    Text(
                      'About me',
                      style: TextStyle(
                        fontSize: sectionTitleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: compactLayout ? 6 : 8),
                    Text(
                      aboutMe,
                      style: TextStyle(
                        fontSize: 14,
                        height: compactLayout ? 1.35 : 1.5,
                      ),
                    ),
                    SizedBox(height: sectionSpacing),
                  ],
                  
                  // Tutor/Stutor: About the lesson (About me 다음)
                  if ((userType == 'tutor' || userType == 'twiner') && experienceDescription != null && experienceDescription.isNotEmpty) ...[
                    Text(
                      'About the lesson',
                      style: TextStyle(
                        fontSize: sectionTitleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: compactLayout ? 6 : 8),
                    Text(
                      experienceDescription,
                      style: TextStyle(
                        fontSize: 14,
                        height: compactLayout ? 1.35 : 1.5,
                      ),
                    ),
                    SizedBox(height: sectionSpacing),
                  ],
                  
                  // Tutor/Tudent: I can teach (talents)
                  if ((userType == 'tutor' || userType == 'twiner') && talents != null && talents.isNotEmpty) ...[
                    Text(
                      'I can teach',
                      style: TextStyle(
                        fontSize: sectionTitleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: compactLayout ? 6 : 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: compactLayout ? 6 : 8,
                      children: talents
                          .map((talent) {
                            final talentStr = talent.toString();
                            final matchingNorm =
                                (currentUserType == 'tutor' || currentUserType == 'twiner') && (userType == 'tutor' || userType == 'twiner')
                                    ? currentUserTalentsNorm
                                    : currentUserGoalsNorm;
                            final isMatched = matchingNorm.contains(_norm(talentStr));
                            return _buildProfileChip(
                              context,
                              talentStr,
                              highlighted: isMatched,
                            );
                          })
                          .toList(),
                    ),
                    SizedBox(height: sectionSpacing),
                  ],
                  
                  // Stutor 전용: I want to learn (goals 컬럼)
                  if (userType == 'twiner' && twinerGoals != null && twinerGoals.isNotEmpty) ...[
                    Text(
                      'I want to learn',
                      style: TextStyle(
                        fontSize: sectionTitleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: compactLayout ? 6 : 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: compactLayout ? 6 : 8,
                      children: twinerGoals
                          .map((goal) {
                            final goalStr = goal.toString();
                            final isMatched = (currentUserType == 'tutor' || currentUserType == 'twiner')
                                ? currentUserTalentsNorm.contains(_norm(goalStr))
                                : currentUserGoalsNorm.contains(_norm(goalStr));
                            return _buildProfileChip(context, goalStr, highlighted: isMatched);
                          })
                          .toList(),
                    ),
                    SizedBox(height: sectionSpacing),
                  ],
                  
                  // Lesson location (Trainer only)
                  if ((userType == 'tutor' || userType == 'twiner') && teachingMethods != null && teachingMethods.isNotEmpty) ...[
                    Text(
                      'Lesson location',
                      style: TextStyle(
                        fontSize: sectionTitleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: compactLayout ? 6 : 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: compactLayout ? 6 : 8,
                      children: [
                        if (teachingMethods.contains('onsite'))
                          _buildProfileChip(context, 'Onsite', highlighted: false),
                        if (teachingMethods.contains('online'))
                          _buildProfileChip(context, 'Online', highlighted: false),
                      ],
                    ),
                    SizedBox(height: sectionSpacing),
                  ],

                  // Trainer 전용: Tutoring rate / Parent participation
                  if (userType == 'tutor' || userType == 'twiner') ...[
                    if (tutoringRate != null && tutoringRate.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            color: Theme.of(context).colorScheme.primary,
                            size: compactLayout ? 18 : 20,
                          ),
                          SizedBox(width: compactLayout ? 6 : 8),
                          Text(
                            'Tutoring Rate: \$$tutoringRate/hour',
                            style: TextStyle(
                              fontSize: compactLayout ? 14 : 16,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: sectionSpacing),
                    ],
                    if (parentParticipationWelcomed) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.family_restroom,
                            color: Theme.of(context).colorScheme.secondary,
                            size: compactLayout ? 18 : 20,
                          ),
                          SizedBox(width: compactLayout ? 6 : 8),
                          Text(
                            'Parent participation welcomed',
                            style: TextStyle(
                              fontSize: compactLayout ? 14 : 16,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: sectionSpacing),
                    ],
                  ],
                  
                  // Student 전용: I want to learn (goals 컬럼)
                  if (userType == 'student' && traineeGoals != null && traineeGoals.isNotEmpty) ...[
                    Text(
                      'I want to learn',
                      style: TextStyle(
                        fontSize: sectionTitleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: compactLayout ? 6 : 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: compactLayout ? 6 : 8,
                      children: traineeGoals
                          .map((goal) {
                            final goalStr = goal.toString();
                            final isMatched = (currentUserType == 'tutor' || currentUserType == 'twiner')
                                ? currentUserTalentsNorm.contains(_norm(goalStr))
                                : currentUserGoalsNorm.contains(_norm(goalStr));
                            return _buildProfileChip(context, goalStr, highlighted: isMatched);
                          })
                          .toList(),
                    ),
                    SizedBox(height: sectionSpacing),
                  ],
                  
                  // Certificates (Trainer만)
                  if ((userType == 'tutor' || userType == 'twiner') && certificatePhotos != null && certificatePhotos.isNotEmpty) ...[
                    Text(
                      'Certificates / Awards / Degrees',
                      style: TextStyle(
                        fontSize: sectionTitleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: compactLayout ? 6 : 8),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: certificatePhotos.length,
                        itemBuilder: (context, index) {
                          final certificatePhoto = certificatePhotos[index] as String?;
                          if (certificatePhoto == null || certificatePhoto.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildCertificateImage(context, certificatePhoto),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: sectionSpacing),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Request Train Modal Widget
class _RequestTrainModal extends StatefulWidget {
  final String trainerId;
  final String trainerName;
  final List<String> availableSkills;
  final List<String> availableMethods;

  const _RequestTrainModal({
    required this.trainerId,
    required this.trainerName,
    required this.availableSkills,
    required this.availableMethods,
  });

  @override
  State<_RequestTrainModal> createState() => _RequestTrainModalState();
}

class _RequestTrainModalState extends State<_RequestTrainModal> {
  String? _selectedSkill;
  String? _selectedMethod;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Request Training',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select the skill and method you want to learn',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  
                  // What to learn (skill chips – 테마 대비로 가독성 확보)
                  Text(
                    'What to learn',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.availableSkills.map((skill) {
                      final isSelected = _selectedSkill == skill;
                      final scheme = Theme.of(context).colorScheme;
                      return FilterChip(
                        label: Text(
                          skill,
                          style: TextStyle(
                            color: isSelected ? scheme.onPrimary : scheme.onSurface,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedSkill = selected ? skill : null;
                          });
                        },
                        backgroundColor: scheme.surfaceContainerHighest,
                        selectedColor: scheme.primary,
                        checkmarkColor: scheme.onPrimary,
                        side: BorderSide(
                          color: isSelected ? scheme.primary : scheme.outline.withOpacity(0.5),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  // Lesson Location (method chips)
                  Text(
                    'Lesson Location',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.availableMethods.map((method) {
                      final isSelected = _selectedMethod == method;
                      final scheme = Theme.of(context).colorScheme;
                      final label = method == 'onsite' ? 'Onsite' : 'Online';
                      return FilterChip(
                        label: Text(
                          label,
                          style: TextStyle(
                            color: isSelected ? scheme.onPrimary : scheme.onSurface,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedMethod = selected ? method : null;
                          });
                        },
                        backgroundColor: scheme.surfaceContainerHighest,
                        selectedColor: scheme.primary,
                        checkmarkColor: scheme.onPrimary,
                        side: BorderSide(
                          color: isSelected ? scheme.primary : scheme.outline.withOpacity(0.5),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  
                  // Send Request Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_selectedSkill != null && _selectedMethod != null && !_isLoading)
                          ? _sendRequest
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Send Request'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendRequest() async {
    if (_selectedSkill == null || _selectedMethod == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final conversationId = await SupabaseService.sendTrainingRequest(
        trainerId: widget.trainerId,
        traineeId: currentUser.id,
        skill: _selectedSkill!,
        method: _selectedMethod!,
      ).timeout(const Duration(seconds: 12));

      if (!mounted) return;
      Navigator.of(context).pop(conversationId);
    } catch (e) {
      // Use maybeOf to avoid throwing if no ScaffoldMessenger in this subtree.
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text('Failed to send request: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

// 사진 슬라이더를 위한 StatefulWidget
class _PhotoSliderWidget extends StatefulWidget {
  final List<String> photos;
  final Widget Function(String) buildImage;

  const _PhotoSliderWidget({
    required this.photos,
    required this.buildImage,
  });

  @override
  State<_PhotoSliderWidget> createState() => _PhotoSliderWidgetState();
}

class _PhotoSliderWidgetState extends State<_PhotoSliderWidget> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return widget.buildImage(widget.photos[index]);
            },
          ),
        ),
        // 페이지 인디케이터
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.photos.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? Theme.of(context).colorScheme.surface
                      : Theme.of(context).colorScheme.surface.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
