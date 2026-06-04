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
    static let topBarPosition = SIMD3<Float>(0.0, 1.92, -1.30)
    static let topBarWidth: CGFloat = 480
    static let auraSize: CGFloat = 1180
    static let heroFrame = CGSize(width: 1440, height: 1100)
    static let panelHeight: CGFloat = 1040
    static let instructionOpacityWhenHidden = 0.001
    static let carouselStackWidth: CGFloat = 880
    static let carouselFrameHeight: CGFloat = 210
    static let bottomStackSpacing: CGFloat = 12
    static let labelVerticalSpread: Float = 0.58
    static let labelSelectedLift: Float = 0.04
    static let labelIdleLift: Float = 0.008
    static let labelDimmedLift: Float = -0.012
    static let labelDepthTilt: Float = 0.032
    static let glowYOffset: Float = -0.40
    static let glowZOffset: Float = 0.02
    static let organAnchorSpreadX: Float = 0.54
    static let organAnchorSpreadY: Float = 0.60
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
    @State private var audio = SpatialAudioController()

    private let carouselOrder = ["heart", "brain"]
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
    /// In Learn mode the organ and carousel recede so the reader becomes the focus.
    private var learnActive: Bool { appModel.selectedStudyMode == .learn }
    /// Panel width per mode — narrower in Labels so right-side callouts have room.
    private var panelWidthForMode: CGFloat {
        switch appModel.selectedStudyMode {
        case .learn:  return 980
        case .labels: return 600   // narrower so right-side callouts have room
        default:      return viewerLayout.panelWidth
        }
    }
    private var viewerLayout: AnatomyOrgan.ViewerLayout { selectedOrgan.viewerLayout(for: viewerAngle) }
    /// In Labels mode the whole study scene shifts left so both label columns have
    /// room and the organ sits left-of-centre (like the reference layout).
    private var labelsShiftX: Float { appModel.selectedStudyMode == .labels ? -0.30 : 0 }
    private var heartPosition: SIMD3<Float> {
        var p = viewerLayout.heroPosition; p.x += labelsShiftX; return p
    }
    private var labelsPosition: SIMD3<Float> {
        var p = viewerLayout.labelsPosition; p.x += labelsShiftX; return p
    }
    private var panelPosition: SIMD3<Float> { viewerLayout.panelPosition }
    private var carouselPosition: SIMD3<Float> { viewerLayout.carouselPosition }
    private var visibleAnnotationIDs: Set<String> {
        guard appModel.selectedStudyMode == .labels else { return [] }
        // If a structure is focused, show only it. Otherwise show a curated set of key
        // labels — Labels mode is a clean reference layer, not the full lesson (that's
        // Learn mode). Keeping the set small avoids overlap and tiny crowding.
        if let id = appModel.selectedAnnotationID { return [id] }
        switch selectedOrgan.id {
        case "heart":
            // Balanced 3 per side: right-heart structures appear on the left, left-heart on the right.
            return ["heart-aorta", "heart-left-atrium", "heart-left-ventricle",
                    "heart-svc", "heart-right-atrium", "heart-right-ventricle"]
        case "brain":
            return ["brain-frontal", "brain-parietal", "brain-temporal",
                    "brain-cerebellum", "brain-brainstem"]
        default:
            return Set(selectedOrgan.atlasNotes.prefix(5).map(\.id))
        }
    }
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
                auraEntity.position = heartPosition + SIMD3<Float>(0.0, 0.02, -0.10)
                auraEntity.scale = [1.8, 1.8, 1.8]
                content.add(auraEntity)
            }

            if let heroEntity = attachments.entity(for: "hero-stage") {
                heroEntity.position = heartPosition
                heroEntity.scale = [1.55, 1.55, 1.55]
                content.add(heroEntity)
            }

            // Spatial audio emitter co-located with the organ.
            audio.attach(to: content, at: heartPosition)
            audio.play(organID: selectedOrgan.id)

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
        } update: { content, attachments in
            // Re-apply positions so labels/organ/panel react to organ, mode and selection.
            attachments.entity(for: "top-bar")?.position = ImmersiveLayoutConfig.topBarPosition
            attachments.entity(for: "ambient-aura")?.position = heartPosition + SIMD3<Float>(0.0, 0.02, -0.10)
            attachments.entity(for: "hero-stage")?.position = heartPosition

            for index in 0..<maxAnnotationSlots {
                guard let note = selectedOrgan.atlasNotes[safe: index] else { continue }
                attachments.entity(for: "connector-slot-\(index)")?.position = connectorLayout(for: note).position
                attachments.entity(for: "anchor-slot-\(index)")?.position = anchorWorldPosition(for: note)
                attachments.entity(for: "annotation-slot-\(index)")?.position = spatialLabelPosition(for: note)
            }

            attachments.entity(for: "panel")?.position = panelPosition
            attachments.entity(for: "carousel-stack")?.position = carouselPosition
            audio.move(to: heartPosition)
            audio.play(organID: selectedOrgan.id)
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
                    .allowsHitTesting(false)   // decorative only — never intercept taps
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
                .scaleEffect((heroVisible ? 0.98 : 0.88) * (learnActive ? 0.82 : 1.0))
                // Recede the organ in Learn mode so the reader leads.
                .opacity(learnActive ? 0.34 : 1.0)
                .blur(radius: learnActive ? 6 : 0)
                .animation(.easeInOut(duration: 0.4), value: learnActive)
                // The hero organ is purely visual — all interaction happens through the
                // label, panel and carousel attachments. Disabling hit testing on this
                // large frame stops it from covering the carousel / panel tap areas.
                .allowsHitTesting(false)
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
                    quizIndex: appModel.activeQuizQuestionIndex,
                    quizCount: selectedOrgan.quizQuestions.count,
                    selectedQuizAnswerIndex: appModel.selectedQuizAnswerIndex,
                    hasSubmittedCurrentQuizAnswer: appModel.hasSubmittedCurrentQuizAnswer,
                    onAnnotationSelected: selectAnnotation,
                    onResetFocus: clearAnnotationFocus,
                    onOpenLearnMore: appModel.openLearnMore,
                    onCloseLearnMore: appModel.closeLearnMore,
                    onSubmitQuizAnswer: appModel.submitQuizAnswer,
                    onAdvanceQuiz: appModel.advanceQuiz,
                    onStartQuiz: {
                        withAnimation(.spring(response: 0.46, dampingFraction: 0.84)) {
                            appModel.setStudyMode(.quiz)
                        }
                    }
                )
                .frame(width: panelWidthForMode, height: ImmersiveLayoutConfig.panelHeight)
                .opacity(panelVisible ? 1 : 0.001)
                .animation(.spring(response: 0.5, dampingFraction: 0.86), value: appModel.selectedStudyMode)
            }

            Attachment(id: "carousel-stack") {
                VStack(spacing: ImmersiveLayoutConfig.bottomStackSpacing) {
                    ImmersiveInstructionBar(mode: appModel.selectedStudyMode)
                        .opacity(labelsVisible || appModel.selectedStudyMode != .labels ? 1 : ImmersiveLayoutConfig.instructionOpacityWhenHidden)
                        .allowsHitTesting(false)   // hint text — not a control

                    ImmersiveCarousel(
                        organs: organs,
                        selectedOrganID: appModel.selectedOrganID,
                        isVisible: carouselVisible,
                        canNavigateLeft: selectedIndex > 0,
                        canNavigateRight: selectedIndex < organs.count - 1,
                        onSelect: selectOrgan,
                        onNavigateLeft: navigateLeft,
                        onNavigateRight: navigateRight
                    )
                    .frame(height: ImmersiveLayoutConfig.carouselFrameHeight)
                }
                .frame(width: ImmersiveLayoutConfig.carouselStackWidth)
                .opacity(learnActive ? 0.32 : 1.0)
                .animation(.easeInOut(duration: 0.4), value: learnActive)
            }
        }
        .animation(.spring(response: 0.62, dampingFraction: 0.86), value: appModel.selectedOrganID)
        .animation(.spring(response: 0.46, dampingFraction: 0.84), value: appModel.selectedAnnotationID)
        .onAppear {
            appModel.constrainSelectionToMVP()
            appModel.selectOrgan(appModel.selectedOrganID.isEmpty ? AnatomyOrgan.launcherFeatured[0].id : appModel.selectedOrganID)
            runLaunchSequenceIfNeeded()
        }
        .onChange(of: appModel.selectedOrganID) { _, newValue in
            if newValue != "heart" {
                viewerAngle = .front
            }
            audio.move(to: heartPosition)
            audio.play(organID: newValue)
        }
        .onDisappear {
            audio.stop()
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
                isVisible: labelsVisible && visibleAnnotationIDs.contains(note.id),
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
                side: viewerLayout.placement(for: note).side,
                tint: selectedOrgan.tint,
                isSelected: note.id == appModel.selectedAnnotationID,
                isDimmed: appModel.selectedAnnotationID != nil && note.id != appModel.selectedAnnotationID,
                isVisible: labelsVisible && visibleAnnotationIDs.contains(note.id),
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
                isVisible: labelsVisible && visibleAnnotationIDs.contains(note.id)
            )
        } else {
            EmptyView()
        }
    }

    /// Even vertical lane for a label among the visible labels on its OWN side, so each
    /// side forms a tidy, non-overlapping column.
    private func sideLane(for note: OrganAnnotation, side: OrganAnnotation.Side) -> Float {
        let sideNotes = selectedOrgan.atlasNotes.filter {
            visibleAnnotationIDs.contains($0.id) && viewerLayout.placement(for: $0).side == side
        }
        guard sideNotes.count > 1, let idx = sideNotes.firstIndex(where: { $0.id == note.id }) else { return 0.5 }
        // Keep the column within the middle band so it stays beside the organ.
        return 0.18 + (Float(idx) + 0.5) / Float(sideNotes.count) * 0.64
    }

    private func laneY(for note: OrganAnnotation, side: OrganAnnotation.Side) -> Float {
        labelsPosition.y + (0.50 - sideLane(for: note, side: side)) * ImmersiveLayoutConfig.labelVerticalSpread * 1.3
    }

    private func spatialLabelPosition(for note: OrganAnnotation) -> SIMD3<Float> {
        let side = viewerLayout.placement(for: note).side
        let xOffset = side == .left ? -Float(viewerLayout.labelLeftX) : Float(viewerLayout.labelRightX)
        let zLift: Float = note.id == appModel.selectedAnnotationID ? ImmersiveLayoutConfig.labelSelectedLift : (appModel.selectedAnnotationID == nil ? ImmersiveLayoutConfig.labelIdleLift : ImmersiveLayoutConfig.labelDimmedLift)
        return SIMD3<Float>(labelsPosition.x + xOffset, laneY(for: note, side: side), labelsPosition.z + zLift)
    }

    /// Anchor dot sits on the organ's contour (left or right) at the label's height, so
    /// each leader line is a short, clean, near-horizontal callout.
    private func anchorWorldPosition(for note: OrganAnnotation) -> SIMD3<Float> {
        let side = viewerLayout.placement(for: note).side
        let x = heartPosition.x + (side == .left ? -0.13 : 0.13)
        return SIMD3<Float>(x, laneY(for: note, side: side), heartPosition.z + 0.03)
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
        HStack(spacing: isCompact ? 6 : 8) {
            ForEach(items, id: \.self) { item in
                Button(action: { onSelect(item) }) {
                    Text(item)
                        .font(.subheadline.weight(item == selectedItem ? .bold : .medium))
                        .foregroundStyle(.white.opacity(item == selectedItem ? 1.0 : 0.58))
                        .padding(.horizontal, isCompact ? 14 : 16)
                        .padding(.vertical, isCompact ? 9 : 11)
                        .background {
                            if item == selectedItem {
                                Capsule()
                                    .fill(accent.opacity(0.42))
                                    .overlay(Capsule().strokeBorder(accent.opacity(0.6), lineWidth: 1))
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, isCompact ? 7 : 8)
        .padding(.vertical, 7)
        .background(.black.opacity(0.5), in: Capsule())
        .glassBackgroundEffect(in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 14, y: 7)
    }
}

private struct ImmersiveInstructionBar: View {
    let mode: AppModel.StudyMode

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.82))

            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.74))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
        .premiumImmersiveCard(cornerRadius: 999, fillOpacity: 0.22, borderOpacity: 0.07)
    }

    private var iconName: String {
        switch mode {
        case .explore: "sparkles"
        case .labels: "hand.tap"
        case .learn: "book"
        case .quiz: "questionmark.circle"
        }
    }

    private var message: String {
        switch mode {
        case .explore:
            "Explore the organ in space • Use the carousel to switch organs"
        case .labels:
            "Tap any label to focus • Review each structure in the side panel"
        case .learn:
            "Read through each lesson section in the side panel"
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

    /// THE one staging knob per organ: where the pedestal sits relative to the model,
    /// as a fraction of the stage height (larger = lower). Tune one value per model
    /// so the organ rests just above its rings.
    private var pedestalFraction: CGFloat {
        // Same pedestal placement for every organ — consistent study stage.
        return 0.28
    }

    var body: some View {
        let preset = organ.immersivePreset

        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            organ.tint.opacity(0.34),
                            organ.tint.opacity(0.12),
                            .clear
                        ],
                        center: .center,
                        startRadius: 24,
                        endRadius: 200
                    )
                )
                .frame(width: 440, height: 440)
                .blur(radius: 32)
                .opacity(isGlowVisible ? 0.92 : 0)

            Circle()
                .stroke(organ.tint.opacity(0.28), lineWidth: 3)
                .frame(width: 400, height: 400)
                .blur(radius: 14)
                .opacity(isGlowVisible ? 0.72 : 0)

            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 1.2)
                .frame(width: 500, height: 500)
                .blur(radius: 6)
                .opacity(isGlowVisible ? 0.48 : 0)

            // Premium holographic study disc — soft halo, calm core, crisp graded rings.
            Group {
                // Soft outer halo
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [organ.tint.opacity(0.20), organ.tint.opacity(0.05), .clear],
                            center: .center, startRadius: 10, endRadius: 260
                        )
                    )
                    .frame(width: preset.floorGlowWidth * 1.15, height: preset.floorGlowHeight * 1.15)
                    .blur(radius: 26)

                // Calm glowing core the organ rests on
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [organ.tint.opacity(0.42), organ.tint.opacity(0.14), .clear],
                            center: .center, startRadius: 2, endRadius: 130
                        )
                    )
                    .frame(width: preset.floorGlowWidth * 0.50, height: preset.floorGlowHeight * 0.36)
                    .blur(radius: 12)

                // Crisp, evenly concentric rings — clean and centered.
                ForEach(Array([1.04, 0.86, 0.66, 0.46].enumerated()), id: \.offset) { i, scale in
                    Ellipse()
                        .stroke(
                            (i == 2 ? organ.tint : Color.white).opacity([0.08, 0.16, 0.40, 0.22][i]),
                            lineWidth: i == 2 ? 1.6 : 1.0
                        )
                        .frame(width: preset.floorGlowWidth * scale, height: preset.floorGlowHeight * scale)
                }

                // Defined accent rim — even all the way around (no side bias).
                Ellipse()
                    .strokeBorder(organ.tint.opacity(0.7), lineWidth: 1.6)
                    .frame(width: preset.floorGlowWidth * 0.66, height: preset.floorGlowHeight * 0.46)
                    .shadow(color: organ.tint.opacity(0.5), radius: 6)
            }
            .offset(y: preset.stageHeight * pedestalFraction)
            .offset(z: -44)
            .opacity(isGlowVisible ? 1 : 0)

            // Warm cinematic key light — upper-left bias
            RadialGradient(
                colors: [
                    Color(red: 1.0, green: 0.86, blue: 0.72).opacity(0.18),
                    Color(red: 1.0, green: 0.78, blue: 0.62).opacity(0.06),
                    .clear
                ],
                center: UnitPoint(x: 0.18, y: 0.22),
                startRadius: 30,
                endRadius: 360
            )
            .frame(width: 720, height: 540)
            .blur(radius: 24)
            .blendMode(.screen)
            .opacity(isGlowVisible ? 0.78 : 0)
            .allowsHitTesting(false)

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
        .shadow(color: organ.tint.opacity(0.14), radius: 34, y: 18)
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
            .scaleEffect(isSelected ? 1.015 : isDimmed ? 0.97 : 1.0)
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
        let width = max(abs(deltaX) + 36, 104)
        let height = max(abs(deltaY) + 28, 56)
        let pulse = isSelected ? 1.0 : 0.92

        Canvas { context, size in
            // Clean single leader line from the anatomy anchor to the label.
            let anchorX: CGFloat = side == .left ? size.width - 6 : 6
            let labelX: CGFloat  = side == .left ? 6 : size.width - 6
            let labelAbove = deltaY < 0
            let anchorY: CGFloat = labelAbove ? size.height - 6 : 6
            let labelY: CGFloat  = labelAbove ? 6 : size.height - 6

            var path = Path()
            path.move(to: CGPoint(x: anchorX, y: anchorY))
            path.addLine(to: CGPoint(x: labelX, y: labelY))

            let baseOpacity: Double = isSelected ? 1.0 : isDimmed ? 0.22 : 0.7
            let lineColor: Color = isSelected ? tint : .white

            context.stroke(
                path,
                with: .color(lineColor.opacity(baseOpacity)),
                style: StrokeStyle(lineWidth: isSelected ? 2.0 * pulse : 1.3, lineCap: .round)
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
        ZStack {
            if isSelected {
                Circle()
                    .fill(tint.opacity(0.32))
                    .frame(width: 26, height: 26)
                    .blur(radius: 6)
            }
            Circle()
                .fill(isSelected ? tint : isDimmed ? .white.opacity(0.26) : .white.opacity(0.80))
                .frame(width: isSelected ? 12 : 8, height: isSelected ? 12 : 8)
                .shadow(color: isSelected ? tint.opacity(0.55) : .clear, radius: isSelected ? 8 : 0)
        }
        .opacity(isVisible ? 1 : 0.001)
        .allowsHitTesting(false)
    }
}

