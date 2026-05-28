//
//  ImmersiveView.swift
//  Anatomy
//
//  Created by Bobur Toshpulatov on 23/05/26.
//

import SwiftUI
import RealityKit
import RealityKitContent

private enum ImmersiveLayoutConfig {
    static let topBarPosition = SIMD3<Float>(0.0, 1.94, -1.66)
    static let topBarWidth: CGFloat = 360
    static let auraSize: CGFloat = 1120
    static let heroFrame = CGSize(width: 1440, height: 1100)
    static let panelHeight: CGFloat = 900
    static let instructionOpacityWhenHidden = 0.001
    static let carouselStackWidth: CGFloat = 1460
    static let carouselFrameHeight: CGFloat = 224
    static let bottomBarWidth: CGFloat = 292
    static let bottomStackSpacing: CGFloat = 8
    static let labelVerticalSpread: Float = 0.70
    static let labelSelectedLift: Float = 0.04
    static let labelIdleLift: Float = 0.008
    static let labelDimmedLift: Float = -0.012
    static let labelDepthTilt: Float = 0.042
    static let glowYOffset: Float = -0.33
    static let glowZOffset: Float = 0.02
    static let organAnchorSpreadX: Float = 0.56
    static let organAnchorSpreadY: Float = 0.62
    static let connectorDepthOffset: Float = -0.02
}

struct ImmersiveView: View {
    @Environment(AppModel.self) private var appModel

    @State private var backgroundGlowVisible = false
    @State private var heroVisible = false
    @State private var carouselVisible = false
    @State private var labelsVisible = false
    @State private var panelVisible = false
    @State private var hasRunLaunchSequence = false
    @State private var isSwitchingOrgan = false
    @State private var viewerAngle: AnatomyOrgan.ViewerAngle = .front

    private let carouselOrder = [
        "brain",
        "lungs",
        "heart",
        "liver",
        "kidneys",
        "stomach",
        "skeleton",
        "eye",
        "ear",
        "spine",
        "intestines"
    ]
    private let maxAnnotationSlots = 8
    private var selectedOrgan: AnatomyOrgan { appModel.selectedOrgan }
    private var selectedAnnotation: OrganAnnotation? { appModel.selectedAnnotation }
    private var modeTitles: [String] { AppModel.StudyMode.allCases.map(\.title) }
    private var organs: [AnatomyOrgan] {
        carouselOrder.compactMap { id in
            AnatomyOrgan.featured.first(where: { $0.id == id })
        }
    }
    private var selectedIndex: Int { organs.firstIndex(where: { $0.id == appModel.selectedOrganID }) ?? 0 }
    private var preset: AnatomyOrgan.ImmersivePreset { selectedOrgan.immersivePreset }
    private var viewerLayout: AnatomyOrgan.ViewerLayout { selectedOrgan.viewerLayout(for: viewerAngle) }
    private var heartPosition: SIMD3<Float> { viewerLayout.heroPosition }
    private var labelsPosition: SIMD3<Float> { viewerLayout.labelsPosition }
    private var panelPosition: SIMD3<Float> { viewerLayout.panelPosition }
    private var carouselPosition: SIMD3<Float> { viewerLayout.carouselPosition }
    private var glowPosition: SIMD3<Float> {
        SIMD3<Float>(
            heartPosition.x,
            heartPosition.y + ImmersiveLayoutConfig.glowYOffset,
            heartPosition.z + ImmersiveLayoutConfig.glowZOffset
        )
    }

