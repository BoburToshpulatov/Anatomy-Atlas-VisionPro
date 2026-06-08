//
//  AppModel.swift
//  Anatomy
//
//  Created by Bobur Toshpulatov on 23/05/26.
//

import SwiftUI

@MainActor
@Observable
final class AppModel {
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }

    enum ImmersiveOpenResult: Equatable {
        case idle
        case opened
        case userCancelled
        case error
        case unknown
    }

    enum StudyMode: String, CaseIterable, Codable, Hashable {
        case explore
        case labels
        case learn
        case quiz

        var title: String {
            switch self {
            case .explore: "Explore"
            case .labels: "Labels"
            case .learn: "Learn"
            case .quiz: "Quiz"
            }
        }
    }

    struct OrganProgress: Codable, Equatable {
        var viewedAnnotationIDs: [String] = []
        var completedQuizQuestionIDs: [String] = []
        var completedModes: [StudyMode] = []

        mutating func markAnnotationViewed(_ annotationID: String) {
            if !viewedAnnotationIDs.contains(annotationID) {
                viewedAnnotationIDs.append(annotationID)
            }
        }

        mutating func markQuizQuestionCompleted(_ questionID: String) {
            if !completedQuizQuestionIDs.contains(questionID) {
                completedQuizQuestionIDs.append(questionID)
            }
        }

        mutating func markModeCompleted(_ mode: StudyMode) {
            if !completedModes.contains(mode) {
                completedModes.append(mode)
            }
        }
    }

    private struct PersistedProgress: Codable {
        var organProgressByID: [String: OrganProgress] = [:]
    }

    static let immersiveSpaceID = "anatomy-study-space"
    static let learnWindowID = "anatomy-learn-reader"

    let immersiveSpaceID = AppModel.immersiveSpaceID

    var immersiveSpaceState: ImmersiveSpaceState = .closed
    var lastImmersiveOpenResult: ImmersiveOpenResult = .idle
    var lastStatusMessage = "Ready to begin."

    var selectedOrganID = AnatomyOrgan.launcherFeatured.first?.id ?? "heart"
    var selectedAnnotationID: String?
    var selectedStudyMode: StudyMode = .explore
    var isLearnMorePresented = false

    var activeQuizQuestionIndex = 0
    var selectedQuizAnswerIndex: Int?
    var hasSubmittedCurrentQuizAnswer = false

    private let progressStorageKey = "anatomy.mvp.progress.v1"
    private var organProgressByID: [String: OrganProgress] = [:]

    init() {
        restoreProgress()
        constrainSelectionToMVP()
    }

    var selectedOrgan: AnatomyOrgan {
        AnatomyOrgan.launcherFeatured.first(where: { $0.id == selectedOrganID })
            ?? AnatomyOrgan.launcherFeatured[0]
    }

    var selectedAnnotation: OrganAnnotation? {
        guard let selectedAnnotationID else { return nil }
        return selectedOrgan.atlasNotes.first(where: { $0.id == selectedAnnotationID })
    }

    var currentQuizQuestion: OrganQuizQuestion? {
        let questions = selectedOrgan.quizQuestions
        guard !questions.isEmpty, questions.indices.contains(activeQuizQuestionIndex) else { return nil }
        return questions[activeQuizQuestionIndex]
    }

    var currentProgress: OrganProgress {
        organProgressByID[selectedOrganID] ?? OrganProgress()
    }

    var selectedOrganProgressFraction: Double {
        progressFraction(for: selectedOrgan)
    }

    var selectedOrganProgressText: String {
        let percent = Int((selectedOrganProgressFraction * 100).rounded())
        return percent >= 100 ? "Completed" : "\(percent)% complete"
    }

    var selectedOrganCompletedCount: Int {
        let progress = currentProgress
        return progress.viewedAnnotationIDs.count + progress.completedQuizQuestionIDs.count + progress.completedModes.count
    }

    var selectedOrganTotalCount: Int {
        selectedOrgan.atlasNotes.count + selectedOrgan.quizQuestions.count + StudyMode.allCases.count
    }

    func progressFraction(for organ: AnatomyOrgan) -> Double {
        let progress = organProgressByID[organ.id] ?? OrganProgress()
        let total = max(organ.atlasNotes.count + organ.quizQuestions.count + StudyMode.allCases.count, 1)
        let completed = progress.viewedAnnotationIDs.count + progress.completedQuizQuestionIDs.count + progress.completedModes.count
        return min(Double(completed) / Double(total), 1)
    }

    func isCompleted(_ organ: AnatomyOrgan) -> Bool {
        progressFraction(for: organ) >= 0.999
    }

    func selectOrgan(_ organID: String) {
        guard organID != selectedOrganID else { return }
        selectedOrganID = organID
        selectedAnnotationID = nil
        selectedStudyMode = .explore
        isLearnMorePresented = false
        activeQuizQuestionIndex = 0
        selectedQuizAnswerIndex = nil
        hasSubmittedCurrentQuizAnswer = false
        lastStatusMessage = "\(selectedOrgan.title) ready to study."
        markModeCompleted(.explore)
    }

    func constrainSelectionToMVP() {
        let allowedIDs = Set(AnatomyOrgan.launcherFeatured.map(\.id))
        guard allowedIDs.contains(selectedOrganID) else {
            selectedOrganID = AnatomyOrgan.launcherFeatured.first?.id ?? "heart"
            selectedAnnotationID = nil
            selectedStudyMode = .explore
            isLearnMorePresented = false
            activeQuizQuestionIndex = 0
            selectedQuizAnswerIndex = nil
            hasSubmittedCurrentQuizAnswer = false
            return
        }
    }

    func setStudyMode(_ mode: StudyMode) {
        selectedStudyMode = mode
        isLearnMorePresented = false

        if mode != .labels {
            selectedAnnotationID = nil
        }

        if mode == .quiz {
            selectedQuizAnswerIndex = nil
            hasSubmittedCurrentQuizAnswer = false
            activeQuizQuestionIndex = min(activeQuizQuestionIndex, max(selectedOrgan.quizQuestions.count - 1, 0))
        }

        markModeCompleted(mode)
        lastStatusMessage = mode.title + " mode active."
    }

    func selectAnnotation(_ annotationID: String) {
        selectedAnnotationID = annotationID
        selectedStudyMode = .labels
        isLearnMorePresented = false
        markAnnotationViewed(annotationID)
        markModeCompleted(.labels)
        lastStatusMessage = "Focused on \(selectedAnnotation?.title ?? selectedOrgan.title)."
    }

    func clearAnnotationFocus() {
        selectedAnnotationID = nil
        isLearnMorePresented = false
    }

    func openLearnMore() {
        guard selectedAnnotation != nil || selectedStudyMode == .explore else { return }
        isLearnMorePresented = true
    }

    func closeLearnMore() {
        isLearnMorePresented = false
    }

    func submitQuizAnswer(_ answerIndex: Int) {
        guard let question = currentQuizQuestion else { return }
        selectedStudyMode = .quiz
        selectedQuizAnswerIndex = answerIndex
        hasSubmittedCurrentQuizAnswer = true

        if answerIndex == question.correctAnswerIndex {
            markQuizQuestionCompleted(question.id)
            markModeCompleted(.quiz)
            lastStatusMessage = "Correct. \(question.title) reviewed."
        } else {
            lastStatusMessage = "Keep going. Review the explanation and try the next prompt."
        }
    }

    func advanceQuiz() {
        let questions = selectedOrgan.quizQuestions
        guard !questions.isEmpty else { return }
        activeQuizQuestionIndex = (activeQuizQuestionIndex + 1) % questions.count
        selectedQuizAnswerIndex = nil
        hasSubmittedCurrentQuizAnswer = false
        isLearnMorePresented = false
        selectedAnnotationID = nil
    }

    private func markAnnotationViewed(_ annotationID: String) {
        var progress = organProgressByID[selectedOrganID] ?? OrganProgress()
        progress.markAnnotationViewed(annotationID)
        organProgressByID[selectedOrganID] = progress
        persistProgress()
    }

    private func markQuizQuestionCompleted(_ questionID: String) {
        var progress = organProgressByID[selectedOrganID] ?? OrganProgress()
        progress.markQuizQuestionCompleted(questionID)
        organProgressByID[selectedOrganID] = progress
        persistProgress()
    }

    private func markModeCompleted(_ mode: StudyMode) {
        var progress = organProgressByID[selectedOrganID] ?? OrganProgress()
        progress.markModeCompleted(mode)
        organProgressByID[selectedOrganID] = progress
        persistProgress()
    }

    private func persistProgress() {
        let payload = PersistedProgress(organProgressByID: organProgressByID)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        UserDefaults.standard.set(data, forKey: progressStorageKey)
    }

    private func restoreProgress() {
        guard
            let data = UserDefaults.standard.data(forKey: progressStorageKey),
            let payload = try? JSONDecoder().decode(PersistedProgress.self, from: data)
        else {
            return
        }

        organProgressByID = payload.organProgressByID
    }
}
