//
//  TextCaptureAnimationView.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 6/7/25.
//

import SwiftUI

/// Animates detected text regions from their positions on the photo into a read-only list.
struct TextCaptureAnimationView: View {
    let photo: UIImage
    @Binding var phase: CapturePhase
    let features: [CaptureMetadata]
    let containerSize: CGSize

    @Namespace private var textAnimation
    @State private var extracted = false

    private var textFeatures: [CaptureMetadata] {
        features.filter { $0.type == .text }
    }

    var body: some View {
        ZStack {
            // Background: captured photo, darkened after extraction
            Image(uiImage: photo)
                .resizable()
                .scaledToFill()
                .frame(width: containerSize.width, height: containerSize.height)
                .clipped()
                .overlay(Color.black.opacity(extracted ? 0.6 : 0))

            if !extracted {
                // Texts overlaid at their detected positions
                ForEach(textFeatures) { data in
                    let points = CGPointUtils.convertToAspectFill(
                        data.flippedPoints,
                        source: data.image.extent.size,
                        target: containerSize
                    )
                    let center = CGPointUtils.center(of: points)
                    let angle = atan2(points[1].y - points[0].y, points[1].x - points[0].x)

                    TextChip(text: data.description)
                        .matchedGeometryEffect(id: data.id, in: textAnimation)
                        .rotationEffect(.radians(angle))
                        .position(x: center.x, y: center.y)
                }
            } else {
                // Read-only text list
                TextListView(items: textFeatures, namespace: textAnimation)
            }
        }
        .onAppear {
            phase = .animating
            withAnimation(.spring(duration: 0.5, bounce: 0.12)) {
                extracted = true
            } completion: {
                phase = .ready
            }
        }
    }
}

// MARK: - Supporting Views

/// A styled chip that represents a detected text block.
struct TextChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.blue.opacity(0.7), in: .capsule)
    }
}

// MARK: - Text List View

/// Scrollable read-only list of extracted texts.
struct TextListView: View {
    let items: [CaptureMetadata]
    var namespace: Namespace.ID

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(items) { item in
                    TextListRow(text: item.description)
                        .matchedGeometryEffect(id: item.id, in: namespace)
                }
            }
            .padding()
        }
    }
}

// MARK: - Text List Row

/// A single row in the read-only text list with a copy action.
struct TextListRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Text(text)
                .font(.body)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            Button {
                UIPasteboard.general.string = text
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 10))
    }
}
