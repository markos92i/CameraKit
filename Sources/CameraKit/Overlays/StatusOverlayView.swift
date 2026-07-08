//
//  StatusOverlayView.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 17/2/25.
//

import SwiftUI

/// A view that presents a status message over the camera user interface.
struct StatusOverlayView: View {
    @Environment(\.openURL) private var openURL

	let status: CameraStatus
    let handled: [CameraStatus] = [.unauthorized, .failed, .interrupted]
    
	var body: some View {
		if handled.contains(status) {
            ZStack {
                Color.black.opacity(0.5)
                
                VStack(alignment: .center, spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                    
                    Text(message)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if status == .unauthorized {
                        Button {
                            openURL(URL(string: UIApplication.openSettingsURLString)!)
                        } label: {
                            Label("Ir a Ajustes", systemImage: "gear")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .environment(\.isEnabled, true)
                    }
                }
                .padding()
                .background(color.opacity(0.1), in: .rect(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.5), lineWidth: 1))
                .frame(maxWidth: 600)
                .padding()
            }
		}
	}
	
	var color: Color {
		switch status {
        case .unauthorized: return .red
		case .failed: return .orange
		case .interrupted: return .yellow
		default: return .clear
		}
	}
	
	var message: String {
		switch status {
		case .unauthorized:
			return String(localized: "No tenemos permiso para acceder a la cámara o al micrófono. \n\nCambia la configuración en ajustes.")
		case .interrupted:
			return String(localized: "Acceso a cámara interrumpido. \n\nAlgún proceso de mayor prioridad ha bloqueado el acceso.")
		case .failed:
			return String(localized: "Ha fallado el arranque de la cámara. \n\nPor favor prueba a relanzar la app.")
		default:
			return ""
		}
	}
}

#Preview("Interrupted") {
    StatusOverlayView(status: .interrupted)
}

#Preview("Failed") {
    StatusOverlayView(status: .failed)
}

#Preview("Unauthorized") {
    StatusOverlayView(status: .unauthorized)
}
