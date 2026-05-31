//
//  SpatialHeartLabels.swift
//  Anatomy
//
//  EXPERIMENT (branch: spatial-anchored-labels-experiment)
//
//  Dynamic 3D-anchored labels for the Heart. The heart is loaded as a RealityKit
//  ModelEntity so labels can be parented to it: when the model rotates, the labels
//  and connector lines rotate with it, while each label billboards to face the
//  viewer. Selection still happens through the labels / side panel — not by tapping
//  mesh geometry (the USDZ has no named anatomical sub-parts).
//
//  This path is gated by `SpatialLabelsConfig.heartEnabled`. If the model fails to
//  load, callers fall back to the existing static (SwiftUI attachment) label system.
//

import SwiftUI
import RealityKit
import RealityKitContent

enum SpatialLabelsConfig {
    /// Master switch for the experimental 3D-anchored heart labels.
    static let heartEnabled = true

    /// Name of the heart asset inside the RealityKitContent bundle (no extension).
    static let heartAssetName = "Human_Heart"

    /// Local-space anchor points for each heart structure, expressed in the
    /// NORMALISED model space (model is re-centred at the origin and scaled so its
    /// largest dimension == 1.0). Tune these against the real model in the simulator.
    ///
    /// Axes: +x = viewer-right, +y = up, +z = toward viewer (front of heart).
    static let heartAnchors: [String: SIMD3<Float>] = [
        "heart-aorta":            SIMD3<Float>( 0.04,  0.42, -0.02),
        "heart-pulmonary-artery": SIMD3<Float>(-0.14,  0.38,  0.06),
        "heart-left-atrium":      SIMD3<Float>( 0.20,  0.12, -0.06),
        "heart-left-ventricle":   SIMD3<Float>( 0.16, -0.30,  0.02),
        "heart-svc":              SIMD3<Float>( 0.22,  0.30,  0.04),
        "heart-right-atrium":     SIMD3<Float>(-0.22,  0.10,  0.06),
        "heart-tricuspid":        SIMD3<Float>(-0.10, -0.04,  0.12),
        "heart-right-ventricle":  SIMD3<Float>(-0.16, -0.30,  0.06)
    ]

    /// How far (in normalised units) the label sits out from its anchor point.
    static let labelOutwardOffset: Float = 0.42

    /// World-space display scale of the normalised heart (≈ how tall it floats).
    static let worldScale: Float = 0.13

    /// World position the heart floats at.
    static let worldPosition = SIMD3<Float>(0.0, 1.45, -1.6)
}

/// One heart structure that has a 3D anchor point.
private struct AnchoredNote: Identifiable {
    let id: String
    let index: Int
    let note: OrganAnnotation
    let anchor: SIMD3<Float>
}

/// Keeps a reference to the rotating root entity so the RealityView `update`
/// closure can apply rotation without depending on entity-graph lookups.
private final class HeartRootHolder {
    var root: Entity?
}

/// EXPERIMENT: heart rendered as a RealityKit `ModelEntity` with labels parented to
/// it. Rotating the heart rotates the labels + connector lines with it; each label
/// billboards to face the viewer. Drag horizontally to spin the model.
struct SpatialHeartLabelsView: View {
    let organ: AnatomyOrgan
    let selectedAnnotationID: String?
    let onSelect: (String) -> Void

    @State private var yaw: Double = 0
    @GestureState private var dragYaw: Double = 0
    @State private var holder = HeartRootHolder()

    private var anchoredNotes: [AnchoredNote] {
        organ.atlasNotes.enumerated().compactMap { index, note in
            guard let anchor = SpatialLabelsConfig.heartAnchors[note.id] else { return nil }
            return AnchoredNote(id: note.id, index: index, note: note, anchor: anchor)
        }
    }

