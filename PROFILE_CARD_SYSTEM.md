# Profile Card System - Complete Implementation

## 🎨 Overview

The Profile Card system is a comprehensive, customizable user profile display feature that allows users to create beautiful, personalized cards for social interaction. It integrates seamlessly with the subscription system and provides multiple access points throughout the app.

## ✨ Features

### 1. **Customization Options**
- **7 Built-in Themes**: Sunset, Ocean, Forest, Lavender, Rose Gold, Minimal, Dark Mode
- **4 Layout Styles**: Standard, Compact, Expanded, Magazine
- **Content Control**: Toggle visibility of bio, traits, posts, matches, and stats
- **Featured Content**: Select up to 3 posts to showcase
- **Privacy Settings**: Control who can view your card

### 2. **Access Control & Subscription Integration**
- **Free Users**: 3 profile card views per day
- **Premium/Pro Members**: Unlimited views
- **Privacy Options**: 
  - Allow/restrict stranger access
  - Show/hide specific sections
  - Feature public match history

### 3. **Multi-Page Integration**
- **Post Feed**: Click any user avatar to view their profile card
- **Match Results**: Access matched user's profile card
- **Profile Page**: Edit and preview your own card
- **Public Profile**: Alternative detailed view

## 📁 File Structure

```
lib/
├── models/
│   ├── profile_card.dart              # Core data model
│   └── profile_card_theme.dart        # Theme and customization models
├── pages/
│   ├── profile_card_page.dart         # View profile card (with permissions)
│   ├── profile_card_editor_page.dart  # Edit and customize card
│   └── profile_page.dart              # User's own profile (updated)
├── services/
│   └── profile_card_service.dart      # Business logic & Firebase operations
└── widgets/
    ├── profile_card_preview.dart      # Reusable preview component
    └── subscription_prompt_dialog.dart # Subscription upgrade prompt
```

## 🚀 Usage Guide

### For Users

#### **Viewing a Profile Card**
1. Navigate to post feed or match results
2. Tap on any user's avatar
3. View their customized profile card (subject to quota)
4. If quota exceeded, subscribe for unlimited access

#### **Editing Your Profile Card**
1. Go to your profile page (bottom navigation)
2. Tap the menu icon (⋮) in the top right
3. Select "Edit Profile Card"
4. Customize in 3 tabs:

**Content Tab:**
- Toggle visibility of bio, traits, stats
- Select featured posts (up to 3)
- Enable/disable match history display
- Configure privacy settings

**Theme Tab:**
- Choose from 7 beautiful themes
- Select layout style (Standard/Compact/Expanded/Magazine)
- Each theme has unique gradient colors

**Preview Tab:**
- See real-time preview of your card
- Test different layouts and themes
- Verify privacy settings

5. Tap "Save" to publish changes

#### **Viewing Your Own Card**
1. Go to profile page
2. Tap the card icon (🪪) in top right
3. View your card as others see it

### For Developers

#### **Creating a Profile Card on User Registration**
```dart
import 'package:flutter_app/services/profile_card_service.dart';
import 'package:flutter_app/models/user_data.dart';

final service = ProfileCardService();
final userData = UserData(/* ... */);

await service.createProfileCard(userData);
```

#### **Checking View Permission**
```dart
final permission = await service.checkViewPermission(targetUserId);

if (!permission.canView) {
  // Show blocked view
  // permission.reason tells why (no quota, blocked, etc.)
}
```

#### **Recording a View**
```dart
await service.recordView(targetUserId);
// Automatically increments view count and records history
```

#### **Updating Profile Card**
```dart
final updatedCard = profileCard.copyWith(
  bio: 'New bio',
  highlightedTraits: ['Trait1', 'Trait2'],
);

await service.updateProfileCard(updatedCard);
```

#### **Saving Customization**
```dart
final customization = ProfileCardCustomization(
  theme: ProfileCardTheme.ocean,
  showPosts: true,
  showMatches: false,
);

await service.saveCustomization(userId, customization);
```

## 🗄️ Data Models

### ProfileCard
```dart
ProfileCard(
  uid: String,                    // User ID
  username: String,               // Display name
  avatarUrl: String?,             // Avatar image URL
  bio: String,                    // User bio
  highlightedTraits: List<String>, // Selected traits to display
  postsCount: int,                // Number of posts
  matchesCount: int,              // Number of matches
  viewCount: int,                 // Profile card views
  featuredPostIds: List<String>,  // Up to 3 featured posts
  privacy: ProfileCardPrivacySettings,
  membershipTier: MembershipTier,
)
```

### ProfileCardCustomization
```dart
ProfileCardCustomization(
  theme: ProfileCardTheme,        // Selected theme
  showAvatar: bool,               // Show/hide avatar
  showBio: bool,                  // Show/hide bio
  showTraits: bool,               // Show/hide traits
  showPosts: bool,                // Show/hide featured posts
  showMatches: bool,              // Show/hide match history
  showStats: bool,                // Show/hide statistics
)
```

### ProfileCardTheme
```dart
ProfileCardTheme(
  id: String,                     // Unique identifier
  name: String,                   // Display name
  style: ProfileCardStyle,        // gradient/solid/glassmorphism/image
  gradientColors: List<String>,   // Hex color codes
  layout: ProfileCardLayout,      // standard/compact/expanded/magazine
)
```

## 🎨 Available Themes

