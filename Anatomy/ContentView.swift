//
//  ContentView.swift
//  Anatomy
//
//  Created by Bobur Toshpulatov on 23/05/26.
//

import SwiftUI
import RealityKit
import RealityKitContent

private enum LauncherLayout {
    static let maxWidth: CGFloat = 1040
    static let contentSpacing: CGFloat = 28
    static let buttonWidth: CGFloat = 420
    static let buttonHeight: CGFloat = 68
    static let topPadding: CGFloat = 36
    static let bottomPadding: CGFloat = 36
    static let shellCornerRadius: CGFloat = 56
}

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    private let organs = AnatomyOrgan.launcherFeatured
    var body: some View {
        ZStack {
            switch appModel.immersiveSpaceState {
            case .open:
                Color.clear
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                VStack {
                    HStack {
                        Spacer()

                        StudySpaceActivePanel(
                            title: appModel.selectedOrgan.title,
                            modeTitle: appModel.selectedStudyMode.title,
                            onClose: closeImmersiveSpace
                        )
                    }

                    Spacer()
                }
                .padding(.top, 14)
                .padding(.trailing, 14)

            case .inTransition:
                LauncherBackdrop(tint: appModel.selectedOrgan.tint)
                    .allowsHitTesting(false)

                TransitionIndicator(
                    message: appModel.lastStatusMessage.isEmpty ? "Preparing study space…" : appModel.lastStatusMessage,
                    tint: appModel.selectedOrgan.tint
                )

            case .closed:
                VStack {
                    Spacer(minLength: 12)

                    LauncherShell {
                        VStack(spacing: LauncherLayout.contentSpacing) {
                            VStack(spacing: 10) {
                                // Premium eyebrow badge.
                                HStack(spacing: 7) {
                                    Image(systemName: "visionpro")
                                        .font(.caption.weight(.bold))
                                    Text("ROOM-SCALE STUDY")
                                        .font(.caption.weight(.bold))
                                        .tracking(1.6)
                                }
                                .foregroundStyle(.white.opacity(0.82))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule().fill(.ultraThinMaterial)
                                        .overlay(Capsule().fill(Color.white.opacity(0.06)))
                                )
                                .overlay(Capsule().strokeBorder(.white.opacity(0.16), lineWidth: 0.8))

                                Text("Immersive Anatomy")
                                    .font(.system(size: 44, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)

                                Text("Choose an organ, then open the room-scale study space.")
                                    .font(.title3.weight(.medium))
                                    .foregroundStyle(.white.opacity(0.74))
                            }
                            .multilineTextAlignment(.center)

                            HStack(spacing: 16) {
                                ForEach(organs) { organ in
                                    LauncherOrganCard(
                                        organ: organ,
                                        isSelected: organ.id == appModel.selectedOrganID
                                    )
                                    .onTapGesture {
                                        appModel.selectOrgan(organ.id)
                                    }
                                }
                            }

                            LauncherSelectionCard(organ: appModel.selectedOrgan)

                            Button(action: enterImmersiveSpace) {
                                HStack(spacing: 12) {
                                    Image(systemName: "visionpro")
                                        .font(.title3.weight(.bold))

                                    Text("Enter Study Space")
                                        .font(.title3.weight(.bold))
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(appModel.selectedOrgan.tint)
                            .foregroundStyle(.white)
                            .frame(width: LauncherLayout.buttonWidth, height: LauncherLayout.buttonHeight)
                            .contentShape(Rectangle())
                            .shadow(color: appModel.selectedOrgan.tint.opacity(0.34), radius: 18, y: 8)
                            .zIndex(999)
                        }
                        .frame(maxWidth: LauncherLayout.maxWidth, alignment: .center)
                        .padding(.horizontal, 18)
                        .padding(.top, LauncherLayout.topPadding)
                        .padding(.bottom, LauncherLayout.bottomPadding)
                    }
                    
                    Spacer(minLength: 12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
        }
    }

    private func enterImmersiveSpace() {
        appModel.immersiveSpaceState = .inTransition
        appModel.lastStatusMessage = "Opening study space..."

        Task {
            let result = await openImmersiveSpace(id: appModel.immersiveSpaceID)

            await MainActor.run {
                switch result {
                case .opened:
                    appModel.lastImmersiveOpenResult = .opened
                    appModel.immersiveSpaceState = .open
                    appModel.lastStatusMessage = "Study space active."
                case .userCancelled:
                    appModel.lastImmersiveOpenResult = .userCancelled
                    appModel.immersiveSpaceState = .closed
                    appModel.lastStatusMessage = "Opening was cancelled."
                case .error:
                    appModel.lastImmersiveOpenResult = .error
                    appModel.immersiveSpaceState = .closed
                    appModel.lastStatusMessage = "Unable to open the study space."
                @unknown default:
                    appModel.lastImmersiveOpenResult = .unknown
                    appModel.immersiveSpaceState = .closed
                    appModel.lastStatusMessage = "The study space is unavailable."
                }
            }
        }
    }

    private func closeImmersiveSpace() {
        appModel.immersiveSpaceState = .inTransition
        appModel.lastStatusMessage = "Closing study space..."

        Task {
            await dismissImmersiveSpace()
            await MainActor.run {
                appModel.lastImmersiveOpenResult = .idle
                appModel.immersiveSpaceState = .closed
                appModel.lastStatusMessage = "Ready to begin."
            }
        }
    }
}

private struct StudySpaceActivePanel: View {
    let title: String
    let modeTitle: String
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // Status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(.green.opacity(0.92))
                    .frame(width: 7, height: 7)
                    .shadow(color: .green.opacity(0.5), radius: 4)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Study Space")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.92))

                    Text("\(title) · \(modeTitle)")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.58))
                }
            }

            Divider()
                .frame(height: 22)
                .overlay(.white.opacity(0.14))

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.82))
                    .frame(width: 24, height: 24)
                    .background(.white.opacity(0.08), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.black.opacity(0.40), in: Capsule())
        .glassBackgroundEffect(in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.20), radius: 12, y: 6)
    }
}

