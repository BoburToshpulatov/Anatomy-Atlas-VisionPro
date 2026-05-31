//
//  SpatialAudioController.swift
//  Anatomy
//
//  Spatial audio for the study space: a looping heartbeat anchored at the heart's
//  position, and a soft ambient tone for the brain. The sound is emitted from the
//  organ's location so it pans naturally as the user moves around it.
//
//  ADD AUDIO FILES TO USE:
//    • "Heartbeat.wav"     (short, seamless loop — e.g. 2–4s)
//    • "BrainAmbient.wav"  (soft ambient pad loop)
//  Drag both into the Xcode project and ensure they are in the Anatomy app target.
//  If the files are absent this controller does nothing (safe no-op).
//

import SwiftUI
import RealityKit
import Foundation

@MainActor
final class SpatialAudioController {
    /// Invisible entity that emits the sound; positioned at the organ.
    let host = Entity()

    private var controller: AudioPlaybackController?
    private var currentOrganID: String?
    private var isAttached = false

    /// File name (without extension) per organ. Add matching files to the target.
    private func resourceName(for organID: String) -> String? {
        switch organID {
        case "heart": return "Heartbeat"
        case "brain": return "BrainAmbient"
        default:      return nil
        }
    }

    /// Call once from the RealityView `make` closure to place the emitter in the scene.
    func attach(to content: RealityViewContent, at position: SIMD3<Float>) {
        host.position = position
        host.spatialAudio = SpatialAudioComponent(gain: -6)   // gentle level
        if !isAttached {
            content.add(host)
            isAttached = true
        }
    }

    /// Keep the emitter co-located with the organ.
    func move(to position: SIMD3<Float>) {
        host.position = position
    }

    /// Start (or switch) the loop for the given organ. No-ops if the file is missing.
    func play(organID: String) {
        guard organID != currentOrganID else { return }
        currentOrganID = organID
        controller?.stop()
        controller = nil

        guard let name = resourceName(for: organID) else { return }

        Task { @MainActor in
            if let resource = try? await AudioFileResource(
                named: name,
                configuration: .init(shouldLoop: true)
            ) {
                controller = host.playAudio(resource)
            }
        }
    }

    func stop() {
        controller?.stop()
        controller = nil
        currentOrganID = nil
    }
}
