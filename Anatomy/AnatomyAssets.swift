//
//  AnatomyAssets.swift
//  Anatomy
//
//  Asset-slot system for educational illustrations. Every lesson/quiz image is
//  referenced by a named `AssetSlot`. `AnatomyImage` renders the real asset if it
//  exists in the bundle, otherwise a branded placeholder — so the UI is identical
//  whether or not the artwork has been added yet.
//
//  TO ADD ART: drop a PNG named exactly like the slot's `assetName` into
//  Assets.xcassets (e.g. an image set named "heart_chambers"). It appears automatically.
//
//  Created by Bobur Toshpulatov.
//

import SwiftUI

/// A named reference to an educational illustration.
struct AssetSlot: Hashable {
    /// Image-set name to look up in the asset catalog (e.g. "heart_chambers").
    let assetName: String
    /// Human-readable caption shown under the image and in the placeholder.
    let caption: String
    /// SF Symbol used for the placeholder state.
    let placeholderSymbol: String

    init(_ assetName: String, caption: String, symbol: String = "photo.on.rectangle.angled") {
        self.assetName = assetName
        self.caption = caption
        self.placeholderSymbol = symbol
    }
}

/// Renders the slot's artwork, or a premium placeholder if the asset is absent.
struct AnatomyImage: View {
    let slot: AssetSlot
    var tint: Color = .white
    var cornerRadius: CGFloat = DS.Radius.thumbnail

    private var hasAsset: Bool {
        #if canImport(UIKit)
        return UIImage(named: slot.assetName) != nil
        #else
        return false
        #endif
    }

    var body: some View {
        ZStack {
            if hasAsset {
                Image(slot.assetName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                placeholder
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
        }
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [tint.opacity(0.16), .black.opacity(0.55)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 8) {
                Image(systemName: slot.placeholderSymbol)
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.55))
                Text(slot.caption)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
        }
    }
}
