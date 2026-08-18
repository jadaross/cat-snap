# Apple Developer Console Setup Instructions

This guide walks you through configuring the Apple Developer Console for CatSnap App Store submission.

## Prerequisites
- Apple Developer Program membership ($99/year)
- Access to https://developer.apple.com
- Xcode installed on your Mac

## Step 1: Register Bundle ID

1. Go to https://developer.apple.com/account
2. Navigate to **Identifiers** → **Bundle IDs**
3. Click **+** to create a new Bundle ID
4. Fill in:
   - **Platform**: iOS, iPadOS
   - **Bundle ID**: `com.jadaross.CatSnap` (must match Xcode project)
   - **Type**: App ID
   - **Description**: CatSnap
5. Under **Capabilities**, scroll down and check **Sign in with Apple**
6. Click **Continue**, then **Register**

## Step 2: Configure Sign in with Apple

1. In the newly created Bundle ID, click on **Sign in with Apple**
2. Ensure it's enabled as a **Primary App ID**
3. No need to configure Service ID or Team ID for native flow
4. Save the configuration

## Step 3: Xcode Project Configuration

1. Open `CatSnap/CatSnap.xcodeproj` in Xcode
2. Select the **CatSnap** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Search for and add **Sign in with Apple**
6. This will automatically create `CatSnap/CatSnap.entitlements` (already exists)
7. Verify your **Team** is selected under Signing
8. Bundle Identifier should be `com.jadaross.CatSnap`

## Step 4: Supabase Dashboard Configuration

1. Go to your Supabase project dashboard
2. Navigate to **Authentication** → **Providers**
3. Find **Apple** in the list
4. Toggle **Enabled** to ON
5. Fill in **Authorized Client IDs** with: `com.jadaross.CatSnap`
6. Leave these fields blank (not needed for native flow):
   - Service ID
   - Secret Key  
   - Team ID
   - Key ID
7. Click **Save**

## Step 5: App Store Connect Setup

1. Go to https://appstoreconnect.apple.com
2. Navigate to **My Apps** → **+** → **New App**
3. Fill in:
   - **Platform**: iOS
   - **Name**: CatSnap
   - **Primary Language**: English
   - **Bundle ID**: com.jadaross.CatSnap (select from dropdown)
   - **SKU**: CATSNAP001 (or your preferred SKU)
4. Click **Create**

## Step 6: Configure App Information

In App Store Connect, for your new CatSnap app:

### Basic Information
- **Name**: CatSnap
- **Subtitle**: spot every cat.
- **Primary Category**: Photo & Video
- **Secondary Category**: Social Networking

### Age Rating
- Complete the age rating questionnaire honestly:
  - **User Generated Content**: Yes
  - **Location Services**: Yes
  - **Photo/Video**: Yes
  - **Social Networking**: Yes
- This should result in a 4+ rating

### Pricing and Availability
- **Price**: Free (or your preferred price tier)
- **Availability**: All territories (or select as needed)

## Step 7: Build and Upload

Once you complete the above:

1. In Xcode, select **Any iOS Device** as the destination
2. Go to **Product** → **Archive**
3. After archive completes, the Organizer window will open
4. Click **Distribute App**
5. Choose **App Store Connect**
6. Follow the upload process
7. Your build will appear in App Store Connect under **TestFlight** → **iOS**

## Step 8: Required Information for Submission

Before final submission, you'll need:

### App Store Information
- **Description** (4000 characters max)
- **Keywords** (100 characters max)
- **Screenshots** (6.7" and 6.1" iPhone required)
- **App Icon** (1024×1024 PNG)
- **Privacy Policy URL**: https://jadaross.github.io/cat-snap/privacy-policy.html
- **Support URL**: https://jadaross.github.io/cat-snap/ (or your support page)
- **Marketing URL** (optional)

### Privacy Nutrition Labels
Declare the following data collection:
- **Contact Info**: Email (linked to identity)
- **Photos**: Yes (linked to identity)  
- **Location**: Coarse location (linked to identity)
- **User Content**: Photos, sightings (linked to identity)
- **Tracking**: None

## Troubleshooting

### Bundle ID Already Exists
If `com.jadaross.CatSnap` already exists:
- Use the existing Bundle ID
- Or choose a different Bundle ID and update Xcode project

### Sign in with Apple Not Working
- Verify Bundle ID matches exactly between Apple Console and Xcode
- Check that Sign in with Apple is enabled in both places
- Ensure Supabase Authorized Client ID matches Bundle ID

### Build Upload Fails
- Verify your Apple Developer account is in good standing
- Check that provisioning profiles are valid
- Ensure Bundle ID is correctly configured in Xcode

## Notes

- The native Sign in with Apple flow does not require Service ID or `.p8` files
- Those are only needed if you implement the OAuth redirect flow (not used here)
- Account deletion revocation with Apple is deferred to v2 (not required for initial submission)
- Email confirmation should be re-enabled before TestFlight (currently off for dev)

## Checklist

- [ ] Bundle ID `com.jadaross.CatSnap` registered in Apple Developer Console
- [ ] Sign in with Apple enabled in Bundle ID capabilities
- [ ] Sign in with Apple capability added to Xcode project
- [ ] Apple Sign In provider enabled in Supabase Dashboard
- [ ] App Store Connect record created
- [ ] App Store basic information configured
- [ ] Age rating completed
- [ ] Privacy nutrition labels configured
- [ ] TestFlight build uploaded successfully