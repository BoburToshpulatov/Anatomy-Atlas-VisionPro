//
//  DesignSystem.swift
//  Anatomy
//
//  Single source of truth for the visual language: radii, spacing, typography,
//  and the one "premium surface" recipe every panel/card/pill uses. Centralising
//  these removes the per-view inconsistencies (mismatched radii, glass halos,
//  passthrough bleed) that caused recurring layout issues.
//
//  Created by Bobur Toshpulatov.
//

import SwiftUI

enum DS {

    // MARK: Corner radii
    enum Radius {
        static let panel: CGFloat = 32
        static let card: CGFloat = 28
        static let thumbnail: CGFloat = 22
        static let control: CGFloat = 16
        static let pill: CGFloat = 999
    }

    // MARK: Spacing scale
    enum Space {
        static let xs: CGFloat = 6
        static let s: CGFloat = 10
        static let m: CGFloat = 16
        static let l: CGFloat = 22
        static let xl: CGFloat = 30
    }

    // MARK: Surface opacities (opaque-leaning so the room never bleeds through)
    enum Surface {
        static let panelTop = Color.black.opacity(0.88)
        static let panelBottom = Color.black.opacity(0.78)
        static let card = Color.white.opacity(0.05)
        static let cardSelectedTint: CGFloat = 0.0   // selection shown via border only
        static let hairline = Color.white.opacity(0.12)
        static let hairlineStrong = Color.white.opacity(0.16)
    }

    // MARK: Stage / pedestal — one consistent line every organ seats onto.
    enum Stage {
        /// Fraction of the hero frame height (from centre) where the pedestal sits.
        static let lineYFraction: CGFloat = 0.30
    }
}

// MARK: - Premium surface modifier

private struct PremiumSurface: ViewModifier {
    let radius: CGFloat
    let selected: Bool
    let tint: Color

    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: [DS.Surface.panelTop, DS.Surface.panelBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        selected ? tint.opacity(0.95) : DS.Surface.hairline,
                        lineWidth: selected ? 2.5 : 1
                    )
            }
            .shadow(color: selected ? tint.opacity(0.34) : .black.opacity(0.30),
                    radius: selected ? 30 : 24, y: 14)
    }
}

extension View {
    /// The single consistent dark surface used across the app. Opaque dark fill,
    /// one clipped rounded shape, one hairline border — no glass halo, no bleed.
    func premiumSurface(radius: CGFloat = DS.Radius.panel,
                        selected: Bool = false,
                        tint: Color = .white) -> some View {
        modifier(PremiumSurface(radius: radius, selected: selected, tint: tint))
    }
}
