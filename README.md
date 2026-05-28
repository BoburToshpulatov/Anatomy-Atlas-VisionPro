# Anatomy Atlas Vision Pro

Spatial anatomy learning app for Apple Vision Pro, built with `SwiftUI` and `RealityKit`.

This project is evolving toward a premium room-scale anatomy atlas where learners can:
- explore organs in immersive space
- study labeled anatomy structures
- answer guided quiz prompts
- track progress across organs and study modes

The current MVP includes real `Heart` and `Brain` model support, an immersive study scene, detached spatial labels, a right-side study panel, carousel-based organ switching, quiz flow, and persistent progress.

## Status

Current phase: `MVP in active development`

Implemented now:
- visionOS launcher window for entering study space
- `ImmersiveSpace` study scene
- study modes: `Explore`, `Labels`, `Quiz`
- organ carousel switching
- annotation tap focus
- Learn More expansion
- progress persistence in `AppModel`
- real spatial model support for:
  - Heart
  - Brain
- placeholder atlas entries for future organs:
  - Lungs
  - Liver
  - Kidneys
  - Stomach
  - Skeleton
  - Eye
  - Ear
  - Spine
  - Intestines

## Tech Stack

- `SwiftUI`
- `RealityKit`
- `Model3D`
- `ImmersiveSpace`
- `Observation` / `@Observable`
- local `RealityKitContent` package

## Project Structure

```text
Anatomy/
├── Anatomy/
│   ├── AnatomyApp.swift
│   ├── AppModel.swift
│   ├── ContentView.swift
│   ├── ImmersiveView.swift
│   ├── OrganRealityView.swift
│   ├── AnatomyOrgan.swift
│   ├── Assets.xcassets
│   └── Info.plist
├── Anatomy.xcodeproj/
├── Packages/
│   └── RealityKitContent/
└── README.md
```

## Architecture

### AppModel

`AppModel` is the central app state container. It manages:
- currently selected organ
- selected annotation
- current study mode
- immersive space state
- learn-more state
- quiz state
- persistent organ progress

### AnatomyOrgan

`AnatomyOrgan` defines organ content and presentation presets:
- titles and study copy
- functions and key parts
- annotation metadata
- quiz questions
- immersive layout presets
- model availability

### ImmersiveView

`ImmersiveView` is the main study experience. It renders:
- floating hero organ stage
- detached spatial labels
- right-side study panel
- bottom carousel
- top and bottom study mode controls

### OrganRealityView

`OrganRealityView` is responsible for:
- presenting bundled 3D models
- placeholder hero states for organs without models
- hero glow / aura treatment
- focus transitions for selected structures

## Getting Started

### Requirements

- macOS with Xcode supporting visionOS
- Apple Vision Pro simulator or device
- visionOS SDK

### Open the project

```bash
open /Users/boburtoshpulatov/Desktop/Anatomy/Anatomy.xcodeproj
```

### Build from terminal

```bash
xcodebuild -project Anatomy.xcodeproj -scheme Anatomy -destination 'generic/platform=visionOS' -derivedDataPath ./.derived-data build CODE_SIGNING_ALLOWED=NO
```

## Current Organ Model Support

Bundled and active:
- `Human_Heart.usdz`
- `Human_Brain.usdz`

Planned next:
- Lungs
- Liver
- Kidneys
- Stomach
- Skeleton
- Eye
- Ear
- Spine
- Intestines

If a model is not bundled yet, the app shows a polished placeholder state and availability messaging instead of a fake 3D anatomy render.

## MVP Goals

- stable immersive anatomy study flow
- clean state management
- anatomy structure focus mode
- guided quiz loop
- organ-by-organ progress tracking
- scalable content pipeline for additional organs

## Near-Term Roadmap

- add a licensed lungs model
- expand organ-specific label layouts
- deepen Brain quiz and label coverage
- improve structure highlighting and camera focus
- validate interaction comfort on real Vision Pro hardware

## Notes

This repository is currently app-first and product-oriented. The priority is shipping a clear, stable, immersive anatomy MVP before expanding into a full atlas library.
