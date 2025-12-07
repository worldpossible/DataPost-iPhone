# DataPost for iOS

A SwiftUI iOS app for syncing content with RACHEL (Remote Area Community Hotspot for Education and Learning) devices.

## Features

- **📱 Status View**: Monitor connection to RACHEL devices and track file transfers
- **👤 Profile View**: View your courier statistics including devices visited, deliveries, and pickups
- **⚙️ Settings View**: Configure sync preferences and manage local storage
- **📂 Bundle Browser**: Browse and download content bundles from RACHEL devices

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Project Structure

```
DataPost/
├── DataPostApp.swift        # App entry point
├── ContentView.swift        # Main view with login/tab navigation
├── Info.plist               # App configuration
├── Assets.xcassets/         # App icons and colors
├── Views/
│   ├── StatusView.swift     # Sync status and transfer progress
│   ├── ProfileView.swift    # User profile and stats
│   ├── SettingsView.swift   # App settings
│   └── BundleListView.swift # Content bundle browser
├── Models/
│   ├── CourierStats.swift   # API response model
│   ├── Bundle.swift         # Content bundle model
│   └── AccessPoint.swift    # WiFi access point model
└── Services/
    ├── APIService.swift         # Gateway server API calls
    ├── AuthManager.swift        # Authentication state
    └── FileTransferManager.swift # File sync operations
```

## Setup

1. Open `DataPost.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Build and run on a device or simulator

### Firebase Setup (Optional)

To enable Google Sign-In:

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add an iOS app with bundle ID `org.worldpossible.DataPost`
3. Download `GoogleService-Info.plist` and add to the project
4. Add Firebase SDK via Swift Package Manager
5. Update `AuthManager.swift` to use Firebase Authentication

## API Endpoints

The app communicates with the DataPost gateway server:

- **Base URL**: `http://52.212.194.99:3000`
- **GET /courier-stats?email={email}**: Fetch courier statistics
- **POST /emule**: Upload files (multipart form data)

## Demo Mode

The app includes a Demo Mode for testing without Firebase configuration:
- Uses `jeremy@worldpossible.org` as the demo user
- Connects to the real gateway server for stats
- Simulates RACHEL device connections

## Building for Release

1. In Xcode, select Product > Archive
2. In the Organizer, click Distribute App
3. Choose your distribution method (App Store, Ad Hoc, Enterprise)

## License

Copyright © 2024 World Possible. All rights reserved.
