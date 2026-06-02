//
//  EducationalContent.swift
//  Anatomy
//
//  Learn Mode content model. Each organ has a structured lesson (Overview, Anatomy,
//  Functionality, Real-World, Summary). Illustrations are referenced via AssetSlot
//  so they render as placeholders until artwork is added.
//
//  Phase 1: scaffold + starter content for Heart and Brain. Phase 2 expands the copy.
//
//  Created by Bobur Toshpulatov.
//

import Foundation

struct LessonSection: Identifiable, Hashable {
    let id = UUID()
    let heading: String
    let body: String
}

struct AnatomySection: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let blurb: String
    let labels: [String]
    let image: AssetSlot
}

struct FunctionTopic: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let explanation: String
    let symbol: String
    let image: AssetSlot?
}

struct RealWorldNote: Identifiable, Hashable {
    let id = UUID()
    let scenario: String
    let explanation: String
    let image: AssetSlot?
}

struct OrganLesson: Hashable {
    let organID: String
    let overview: LessonSection
    let anatomy: [AnatomySection]
    let functions: [FunctionTopic]
    let realWorld: [RealWorldNote]
    let summary: [String]

    /// Section names for the Learn Mode navigation rail.
    enum Section: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case anatomy = "Anatomy"
        case functionality = "Functionality"
        case realWorld = "Real-World"
        case summary = "Summary"
        var id: String { rawValue }
        var symbol: String {
            switch self {
            case .overview: "book"
            case .anatomy: "square.stack.3d.up"
            case .functionality: "bolt.heart"
            case .realWorld: "globe"
            case .summary: "checkmark.seal"
            }
        }
    }
}

extension OrganLesson {
    static func lesson(for organID: String) -> OrganLesson? {
        switch organID {
        case "heart": return heart
        case "brain": return brain
        default:      return nil
        }
    }

    // MARK: - Heart

    static let heart = OrganLesson(
        organID: "heart",
        overview: LessonSection(
            heading: "What is the heart?",
            body: "The heart is a four-chambered muscular pump about the size of a closed fist, sitting just left of centre in the chest. Beating roughly 100,000 times a day, it drives two linked circuits: the pulmonary circuit that sends blood to the lungs for oxygen, and the systemic circuit that delivers oxygen-rich blood to every tissue. If the heart stops, oxygen delivery halts within seconds — which is why its rhythm and coordination are so vital."
        ),
        anatomy: [
            AnatomySection(
                name: "Chambers",
                blurb: "Two atria receive blood; two ventricles pump it out. The right side handles deoxygenated blood; the left side, oxygenated.",
                labels: ["Right atrium", "Right ventricle", "Left atrium", "Left ventricle"],
                image: AssetSlot("heart_chambers", caption: "Heart chambers", symbol: "square.split.2x2")
            ),
            AnatomySection(
                name: "Valves",
                blurb: "Four valves keep blood moving one way: tricuspid, pulmonary, mitral, and aortic.",
                labels: ["Tricuspid", "Pulmonary", "Mitral", "Aortic"],
                image: AssetSlot("heart_valves", caption: "Heart valves", symbol: "arrow.triangle.merge")
            ),
            AnatomySection(
                name: "Major vessels",
                blurb: "The aorta carries blood to the body; the vena cavae return it; the pulmonary vessels link to the lungs.",
                labels: ["Aorta", "Superior vena cava", "Pulmonary artery", "Pulmonary veins"],
                image: AssetSlot("heart_vessels", caption: "Great vessels", symbol: "point.topleft.down.curvedto.point.bottomright.up")
            )
        ],
        functions: [
            FunctionTopic(title: "Blood circulation", explanation: "Each beat pushes blood through the pulmonary and systemic circuits, completing a full loop of the body in under a minute.", symbol: "arrow.triangle.2.circlepath", image: AssetSlot("heart_circulation", caption: "Circulation loop", symbol: "arrow.triangle.2.circlepath")),
            FunctionTopic(title: "Oxygen transport", explanation: "Oxygen picked up in the lungs is carried by red blood cells and delivered to tissues that need it to release energy.", symbol: "lungs.fill", image: nil),
            FunctionTopic(title: "Electrical system", explanation: "The SA node fires the heartbeat; the signal spreads through the AV node and conduction pathways to coordinate contraction.", symbol: "waveform.path.ecg", image: AssetSlot("heart_conduction", caption: "Conduction system", symbol: "waveform.path.ecg")),
            FunctionTopic(title: "Blood pressure", explanation: "Rhythmic contraction generates the pressure that keeps blood flowing against resistance throughout the vessels.", symbol: "gauge.with.dots.needle.bottom.50percent", image: nil)
        ],
        realWorld: [
            RealWorldNote(scenario: "Exercise", explanation: "During exercise the heart rate and stroke volume rise, delivering more oxygen to working muscles.", image: nil),
            RealWorldNote(scenario: "Stress", explanation: "Adrenaline speeds the heart and raises blood pressure as part of the fight-or-flight response.", image: nil),
            RealWorldNote(scenario: "Heart attack", explanation: "A blocked coronary artery starves heart muscle of oxygen, damaging tissue — the basis of a myocardial infarction.", image: AssetSlot("heart_attack", caption: "Coronary blockage", symbol: "bolt.heart"))
        ],
        summary: [
            "Four chambers: two atria, two ventricles.",
            "Right side → lungs; left side → body.",
            "Four valves enforce one-way flow.",
            "The SA node sets the rhythm.",
            "Beats ~100,000 times a day."
        ]
    )

