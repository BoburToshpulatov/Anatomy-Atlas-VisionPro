//
//  OrganRealityView.swift
//  Anatomy
//
//  Created by Bobur Toshpulatov on 24/05/26.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct OrganRealityView: View {
    let organ: AnatomyOrgan
    let viewerLayout: AnatomyOrgan.ViewerLayout
    let selectedAnnotationID: String?
    let showAnnotations: Bool
    let isHeroVisible: Bool
    let onSelectAnnotation: (String) -> Void

    private var selectedAnnotation: OrganAnnotation? {
        guard let selectedAnnotationID else { return nil }
        return organ.atlasNotes.first(where: { $0.id == selectedAnnotationID })
    }

    private var bundledModelScaleMultiplier: CGFloat {
        switch organ.id {
        case "heart":
            0.72
        case "brain":
            0.52
        default:
            0.60
        }
    }

    private var bundledFrameScale: CGSize {
        switch organ.id {
        case "heart":
            CGSize(width: 0.72, height: 0.82)
        case "brain":
            CGSize(width: 0.62, height: 0.70)
        default:
            CGSize(width: 0.60, height: 0.74)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                // In Labels mode the model holds still (only a gentle float) so the
                // callout lines stay aligned with the anatomy.
                let motionRate = organ.pulseStyle == .heartbeat ? 0.55 : 0.40
                let sway = showAnnotations ? 0 : sin(time * motionRate) * (organ.pulseStyle == .heartbeat ? 8 : 5)
                // Rotation removed — the organ is a curated educational subject, not a
                // free-spin toy. A gentle sway/float only.
                let autoSpin: Double = 0
                let lift = sin(time * (organ.pulseStyle == .heartbeat ? 0.95 : 0.70)) * (showAnnotations ? 3 : (organ.pulseStyle == .heartbeat ? 10 : 7))
                let organPulse: CGFloat = {
                    if showAnnotations { return 1.0 }
                    switch organ.pulseStyle {
                    case .heartbeat:
                        return sin(time * 2.2) * 0.018 + 1.0
                    case .neural:
                        return sin(time * 1.35) * 0.010 + 1.0
                    }
                }()
                let shimmer = 0.76 + (sin(time * 0.8) * 0.08)
                // Selecting a label gently ROTATES the organ toward that structure only —
                // it does NOT zoom in, scale up, or shift off-centre. Damp the rotation so
                // the turn is calm and the organ stays balanced on its pedestal.
                // Organ stays calmly in place when a label is selected (the labels are a
                // fixed reference layer); only the chosen label highlights.
                let focusYaw = organ.baseYaw + viewerLayout.heroYawOffset
                let focusPitch = organ.basePitch + viewerLayout.heroPitchOffset
                let focusScale: CGFloat = 1                       // no zoom on focus
                let focusOffset = viewerLayout.heroVisualOffset   // no positional shift on focus
                // Selecting a label no longer pumps up a big coloured bloom on the model —
                // the highlight lives on the label itself, the organ glow stays calm.
                let highlightBloom = false

                ZStack {
                    Ellipse()
                        .fill(.black.opacity(0.28))
                        .frame(width: geometry.size.width * 0.22, height: geometry.size.height * 0.05)
                        .blur(radius: 18)
                        .offset(y: geometry.size.height * 0.22)

                    Ellipse()
                        .fill(organ.tint.opacity(0.16))
                        .frame(
                            width: geometry.size.width * (0.26 * organ.glowScale),
                            height: geometry.size.width * (0.20 * organ.glowScale)
                        )
                        .blur(radius: 28)
                        .offset(x: geometry.size.width * 0.04, y: geometry.size.height * 0.04)

                    Ellipse()
                        .stroke(organ.tint.opacity(0.22 * shimmer), lineWidth: 2)
                        .frame(
                            width: geometry.size.width * (0.28 * organ.glowScale),
                            height: geometry.size.width * (0.22 * organ.glowScale)
                        )
                        .blur(radius: 8)
                        .offset(x: geometry.size.width * 0.02, y: geometry.size.height * 0.02)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    organ.tint.opacity(0.10),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 24,
                                endRadius: geometry.size.width * 0.22
                            )
                        )
                        .frame(width: geometry.size.width * 0.42, height: geometry.size.width * 0.42)
                        .blur(radius: highlightBloom ? 34 : 24)
                        .opacity(isHeroVisible ? 1 : 0)
                        .blendMode(.screen)

                    if highlightBloom {
                        Circle()
                            .stroke(organ.tint.opacity(0.26), lineWidth: 4)
                            .frame(width: geometry.size.width * 0.30, height: geometry.size.width * 0.30)
                            .blur(radius: 16)
                            .opacity(isHeroVisible ? 1 : 0)
                    }

                    if organ.pulseStyle == .neural {
                        Ellipse()
                            .stroke(organ.tint.opacity(0.16 + (sin(time * 1.35) * 0.05)), style: StrokeStyle(lineWidth: 1.5, dash: [4, 8]))
                            .frame(
                                width: geometry.size.width * (0.34 * organ.glowScale),
                                height: geometry.size.width * (0.24 * organ.glowScale)
                            )
                            .blur(radius: 1.5)
                    }

                    if organ.hasBundledModel {
                        Model3D(named: organ.modelName, bundle: realityKitContentBundle) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(1.6)
                            case .success(let resolvedModel):
                                resolvedModel
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .scaleEffect((organ.heroScale * bundledModelScaleMultiplier) * focusScale * organPulse * (isHeroVisible ? 1 : 0.82))
                                    .rotation3DEffect(.degrees(focusPitch), axis: (x: 1, y: 0, z: 0))
                                    .rotation3DEffect(.degrees(sway + focusYaw + autoSpin), axis: (x: 0, y: 1, z: 0))
                                    .offset(
                                        x: organ.heroOffset.width + focusOffset.width,
                                        y: organ.heroOffset.height + focusOffset.height + lift + (isHeroVisible ? 0 : 20)
                                    )
                                    .opacity(isHeroVisible ? 1 : 0)
                                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
                                    .shadow(color: .black.opacity(0.45), radius: 44, y: 18)
                                    .overlay {
                                        Circle()
                                            .fill(
                                                RadialGradient(
                                                    colors: [
                                                        .white.opacity(0.08),
                                                        organ.tint.opacity(0.10),
                                                        .clear
                                                    ],
                                                    center: .topTrailing,
                                                    startRadius: 10,
                                                    endRadius: geometry.size.width * 0.24
                                                )
                                            )
                                            .blur(radius: highlightBloom ? 28 : 20)
                                            .blendMode(.screen)
                                    }
                                    .animation(.spring(response: 0.52, dampingFraction: 0.84), value: selectedAnnotationID)
                                    .animation(.spring(response: 0.82, dampingFraction: 0.86), value: isHeroVisible)
                            case .failure:
                                organPlaceholder(in: geometry, organPulse: organPulse, sway: sway, lift: lift, focusYaw: focusYaw, focusPitch: focusPitch, focusScale: focusScale, focusOffset: focusOffset)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: geometry.size.width * bundledFrameScale.width, height: geometry.size.height * bundledFrameScale.height)
                    } else {
                        organPlaceholder(in: geometry, organPulse: organPulse, sway: sway, lift: lift, focusYaw: focusYaw, focusPitch: focusPitch, focusScale: focusScale, focusOffset: focusOffset)
                            .frame(width: geometry.size.width * 0.36, height: geometry.size.height * 0.28)
                    }

                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(.clear)
    }

    private func organPlaceholder(
        in geometry: GeometryProxy,
        organPulse: CGFloat,
        sway: Double,
        lift: Double,
        focusYaw: Double,
        focusPitch: Double,
        focusScale: CGFloat,
        focusOffset: CGSize
    ) -> some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            organ.tint.opacity(0.30),
                            organ.tint.opacity(0.12),
                            .clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: geometry.size.width * 0.16
                    )
                )
                .blur(radius: 18)

            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.black.opacity(0.42))
                .frame(width: geometry.size.width * 0.28, height: geometry.size.width * 0.16)
                .overlay {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .strokeBorder(organ.tint.opacity(0.24), lineWidth: 1)
                }
                .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 32, style: .continuous))

            Image(systemName: organ.symbolName)
                .font(.system(size: geometry.size.width * 0.05, weight: .medium))
                .foregroundStyle(.white.opacity(0.94))

            VStack(spacing: 6) {
                Text(organ.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Text("Model coming soon")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(organ.tint.opacity(0.92))
            }
        }
        .scaleEffect((organ.heroScale * 0.76) * focusScale * organPulse * (isHeroVisible ? 1 : 0.82))
        .rotation3DEffect(.degrees(focusPitch), axis: (x: 1, y: 0, z: 0))
        .rotation3DEffect(.degrees(sway + focusYaw), axis: (x: 0, y: 1, z: 0))
        .offset(
            x: organ.heroOffset.width + focusOffset.width,
            y: organ.heroOffset.height + focusOffset.height + lift + (isHeroVisible ? 0 : 20)
        )
        .opacity(isHeroVisible ? 1 : 0)
        .shadow(color: organ.tint.opacity(0.30), radius: 40, y: 18)
        .animation(.spring(response: 0.52, dampingFraction: 0.84), value: selectedAnnotationID)
        .animation(.spring(response: 0.82, dampingFraction: 0.86), value: isHeroVisible)
    }
}

