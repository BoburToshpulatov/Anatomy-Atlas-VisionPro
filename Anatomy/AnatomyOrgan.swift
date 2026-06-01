//
//  AnatomyOrgan.swift
//  Anatomy
//
//  Created by Bobur Toshpulatov on 23/05/26.
//

import SwiftUI

struct AnatomyOrgan: Identifiable, Hashable {
    enum PulseStyle: Hashable {
        case heartbeat
        case neural
    }

    enum ViewerAngle: String, Hashable {
        case front
        case frontLeft
        case frontRight
        case rear
    }

    struct AnnotationPlacement {
        let anchor: CGPoint
        let side: OrganAnnotation.Side
        let lane: CGFloat
    }

    struct ViewerLayout {
        let heroPosition: SIMD3<Float>
        let labelsPosition: SIMD3<Float>
        let panelPosition: SIMD3<Float>
        let panelWidth: CGFloat
        let carouselPosition: SIMD3<Float>
        let heroYawOffset: Double
        let heroPitchOffset: Double
        let heroVisualOffset: CGSize
        let labelLeftX: CGFloat
        let labelRightX: CGFloat
        let labelWidth: CGFloat
        let labelSelectedZ: CGFloat
        let labelRestZ: CGFloat
        let annotationPlacements: [String: AnnotationPlacement]

        func placement(for note: OrganAnnotation) -> AnnotationPlacement {
            annotationPlacements[note.id] ?? AnnotationPlacement(
                anchor: note.anchor,
                side: note.side,
                lane: note.lane
            )
        }
    }

    struct ImmersivePreset: Hashable {
        let heroX: CGFloat
        let heroY: CGFloat
        let heroZ: CGFloat
        let stageWidth: CGFloat
        let stageHeight: CGFloat
        let panelX: CGFloat
        let panelY: CGFloat
        let panelZ: CGFloat
        let panelWidth: CGFloat
        let carouselY: CGFloat
        let carouselZ: CGFloat
        let carouselScale: CGFloat
        let labelLeftX: CGFloat
        let labelRightX: CGFloat
        let labelWidth: CGFloat
        let labelSelectedZ: CGFloat
        let labelRestZ: CGFloat
        let floorGlowWidth: CGFloat
        let floorGlowHeight: CGFloat
    }

    let id: String
    let title: String
    let tagline: String
    let shortDescription: String
    let description: String
    let studyPrompt: String
    let functions: [String]
    let keyParts: [String]
    let symbolName: String
    let modelName: String
    let tint: Color
    let heroScale: CGFloat
    let heroOffset: CGSize
    let baseYaw: Double
    let basePitch: Double
    let glowScale: CGFloat
    let pulseStyle: PulseStyle
    let immersivePreset: ImmersivePreset
    let atlasNotes: [OrganAnnotation]
}

struct OrganAnnotation: Identifiable, Hashable {
    enum Side: Hashable {
        case left
        case right
    }

    let id: String
    let title: String
    let subtitle: String
    let detail: String
    let anchor: CGPoint
    let side: Side
    let lane: CGFloat
    let focusYaw: Double
    let focusPitch: Double
    let focusScale: CGFloat
    let focusOffset: CGSize
}

struct OrganQuizQuestion: Identifiable, Hashable {
    let id: String
    let title: String
    let prompt: String
    let answers: [String]
    let correctAnswerIndex: Int
    let hint: String
    let explanation: String
}

extension AnatomyOrgan {
    var hasBundledModel: Bool {
        switch id {
        case "heart", "brain":
            return true
        default:
            return false
        }
    }

    var modelAvailabilityText: String? {
        hasBundledModel ? nil : "Model coming soon"
    }

    /// SF Symbols paired with each entry in `functions`, for the panel's Key Functions list.
    var functionSymbols: [String] {
        switch id {
        case "heart":
            return ["drop.fill", "waveform.path.ecg", "lungs.fill"]
        case "brain":
            return ["eye.fill", "figure.walk", "lightbulb.fill"]
        default:
            return []
        }
    }

    static let launcherFeatured: [AnatomyOrgan] = featured.filter { organ in
        ["heart", "brain"].contains(organ.id)
    }