    // MARK: - Brain

    static let brain = OrganLesson(
        organID: "brain",
        overview: LessonSection(
            heading: "What is the brain?",
            body: "The brain is the control centre of the nervous system — roughly 1.4 kg of tissue containing around 86 billion neurons. Housed in the skull and cushioned by fluid, it integrates sensory information, directs movement, stores memory, and governs thought, language, and emotion. Different regions specialise in different jobs, yet work together as a network. Damage to a region produces predictable, localised effects."
        ),
        anatomy: [
            AnatomySection(
                name: "Cerebral lobes",
                blurb: "The cerebrum's four lobes handle planning, sensation, hearing/memory, and vision.",
                labels: ["Frontal", "Parietal", "Temporal", "Occipital"],
                image: AssetSlot("brain_lobes", caption: "Cerebral lobes", symbol: "square.stack.3d.up")
            ),
            AnatomySection(
                name: "Cerebellum",
                blurb: "Sitting at the back, the cerebellum fine-tunes balance, coordination, and precise movement.",
                labels: ["Cerebellum"],
                image: AssetSlot("brain_cerebellum", caption: "Cerebellum", symbol: "figure.walk")
            ),
            AnatomySection(
                name: "Brainstem",
                blurb: "The brainstem relays signals and controls automatic functions like breathing and heart rate.",
                labels: ["Midbrain", "Pons", "Medulla"],
                image: AssetSlot("brain_brainstem", caption: "Brainstem", symbol: "point.3.connected.trianglepath.dotted")
            )
        ],
        functions: [
            FunctionTopic(title: "Memory", explanation: "The hippocampus and cortex encode, store, and retrieve memories that shape learning.", symbol: "brain", image: AssetSlot("brain_memory", caption: "Memory pathways", symbol: "brain")),
            FunctionTopic(title: "Movement", explanation: "The motor cortex plans and commands voluntary movement, refined by the cerebellum.", symbol: "figure.walk", image: nil),
            FunctionTopic(title: "Sensory processing", explanation: "Incoming signals from the senses are mapped and interpreted across dedicated cortical areas.", symbol: "eye.fill", image: nil),
            FunctionTopic(title: "Language & emotion", explanation: "Language centres and the limbic system support communication and emotional response.", symbol: "text.bubble", image: nil)
        ],
        realWorld: [
            RealWorldNote(scenario: "Learning", explanation: "Repeated practice strengthens synaptic connections — the physical basis of learning a new skill.", image: nil),
            RealWorldNote(scenario: "Sleep", explanation: "During sleep the brain consolidates memories and clears metabolic waste.", image: AssetSlot("brain_sleep", caption: "Sleep & memory", symbol: "moon.zzz")),
            RealWorldNote(scenario: "Decision making", explanation: "The frontal lobe weighs options, predicts outcomes, and inhibits impulses.", image: nil)
        ],
        summary: [
            "~86 billion neurons coordinate the body.",
            "Four cerebral lobes, each specialised.",
            "Cerebellum → balance and coordination.",
            "Brainstem → automatic vital functions.",
            "Regions specialise but work as a network."
        ]
    )
}