private struct ImmersiveCarousel: View {
    let organs: [AnatomyOrgan]
    let selectedOrganID: String
    let isVisible: Bool
    let canNavigateLeft: Bool
    let canNavigateRight: Bool
    let onSelect: (String) -> Void
    let onNavigateLeft: () -> Void
    let onNavigateRight: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                ImmersiveNavButton(direction: .left, isEnabled: canNavigateLeft, action: onNavigateLeft)

                HStack(spacing: 18) {
                    ForEach(organs) { organ in
                        ImmersiveCarouselCard(
                            organ: organ,
                            isSelected: organ.id == selectedOrganID
                        )
                        .onTapGesture {
                            onSelect(organ.id)
                        }
                    }
                }

                ImmersiveNavButton(direction: .right, isEnabled: canNavigateRight, action: onNavigateRight)
            }

            // Page indicator dots
            HStack(spacing: 8) {
                ForEach(organs) { organ in
                    Circle()
                        .fill(.white.opacity(organ.id == selectedOrganID ? 0.92 : 0.32))
                        .frame(
                            width: organ.id == selectedOrganID ? 8 : 6,
                            height: organ.id == selectedOrganID ? 8 : 6
                        )
                }
            }
        }
        .opacity(isVisible ? 1 : 0)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
    }
}