    static let featured: [AnatomyOrgan] = [
        AnatomyOrgan(
            id: "heart",
            title: "Heart",
            tagline: "Circulation",
            shortDescription: "Pumps oxygenated blood through the body with coordinated electrical rhythm.",
            description: "The heart is a four-chambered muscular pump that keeps blood moving through the pulmonary and systemic circuits.",
            studyPrompt: "Track chamber flow, valve timing, and the path of electrical conduction.",
            functions: [
                "Circulates oxygen and nutrients to tissues.",
                "Maintains blood pressure through rhythmic contraction.",
                "Supports gas exchange by sending blood to the lungs."
            ],
            keyParts: [
                "Right atrium and right ventricle",
                "Left atrium and left ventricle",
                "Aortic, mitral, pulmonary, and tricuspid valves",
                "Septum, coronary vessels, and conduction pathways"
            ],
            symbolName: "heart.fill",
            modelName: "Human_Heart.usdz",
            tint: Color(red: 0.93, green: 0.28, blue: 0.35),
            heroScale: 0.92,
            heroOffset: CGSize(width: 10, height: 210),
            baseYaw: -6,
            basePitch: -12,
            glowScale: 1.0,
            pulseStyle: .heartbeat,
            immersivePreset: ImmersivePreset(
                heroX: 0,
                heroY: 24,
                heroZ: 212,
                stageWidth: 2060,
                stageHeight: 1460,
                panelX: 736,
                panelY: 16,
                panelZ: 238,
                panelWidth: 592,
                carouselY: 158,
                carouselZ: 198,
                carouselScale: 1.12,
                labelLeftX: 0.08,
                labelRightX: 0.88,
                labelWidth: 310,
                labelSelectedZ: 92,
                labelRestZ: 32,
                floorGlowWidth: 620,
                floorGlowHeight: 156
            ),
            atlasNotes: [
                OrganAnnotation(
                    id: "heart-aorta",
                    title: "Aorta",
                    subtitle: "Systemic outflow",
                    detail: "The aorta carries oxygen-rich blood from the left ventricle to the body under the highest arterial pressure in the circulation.",
                    anchor: CGPoint(x: 0.58, y: 0.19),
                    side: .right,
                    lane: 0.10,
                    focusYaw: -16,
                    focusPitch: -8,
                    focusScale: 1.28,
                    focusOffset: CGSize(width: 26, height: 4)
                ),
                OrganAnnotation(
                    id: "heart-pulmonary-artery",
                    title: "Pulmonary Artery",
                    subtitle: "Route to the lungs",
                    detail: "The pulmonary trunk and arteries carry deoxygenated blood from the right ventricle to the lungs for gas exchange.",
                    anchor: CGPoint(x: 0.63, y: 0.34),
                    side: .right,
                    lane: 0.27,
                    focusYaw: -10,
                    focusPitch: -7,
                    focusScale: 1.24,
                    focusOffset: CGSize(width: 24, height: 2)
                ),
                OrganAnnotation(
                    id: "heart-left-atrium",
                    title: "Left Atrium",
                    subtitle: "Receives oxygenated blood",
                    detail: "The left atrium receives oxygen-rich blood returning from the pulmonary veins and primes the left ventricle.",
                    anchor: CGPoint(x: 0.67, y: 0.50),
                    side: .right,
                    lane: 0.47,
                    focusYaw: -18,
                    focusPitch: -4,
                    focusScale: 1.22,
                    focusOffset: CGSize(width: 28, height: -6)
                ),
                OrganAnnotation(
                    id: "heart-left-ventricle",
                    title: "Left Ventricle",
                    subtitle: "Main pressure chamber",
                    detail: "The left ventricle has the thickest wall and generates the force needed to drive blood through the systemic circuit.",
                    anchor: CGPoint(x: 0.61, y: 0.74),
                    side: .right,
                    lane: 0.70,
                    focusYaw: -8,
                    focusPitch: 6,
                    focusScale: 1.30,
                    focusOffset: CGSize(width: 18, height: -18)
                ),
                OrganAnnotation(
                    id: "heart-svc",
                    title: "Superior Vena Cava",
                    subtitle: "Upper body return",
                    detail: "The superior vena cava returns deoxygenated blood from the head, neck, and upper limbs into the right atrium.",
                    anchor: CGPoint(x: 0.37, y: 0.23),
                    side: .left,
                    lane: 0.16,
                    focusYaw: 14,
                    focusPitch: -8,
                    focusScale: 1.22,
                    focusOffset: CGSize(width: -18, height: 0)
                ),
                OrganAnnotation(
                    id: "heart-right-atrium",
                    title: "Right Atrium",
                    subtitle: "Venous receiving chamber",
                    detail: "The right atrium collects systemic venous blood and directs it across the tricuspid valve into the right ventricle.",
                    anchor: CGPoint(x: 0.33, y: 0.49),
                    side: .left,
                    lane: 0.44,
                    focusYaw: 18,
                    focusPitch: -2,
                    focusScale: 1.20,
                    focusOffset: CGSize(width: -22, height: -4)
                ),
                OrganAnnotation(
                    id: "heart-tricuspid",
                    title: "Tricuspid Valve",
                    subtitle: "Right AV valve",
                    detail: "The tricuspid valve prevents backflow into the right atrium when the right ventricle contracts.",
                    anchor: CGPoint(x: 0.40, y: 0.62),
                    side: .left,
                    lane: 0.62,
                    focusYaw: 16,
                    focusPitch: 6,
                    focusScale: 1.28,
                    focusOffset: CGSize(width: -10, height: -12)
                ),
                OrganAnnotation(
                    id: "heart-right-ventricle",
                    title: "Right Ventricle",
                    subtitle: "Pulmonary pump",
                    detail: "The right ventricle sends blood through the pulmonary valve and into the pulmonary arteries toward the lungs.",
                    anchor: CGPoint(x: 0.42, y: 0.77),
                    side: .left,
                    lane: 0.78,
                    focusYaw: 12,
                    focusPitch: 8,
                    focusScale: 1.30,
                    focusOffset: CGSize(width: -12, height: -18)
                )
            ]
        ),
        AnatomyOrgan(
            id: "brain",
            title: "Brain",
            tagline: "Neural Control",
            shortDescription: "Coordinates sensation, movement, memory, and autonomic regulation.",
            description: "The brain is the command center of the nervous system, integrating signals and directing cognitive and bodily functions.",
            studyPrompt: "Compare cortical regions, subcortical hubs, and the brainstem relay network.",
            functions: [
                "Processes sensory input and shapes perception.",
                "Coordinates voluntary movement and balance.",
                "Supports memory, emotion, language, and executive function."
            ],
            keyParts: [
                "Frontal, parietal, temporal, and occipital lobes",
                "Cerebellum and brainstem",
                "Thalamus, hypothalamus, and limbic structures",
                "Cerebral hemispheres and cortical folds"
            ],
            symbolName: "brain.head.profile",
            modelName: "Human_Brain.usdz",
            tint: Color(red: 0.23, green: 0.71, blue: 0.98),
            heroScale: 1.03,
            heroOffset: CGSize(width: -4, height: -8),
            baseYaw: 10,
            basePitch: -6,
            glowScale: 1.18,
            pulseStyle: .neural,
            immersivePreset: ImmersivePreset(
                heroX: 0,
                heroY: -8,
                heroZ: 214,
                stageWidth: 2100,
                stageHeight: 1480,
                panelX: 740,
                panelY: 2,
                panelZ: 240,
                panelWidth: 596,
                carouselY: 160,
                carouselZ: 198,
                carouselScale: 1.10,
                labelLeftX: 0.09,
                labelRightX: 0.90,
                labelWidth: 278,
                labelSelectedZ: 90,
                labelRestZ: 30,
                floorGlowWidth: 650,
                floorGlowHeight: 164
            ),
            atlasNotes: [
                OrganAnnotation(
                    id: "brain-frontal",
                    title: "Frontal Lobe",
                    subtitle: "Planning and control",
                    detail: "Supports executive function, voluntary movement planning, working memory, and decision making.",
                    anchor: CGPoint(x: 0.67, y: 0.39),
                    side: .right,
                    lane: 0.28,
                    focusYaw: -14,
                    focusPitch: -4,
                    focusScale: 1.18,
                    focusOffset: CGSize(width: 16, height: -4)
                ),
                OrganAnnotation(
                    id: "brain-parietal",
                    title: "Parietal Lobe",
                    subtitle: "Spatial integration",
                    detail: "Integrates touch, body position, and spatial awareness to help orient the body in space.",
                    anchor: CGPoint(x: 0.55, y: 0.27),
                    side: .right,
                    lane: 0.14,
                    focusYaw: -6,
                    focusPitch: -10,
                    focusScale: 1.16,
                    focusOffset: CGSize(width: 8, height: 2)
                ),
                OrganAnnotation(
                    id: "brain-temporal",
                    title: "Temporal Lobe",
                    subtitle: "Language and memory",
                    detail: "Contributes to auditory processing, language comprehension, and memory encoding.",
                    anchor: CGPoint(x: 0.63, y: 0.60),
                    side: .right,
                    lane: 0.55,
                    focusYaw: -18,
                    focusPitch: 2,
                    focusScale: 1.18,
                    focusOffset: CGSize(width: 18, height: -6)
                ),
                OrganAnnotation(
                    id: "brain-cerebellum",
                    title: "Cerebellum",
                    subtitle: "Precision and balance",
                    detail: "Refines movement timing, balance, and motor learning by coordinating signals from the cortex and spinal pathways.",
                    anchor: CGPoint(x: 0.33, y: 0.68),
                    side: .left,
                    lane: 0.62,
                    focusYaw: 20,
                    focusPitch: 8,
                    focusScale: 1.16,
                    focusOffset: CGSize(width: -18, height: -12)
                ),
                OrganAnnotation(
                    id: "brain-brainstem",
                    title: "Brainstem",
                    subtitle: "Autonomic relay",
                    detail: "Regulates core autonomic functions such as breathing, heart rate, and arousal while linking brain and spinal cord.",
                    anchor: CGPoint(x: 0.40, y: 0.78),
                    side: .left,
                    lane: 0.80,
                    focusYaw: 12,
                    focusPitch: 12,
                    focusScale: 1.20,
                    focusOffset: CGSize(width: -8, height: -18)
                )
            ]
        ),
        AnatomyOrgan(
            id: "lungs",
            title: "Lungs",
            tagline: "Respiration",
            shortDescription: "Exchange oxygen and carbon dioxide across millions of alveoli.",
            description: "The lungs bring oxygen into the bloodstream and remove carbon dioxide through an intricate branching airway and alveolar network.",
            studyPrompt: "Explore airway branching, pleural surfaces, and gas exchange regions.",
            functions: [
                "Oxygenates blood through alveolar exchange.",
                "Removes carbon dioxide during exhalation.",
                "Supports acid-base regulation through ventilation."
            ],
            keyParts: [
                "Right and left lungs",
                "Bronchi, bronchioles, and alveoli",
                "Pleura and pleural cavity",
                "Pulmonary vessels and lobes"
            ],
            symbolName: "lungs.fill",
            modelName: "Human_Lungs.usdz",
            tint: Color(red: 0.46, green: 0.71, blue: 0.96),
            heroScale: 0.98,
            heroOffset: CGSize(width: 0, height: 8),
            baseYaw: -4,
            basePitch: -6,
            glowScale: 1.08,
            pulseStyle: .neural,
            immersivePreset: ImmersivePreset(
                heroX: -26, heroY: 18, heroZ: 168, stageWidth: 1600, stageHeight: 1040,
                panelX: 72, panelY: 16, panelZ: 220, panelWidth: 420,
                carouselY: 82, carouselZ: 112, carouselScale: 1.0,
                labelLeftX: 0.06, labelRightX: 0.88, labelWidth: 232,
                labelSelectedZ: 74, labelRestZ: 20, floorGlowWidth: 470, floorGlowHeight: 120
            ),
            atlasNotes: []
        ),
        AnatomyOrgan(
            id: "liver",
            title: "Liver",
            tagline: "Metabolism",
            shortDescription: "Filters blood, processes nutrients, and produces bile.",
            description: "The liver is a central metabolic organ that detoxifies blood, stores glycogen, and supports digestion through bile production.",
            studyPrompt: "Study lobes, vascular inflow, and the biliary drainage network.",
            functions: [
                "Filters blood from the digestive tract.",
                "Stores glycogen and processes nutrients.",
                "Produces bile for fat digestion."
            ],
            keyParts: [
                "Right and left lobes",
                "Portal triad",
                "Hepatic veins",
                "Gallbladder and bile ducts"
            ],
            symbolName: "cross.case.fill",
            modelName: "Human_Liver.usdz",
            tint: Color(red: 0.79, green: 0.35, blue: 0.21),
            heroScale: 0.94,
            heroOffset: CGSize(width: 0, height: 18),
            baseYaw: -10,
            basePitch: -8,
            glowScale: 0.96,
            pulseStyle: .heartbeat,
            immersivePreset: ImmersivePreset(
                heroX: -20, heroY: 28, heroZ: 164, stageWidth: 1560, stageHeight: 1020,
                panelX: 72, panelY: 24, panelZ: 218, panelWidth: 418,
                carouselY: 82, carouselZ: 112, carouselScale: 1.0,
                labelLeftX: 0.07, labelRightX: 0.89, labelWidth: 228,
                labelSelectedZ: 72, labelRestZ: 20, floorGlowWidth: 440, floorGlowHeight: 112
            ),
            atlasNotes: []
        ),
        AnatomyOrgan(
            id: "kidneys",
            title: "Kidneys",
            tagline: "Filtration",
            shortDescription: "Filter blood, balance fluids, and help regulate blood pressure.",
            description: "The kidneys maintain fluid and electrolyte balance while filtering blood and producing urine through the nephron network.",
            studyPrompt: "Review cortex, medulla, renal vessels, and urine outflow pathways.",
            functions: [
                "Filters waste from the bloodstream.",
                "Balances water, salts, and pH.",
                "Supports blood pressure regulation."
            ],
            keyParts: [
                "Renal cortex and medulla",
                "Nephrons",
                "Renal artery and vein",
                "Ureters and renal pelvis"
            ],
            symbolName: "drop.circle.fill",
            modelName: "Human_Kidneys.usdz",
            tint: Color(red: 0.64, green: 0.32, blue: 0.64),
            heroScale: 0.98,
            heroOffset: CGSize(width: 0, height: 14),
            baseYaw: 8,
            basePitch: -6,
            glowScale: 1.04,
            pulseStyle: .neural,
            immersivePreset: ImmersivePreset(
                heroX: -18, heroY: 16, heroZ: 166, stageWidth: 1600, stageHeight: 1040,
                panelX: 74, panelY: 18, panelZ: 220, panelWidth: 420,
                carouselY: 82, carouselZ: 112, carouselScale: 1.0,
                labelLeftX: 0.06, labelRightX: 0.88, labelWidth: 232,
                labelSelectedZ: 74, labelRestZ: 20, floorGlowWidth: 450, floorGlowHeight: 116
            ),
            atlasNotes: []
        ),
        AnatomyOrgan(
            id: "stomach",
            title: "Stomach",
            tagline: "Digestion",
            shortDescription: "Mixes food with acid and enzymes for early digestion.",
            description: "The stomach stores food temporarily and begins protein digestion with muscular mixing and acidic gastric secretions.",
            studyPrompt: "Inspect curvature landmarks, sphincters, and the layered muscular wall.",
            functions: [
                "Stores food after swallowing.",
                "Begins protein digestion.",
                "Mixes contents into chyme for the small intestine."
            ],
            keyParts: [
                "Fundus and body",
                "Greater and lesser curvature",
                "Cardiac and pyloric sphincters",
                "Rugae and gastric wall layers"
            ],
            symbolName: "takeoutbag.and.cup.and.straw.fill",
            modelName: "Human_Stomach.usdz",
            tint: Color(red: 0.92, green: 0.49, blue: 0.60),
            heroScale: 0.96,
            heroOffset: CGSize(width: 0, height: 16),
            baseYaw: -12,
            basePitch: -8,
            glowScale: 1.02,
            pulseStyle: .heartbeat,
            immersivePreset: ImmersivePreset(
                heroX: -18, heroY: 22, heroZ: 164, stageWidth: 1560, stageHeight: 1020,
                panelX: 74, panelY: 20, panelZ: 218, panelWidth: 418,
                carouselY: 84, carouselZ: 110, carouselScale: 1.0,
                labelLeftX: 0.07, labelRightX: 0.88, labelWidth: 230,
                labelSelectedZ: 72, labelRestZ: 18, floorGlowWidth: 438, floorGlowHeight: 112
            ),
            atlasNotes: []
        ),
        AnatomyOrgan(
            id: "skeleton",
            title: "Skeleton",
            tagline: "Framework",
            shortDescription: "Provides structure, protection, and leverage for movement.",
            description: "The skeleton supports the body, protects vital organs, and works with muscles to create movement while storing minerals.",
            studyPrompt: "Explore axial versus appendicular anatomy and major structural landmarks.",
            functions: [
                "Supports posture and body structure.",
                "Protects organs such as the brain and thorax.",
                "Stores minerals and houses marrow."
            ],
            keyParts: [
                "Skull and vertebral column",
                "Rib cage and sternum",
                "Pelvis and limb bones",
                "Joints and marrow cavities"
            ],
            symbolName: "figure.stand",
            modelName: "Human_Skeleton.usdz",
            tint: Color(red: 0.84, green: 0.84, blue: 0.90),
            heroScale: 1.04,
            heroOffset: CGSize(width: 0, height: -2),
            baseYaw: 6,
            basePitch: -4,
            glowScale: 1.10,
            pulseStyle: .neural,
            immersivePreset: ImmersivePreset(
                heroX: -8, heroY: 2, heroZ: 168, stageWidth: 1660, stageHeight: 1100,
                panelX: 78, panelY: 12, panelZ: 220, panelWidth: 426,
                carouselY: 86, carouselZ: 112, carouselScale: 1.02,
                labelLeftX: 0.08, labelRightX: 0.86, labelWidth: 236,
                labelSelectedZ: 72, labelRestZ: 18, floorGlowWidth: 520, floorGlowHeight: 128
            ),
            atlasNotes: []
        ),
        AnatomyOrgan(
            id: "eye",
            title: "Eye",
            tagline: "Vision",
            shortDescription: "Captures light and converts it into neural signals for visual processing.",
            description: "The eye focuses light through the cornea and lens, then transforms it into neural signals within the retina.",
            studyPrompt: "Review the optical pathway from cornea to retina and trace visual signal transfer to the brain.",
            functions: [
                "Focuses incoming light onto the retina.",
                "Adapts to brightness and supports color vision.",
                "Sends visual information through the optic nerve."
            ],
            keyParts: [
                "Cornea and lens",
                "Iris and pupil",
                "Retina and macula",
                "Optic nerve"
            ],
            symbolName: "eye.fill",
            modelName: "Human_Eye.usdz",
            tint: Color(red: 0.37, green: 0.75, blue: 0.96),
            heroScale: 0.94,
            heroOffset: CGSize(width: 0, height: 0),
            baseYaw: 0,
            basePitch: -4,
            glowScale: 0.96,
            pulseStyle: .neural,
            immersivePreset: ImmersivePreset(
                heroX: 0, heroY: 10, heroZ: 160, stageWidth: 1520, stageHeight: 980,
                panelX: 78, panelY: 12, panelZ: 218, panelWidth: 440,
                carouselY: 84, carouselZ: 110, carouselScale: 1.0,
                labelLeftX: 0.08, labelRightX: 0.88, labelWidth: 230,
                labelSelectedZ: 70, labelRestZ: 18, floorGlowWidth: 420, floorGlowHeight: 108
            ),
            atlasNotes: []
        ),
        AnatomyOrgan(
            id: "ear",
            title: "Ear",
            tagline: "Hearing",
            shortDescription: "Transforms sound vibrations into neural signals and helps maintain balance.",
            description: "The ear receives sound, amplifies it through the middle ear, and converts vibration into neural activity within the inner ear.",
            studyPrompt: "Compare outer, middle, and inner ear anatomy while tracing hearing and vestibular pathways.",
            functions: [
                "Collects and channels sound waves.",
                "Amplifies vibration through ossicles.",
                "Supports hearing and balance."
            ],
            keyParts: [
                "Auricle and ear canal",
                "Tympanic membrane",
                "Ossicles",
                "Cochlea and vestibular system"
            ],
            symbolName: "ear.fill",
            modelName: "Human_Ear.usdz",
            tint: Color(red: 0.45, green: 0.69, blue: 0.92),
            heroScale: 0.92,
            heroOffset: CGSize(width: 0, height: 4),
            baseYaw: 8,
            basePitch: -5,
            glowScale: 0.94,
            pulseStyle: .neural,
            immersivePreset: ImmersivePreset(
                heroX: 0, heroY: 12, heroZ: 160, stageWidth: 1500, stageHeight: 980,
                panelX: 78, panelY: 12, panelZ: 218, panelWidth: 438,
                carouselY: 84, carouselZ: 110, carouselScale: 1.0,
                labelLeftX: 0.08, labelRightX: 0.88, labelWidth: 230,
                labelSelectedZ: 70, labelRestZ: 18, floorGlowWidth: 418, floorGlowHeight: 108
            ),
            atlasNotes: []
        ),
        AnatomyOrgan(
            id: "spine",
            title: "Spine",
            tagline: "Support",
            shortDescription: "Supports posture, protects the spinal cord, and enables flexible movement.",
            description: "The vertebral column supports the body, protects the spinal cord, and transmits load through a segmented mobile axis.",
            studyPrompt: "Survey cervical, thoracic, lumbar, sacral, and coccygeal regions with their major curvatures.",
            functions: [
                "Supports upright posture.",
                "Protects the spinal cord.",
                "Enables flexible trunk movement."
            ],
            keyParts: [
                "Cervical vertebrae",
                "Thoracic vertebrae",
                "Lumbar vertebrae",
                "Sacrum and coccyx"
            ],
            symbolName: "figure.walk.motion",
            modelName: "Human_Spine.usdz",
            tint: Color(red: 0.79, green: 0.80, blue: 0.88),
            heroScale: 1.0,
            heroOffset: CGSize(width: 0, height: -2),
            baseYaw: 4,
            basePitch: -4,
            glowScale: 1.00,
            pulseStyle: .neural,
            immersivePreset: ImmersivePreset(
                heroX: 0, heroY: 0, heroZ: 166, stageWidth: 1640, stageHeight: 1080,
                panelX: 80, panelY: 14, panelZ: 220, panelWidth: 448,
                carouselY: 86, carouselZ: 112, carouselScale: 1.0,
                labelLeftX: 0.08, labelRightX: 0.86, labelWidth: 236,
                labelSelectedZ: 72, labelRestZ: 18, floorGlowWidth: 450, floorGlowHeight: 116
            ),
            atlasNotes: []
        ),
        AnatomyOrgan(
            id: "intestines",
            title: "Intestines",
            tagline: "Absorption",
            shortDescription: "Absorb nutrients, reclaim water, and move waste through the digestive tract.",
            description: "The intestines continue digestion, absorb nutrients and water, and coordinate transit through small and large bowel loops.",
            studyPrompt: "Compare small and large intestine regions and follow nutrient absorption through the gut wall.",
            functions: [
                "Absorbs nutrients in the small intestine.",
                "Reclaims water and electrolytes.",
                "Moves and compacts digestive waste."
            ],
            keyParts: [
                "Duodenum, jejunum, ileum",
                "Cecum and colon",
                "Mesentery",
                "Rectum"
            ],
            symbolName: "waveform.path.ecg.rectangle",
            modelName: "Human_Intestines.usdz",
            tint: Color(red: 0.92, green: 0.60, blue: 0.47),
            heroScale: 0.96,
            heroOffset: CGSize(width: 0, height: 14),
            baseYaw: -8,
            basePitch: -6,
            glowScale: 1.00,
            pulseStyle: .heartbeat,
            immersivePreset: ImmersivePreset(
                heroX: 0, heroY: 14, heroZ: 162, stageWidth: 1560, stageHeight: 1000,
                panelX: 78, panelY: 16, panelZ: 218, panelWidth: 442,
                carouselY: 84, carouselZ: 110, carouselScale: 1.0,
                labelLeftX: 0.08, labelRightX: 0.88, labelWidth: 232,
                labelSelectedZ: 70, labelRestZ: 18, floorGlowWidth: 430, floorGlowHeight: 110
            ),
            atlasNotes: []
        )
    ]

