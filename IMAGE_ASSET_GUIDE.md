# ARTE Anatomy — Image Asset Guide (Phase 6)

This app uses an **asset-slot system**. Each lesson/quiz illustration is referenced by a
named slot. `AnatomyImage(slot:)` shows the real image if it exists in the asset catalog,
otherwise a branded placeholder — so the UI never breaks.

## How to add an image
1. Open `Anatomy/Assets.xcassets` in Xcode → group **`Lessons`**.
2. Find the imageset matching the **exact asset name** below (e.g. `heart_chambers`).
3. Drag your PNG into the **Universal** well of that imageset (or drag the PNG onto the
   imageset and let Xcode assign it).
4. Build & run — the image appears automatically wherever that slot is used.

> The `Lessons` group has **namespace disabled**, so the code references the bare name
> (`heart_chambers`), not `Lessons/heart_chambers`. Do not rename the imagesets.

## Recommended specs
- **Format:** PNG (transparent background preferred; otherwise a dark/neutral background).
- **Resolution:** high — **≥ 1600 px on the long edge** (these float in spatial UI).
- **Aspect:** roughly landscape (~4:3 or 16:9); slots render at ~150pt tall, full width.
- **Style:** clean **medical illustration** — consistent palette, labeled where useful,
  reads well on a dark panel. Keep a unified look across all images.
- **Weight:** optimize PNGs; avoid huge files where possible.

## License — only safe sources
Use **public-domain or openly-licensed** art. Verify each file individually.
- **NIH / NCI / NLM** — many images are U.S. public domain (still verify).
- **OpenStax Anatomy & Physiology** — CC-BY 4.0 (**attribution required**).
- **Wikimedia Commons** — check the **specific file's** license (CC0 / CC-BY / PD).
- **Servier Medical Art** — CC-BY 3.0/4.0 (**attribution required**).
- **BodyParts3D / NIH 3D** — check terms.

❌ Do **not** use all-rights-reserved, stock-watermarked, or unclear-license images.
Keep an attribution list for any CC-BY assets (see bottom).

---

## Required images — checklist

| ✓ | Asset name (exact) | Organ | Section | Expected content |
|---|---|---|---|---|
| ☐ | `heart_chambers`    | Heart | Anatomy        | Cross-section showing the **four chambers** (right/left atria & ventricles), labeled. |
| ☐ | `heart_valves`      | Heart | Anatomy        | The **four valves** (tricuspid, pulmonary, mitral, aortic). |
| ☐ | `heart_vessels`     | Heart | Anatomy / Quiz | **Great vessels** — aorta, superior/inferior vena cava, pulmonary artery & veins. |
| ☐ | `heart_circulation` | Heart | Functionality  | **Pulmonary + systemic circulation** loop diagram (oxygenated vs deoxygenated). |
| ☐ | `heart_conduction`  | Heart | Functionality  | **Electrical conduction system** — SA node, AV node, bundle branches. |
| ☐ | `heart_attack`      | Heart | Real-World     | **Coronary artery blockage** / myocardial infarction illustration. |
| ☐ | `brain_lobes`       | Brain | Anatomy / Quiz | **Four cerebral lobes** (frontal, parietal, temporal, occipital), colour-coded. |
| ☐ | `brain_cerebellum`  | Brain | Anatomy        | **Cerebellum** highlighted at the back/base of the brain. |
| ☐ | `brain_brainstem`   | Brain | Anatomy        | **Brainstem** — midbrain, pons, medulla. |
| ☐ | `brain_memory`      | Brain | Functionality  | **Hippocampus / memory pathways** within the temporal lobe. |
| ☐ | `brain_sleep`       | Brain | Real-World     | **Sleep & memory consolidation** concept illustration. |

**11 images total** (6 heart, 5 brain). `heart_vessels` and `brain_lobes` are reused by the
quiz's identify-structure questions.

---

## Where each slot is used (code references)
- Lesson content: `Anatomy/EducationalContent.swift` (Anatomy / Functionality / Real-World sections).
- Quiz illustrations: `Anatomy/AnatomyOrgan.swift` (`heart_vessels`, `brain_lobes`).
- Renderer: `Anatomy/AnatomyAssets.swift` (`AnatomyImage` — asset-or-placeholder).

## Attribution log (fill in for any CC-BY assets)
| Asset | Source URL | License | Author / credit |
|---|---|---|---|
| | | | |