    var body: some View {
        RealityView { content, attachments in
            let ring = ModelEntity(
                mesh: .generateCylinder(height: 0.002, radius: 0.06),
                materials: [SimpleMaterial(color: .systemBlue.withAlphaComponent(0.10), roughness: 0.18, isMetallic: false)]
            )
            ring.position = glowPosition
            ring.scale = [1.0, 1.0, 1.0]
            content.add(ring)

            if let topBarEntity = attachments.entity(for: "top-bar") {
                topBarEntity.position = ImmersiveLayoutConfig.topBarPosition
                content.add(topBarEntity)
            }

            if let auraEntity = attachments.entity(for: "ambient-aura") {
                auraEntity.position = heartPosition + SIMD3<Float>(0.0, 0.02, -0.06)
                auraEntity.scale = [0.96, 0.96, 0.96]
                content.add(auraEntity)
            }

            if let heroEntity = attachments.entity(for: "hero-stage") {
                heroEntity.position = heartPosition
                heroEntity.scale = [0.92, 0.92, 0.92]
                content.add(heroEntity)
            }

            for index in 0..<maxAnnotationSlots {
                guard let note = selectedOrgan.atlasNotes[safe: index] else { continue }
                if let connectorEntity = attachments.entity(for: "connector-slot-\(index)") {
                    connectorEntity.position = connectorLayout(for: note).position
                    content.add(connectorEntity)
                }

                if let anchorEntity = attachments.entity(for: "anchor-slot-\(index)") {
                    anchorEntity.position = anchorWorldPosition(for: note)
                    content.add(anchorEntity)
                }

                if let labelEntity = attachments.entity(for: "annotation-slot-\(index)") {
                    labelEntity.position = spatialLabelPosition(for: note)
                    content.add(labelEntity)
                }
            }

            if let panelEntity = attachments.entity(for: "panel") {
                panelEntity.position = panelPosition
                panelEntity.orientation = simd_quatf(angle: -.pi / 18, axis: [0, 1, 0])
                content.add(panelEntity)
            }

            if let carouselEntity = attachments.entity(for: "carousel-stack") {
                carouselEntity.position = carouselPosition
                content.add(carouselEntity)
            }
        } attachments: {
            Attachment(id: "top-bar") {
                VStack(spacing: 14) {
                    ImmersiveModeBar(
                        items: modeTitles,
                        selectedItem: appModel.selectedStudyMode.title,
                        accent: selectedOrgan.tint
                    ) { mode in
                        if let resolvedMode = AppModel.StudyMode.allCases.first(where: { $0.title == mode }) {
                            withAnimation(.spring(response: 0.46, dampingFraction: 0.84)) {
                                appModel.setStudyMode(resolvedMode)
                            }
                        }
                    }
                    .frame(width: ImmersiveLayoutConfig.topBarWidth)
                }
            }

            Attachment(id: "ambient-aura") {
                ImmersiveAuraField(tint: selectedOrgan.tint, isVisible: backgroundGlowVisible)
                    .frame(width: ImmersiveLayoutConfig.auraSize, height: ImmersiveLayoutConfig.auraSize)
            }

            Attachment(id: "hero-stage") {
                ImmersiveHeroStage(
                    organ: selectedOrgan,
                    viewerLayout: viewerLayout,
                    selectedAnnotationID: appModel.selectedAnnotationID,
                    showAnnotations: labelsVisible,
                    isHeroVisible: heroVisible,
                    isGlowVisible: backgroundGlowVisible,
                    onAnnotationSelected: selectAnnotation
                )
                .frame(width: ImmersiveLayoutConfig.heroFrame.width, height: ImmersiveLayoutConfig.heroFrame.height)
                .scaleEffect(heroVisible ? 0.98 : 0.88)
            }

            makeAnnotationAttachment(index: 0)
            makeAnnotationAttachment(index: 1)
            makeAnnotationAttachment(index: 2)
            makeAnnotationAttachment(index: 3)
            makeAnnotationAttachment(index: 4)
            makeAnnotationAttachment(index: 5)
            makeAnnotationAttachment(index: 6)
            makeAnnotationAttachment(index: 7)
            makeConnectorAttachment(index: 0)
            makeConnectorAttachment(index: 1)
            makeConnectorAttachment(index: 2)
            makeConnectorAttachment(index: 3)
            makeConnectorAttachment(index: 4)
            makeConnectorAttachment(index: 5)
            makeConnectorAttachment(index: 6)
            makeConnectorAttachment(index: 7)
            makeAnchorAttachment(index: 0)
            makeAnchorAttachment(index: 1)
            makeAnchorAttachment(index: 2)
            makeAnchorAttachment(index: 3)
            makeAnchorAttachment(index: 4)
            makeAnchorAttachment(index: 5)
            makeAnchorAttachment(index: 6)
            makeAnchorAttachment(index: 7)

            Attachment(id: "panel") {
                ImmersiveInfoPanel(
                    organ: selectedOrgan,
                    selectedAnnotation: selectedAnnotation,
                    studyMode: appModel.selectedStudyMode,
                    progressFraction: appModel.selectedOrganProgressFraction,
                    progressText: appModel.selectedOrganProgressText,
                    isLearnMorePresented: appModel.isLearnMorePresented,
                    currentQuizQuestion: appModel.currentQuizQuestion,
                    selectedQuizAnswerIndex: appModel.selectedQuizAnswerIndex,
                    hasSubmittedCurrentQuizAnswer: appModel.hasSubmittedCurrentQuizAnswer,
                    onAnnotationSelected: selectAnnotation,
                    onResetFocus: clearAnnotationFocus,
                    onOpenLearnMore: appModel.openLearnMore,
                    onCloseLearnMore: appModel.closeLearnMore,
                    onSubmitQuizAnswer: appModel.submitQuizAnswer,
                    onAdvanceQuiz: appModel.advanceQuiz
                )
                .frame(width: viewerLayout.panelWidth, height: ImmersiveLayoutConfig.panelHeight)
                .opacity(panelVisible ? 1 : 0.001)
            }

            Attachment(id: "carousel-stack") {
                VStack(spacing: ImmersiveLayoutConfig.bottomStackSpacing) {
                    ImmersiveInstructionBar(mode: appModel.selectedStudyMode)
                        .opacity(labelsVisible || appModel.selectedStudyMode != .labels ? 1 : ImmersiveLayoutConfig.instructionOpacityWhenHidden)

                    ImmersiveCarousel(
                        organs: organs,
                        selectedOrganID: appModel.selectedOrganID,
                        preset: preset,
                        isVisible: carouselVisible,
                        canNavigateLeft: selectedIndex > 0,
                        canNavigateRight: selectedIndex < organs.count - 1,
                        onSelect: selectOrgan,
                        onNavigateLeft: navigateLeft,
                        onNavigateRight: navigateRight
                    )
                    .frame(height: ImmersiveLayoutConfig.carouselFrameHeight)

                    ImmersiveModeBar(
                        items: modeTitles,
                        selectedItem: appModel.selectedStudyMode.title,
                        accent: selectedOrgan.tint,
                        isCompact: true
                    ) { mode in
                        if let resolvedMode = AppModel.StudyMode.allCases.first(where: { $0.title == mode }) {
                            withAnimation(.spring(response: 0.46, dampingFraction: 0.84)) {
                                appModel.setStudyMode(resolvedMode)
                            }
                        }
                    }
                    .frame(width: ImmersiveLayoutConfig.bottomBarWidth)
                }
                .frame(width: ImmersiveLayoutConfig.carouselStackWidth)
            }
        }
        .animation(.spring(response: 0.62, dampingFraction: 0.86), value: appModel.selectedOrganID)
        .animation(.spring(response: 0.46, dampingFraction: 0.84), value: appModel.selectedAnnotationID)
        .onAppear {
            appModel.selectOrgan(appModel.selectedOrganID.isEmpty ? AnatomyOrgan.featured[0].id : appModel.selectedOrganID)
            runLaunchSequenceIfNeeded()
        }
        .onChange(of: appModel.selectedOrganID) { _, newValue in
            if newValue != "heart" {
                viewerAngle = .front
            }
        }
        .onChange(of: appModel.selectedStudyMode) { _, newValue in
            withAnimation(.spring(response: 0.48, dampingFraction: 0.84)) {
                labelsVisible = newValue == .labels
            }
        }
    }

