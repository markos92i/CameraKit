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

    private var captured: Bool { camera.captureSnapshot != nil }
    private var disabled: Bool { camera.isProcessing || camera.isSwitching || camera.status.disabled }

    /// Zoom factor at the start of a pinch gesture.
    @State private var zoomAtGestureStart: CGFloat = 1.0
        
    public init(camera: CameraModel, handler: ((CaptureResult) -> Void)? = nil) {
        self.camera = camera
        self.handler = handler
    }
    
    public var body: some View {
        CameraPreview(preview: camera.preview, videoGravity: .resizeAspectFill)
            .onCameraCaptureEvent { event in
                guard event.phase == .ended else { return }
                switch camera.config.captureMode {
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
            .simultaneousGesture(
                MagnifyGesture()
                    .onChanged { value in
                        Task { await camera.setZoom(zoomAtGestureStart * value.magnification) }
                    }
                    .onEnded { _ in
                        zoomAtGestureStart = camera.zoomFactor
                    }
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
            .onChange(of: camera.config.imageFilter) { _, _ in clear() }
            .onChange(of: camera.config.captureMode) { _, _ in clear() }
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
            .alert(
                "Error",
                isPresented: Binding(get: { camera.error != nil }, set: { if !$0 { camera.error = nil } }),
                actions: { Button("OK") { camera.error = nil } },
                message: { Text(camera.error?.localizedDescription ?? "") }
            )
    }
    
    @ViewBuilder
    var Indicators: some View {
        switch camera.config.captureMode {
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
            switch camera.config.captureMode {
            case .photo:    FilterPicker(camera: camera)
            default:        EmptyView()
            }
            
            Spacer()
            
            switch camera.config.captureMode {
            case .photo:
                if camera.capabilities.isLivePhotoSupported {
                    LivePhotoButton(camera: camera)
                }
                
                QualityPicker(camera: camera)
            case .video:
                if camera.capabilities.isHDRVideoSupported {
                    HDRButton(camera: camera)
                }
            }
        }
        .animation(.easeInOut, value: camera.config.captureMode)
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
                switch camera.captureSnapshot {
                case .photo(_, let raw, let metadata):
                    if let url = raw.fileURL() {
                        handler?(.photo(url: url, metadata: metadata))
                    }
                case .video(let url):
                    handler?(.video(url: url))
                case nil:
                    break
                }
            }
        } label: {
            Label("hecho", systemImage: "checkmark")
        }
        .buttonStyle(CameraButtonStyle(size: .medium))
    }
            
    @ViewBuilder
    var CameraUI: some View {
        Color.clear
            .overlay {
                StatusOverlayView(camera: camera)
            }
            .overlay(alignment: .top) {
                Indicators
                    .padding()
            }
            .overlay(alignment: .top) {
                TopToolbar
                    .padding()
                    .opacity(camera.config.isToolbarVisible ? 1 : 0)
                    .disabled(!camera.config.isToolbarVisible)
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
