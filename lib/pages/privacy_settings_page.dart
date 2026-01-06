import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/models/user_privacy_settings.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  UserPrivacySettings? _settings;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) throw Exception('Not logged in');

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('private')
          .doc('privacy_settings')
          .get();

      if (doc.exists) {
        setState(() {
          _settings = UserPrivacySettings.fromJson(doc.data()!);
          _isLoading = false;
        });
      } else {
        // Create default settings
        setState(() {
          _settings = const UserPrivacySettings();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading privacy settings: $e');
      setState(() {
        _settings = const UserPrivacySettings();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_settings == null) return;

    setState(() => _isSaving = true);

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) throw Exception('Not logged in');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('private')
          .doc('privacy_settings')
          .set(_settings!.toJson(), SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Privacy settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error saving privacy settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacy Settings',
          style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_isSaving)
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
              onPressed: _saveSettings,
              child: const Text('Save'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSection(
                  title: 'Profile Visibility',
                  icon: Icons.visibility_outlined,
                  theme: theme,
                  children: [
                    _buildDropdownTile(
                      title: 'Who can view my profile',
                      value: _settings!.profileVisibility,
                      items: ProfileVisibility.values,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings!.copyWith(
                            profileVisibility: value,
                          );
                        });
                      },
                      getLabel: (v) => v.displayName,
                    ),
                    _buildSwitchTile(
                      title: 'Show avatar to strangers',
                      value: _settings!.showAvatarToStrangers,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings!.copyWith(
                            showAvatarToStrangers: value,
                          );
                        });
                      },
                    ),
                    _buildSwitchTile(
                      title: 'Show bio to strangers',
                      value: _settings!.showBioToStrangers,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings!.copyWith(
                            showBioToStrangers: value,
                          );
                        });
                      },
                    ),
                    _buildSwitchTile(
                      title: 'Show traits to strangers',
                      value: _settings!.showTraitsToStrangers,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings!.copyWith(
                            showTraitsToStrangers: value,
                          );
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: 'Content Settings',
                  icon: Icons.article_outlined,
                  theme: theme,
                  children: [
                    _buildDropdownTile(
                      title: 'Default post visibility',
                      value: _settings!.defaultPostVisibility,
                      items: PostVisibility.values,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings!.copyWith(
                            defaultPostVisibility: value,
                          );
                        });
                      },
                      getLabel: (v) => v.displayName,
                    ),
                    _buildSwitchTile(
                      title: 'Allow comments on posts',
                      value: _settings!.allowComments,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings!.copyWith(
                            allowComments: value,
                          );
                        });
                      },
                    ),
                    _buildSwitchTile(
                      title: 'Allow sharing posts',
                      value: _settings!.allowShare,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings!.copyWith(
                            allowShare: value,
                          );
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: 'Interaction Settings',
                  icon: Icons.people_outline,
                  theme: theme,
                  children: [
                    _buildSwitchTile(
                      title: 'Allow messages from strangers',
                      value: _settings!.allowMessageFromStrangers,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings!.copyWith(
                            allowMessageFromStrangers: value,
                          );
                        });
                      },
                    ),
                    _buildSwitchTile(
                      title: 'Allow matches from strangers',
                      value: _settings!.allowMatchFromStrangers,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings!.copyWith(
                            allowMatchFromStrangers: value,
                          );
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: 'Profile Card Settings',
                  icon: Icons.card_membership_outlined,
                  theme: theme,
                  children: [
                    _buildSwitchTile(
                      title: 'Enable profile card',
                      subtitle: 'Allow others to view your profile card',
                      value: _settings!.enableProfileCard,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings!.copyWith(
                            enableProfileCard: value,
                          );
                        });
                      },
                    ),
                    _buildSwitchTile(
                      title: 'Require subscription to view',
                      subtitle: 'Non-subscribers need subscription to view',
                      value: _settings!.profileCardRequiresSubscription,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings!.copyWith(
                            profileCardRequiresSubscription: value,
                          );
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: 'Blocked Users',
                  icon: Icons.block_outlined,
                  theme: theme,
                  children: [
                    if (_settings!.blockedUserIds.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No blocked users',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ..._settings!.blockedUserIds.map((userId) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[300],
                            child: Icon(Icons.person, color: Colors.grey[600]),
                          ),
                          title: Text(userId.substring(0, 16) + '...'),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              setState(() {
                                _settings = _settings!.unblockUser(userId);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('User unblocked')),
                              );
                            },
                          ),
                        );
                      }).toList(),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required ThemeData theme,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            )
          : null,
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildDropdownTile<T>({
    required String title,
    required T value,
    required List<T> items,
    required Function(T) onChanged,
    required String Function(T) getLabel,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: DropdownButton<T>(
        value: value,
        underline: const SizedBox(),
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(getLabel(item)),
          );
        }).toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
      ),
    );
  }
}