    private func selectOrgan(_ organID: String) {
        guard organID != appModel.selectedOrganID, !isSwitchingOrgan else { return }
        isSwitchingOrgan = true

        Task { @MainActor in
            withAnimation(.easeInOut(duration: 0.18)) {
                labelsVisible = false
                panelVisible = false
                carouselVisible = false
            }

            try? await Task.sleep(for: .milliseconds(110))

            withAnimation(.spring(response: 0.40, dampingFraction: 0.92)) {
                heroVisible = false
            }

            try? await Task.sleep(for: .milliseconds(150))

            appModel.selectOrgan(organID)

            withAnimation(.easeOut(duration: 0.24)) {
                backgroundGlowVisible = true
            }

            withAnimation(.spring(response: 0.66, dampingFraction: 0.84)) {
                heroVisible = true
            }

            try? await Task.sleep(for: .milliseconds(260))

            withAnimation(.spring(response: 0.58, dampingFraction: 0.84)) {
                labelsVisible = appModel.selectedStudyMode == .labels
            }

            try? await Task.sleep(for: .milliseconds(180))

            withAnimation(.spring(response: 0.62, dampingFraction: 0.86)) {
                panelVisible = true
            }

            try? await Task.sleep(for: .milliseconds(180))

            withAnimation(.spring(response: 0.72, dampingFraction: 0.84)) {
                carouselVisible = true
            }

            isSwitchingOrgan = false
        }
    }

    private func navigateLeft() {
        guard selectedIndex > 0 else { return }
        selectOrgan(organs[selectedIndex - 1].id)
    }

    private func navigateRight() {
        guard selectedIndex < organs.count - 1 else { return }
        selectOrgan(organs[selectedIndex + 1].id)
    }

    private func selectAnnotation(_ annotationID: String) {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
            appModel.selectAnnotation(annotationID)
        }
    }

    private func clearAnnotationFocus() {
        withAnimation(.spring(response: 0.46, dampingFraction: 0.84)) {
            appModel.clearAnnotationFocus()
        }
    }

    private func runLaunchSequenceIfNeeded() {
        guard !hasRunLaunchSequence else { return }
        hasRunLaunchSequence = true

        backgroundGlowVisible = false
        heroVisible = false
        carouselVisible = false
        labelsVisible = false
        panelVisible = false

        Task {
            withAnimation(.easeOut(duration: 0.72)) {
                backgroundGlowVisible = true
            }

            try? await Task.sleep(for: .milliseconds(180))

            withAnimation(.spring(response: 0.84, dampingFraction: 0.84)) {
                heroVisible = true
            }

            try? await Task.sleep(for: .milliseconds(360))

            withAnimation(.spring(response: 0.62, dampingFraction: 0.82)) {
                labelsVisible = appModel.selectedStudyMode == .labels
            }

            try? await Task.sleep(for: .milliseconds(170))

            withAnimation(.spring(response: 0.62, dampingFraction: 0.84)) {
                panelVisible = true
            }

            try? await Task.sleep(for: .milliseconds(170))

            withAnimation(.spring(response: 0.72, dampingFraction: 0.84)) {
                carouselVisible = true
            }
        }
    }

    private func makeAnnotationAttachment(index: Int) -> Attachment<AnyView> {
        Attachment(id: "annotation-slot-\(index)") {
            AnyView(annotationSlotView(index: index))
        }
    }

    private func makeConnectorAttachment(index: Int) -> Attachment<AnyView> {
        Attachment(id: "connector-slot-\(index)") {
            AnyView(connectorSlotView(index: index))
        }
    }

    private func makeAnchorAttachment(index: Int) -> Attachment<AnyView> {
        Attachment(id: "anchor-slot-\(index)") {
            AnyView(anchorSlotView(index: index))
        }
    }

    @ViewBuilder
    private func annotationSlotView(index: Int) -> some View {
        if let note = selectedOrgan.atlasNotes[safe: index] {
            SpatialAnnotationAttachment(
                note: note,
                tint: selectedOrgan.tint,
                bubbleWidth: viewerLayout.labelWidth,
                isSelected: note.id == appModel.selectedAnnotationID,
                isDimmed: appModel.selectedAnnotationID != nil && note.id != appModel.selectedAnnotationID,
                isVisible: labelsVisible,
                delay: Double(index) * 0.07,
                selectedZOffset: viewerLayout.labelSelectedZ,
                restZOffset: viewerLayout.labelRestZ,
                onSelect: { selectAnnotation(note.id) }
            )
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func connectorSlotView(index: Int) -> some View {
        if let note = selectedOrgan.atlasNotes[safe: index] {
            let layout = connectorLayout(for: note)
            SpatialConnectorAttachment(
                side: note.side,
                tint: selectedOrgan.tint,
                isSelected: note.id == appModel.selectedAnnotationID,
                isDimmed: appModel.selectedAnnotationID != nil && note.id != appModel.selectedAnnotationID,
                isVisible: labelsVisible,
                deltaX: layout.deltaX,
                deltaY: layout.deltaY
            )
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func anchorSlotView(index: Int) -> some View {
        if let note = selectedOrgan.atlasNotes[safe: index] {
            SpatialAnchorDot(
                tint: selectedOrgan.tint,
                isSelected: note.id == appModel.selectedAnnotationID,
                isDimmed: appModel.selectedAnnotationID != nil && note.id != appModel.selectedAnnotationID,
                isVisible: labelsVisible
            )
        } else {
            EmptyView()
        }
    }

    private func spatialLabelPosition(for note: OrganAnnotation) -> SIMD3<Float> {
        let placement = viewerLayout.placement(for: note)
        let xOffset = placement.side == .left ? -Float(viewerLayout.labelLeftX) : Float(viewerLayout.labelRightX)
        let x = labelsPosition.x + xOffset
        let laneDelta = Float(0.50 - placement.lane)
        let y = labelsPosition.y + (laneDelta * ImmersiveLayoutConfig.labelVerticalSpread)
        let zLift: Float = note.id == appModel.selectedAnnotationID ? ImmersiveLayoutConfig.labelSelectedLift : (appModel.selectedAnnotationID == nil ? ImmersiveLayoutConfig.labelIdleLift : ImmersiveLayoutConfig.labelDimmedLift)
        let anchorYDelta = Float(0.5 - placement.anchor.y)
        let z = labelsPosition.z + zLift + (anchorYDelta * ImmersiveLayoutConfig.labelDepthTilt)
        return SIMD3<Float>(x, y, z)
    }

    private func anchorWorldPosition(for note: OrganAnnotation) -> SIMD3<Float> {
        let placement = viewerLayout.placement(for: note)
        let x = heartPosition.x + Float(placement.anchor.x - 0.5) * ImmersiveLayoutConfig.organAnchorSpreadX
        let y = heartPosition.y + Float(0.5 - placement.anchor.y) * ImmersiveLayoutConfig.organAnchorSpreadY
        let z = heartPosition.z + (placement.side == .right ? 0.02 : -0.01)
        return SIMD3<Float>(x, y, z)
    }

    private func connectorLayout(for note: OrganAnnotation) -> ConnectorLayout {
        let anchor = anchorWorldPosition(for: note)
        let label = spatialLabelPosition(for: note)
        return ConnectorLayout(
            position: SIMD3<Float>(
                (anchor.x + label.x) * 0.5,
                (anchor.y + label.y) * 0.5,
                min(anchor.z, label.z) + ImmersiveLayoutConfig.connectorDepthOffset
            ),
            deltaX: CGFloat((label.x - anchor.x) * 920),
            deltaY: CGFloat((label.y - anchor.y) * 920)
        )
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private struct ConnectorLayout {
    let position: SIMD3<Float>
    let deltaX: CGFloat
    let deltaY: CGFloat
}

private struct PremiumImmersiveCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let fillOpacity: CGFloat
    let borderOpacity: CGFloat

    func body(content: Content) -> some View {
        content
            .background(.black.opacity(fillOpacity), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(borderOpacity), lineWidth: 1)
            }
    }
}

private extension View {
    func premiumImmersiveCard(cornerRadius: CGFloat, fillOpacity: CGFloat = 0.24, borderOpacity: CGFloat = 0.08) -> some View {
        modifier(PremiumImmersiveCardModifier(cornerRadius: cornerRadius, fillOpacity: fillOpacity, borderOpacity: borderOpacity))
    }
}

private struct ImmersiveSceneFallbackCard: View {
    let organ: AnatomyOrgan

    var body: some View {
        VStack(spacing: 10) {
            Text("Loading \(organ.title) Study Space")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            Text("Preparing the spatial organ, labels, carousel, and study notes.")
                .font(.body.weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.78))
                .frame(maxWidth: 420)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .background(.black.opacity(0.24), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
        }
    }
}

private struct ImmersiveFloatingBadge: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))

            VStack(alignment: .leading, spacing: 2) {
                Text("Atlas Mode")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)

                Text("Spatial Learning")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white.opacity(0.66))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(.black.opacity(0.22), in: Capsule())
        .glassBackgroundEffect(in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
        }
    }
}