private struct ImmersiveCarouselCard: View {
    let organ: AnatomyOrgan
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Model3D(named: organ.modelName, bundle: realityKitContentBundle) { phase in
                switch phase {
                case .empty:
                    ProgressView().tint(.white.opacity(0.9))
                case .success(let model):
                    model
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(isSelected ? 1.05 : 0.86)
                        .padding(12)
                case .failure:
                    Image(systemName: organ.symbolName)
                        .font(.system(size: isSelected ? 32 : 26, weight: .bold))
                        .foregroundStyle(.white.opacity(0.8))
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 132, height: 100)
            // Flat tile — opaque dark fill so the room never shows through, single
            // border for selection, NO shadow (shadows read as misaligned layers
            // from a top viewing angle).
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.thumbnail, style: .continuous)
                    .fill(isSelected ? organ.tint.opacity(0.22) : Color.black.opacity(0.55))
            )
            .overlay {
                RoundedRectangle(cornerRadius: DS.Radius.thumbnail, style: .continuous)
                    .strokeBorder(isSelected ? organ.tint.opacity(0.95) : .white.opacity(0.12), lineWidth: isSelected ? 2.5 : 1)
            }

            VStack(spacing: 3) {
                Text(organ.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white.opacity(isSelected ? 0.99 : 0.82))

                Text(organ.tagline)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isSelected ? organ.tint.opacity(0.9) : .white.opacity(0.52))
            }
        }
        .frame(width: 172)
        .scaleEffect(isSelected ? 1.04 : 1.0)
        .animation(.spring(response: 0.42, dampingFraction: 0.84), value: isSelected)
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
                .font(.body.weight(.bold))
                .foregroundStyle(.white.opacity(isEnabled ? 0.92 : 0.30))
                .frame(width: 48, height: 48)
                .background(.black.opacity(isEnabled ? 0.12 : 0.04), in: Circle())
                .glassBackgroundEffect(in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(.white.opacity(isEnabled ? 0.10 : 0.04), lineWidth: 0.8)
                }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.3)
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
    let quizIndex: Int
    let quizCount: Int
    let selectedQuizAnswerIndex: Int?
    let hasSubmittedCurrentQuizAnswer: Bool
    let onAnnotationSelected: (String) -> Void
    let onResetFocus: () -> Void
    let onOpenLearnMore: () -> Void
    let onCloseLearnMore: () -> Void
    let onSubmitQuizAnswer: (Int) -> Void
    let onAdvanceQuiz: () -> Void
    let onStartQuiz: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .center) {
                        Text(organ.title)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Spacer()

                        Image(systemName: organ.symbolName)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(organ.tint)
                            .padding(10)
                            .background(organ.tint.opacity(0.16), in: Circle())
                    }

                    if studyMode != .learn {
                        Text(organ.description)
                            .font(.title2.weight(.medium))
                            .foregroundStyle(.white.opacity(0.86))
                            .lineLimit(4)
                    }
                }

                if studyMode != .learn {
                    ProgressCard(progressFraction: progressFraction, progressText: progressText, tint: organ.tint)
                }

                if let availability = organ.modelAvailabilityText {
                    AvailabilityCard(message: availability, tint: organ.tint)
                }

                switch studyMode {
                case .explore:
                    ImmersiveStudySection(title: "Key Functions", items: organ.functions, tint: organ.tint, symbols: organ.functionSymbols)
                    KeyStructuresSummary(count: organ.atlasNotes.count, tint: organ.tint)
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
                case .learn:
                    LearnModeSection(organ: organ)
                case .quiz:
                    QuizSection(
                        organ: organ,
                        question: currentQuizQuestion,
                        questionNumber: quizIndex + 1,
                        questionCount: quizCount,
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

            }
            .padding(26)
        }
        .scrollIndicators(.hidden)
        // Pinned footer — Start Quiz / Learn More are always visible regardless of
        // how tall the scrolling content is (fixes the clipped button on Brain).
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if studyMode != .quiz {
                VStack(spacing: 12) {
                    Button(action: onStartQuiz) {
                        HStack(spacing: 10) {
                            Spacer()
                            Image(systemName: "questionmark.circle.fill")
                                .font(.headline.weight(.bold))
                            Text("Start Quiz")
                                .font(.headline.weight(.bold))
                            Spacer()
                        }
                        .foregroundStyle(.white)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(
                                colors: [organ.tint.opacity(0.92), organ.tint.opacity(0.74)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: Capsule()
                        )
                        .shadow(color: organ.tint.opacity(0.34), radius: 14, y: 6)
                    }
                    .buttonStyle(.plain)

                    if studyMode != .learn {
                        Button(action: {
                            isLearnMorePresented ? onCloseLearnMore() : onOpenLearnMore()
                        }) {
                            HStack(spacing: 10) {
                                Spacer()
                                Image(systemName: isLearnMorePresented ? "xmark.circle" : "book")
                                    .font(.subheadline.weight(.semibold))
                                Text(isLearnMorePresented ? "Close" : "Learn More")
                                    .font(.headline.weight(.semibold))
                                Spacer()
                            }
                            .foregroundStyle(.white.opacity(0.92))
                            .padding(.vertical, 14)
                            .background(.white.opacity(0.06), in: Capsule())
                            .overlay {
                                Capsule()
                                    .strokeBorder(.white.opacity(0.14), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 26)
                .padding(.top, 14)
                .padding(.bottom, 24)
                .background(.black.opacity(0.55))
            }
        }
        .background(
            LinearGradient(
                colors: [
                    .black.opacity(0.86),
                    .black.opacity(0.74),
                    organ.tint.opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .premiumImmersiveCard(cornerRadius: 32, fillOpacity: 0.08, borderOpacity: 0.09)
        .shadow(color: .black.opacity(0.30), radius: 26, y: 14)
        .rotation3DEffect(.degrees(-6), axis: (x: 0, y: 1, z: 0))
    }
}

// MARK: - Learn Mode (Phase 1 reader)

private struct LearnModeSection: View {
    let organ: AnatomyOrgan
    @State private var section: OrganLesson.Section = .overview

    private var lesson: OrganLesson? { OrganLesson.lesson(for: organ.id) }

    var body: some View {
        if let lesson {
            HStack(alignment: .top, spacing: 24) {
                // Left rail — "Learning Sections"
                VStack(alignment: .leading, spacing: 6) {
                    Text("Learning Sections")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.5))
                        .textCase(.uppercase)
                        .tracking(0.6)
                        .padding(.bottom, 4)

                    ForEach(Array(OrganLesson.Section.allCases.enumerated()), id: \.element.id) { index, sec in
                        Button {
                            withAnimation(.easeInOut(duration: 0.22)) { section = sec }
                        } label: {
                            HStack(spacing: 10) {
                                Text("\(index + 1)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(section == sec ? .white : .white.opacity(0.6))
                                    .frame(width: 22, height: 22)
                                    .background(
                                        Circle().fill(section == sec ? organ.tint.opacity(0.9) : .white.opacity(0.08))
                                    )
                                Text(sec.rawValue)
                                    .font(.subheadline.weight(section == sec ? .semibold : .medium))
                                    .foregroundStyle(section == sec ? .white : .white.opacity(0.66))
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                                    .fill(section == sec ? organ.tint.opacity(0.16) : .clear)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: 210, alignment: .leading)

                // Content column
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        Image(systemName: section.symbol)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(organ.tint)
                        Text(section.rawValue)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    content(for: lesson)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            Text("A guided lesson for this organ is coming soon.")
                .font(.body.weight(.medium))
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    @ViewBuilder
    private func content(for lesson: OrganLesson) -> some View {
        switch section {
        case .overview:
            VStack(alignment: .leading, spacing: 8) {
                Text(lesson.overview.heading)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text(lesson.overview.body)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white.opacity(0.84))
                    .fixedSize(horizontal: false, vertical: true)
            }

        case .anatomy:
            VStack(alignment: .leading, spacing: 16) {
                ForEach(lesson.anatomy) { sec in
                    VStack(alignment: .leading, spacing: 8) {
                        AnatomyImage(slot: sec.image, tint: organ.tint)
                            .frame(height: 150)
                        Text(sec.name)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                        Text(sec.blurb)
                            .font(.callout.weight(.medium))
                            .foregroundStyle(.white.opacity(0.82))
                            .fixedSize(horizontal: false, vertical: true)
                        FlowChips(items: sec.labels, tint: organ.tint)
                    }
                }
            }

        case .functionality:
            VStack(alignment: .leading, spacing: 14) {
                ForEach(lesson.functions) { topic in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: topic.symbol)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(organ.tint)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(topic.title)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.white)
                            Text(topic.explanation)
                                .font(.callout.weight(.medium))
                                .foregroundStyle(.white.opacity(0.80))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

        case .realWorld:
            VStack(alignment: .leading, spacing: 14) {
                ForEach(lesson.realWorld) { note in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.scenario)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(organ.tint.opacity(0.96))
                        Text(note.explanation)
                            .font(.callout.weight(.medium))
                            .foregroundStyle(.white.opacity(0.82))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

        case .summary:
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(lesson.summary.enumerated()), id: \.offset) { _, fact in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.callout)
                            .foregroundStyle(organ.tint.opacity(0.9))
                        Text(fact)
                            .font(.callout.weight(.medium))
                            .foregroundStyle(.white.opacity(0.86))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

/// Simple wrapping chip row for anatomy label lists.
private struct FlowChips: View {
    let items: [String]
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.82))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.07), in: Capsule())
            }
        }
    }
}

private struct ImmersiveStudySection: View {
    let title: String
    let items: [String]
    let tint: Color
    var symbols: [String] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white.opacity(0.80))
                .textCase(.uppercase)
                .tracking(0.6)

            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 12) {
                    if let symbol = symbols[safe: index] {
                        Image(systemName: symbol)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(tint.opacity(0.92))
                            .frame(width: 26, height: 26)
                            .padding(.top, 1)
                    } else {
                        Circle()
                            .fill(tint.opacity(0.92))
                            .frame(width: 8, height: 8)
                            .padding(.top, 8)
                    }

                    Text(item)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.white.opacity(0.88))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.88))

                Spacer()

                Text(progressText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint.opacity(0.96))
            }

            ProgressView(value: progressFraction)
                .tint(tint)
        }
        .padding(16)
        .premiumImmersiveCard(cornerRadius: 22, fillOpacity: 0.14, borderOpacity: 0.08)
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
        .padding(16)
        .premiumImmersiveCard(cornerRadius: 22, fillOpacity: 0.14, borderOpacity: 0.08)
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
                    .font(.headline.weight(.semibold))
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
                        .font(.title3.weight(.bold))

                    Text(annotation.subtitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(tint.opacity(0.96))

                    Text(annotation.detail)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.white.opacity(0.86))
                }
                .padding(18)
                .background(tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .premiumImmersiveCard(cornerRadius: 22, fillOpacity: 0.06, borderOpacity: 0.10)
            } else {
                Text("Select a floating label to focus on a specific structure.")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white.opacity(0.68))
                    .padding(.vertical, 4)
            }
        }
    }
}

