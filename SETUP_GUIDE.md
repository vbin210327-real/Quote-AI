# Quick Setup Guide for Quote AI iOS App

## What You Have

All the Swift source code files are ready in your directory:
- ✅ QuoteAIApp.swift (app entry point)
- ✅ ChatView.swift (UI interface)
- ✅ ChatViewModel.swift (business logic)
- ✅ KimiService.swift (API integration)
- ✅ Models.swift (data structures)
- ✅ Config.swift (API key configuration)
- ✅ Info.plist (app configuration)

## Next Steps: Create the Xcode Project

### Option 1: Using Xcode GUI (Recommended for Beginners)

1. **Open Xcode** (if you don't have it, download from Mac App Store)

2. **Create New Project:**
   - Click "Create a new Xcode project"
   - Select "iOS" tab at top
   - Choose "App" template
   - Click "Next"

3. **Configure Project:**
   - Product Name: `Quote AI`
   - Team: Select your Apple ID (or leave as None for simulator only)
   - Organization Identifier: `com.yourname` (or any reverse domain)
   - Bundle Identifier: Will auto-fill as `com.yourname.Quote-AI`
   - Interface: **SwiftUI** (important!)
   - Language: **Swift** (important!)
   - Storage: None
   - Include Tests: (optional, can uncheck)
   - Click "Next"

4. **Save Location:**
   - Navigate to: `/Users/linfanbin/Desktop`
   - You'll see "Quote AI" folder
   - **IMPORTANT:** Xcode will try to create a new folder. Delete the " 2" or rename so it saves INTO the existing "Quote AI" folder
   - Or select "Quote AI" folder and click "Create"

5. **Remove Default Files:**
   - In Xcode's left sidebar (Project Navigator)
   - Find and delete these auto-generated files (select and press Delete, choose "Move to Trash"):
     - `ContentView.swift`
     - Any other duplicate Swift files

6. **Add Your Swift Files:**
   - Right-click on the "Quote AI" folder (the one with the blue icon) in Project Navigator
   - Select "Add Files to Quote AI..."
   - Navigate to `/Users/linfanbin/Desktop/Quote AI`
   - Select ALL these Swift files:
     - QuoteAIApp.swift
     - ChatView.swift
     - ChatViewModel.swift
     - KimiService.swift
     - Models.swift
     - Config.swift
   - **UNCHECK** "Copy items if needed" (files are already in the right place)
   - Make sure "Quote AI" target is checked
   - Click "Add"

7. **Build and Run:**
   - Select iPhone simulator (e.g., "iPhone 15 Pro") from top toolbar
   - Click the "Play" button (▶) or press `Cmd + R`
   - Wait for build to complete
   - App will launch in simulator!

### Option 2: Command Line (Advanced)

If you're comfortable with command line and want to generate the Xcode project using Swift Package Manager or other tools, you can initialize it manually. However, for iOS apps, using Xcode GUI is the standard approach.

## Testing the App

Once the app is running:

1. You'll see the welcome message
2. Type something like: "I'm feeling unmotivated"
3. Tap the send button
4. Quote AI will respond with an inspiring quote!

## Troubleshooting

### "No such module" errors
- Make sure all Swift files are added to the Xcode project target
- Check that the deployment target is iOS 16.0 or later (Project Settings → General → Minimum Deployments)

### API doesn't work
- Check Config.swift has the correct API key
- Make sure you have internet connection (simulator needs host internet)
- Check Console in Xcode (Cmd + Shift + Y) for error messages

### Build fails
- Make sure you selected "SwiftUI" when creating the project
- Verify all files are added to the target (check the box in File Inspector)
- Clean build folder: Product → Clean Build Folder (Cmd + Shift + K)

### App crashes immediately
- Check that QuoteAIApp.swift is set as the entry point
- Verify Info.plist is properly configured
- Look at crash logs in Xcode console

## Security Note

Your API key is in `Config.swift`. This is fine for personal use, but:
- ✅ `Config.swift` is in `.gitignore` so it won't be committed to git
- ✅ The key stays on your device and is only sent to Kimi API
- ⚠️ For App Store distribution, use Xcode build configurations or a backend server

## Need Help?

- Check the full README.md for detailed documentation
- Xcode Help menu has great tutorials
- Apple's SwiftUI documentation: https://developer.apple.com/documentation/swiftui

Enjoy your Quote AI app! 🚀