struct AnnotationConnector: View {
    let anchor: CGPoint
    let laneEnd: CGPoint
    let isSelected: Bool
    let isDimmed: Bool
    let tint: Color
    let time: TimeInterval
    let revealAmount: CGFloat

    var body: some View {
        let pulse = isSelected ? (0.84 + (sin(time * 3.4) * 0.16)) : 1.0

        Path { path in
            path.move(to: anchor)
            path.addQuadCurve(
                to: laneEnd,
                control: CGPoint(
                    x: (anchor.x + laneEnd.x) * 0.5,
                    y: min(anchor.y, laneEnd.y) - 40
                )
            )
        }
        .trim(from: 0, to: revealAmount)
        .stroke(
            LinearGradient(
                colors: isSelected
                    ? [tint.opacity(0.95), .white.opacity(0.92)]
                    : isDimmed
                        ? [.white.opacity(0.16), .white.opacity(0.06)]
                        : [.white.opacity(0.38), .white.opacity(0.12)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: (isSelected ? 1.45 : 0.85) * pulse, lineCap: .round, lineJoin: .round)
        )
        .shadow(color: isSelected ? tint.opacity(0.18 * pulse) : .clear, radius: 8)
        .overlay {
            Circle()
                .fill(isSelected ? tint : isDimmed ? .white.opacity(0.34) : .white.opacity(0.82))
                .frame(
                    width: (isSelected ? 7 : 5) * pulse,
                    height: (isSelected ? 7 : 5) * pulse
                )
                .position(anchor)
                .shadow(color: isSelected ? tint.opacity(0.20) : .clear, radius: 6)
        }
    }
}

struct AnnotationBubble: View {
    let note: OrganAnnotation
    let isSelected: Bool
    let isDimmed: Bool
    let tint: Color