/// Compact "Key Structures" summary used in Explore (the full list lives in Labels/Learn).
private struct KeyStructuresSummary: View {
    let count: Int
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Structures")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white.opacity(0.80))
                .textCase(.uppercase)
                .tracking(0.6)

            HStack(spacing: 12) {
                Image(systemName: "square.stack.3d.up")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(count) main structures")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Open Labels to explore them in space, or Learn for the full lesson.")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.62))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .premiumImmersiveCard(cornerRadius: DS.Radius.control, fillOpacity: 0.10, borderOpacity: 0.08)
        }
    }
}

private struct StructureListSection: View {
    let notes: [OrganAnnotation]
    let selectedAnnotationID: String?
    let tint: Color
    let emptyMessage: String
    let onSelect: (String) -> Void

    @State private var isExpanded = false
    private let collapsedLimit = 5

    private var visibleNotes: [OrganAnnotation] {
        if isExpanded || notes.count <= collapsedLimit {
            return notes
        }
        return Array(notes.prefix(collapsedLimit))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Structures")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white.opacity(0.80))
                .textCase(.uppercase)
                .tracking(0.6)

            if notes.isEmpty {
                Text(emptyMessage)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white.opacity(0.64))
                    .padding(.vertical, 6)
            } else {
                ForEach(visibleNotes) { note in
                    ImmersiveAnnotationRow(
                        note: note,
                        tint: tint,
                        isSelected: note.id == selectedAnnotationID
                    )
                    .onTapGesture {
                        onSelect(note.id)
                    }
                }

                if notes.count > collapsedLimit {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(tint.opacity(0.9))
                                .frame(width: 6, height: 6)
                            Text(isExpanded ? "Show less" : "View all (\(notes.count))")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(tint.opacity(0.96))
                            Spacer()
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(tint.opacity(0.8))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.black.opacity(0.18))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct QuizSection: View {
    let organ: AnatomyOrgan
    let question: OrganQuizQuestion?
    let questionNumber: Int
    let questionCount: Int
    let selectedAnswerIndex: Int?
    let hasSubmitted: Bool
    let onSubmitAnswer: (Int) -> Void
    let onAdvance: () -> Void

    private var isCorrect: Bool {
        guard let question, let selectedAnswerIndex else { return false }
        return selectedAnswerIndex == question.correctAnswerIndex
    }

    var body: some View {
        if let question {
            VStack(alignment: .leading, spacing: 16) {
                // Header row: progress + question kind
                HStack {
                    Text("Question \(questionNumber) of \(questionCount)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    Label(question.kind.label, systemImage: question.kind.symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(organ.tint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(organ.tint.opacity(0.16), in: Capsule())
                }

                // Category badge
                Text(question.category.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.5))
                    .tracking(0.8)

                // Optional illustration
                if let slot = question.imageSlot {
                    AnatomyImage(slot: slot, tint: organ.tint)
                        .frame(height: 150)
                }

                // Prompt
                Text(question.prompt)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                // Answers
                VStack(spacing: 10) {
                    ForEach(Array(question.answers.enumerated()), id: \.offset) { index, answer in
                        QuizAnswerButton(
                            answer: answer,
                            letter: String(UnicodeScalar(65 + index)!),
                            isSelected: selectedAnswerIndex == index,
                            isCorrect: hasSubmitted && index == question.correctAnswerIndex,
                            isIncorrect: hasSubmitted && selectedAnswerIndex == index && index != question.correctAnswerIndex,
                            locked: hasSubmitted,
                            tint: organ.tint
                        ) {
                            if !hasSubmitted { onSubmitAnswer(index) }
                        }
                    }
                }

                if hasSubmitted {
                    QuizFeedbackBanner(
                        isCorrect: isCorrect,
                        hint: question.hint,
                        explanation: question.explanation,
                        tint: organ.tint
                    )

                    Button(action: onAdvance) {
                        Label(questionNumber >= questionCount ? "Restart Quiz" : "Next Question",
                              systemImage: "arrow.right.circle.fill")
                            .font(.headline.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                LinearGradient(colors: [organ.tint.opacity(0.92), organ.tint.opacity(0.74)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                in: Capsule()
                            )
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
            }
        } else {
            Text(organ.hasBundledModel ? "Choose Heart or Brain to begin the quiz." : "Quiz content for this organ is coming soon.")
                .font(.body.weight(.medium))
                .foregroundStyle(.white.opacity(0.74))
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
    let letter: String
    let isSelected: Bool
    let isCorrect: Bool
    let isIncorrect: Bool
    let locked: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(markerFill).frame(width: 26, height: 26)
                    if isCorrect {
                        Image(systemName: "checkmark").font(.caption.weight(.bold)).foregroundStyle(.white)
                    } else if isIncorrect {
                        Image(systemName: "xmark").font(.caption.weight(.bold)).foregroundStyle(.white)
                    } else {
                        Text(letter).font(.caption.weight(.bold)).foregroundStyle(.white.opacity(0.9))
                    }
                }

                Text(answer)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.94))
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: isSelected || isCorrect || isIncorrect ? 1.6 : 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(locked)
    }

    private var markerFill: Color {
        if isCorrect { return .green.opacity(0.9) }
        if isIncorrect { return .red.opacity(0.9) }
        if isSelected { return tint }
        return .white.opacity(0.16)
    }

    private var backgroundColor: Color {
        if isCorrect { return .green.opacity(0.16) }
        if isIncorrect { return .red.opacity(0.16) }
        if isSelected { return tint.opacity(0.18) }
        return .white.opacity(0.04)
    }

    private var borderColor: Color {
        if isCorrect { return .green.opacity(0.6) }
        if isIncorrect { return .red.opacity(0.6) }
        if isSelected { return tint.opacity(0.5) }
        return .white.opacity(0.10)
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
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(tint.opacity(0.94))
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
                .font(.callout.weight(.medium))
                .foregroundStyle(.white.opacity(0.82))

            VStack(alignment: .leading, spacing: 6) {
                ForEach(highlights, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(tint.opacity(0.86))
                            .frame(width: 5, height: 5)
                            .padding(.top, 5)

                        Text(item)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.74))
                    }
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    tint.opacity(0.18),
                    .black.opacity(0.56)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .premiumImmersiveCard(cornerRadius: 24, fillOpacity: 0.08, borderOpacity: 0.10)
    }
}

private struct ImmersiveAnnotationRow: View {
    let note: OrganAnnotation
    let tint: Color
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(isSelected ? tint : .white.opacity(0.32))
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 3) {
                Text(note.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(isSelected ? 0.98 : 0.92))

                Text(note.subtitle)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white.opacity(0.68))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.body.weight(.bold))
                .foregroundStyle(isSelected ? tint.opacity(0.9) : .white.opacity(0.42))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isSelected ? tint.opacity(0.16) : Color.black.opacity(0.20))
        )
        .premiumImmersiveCard(cornerRadius: 16, fillOpacity: 0.06, borderOpacity: isSelected ? 0.12 : 0.05)
    }
}

