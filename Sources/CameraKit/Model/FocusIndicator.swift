import SwiftUI

/// Represents a focus indicator shown on the camera preview.
public struct FocusIndicator: Identifiable, Sendable {
    public let id = UUID()
    let position: CGPoint

    init(position: CGPoint) {
        self.position = position
    }
}
