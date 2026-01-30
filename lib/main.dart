import 'package:flutter/material.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/liked_profiles_screen.dart';
import 'screens/profile_detail_screen.dart';
import 'screens/my_profile_screen.dart';
import 'screens/public_profile_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://oibboowecbxvjmookwtd.supabase.co',
    anonKey: 'sb_publishable_SYXxaO7zPzUsgarNzSqCgA_pdhR9ZIj',
  );

  // 알림 서비스 초기화 및 navigator key 설정
  await NotificationService().initialize();
  await NotificationService().requestPermissions();
  NotificationService().setNavigatorKey(navigatorKey);

  runApp(const GuruTownApp());
}

class GuruTownApp extends StatelessWidget {
  const GuruTownApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Twingl',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.system, // Automatically switch based on system settings
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/onboarding': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return OnboardingScreen(
            initialUserType: args?['userType'] as String?,
          );
        },
        '/home': (context) => const MainScreen(),
        '/profile': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final userId = args?['userId'] as String?;
          if (userId == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid profile link')),
            );
          }
          return PublicProfileScreen(userId: userId);
        },
      },
      initialRoute: '/',
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isChecking = false;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Auth 상태 변화 리스너 추가
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      if (event == AuthChangeEvent.signedIn && session != null) {
        // 로그인 성공 - 스플래시를 표시하지 않고 바로 체크
        if (mounted) {
          setState(() {
            _showSplash = false;
          });
          _checkAuthStatus();
        }
      } else if (event == AuthChangeEvent.signedOut) {
        // 로그아웃
        if (mounted) {
          setState(() {
            _showSplash = false;
          });
          SupabaseService.clearInMemoryCaches();
        Navigator.of(context).pushReplacementNamed('/login');
      }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    if (_isChecking) return; // 중복 호출 방지
    _isChecking = true;

    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        // 로그인 안됨 - 스플래시 숨기고 로그인 화면으로
        if (mounted) {
          setState(() {
            _showSplash = false;
          });
        Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      // Hydrate device caches first for instant rendering.
      await SupabaseService.hydrateCachesFromDisk(user.id);

      // 프로필 확인 (cache-first)
      final profile = await SupabaseService.getCurrentUserProfileCached(user.id);
      
      if (!mounted) return;

      // 스플래시 숨기기
      setState(() {
        _showSplash = false;
      });
      
      if (profile == null) {
        // 온보딩 필요
        Navigator.of(context).pushReplacementNamed('/onboarding');
      } else {
        // 홈으로
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      print('Auth status check failed: $e');
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      Navigator.of(context).pushReplacementNamed('/login');
      }
    } finally {
      _isChecking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 초기 앱 시작 시에만 스플래시 표시 (체크 중이고 아직 네비게이션하지 않은 경우)
    if (_showSplash && _isChecking) {
      return const SplashScreen();
    }
    // 체크가 완료되거나 스플래시를 숨긴 경우 빈 화면 (곧바로 네비게이션됨)
    return const Scaffold(
      body: SizedBox.shrink(),
    );
  }
}

class GuruTownHomePage extends StatefulWidget {
  const GuruTownHomePage({super.key});

  @override
  State<GuruTownHomePage> createState() => _GuruTownHomePageState();
}

class _GuruTownHomePageState extends State<GuruTownHomePage> {
  late AppinioSwiperController _swiperController;
  List<Map<String, dynamic>> _users = [];
  Map<String, dynamic>? _currentProfile;
  bool _isLoading = true;
  bool _isButtonSwipe = false; // 버튼으로 인한 스와이프인지 확인하는 플래그
  String? _pendingSwipeUserId; // 버튼 클릭 시 저장할 유저 ID (스와이프 전에 고정)
  String? _currentCity; // 현재 도시 이름
  int _currentCardIndex = 0; // 현재 보이는 카드의 인덱스
  int _unreadMessageCount = 0; // 읽지 않은 메시지 수

  @override
  void initState() {
    super.initState();
    _swiperController = AppinioSwiperController();
    _loadData();
  }

