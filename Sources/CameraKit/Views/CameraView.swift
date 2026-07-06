//
//  CameraView.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 17/2/25.
//

import SwiftUI

public struct CameraView<CameraModel: Camera>: View {
    @State private var camera: CameraModel
    private var handler: ((CaptureResult) -> Void)?
                
    private var captured: Bool { camera.lastPhoto != nil || camera.lastVideo != nil }
    private var disabled: Bool { camera.isProcessing || camera.status.disabled }
        
    public init(camera: CameraModel, handler: ((CaptureResult) -> Void)? = nil) {
        self.camera = camera
        self.handler = handler
    }
    
    public var body: some View {
        CameraPreview(preview: camera.preview, videoGravity: .resizeAspectFill)
            .onCameraCaptureEvent { event in
                guard event.phase == .ended else { return }
                switch camera.captureMode {
                case .photo: Task { await camera.capturePhoto() }
                case .video: Task { await camera.toggleRecording() }
                }
            }
            .opacity(camera.shouldFlashScreen ? 0 : 1)
            .blur(radius: camera.isSwitching ? 20 : 0)
            .animation(.easeInOut, value: camera.isSwitching)
            .overlay {
                FeatureOverlayView(camera: camera)
            }
            .overlay {
                FocusOverlayView(camera: camera)
            }
            .overlay {
                CameraUI
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 50)
                    .onEnded { camera.swipeDirection = .init(size: $0.translation) }
            )
            .clipShape(.rect(cornerRadius: 30))
            .padding()
            .safeAreaInset(edge: .bottom, spacing: 0) {
                BottomToolbar
                    .padding(.horizontal, 40)
                    .padding(.bottom)
            }
            .disabled(disabled)
            .animation(.easeInOut, value: disabled)
            .animation(.easeInOut, value: captured)
            .onChange(of: camera.imageFilter) { _, _ in clear() }
            .onChange(of: camera.captureMode) { _, _ in clear() }
            .background(.ultraThinMaterial)
            .background {
                CameraPreview(preview: camera.alternativePreview, videoGravity: .resizeAspectFill)
                    .ignoresSafeArea()
            }
            .colorScheme(.dark)
            .task {
                await camera.start()
            }
            .onDisappear {
                Task {
                    if camera.captureActivity.isRecording { _ = await camera.toggleRecording() }
                    await camera.stop()
                }
            }
    }
    
    @ViewBuilder
    var Indicators: some View {
        switch camera.captureMode {
        case .photo:
            LiveBadge()
                .opacity(camera.captureActivity.isLivePhoto ? 1 : 0)
        case .video:
            RecordingTimeView(time: camera.captureActivity.currentTime)
        }
    }
    
    @ViewBuilder
    var TopToolbar: some View {
        HStack(spacing: 20) {
            switch camera.captureMode {
            case .photo:    FilterPicker(camera: camera)
            default:        EmptyView()
            }
            
            Spacer()
            
            switch camera.captureMode {
            case .photo:
                LivePhotoButton(camera: camera)
                
                QualityPicker(camera: camera)
            case .video:
                if camera.isHDRVideoSupported {
                    HDRButton(camera: camera)
                }
            }
        }
        .animation(.easeInOut, value: camera.captureMode)
    }
    
    @ViewBuilder
    var BottomToolbar: some View {
        if captured {
            HStack(alignment: .center) {
                RemoveButton
                
                Spacer()
                
                AcceptButton
            }
            .frame(height: 60)
        } else {
            MainToolbar(camera: camera)
        }
    }
    
    @ViewBuilder
    var RemoveButton: some View {
        Button {
            clear()
        } label: {
            Label("borrar", systemImage: "trash")
        }
        .buttonStyle(CameraButtonStyle(size: .medium))
    }
    
    @ViewBuilder
    var AcceptButton: some View {
        Button {
            Task {
                if let lastPhoto = camera.lastPhoto, let url = lastPhoto.store(quality: 0.8) {
                    switch camera.imageFilter {
                    case .cards, .text:
                        let regions = await recognizeText(in: lastPhoto)
                        handler?(.document(url: url, regions: regions))
                    case .none:
                        handler?(.photo(url: url))
                    }
                } else if let lastVideo = camera.lastVideo {
                    handler?(.video(url: lastVideo))
                }
            }
        } label: {
            Label("hecho", systemImage: "checkmark")
        }
        .buttonStyle(CameraButtonStyle(size: .medium))
    }
    
    private func recognizeText(in image: UIImage) async -> [TextRegion] {
        guard let ciImage = CIImage(image: image) else { return [] }
        let observations = await FeatureDetection.text(in: ciImage)
        return observations.compactMap { observation in
            guard let candidate = observation.topCandidates(1).first,
                  let box = candidate.boundingBox(for: candidate.string.startIndex..<candidate.string.endIndex) else { return nil }
            let rect = CGRect(
                x: box.bottomLeft.x,
                y: 1 - box.topLeft.y,
                width: box.topRight.x - box.topLeft.x,
                height: box.topLeft.y - box.bottomLeft.y
            )
            return TextRegion(text: candidate.string, bounds: rect)
        }
    }
            
    @ViewBuilder
    var CameraUI: some View {
        Color.clear
            .overlay {
                StatusOverlayView(status: camera.status)
            }
            .overlay(alignment: .top) {
                Indicators
                    .padding()
            }
            .overlay(alignment: .top) {
                TopToolbar
                    .padding()
                    .opacity(camera.isToolbarVisible ? 1 : 0)
                    .disabled(!camera.isToolbarVisible)
            }
            .overlay(alignment: .bottom) {
                CaptureModeView(camera: camera)
            }
            .overlay {
                if captured || camera.isProcessing { Color.black.opacity(0.5) }
            }
            .overlay {
                if camera.isProcessing { ProgressView().tint(.white) }
            }
            .overlay {
                CaptureOverlayView(camera: camera)
            }
    }
    
    private func clear() {
        camera.clearCapture()
    }
}

#Preview {
    CameraView(camera: PreviewCameraModel())
}
