//
//  DiagnosticImmersiveView.swift
//  Anatomy
//
//  Created by Codex on 25/05/26.
//

import SwiftUI

struct DiagnosticImmersiveView: View {
    var body: some View {
        ZStack {
            Color.clear

            Text("Diagnostic scene unavailable in MVP builds.")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.82))
                .padding(.horizontal, 22)
                .padding(.vertical, 16)
                .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
}
