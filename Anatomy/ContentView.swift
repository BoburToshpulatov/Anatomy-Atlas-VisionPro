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
    static let maxWidth: CGFloat = 1060
    static let contentSpacing: CGFloat = 30
    static let buttonWidth: CGFloat = 460
    static let buttonHeight: CGFloat = 70
    static let topPadding: CGFloat = 38
    static let bottomPadding: CGFloat = 38
    static let shellCornerRadius: CGFloat = 40
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
                LauncherBackdrop(tint: appModel.selectedOrgan.tint)
                    .allowsHitTesting(false)

                VStack {
                    Spacer(minLength: 12)

                    LauncherShell {
                        VStack(spacing: LauncherLayout.contentSpacing) {
                            VStack(spacing: 10) {
                                Text("Immersive Anatomy")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)

                                Text("Choose an organ, then open the room-scale study space.")
                                    .font(.title2.weight(.medium))
                                    .foregroundStyle(.white.opacity(0.72))
                            }
                            .multilineTextAlignment(.center)

                            HStack(spacing: 28) {
                                ForEach(organs) { organ in
                                    LauncherOrganCard(
                                        organ: organ,
                                        isSelected: organ.id == appModel.selectedOrganID
                                    )
                                    .frame(maxWidth: .infinity)
                                    .onTapGesture {
                                        appModel.selectOrgan(organ.id)
                                    }
                                }
                            }

                            LauncherSelectionCard(organ: appModel.selectedOrgan)

                            Button(action: enterImmersiveSpace) {
                                HStack(spacing: 12) {
                                    Image(systemName: "visionpro")
                                        .font(.title2.weight(.bold))

                                    Text("Enter Study Space")
                                        .font(.title2.weight(.bold))
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
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [
                        .black.opacity(0.74),
                        .black.opacity(0.62)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            // Black fill is clipped to the exact same shape used for the glass + border,
            // so the dark surface is the same size/radius as the glass.
            .clipShape(RoundedRectangle(cornerRadius: LauncherLayout.shellCornerRadius, style: .continuous))
            .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: LauncherLayout.shellCornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: LauncherLayout.shellCornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.30), radius: 32, y: 18)
    }
}

private struct LauncherOrganCard: View {
    let organ: AnatomyOrgan
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 18) {
            // Large model stage inside the card
            organPreview
                .frame(height: 248)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    organ.tint.opacity(isSelected ? 0.32 : 0.08),
                                    .white.opacity(isSelected ? 0.05 : 0.015),
                                    .black.opacity(0.28)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(.white.opacity(0.07), lineWidth: 1)
                }

            VStack(spacing: 5) {
                Text(organ.title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(organ.tagline)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(isSelected ? organ.tint.opacity(0.95) : .white.opacity(0.62))
            }
        }
        .padding(26)
        .frame(maxWidth: .infinity)
        .background(.black.opacity(isSelected ? 0.26 : 0.18), in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        // Outer selection highlight
        .overlay {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .strokeBorder(
                    isSelected ? organ.tint.opacity(0.95) : .white.opacity(0.10),
                    lineWidth: isSelected ? 3 : 1
                )
                .allowsHitTesting(false)
        }
        .shadow(color: isSelected ? organ.tint.opacity(0.40) : .black.opacity(0.20), radius: isSelected ? 34 : 14, y: 12)
        .scaleEffect(isSelected ? 1.0 : 0.95)
        .animation(.spring(response: 0.4, dampingFraction: 0.84), value: isSelected)
    }

    private var organPreview: some View {
        Model3D(named: organ.modelName, bundle: realityKitContentBundle) { phase in
            switch phase {
            case .empty:
                ProgressView().tint(.white)
            case .success(let model):
                model
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(isSelected ? 1.08 : 0.94)
                    .padding(20)
            case .failure:
                Image(systemName: organ.symbolName)
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(.white.opacity(0.86))
            @unknown default:
                EmptyView()
            }
        }
    }
}

private struct LauncherSelectionCard: View {
    let organ: AnatomyOrgan
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text(organ.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Text(appModel.progressFraction(for: organ) >= 0.999 ? "Completed" : appModel.selectedOrganID == organ.id ? appModel.selectedOrganProgressText : "\(Int((appModel.progressFraction(for: organ) * 100).rounded()))%")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(organ.tint.opacity(0.96))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(.white.opacity(0.06), in: Capsule())
            }

            Text(organ.shortDescription)
                .font(.headline.weight(.medium))
                .foregroundStyle(.white.opacity(0.84))

            Text(organ.studyPrompt)
                .font(.body.weight(.medium))
                .foregroundStyle(organ.tint.opacity(0.96))

            ProgressView(value: appModel.progressFraction(for: organ))
                .tint(organ.tint)
        }
        .frame(maxWidth: 760, alignment: .leading)
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .background(.black.opacity(0.24), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
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
