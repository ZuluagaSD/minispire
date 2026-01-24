# Minispire Release Plan

## Google Play Store Status

### Completed
- [x] App created in Google Play Console
- [x] Store listing (English - US)
  - App name: Minispire
  - Short description
  - Full description
- [x] Graphics uploaded
  - App icon (512x512)
  - Feature graphic (1024x500)
  - Phone screenshots (4)
  - 7-inch tablet screenshots (4)
- [x] Content rating questionnaire
- [x] Target audience and content (18+)
- [x] Privacy policy URL (https://minispire.app/privacy)
- [x] Ads declaration (no ads)
- [x] Data safety declaration
- [x] Store settings (category: Art & Design)
- [x] Android App Bundle built (`build/app/outputs/bundle/release/app-release.aab`)

### Waiting On
- [ ] **Google identity verification** (in progress - may take a few days)
  - You'll receive an email when complete
- [ ] **Phone number verification** (requires identity verification first)

### To Do After Verification
1. Upload app bundle to Production track
   - Go to: Test and release > Production > Create new release
   - Upload: `android/app/build/outputs/bundle/release/app-release.aab`
2. Submit for review

---

## iOS App Store Status

### Prerequisites
- [ ] Apple Developer Program enrollment ($99/year)
  - Enroll at: https://developer.apple.com/programs/enroll/
  - Verification takes 24-48 hours

### To Do
1. **Create app in App Store Connect**
   - Bundle ID: `com.lesogs.minispire`
   - SKU: `minispire`
   - Primary language: English (US)

2. **App Information**
   - Name: Minispire
   - Subtitle: AI Miniature Painting Ideas
   - Category: Graphics & Design
   - Secondary Category: Entertainment
   - Content Rights: Does not contain third-party content
   - Age Rating: 4+

3. **Pricing and Availability**
   - Price: Free
   - Availability: All territories

4. **App Privacy**
   - Privacy Policy URL: https://minispire.app/privacy
   - Data collection: Photos (optional, not linked to identity)

5. **Version Information (1.0.0)**
   - Screenshots needed:
     - 6.7" iPhone (1290x2796) - iPhone 14 Pro Max
     - 6.5" iPhone (1284x2778) - iPhone 11 Pro Max
     - 5.5" iPhone (1242x2208) - iPhone 8 Plus
     - 12.9" iPad Pro (2048x2732)
   - App Preview (optional): None
   - Description: (use content from APP_STORE_DESCRIPTION.md)
   - Keywords: miniature,painting,warhammer,dnd,tabletop,inspiration,color scheme,ai,hobby,model,figurine,wargaming
   - Support URL: https://minispire.app/support
   - Marketing URL: https://minispire.app

6. **Build and Upload**
   ```bash
   # Clean and build iOS release
   cd /Users/dzs/Git/Personal/minispire
   flutter clean
   flutter build ios --release

   # Open Xcode and archive
   open ios/Runner.xcworkspace
   # In Xcode: Product > Archive > Distribute App > App Store Connect
   ```

7. **Submit for Review**
   - Review notes: None required
   - App Review contact info

---

## Files Reference

### Graphics (already created)
- App icon: `/Users/dzs/Git/Personal/minispire/app_icon_512.png`
- Feature graphic: `/Users/dzs/Git/Personal/minispire/feature_graphic.png`
- Phone screenshots: `/Users/dzs/Git/Personal/minispire/screenshots/google_play/phone/`
- Tablet screenshots: `/Users/dzs/Git/Personal/minispire/screenshots/google_play/tablet_7inch/`
- iOS app icons: `/Users/dzs/Git/Personal/minispire/ios/Runner/Assets.xcassets/AppIcon.appiconset/`

### Documentation
- Privacy Policy: `/Users/dzs/Git/Personal/minispire/PRIVACY_POLICY.md`
- App Store Description: `/Users/dzs/Git/Personal/minispire/APP_STORE_DESCRIPTION.md`

### Build Outputs
- Android AAB: `android/app/build/outputs/bundle/release/app-release.aab`
- iOS: Build via Xcode Archive

### Signing
- Android keystore: `android/app/keystore/release.jks`
- Android key properties: `android/key.properties`
- iOS: Managed via Xcode automatic signing

---

## iOS Screenshots To Create

The existing phone screenshots need to be resized for iOS requirements:

| Device | Size | Source |
|--------|------|--------|
| 6.7" iPhone | 1290x2796 | Scale from phone screenshots |
| 6.5" iPhone | 1284x2778 | Scale from phone screenshots |
| 5.5" iPhone | 1242x2208 | Scale from phone screenshots |
| 12.9" iPad | 2048x2732 | Scale from tablet screenshots |

Run iOS simulator and capture new screenshots, or resize existing ones.