    private var alignment: HorizontalAlignment { note.side == .left ? .leading : .trailing }
    private var frameAlignment: Alignment { note.side == .left ? .leading : .trailing }

    var body: some View {
        VStack(alignment: alignment, spacing: 5) {
            // Title pill — coloured dot + structure name
            HStack(spacing: 8) {
                Circle()
                    .fill(isSelected ? tint : tint.opacity(0.8))
                    .frame(width: isSelected ? 9 : 7, height: isSelected ? 9 : 7)
                    .shadow(color: isSelected ? tint : .clear, radius: isSelected ? 5 : 0)

                Text(note.title)
                    .font(.headline.weight(isSelected ? .bold : .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .padding(.horizontal, isSelected ? 17 : 15)
            .padding(.vertical, isSelected ? 11 : 9)
            // Premium dark highlight — the selected pill goes deeper/darker, never a bright colour fill.
            .background(
                Capsule().fill(
                    isSelected
                        ? AnyShapeStyle(Color.black.opacity(0.82))
                        : AnyShapeStyle(Color.black.opacity(0.5))
                )
            )
            .overlay {
                Capsule()
                    .strokeBorder(isSelected ? .white.opacity(0.85) : Color.white.opacity(0.18),
                                  lineWidth: isSelected ? 1.6 : 1.0)
            }
            // Soft neutral glow only — a quiet premium ring, no coloured (blue/red) bloom.
            .background(
                Capsule()
                    .strokeBorder(.white, lineWidth: 3)
                    .blur(radius: 8)
                    .opacity(isSelected ? 0.4 : 0)
                    .scaleEffect(1.08)
            )
            .shadow(color: .black.opacity(isSelected ? 0.4 : 0.22), radius: isSelected ? 14 : 8, y: 4)

            // Short description below the pill (textbook-callout style, always shown).
            Text(note.subtitle)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(isSelected ? 0.95 : 0.7))
                .lineLimit(2)
                .multilineTextAlignment(note.side == .left ? .leading : .trailing)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 6)
        }
        .frame(maxWidth: .infinity, alignment: frameAlignment)
        .padding(isSelected ? 6 : 0)   // breathing room so the scaled/glowing pill is never clipped
        // Scale from the inner edge so the text never overflows the frame edge.
        .scaleEffect(isSelected ? 1.06 : 1.0, anchor: note.side == .left ? .leading : .trailing)
        // Other labels stay fully visible — no dimming when one is tapped.
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
        .animation(.easeInOut(duration: 0.3), value: isDimmed)
    }
}
