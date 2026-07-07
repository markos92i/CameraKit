//
//  TextCaptureAnimationView.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 6/7/25.
//

import SwiftUI

/// Animates detected text regions from their positions on the photo into an editable list.
struct TextCaptureAnimationView: View {
    let photo: UIImage
    @Binding var phase: CapturePhase
    @Binding var editableTexts: [EditableTextItem]
    let features: [FeatureMetadata]
    let containerSize: CGSize

    @Namespace private var textAnimation
    @State private var extracted = false

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
                ForEach(features) { data in
                    if data.type == .text {
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
                }
            } else {
                // Editable text list
                TextListView(
                    items: $editableTexts,
                    namespace: textAnimation
                )
            }
        }
        .onAppear {
            editableTexts = features
                .filter { $0.type == .text }
                .map { EditableTextItem(id: $0.id, text: $0.description) }
            phase = .animating
            withAnimation(.spring(duration: 0.5, bounce: 0.12)) {
                extracted = true
            } completion: {
                phase = .ready
            }
        }
    }
}

// MARK: - Supporting Types

/// An editable text item for the post-capture list.
public struct EditableTextItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var text: String

    public init(id: UUID = UUID(), text: String) {
        self.id = id
        self.text = text
    }
}

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

/// Scrollable editable list of extracted texts.
struct TextListView: View {
    @Binding var items: [EditableTextItem]
    var namespace: Namespace.ID

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach($items) { $item in
                    TextListRow(item: $item) {
                        items.removeAll { $0.id == item.id }
                    }
                    .matchedGeometryEffect(id: item.id, in: namespace)
                }
            }
            .padding()
        }
    }
}

// MARK: - Text List Row

/// A single row in the editable text list with copy, edit, and delete actions.
struct TextListRow: View {
    @Binding var item: EditableTextItem
    let onDelete: () -> Void
    @State private var isEditing = false
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            if isEditing {
                TextField("", text: $item.text)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .focused($isFocused)
                    .onSubmit { isEditing = false }
            } else {
                Text(item.text)
                    .font(.body)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 0)

            Button {
                UIPasteboard.general.string = item.text
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Button {
                isEditing.toggle()
                isFocused = isEditing
            } label: {
                Image(systemName: isEditing ? "checkmark" : "pencil")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 10))
    }
}