  // 읽지 않은 메시지 수만 로드
  Future<void> _loadUnreadMessageCount() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null && _currentProfile != null) {
        final userType = _currentProfile?['user_type'] as String?;
        if (userType != null) {
          final unreadCount = await SupabaseService.getTotalUnreadMessageCount(
            currentUser.id,
            userType,
          );
          if (mounted) {
            setState(() {
              _unreadMessageCount = unreadCount;
            });
          }
        }
      }
    } catch (e) {
      print('Failed to load unread message count: $e');
    }
  }

  // Reverse geocoding으로 도시 이름 가져오기 (플랫폼별 처리)
  Future<void> _getCityName(double latitude, double longitude) async {
    try {
      // 좌표 유효성 검사
      if (latitude.isNaN || longitude.isNaN ||
          latitude.isInfinite || longitude.isInfinite) {
        print('유효하지 않은 좌표: $latitude, $longitude');
        return;
      }

      String? city;

      if (kIsWeb) {
        // Web 플랫폼: OpenStreetMap Nominatim API 사용
        try {
          final url = Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=10&addressdetails=1',
          );
          
          final response = await http.get(
            url,
            headers: {
              'User-Agent': 'TwinglApp/1.0', // Nominatim은 User-Agent 필수
            },
          ).timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw Exception('Geocoding API 타임아웃');
            },
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final address = data['address'] as Map<String, dynamic>?;
            
            if (address != null) {
              // 우선순위: city -> town -> village -> municipality -> county
              city = address['city'] as String? ??
                     address['town'] as String? ??
                     address['village'] as String? ??
                     address['municipality'] as String? ??
                     address['county'] as String?;
            }
          } else {
            print('Nominatim API 응답 오류: ${response.statusCode}');
          }
        } catch (e) {
          print('Web geocoding 실패: $e');
        }
      } else {
        // Mobile 플랫폼: geocoding 패키지 사용
        try {
          final placemarks = await placemarkFromCoordinates(
            latitude,
            longitude,
          ).timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              print('Geocoding 타임아웃');
              return <Placemark>[];
            },
          );

          if (placemarks.isNotEmpty) {
            final placemark = placemarks[0];
            
            // 각 필드를 순차적으로 확인 (null-safe)
            try {
              if (placemark.locality != null && placemark.locality!.isNotEmpty) {
                city = placemark.locality;
              } else if (placemark.subAdministrativeArea != null && 
                         placemark.subAdministrativeArea!.isNotEmpty) {
                city = placemark.subAdministrativeArea;
              } else if (placemark.administrativeArea != null && 
                         placemark.administrativeArea!.isNotEmpty) {
                city = placemark.administrativeArea;
              }
            } catch (e) {
              print('Placemark 필드 접근 중 오류: $e');
            }
          }
        } catch (e, stackTrace) {
          print('Mobile geocoding 실패: $e');
          print('Stack trace: $stackTrace');
        }
      }

      if (city != null && city.isNotEmpty) {
        setState(() {
          _currentCity = city;
        });
        print('현재 도시: $city');
      } else {
        print('도시 이름을 찾을 수 없습니다.');
      }
    } catch (e, stackTrace) {
      print('도시 이름 가져오기 실패: $e');
      print('Stack trace: $stackTrace');
      // 도시 이름 가져오기 실패해도 앱은 계속 진행
    }
  }

  // 카드를 매칭 개수와 거리 기준으로 정렬
  List<Map<String, dynamic>> _sortCardsByMatchAndDistance({
    required List<Map<String, dynamic>> cards,
    required String currentUserType,
    required List<String> currentUserTalentsOrGoals,
  }) {
    // 각 카드에 매칭 개수 계산
    final cardsWithMatchCount = cards.map((card) {
      final cardTalents = (card['talents'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final cardGoals = (card['goals'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final distance = (card['distance_meters'] as num?)?.toDouble() ?? double.infinity;

      int matchCount = 0;
      
      // 카드의 user_type 확인
      final cardUserType = card['user_type'] as String? ?? '';

      if (currentUserType == 'trainer') {
        if (cardUserType == 'trainer') {
          // Trainer가 Trainer를 볼 때: 내 talents와 상대방의 talents 비교
          final cardTalentsSet = cardTalents.toSet();
          matchCount = currentUserTalentsOrGoals
              .where((talent) => cardTalentsSet.contains(talent))
              .length;
        } else {
          // Trainer가 Trainee를 볼 때: 내 talents와 상대방의 goals 비교 (기존 로직 유지)
          final cardGoalsSet = cardGoals.toSet();
          matchCount = currentUserTalentsOrGoals
              .where((talent) => cardGoalsSet.contains(talent))
              .length;
        }
      } else {
        // Trainee인 경우: 내 goals와 상대방의 talents 비교
        final cardTalentsSet = cardTalents.toSet();
        matchCount = currentUserTalentsOrGoals
            .where((goal) => cardTalentsSet.contains(goal))
            .length;
      }

      return {
        'card': card,
        'matchCount': matchCount,
        'distance': distance,
      };
    }).toList();

    // 정렬: AppinioSwiper는 리스트의 마지막 카드를 맨 위에 보여주므로 반대로 정렬
    // 1) 매칭 개수 오름차순 (적은 것 먼저) -> 많은 것이 뒤에 옴
    // 2) 거리 내림차순 (먼 것 먼저) -> 가까운 것이 뒤에 옴
    cardsWithMatchCount.sort((a, b) {
      final matchCountA = a['matchCount'] as int;
      final matchCountB = b['matchCount'] as int;
      final distanceA = a['distance'] as double;
      final distanceB = b['distance'] as double;

      // 1. 매칭 개수로 정렬 (오름차순 - 적은 것 먼저)
      if (matchCountA != matchCountB) {
        return matchCountA.compareTo(matchCountB);
      }

      // 2. 매칭 개수가 같으면 거리로 정렬 (내림차순 - 먼 것 먼저)
      return distanceB.compareTo(distanceA);
    });

    // 정렬된 카드만 반환
    return cardsWithMatchCount
        .map((item) => item['card'] as Map<String, dynamic>)
        .toList();
  }

  Future<void> _loadData() async {
    try {
      // 현재 사용자 프로필 가져오기
      final profile = await SupabaseService.getCurrentUserProfile();
      
      // 읽지 않은 메시지 수 가져오기
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null && profile != null) {
        final userType = profile['user_type'] as String?;
        if (userType != null) {
          final unreadCount = await SupabaseService.getTotalUnreadMessageCount(
            currentUser.id,
            userType,
          );
          if (mounted) {
            setState(() {
              _unreadMessageCount = unreadCount;
            });
          }
        }
      }
      if (profile == null) {
        // 프로필이 없으면 온보딩으로 이동 (이미 AuthWrapper를 통과했으므로 데이터베이스 문제일 수 있음)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile not found. Please complete onboarding.'),
              duration: Duration(seconds: 3),
            ),
          );
          await Future.delayed(const Duration(seconds: 1));
          Navigator.of(context).pushReplacementNamed('/onboarding');
        }
        return;
      }

      setState(() {
        _currentProfile = profile;
      });

      // 읽지 않은 메시지 수 가져오기
      final currentUserForUnread = Supabase.instance.client.auth.currentUser;
      if (currentUserForUnread != null) {
        final userType = profile['user_type'] as String?;
        if (userType != null) {
          final unreadCount = await SupabaseService.getTotalUnreadMessageCount(
            currentUserForUnread.id,
            userType,
          );
          if (mounted) {
            setState(() {
              _unreadMessageCount = unreadCount;
            });
          }
        }
      }

      // 현재 위치 가져오기
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
        
        // 위치를 성공적으로 가져오면 Supabase에 업데이트
        try {
          await SupabaseService.updateUserLocation(
            latitude: position.latitude,
            longitude: position.longitude,
          );
          print('위치 정보가 Supabase에 업데이트되었습니다.');
          
          // Reverse geocoding으로 도시 이름 가져오기
          await _getCityName(position.latitude, position.longitude);
        } catch (e) {
          print('위치 정보 업데이트 실패 (계속 진행): $e');
          // 위치 업데이트 실패해도 앱은 계속 진행
        }
      } catch (e) {
        print('Failed to get location: $e');
        // 프로필에 저장된 위치 사용
        if (profile['latitude'] != null && profile['longitude'] != null) {
          position = Position(
            latitude: (profile['latitude'] as num).toDouble(),
            longitude: (profile['longitude'] as num).toDouble(),
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
          
          // 저장된 위치로 도시 이름 가져오기
          await _getCityName(position.latitude, position.longitude);
        }
      }

      if (position == null) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to get location. Please check location permissions.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // 사용자 타입에 따라 매칭 카드 가져오기
      final userType = profile['user_type'] as String?;
      final userId = profile['user_id'] as String?;
      
      if (userType == null || userId == null) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile information is incomplete.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final talentsOrGoals = userType == 'trainer'
          ? (profile['talents'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              []
          : (profile['goals'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];

      final cards = await SupabaseService.getMatchingCards(
        userType: userType,
        currentLatitude: position.latitude,
        currentLongitude: position.longitude,
        userTalentsOrGoals: talentsOrGoals,
        currentUserId: userId,
      );

      // 카드 정렬: 매칭 개수 우선, 그 다음 거리
      final sortedCards = _sortCardsByMatchAndDistance(
        cards: cards,
        currentUserType: userType,
        currentUserTalentsOrGoals: talentsOrGoals,
      );

            setState(() {
              _users = sortedCards;
              _currentCardIndex = 0; // 새 데이터 로드 시 첫 번째 카드로 리셋
              _isLoading = false;
            });
    } catch (e) {
      print('Failed to load data: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Back 버튼 제거
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Twingl',
              style: GoogleFonts.quicksand(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
            if (_currentCity != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.location_on,
                size: 18,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(width: 4),
              Text(
                _currentCity!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.tertiary,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
        actions: [
          Stack(
            children: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'my_profile') {
                // My Profile 화면으로 이동
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MyProfileScreen(),
                  ),
                );
              } else if (value == 'dashboard') {
                // Dashboard 화면으로 이동 (Trainer와 Trainee 모두)
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DashboardScreen(),
                  ),
                ).then((_) {
                  // Dashboard에서 돌아오면 읽지 않은 메시지 수 다시 로드
                  _loadUnreadMessageCount();
                });
              } else if (value == 'liked') {
                // Liked 프로필 화면으로 이동
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LikedProfilesScreen(),
                  ),
                );
              } else if (value == 'logout') {
                // 로그아웃
                await Supabase.instance.client.auth.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              }
            },
            itemBuilder: (BuildContext context) {
              final items = <PopupMenuEntry<String>>[];
              
              // My Profile 메뉴 추가
              items.add(
                const PopupMenuItem<String>(
                  value: 'my_profile',
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 20),
                      SizedBox(width: 8),
                      Text('My Profile'),
                    ],
                  ),
                ),
              );
              
              // Dashboard 메뉴 추가 (Trainer와 Trainee 모두)
              items.add(
                PopupMenuItem<String>(
                  value: 'dashboard',
                  child: Row(
                    children: [
                      const Icon(Icons.dashboard, size: 20),
                      const SizedBox(width: 8),
                      const Text('Dashboard'),
                      if (_unreadMessageCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.secondaryGold,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
              
              // Trainer와 Trainee 모두 'My Favorite Trainer' 메뉴 표시
              items.add(
                const PopupMenuItem<String>(
                  value: 'liked',
                  child: Row(
                    children: [
                      Icon(Icons.favorite, size: 20),
                      SizedBox(width: 8),
                      Text('My Favorite Trainer'),
                    ],
                  ),
                ),
              );
              
              items.add(
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              );
              
              return items;
            },
          ),
              // 읽지 않은 메시지가 있으면 노란 점 표시
              if (_unreadMessageCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _users.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No more cards to match.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // 카드 영역 - 화면에 꽉 차게
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                          child: AppinioSwiper(
                            controller: _swiperController,
                            cardCount: _users.length,
                            cardBuilder: (BuildContext context, int index) {
                              if (index >= _users.length) {
                                return const SizedBox.shrink();
                              }
                              return _buildProfileCard(context, _users[index]);
                            },
                            onSwipeEnd: (previousIndex, targetIndex, activity) {
                                print('========================================');
                                print('onSwipeEnd 콜백 호출됨');
                                print('  - previousIndex: $previousIndex');
                                print('  - targetIndex: $targetIndex');
                                print('  - activity: $activity');
                                print('  - _users.length (스와이프 전): ${_users.length}');
                                if (previousIndex >= 0 && previousIndex < _users.length) {
                                  final swipedUser = _users[previousIndex];
                                  print('  - 스와이프된 카드: ${swipedUser['name']} (ID: ${swipedUser['user_id']})');
                                }
                                print('========================================');
                                
                                // AppinioSwiper는 항상 첫 번째 카드를 보여주므로, _currentCardIndex는 항상 0
                                setState(() {
                                  _currentCardIndex = 0;
                                });
                                
                                // 버튼으로 인한 스와이프인 경우 - 이미 카드가 제거되었으므로 여기서는 아무것도 하지 않음
                                if (_isButtonSwipe) {
                                  print('========================================');
                                  print('버튼으로 인한 스와이프 - 이미 카드가 제거됨 (무시)');
                                  print('  - previousIndex: $previousIndex');
                                  print('  - 이 콜백은 무시됩니다 (카드는 이미 제거됨)');
                                  print('========================================');
                                  
                                  // 플래그와 pending ID 리셋
                                  _isButtonSwipe = false;
                                  _pendingSwipeUserId = null;
                                  
                                  return;
                                }
                                
                                // 수동 스와이프인 경우에만 저장
                                if (previousIndex >= 0 && previousIndex < _users.length) {
                                  final swipedUser = _users[previousIndex];
                                  final swipedUserId = swipedUser['user_id'] as String;
                                  final swipedUserName = swipedUser['name'] as String? ?? 'Unknown';
                                  
                                  print('========================================');
                                  print('수동 카드 스와이프 이벤트 발생');
                                  print('  - previousIndex: $previousIndex');
                                  print('  - activity: $activity');
                                  print('  - swipedUserName: $swipedUserName');
                                  print('  - swipedUserId: $swipedUserId');
                                  
                                  // activity에서 방향 확인
                                  final activityStr = activity.toString();
                                  // 오른쪽으로 스와이프한 경우 (좋아요)
                                  if (activityStr.contains('right') ||
                                      activityStr.contains('Right')) {
                                    print('  -> 오른쪽 스와이프 감지: 좋아요 저장 시작');
                                    _saveMatch(swipedUserId, isMatch: true);
                                  }
                                  // 왼쪽으로 스와이프한 경우 (싫어요) - 저장하지 않음
                                  else if (activityStr.contains('left') ||
                                          activityStr.contains('Left')) {
                                    print('  -> 왼쪽 스와이프 감지: 싫어요 (저장하지 않음)');
                                    // 싫어요는 Supabase에 저장하지 않음
                                  } else {
                                    print('  -> 알 수 없는 방향: $activity');
                                  }
                                  print('========================================');
                                  
                                  // 스와이프한 카드 제거
                                  setState(() {
                                    if (previousIndex < _users.length) {
                                      _users.removeAt(previousIndex);
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      // 카드가 있을 때만 버튼 표시
                      if (_users.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 32.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildCircleActionButton(
                                color: Theme.of(context).colorScheme.error,
                                icon: Icons.skip_next,
                                onTap: () {
                                  print('========================================');
                                  print('싫어요 버튼 클릭됨!');
                                  if (_users.isNotEmpty) {
                                    // AppinioSwiper는 리스트의 마지막 카드를 맨 위에 보여줍니다
                                    final lastIndex = _users.length - 1;
                                    final currentUser = _users[lastIndex];
                                    final swipedUserId = currentUser['user_id'] as String?;
                                    final swipedUserName = currentUser['name'] as String? ?? 'Unknown';
                                    print('  - 대상: $swipedUserName (ID: $swipedUserId)');
                                    print('  - 마지막 카드 인덱스: $lastIndex');
                                    
                                    // 싫어요는 Supabase에 저장하지 않고 바로 카드 제거만 실행
                                    print('싫어요 버튼 클릭 (저장하지 않음, 카드 제거만 실행)...');
                                    setState(() {
                                      _users.removeAt(lastIndex);
                                    });
                                  } else {
                                    print('경고: 싫어요할 카드가 없습니다!');
                                  }
                                  print('========================================');
                                },
                              ),
                              const SizedBox(width: 40),
                              _buildCircleActionButton(
                                color: Theme.of(context).colorScheme.secondary,
                                icon: Icons.favorite,
                                onTap: () {
                                  print('========================================');
                                  print('좋아요 버튼 클릭됨!');
                                  print('  - _users.length: ${_users.length}');
                                  if (_users.isNotEmpty) {
                                    // AppinioSwiper는 리스트의 마지막 카드(_users[length-1])를 맨 위에 보여줍니다
                                    final lastIndex = _users.length - 1;
                                    final currentUser = _users[lastIndex];
                                    final swipedUserId = currentUser['user_id'] as String?;
                                    final swipedUserName = currentUser['name'] as String? ?? 'Unknown';
                                    print('좋아요 대상: $swipedUserName (ID: $swipedUserId)');
                                    print('  - 마지막 카드 인덱스: $lastIndex');
                                    print('  - 전체 카드 목록:');
                                    for (int i = 0; i < _users.length; i++) {
                                      final user = _users[i];
                                      final userId = user['user_id'] as String?;
                                      final userName = user['name'] as String? ?? 'Unknown';
                                      print('    [$i] $userName (ID: $userId) ${i == lastIndex ? "← 현재 보이는 카드" : ""}');
                                    }
                                    
                                    if (swipedUserId != null && swipedUserId.isNotEmpty) {
                                      // 버튼 플래그와 pending ID 설정 (스와이프 전에 고정)
                                      _isButtonSwipe = true;
                                      _pendingSwipeUserId = swipedUserId;
                                      
                                      // 먼저 저장하고, 그 다음 카드 제거
                                      print('좋아요 저장 시작 (버튼 클릭)...');
                                      print('  - 저장할 유저 ID (고정): $swipedUserId');
                                      print('  - 저장할 유저 이름: $swipedUserName');
                                      _saveMatch(swipedUserId, isMatch: true).then((_) {
                                        print('좋아요 저장 완료, 카드 제거 실행...');
                                        print('  - 저장된 유저 ID: $swipedUserId');
                                        final currentLastIndex = _users.length - 1;
                                        print('  - 현재 마지막 카드 인덱스: $currentLastIndex');
                                        print('  - 현재 마지막 카드 ID: ${_users.isNotEmpty ? _users[currentLastIndex]['user_id'] : 'N/A'}');
                                        print('  - 현재 마지막 카드 이름: ${_users.isNotEmpty ? (_users[currentLastIndex]['name'] as String? ?? 'Unknown') : 'N/A'}');
                                        // 저장한 유저가 여전히 마지막 카드인지 확인
                                        if (_users.isNotEmpty && _users[currentLastIndex]['user_id'] == swipedUserId) {
                                          print('  -> 카드 일치 확인, 마지막 카드 직접 제거');
                                          // AppinioSwiper는 마지막 카드를 보여주므로 마지막 카드를 제거
                                          setState(() {
                                            _users.removeAt(currentLastIndex);
                                          });
                                          // 플래그 리셋
                                          _isButtonSwipe = false;
                                          _pendingSwipeUserId = null;
                                        } else {
                                          print('경고: 카드가 이미 변경됨, 제거 취소');
                                          print('  - 예상 ID: $swipedUserId');
                                          print('  - 실제 마지막 카드 ID: ${_users.isNotEmpty ? _users[currentLastIndex]['user_id'] : 'N/A'}');
                                          _isButtonSwipe = false;
                                          _pendingSwipeUserId = null;
                                        }
                                      }).catchError((error) {
                                        print('좋아요 저장 실패: $error');
                                        _isButtonSwipe = false; // 에러 시 플래그 리셋
                                        _pendingSwipeUserId = null;
                                        // 저장 실패해도 카드는 제거
                                        final currentLastIndex = _users.length - 1;
                                        if (_users.isNotEmpty && _users[currentLastIndex]['user_id'] == swipedUserId) {
                                          setState(() {
                                            _users.removeAt(currentLastIndex);
                                          });
                                        }
                                      });
                                    } else {
                                      print('ERROR: swipedUserId가 null이거나 비어있습니다!');
                                    }
                                  } else {
                                    print('경고: 좋아요할 카드가 없습니다!');
                                  }
                                  print('========================================');
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }

  String _formatDistance(double distanceMeters) {
    // 거리를 지정된 범위로 반올림
    if (distanceMeters < 100) {
      return '100m';
    } else if (distanceMeters < 500) {
      return '500m';
    } else if (distanceMeters < 1000) {
      return '1km';
    } else if (distanceMeters < 5000) {
      return '5km';
    } else if (distanceMeters < 10000) {
      return '10km';
    } else if (distanceMeters < 20000) {
      return '20km';
    } else if (distanceMeters < 50000) {
      return '50km';
    } else if (distanceMeters < 100000) {
      return '100km';
    } else {
      // 100km 이상은 실제 거리 표시
      return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
    }
  }

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

  Widget _buildProfileImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return Builder(
        builder: (context) => Container(
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: Icon(
            Icons.person,
            size: 100,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // base64 data URL인 경우
    if (imagePath.startsWith('data:image')) {
      return Image.memory(
        base64Decode(imagePath.split(',')[1]),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Theme.of(context).colorScheme.surfaceVariant,
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
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Theme.of(context).colorScheme.surfaceVariant,
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
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.person, size: 100),
            );
          },
        );
      } catch (e) {
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.person, size: 100),
        );
      }
    }
    
    // 기본값
    return Builder(
      builder: (context) => Container(
        color: Theme.of(context).colorScheme.surfaceVariant,
        child: Icon(
          Icons.person,
          size: 100,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, Map<String, dynamic> user) {
    final userType = user['user_type'] as String? ?? '';
    final name = user['name'] as String? ?? 'No name';
    final age = user['age'] as int?;
    final gender = user['gender'] as String?;
    final talents = user['talents'] as List<dynamic>?;
    final goals = user['goals'] as List<dynamic>?;
    final teachingMethods = user['teaching_methods'] as List<dynamic>?;
    final parentParticipationWelcomed = user['parent_participation_welcomed'] as bool? ?? false;
    
    // 현재 사용자의 goals 또는 talents 가져오기
    final currentUserType = _currentProfile?['user_type'] as String?;
    final currentUserGoals = currentUserType == 'trainee' 
        ? (_currentProfile?['goals'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? []
        : [];
    final currentUserTalents = currentUserType == 'trainer'
        ? (_currentProfile?['talents'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? []
        : [];

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProfileDetailScreen(
                profile: user,
                currentUserProfile: _currentProfile,
              ),
            ),
          );
        },
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: SizedBox.expand(
                child: _buildProfileImage(user['main_photo_path']),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                color: Theme.of(context).colorScheme.surface,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Distance display (이름 바로 옆, "Within" 포함)
                        if (user['distance_meters'] != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Within ${_formatDistance(user['distance_meters'] as double)}',
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
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                        if (age != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            _formatAgeRange(age, user['created_at'] as String?),
                            style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Trainer의 경우: Can teach (talents) - Chip으로 표시
                    if (userType == 'trainer' && talents != null && talents.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          // Trainer가 Trainer를 볼 때는 talent-talent 매칭, Trainer가 Trainee를 볼 때는 talent-goal 매칭
                          final matchingList = currentUserType == 'trainer' && userType == 'trainer'
                              ? currentUserTalents  // Trainer-Trainer: talent-talent
                              : currentUserGoals;    // Trainer-Trainee: talent-goal (또는 Trainee-Trainer: goal-talent)
                          
                          // 매칭 여부를 확인하고 정렬된 리스트 생성
                          final talentList = talents
                              .map((talent) {
                                final talentStr = talent.toString();
                                final isMatched = matchingList.contains(talentStr);
                                return (talentStr, isMatched);
                              })
                              .toList();
                          
                          // 매칭된 항목을 먼저 정렬
                          talentList.sort((a, b) {
                            if (a.$2 && !b.$2) return -1; // a가 매칭되고 b가 아니면 a를 앞으로
                            if (!a.$2 && b.$2) return 1;  // a가 매칭 안되고 b가 매칭되면 b를 앞으로
                            return 0; // 둘 다 매칭되거나 둘 다 안되면 순서 유지
                          });
                          
                          return Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: talentList
                                .take(5)
                                .map((item) {
                                  final talentStr = item.$1;
                                  final isMatched = item.$2;
                                  return Chip(
                                    label: Text(
                                      talentStr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isMatched ? Colors.white : null,
                                        fontWeight: isMatched ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    backgroundColor: isMatched ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceVariant,
                                    side: BorderSide(
                                      color: isMatched 
                                          ? Theme.of(context).colorScheme.primary 
                                          : Theme.of(context).colorScheme.surfaceVariant,
                                    ),
                                    padding: EdgeInsets.zero,
                                  );
                                })
                                .toList(),
                          );
                        },
                      ),
                    ],
                    // Trainer의 경우: Teaching Methods 표시
                    if (userType == 'trainer' && teachingMethods != null && teachingMethods.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          if (teachingMethods.contains('onsite'))
                            Chip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.location_on, size: 14, color: Theme.of(context).colorScheme.tertiary),
                                  const SizedBox(width: 4),
                                  const Text('Onsite'),
                                ],
                              ),
                              backgroundColor: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          if (teachingMethods.contains('online'))
                            Chip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.video_call, size: 14, color: Theme.of(context).colorScheme.tertiary),
                                  const SizedBox(width: 4),
                                  const Text('Online'),
                                ],
                              ),
                              backgroundColor: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          if (parentParticipationWelcomed)
                            Chip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.family_restroom, size: 14, color: Theme.of(context).colorScheme.secondary),
                                  const SizedBox(width: 4),
                                  const Text('Parent Welcome'),
                                ],
                              ),
                              backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                    ],
                    // Trainee의 경우: Wants to learn (goals) - Chip으로 표시
                    if (userType == 'trainee' && goals != null && goals.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Builder(
                        builder: (context) {
                          // 매칭 여부를 확인하고 정렬된 리스트 생성
                          final goalList = goals
                              .map((goal) {
                                final goalStr = goal.toString();
                                final isMatched = currentUserTalents.contains(goalStr);
                                return (goalStr, isMatched);
                              })
                              .toList();
                          
                          // 매칭된 항목을 먼저 정렬
                          goalList.sort((a, b) {
                            if (a.$2 && !b.$2) return -1; // a가 매칭되고 b가 아니면 a를 앞으로
                            if (!a.$2 && b.$2) return 1;  // a가 매칭 안되고 b가 매칭되면 b를 앞으로
                            return 0; // 둘 다 매칭되거나 둘 다 안되면 순서 유지
                          });
                          
                          return Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: goalList
                                .take(5)
                                .map((item) {
                                  final goalStr = item.$1;
                                  final isMatched = item.$2;
                                  return Chip(
                                    label: Text(
                                      goalStr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isMatched ? Colors.white : null,
                                        fontWeight: isMatched ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    backgroundColor: isMatched ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceVariant,
                                    side: BorderSide(
                                      color: isMatched 
                                          ? Theme.of(context).colorScheme.primary 
                                          : Theme.of(context).colorScheme.surfaceVariant,
                                    ),
                                    padding: EdgeInsets.zero,
                                  );
                                })
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveMatch(String swipedUserId, {required bool isMatch}) async {
    print('========================================');
    print('_saveMatch 함수 호출됨');
    print('  - swipedUserId: $swipedUserId');
    print('  - isMatch: $isMatch');
    print('  - _users.length: ${_users.length}');
    print('  - 현재 _users 리스트:');
    for (int i = 0; i < _users.length; i++) {
      final user = _users[i];
      final userId = user['user_id'] as String?;
      final userName = user['name'] as String? ?? 'Unknown';
      print('    [$i] $userName (ID: $userId) ${userId == swipedUserId ? "← 저장 대상" : ""}');
    }
    
    try {
      final authUserId = Supabase.instance.client.auth.currentUser?.id;
      final profileUserId = _currentProfile?['user_id'] as String?;
      
      // RLS 정책이 auth.uid()를 사용하므로 반드시 auth.currentUser.id를 사용해야 함
      // authUserId가 없으면 에러
      if (authUserId == null) {
        print('ERROR: auth.currentUser가 null입니다!');
        print('  - 로그인 상태를 확인하세요.');
        throw Exception('User not authenticated');
      }
      
      final currentUserId = authUserId;
      
      print('사용자 ID 확인:');
      print('  - currentUserId: $currentUserId');
      print('  - authUserId: $authUserId');
      print('  - profileUserId: $profileUserId');
      
      if (currentUserId.isEmpty) {
        print('ERROR: currentUserId가 비어있습니다!');
        throw Exception('User ID is empty');
      }
      
      if (swipedUserId.isEmpty) {
        print('ERROR: swipedUserId가 비어있습니다!');
        throw Exception('Swiped user ID is empty');
      }
      
      print('SupabaseService.saveMatch 호출 전...');
      await SupabaseService.saveMatch(
        swipedUserId: swipedUserId,
        currentUserId: currentUserId,
        isMatch: isMatch,
      );
      
      print('SupabaseService.saveMatch 호출 완료');
      
      // 저장 후 실제로 데이터가 있는지 확인
      print('저장 확인: matches 테이블에서 데이터 조회 시작...');
      try {
        final verifyResponse = await Supabase.instance.client
            .from('matches')
            .select()
            .eq('user_id', currentUserId)
            .eq('swiped_user_id', swipedUserId)
            .eq('is_match', isMatch)
            .maybeSingle();
        
        if (verifyResponse != null) {
          print('✓ 저장 확인 성공: matches 테이블에 데이터가 있습니다!');
          print('  저장된 데이터: $verifyResponse');
        } else {
          print('✗ 저장 확인 실패: matches 테이블에 데이터가 없습니다!');
        }
        
        // 전체 matches 개수 확인
        final allMatches = await Supabase.instance.client
            .from('matches')
            .select('id')
            .eq('user_id', currentUserId);
        
        print('현재 사용자의 전체 matches 개수: ${allMatches.length}');
      } catch (verifyError) {
        print('저장 확인 중 오류 발생: $verifyError');
      }
      
      print('Match saved successfully');
      print('========================================');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isMatch ? 'Added to favorites!' : 'Passed.'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('========================================');
      print('ERROR: Failed to save match');
      print('  - Error: $e');
      print('  - StackTrace: $stackTrace');
      print('========================================');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error occurred: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildCircleActionButton({
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}