private struct LauncherShell<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(.horizontal, 44)
            .padding(.vertical, 38)
            .premiumSurface(radius: LauncherLayout.shellCornerRadius)
    }
}

private struct LauncherOrganCard: View {
    let organ: AnatomyOrgan
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Model sits directly on the panel — no box behind it
            organPreview
                .frame(width: 176, height: 138)

            VStack(spacing: 4) {
                Text(organ.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)

                Text(organ.tagline)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white.opacity(0.66))
            }
        }
        .padding(18)
        // Identical fixed size; selection shown only by the shared surface's border.
        .frame(width: 232, height: 248)
        .premiumSurface(radius: DS.Radius.card, selected: isSelected, tint: organ.tint)
        .animation(.spring(response: 0.4, dampingFraction: 0.84), value: isSelected)
    }

    private var organPreview: some View {
        ZStack {
            // Soft tint bloom behind the artwork for a premium, lit feel.
            Circle()
                .fill(organ.tint.opacity(isSelected ? 0.32 : 0.12))
                .frame(width: 150, height: 150)
                .blur(radius: 40)

            Group {
                if UIImage(named: organ.carouselImageName) != nil {
                    Image(organ.carouselImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Model3D(named: organ.modelName, bundle: realityKitContentBundle) { phase in
                        switch phase {
                        case .success(let model): model.resizable().aspectRatio(contentMode: .fit)
                        case .failure:
                            Image(systemName: organ.symbolName)
                                .font(.system(size: 48, weight: .bold))
                                .foregroundStyle(.white.opacity(0.86))
                        default: ProgressView().tint(.white)
                        }
                    }
                }
            }
            .scaleEffect(isSelected ? 1.04 : 0.92)
            .saturation(isSelected ? 1.0 : 0.85)
            .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
            .padding(16)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.84), value: isSelected)
    }
}

private struct LauncherSelectionCard: View {
    let organ: AnatomyOrgan

    var body: some View {
        // Concise selected-organ summary — title + one-line description + study prompt.
        // No progress bar here (progress lives inside the study space); keeps the
        // launcher's hierarchy focused on: choose organ → enter.
        VStack(alignment: .leading, spacing: 8) {
            Text(organ.title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(organ.shortDescription)
                .font(.headline.weight(.medium))
                .foregroundStyle(.white.opacity(0.82))

            Text(organ.studyPrompt)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(organ.tint.opacity(0.96))
        }
        .frame(maxWidth: 760, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .allowsHitTesting(false)
    }
}

private struct TransitionIndicator: View {
    let message: String
    let tint: Color

    @State private var pulse: Bool = false

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.18))
                    .frame(width: 96, height: 96)
                    .blur(radius: 22)
                    .scaleEffect(pulse ? 1.18 : 0.92)

                Circle()
                    .stroke(tint.opacity(0.42), lineWidth: 2)
                    .frame(width: 64, height: 64)
                    .scaleEffect(pulse ? 1.04 : 0.96)

                Image(systemName: "visionpro")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
            }

            VStack(spacing: 4) {
                Text(message)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .multilineTextAlignment(.center)

                Text("This only takes a moment.")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white.opacity(0.58))
            }
        }
        .padding(.horizontal, 36)
        .padding(.vertical, 28)
        .background(.black.opacity(0.32), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.30), radius: 24, y: 12)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

private struct LauncherBackdrop: View {
    let tint: Color

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.03, blue: 0.07),
                    Color(red: 0.03, green: 0.05, blue: 0.09),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(tint.opacity(0.30))
                .frame(width: 560, height: 560)
                .blur(radius: 110)
                .offset(x: -160, y: -110)

            Circle()
                .fill(Color.cyan.opacity(0.12))
                .frame(width: 420, height: 420)
                .blur(radius: 120)
                .offset(x: 280, y: 160)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
