//
//  LearnReaderView.swift
//  Anatomy
//
//  Premium Learn-mode reader: a hierarchical learning path (categories → chapters)
//  on the left, and a calm, textbook-quality chapter reader on the right.
//

import SwiftUI

struct LearnReaderView: View {
    let organID: String
    let tint: Color

    @State private var selectedID: String = ""

    private var chapters: [LearnChapter] { LearnCurriculum.chapters(for: organID) }
    private var current: LearnChapter? {
        chapters.first(where: { $0.id == selectedID }) ?? chapters.first
    }
    private var currentIndex: Int {
        chapters.firstIndex(where: { $0.id == current?.id }) ?? 0
    }
    /// Chapters present, grouped in category order.
    private var groupedCategories: [(LearnCategory, [LearnChapter])] {
        LearnCategory.allCases.compactMap { cat in
            let items = chapters.filter { $0.category == cat }
            return items.isEmpty ? nil : (cat, items)
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 30) {
            learningPath
                .frame(width: 290)

            if let chapter = current {
                VStack(spacing: 0) {
                    ScrollView {
                        ChapterContent(
                            chapter: chapter,
                            index: currentIndex,
                            total: chapters.count,
                            categoryPosition: categoryPosition(for: chapter),
                            tint: tint
                        )
                        .padding(.trailing, 6)
                        .id(chapter.id)   // restart scroll at top on chapter change
                    }
                    .scrollIndicators(.hidden)

                    // Pinned navigation — always visible, no scrolling required.
                    navigationFooter
                }
            }
        }
        .onAppear { if selectedID.isEmpty { selectedID = chapters.first?.id ?? "" } }
        .onChange(of: organID) { _, _ in selectedID = chapters.first?.id ?? "" }
    }

    private func select(_ chapter: LearnChapter) {
        withAnimation(.easeInOut(duration: 0.28)) { selectedID = chapter.id }
    }

    // MARK: Pinned navigation footer

    private var navigationFooter: some View {
        HStack {
            if currentIndex > 0 {
                Button { select(chapters[currentIndex - 1]) } label: {
                    Label("Previous", systemImage: "chevron.left")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20).padding(.vertical, 13)
                        .background(Capsule().fill(.white.opacity(0.1)))
                }
                .buttonStyle(.plain)
            }
            Spacer()
            if currentIndex < chapters.count - 1 {
                Button { select(chapters[currentIndex + 1]) } label: {
                    HStack(spacing: 8) {
                        Text("Next Chapter").font(.headline.weight(.semibold))
                        Image(systemName: "chevron.right").font(.headline.weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22).padding(.vertical, 13)
                    .background(Capsule().fill(tint))
                    .shadow(color: tint.opacity(0.4), radius: 10, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 14)
    }

    /// "Anatomy • 2 of 4" position of a chapter within its category.
    private func categoryPosition(for chapter: LearnChapter) -> (Int, Int) {
        let inCat = chapters.filter { $0.category == chapter.category }
        let idx = inCat.firstIndex(where: { $0.id == chapter.id }) ?? 0
        return (idx + 1, inCat.count)
    }

    // MARK: Learning path rail

    private var learningPath: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Learning Path")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(1.0)

            ForEach(groupedCategories, id: \.0) { category, items in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: category.symbol)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(tint.opacity(0.9))
                        Text(category.rawValue)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(.top, 4)

                    ForEach(items) { chapter in
                        chapterRow(chapter)
                    }
                }
            }
        }
    }

    private func chapterRow(_ chapter: LearnChapter) -> some View {
        let isSelected = chapter.id == current?.id
        return Button {
            select(chapter)
        } label: {
            HStack(spacing: 10) {
                Circle()
                    .fill(isSelected ? tint : .white.opacity(0.16))
                    .frame(width: 7, height: 7)
                Text(chapter.title)
                    .font(.body.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(.white.opacity(isSelected ? 1.0 : 0.62))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? tint.opacity(0.16) : .clear)
            )
            .overlay(alignment: .leading) {
                if isSelected {
                    Capsule().fill(tint).frame(width: 3).padding(.vertical, 6)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Chapter content

private struct ChapterContent: View {
    let chapter: LearnChapter
    let index: Int
    let total: Int
    let categoryPosition: (Int, Int)
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            // Progress row
            HStack {
                HStack(spacing: 7) {
                    Image(systemName: chapter.category.symbol)
                        .font(.caption.weight(.bold))
                    Text("\(chapter.category.rawValue) • \(categoryPosition.0) of \(categoryPosition.1)")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(tint.opacity(0.95))
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Capsule().fill(tint.opacity(0.16)))

                Spacer()

                Text("Chapter \(index + 1) of \(total)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }

            // Title + learning goal
            VStack(alignment: .leading, spacing: 10) {
                Text(chapter.title)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "target")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(tint)
                        .padding(.top, 2)
                    Text(chapter.learningGoal)
                        .font(.title2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Illustration always on the left, explanation on the right.
            HStack(alignment: .top, spacing: 26) {
                illustration
                explanationColumn
            }

            keyFactsCard
            checkUnderstandingCard
        }
        .padding(.bottom, 18)
    }

    // MARK: pieces

    private var illustration: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(chapter.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .frame(maxHeight: 300)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 16, y: 8)

            Text(chapter.caption)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)

            if !chapter.labels.isEmpty {
                LearnChips(items: chapter.labels, tint: tint)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var explanationColumn: some View {
        Text(chapter.explanation)
            .font(.title2.weight(.regular))
            .foregroundStyle(.white.opacity(0.9))
            .lineSpacing(7)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var keyFactsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Key Facts", systemImage: "key.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            ForEach(Array(chapter.keyFacts.enumerated()), id: \.offset) { _, fact in
                HStack(alignment: .top, spacing: 12) {
                    Circle().fill(tint).frame(width: 8, height: 8).padding(.top, 11)
                    Text(fact)
                        .font(.title2.weight(.regular))
                        .foregroundStyle(.white.opacity(0.88))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var checkUnderstandingCard: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "questionmark.circle.fill")
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 7) {
                Text("Check Your Understanding")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text(chapter.checkQuestion)
                    .font(.title2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(tint.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(tint.opacity(0.4), lineWidth: 1)
        )
    }

}

// MARK: - Label chips

private struct LearnChips: View {
    let items: [String]
    let tint: Color

    var body: some View {
        FlowLayout(spacing: 8, lineSpacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.82))
                    .padding(.horizontal, 11).padding(.vertical, 6)
                    .background(Capsule().fill(tint.opacity(0.16)))
                    .overlay(Capsule().strokeBorder(tint.opacity(0.3), lineWidth: 0.8))
            }
        }
    }
}

/// Simple wrapping flow layout for chips.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0; y += rowHeight + lineSpacing; rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = bounds.minX, y: CGFloat = bounds.minY, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.minX + maxWidth, x > bounds.minX {
                x = bounds.minX; y += rowHeight + lineSpacing; rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