private struct ImmersiveUtilityDots: View {
    var body: some View {
        HStack(spacing: 16) {
            ForEach(["arrow.clockwise", "speaker.wave.2", "arrow.up.left.and.arrow.down.right"], id: \.self) { icon in
                Image(systemName: icon)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.88))
                    .frame(width: 52, height: 52)
                    .background(.black.opacity(0.18), in: Circle())
                    .glassBackgroundEffect(in: Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                    }
            }
        }
    }
}

private struct ImmersiveModeBar: View {
    let items: [String]
    let selectedItem: String
    let accent: Color
    var isCompact = false
    let onSelect: (String) -> Void

    var body: some View {
        HStack(spacing: isCompact ? 12 : 14) {
            ForEach(items, id: \.self) { item in
                Button(action: { onSelect(item) }) {
                    Text(item)
                        .font((isCompact ? Font.body : .title3).weight(item == selectedItem ? .bold : .medium))
                        .foregroundStyle(.white.opacity(item == selectedItem ? 0.98 : 0.72))
                        .padding(.horizontal, isCompact ? 20 : 26)
                        .padding(.vertical, isCompact ? 16 : 18)
                        .background {
                            if item == selectedItem {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                accent.opacity(0.34),
                                                .white.opacity(0.10)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, isCompact ? 16 : 18)
        .padding(.vertical, isCompact ? 14 : 14)
        .background(.black.opacity(0.52), in: Capsule())
        .glassBackgroundEffect(in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.22), radius: 24, y: 12)
    }
}

private struct ImmersiveInstructionBar: View {
    let mode: AppModel.StudyMode

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.86))

            Text(message)
                .font(.body.weight(.medium))
                .foregroundStyle(.white.opacity(0.74))
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 16)
        .premiumImmersiveCard(cornerRadius: 999, fillOpacity: 0.30, borderOpacity: 0.09)
    }

    private var iconName: String {
        switch mode {
        case .explore: "sparkles"
        case .labels: "hand.tap"
        case .quiz: "questionmark.circle"
        }
    }

    private var message: String {
        switch mode {
        case .explore:
            "Explore the organ in space • Use the carousel to switch organs"
        case .labels:
            "Tap any label to focus • Review each structure in the side panel"
        case .quiz:
            "Answer the quiz prompt in the side panel to track progress"
        }
    }
}

private struct ImmersiveHeader: View {
    let organ: AnatomyOrgan

    var body: some View {
        VStack(spacing: 10) {
            Text("Anatomy Study Space")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))

            Text(organ.title)
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(organ.studyPrompt)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.78))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 820)
        }
        .padding(.horizontal, 34)
        .padding(.vertical, 22)
        .background(.black.opacity(0.14), in: Capsule())
        .glassBackgroundEffect(in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
        }
    }
}

private struct ImmersiveHeroStage: View {
    let organ: AnatomyOrgan
    let viewerLayout: AnatomyOrgan.ViewerLayout
    let selectedAnnotationID: String?
    let showAnnotations: Bool
    let isHeroVisible: Bool
    let isGlowVisible: Bool
    let onAnnotationSelected: (String) -> Void

