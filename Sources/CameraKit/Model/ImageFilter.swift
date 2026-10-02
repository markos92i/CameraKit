//
//  ImageFilter.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 19/2/25.
//

import Foundation

public enum ImageFilter: Int, Identifiable, CaseIterable, CustomStringConvertible, Codable, Sendable {
    case none
    case cards
    case text
    
    public var id: Self { self }
        
    public var description: String {
        switch self {
        case .none: String(localized: "Ninguno", bundle: .module)
        case .cards: String(localized: "Tarjetas", bundle: .module)
        case .text: String(localized: "Texto", bundle: .module)
        }
    }
    
    public var systemName: String {
        switch self {
        case .none: "viewfinder"
        case .cards: "creditcard.viewfinder"
        case .text: "text.viewfinder"
        }
    }
}
