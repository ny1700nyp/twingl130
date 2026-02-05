import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

enum AgreementType {
  trainer,
  trainee,
}

class AgreementScreen extends StatefulWidget {
  final AgreementType? agreementType; // null이면 사용자 타입 선택 화면 표시

  const AgreementScreen({
    super.key,
    this.agreementType,
  });

  @override
  State<AgreementScreen> createState() => _AgreementScreenState();
}

class _AgreementScreenState extends State<AgreementScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;
  bool _isAgreed = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScrollPosition);
    
    // 위젯이 빌드된 후 스크롤이 필요한지 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfScrollNeeded();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_checkScrollPosition);
    _scrollController.dispose();
    super.dispose();
  }

  void _checkIfScrollNeeded() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    // 스크롤이 필요 없는 경우 (모든 내용이 한 번에 보이는 경우)
    // maxScrollExtent가 10px 이하면 스크롤이 필요 없다고 판단
    if (maxScroll <= 10.0) {
      if (!_hasScrolledToBottom) {
        setState(() {
          _hasScrolledToBottom = true;
        });
      }
    }
  }

  void _checkScrollPosition() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = 50.0; // 50px 이내면 맨 아래로 간주

    // 스크롤이 필요 없는 경우 (모든 내용이 한 번에 보이는 경우)
    if (maxScroll <= 10.0) {
      if (!_hasScrolledToBottom) {
        setState(() {
          _hasScrolledToBottom = true;
        });
      }
      return;
    }

    // 스크롤이 필요한 경우
    if (maxScroll - currentScroll <= threshold) {
      if (!_hasScrolledToBottom) {
        setState(() {
          _hasScrolledToBottom = true;
        });
      }
    } else {
      if (_hasScrolledToBottom) {
        setState(() {
          _hasScrolledToBottom = false;
          _isAgreed = false; // 스크롤이 위로 올라가면 체크 해제
        });
      }
    }
  }

  Future<void> _handleConfirm() async {
    if (!_isAgreed || _isLoading) {
      print('Cannot confirm: _isAgreed=$_isAgreed, _isLoading=$_isLoading');
      return;
    }

    print('Confirming agreement for: ${widget.agreementType}');

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // 약관 동의 저장
      final agreementType = widget.agreementType == AgreementType.trainer
          ? 'trainer_terms'
          : 'trainee_waiver';

      print('Saving agreement: $agreementType');

      await SupabaseService.saveUserAgreement(
        agreementType: agreementType,
        version: 'v1.0',
      );

      print('Agreement saved successfully, navigating to onboarding');

      if (mounted) {
        // 모든 이전 화면을 제거하고 온보딩으로 이동
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/onboarding',
          (route) => false, // 모든 이전 라우트 제거
          arguments: {
            'userType': widget.agreementType == AgreementType.trainer ? 'tutor' : 'student',
          },
        );
      }
    } catch (e) {
      print('Failed to save agreement: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save agreement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 사용자 타입이 지정되지 않았으면 선택 화면 표시
    if (widget.agreementType == null) {
      return _buildUserTypeSelection();
    }

    final isTrainer = widget.agreementType == AgreementType.trainer;
    final title = isTrainer
        ? 'Partner & Safety Agreement'
        : 'Safe Learning & Waiver';
    final summary = isTrainer
        ? _trainerSummary
        : _traineeSummary;
    final legalText = isTrainer
        ? _trainerLegalText
        : _traineeLegalText;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Legal Agreement'),
        automaticallyImplyLeading: true, // 뒤로가기 버튼 표시
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            ),

            // Scrollable content area
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary
                      Text(
                        'Summary:',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ...summary.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '• ',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(fontSize: 16),
                                ),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 24),

                      // Legal Text
                      Text(
                        'Legal Text:',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                                ),
                            children: AppTheme.textSpansWithTwinglHighlight(
                              legalText,
                              baseStyle: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontSize: 14,
                                        height: 1.5,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ) ??
                                  const TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24), // Bottom padding for scroll detection
                    ],
                  ),
                ),
              ),
            ),

            // Checkbox
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Checkbox(
                    value: _isAgreed,
                    onChanged: _hasScrolledToBottom
                        ? (value) {
                            setState(() {
                              _isAgreed = value ?? false;
                            });
                          }
                        : null, // 스크롤하지 않으면 비활성화
                  ),
                  Expanded(
                  child: Text(
                    'I agree to the terms and conditions stated above.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: _hasScrolledToBottom
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.grey,
                        ),
                  ),
                  ),
                ],
              ),
            ),

            // Confirm Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isAgreed && !_isLoading) ? _handleConfirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Confirm',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Trainer content
  static const List<String> _trainerSummary = [
    'You are an Independent Pro (Independent Contractor, not employee).',
    'Compliance is Key (You hold necessary licenses/insurance).',
    'Liability (You maintain safe environment).',
  ];

  static const String _trainerLegalText =
      'I hereby agree to indemnify and hold harmless RadiusHub and its affiliates from any claims, damages, or expenses arising out of my services. I understand that I am solely responsible for the quality, safety, and legality of the services I provide.';

  // Trainee content
  static const List<String> _traineeSummary = [
    'Connect at Your Own Risk (RadiusHub is a connector, not a school).',
    'Assumption of Risk (You assume responsibility for injury/damage).',
    'Due Diligence (Verify your trainer).',
  ];

  static const String _traineeLegalText =
      'By continuing, I release and forever discharge RadiusHub from any and all liability, claims, and causes of action arising out of or related to my participation in any classes or interactions facilitated through this platform.';

  // 사용자 타입 선택 화면
  Widget _buildUserTypeSelection() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Role'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Please select your role',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Trainer 버튼
              SizedBox(
                width: double.infinity,
                height: 80,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AgreementScreen(
                          agreementType: AgreementType.trainer,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person, size: 32, color: Colors.white),
                      SizedBox(height: 8),
                      Text(
                        'Trainer',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Trainee 버튼
              SizedBox(
                width: double.infinity,
                height: 80,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AgreementScreen(
                          agreementType: AgreementType.trainee,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school, size: 32, color: Colors.white),
                      SizedBox(height: 8),
                      Text(
                        'Trainee',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
