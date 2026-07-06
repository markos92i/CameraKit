//
//  RecordingTimeView.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 17/2/25.
//

import SwiftUI

/// A view that displays the current recording time.
struct RecordingTimeView: View {
    let time: TimeInterval
    
    var body: some View {
        Text(time.formatted)
            .padding([.leading, .trailing], 10)
            .padding([.top, .bottom], 4)
            .background(.black.opacity(0.3))
            .foregroundStyle(.white)
            .font(.body.weight(.semibold))
            .clipShape(.capsule)
    }
}

extension TimeInterval {
    var formatted: String {
        let time = Int(self)
        let seconds = time % 60
        let minutes = (time / 60) % 60
        let hours = (time / 3600)
        let formatString = "%0.2d:%0.2d:%0.2d"
        return String(format: formatString, hours, minutes, seconds)
    }
}

#Preview {
    RecordingTimeView(time: TimeInterval(floatLiteral: 500))
}
