# Swift Package Dependencies Setup

## Required Packages

You need to add these two Swift packages to your Xcode project:

### 1. Supabase Swift SDK
- Repository URL: `https://github.com/supabase/supabase-swift`
- Version: Latest (or `2.0.0` and up)

### 2. Google Sign-In SDK
- Repository URL: `https://github.com/google/GoogleSignIn-iOS`
- Version: Latest (or `7.0.0` and up)

## How to Add Packages in Xcode

1. Open `Quote AI.xcodeproj` in Xcode
2. Click on the project file in the navigator (the blue "Quote AI" icon)
3. Select the "Quote AI" target
4. Go to the "Package Dependencies" tab
5. Click the "+" button at the bottom
6. Paste the repository URL
7. Click "Add Package"
8. Select all the products that come with the package
9. Repeat for the second package

## Alternative: Command Line Method

You can also add these to your project's Package Dependencies by modifying the project.pbxproj file, but it's easier to use Xcode's UI.

### Quick Verification

After adding both packages, try building the project:
```bash
cd "/Users/linfanbin/Desktop/Quote AI/Quote AI"
xcodebuild -project "Quote AI.xcodeproj" -scheme "Quote AI" -sdk iphonesimulator
```

If there are no build errors related to missing imports, you're all set!
