# Anatomy Atlas Vision Pro

Spatial anatomy learning app for Apple Vision Pro, built with `SwiftUI` and `RealityKit`.

This project is evolving toward a premium room-scale anatomy atlas where learners can:
- explore organs in immersive space
- study labeled anatomy structures
- answer guided quiz prompts
- track progress across organs and study modes

The MVP scope is **Heart and Brain only**, presented as a premium educational experience:
an immersive study scene, a textbook-style Learn mode, a clean Labels reference layer,
an engaging Quiz, a right-side study panel, carousel-based organ switching, and persistent progress.

## Status

Current phase: `Premium educational MVP`

Implemented:
- visionOS launcher window for entering the study space
- `ImmersiveSpace` study scene (no manual rotation — curated presentation)
- study modes: `Explore`, `Labels`, `Learn`, `Quiz`
- **Learn mode**: sectioned textbook reader (Overview / Anatomy / Functionality / Real-World / Summary)
- **Quiz**: typed questions (multiple choice, identify structure, match function, scenario) with feedback
- design system (`DesignSystem.swift`) for consistent surfaces, radii, and spacing
- educational content model (`EducationalContent.swift`) for Heart & Brain
- asset-slot image system (`AnatomyAssets.swift`) with premium placeholders — see `IMAGE_ASSET_GUIDE.md`
- organ carousel switching, annotation focus, persistent progress in `AppModel`
- real spatial model support for **Heart** and **Brain**

Scope is intentionally limited to Heart and Brain; the roadmap (`PLAN.md`) tracks the redesign phases.

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

## Organ Model Support

Bundled and active (MVP scope):
- `Human_Heart.usdz`
- `Human_Brain.usdz`

## MVP Goals

- stable immersive anatomy study flow across Explore / Labels / Learn / Quiz
- premium, consistent educational presentation
- textbook-quality Learn mode
- engaging quiz with feedback
- organ-by-organ progress tracking
- drop-in educational illustrations via the asset-slot system

## Near-Term Roadmap

- add safe, openly-licensed anatomy illustrations (see `IMAGE_ASSET_GUIDE.md`)
- validate interaction comfort on real Vision Pro hardware
- deepen Heart and Brain lesson and quiz content

## Notes

The priority is a clear, stable, premium educational MVP for Heart and Brain.
See `PLAN.md` for the redesign roadmap and `IMAGE_ASSET_GUIDE.md` for adding artwork.
