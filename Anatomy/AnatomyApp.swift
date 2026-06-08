//
//  AnatomyApp.swift
//  Anatomy
//
//  Created by Bobur Toshpulatov on 23/05/26.
//

import SwiftUI

@main
struct AnatomyApp: App {

    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
        }
        .windowStyle(.plain)
        .defaultSize(width: 1300, height: 920)
        .windowResizability(.contentSize)

        // Learn reader — a flat system window (always faces the viewer, no perspective lean).
        WindowGroup(id: AppModel.learnWindowID) {
            LearnReaderWindow()
                .environment(appModel)
                .persistentSystemOverlays(.hidden)   // hide the window grabber/chrome
        }
        .windowStyle(.plain)
        .defaultSize(width: 1540, height: 1160)
        .windowResizability(.contentSize)

        ImmersiveSpace(id: AppModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.lastImmersiveOpenResult = .opened
                    appModel.immersiveSpaceState = .open
                    appModel.lastStatusMessage = "Study space active."
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                    appModel.lastStatusMessage = "Study space closed."
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