    var body: some View {
        let preset = organ.immersivePreset

        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            organ.tint.opacity(0.18),
                            organ.tint.opacity(0.06),
                            .clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 190
                    )
                )
                .frame(width: 420, height: 420)
                .blur(radius: 34)
                .opacity(isGlowVisible ? 0.92 : 0)

            Circle()
                .stroke(organ.tint.opacity(0.20), lineWidth: 6)
                .frame(width: 420, height: 420)
                .blur(radius: 22)
                .opacity(isGlowVisible ? 0.68 : 0)

            Circle()
                .stroke(Color.cyan.opacity(0.15), lineWidth: 1.4)
                .frame(width: 510, height: 510)
                .blur(radius: 10)
                .opacity(isGlowVisible ? 0.54 : 0)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.cyan.opacity(0.16),
                            organ.tint.opacity(0.12),
                            .clear
                        ],
                        center: .center,
                        startRadius: 18,
                        endRadius: 160
                    )
                )
                .frame(width: preset.floorGlowWidth, height: preset.floorGlowHeight)
                .blur(radius: 18)
                .offset(y: preset.stageHeight * 0.26)
                .offset(z: -36)
                .opacity(isGlowVisible ? 0.82 : 0)

            ForEach(0..<18, id: \.self) { index in
                Circle()
                    .fill(index.isMultiple(of: 2) ? organ.tint.opacity(0.30) : Color.cyan.opacity(0.20))
                    .frame(width: index.isMultiple(of: 3) ? 3.5 : 2.2, height: index.isMultiple(of: 3) ? 3.5 : 2.2)
                    .blur(radius: 0.8)
                    .offset(
                        x: CGFloat(cos(Double(index) * 0.70)) * (index.isMultiple(of: 2) ? 220 : 170),
                        y: CGFloat(sin(Double(index) * 0.82)) * (index.isMultiple(of: 2) ? 150 : 110)
                    )
                    .opacity(isGlowVisible ? 0.48 : 0)
            }

            Ellipse()
                .stroke(.white.opacity(0.07), lineWidth: 1)
                .frame(width: 560, height: 430)
                .opacity(isGlowVisible ? 0.44 : 0)

            Ellipse()
                .stroke(Color.cyan.opacity(0.20), style: StrokeStyle(lineWidth: 1.6, dash: [8, 12]))
                .frame(width: 680, height: 520)
                .opacity(isGlowVisible ? 0.24 : 0)

            OrganRealityView(
                organ: organ,
                viewerLayout: viewerLayout,
                selectedAnnotationID: selectedAnnotationID,
                showAnnotations: showAnnotations,
                isHeroVisible: isHeroVisible,
                onSelectAnnotation: onAnnotationSelected
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .shadow(color: organ.tint.opacity(0.18), radius: 48, y: 24)
    }
}

private struct SpatialAnnotationAttachment: View {
    let note: OrganAnnotation
    let tint: Color
    let bubbleWidth: CGFloat
    let isSelected: Bool
    let isDimmed: Bool
    let isVisible: Bool
    let delay: Double
    let selectedZOffset: CGFloat
    let restZOffset: CGFloat
    let onSelect: () -> Void

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let revealAmount: CGFloat = isVisible ? 1 : 0
            labelBody(time: time, revealAmount: revealAmount)
            .opacity(Double(revealAmount) * (isDimmed ? 0.56 : 1))
            .offset(y: (1 - revealAmount) * 10)
            .offset(z: isSelected ? selectedZOffset : isDimmed ? restZOffset - 18 : restZOffset)
            .scaleEffect(isSelected ? 1.02 : isDimmed ? 0.96 : 1.0)
            .animation(.spring(response: 0.50, dampingFraction: 0.82).delay(delay), value: isVisible)
            .contentShape(Rectangle())
            .allowsHitTesting(isVisible)
            .onTapGesture(perform: onSelect)
        }
    }

    @ViewBuilder
    private func labelBody(time: TimeInterval, revealAmount: CGFloat) -> some View {
        AnnotationBubble(
            note: note,
            isSelected: isSelected,
            isDimmed: isDimmed,
            tint: tint
        )
        .frame(width: bubbleWidth)
    }
}

private struct SpatialConnectorAttachment: View {
    let side: OrganAnnotation.Side
    let tint: Color
    let isSelected: Bool
    let isDimmed: Bool
    let isVisible: Bool
    let deltaX: CGFloat
    let deltaY: CGFloat

    var body: some View {
        let width = max(abs(deltaX) + 44, 120)
        let height = max(abs(deltaY) + 34, 64)
        let pulse = isSelected ? 1.0 : 0.92

        Canvas { context, size in
            let start = CGPoint(x: side == .left ? size.width - 10 : 10, y: size.height * 0.5)
            let labelAbove = deltaY < 0
            let endY = labelAbove ? 14 : size.height - 14
            let end = CGPoint(x: side == .left ? 14 : size.width - 14, y: endY)
            let elbow = CGPoint(x: side == .left ? size.width * 0.58 : size.width * 0.42, y: start.y)

            var path = Path()
            path.move(to: start)
            path.addLine(to: elbow)
            path.addLine(to: end)

            let colors: [Color] = isSelected
                ? [tint.opacity(0.94), .white.opacity(0.88)]
                : isDimmed
                    ? [.white.opacity(0.10), .white.opacity(0.02)]
                    : [.white.opacity(0.22), .white.opacity(0.05)]
            let gradient = Gradient(colors: side == .left ? colors : colors.reversed())

            context.stroke(
                path,
                with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: 0, y: size.height * 0.5),
                    endPoint: CGPoint(x: size.width, y: size.height * 0.5)
                ),
                style: StrokeStyle(lineWidth: isSelected ? 1.2 * pulse : 0.72, lineCap: .round, lineJoin: .round)
            )
        }
        .frame(width: width, height: height)
        .opacity(isVisible ? 1 : 0.001)
        .allowsHitTesting(false)
    }
}

private struct SpatialAnchorDot: View {
    let tint: Color
    let isSelected: Bool
    let isDimmed: Bool
    let isVisible: Bool

    var body: some View {
        Circle()
            .fill(isSelected ? tint : isDimmed ? .white.opacity(0.18) : .white.opacity(0.62))
            .frame(width: isSelected ? 12 : 8, height: isSelected ? 12 : 8)
            .shadow(color: isSelected ? tint.opacity(0.40) : .white.opacity(0.14), radius: isSelected ? 10 : 4)
            .opacity(isVisible ? 1 : 0.001)
            .allowsHitTesting(false)
    }
}

