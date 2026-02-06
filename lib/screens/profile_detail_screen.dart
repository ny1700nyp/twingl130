import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../utils/distance_formatter.dart';
import '../widgets/avatar_with_type_badge.dart';
import '../widgets/user_stats_widget.dart';
import 'chat_screen.dart';
import 'training_history_screen.dart';

const double _kProfileImageSize = 150;

class ProfileDetailScreen extends StatelessWidget {
  final Map<String, dynamic> profile;
  final bool hideAppBar;
  final Map<String, dynamic>? currentUserProfile;
  final bool hideActionButtons;
  /// When true (e.g. in chat profile sheet), do not show name/age/gender block in body.
  final bool hideNameAgeGenderInBody;
  /// Optional actions for the AppBar (e.g. Edit for my profile). When [onEditPressed] is set and isMyProfile, Share/Edit are shown in My Details card instead.
  final List<Widget>? appBarActions;
  /// When true, hide the distance label below Chat history (e.g. My Favorite detail).
  final bool hideDistance;
  /// When set (e.g. from chat), show a thumbs-up like button on the photo below the link button.
  final VoidCallback? onLikeFromPhoto;
  /// When set and viewing own profile, Edit button in My Details card calls this.
  final VoidCallback? onEditPressed;

  const ProfileDetailScreen({
    super.key,
    required this.profile,
    this.hideAppBar = false,
    this.currentUserProfile,
    this.hideActionButtons = false,
    this.hideNameAgeGenderInBody = false,
    this.appBarActions,
    this.hideDistance = false,
    this.onLikeFromPhoto,
    this.onEditPressed,
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

  /// Returns ImageProvider for avatar from profile photos (for use when image is hidden).
  static ImageProvider? _imageProviderFromProfile(Map<String, dynamic> profile) {
    final profilePhotos = profile['profile_photos'] as List<dynamic>?;
    final mainPhotoPath = profile['main_photo_path'] as String?;
    final List<String> photos = [];
    if (profilePhotos != null && profilePhotos.isNotEmpty) {
      photos.addAll(profilePhotos.map((p) => p.toString()));
    } else if (mainPhotoPath != null && mainPhotoPath.isNotEmpty) {
      photos.add(mainPhotoPath);
    }
    if (photos.isEmpty) return null;
    final first = photos.first;
    if (first.startsWith('data:image')) {
      try {
        return MemoryImage(base64Decode(first.split(',')[1]));
      } catch (_) {
        return null;
      }
    }
    if (first.startsWith('http://') || first.startsWith('https://')) {
      return NetworkImage(first);
    }
    if (!kIsWeb) {
      try {
        return FileImage(File(first));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

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

  Widget _buildDetailChip(BuildContext context, IconData? icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
          const SizedBox(width: 6),
        ],
        Text(label, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }

  static Color _colorForUserType(String? userType) {
    final t = (userType ?? '').trim().toLowerCase();
    if (t == 'student') return AppTheme.twinglMint;
    if (t == 'tutor') return AppTheme.twinglPurple;
    if (t == 'twiner') return AppTheme.twinglYellow;
    return AppTheme.twinglGreen;
  }

  /// [highlightColor]: when non-null and highlighted, use purple (goal↔talent) or mint (talent↔goal).
  /// [chipBorderColor]: goal=mint, talent=purple.
  Widget _buildProfileChip(
    BuildContext context,
    String label, {
    bool highlighted = false,
    Color? highlightColor,
    Color? chipBorderColor,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final bg = highlighted
        ? (highlightColor ?? scheme.primary)
        : scheme.surfaceContainerHighest;
    final textColor = highlighted
        ? (highlightColor != null ? Colors.white : scheme.onPrimary)
        : scheme.onSurface;
    final borderColor = chipBorderColor ?? bg;
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: highlighted ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      backgroundColor: bg,
      side: BorderSide(color: borderColor),
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
    final imageBox = SizedBox(
      width: _kProfileImageSize,
      height: _kProfileImageSize,
      child: ClipRect(
        child: _buildProfileImageInner(context, imagePath),
      ),
    );
    return Center(child: imageBox);
  }

  Widget _buildProfileImageInner(BuildContext context, String? imagePath) {
    final emptyWidget = Container(
      width: _kProfileImageSize,
      height: _kProfileImageSize,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.person,
        size: 60,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
    if (imagePath == null || imagePath.isEmpty) return emptyWidget;

    // base64 data URL인 경우 (cover로 채워서 라운드 클립이 보이도록)
    if (imagePath.startsWith('data:image')) {
      return Image.memory(
        base64Decode(imagePath.split(',')[1]),
        fit: BoxFit.cover,
        width: _kProfileImageSize,
        height: _kProfileImageSize,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => emptyWidget,
      );
    }

    // 네트워크 URL인 경우
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        width: _kProfileImageSize,
        height: _kProfileImageSize,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => emptyWidget,
      );
    }

    // 로컬 파일 경로인 경우 (모바일만)
    if (!kIsWeb) {
      try {
        return Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          width: _kProfileImageSize,
          height: _kProfileImageSize,
          errorBuilder: (_, __, ___) => emptyWidget,
        );
      } catch (e) {
        return emptyWidget;
      }
    }

    return emptyWidget;
  }

  /// Static helper to build Share app bar button for use in AppBar actions.
  /// [iconColor] when set, applies to the share icon (e.g. user type color).
  static Widget buildShareAppBarButton(BuildContext context, Map<String, dynamic> profile, {Color? iconColor}) {
    final userType = (profile['user_type'] as String?)?.trim().toLowerCase() ?? '';
    final isTutorOrTwiner = userType == 'tutor' || userType == 'twiner';
    if (!isTutorOrTwiner) return const SizedBox.shrink();

    final color = iconColor ?? _colorForUserType(profile['user_type'] as String?);
    return PopupMenuButton<String>(
      icon: Icon(Icons.share_outlined, color: color),
      tooltip: 'Share',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'copy',
          child: Row(
            children: [
              Icon(Icons.copy, size: 20),
              SizedBox(width: 12),
              Text('Copy Link'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share, size: 20),
              SizedBox(width: 12),
              Text('Share'),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'copy') {
          ProfileDetailScreen._copyProfileLinkStatic(context, profile);
        } else if (value == 'share') {
          ProfileDetailScreen._shareProfileStatic(context, profile);
        }
      },
    );
  }

  static String _generateProfileLinkStatic(Map<String, dynamic> profile) {
    final userId = profile['user_id'] as String?;
    if (userId == null) return '';
    // TODO: 실제 도메인으로 변경
    return 'https://twingl.app/profile/$userId';
  }

  // 프로필 링크 복사
  Future<void> _copyProfileLink(BuildContext context) async {
    await _copyProfileLinkStatic(context, profile);
  }

  static Future<void> _copyProfileLinkStatic(BuildContext context, Map<String, dynamic> profile) async {
    final link = _generateProfileLinkStatic(profile);
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
    await _shareProfileStatic(context, profile);
  }

  static Future<void> _shareProfileStatic(BuildContext context, Map<String, dynamic> profile) async {
    final link = _generateProfileLinkStatic(profile);
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

  Widget _buildPhotoSlider(BuildContext context, List<String> photos, {VoidCallback? onLikeFromPhoto}) {
    final userType = (profile['user_type'] as String?)?.trim().toLowerCase() ?? '';
    final isTutorOrTwiner = userType == 'tutor' || userType == 'twiner';

    final showShare = isTutorOrTwiner;
    final likeCallback = onLikeFromPhoto;
    final showLike = likeCallback != null;

    final topRightChildren = <Widget>[
      if (showLike) _buildLikeOnPhotoButton(context, likeCallback),
      if (showShare && showLike) const SizedBox(width: 8),
      if (showShare) _buildShareButton(context),
    ];
    final topRightWidget = topRightChildren.isEmpty
        ? null
        : Positioned(
            top: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: topRightChildren,
            ),
          );

    if (photos.isEmpty) {
      return SizedBox(
        height: _kProfileImageSize + 24,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: _buildProfileImage(context, null),
            ),
            if (topRightWidget != null) topRightWidget,
          ],
        ),
      );
    }

    if (photos.length == 1) {
      return SizedBox(
        height: _kProfileImageSize + 24,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(child: _buildProfileImage(context, photos[0])),
            if (topRightWidget != null) topRightWidget,
          ],
        ),
      );
    }

