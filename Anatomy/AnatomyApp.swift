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
        .defaultSize(width: 980, height: 700)
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