private struct ImmersiveCarousel: View {
    let organs: [AnatomyOrgan]
    let selectedOrganID: String
    let preset: AnatomyOrgan.ImmersivePreset
    let isVisible: Bool
    let canNavigateLeft: Bool
    let canNavigateRight: Bool
    let onSelect: (String) -> Void
    let onNavigateLeft: () -> Void
    let onNavigateRight: () -> Void

    var body: some View {
        ZStack {
            HStack {
                ImmersiveNavButton(direction: .left, isEnabled: canNavigateLeft, action: onNavigateLeft)
                Spacer()
                ImmersiveNavButton(direction: .right, isEnabled: canNavigateRight, action: onNavigateRight)
            }
            .padding(.horizontal, 56)

            ZStack {
                ForEach(Array(organs.enumerated()), id: \.element.id) { index, organ in
                    let offset = cardOffset(for: index)
                    ImmersiveCarouselCard(
                        organ: organ,
                        isSelected: organ.id == selectedOrganID,
                        distanceFromSelection: offset
                    )
                    .onTapGesture {
                        onSelect(organ.id)
                    }
                }
            }
            .frame(height: 150)
        }
        .opacity(isVisible ? 1 : 0)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .rotation3DEffect(.degrees(8), axis: (x: 1, y: 0, z: 0))
        .offset(z: 22)
    }

    private func cardOffset(for index: Int) -> Int {
        guard let selectedIndex = organs.firstIndex(where: { $0.id == selectedOrganID }) else {
            return 0
        }
        return index - selectedIndex
    }
}

private struct ImmersiveCarouselCard: View {
    let organ: AnatomyOrgan
    let isSelected: Bool
    let distanceFromSelection: Int

    var body: some View {
        let absoluteDistance = abs(distanceFromSelection)
        let arcLift = CGFloat(absoluteDistance) * 16
        let depthScale = max(0.72, 1 - CGFloat(absoluteDistance) * 0.07)
        let cardOpacity = isSelected ? 1.0 : max(0.38, 0.76 - Double(absoluteDistance) * 0.08)

        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                organ.tint.opacity(isSelected ? 0.46 : 0.08),
                                .white.opacity(isSelected ? 0.10 : 0.02),
                                .black.opacity(0.32)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Model3D(named: organ.modelName, bundle: realityKitContentBundle) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().tint(.white.opacity(0.9))
                    case .success(let model):
                        model
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(isSelected ? 1.12 : 0.80)
                            .rotation3DEffect(.degrees(Double(distanceFromSelection) * -18), axis: (x: 0, y: 1, z: 0))
                            .blur(radius: isSelected ? 0 : CGFloat(absoluteDistance) * 0.55)
                            .padding(14)
                    case .failure:
                        Image(systemName: organ.symbolName)
                            .font(.system(size: isSelected ? 40 : 32, weight: .bold))
                            .foregroundStyle(.white.opacity(0.8))
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .frame(width: isSelected ? 170 : 124, height: isSelected ? 132 : 92)
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(isSelected ? organ.tint.opacity(0.92) : .white.opacity(0.08), lineWidth: isSelected ? 1.6 : 1)
            }
                    .shadow(color: organ.tint.opacity(isSelected ? 0.30 : 0.06), radius: isSelected ? 22 : 8, y: isSelected ? 12 : 5)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(.white.opacity(0.10), lineWidth: 4)
                        .blur(radius: 12)
                }
            }
            .offset(z: isSelected ? 62 : CGFloat(-absoluteDistance * 30))

            VStack(spacing: 4) {
                Text(organ.title)
                    .font(isSelected ? .subheadline.weight(.bold) : .caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(isSelected ? 0.98 : 0.78))

                Text(organ.tagline)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(isSelected ? 0.74 : 0.56))
            }
        }
        .opacity(cardOpacity)
        .scaleEffect(isSelected ? 1.12 : depthScale)
        .rotation3DEffect(.degrees(Double(distanceFromSelection) * -20), axis: (x: 0, y: 1, z: 0))
        .offset(x: CGFloat(distanceFromSelection) * 150, y: isSelected ? -8 : arcLift)
        .offset(z: isSelected ? 52 : CGFloat(-absoluteDistance * 26))
        .zIndex(isSelected ? 20 : Double(10 - absoluteDistance))
    }
}

private struct ImmersiveNavButton: View {
    enum Direction {
        case left
        case right

        var symbolName: String {
            switch self {
            case .left: "chevron.left"
            case .right: "chevron.right"
            }
        }
    }

    let direction: Direction
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: direction.symbolName)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white.opacity(isEnabled ? 0.92 : 0.34))
                .frame(width: 58, height: 58)
                .background(.black.opacity(isEnabled ? 0.18 : 0.06), in: Circle())
                .glassBackgroundEffect(in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(.white.opacity(isEnabled ? 0.12 : 0.05), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .offset(z: 32)
    }
}

private struct ImmersiveInfoPanel: View {
    let organ: AnatomyOrgan
    let selectedAnnotation: OrganAnnotation?
    let studyMode: AppModel.StudyMode
    let progressFraction: Double
    let progressText: String
    let isLearnMorePresented: Bool
    let currentQuizQuestion: OrganQuizQuestion?
    let selectedQuizAnswerIndex: Int?
    let hasSubmittedCurrentQuizAnswer: Bool
    let onAnnotationSelected: (String) -> Void
    let onResetFocus: () -> Void
    let onOpenLearnMore: () -> Void
    let onCloseLearnMore: () -> Void
    let onSubmitQuizAnswer: (Int) -> Void
    let onAdvanceQuiz: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(organ.title)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Spacer()