    final sliderKey = ValueKey<String>(photos.isEmpty ? '' : photos.first);
    return SizedBox(
      height: _kProfileImageSize + 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: _PhotoSliderWidget(
              key: sliderKey,
              photos: photos,
              buildImage: (imagePath) => _buildProfileImage(context, imagePath),
            ),
          ),
          if (topRightWidget != null) topRightWidget,
        ],
      ),
    );
  }

  Widget _buildLikeOnPhotoButton(BuildContext context, VoidCallback onLike) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onLike,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.thumb_up_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
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

    final effectiveProfile = currentUserProfile ?? SupabaseService.currentUserProfileCache.value;
    final currentUserType = (effectiveProfile?['user_type'] as String?)?.trim().toLowerCase();
    final List<String> currentUserGoals = (currentUserType == 'student' || currentUserType == 'twiner')
        ? ((effectiveProfile?['goals'] as List<dynamic>?) ??
                (effectiveProfile?['talents'] as List<dynamic>?) ??
                const <dynamic>[])
            .map((e) => e.toString().trim().toLowerCase())
            .toList()
        : const <String>[];

    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RequestTrainModal(
        trainerId: trainerId,
        trainerName: trainerName,
        availableSkills: talents.map((e) => e.toString()).toList(),
        availableMethods: teachingMethods.map((e) => e.toString()).toList(),
        currentUserGoals: currentUserGoals,
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
    final tutoringRate = profile['tutoring_rate'] as String?;
    final parentParticipationWelcomed = profile['parent_participation_welcomed'] as bool? ?? false;
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

    // AppBar에 이름·나이대·성별 표시 (다른 사람 프로필 + 내 프로필 동일 형식)
    final shouldShowCustomAppBar = !hideAppBar;
    
    // AppBar 제목 생성 (내 프로필일 때는 이름만, 다른 사람은 이름+나이대+성별)
    Widget? appBarTitle;
    if (shouldShowCustomAppBar) {
      final ageText = age != null ? _formatAgeRange(age, profile['created_at'] as String?) : null;
      final genderText = _genderLabel(gender);
      final ageGenderText = <String>[
        if (ageText != null && ageText.isNotEmpty) ageText,
        if (genderText.isNotEmpty) genderText,
      ].join(' • ');
      
      final nameOnly = Flexible(
        child: Text(
          name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      );
      final nameAndAge = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          nameOnly,
          if (!isMyProfile && ageGenderText.isNotEmpty) ...[
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
      appBarTitle = isMyProfile
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AvatarWithTypeBadge(
                  radius: 18,
                  backgroundImage: _imageProviderFromProfile(profile),
                  userType: profile['user_type'] as String?,
                ),
                const SizedBox(width: 12),
                nameOnly,
              ],
            )
          : nameAndAge;
    } else {
      appBarTitle = const Text('Profile Details');
    }

    final isSignedIn = Supabase.instance.client.auth.currentUser != null;
    // 모든 프로필(내 프로필·채팅 이름 탭·My Favorite 등) 동일한 컴팩트 레이아웃
    const double sectionTitleFontSize = 16.0;
    const double sectionSpacing = 14.0;
    const double buttonVerticalPadding = 12.0;
    // Tudent의 "I want to learn"용 goals (DB goals 컬럼)
    final twinerGoals = userType == 'twiner' ? (profile['goals'] as List<dynamic>?) ?? const <dynamic>[] : null;

    // 내 프로필이고 onEditPressed가 있으면 Share/Edit은 My Details 카드에 표시하므로 AppBar에는 빈 actions
    final effectiveAppBarActions = (isMyProfile && onEditPressed != null)
        ? const <Widget>[]
        : (appBarActions ?? const <Widget>[]);

    return Scaffold(
      appBar: hideAppBar ? null : AppBar(
        title: appBarTitle,
        elevation: 0,
        actions: effectiveAppBarActions,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 이미지 슬라이더 (내 프로필이 아닐 때만 표시)
            if (!isMyProfile)
              RepaintBoundary(
                child: Container(
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
                    child: _buildPhotoSlider(context, photos, onLikeFromPhoto: onLikeFromPhoto),
                  ),
                ),
              ),

            // Request Training 버튼 (로그인 상태에서 다른 Trainer 프로필을 볼 때 표시)
            if (!hideActionButtons && !isMyProfile && (userType == 'tutor' || userType == 'twiner') && isSignedIn)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
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
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
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

            // Distance (privacy-friendly) just below Chat history (생략: My Favorite detail 등 hideDistance 시)
            if (!hideDistance && !hideActionButtons && !isMyProfile && (userType == 'tutor' || userType == 'twiner' || userType == 'student') && isSignedIn && distanceLabel != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
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
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AppBar가 없을 때만 본문에 이름·나이·성별 표시 (hideAppBar일 때). 채팅/다른 프로필과 동일 형식(18/14px).
                  if (hideAppBar && !hideNameAgeGenderInBody) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
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
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                        if (age != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            _formatAgeRange(age, profile['created_at'] as String?),
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: sectionSpacing),
                  ] else ...[
                    SizedBox(height: sectionSpacing),
                  ],

                  // My Activity Stats (내 프로필일 때만, 카드로 표시)
                  if (isMyProfile) ...[
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'My Activity Stats',
                              style: TextStyle(
                                fontSize: sectionTitleFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            UserStatsWidget(
                              user: UserModel.fromProfile(profile),
                              showTitle: false,
                              wrapInCard: false,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: sectionSpacing),
                  ],

                  // My Details (내 프로필일 때: Share/Edit, 거리·성별·나이, 그 외 정보)
                  if (isMyProfile && onEditPressed != null) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                            // 제목 + Share, Edit (오른쪽 위) — user type 색상 적용
                            Builder(
                              builder: (ctx) {
                                final typeColor = _colorForUserType(profile['user_type'] as String?);
                                return Row(
                                  children: [
                                    Text(
                                      'My Details',
                                      style: TextStyle(
                                        fontSize: sectionTitleFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: typeColor,
                                      ),
                                    ),
                                    const Spacer(),
                                    ProfileDetailScreen.buildShareAppBarButton(ctx, profile, iconColor: typeColor),
                                    IconButton(
                                      icon: Icon(Icons.edit_outlined, color: typeColor),
                                      onPressed: onEditPressed,
                                      tooltip: 'Edit Profile',
                                    ),
                                  ],
                                );
                              },
                            ),
                            // 도시명, 나이대 (My Details 아래)
                            ValueListenableBuilder<String?>(
                              valueListenable: SupabaseService.currentCityCache,
                              builder: (context, cityValue, _) {
                                final city = (cityValue ?? '').trim();
                                final hasCity = city.isNotEmpty;
                                final hasAge = age != null;
                                if (!hasCity && !hasAge) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Wrap(
                                    spacing: 12,
                                    runSpacing: 6,
                                    children: [
                                      if (hasCity)
                                        _buildDetailChip(context, Icons.location_on, city),
                                      if (hasAge)
                                        _buildDetailChip(
                                          context,
                                          null,
                                          _formatAgeRange(age, profile['created_at'] as String?),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            // About me
                            if (aboutMe != null && aboutMe.isNotEmpty) ...[
                              Text('About me', style: TextStyle(fontSize: sectionTitleFontSize - 1, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text(aboutMe, style: const TextStyle(fontSize: 14, height: 1.35)),
                              SizedBox(height: sectionSpacing),
                            ],
                            // About the lesson
                            if ((userType == 'tutor' || userType == 'twiner') && experienceDescription != null && experienceDescription.isNotEmpty) ...[
                              Text('About the lesson', style: TextStyle(fontSize: sectionTitleFontSize - 1, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text(experienceDescription, style: const TextStyle(fontSize: 14, height: 1.35)),
                              SizedBox(height: sectionSpacing),
                            ],
                            // I can teach
                            if ((userType == 'tutor' || userType == 'twiner') && talents != null && talents.isNotEmpty) ...[
                              Text('I can teach', style: TextStyle(fontSize: sectionTitleFontSize - 1, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: talents.map((t) => _buildProfileChip(context, t.toString(), highlighted: false, chipBorderColor: AppTheme.twinglPurple)).toList(),
                              ),
                              SizedBox(height: sectionSpacing),
                            ],
                            // I want to learn (Twiner)
                            if (userType == 'twiner' && twinerGoals != null && twinerGoals.isNotEmpty) ...[
                              Text('I want to learn', style: TextStyle(fontSize: sectionTitleFontSize - 1, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: twinerGoals.map((g) => _buildProfileChip(context, g.toString(), highlighted: false, chipBorderColor: AppTheme.twinglMint)).toList(),
                              ),
                              SizedBox(height: sectionSpacing),
                            ],
                            // Lesson location
                            if ((userType == 'tutor' || userType == 'twiner') && teachingMethods != null && teachingMethods.isNotEmpty) ...[
                              Text('Lesson location', style: TextStyle(fontSize: sectionTitleFontSize - 1, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  if (teachingMethods.contains('onsite')) _buildProfileChip(context, 'Onsite', highlighted: false),
                                  if (teachingMethods.contains('online')) _buildProfileChip(context, 'Online', highlighted: false),
                                ],
                              ),
                              SizedBox(height: sectionSpacing),
                            ],
                            // Lesson Fee, Parent participation (Lesson location 아래)
                            if (userType == 'tutor' || userType == 'twiner') ...[
                              if (tutoringRate != null && tutoringRate.isNotEmpty) ...[
                                Row(
                                  children: [
                                    Icon(Icons.attach_money, color: Theme.of(context).colorScheme.primary, size: 18),
                                    const SizedBox(width: 6),
                                    Text('Lesson Fee: \$$tutoringRate/hour', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                SizedBox(height: sectionSpacing),
                              ],
                              Row(
                                children: [
                                  Icon(Icons.family_restroom, color: Theme.of(context).colorScheme.secondary, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    parentParticipationWelcomed ? 'Parent participation welcomed' : 'Parent participation not specified',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85)),
                                  ),
                                ],
                              ),
                              SizedBox(height: sectionSpacing),
                            ],
                            // I want to learn (Student)
                            if (userType == 'student' && traineeGoals != null && traineeGoals.isNotEmpty) ...[
                              Text('I want to learn', style: TextStyle(fontSize: sectionTitleFontSize - 1, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: traineeGoals.map((g) => _buildProfileChip(context, g.toString(), highlighted: false, chipBorderColor: AppTheme.twinglMint)).toList(),
                              ),
                            ],
                      ],
                    ),
                    SizedBox(height: sectionSpacing),
                  ],

                  // About me (내 프로필이 아니거나 My Details가 없을 때)
                  if ((!isMyProfile || onEditPressed == null) && aboutMe != null && aboutMe.isNotEmpty) ...[
                    Text(
                      'About me',
                      style: TextStyle(
                        fontSize: sectionTitleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      aboutMe,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                    SizedBox(height: sectionSpacing),
                  ],

                  // Tutor/Stutor: About the lesson (About me 다음) — My Details 카드가 있을 때는 카드 내에 이미 표시됨
                  if ((!isMyProfile || onEditPressed == null) && (userType == 'tutor' || userType == 'twiner') && experienceDescription != null && experienceDescription.isNotEmpty) ...[
                    Text(
                      'About the lesson',
                      style: TextStyle(
                        fontSize: sectionTitleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      experienceDescription,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                    SizedBox(height: sectionSpacing),
                  ],
                  
                  // Tutor/Twiner: I can teach (talents). Purple = my goal ↔ their talent (I'm Student or Twiner).
                  if ((!isMyProfile || onEditPressed == null) && (userType == 'tutor' || userType == 'twiner') && talents != null && talents.isNotEmpty) ...[
                    Text(
                      'I can teach',
                      style: TextStyle(
                        fontSize: sectionTitleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: talents
                          .map((talent) {
                            final talentStr = talent.toString();
                            final isMatchPurple = (currentUserType == 'student' || currentUserType == 'twiner') &&
                                currentUserGoalsNorm.contains(_norm(talentStr));
                            final highlighted = isMatchPurple && !isMyProfile;
                            return _buildProfileChip(
                              context,
                              talentStr,
                              highlighted: highlighted,
                              highlightColor: highlighted ? AppTheme.twinglPurple : null,
                              chipBorderColor: AppTheme.twinglPurple,
                            );
                          })
                          .toList(),
                    ),
                    SizedBox(height: sectionSpacing),
                  ],
                  
                  // Twiner 전용: I want to learn (goals). Mint = my talent ↔ their goal (I'm Tutor or Twiner).
                  if (userType == 'twiner' && twinerGoals != null && twinerGoals.isNotEmpty) ...[
                    Text(
                      'I want to learn',
                      style: TextStyle(
                        fontSize: sectionTitleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: twinerGoals
                          .map((goal) {
                            final goalStr = goal.toString();
                            final isMatchMint = (currentUserType == 'tutor' || currentUserType == 'twiner') &&
                                currentUserTalentsNorm.contains(_norm(goalStr));
                            final highlighted = isMatchMint && !isMyProfile;
                            return _buildProfileChip(
                              context,
                              goalStr,
                              highlighted: highlighted,
                              highlightColor: highlighted ? AppTheme.twinglMint : null,
                              chipBorderColor: AppTheme.twinglMint,
                            );
                          })
                          .toList(),
                    ),
                    SizedBox(height: sectionSpacing),
                  ],
                  
                  // Lesson location (Trainer only)
                  if ((!isMyProfile || onEditPressed == null) && (userType == 'tutor' || userType == 'twiner') && teachingMethods != null && teachingMethods.isNotEmpty) ...[
                    Text(
                      'Lesson location',
                      style: TextStyle(
                        fontSize: sectionTitleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (teachingMethods.contains('onsite'))
                          _buildProfileChip(context, 'Onsite', highlighted: false),
                        if (teachingMethods.contains('online'))
                          _buildProfileChip(context, 'Online', highlighted: false),
                      ],
                    ),
                    SizedBox(height: sectionSpacing),
                  ],

                  // Lesson Fee, Parent participation (Lesson location 아래)
                  if ((!isMyProfile || onEditPressed == null) && (userType == 'tutor' || userType == 'twiner')) ...[
                    if (tutoringRate != null && tutoringRate.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.attach_money, color: Theme.of(context).colorScheme.primary, size: 18),
                          const SizedBox(width: 6),
                          Text('Lesson Fee: \$$tutoringRate/hour', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      SizedBox(height: sectionSpacing),
                    ],
                    Row(
                      children: [
                        Icon(Icons.family_restroom, color: Theme.of(context).colorScheme.secondary, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          parentParticipationWelcomed ? 'Parent participation welcomed' : 'Parent participation not specified',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85)),
                        ),
                      ],
                    ),
                    SizedBox(height: sectionSpacing),
                  ],

                  // Student 전용: I want to learn (goals). Mint = my talent ↔ their goal (I'm Tutor or Twiner).
                  if ((!isMyProfile || onEditPressed == null) && userType == 'student' && traineeGoals != null && traineeGoals.isNotEmpty) ...[
                    Text(
                      'I want to learn',
                      style: TextStyle(
                        fontSize: sectionTitleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: traineeGoals
                          .map((goal) {
                            final goalStr = goal.toString();
                            final isMatchMint = (currentUserType == 'tutor' || currentUserType == 'twiner') &&
                                currentUserTalentsNorm.contains(_norm(goalStr));
                            final highlighted = isMatchMint && !isMyProfile;
                            return _buildProfileChip(
                              context,
                              goalStr,
                              highlighted: highlighted,
                              highlightColor: highlighted ? AppTheme.twinglMint : null,
                              chipBorderColor: AppTheme.twinglMint,
                            );
                          })
                          .toList(),
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
  final List<String> currentUserGoals;

  const _RequestTrainModal({
    required this.trainerId,
    required this.trainerName,
    required this.availableSkills,
    required this.availableMethods,
    this.currentUserGoals = const [],
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
                      final isMatch = widget.currentUserGoals.contains(skill.trim().toLowerCase());
                      return FilterChip(
                        label: Text(
                          skill,
                          style: TextStyle(
                            color: isSelected
                                ? scheme.onPrimary
                                : isMatch
                                    ? Colors.white
                                    : scheme.onSurface,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedSkill = selected ? skill : null;
                          });
                        },
                        backgroundColor: isMatch && !isSelected
                            ? AppTheme.twinglPurple.withOpacity(0.9)
                            : scheme.surfaceContainerHighest,
                        selectedColor: scheme.primary,
                        checkmarkColor: scheme.onPrimary,
                        side: BorderSide.none,
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
                        side: BorderSide.none,
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
    super.key,
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
          height: _kProfileImageSize + 24,
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

// --- 슬라이드업 프로필 시트 (채팅 이름 탭과 동일 형식) ---

String _sheetFormatAgeRange(int? age, String? createdAt) {
  if (age == null) return '';
  int currentYear = DateTime.now().year;
  int registrationYear = currentYear;
  if (createdAt != null) {
    try {
      registrationYear = DateTime.parse(createdAt).year;
    } catch (_) {}
  }
  int currentAge = age + (currentYear - registrationYear);
  int ageRange = (currentAge ~/ 10) * 10;
  return '${ageRange}s';
}

String _sheetGenderLabel(String? gender) {
  if (gender == null) return '';
  final g = gender.trim();
  if (g.isEmpty || g == 'Prefer not to say') return '';
  switch (g) {
    case 'man': return 'Man';
    case 'woman': return 'Woman';
    case 'non-binary': return 'Non-binary';
    default: return g;
  }
}

double? _sheetDistanceMeters(Map<String, dynamic> otherProfile, Map<String, dynamic>? currentUserProfile) {
  final cached = SupabaseService.lastKnownLocation.value;
  final myLat = cached?.lat ?? (currentUserProfile?['latitude'] as num?)?.toDouble();
  final myLon = cached?.lon ?? (currentUserProfile?['longitude'] as num?)?.toDouble();
  if (myLat == null || myLon == null) return null;
  final lat = (otherProfile['latitude'] as num?)?.toDouble();
  final lon = (otherProfile['longitude'] as num?)?.toDouble();
  if (lat == null || lon == null) return null;
  return Geolocator.distanceBetween(myLat, myLon, lat, lon);
}

/// 채팅에서 이름 탭 시와 동일한 슬라이드업 시트로 프로필을 연다.
/// [profile]이 있으면 바로 표시, 없으면 [userId]로 로드한다. [isMyProfile]이 true면 편집 버튼을 노출한다.
Future<void> showProfileDetailSheet(
  BuildContext context, {
  Map<String, dynamic>? profile,
  String? userId,
  bool isMyProfile = false,
  VoidCallback? onEditPressed,
  bool hideActionButtons = true,
  bool hideDistance = false,
  Map<String, dynamic>? currentUserProfile,
}) async {
  final effectiveCurrent = currentUserProfile ?? SupabaseService.currentUserProfileCache.value;
  // 시트 드래그 시 재빌드되어도 동일한 Future를 쓰도록, 시트 밖에서 한 번만 생성
  final Future<Map<String, dynamic>?>? sheetProfileFuture = (profile == null && userId != null)
      ? (isMyProfile ? SupabaseService.getCurrentUserProfileCached(userId) : SupabaseService.getPublicProfile(userId))
      : null;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final media = MediaQuery.of(ctx);
      final h = media.size.height;
      final topPadding = media.padding.top;
      final sheetHeight = (h - topPadding - 24).clamp(400.0, h * 0.88);
      final surface = Theme.of(ctx).colorScheme.surface;
      return Padding(
        padding: EdgeInsets.only(top: topPadding + 8, left: 12, right: 12, bottom: 12),
        child: Material(
          color: surface,
          elevation: 10,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: sheetHeight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.onSurface.withAlpha(80),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: profile != null
                      ? _ProfileSheetBody(
                          profile: profile,
                          isMyProfile: isMyProfile,
                          onEditPressed: onEditPressed,
                          hideActionButtons: hideActionButtons,
                          hideDistance: hideDistance,
                          currentUserProfile: effectiveCurrent,
                        )
                      : (sheetProfileFuture != null
                          ? FutureBuilder<Map<String, dynamic>?>(
                              future: sheetProfileFuture,
                              builder: (context, snap) {
                                if (snap.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                if (snap.hasError) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text('Failed to load profile: ${snap.error}'),
                                    ),
                                  );
                                }
                                final p = snap.data;
                                if (p == null) {
                                  return const Center(child: Text('Profile not found'));
                                }
                                final withDistance = Map<String, dynamic>.from(p);
                                final meters = _sheetDistanceMeters(withDistance, effectiveCurrent);
                                if (meters != null) {
                                  withDistance['distance_meters'] = meters;
                                }
                                return _ProfileSheetBody(
                                  profile: withDistance,
                                  isMyProfile: isMyProfile,
                                  onEditPressed: onEditPressed,
                                  hideActionButtons: hideActionButtons,
                                  hideDistance: hideDistance,
                                  currentUserProfile: effectiveCurrent,
                                );
                              },
                            )
                          : const Center(child: Text('Profile not found'))),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ProfileSheetBody extends StatelessWidget {
  const _ProfileSheetBody({
    required this.profile,
    required this.isMyProfile,
    this.onEditPressed,
    required this.hideActionButtons,
    this.hideDistance = false,
    this.currentUserProfile,
  });

  final Map<String, dynamic> profile;
  final bool isMyProfile;
  final VoidCallback? onEditPressed;
  final bool hideActionButtons;
  final bool hideDistance;
  final Map<String, dynamic>? currentUserProfile;

  @override
  Widget build(BuildContext context) {
    final name = profile['name'] as String? ?? 'Unknown';
    final age = profile['age'] as int?;
    final gender = profile['gender'] as String?;
    final createdAt = profile['created_at'] as String?;
    final distanceMeters = (profile['distance_meters'] as num?)?.toDouble() ??
        _sheetDistanceMeters(profile, currentUserProfile);
    final distanceStr = distanceMeters != null ? formatDistanceMeters(distanceMeters) : null;
    final ageStr = _sheetFormatAgeRange(age, createdAt);
    final genderStr = _sheetGenderLabel(gender);
    // 내 프로필 topbar에는 아바타·뱃지·이름만 (거리·나이대·성별 제거)
    final subParts = <String>[
      if (!isMyProfile && distanceStr != null && distanceStr.isNotEmpty) distanceStr,
      if (!isMyProfile && ageStr.isNotEmpty) ageStr,
      if (!isMyProfile && genderStr.isNotEmpty) genderStr,
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMyProfile)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AvatarWithTypeBadge(
                    radius: 22,
                    backgroundImage: ProfileDetailScreen._imageProviderFromProfile(profile),
                    userType: profile['user_type'] as String?,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subParts.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subParts.join('  •  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ProfileDetailScreen(
            profile: profile,
            hideAppBar: true,
            hideActionButtons: hideActionButtons,
            hideNameAgeGenderInBody: true,
            hideDistance: hideDistance,
            currentUserProfile: currentUserProfile,
            onEditPressed: isMyProfile && onEditPressed != null
                ? () {
                    Navigator.pop(context);
                    onEditPressed?.call();
                  }
                : null,
          ),
        ),
      ],
    );
  }
}
