//
//  CameraState.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 17/2/25.
//

import SwiftUI

public struct CameraState: Sendable {
    public init() {}
    @AppStorage("app.camera.isToolbarVisible") public var isToolbarVisible: Bool = true
    @AppStorage("app.camera.isCaptureModeVisible") public var isCaptureModeVisible: Bool = true
    @AppStorage("app.camera.isLivePhotoEnabled") public var isLivePhotoEnabled: Bool = true
    @AppStorage("app.camera.isVideoHDRSupported") public var isVideoHDRSupported: Bool = true
    @AppStorage("app.camera.isVideoHDREnabled") public var isVideoHDREnabled: Bool = true
    @AppStorage("app.camera.qualityPrioritization") public var qualityPrioritization: QualityPrioritization = .quality
    @AppStorage("app.camera.captureMode") public var captureMode: CaptureMode = .photo
    @AppStorage("app.camera.imageFilter") public var imageFilter: ImageFilter = .none
}