                        Image(systemName: organ.symbolName)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(organ.tint)
                            .padding(10)
                            .background(organ.tint.opacity(0.16), in: Circle())
                    }

                    Text(organ.description)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.white.opacity(0.84))
                }

                ProgressCard(progressFraction: progressFraction, progressText: progressText, tint: organ.tint)

                if let availability = organ.modelAvailabilityText {
                    AvailabilityCard(message: availability, tint: organ.tint)
                }

                switch studyMode {
                case .explore:
                    ImmersiveStudySection(title: "Functions", items: organ.functions, tint: organ.tint)
                    ImmersiveStudySection(title: "Key Parts", items: organ.keyParts, tint: organ.tint)
                    StructureListSection(
                        notes: organ.atlasNotes,
                        selectedAnnotationID: selectedAnnotation?.id,
                        tint: organ.tint,
                        emptyMessage: organ.hasBundledModel ? "Label overlays are available for this organ." : "Detailed labels will appear here when the spatial model is added.",
                        onSelect: onAnnotationSelected
                    )
                case .labels:
                    PinnedStructureCard(
                        annotation: selectedAnnotation,
                        tint: organ.tint,
                        onResetFocus: onResetFocus
                    )
                    StructureListSection(
                        notes: organ.atlasNotes,
                        selectedAnnotationID: selectedAnnotation?.id,
                        tint: organ.tint,
                        emptyMessage: organ.hasBundledModel ? "Select a floating label to focus on a structure." : "Detailed label mode will unlock when this organ model is available.",
                        onSelect: onAnnotationSelected
                    )
                case .quiz:
                    QuizSection(
                        organ: organ,
                        question: currentQuizQuestion,
                        selectedAnswerIndex: selectedQuizAnswerIndex,
                        hasSubmitted: hasSubmittedCurrentQuizAnswer,
                        onSubmitAnswer: onSubmitQuizAnswer,
                        onAdvance: onAdvanceQuiz
                    )
                }

                if isLearnMorePresented {
                    LearnMoreSection(
                        title: selectedAnnotation?.title ?? organ.title,
                        subtitle: selectedAnnotation?.subtitle ?? organ.tagline,
                        bodyText: selectedAnnotation?.detail ?? organ.description,
                        highlights: selectedAnnotation.map { [$0.subtitle, organ.studyPrompt] } ?? [organ.shortDescription, organ.studyPrompt],
                        tint: organ.tint,
                        onClose: onCloseLearnMore
                    )
                }

                if studyMode != .quiz {
                    Button(action: {
                        isLearnMorePresented ? onCloseLearnMore() : onOpenLearnMore()
                    }) {
                        HStack {
                            Label(isLearnMorePresented ? "Close Learn More" : "Learn More", systemImage: isLearnMorePresented ? "xmark.circle" : "arrow.right.circle")
                                .font(.title2.weight(.semibold))

                            Spacer()

                            Image(systemName: isLearnMorePresented ? "chevron.down" : "arrow.right")
                                .font(.title3.weight(.bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .background(.black.opacity(0.22), in: Capsule())
                        .overlay {
                            Capsule()
                                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(32)
        }
        .scrollIndicators(.hidden)
        .background(
            LinearGradient(
                colors: [
                    .black.opacity(0.92),
                    .black.opacity(0.80),
                    organ.tint.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 38, style: .continuous)
        )
        .premiumImmersiveCard(cornerRadius: 38, fillOpacity: 0.10, borderOpacity: 0.10)
        .shadow(color: .black.opacity(0.34), radius: 34, y: 18)
        .rotation3DEffect(.degrees(-12), axis: (x: 0, y: 1, z: 0))
    }
}

private struct ImmersiveStudySection: View {
    let title: String
    let items: [String]
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.88))

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(tint.opacity(0.92))
                        .frame(width: 8, height: 8)
                        .padding(.top, 6)

                    Text(item)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.white.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct ProgressCard: View {
    let progressFraction: Double
    let progressText: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Progress")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.88))

                Spacer()

                Text(progressText)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(tint.opacity(0.96))
            }

            ProgressView(value: progressFraction)
                .tint(tint)
        }
        .padding(18)
        .premiumImmersiveCard(cornerRadius: 24, fillOpacity: 0.16, borderOpacity: 0.08)
    }
}

private struct AvailabilityCard: View {
    let message: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.badge")
                .font(.title3.weight(.bold))
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: 4) {
                Text("Atlas Status")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.92))

                Text(message)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white.opacity(0.74))
            }
        }
        .padding(18)
        .premiumImmersiveCard(cornerRadius: 24, fillOpacity: 0.16, borderOpacity: 0.08)
    }
}

private struct PinnedStructureCard: View {
    let annotation: OrganAnnotation?
    let tint: Color
    let onResetFocus: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Pinned Structure")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.88))

                Spacer()

                if annotation != nil {
                    Button(action: onResetFocus) {
                        Label("Full Organ", systemImage: "arrow.uturn.backward")
                            .font(.callout.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white.opacity(0.88))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(.white.opacity(0.05), in: Capsule())
                }
            }

            if let annotation {
                VStack(alignment: .leading, spacing: 8) {
                    Text(annotation.title)
                        .font(.title2.weight(.bold))

                    Text(annotation.subtitle)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(tint.opacity(0.95))

                    Text(annotation.detail)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.white.opacity(0.84))
                }
                .padding(20)
                .background(tint.opacity(0.18), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                .premiumImmersiveCard(cornerRadius: 26, fillOpacity: 0.08, borderOpacity: 0.12)
            } else {
                Text("Select a floating label to focus on a specific structure.")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white.opacity(0.68))
                    .padding(.vertical, 4)
            }
        }
    }
}

private struct StructureListSection: View {
    let notes: [OrganAnnotation]
    let selectedAnnotationID: String?
    let tint: Color
    let emptyMessage: String
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Structures")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.88))

            if notes.isEmpty {
                Text(emptyMessage)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white.opacity(0.64))
                    .padding(.vertical, 6)
            } else {
                ForEach(notes) { note in
                    ImmersiveAnnotationRow(
                        note: note,
                        tint: tint,
                        isSelected: note.id == selectedAnnotationID
                    )
                    .onTapGesture {
                        onSelect(note.id)
                    }
                }
            }
        }
    }
}

private struct QuizSection: View {
    let organ: AnatomyOrgan
    let question: OrganQuizQuestion?
    let selectedAnswerIndex: Int?
    let hasSubmitted: Bool
    let onSubmitAnswer: (Int) -> Void
    let onAdvance: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quiz")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.88))

