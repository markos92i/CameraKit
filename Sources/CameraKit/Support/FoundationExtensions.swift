//
//  FoundationExtensions.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 17/2/25.
//

import Foundation

extension URL {
    /// A unique output location to write a movie.
    public static var movieFileURL: URL {
        URL.temporaryDirectory.appending(component: UUID().uuidString).appendingPathExtension(for: .quickTimeMovie)
    }
}
