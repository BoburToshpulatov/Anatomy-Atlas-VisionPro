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

    @State private var loadError: String?

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
                // Slow continuous turntable spin in Explore mode (paused while labels are
                // shown or a structure is focused, so callouts stay aligned).
                let autoSpin: Double = (showAnnotations || selectedAnnotation != nil) ? 0 : time * 12.0
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
                let focusYaw = (selectedAnnotation?.focusYaw ?? organ.baseYaw) + viewerLayout.heroYawOffset
                let focusPitch = (selectedAnnotation?.focusPitch ?? organ.basePitch) + viewerLayout.heroPitchOffset
                let focusScale = selectedAnnotation?.focusScale ?? 1
                let selectedFocusOffset = selectedAnnotation?.focusOffset ?? .zero
                let focusOffset = CGSize(
                    width: selectedFocusOffset.width + viewerLayout.heroVisualOffset.width,
                    height: selectedFocusOffset.height + viewerLayout.heroVisualOffset.height
                )
                let highlightBloom = selectedAnnotation != nil

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
                                    organ.tint.opacity(highlightBloom ? 0.22 : 0.12),
                                    Color.cyan.opacity(highlightBloom ? 0.16 : 0.08),
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
                                    .shadow(color: organ.tint.opacity(0.40), radius: 54, y: 18)
                                    .overlay {
                                        Circle()
                                            .fill(
                                                RadialGradient(
                                                    colors: [
                                                        .white.opacity(highlightBloom ? 0.16 : 0.10),
                                                        organ.tint.opacity(highlightBloom ? 0.22 : 0.14),
                                                        Color.cyan.opacity(highlightBloom ? 0.10 : 0.04),
                                                        .clear
                                                    ],
                                                    center: .topTrailing,
                                                    startRadius: 10,
                                                    endRadius: geometry.size.width * (highlightBloom ? 0.29 : 0.24)
                                                )
                                            )
                                            .blur(radius: highlightBloom ? 28 : 20)
                                            .blendMode(.screen)
                                    }
                                    .onAppear { loadError = nil }
                                    .animation(.spring(response: 0.52, dampingFraction: 0.84), value: selectedAnnotationID)
                                    .animation(.spring(response: 0.82, dampingFraction: 0.86), value: isHeroVisible)
                            case .failure(let error):
                                organPlaceholder(in: geometry, organPulse: organPulse, sway: sway, lift: lift, focusYaw: focusYaw, focusPitch: focusPitch, focusScale: focusScale, focusOffset: focusOffset)
                                    .onAppear {
                                        loadError = "Failed to load \(organ.modelName)\n\(String(describing: error))"
                                    }
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
        .overlay(alignment: .bottomLeading) {
            if let loadError {
                Text(loadError)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.86), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(18)
            }
        }
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
        VStack(alignment: alignment, spacing: 7) {
            // Title pill — coloured dot + structure name
            HStack(spacing: 9) {
                Circle()
                    .fill(isSelected ? tint : tint.opacity(isDimmed ? 0.4 : 0.85))
                    .frame(width: 9, height: 9)

                Text(note.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(isDimmed ? 0.56 : 0.98))
                    .lineLimit(1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(
                Capsule()
                    .fill(Color.black.opacity(isSelected ? 0.60 : isDimmed ? 0.40 : 0.52))
            )
            .overlay {
                Capsule()
                    .strokeBorder(
                        isSelected ? tint.opacity(0.85) : isDimmed ? Color.white.opacity(0.05) : Color.white.opacity(0.14),
                        lineWidth: isSelected ? 1.6 : 1.0
                    )
            }
            .glassBackgroundEffect(in: Capsule())
            .shadow(color: isSelected ? tint.opacity(0.28) : .black.opacity(0.18), radius: 10, y: 5)

            // Description hanging below the pill (outside, like a medical callout)
            Text(note.subtitle)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(isDimmed ? 0.34 : 0.66))
                .lineLimit(2)
                .multilineTextAlignment(note.side == .left ? .leading : .trailing)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 6)
        }
        .frame(maxWidth: .infinity, alignment: frameAlignment)
        .scaleEffect(isSelected ? 1.04 : isDimmed ? 0.97 : 1)
    }
}
