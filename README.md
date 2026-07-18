<p align="center"><br><img src="https://user-images.githubusercontent.com/236501/85893648-1c92e880-b7a8-11ea-926d-95355b8175c7.png" width="128" height="128" /></p>
<h3 align="center">Live Activities</h3>
<p align="center"><strong><code>capacitor-live-activities</code></strong></p>
<p align="center">
  Ionic Capacitor plugin for <a href="https://developer.apple.com/videos/play/wwdc2023/10184/">Live Activities</a> for iOS 16.2+
</p>

<p align="center">
  <img src="https://img.shields.io/maintenance/yes/2025?style=flat-square" />
  <a href="https://www.npmjs.com/package/capacitor-live-activities"><img src="https://img.shields.io/npm/l/capacitor-live-activities?style=flat-square" /></a>
  <a href="https://www.npmjs.com/package/capacitor-live-activities"><img src="https://img.shields.io/npm/dw/capacitor-live-activities?style=flat-square" /></a>
  <a href="https://www.npmjs.com/package/capacitor-live-activities"><img src="https://img.shields.io/npm/v/capacitor-live-activities?style=flat-square" /></a>
<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->
<a href="#contributors-"><img src="https://img.shields.io/badge/all%20contributors-0-orange?style=flat-square" /></a>
<!-- ALL-CONTRIBUTORS-BADGE:END -->
<br />
<a href="https://www.buymeacoffee.com/ludufre"><img src="https://img.shields.io/badge/Buy%20me%20a%20coffee-ludufre-fce802?style=flat-square" alt="Buy me a coffee"></a>
</p>

## Maintainers