private struct ImmersiveAuraField: View {
    let tint: Color
    let isVisible: Bool

    var body: some View {
        ZStack {
            // Deep dark backdrop — makes organ pop against the room
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .black.opacity(0.82),
                            .black.opacity(0.52),
                            .black.opacity(0.18),
                            .clear
                        ],
                        center: .center,
                        startRadius: 60,
                        endRadius: 520
                    )
                )
                .frame(width: 920, height: 920)
                .blur(radius: 24)

            // Primary tint bloom — warm coloured halo behind the organ
            Circle()
                .fill(tint.opacity(0.28))
                .frame(width: 520, height: 520)
                .blur(radius: 90)
                .offset(x: -16, y: -12)

            // Secondary soft tint spread
            Circle()
                .fill(tint.opacity(0.12))
                .frame(width: 680, height: 680)
                .blur(radius: 120)
                .offset(x: 24, y: 18)

            // Subtle white specular highlight at top
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 280, height: 280)
                .blur(radius: 60)
                .offset(x: 0, y: -120)

            // Thin outer halo ring — museum-like
            Ellipse()
                .stroke(tint.opacity(0.18), lineWidth: 1.2)
                .frame(width: 580, height: 420)
                .blur(radius: 3)

            Ellipse()
                .stroke(.white.opacity(0.04), lineWidth: 1)
                .frame(width: 700, height: 500)
                .offset(y: 14)
        }
        .opacity(isVisible ? 1 : 0.18)
        .allowsHitTesting(false)
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
}
