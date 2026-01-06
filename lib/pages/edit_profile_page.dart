import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/services/api_service.dart';
import 'package:flutter_app/services/service_locator.dart';
import 'package:flutter_app/services/profile_card_service.dart';
import 'package:flutter_app/models/user_data.dart';
import 'package:flutter_app/pages/auth_page.dart';
import 'package:flutter_app/pages/privacy_settings_page.dart';
import 'package:flutter_app/pages/subscribe_page.dart';

class EditProfilePage extends StatefulWidget {
  final UserData? userData;

  const EditProfilePage({super.key, this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final List<String> _selectedTraits = [];
  final ProfileCardService _profileCardService = ProfileCardService();
  bool _isLoading = false;

  final List<String> _availableTraits = [
  'Depression',
  'Anxiety',
  'Bipolar',
  'ADHD',
  'OCD',
    'PTSD',
  'BPD',
      'NPD',
      'Asperger',
      'Autism',
      'Eating D.',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.userData != null) {
      _usernameController.text = widget.userData!.username;
      _bioController.text = widget.userData!.freeText;
      _selectedTraits.addAll(widget.userData!.traits);
    } else {
      _usernameController.text = FirebaseAuth.instance.currentUser?.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate traits selection
    if (_selectedTraits.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 2 traits to help with matching'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = locator<ApiService>();
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) throw Exception('Not logged in');

      final updatedUser = UserData(
        uid: currentUser.uid,
        username: _usernameController.text.trim(),
        traits: _selectedTraits,
        freeText: _bioController.text.trim(),
        avatarUrl: widget.userData?.avatarUrl,
        followedBloggerIds: widget.userData?.followedBloggerIds ?? [],
        favoritedPostIds: widget.userData?.favoritedPostIds ?? [],
        favoritedConversationIds: widget.userData?.favoritedConversationIds ?? [],
      );

      await apiService.updateUser(updatedUser);

      // Also update or create profile card
      try {
        await _profileCardService.createProfileCard(updatedUser);
      } catch (e) {
        print('⚠️ Warning: Profile card update failed: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context, updatedUser);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleTrait(String trait) {
    setState(() {
      if (_selectedTraits.contains(trait)) {
        _selectedTraits.remove(trait);
      } else {
        _selectedTraits.add(trait);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Username
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a display name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Bio
            TextFormField(
              controller: _bioController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'About You',
                hintText: 'Tell others about yourself...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Traits section
            Text(
              'Mental Health & Personality',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select at least 2 conditions/traits that describe your journey (helps with better matching)',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTraits.map((trait) {
                final isSelected = _selectedTraits.contains(trait);
                return FilterChip(
                  label: Text(trait),
                  selected: isSelected,
                  onSelected: (_) => _toggleTrait(trait),
                  selectedColor: theme.primaryColor.withOpacity(0.2),
                  checkmarkColor: theme.primaryColor,
                  labelStyle: TextStyle(
                    color: isSelected ? theme.primaryColor : Colors.grey[700],
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 32),

            // Settings sections
            _buildSettingsSection(theme),

            const SizedBox(height: 32),

            // Logout button
            OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AuthPage()),
                      (route) => false,
                    );
                  }
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Profile Card Settings
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.credit_card,
              color: Colors.purple,
            ),
          ),
          title: const Text('Profile Card Settings'),
          subtitle: const Text('Customize your public profile display'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.pushNamed(context, '/profile_card_editor');
          },
        ),
        const Divider(),

        // Privacy Settings
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.lock_outline,
              color: theme.primaryColor,
            ),
          ),
          title: const Text('Privacy & Visibility'),
          subtitle: const Text('Control profile visibility and privacy'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PrivacySettingsPage(),
              ),
            );
          },
        ),
        const Divider(),
        
        // Premium Features
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.star,
              color: Colors.amber,
            ),
          ),
          title: const Text('Premium Membership'),
          subtitle: widget.userData?.hasActiveMembership == true
              ? Text(
                  'Active • ${widget.userData!.membershipTier.displayName}',
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w500),
                )
              : const Text('Upgrade for advanced features'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SubscribePage(),
              ),
            );

            if (result == true && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Subscription updated! Refreshing profile...'),
                  backgroundColor: Colors.green,
                ),
              );
              // Refresh the page to show updated membership
              Navigator.pop(context);
            }
          },
        ),
        const Divider(),

        // Account & Security
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.shield,
              color: Colors.blue,
            ),
          ),
          title: const Text('Account & Security'),
          subtitle: const Text('Manage password and account protection'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account security settings coming soon!'),
              ),
            );
          },
        ),
      ],
    );
  }
}
