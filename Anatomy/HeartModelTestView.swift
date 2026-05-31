//
//  HeartModelTestView.swift
//  Anatomy
//
//  Created by Bobur Toshpulatov on 24/05/26.
//

import SwiftUI

struct HeartModelTestView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.92)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Image(systemName: "heart.circle")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))

                Text("Heart test scene removed for MVP")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                Text("Use the main immersive study space to review bundled anatomy models.")
                    .font(.body.weight(.medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.74))
                    .frame(maxWidth: 420)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(.white.opacity(0.10), lineWidth: 1)
            }
        }
    }
}