    var body: some View {
        RealityView { content, attachments in
            let root = Entity()
            root.name = "spatial-heart-root"
            root.position = SpatialLabelsConfig.worldPosition
            content.add(root)
            holder.root = root

            // Load the heart and force it to an exact target size in metres.
            // The model is first added to a parent that is already in the scene, then
            // measured relative to that parent so the bounds are reliable; finally it is
            // scaled so its largest dimension == targetSize.
            let target = SpatialLabelsConfig.worldScale
            if let heart = try? await Entity(named: SpatialLabelsConfig.heartAssetName, in: realityKitContentBundle) {
                let modelHost = Entity()
                root.addChild(modelHost)
                modelHost.addChild(heart)

                let bounds = heart.visualBounds(relativeTo: modelHost)
                let maxDim = max(bounds.extents.x, bounds.extents.y, bounds.extents.z)
                let factor: Float = maxDim > 0.0001 ? (target / maxDim) : 0.01
                heart.scale = SIMD3<Float>(repeating: factor)
                heart.position = -bounds.center * factor
            }

            // Anchored labels + dots + connectors (all children of root → rotate with it).
            // Anchor positions are scaled by `target` so they sit on the target-sized
            // heart, while the label attachments stay unscaled so the text is readable.
            let s = target
            for item in anchoredNotes {
                let anchorPos = item.anchor * s

                let dot = ModelEntity(
                    mesh: .generateSphere(radius: 0.005),
                    materials: [UnlitMaterial(color: .white)]
                )
                dot.position = anchorPos
                root.addChild(dot)

                if let label = attachments.entity(for: "spatial-label-\(item.index)") {
                    label.components.set(BillboardComponent())
                    let outward = normalizedOutward(item.anchor)
                    let labelPos = anchorPos + outward * (SpatialLabelsConfig.labelOutwardOffset * s)
                    label.position = labelPos
                    root.addChild(label)

                    let line = Self.makeLine(from: anchorPos, to: labelPos, tint: organ.tint)
                    root.addChild(line)
                }
            }
        } update: { _, _ in
            holder.root?.orientation = simd_quatf(angle: Float(yaw + dragYaw), axis: [0, 1, 0])
        } attachments: {
            ForEach(anchoredNotes) { item in
                Attachment(id: "spatial-label-\(item.index)") {
                    SpatialLabelPill(
                        note: item.note,
                        tint: organ.tint,
                        isSelected: item.note.id == selectedAnnotationID
                    )
                    .onTapGesture { onSelect(item.note.id) }
                }
            }
        }
        .gesture(
            DragGesture()
                .updating($dragYaw) { value, state, _ in
                    state = Double(value.translation.width) * 0.012
                }
                .onEnded { value in
                    yaw += Double(value.translation.width) * 0.012
                }
        )
    }

    /// Outward direction (away from organ centre) used to push the label off the anchor.
    private func normalizedOutward(_ anchor: SIMD3<Float>) -> SIMD3<Float> {
        let raw = SIMD3<Float>(anchor.x, anchor.y * 0.5, max(anchor.z, 0.08))
        let len = simd_length(raw)
        return len > 0 ? raw / len : SIMD3<Float>(0, 0, 1)
    }

    /// A thin line entity connecting an anchor point to its label.
    static func makeLine(from: SIMD3<Float>, to: SIMD3<Float>, tint: Color) -> ModelEntity {
        let diff = to - from
        let length = max(simd_length(diff), 0.0001)
        let mesh = MeshResource.generateBox(size: SIMD3<Float>(0.0018, 0.0018, length))
        let entity = ModelEntity(
            mesh: mesh,
            materials: [UnlitMaterial(color: UIColor.white.withAlphaComponent(0.55))]
        )
        entity.position = (from + to) / 2

        let zAxis = SIMD3<Float>(0, 0, 1)
        let dir = diff / length
        let dot = simd_dot(zAxis, dir)
        if abs(dot) < 0.9999 {
            let axis = simd_normalize(simd_cross(zAxis, dir))
            entity.orientation = simd_quatf(angle: acos(dot), axis: axis)
        }
        return entity
    }
}

/// Compact billboarded label used by the spatial heart.
private struct SpatialLabelPill: View {
    let note: OrganAnnotation
    let tint: Color
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Circle()
                    .fill(isSelected ? tint : tint.opacity(0.85))
                    .frame(width: 8, height: 8)
                Text(note.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.black.opacity(0.55), in: Capsule())
            .overlay {
                Capsule().strokeBorder(isSelected ? tint.opacity(0.9) : .white.opacity(0.16), lineWidth: isSelected ? 1.6 : 1)
            }
            .glassBackgroundEffect(in: Capsule())

            Text(note.subtitle)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.66))
                .padding(.horizontal, 6)
        }
        .frame(width: 220, alignment: .leading)
    }
}

#Preview(immersionStyle: .mixed) {
    if let heart = AnatomyOrgan.featured.first(where: { $0.id == "heart" }) {
        SpatialHeartLabelsView(organ: heart, selectedAnnotationID: nil, onSelect: { _ in })
    }
}