1. **Sunset** - Warm reds and oranges (#FF6B6B, #FFA07A, #FFD93D)
2. **Ocean** - Cool blues and purples (#667eea, #764ba2, #f093fb)
3. **Forest** - Deep greens (#134E5E, #71B280)
4. **Lavender** - Purple tones (#B06AB3, #4568DC)
5. **Rose Gold** - Pink and cream (#ED4264, #FFEDBC)
6. **Minimal** - Pure white (#FFFFFF)
7. **Dark Mode** - Dark slate (#2C3E50)

## 🔐 Security & Privacy

### Firestore Security Rules

```javascript
// Profile Cards Collection
match /profileCards/{userId} {
  allow read: if request.auth != null;
  allow create: if request.auth.uid == userId;
  allow update: if request.auth.uid == userId;
  
  // Customization subcollection
  match /settings/{settingId} {
    allow read, write: if request.auth.uid == userId;
  }
}

// Profile Card Views Collection
match /profileCardViews/{viewerId} {
  allow read, write: if request.auth.uid == viewerId;
  
  match /daily/{date} {
    allow read, write: if request.auth.uid == viewerId;
  }
  
  match /history/{viewId} {
    allow read, write: if request.auth.uid == viewerId;
  }
}
```

### Privacy Features
- **Stranger Access Control**: Restrict card viewing to matched users only
- **Section Visibility**: Hide specific sections (traits, posts, matches)
- **View Tracking**: All views are recorded with timestamps
- **Subscription-Based**: Free tier has daily limits, premium unlimited

## 📊 Database Schema

### Collection: `profileCards`
```
profileCards/{userId}
  ├── uid: string
  ├── username: string
  ├── avatarUrl: string?
  ├── bio: string
  ├── highlightedTraits: string[]
  ├── postsCount: number
  ├── matchesCount: number
  ├── viewCount: number
  ├── likeCount: number
  ├── featuredPostIds: string[]
  ├── publicMatchIds: string[]
  ├── privacy: {
  │     showTraits: boolean
  │     showPosts: boolean
  │     showMatches: boolean
  │     showStats: boolean
  │     allowStrangerAccess: boolean
  │   }
  ├── membershipTier: string
  └── lastUpdated: timestamp

  └── settings/customization
        ├── theme: {...}
        ├── showAvatar: boolean
        ├── showBio: boolean
        ├── showTraits: boolean
        ├── showPosts: boolean
        ├── showMatches: boolean
        └── showStats: boolean
```

### Collection: `profileCardViews`
```
profileCardViews/{viewerId}
  ├── daily/{YYYY-MM-DD}
  │     ├── count: number
  │     ├── viewedUserIds: string[]
  │     └── lastUpdated: timestamp
  │
  └── history/{viewId}
        ├── viewerUserId: string
        ├── targetUserId: string
        └── timestamp: timestamp
```

## 🔄 Integration Points

### 1. Post Feed Integration
```dart
// In post_card.dart
void _navigateToProfile() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ProfileCardPage(userId: post.userId),
    ),
  );
}
```

### 2. Match Result Integration
```dart
// In match_result_page.dart
void _viewMatchedUserCard(String userId) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ProfileCardPage(userId: userId),
    ),
  );
}
```

### 3. Profile Page Integration
```dart
// In profile_page.dart - AppBar actions
PopupMenuButton<String>(
  onSelected: (value) {
    if (value == 'edit_card') {
      Navigator.pushNamed(context, '/profile_card_editor');
    }
  },
  itemBuilder: (context) => [
    PopupMenuItem(
      value: 'edit_card',
      child: Text('Edit Profile Card'),
    ),
  ],
)
```

## 🎯 Testing Checklist

- [ ] Create new profile card for fresh user
- [ ] Edit card content (bio, traits, featured posts)
- [ ] Change theme and verify preview updates
- [ ] Toggle privacy settings and verify access control
- [ ] Test free user daily quota (3 views)
- [ ] Verify premium users have unlimited views
- [ ] Test subscription prompt when quota exceeded
- [ ] Verify view count increments correctly
- [ ] Test profile card access from post feed
- [ ] Test profile card access from match results
- [ ] Verify privacy restrictions work correctly
- [ ] Test all 4 layout styles render properly
- [ ] Verify membership badges display correctly

## 🐛 Troubleshooting

### Issue: Profile card not found
**Solution**: Ensure `createProfileCard()` is called during user registration

### Issue: Customization not saving
**Solution**: Check Firestore rules allow write access to settings subcollection

### Issue: View quota not updating
**Solution**: Verify date string format in `_getTodayDateString()` matches database

### Issue: Theme not applying
**Solution**: Ensure customization is loaded before rendering preview

### Issue: Featured posts not showing
**Solution**: Verify post IDs in `featuredPostIds` exist and are accessible

## 📈 Future Enhancements

1. **Custom Background Images**: Upload custom backgrounds
2. **Animated Themes**: Add theme transitions and animations
3. **Social Sharing**: Share profile card as image
4. **QR Code**: Generate QR code for profile card
5. **Analytics**: Track which sections get most views
6. **Badges & Achievements**: Display earned badges on card
7. **Video Backgrounds**: Support video backgrounds for premium users
8. **Card Templates**: Pre-designed templates for quick setup

## 🎓 Best Practices

1. **Always check permissions** before displaying sensitive information
2. **Cache profile cards** for offline viewing
3. **Optimize images** to reduce loading time
4. **Implement pagination** for view history
5. **Rate limit** profile card updates to prevent abuse
6. **Log analytics** for feature usage insights
7. **A/B test** different themes to see user preferences

## 📝 Notes

- Profile cards are automatically created when editing profile for first time
- View counts update asynchronously to reduce latency
- Featured posts must be public to display on card
- Theme changes take effect immediately in preview
- Privacy settings override subscription benefits (private cards can't be viewed even by subscribers)

---

**Version**: 1.0.0  
**Last Updated**: November 2024  
**Maintainer**: Development Team