    var learnMoreTitle: String {
        selectedStructureFallback?.title ?? title
    }

    var learnMoreBody: String {
        selectedStructureFallback?.detail ?? description
    }

    var learnMoreHighlights: [String] {
        if let structure = selectedStructureFallback {
            return [
                structure.subtitle,
                "Tap related labels to compare nearby structures.",
                studyPrompt
            ]
        }

        return [
            shortDescription,
            studyPrompt,
            keyParts.first ?? title
        ]
    }

    var quizQuestions: [OrganQuizQuestion] {
        switch id {
        case "heart":
            return [
                OrganQuizQuestion(
                    id: "heart-quiz-aorta",
                    title: "Systemic outflow",
                    prompt: "Which heart structure carries oxygen-rich blood from the left ventricle into the systemic circuit?",
                    answers: ["Pulmonary artery", "Aorta", "Superior vena cava"],
                    correctAnswerIndex: 1,
                    hint: "Look for the large artery leaving the left ventricle at the top of the heart.",
                    explanation: "The aorta is the main systemic outflow vessel. It receives blood from the left ventricle and distributes it to the body."
                ),
                OrganQuizQuestion(
                    id: "heart-quiz-right-atrium",
                    title: "Venous return",
                    prompt: "Which chamber receives deoxygenated blood returning from the body?",
                    answers: ["Left atrium", "Right ventricle", "Right atrium"],
                    correctAnswerIndex: 2,
                    hint: "Trace systemic venous blood as it enters the heart before crossing the tricuspid valve.",
                    explanation: "The right atrium collects systemic venous blood before it passes through the tricuspid valve."
                ),
                OrganQuizQuestion(
                    id: "heart-quiz-left-ventricle",
                    title: "Pressure chamber",
                    prompt: "Which heart chamber generates the highest pressure for systemic circulation?",
                    answers: ["Left ventricle", "Right ventricle", "Left atrium"],
                    correctAnswerIndex: 0,
                    hint: "Choose the chamber with the thickest muscular wall that sends blood to the whole body.",
                    explanation: "The left ventricle has the thickest myocardium and provides the pressure needed to drive blood through the body."
                )
            ]
        case "brain":
            return [
                OrganQuizQuestion(
                    id: "brain-quiz-frontal",
                    title: "Executive control",
                    prompt: "Which brain region is most associated with planning, decision making, and voluntary movement control?",
                    answers: ["Temporal lobe", "Frontal lobe", "Cerebellum"],
                    correctAnswerIndex: 1,
                    hint: "Focus on the forward portion of the cerebral hemisphere behind the forehead.",
                    explanation: "The frontal lobe supports executive function, motor planning, and decision making."
                ),
                OrganQuizQuestion(
                    id: "brain-quiz-cerebellum",
                    title: "Precision and balance",
                    prompt: "Which structure helps refine movement timing and balance?",
                    answers: ["Brainstem", "Parietal lobe", "Cerebellum"],
                    correctAnswerIndex: 2,
                    hint: "Look below the posterior cerebrum for the tightly folded structure that fine-tunes movement.",
                    explanation: "The cerebellum coordinates fine movement, balance, and motor learning."
                ),
                OrganQuizQuestion(
                    id: "brain-quiz-brainstem",
                    title: "Autonomic relay",
                    prompt: "Which region links the brain and spinal cord while regulating breathing and arousal?",
                    answers: ["Brainstem", "Frontal lobe", "Parietal lobe"],
                    correctAnswerIndex: 0,
                    hint: "Find the narrow stalk-like region at the base of the brain.",
                    explanation: "The brainstem is the core relay for autonomic regulation and the pathway between brain and spinal cord."
                )
            ]
        default:
            return []
        }
    }

