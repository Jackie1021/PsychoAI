# Profile Card Quick Start Guide

## 🚀 Quick Start

### For Users

1. **Edit Your Card**
   - Go to Profile → Menu (⋮) → "Edit Profile Card"
   - Choose theme, layout, and content
   - Preview and save

2. **View Others' Cards**
   - Tap any avatar in post feed
   - Subject to daily limits (3/day free, unlimited premium)

### For Developers

```dart
// Import
import 'package:flutter_app/pages/profile_card_page.dart';

// Navigate to view card
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ProfileCardPage(userId: userId),
  ),
);

// Navigate to edit card
Navigator.pushNamed(context, '/profile_card_editor');
```

## 📁 Key Files

| File | Purpose |
|------|---------|
| `profile_card_theme.dart` | 7 themes + customization models |
| `profile_card_editor_page.dart` | Full-featured editor (3 tabs) |
| `profile_card_preview.dart` | Reusable preview widget |
| `profile_card_service.dart` | Business logic + Firebase |
| `profile_card_page.dart` | View card (with permissions) |

## 🎨 Themes

```dart
// Available themes
ProfileCardTheme.sunset      // Warm reds/oranges
ProfileCardTheme.ocean       // Cool blues
ProfileCardTheme.forest      // Natural greens
ProfileCardTheme.lavender    // Purple elegance
ProfileCardTheme.rose        // Pink/cream
ProfileCardTheme.minimal     // Clean white
ProfileCardTheme.dark        // Dark mode
```

## 📐 Layouts

```dart
// Available layouts
ProfileCardLayout.standard   // Classic balanced
ProfileCardLayout.compact    // Horizontal minimal
ProfileCardLayout.expanded   // Detailed vertical
ProfileCardLayout.magazine   // Creative banner style
```

## 🔐 Permissions

```dart
// Check view permission
final permission = await service.checkViewPermission(userId);

if (permission.canView) {
  // Show card
} else {
  // permission.reason tells why blocked
  // permission.remainingFreeViews shows quota
}
```

## 🎯 Common Tasks

### Update Profile Card
```dart
final card = profileCard.copyWith(
  bio: 'New bio',
  highlightedTraits: ['Trait1', 'Trait2', 'Trait3'],
);
await service.updateProfileCard(card);
```

### Save Customization
```dart
final customization = ProfileCardCustomization(
  theme: ProfileCardTheme.ocean,
  showPosts: true,
  showMatches: false,
);
await service.saveCustomization(userId, customization);
```

### Record View
```dart
await service.recordView(targetUserId);
// Automatically: increments count, checks quota, records history
```

## 📊 Stats Tracking

- **View Count**: Increments on each unique view
- **Daily Quota**: 3 free views per day per user
- **History**: All views recorded with timestamp
- **Privacy**: User can hide stats

## 🧪 Testing Checklist

- [ ] Create and save card customization
- [ ] View own card from profile page
- [ ] View other user's card from post feed
- [ ] Test all 7 themes render correctly
- [ ] Test all 4 layouts work properly
- [ ] Verify daily quota limits (free users)
- [ ] Test premium unlimited access
- [ ] Check privacy settings enforcement
- [ ] Verify featured posts display
- [ ] Test subscription prompt appears

## 💡 Tips

1. **Theme Selection**: Ocean and Sunset are most popular
2. **Layout Choice**: Standard for general use, Magazine for visual impact
3. **Featured Posts**: Choose your best 3 posts with images
4. **Privacy**: Enable stranger access for more visibility
5. **Bio**: Keep it short and engaging (2-3 lines)

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Card not found | Call `createProfileCard()` first |
| Can't save changes | Check Firestore permissions |
| Theme not showing | Reload customization data |
| Quota not working | Verify date format in service |
| Featured posts missing | Check post IDs are valid |

## 📞 Support

See full documentation in `PROFILE_CARD_SYSTEM.md`

---

**Quick Reference**: This guide covers 90% of common use cases. For advanced features and API details, see the complete documentation.
