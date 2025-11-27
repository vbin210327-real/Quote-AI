# Quote AI - iOS App

A native iOS app that provides motivational quotes using Kimi AI. Built with SwiftUI.

## Features

- Native iOS app built with SwiftUI
- Beautiful, modern chat interface
- Real-time responses from Kimi AI
- Secure API key handling
- Dark mode support
- Smooth animations and loading states

## Project Structure

```
Quote AI/
├── QuoteAIApp.swift        # App entry point
├── ChatView.swift           # Main chat interface (SwiftUI)
├── ChatViewModel.swift      # View model with business logic
├── KimiService.swift        # API service layer
├── Models.swift             # Data models
├── Config.swift             # Configuration (API key)
├── Info.plist              # App configuration
├── .gitignore              # Git ignore rules
└── README.md               # This file
```

## Setup Instructions

### 1. Create Xcode Project

1. Open Xcode
2. Select "Create a new Xcode project"
3. Choose "iOS" → "App"
4. Fill in:
   - Product Name: `Quote AI`
   - Team: Your team
   - Organization Identifier: `com.yourname`
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Storage: `None`
5. Save to: `/Users/linfanbin/Desktop/Quote AI`

### 2. Add Source Files

The source files have already been created in the project directory:
- QuoteAIApp.swift
- ChatView.swift
- ChatViewModel.swift
- KimiService.swift
- Models.swift
- Config.swift

**Important:** After creating the Xcode project, you'll need to add these files to your project:
1. In Xcode, right-click on the "Quote AI" folder in the Project Navigator
2. Select "Add Files to Quote AI..."
3. Select all the Swift files listed above
4. Make sure "Copy items if needed" is unchecked (files are already in place)
5. Click "Add"

### 3. Configure App Permissions

The app needs internet access to call the Kimi API. This is already configured in `Info.plist`.

### 4. Build and Run

1. Select a simulator or connected device
2. Press `Cmd + R` to build and run
3. The app will launch with the chat interface

## How It Works

### Architecture

The app follows MVVM (Model-View-ViewModel) architecture:

- **View** (`ChatView.swift`): SwiftUI interface
- **ViewModel** (`ChatViewModel.swift`): Manages state and business logic
- **Model** (`Models.swift`): Data structures
- **Service** (`KimiService.swift`): API communication layer
- **Config** (`Config.swift`): Configuration and constants

### API Integration

The app communicates with Kimi AI API at `https://api.moonshot.cn/v1/chat/completions`:

1. User types a message
2. `ChatViewModel` sends it to `KimiService`
3. `KimiService` makes HTTPS request with your API key
4. Response is parsed and displayed in the chat

### Security Notes

**IMPORTANT:** The current implementation stores the API key in `Config.swift`. This is acceptable for:
- Personal use
- Development/testing
- Apps not distributed to others

**For production apps distributed via App Store:**
1. Use Xcode build configurations to separate dev/prod keys
2. Or use a backend server (like the Node.js version) to proxy requests
3. Never commit `Config.swift` to public repositories (it's in `.gitignore`)

The API key is only used in the app itself and never sent anywhere except to the official Kimi API endpoint.

## Customization

### Change the System Prompt

Edit the `systemPrompt` in `Config.swift` to change how Quote AI responds.

### Adjust UI Colors

The app uses a purple gradient theme (`#667eea` → `#764ba2`). You can change these colors in `ChatView.swift`:

```swift
Color(hex: "667eea")  // Replace with your color
Color(hex: "764ba2")  // Replace with your color
```

### Change Model or Parameters

In `Config.swift`, you can adjust:
- `modelName`: Switch to different Kimi models
- In `KimiService.swift`:
  - `temperature`: Controls randomness (0.0 - 1.0)
  - `maxTokens`: Maximum response length

## Testing

Run the app in the iOS Simulator or on a physical device. Try asking:
- "I'm feeling unmotivated today"
- "I'm nervous about my presentation"
- "I just failed my exam"
- "I'm starting a new job tomorrow"

Quote AI will respond with inspiring, motivational quotes tailored to your message.

## Requirements

- macOS with Xcode 14.0 or later
- iOS 16.0 or later
- Valid Kimi API key

## Troubleshooting

### Build Errors
- Make sure all Swift files are added to the Xcode project
- Check that the deployment target is set to iOS 16.0+

### API Errors
- Verify your API key is correct in `Config.swift`
- Check your internet connection
- Ensure the Kimi API endpoint is accessible

### Network Errors
- The app requires internet access
- Check that App Transport Security is configured in Info.plist

## Next Steps

Potential enhancements:
- [ ] Add conversation history persistence (Core Data or UserDefaults)
- [ ] Support for different quote categories
- [ ] Share quotes to social media
- [ ] Widget support for daily quotes
- [ ] Custom themes and appearance options
- [ ] Favorite quotes feature

## License

Personal use only. Kimi API usage subject to Moonshot AI's terms of service.
