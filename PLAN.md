# ARTE Anatomy — Master Redesign Plan

Transform ARTE from a 3D viewer into a premium **educational** anatomy experience for
Apple Vision Pro. Scope is frozen to **Heart and Brain** with modes **Explore, Labels,
Learn, Quiz** plus **Progress**. The organ is a learning medium; the education is the product.

## Hard limits
- I cannot download or generate image files. Educational art uses an **AssetSlot /
  AnatomyImage** placeholder system; real PNGs are dropped into `Assets.xcassets` later
  with no UI change.
- Photo-real organ shading depends on the bundled USDZ.

## Architecture
- `DesignSystem.swift` — tokens (radii/spacing/surfaces) + `premiumSurface()`.
- `AnatomyAssets.swift` — `AssetSlot` + `AnatomyImage` (asset-or-placeholder).
- `EducationalContent.swift` — `OrganLesson` (Overview / Anatomy / Functionality /
  Real-World / Summary) for heart & brain.
- `AppModel.StudyMode` — `explore · labels · learn · quiz`.

## Modes
- **Explore** — organ is hero, no rotation, calm.
- **Labels** — reference only: small, clean, secondary.
- **Learn** — centerpiece: textbook reader (sectioned), organ de-emphasized.
- **Quiz** — engaging: identify / multiple-choice / match / scenario, progression, feedback.

## Phases (each build-verified & committed)
1. **Foundation** ✅ — remove rotation; add Learn mode; AssetSlot/AnatomyImage; EducationalContent scaffold; Phase-1 Learn reader.
2. **Learn Mode** — full reader UI, dim organ, complete written content + image slots.
3. **Quiz redesign** — QuizEngine, 4 question types, visual feedback, progression.
4. **Labels + Explore refinement** — simplify labels; curated Explore views.
5. **Launcher / panel / carousel polish** — final premium pass.
6. **Art integration** — drop in NIH/OpenStax/Wikimedia PNGs (user-provided).

## Interaction rules
No overlapping interactions, no blocked buttons, dedicated spatial zones
(top = modes, center = organ [non-interactive], right = panel, bottom = carousel, corner = status).