            if let question {
                VStack(alignment: .leading, spacing: 10) {
                    Text(question.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(organ.tint.opacity(0.96))

                    Text(question.prompt)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)

                    Text("Select the structure that best matches the prompt. Use the floating labels or the structure list to inspect anatomy before you answer.")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.white.opacity(0.72))

                    VStack(spacing: 12) {
                        ForEach(Array(question.answers.enumerated()), id: \.offset) { index, answer in
                            QuizAnswerButton(
                                answer: answer,
                                isSelected: selectedAnswerIndex == index,
                                isCorrect: hasSubmitted && index == question.correctAnswerIndex,
                                isIncorrect: hasSubmitted && selectedAnswerIndex == index && index != question.correctAnswerIndex,
                                tint: organ.tint
                            ) {
                                onSubmitAnswer(index)
                            }
                        }
                    }

                    if hasSubmitted {
                        QuizFeedbackBanner(
                            isCorrect: selectedAnswerIndex == question.correctAnswerIndex,
                            hint: question.hint,
                            explanation: question.explanation,
                            tint: organ.tint
                        )

                        Button(action: onAdvance) {
                            Label("Next Question", systemImage: "arrow.right.circle")
                                .font(.headline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(organ.tint)
                    }
                }
                .padding(22)
                .premiumImmersiveCard(cornerRadius: 26, fillOpacity: 0.16, borderOpacity: 0.08)
            } else {
                Text(organ.hasBundledModel ? "Choose Heart or Brain to begin the structure quiz." : "Quiz content for this organ is coming soon.")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white.opacity(0.74))
            }
        }
    }
}

private struct QuizFeedbackBanner: View {
    let isCorrect: Bool
    let hint: String
    let explanation: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "lightbulb.fill")
                    .foregroundStyle(isCorrect ? .green.opacity(0.92) : tint.opacity(0.92))

                Text(isCorrect ? "Correct" : "Gentle hint")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }

            Text(isCorrect ? explanation : hint)
                .font(.body.weight(.medium))
                .foregroundStyle(.white.opacity(0.82))
        }
        .padding(16)
        .background((isCorrect ? Color.green.opacity(0.12) : tint.opacity(0.14)), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder((isCorrect ? Color.green.opacity(0.34) : tint.opacity(0.28)), lineWidth: 1)
        }
        .padding(.top, 6)
    }
}

private struct QuizAnswerButton: View {
    let answer: String
    let isSelected: Bool
    let isCorrect: Bool
    let isIncorrect: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(markerColor)
                    .frame(width: 12, height: 12)

                Text(answer)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.92))

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var markerColor: Color {
        if isCorrect { return .green.opacity(0.9) }
        if isIncorrect { return .red.opacity(0.9) }
        if isSelected { return tint }
        return .white.opacity(0.42)
    }

    private var backgroundColor: Color {
        if isCorrect { return .green.opacity(0.12) }
        if isIncorrect { return .red.opacity(0.12) }
        if isSelected { return tint.opacity(0.16) }
        return .white.opacity(0.03)
    }

    private var borderColor: Color {
        if isCorrect { return .green.opacity(0.52) }
        if isIncorrect { return .red.opacity(0.52) }
        if isSelected { return tint.opacity(0.48) }
        return .white.opacity(0.08)
    }
}

private struct LearnMoreSection: View {
    let title: String
    let subtitle: String
    let bodyText: String
    let highlights: [String]
    let tint: Color
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(tint.opacity(0.92))
                }

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.78))
                }
                .buttonStyle(.plain)
            }

            Text(bodyText)
                .font(.body.weight(.medium))
                .foregroundStyle(.white.opacity(0.82))

            VStack(alignment: .leading, spacing: 8) {
                ForEach(highlights, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(tint.opacity(0.92))
                            .frame(width: 7, height: 7)
                            .padding(.top, 7)

                        Text(item)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.white.opacity(0.76))
                    }
                }
            }
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [
                    tint.opacity(0.18),
                    .black.opacity(0.56)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .premiumImmersiveCard(cornerRadius: 28, fillOpacity: 0.10, borderOpacity: 0.12)
    }
}

private struct ImmersiveAnnotationRow: View {
    let note: OrganAnnotation
    let tint: Color
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(isSelected ? tint : .white.opacity(0.28))
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(note.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(isSelected ? 0.96 : 0.82))

                Text(note.subtitle)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.66))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(isSelected ? tint.opacity(0.16) : Color.black.opacity(0.28))
        )
        .premiumImmersiveCard(cornerRadius: 20, fillOpacity: 0.10, borderOpacity: isSelected ? 0.12 : 0.06)
    }
}

private struct ImmersiveAuraField: View {
    let tint: Color
    let isVisible: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .black.opacity(0.66),
                            .black.opacity(0.34),
                            .clear
                        ],
                        center: .center,
                        startRadius: 80,
                        endRadius: 480
                    )
                )
                .frame(width: 980, height: 980)
                .blur(radius: 38)

            Circle()
                .fill(tint.opacity(0.18))
                .frame(width: 560, height: 560)
                .blur(radius: 82)
                .offset(x: -46, y: -22)

            Circle()
                .fill(Color.cyan.opacity(0.09))
                .frame(width: 500, height: 500)
                .blur(radius: 88)
                .offset(x: 132, y: 48)

            Ellipse()
                .stroke(.white.opacity(0.05), lineWidth: 1)
                .frame(width: 720, height: 520)

            Ellipse()
                .stroke(.white.opacity(0.025), lineWidth: 1)
                .frame(width: 880, height: 620)
                .offset(y: 22)

            ForEach(0..<24, id: \.self) { index in
                Circle()
                    .fill(index.isMultiple(of: 3) ? tint.opacity(0.28) : .white.opacity(0.10))
                    .frame(width: index.isMultiple(of: 4) ? 4 : 2, height: index.isMultiple(of: 4) ? 4 : 2)
                    .blur(radius: 0.8)
                    .offset(
                        x: CGFloat((index * 57) % 640) - 320,
                        y: CGFloat((index * 43) % 420) - 210
                    )
            }
        }
        .opacity(isVisible ? 1 : 0.22)
        .allowsHitTesting(false)
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
