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
    static let maxWidth: CGFloat = 848
    static let contentSpacing: CGFloat = 14
    static let buttonWidth: CGFloat = 320
    static let buttonHeight: CGFloat = 58
    static let topPadding: CGFloat = 18
    static let bottomPadding: CGFloat = 18
    static let shellCornerRadius: CGFloat = 36
}

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    private let organs = AnatomyOrgan.launcherFeatured
    var body: some View {
        ZStack {
            if appModel.immersiveSpaceState == .open {
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
                .padding(.top, 18)
                .padding(.trailing, 18)
            } else {
                LauncherBackdrop(tint: appModel.selectedOrgan.tint)
                    .allowsHitTesting(false)

                VStack {
                    Spacer(minLength: 12)

                    LauncherShell {
                        VStack(spacing: LauncherLayout.contentSpacing) {
                            VStack(spacing: 6) {
                                Text("Immersive Anatomy")
                                    .font(.system(size: 30, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)

                                Text("Choose an organ, then open the room-scale study space.")
                                    .font(.title3.weight(.medium))
                                    .foregroundStyle(.white.opacity(0.76))
                            }
                            .multilineTextAlignment(.center)

                            HStack(spacing: 14) {
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
                                        .font(.headline.weight(.bold))

                                    Text("Enter Study Space")
                                        .font(.headline.weight(.bold))
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(appModel.selectedOrgan.tint)
                            .foregroundStyle(.white)
                            .frame(width: LauncherLayout.buttonWidth, height: LauncherLayout.buttonHeight)
                            .contentShape(Rectangle())
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "visionpro.circle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.78))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Study Space Active")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white.opacity(0.88))

                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.60))
                }
            }

            Text(modeTitle + " mode")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.50))

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.08))
            .foregroundStyle(.white.opacity(0.78))
        }
        .frame(width: 146, alignment: .leading)
        .padding(8)
        .background(.black.opacity(0.34), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.14), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
        .opacity(0.82)
        .offset(x: 86, y: -56)
    }
}

private struct LauncherShell<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(.horizontal, 24)
            .padding(.vertical, 18)
            .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: LauncherLayout.shellCornerRadius, style: .continuous))
            .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: LauncherLayout.shellCornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: LauncherLayout.shellCornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.10), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.22), radius: 32, y: 18)
    }
}

private struct LauncherOrganCard: View {
    let organ: AnatomyOrgan
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                organ.tint.opacity(isSelected ? 0.42 : 0.14),
                                .white.opacity(isSelected ? 0.12 : 0.05),
                                .black.opacity(0.20)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                organPreview
            }
            .frame(width: isSelected ? 192 : 176, height: isSelected ? 132 : 120)
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(.white.opacity(isSelected ? 0.18 : 0.08), lineWidth: 1)
            }
            .shadow(color: organ.tint.opacity(isSelected ? 0.24 : 0.10), radius: isSelected ? 24 : 14, y: 10)

            VStack(spacing: 4) {
                Text(organ.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)

                Text(organ.tagline)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.66))
            }
        }
        .padding(12)
        .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(.white.opacity(isSelected ? 0.12 : 0.06), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .scaleEffect(isSelected ? 1 : 0.94)
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
                    .scaleEffect(isSelected ? 1.16 : 0.92)
                    .padding(20)
            case .failure:
                Image(systemName: organ.symbolName)
                    .font(.system(size: 40, weight: .bold))
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
