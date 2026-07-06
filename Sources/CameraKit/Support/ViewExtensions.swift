//
//  ViewExtensions.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 17/2/25.
//

import SwiftUI

struct CameraButtonLabel: LabelStyle {
    @Environment(\.isEnabled) private var isEnabled: Bool
    
    enum Size {
        case small
        case medium
        case large
        
        var icon: CGFloat {
            switch self {
            case .small: 16
            case .medium: 20
            case .large: 24
            }
        }

        var padding: CGFloat {
            switch self {
            case .small: 10
            case .medium: 15
            case .large: 20
            }
        }
    }
    
    private let size: Size
    private let icon: Bool
    private let text: Bool
    
    init(size: Size, icon: Bool, text: Bool) {
        self.size = size
        self.icon = icon
        self.text = text
    }

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            if icon {
                configuration.icon
                    .foregroundStyle(isEnabled ? .white : .white.opacity(0.4))
                    .frame(width: size.icon, height: size.icon)
                    .padding(size.padding)
                    .background(.black.opacity(0.3))
                    .clipShape(Circle())
                    .symbolEffect(.scale)
            }
            
            if text {
                configuration.title
                    .font(.system(size: size.icon, weight: .bold))
            }
        }
    }
}

struct CameraButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled: Bool
    
    enum Size {
        case small
        case medium
        case large
        
        var icon: CGFloat {
            switch self {
            case .small: 16
            case .medium: 20
            case .large: 24
            }
        }

        var padding: CGFloat {
            switch self {
            case .small: 10
            case .medium: 15
            case .large: 20
            }
        }
    }
    
    private let size: Size
    
    init(size: Size) {
        self.size = size
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(.iconOnly)
            .foregroundStyle(isEnabled ? (configuration.isPressed ? .white.opacity(0.5) : .white) : .white.opacity(0.4))
            .frame(width: size.icon, height: size.icon)
            .padding(size.padding)
            .background(.black.opacity(0.3))
            .clipShape(.circle)
            .symbolEffect(.scale)
    }
}
