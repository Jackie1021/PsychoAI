import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/models/user_data.dart';
import 'package:flutter_app/services/api_service.dart';
import 'package:flutter_app/services/service_locator.dart';
import 'package:intl/intl.dart';

class SubscribePage extends StatefulWidget {
  const SubscribePage({super.key});

  @override
  State<SubscribePage> createState() => _SubscribePageState();
}

class _SubscribePageState extends State<SubscribePage> {
  int _selectedPlanIndex = 1; // Default to Premium
  bool _isLoading = false;
  bool _isLoadingUser = true;
  UserData? _currentUser;
  bool _agreedToTerms = false;

  final List<MembershipPlan> _plans = [
    MembershipPlan(
      tier: MembershipTier.free,
      name: 'Free',
      price: 0,
      duration: 'Forever',
      features: [
        'Browse posts',
        'Create 10 posts per day',
        'Basic matching (3 matches per day)',
        'Standard support',
        'View match history (last 30 days)',
      ],
      limitations: [
        '3 free post unlocks per day',
        'Limited match analytics',
        'Ads supported',
      ],
      color: Colors.grey,
      icon: Icons.person_outline,
    ),
    MembershipPlan(
      tier: MembershipTier.premium,
      name: 'Premium',
      price: 9.99,
      duration: 'month',
      features: [
        'Everything in Free',
        'Unlimited posts',
        'AI-powered matching (unlimited)',
        'Unlock all posts',
        'Priority support',
        'No ads',
        'Special member badge',
        'View match history (all time)',
        'Basic match analytics',
      ],
      color: Colors.purple,
      icon: Icons.star,
      popular: true,
      savings: '60% off first month',
    ),
    MembershipPlan(
      tier: MembershipTier.pro,
      name: 'Pro',
      price: 19.99,
      duration: 'month',
      features: [
        'Everything in Premium',
        'Advanced match analytics',
        'Detailed compatibility insights',
        'Priority matching',
        'Early access to new features',
        'Custom profile themes',
        'Export yearly reports',
        'Dedicated support',
        'Exclusive community access',
      ],
      color: Colors.amber,
      icon: Icons.workspace_premium,
      savings: 'Best value',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    setState(() => _isLoadingUser = true);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final apiService = locator<ApiService>();
        final userData = await apiService.getUser(user.uid);
        
        if (mounted) {
          setState(() {
            _currentUser = userData;
            _isLoadingUser = false;
            
            // Set selected index based on current tier
            switch (userData.effectiveTier) {
              case MembershipTier.free:
                _selectedPlanIndex = 0;
                break;
              case MembershipTier.premium:
                _selectedPlanIndex = 1;
                break;
              case MembershipTier.pro:
                _selectedPlanIndex = 2;
                break;
            }
          });
        }
      } catch (e) {
        print('Error loading user: $e');
        if (mounted) {
          setState(() => _isLoadingUser = false);
        }
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingUser = false);
      }
    }
  }

  Future<void> _subscribe() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorDialog('Please log in to subscribe');
      return;
    }

    if (_selectedPlanIndex == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are already on the Free plan')),
      );
      return;
    }
    
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms of Service to continue'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedPlan = _plans[_selectedPlanIndex];
    
    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(selectedPlan);
    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Integrate with actual payment provider (Stripe, PayPal, etc.)
      // For now, simulate payment processing
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate payment validation
      final paymentSuccess = await _processPayment(selectedPlan);
      
      if (!paymentSuccess) {
        throw Exception('Payment processing failed');
      }

      final apiService = locator<ApiService>();
      final subscriptionId = 'sub_${DateTime.now().millisecondsSinceEpoch}_${user.uid.substring(0, 8)}';
      
      print('🔄 [SUBSCRIBE] Upgrading membership via Cloud Function...');
      print('   - User: ${user.uid}');
      print('   - Tier: ${selectedPlan.tier.name}');
      print('   - Subscription ID: $subscriptionId');
      
      // Use Cloud Function to upgrade membership
      await apiService.upgradeMembership(
        tier: selectedPlan.tier,
        durationDays: 30,
        subscriptionId: subscriptionId,
      );
      
      print('✅ [SUBSCRIBE] Membership upgraded successfully');
      
      // Reload user data to get updated membership info
      await _loadCurrentUser();

      if (mounted) {
        _showSuccessDialog(selectedPlan);
      }
    } catch (e) {
      print('❌ [SUBSCRIBE] Subscription failed: $e');
      if (mounted) {
        _showErrorDialog('Subscription failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _processPayment(MembershipPlan plan) async {
    // TODO: Integrate with payment gateway
    // This is a placeholder for real payment processing
    // 
    // Example integration points:
    // - Stripe: Use stripe_flutter package
    // - PayPal: Use paypal_flutter package
    // - In-app purchase: Use in_app_purchase package
    //
    // For now, return success to simulate payment
    return true;
  }

  Future<bool?> _showConfirmationDialog(MembershipPlan plan) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are subscribing to:',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '${plan.name} Plan',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: plan.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${plan.price.toStringAsFixed(2)} / ${plan.duration}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Auto-renews monthly. You can cancel anytime from your account settings.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: plan.color,
            ),
            child: const Text('Confirm & Subscribe'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(MembershipPlan plan) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            const Text('Welcome!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You\'re now a ${plan.name} member!',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Enjoy all premium features and start exploring!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Return to previous screen with success
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: plan.color,
              minimumSize: const Size(double.infinity, 45),
            ),
            child: const Text('Start Exploring'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 12),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Choose Your Plan',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Choose Your Plan',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current membership status
            if (_currentUser != null) _buildCurrentStatus(),
            const SizedBox(height: 24),

            // Header
            Text(
              'Unlock Premium Features',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose the plan that works best for you',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Plans
            ..._plans.asMap().entries.map((entry) {
              final index = entry.key;
              final plan = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildPlanCard(plan, index),
              );
            }).toList(),

            const SizedBox(height: 16),

            // Terms checkbox
            if (_selectedPlanIndex > 0) ...[
              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (value) {
                      setState(() => _agreedToTerms = value ?? false);
                    },
                    activeColor: _plans[_selectedPlanIndex].color,
                  ),
                  Expanded(
                    child: Text(
                      'I agree to the Terms of Service and Privacy Policy',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Subscribe button
            if (_selectedPlanIndex > 0)
              ElevatedButton(
                onPressed: _isLoading ? null : _subscribe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _plans[_selectedPlanIndex].color,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: _isLoading ? 0 : 2,
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
                    : Text(
                        'Subscribe for \$${_plans[_selectedPlanIndex].price.toStringAsFixed(2)}/${_plans[_selectedPlanIndex].duration}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),

            const SizedBox(height: 16),

            // Security notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Secure payment processing. Your data is protected.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Terms
            Text(
              'By subscribing, you agree to our Terms of Service and Privacy Policy. '
              'Subscription auto-renews unless cancelled. You can manage or cancel '
              'your subscription anytime from your profile settings.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatus() {
    final hasActive = _currentUser!.hasActiveMembership;
    final tier = _currentUser!.effectiveTier;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasActive ? Colors.purple[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasActive ? Colors.purple : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasActive ? Icons.star : Icons.person_outline,
            color: hasActive ? Colors.purple : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Plan: ${tier.displayName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (hasActive && _currentUser!.membershipExpiry != null)
                  Text(
                    'Expires: ${_formatDate(_currentUser!.membershipExpiry!)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(MembershipPlan plan, int index) {
    final isSelected = _selectedPlanIndex == index;
    final isCurrent = _currentUser?.effectiveTier == plan.tier;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlanIndex = index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? plan.color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: plan.color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Popular badge
            if (plan.popular)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: plan.color,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'POPULAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Current badge
            if (isCurrent)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'CURRENT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plan name
                  Text(
                    plan.name,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: plan.color,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        plan.price == 0
                            ? 'Free'
                            : '\$${plan.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (plan.price > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          plan.duration,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Features
                  ...plan.features.map((feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 20,
                              color: plan.color,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feature,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class MembershipPlan {
  final MembershipTier tier;
  final String name;
  final double price;
  final String duration;
  final List<String> features;
  final List<String> limitations;
  final Color color;
  final IconData icon;
  final bool popular;
  final String? savings;

  const MembershipPlan({
    required this.tier,
    required this.name,
    required this.price,
    required this.duration,
    required this.features,
    this.limitations = const [],
    required this.color,
    required this.icon,
    this.popular = false,
    this.savings,
  });
}