    private var selectedStructureFallback: OrganAnnotation? {
        atlasNotes.first
    }

    func viewerLayout(for angle: ViewerAngle) -> ViewerLayout {
        switch (id, angle) {
        case ("heart", .front):
            return ViewerLayout(
                heroPosition: SIMD3<Float>(0.0, 1.52, -1.80),
                labelsPosition: SIMD3<Float>(0.0, 1.52, -1.80),
                panelPosition: SIMD3<Float>(0.86, 1.54, -1.55),
                panelWidth: 820,
                carouselPosition: SIMD3<Float>(0.0, 1.04, -1.12),
                heroYawOffset: 0,
                heroPitchOffset: 0,
                heroVisualOffset: .zero,
                labelLeftX: 0.46,
                labelRightX: 0.40,
                labelWidth: 300,
                labelSelectedZ: 92,
                labelRestZ: 32,
                annotationPlacements: [
                    "heart-aorta": .init(anchor: CGPoint(x: 0.58, y: 0.19), side: .right, lane: 0.14),
                    "heart-pulmonary-artery": .init(anchor: CGPoint(x: 0.63, y: 0.34), side: .right, lane: 0.33),
                    "heart-left-atrium": .init(anchor: CGPoint(x: 0.67, y: 0.50), side: .right, lane: 0.53),
                    "heart-left-ventricle": .init(anchor: CGPoint(x: 0.61, y: 0.74), side: .right, lane: 0.74),
                    "heart-svc": .init(anchor: CGPoint(x: 0.37, y: 0.23), side: .left, lane: 0.16),
                    "heart-right-atrium": .init(anchor: CGPoint(x: 0.33, y: 0.49), side: .left, lane: 0.44),
                    "heart-tricuspid": .init(anchor: CGPoint(x: 0.40, y: 0.62), side: .left, lane: 0.62),
                    "heart-right-ventricle": .init(anchor: CGPoint(x: 0.42, y: 0.77), side: .left, lane: 0.80)
                ]
            )
        case ("heart", .frontRight):
            return ViewerLayout(
                heroPosition: SIMD3<Float>(0.03, 1.52, -1.80),
                labelsPosition: SIMD3<Float>(0.03, 1.52, -1.80),
                panelPosition: SIMD3<Float>(0.88, 1.54, -1.55),
                panelWidth: 812,
                carouselPosition: SIMD3<Float>(0.0, 1.04, -1.12),
                heroYawOffset: -22,
                heroPitchOffset: -2,
                heroVisualOffset: CGSize(width: 26, height: 0),
                labelLeftX: 0.45,
                labelRightX: 0.40,
                labelWidth: 310,
                labelSelectedZ: 94,
                labelRestZ: 34,
                annotationPlacements: [
                    "heart-aorta": .init(anchor: CGPoint(x: 0.53, y: 0.18), side: .right, lane: 0.14),
                    "heart-pulmonary-artery": .init(anchor: CGPoint(x: 0.60, y: 0.29), side: .right, lane: 0.30),
                    "heart-left-atrium": .init(anchor: CGPoint(x: 0.67, y: 0.43), side: .right, lane: 0.47),
                    "heart-left-ventricle": .init(anchor: CGPoint(x: 0.64, y: 0.69), side: .right, lane: 0.67),
                    "heart-svc": .init(anchor: CGPoint(x: 0.39, y: 0.22), side: .left, lane: 0.16),
                    "heart-right-atrium": .init(anchor: CGPoint(x: 0.34, y: 0.42), side: .left, lane: 0.39),
                    "heart-tricuspid": .init(anchor: CGPoint(x: 0.37, y: 0.57), side: .left, lane: 0.59),
                    "heart-right-ventricle": .init(anchor: CGPoint(x: 0.40, y: 0.75), side: .left, lane: 0.80)
                ]
            )
        case ("brain", .front):
            return ViewerLayout(
                heroPosition: SIMD3<Float>(0.0, 1.54, -1.82),
                labelsPosition: SIMD3<Float>(0.0, 1.54, -1.82),
                panelPosition: SIMD3<Float>(0.88, 1.56, -1.58),
                panelWidth: 818,
                carouselPosition: SIMD3<Float>(0.0, 1.06, -1.14),
                heroYawOffset: 0,
                heroPitchOffset: 0,
                heroVisualOffset: .zero,
                labelLeftX: 0.50,
                labelRightX: 0.44,
                labelWidth: 320,
                labelSelectedZ: 96,
                labelRestZ: 34,
                annotationPlacements: [
                    "brain-parietal": .init(anchor: CGPoint(x: 0.55, y: 0.25), side: .right, lane: 0.12),
                    "brain-frontal": .init(anchor: CGPoint(x: 0.69, y: 0.37), side: .right, lane: 0.28),
                    "brain-temporal": .init(anchor: CGPoint(x: 0.64, y: 0.60), side: .right, lane: 0.50),
                    "brain-cerebellum": .init(anchor: CGPoint(x: 0.31, y: 0.67), side: .left, lane: 0.66),
                    "brain-brainstem": .init(anchor: CGPoint(x: 0.40, y: 0.80), side: .left, lane: 0.82)
                ]
            )
        default:
            return ViewerLayout(
                heroPosition: SIMD3<Float>(0.0, 1.52, -1.80),
                labelsPosition: SIMD3<Float>(0.0, 1.52, -1.80),
                panelPosition: SIMD3<Float>(0.86, 1.54, -1.55),
                panelWidth: 760,
                carouselPosition: SIMD3<Float>(0.0, 1.04, -1.12),
                heroYawOffset: 0,
                heroPitchOffset: 0,
                heroVisualOffset: .zero,
                labelLeftX: immersivePreset.labelLeftX,
                labelRightX: immersivePreset.labelRightX,
                labelWidth: immersivePreset.labelWidth,
                labelSelectedZ: immersivePreset.labelSelectedZ,
                labelRestZ: immersivePreset.labelRestZ,
                annotationPlacements: [:]
            )
        }
    }
}
