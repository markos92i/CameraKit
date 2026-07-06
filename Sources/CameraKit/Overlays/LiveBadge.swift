//
//  LiveBadge.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 17/2/25.
//

import SwiftUI

/// A view that the app presents to indicate that Live Photo capture is active.
struct LiveBadge: View {
    var body: some View {
        Group {
            Text("LIVE")
                .padding(6)
                .foregroundStyle(.white)
                .font(.subheadline.bold())
        }
        .background(Color.accentColor.opacity(0.9))
        .clipShape(.buttonBorder)
    }
}

#Preview {
    LiveBadge()
        .padding()
        .background(.black)
}