| Maintainer             | GitHub                                | Social                            | LinkedIn                                                           |
| ---------------------- | ------------------------------------- | --------------------------------- | ------------------------------------------------------------------ |
| Luan Freitas (ludufre) | [ludufre](https://github.com/ludufre) | [@ludufre](https://x.com/ludufre) | [Luan Freitas](https://www.linkedin.com/in/luan-freitas-14341687/) |


## ✨ Features

- 🏃‍♂️ **Easy Integration**: Simple installation with automatic configuration
- 🎨 **Flexible Layouts**: JSON-based layout system with containers, text, images, progress, and timers
- 📱 **Dynamic Island Support**: Full support for iPhone 14 Pro+ Dynamic Island states
- 🔄 **Real-time Updates**: Live data updates with push notifications
- 🖼️ **Rich Media**: Support for SF Symbols, images, gradients, and custom styling
- ⏱️ **Timer Integration**: Built-in countdown and relative time displays
- 📊 **Progress Tracking**: Visual progress bars and completion indicators
- 🎯 **Multiple Examples**: Comprehensive examples including sports scoreboards and food delivery tracking

## 🎯 JSON Layout System

Create beautiful Live Activities using a declarative JSON structure:

```typescript
const result = await LiveActivities.startActivity({
  layout: {
    type: "container",
    properties: [{ direction: "vertical" }, { spacing: 12 }],
    children: [
      {
        type: "text",
        properties: [{ text: "{{title}}" }, { fontSize: 18 }]
      }
    ]
  },
  data: { title: "Hello Live Activity!" }
});
```

## [🧑🏻‍🏫 Documentation & How-to](./docs/README.md)

## 🚀 Quick Start

### 1. Install the Plugin

```bash
npm install capacitor-live-activities
npx cap sync
```

### 2. Create Widget Extension in Xcode

1. **Open your iOS project in Xcode**
2. **Add Widget Extension Target:**
   - File → New → Target
   - Select "Widget Extension"
   - **Product Name:** `LiveActivities` (exactly as shown)
   - **Uncheck all options:** `Include Live Activity`, `Include Control`, `Include Configuration App Intent`
   - Click "Finish"
   - Choose `Don't Activate` when prompted

<img src="docs/assets/target-1.png" width="400" />  
<img src="docs/assets/target-2.png" width="400" />  
<img src="docs/assets/target-3.png" />  
<img src="docs/assets/target-4.png" />  

3. **Convert to Group:**
   - Right-click on `LiveActivities` folder in Xcode
   - Select "Convert to Group"

<img src="docs/assets/convert-target.png" width="400" />

### 3. Configure Podfile

Add the LiveActivitiesKit dependency to your `ios/App/Podfile`:

```ruby
target 'LiveActivitiesExtension' do
  pod 'LiveActivitiesKit', :path => '../../node_modules/capacitor-live-activities'
end
```

### 4. Enable Live Activities

Add Live Activities support to your `ios/App/Info.plist`:

```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

### 5. Configure Widget Bundle

Replace the content of `ios/App/LiveActivities/LiveActivitiesBundle.swift`:

```swift
import WidgetKit
import SwiftUI
import LiveActivitiesKit

@main
struct LiveActivitiesBundle: WidgetBundle {
    var body: some Widget {
        LiveActivities()
        DynamicActivityWidget()
    }
}
``` 

### 6. Add App Groups Capability

1. **In Xcode, select your main app target**
2. **Go to Signing & Capabilities**
3. **Add App Groups capability**
4. **Create new App Group:** `group.YOUR_BUNDLE_ID.liveactivities`
   - Example: `group.com.example.myapp.liveactivities`
5. **Repeat for Widget Extension target**

<img src="docs/assets/capability-1.png" width="400" />  
<img src="docs/assets/capability-2.png" width="400" />  

### 7. Basic Usage

<img src="docs/assets/example.png" width="400" />  

```typescript
import { LiveActivities } from 'capacitor-live-activities';

// Start a Live Activity
const result = await LiveActivities.startActivity({
  layout: {
    type: 'container',
    properties: [
      { direction: 'vertical' },
      { spacing: 12 },
      { padding: 16 },
      { backgroundColor: '#ffffff' },
      { cornerRadius: 12 },
    ],
    children: [
      {
        type: 'text',
        properties: [
          { text: '{{title}}' },
          { fontSize: 18 },
          { fontWeight: 'bold' },
          { color: '#1a1a1a' },
          { alignment: 'center' },
        ],
      },
    ],
  },
  dynamicIslandLayout: {
    expanded: {
      leading: {
        type: 'text',
        properties: [{ text: 'Left' }],
      },
      center: {
        type: 'text',
        properties: [{ text: 'Center' }],
      },
      trailing: {
        type: 'text',
        properties: [{ text: 'Right' }],
      },

      bottom: {
        type: 'text',
        properties: [{ text: '{{title}}' }],
      },
    },
    compactLeading: {
      type: 'image',
      properties: [{ systemName: 'face.smiling' }],
    },
    compactTrailing: {
      type: 'image',
      properties: [{ systemName: 'figure.walk.diamond.fill' }],
    },
    minimal: {
      type: 'text',
      properties: [{ text: 'Hi!' }],
    },
  },
  data: {
    title: 'Hello Live Activity!',
  },
  behavior: {
    systemActionForegroundColor: '#007AFF',
    widgetUrl: 'https://example.com',
    keyLineTint: '#007AFF',
  },
});

// Update the activity
await LiveActivities.updateActivity({
  activityId: result.activityId,
  data: {
    title: "Updated content!"
  }
});

// End the activity
await LiveActivities.endActivity({
  activityId: result.activityId,
  data: {
    title: "Activity completed"
  },
  // Optional: how the ended activity leaves the Lock Screen.
  // 'default' keeps it for up to 4 hours, 'immediate' removes it right away,
  // 'after' removes it at `dismissalDate` (ms, capped at 4 hours by iOS).
  dismissalPolicy: "immediate"
});
```

### Remote updates via APNs (push tokens)

Activities are requested with `pushType: .token`, so ActivityKit provides an
APNs token per activity for remote updates (`apns-push-type: liveactivity`).
Tokens arrive asynchronously after `startActivity` resolves and can rotate —
listen for them and forward the latest token to your server:

```typescript
await LiveActivities.addListener('activityPushToken', ({ activityId, pushToken }) => {
  // send the hex-encoded token to your backend
});
```

If the app lacks a push entitlement, the plugin automatically falls back to
starting the activity without push support (no token events are emitted).

## 📚 Examples

This plugin includes a comprehensive example app with multiple Live Activity implementations:

### JSON Layout Examples
- **Text Examples**: Typography, formatting, and styling
- **Image Examples**: SF Symbols, sizing, and layouts  
- **Timer Examples**: Countdown timers and time formatting
- **Progress Examples**: Progress bars and completion tracking
- **Container Examples**: Complex layouts with nested elements

### Real-World Examples
- **Football Scoreboard**: Complete sports scoreboard with Dynamic Island
- **Food Order Tracking**: Real-world delivery tracking example
- **Crypto Tracker**: Bitcoin price tracking with charts


### Run the Example App

```bash
cd example-app
npm install # or pnpm install
npx cap run ios
ionic cap run ios
```

## 🛠️ Troubleshooting

### Common Issues

1. **"No such module 'LiveActivitiesKit'"**
   - Ensure you added the Podfile target correctly
   - Run `npx cap sync` after adding the Podfile entry

2. **Live Activities not appearing**
   - Check that `NSSupportsLiveActivities` is in Info.plist
   - Verify App Groups are configured for both targets
   - Ensure you're testing on iOS 16.2+ device

3. **Dynamic Island not working**
   - Dynamic Island requires iPhone 14 Pro/Pro Max or newer
   - Test regular Live Activities first

4. **Build errors in Xcode**
   - Clean build folder (Cmd+Shift+K)
   - Delete DerivedData
   - Ensure Widget Extension target has correct settings

### Getting Help

- 📖 Check the [example app](./example-app) for complete implementations
- 🐛 Report issues on [GitHub](https://github.com/ludufre/capacitor-live-activities/issues)
- 💬 Join discussions in the issues section

## Maintainers

| Maintainer             | GitHub                                | Social                            | LinkedIn                                                           |
| ---------------------- | ------------------------------------- | --------------------------------- | ------------------------------------------------------------------ |
| Luan Freitas (ludufre) | [ludufre](https://github.com/ludufre) | [@ludufre](https://x.com/ludufre) | [Luan Freitas](https://www.linkedin.com/in/luan-freitas-14341687/) |

<br />
<a href="https://www.buymeacoffee.com/ludufre"><img src="https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png"></a>
