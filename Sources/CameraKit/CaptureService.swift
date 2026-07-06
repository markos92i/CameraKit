//
//  CaptureService.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 17/2/25.
//

import UIKit
@preconcurrency import AVFoundation
import CoreImage

/// An actor that manages the capture pipeline, which includes the capture session, device inputs, and capture outputs.
/// The app defines it as an `actor` type to ensure that all camera operations happen off of the `@MainActor`.
actor CaptureService {
    
    /// A value that indicates whether the capture service is idle or capturing a photo or movie.
    private(set) var captureActivity: CaptureActivity = .idle
    /// A value that indicates the current capture capabilities of the service.
    private(set) var captureCapabilities: CaptureCapabilities = .unknown
    /// A Boolean value that indicates whether a higher priority event, like receiving a phone call, interrupts the app.
    private(set) var isInterrupted = false
    /// A Boolean value that indicates whether the user enables HDR video capture.
    var isHDRVideoEnabled = false
    
    /// An AsyncStream with the camera image flow.
    nonisolated let previewStream: AsyncStream<CIImage>
    
    /// An AsyncStream that emits capture activity changes.
    nonisolated let activityStream: AsyncStream<CaptureActivity>
    private let activityContinuation: AsyncStream<CaptureActivity>.Continuation
    
    /// An AsyncStream that emits capture capabilities changes.
    nonisolated let capabilitiesStream: AsyncStream<CaptureCapabilities>
    private let capabilitiesContinuation: AsyncStream<CaptureCapabilities>.Continuation
    
    /// An AsyncStream that emits filter changes from Camera Control.
    nonisolated let filterStream: AsyncStream<ImageFilter>
    private let filterContinuation: AsyncStream<ImageFilter>.Continuation
    
    /// An AsyncStream that emits focus points when autofocus is triggered.
    nonisolated let focusPointStream: AsyncStream<CGPoint>
    private let focusPointContinuation: AsyncStream<CGPoint>.Continuation

    // The app's capture session.
    private let captureSession = AVCaptureSession()
    
    // An object that manages the app's photo capture behavior.
    private let photoCapture = PhotoCapture()
    
    // An object that manages the app's video capture behavior.
    private let movieCapture = MovieCapture()
    
    // An object that manages the app's camera preview.
    private let previewCapture = PreviewCapture()

    // An internal collection of output services.
    private var outputServices: [any OutputService] { [photoCapture, movieCapture, previewCapture] }
    
    // The video input for the currently selected device camera.
    private var activeVideoInput: AVCaptureDeviceInput?
    
    // The mode of capture, either photo or video. Defaults to photo.
    private(set) var captureMode: CaptureMode = .photo
    
    // An object the service uses to retrieve capture devices.
    private let deviceLookup = DeviceLookup()
        
    // An object that monitors the state of the system-preferred camera.
    // private let systemPreferredCamera = SystemPreferredCameraObserver()

    // An object that monitors video device rotations.
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator!
    private var rotationObservers = [AnyObject]()
    private let previewLayers: [AVSampleBufferDisplayLayer]

    // A Boolean value that indicates whether the actor finished its required configuration.
    private var isSetUp = false
            
    // A serial dispatch queue to use for capture control actions.
    private let sessionQueue = DispatchSerialQueue(label: "es.randstad.candidate.camera.sessionQueue")
    
    // Sets the session queue as the actor's executor.
    nonisolated var unownedExecutor: UnownedSerialExecutor {
        sessionQueue.asUnownedSerialExecutor()
    }
    
    private var isUsingFrontCaptureDevice: Bool { activeVideoInput?.device.position == .front }
    
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        // Access the capture session's connected preview layer.
        guard let previewLayer = captureSession.connections.compactMap({ $0.videoPreviewLayer }).first else {
            fatalError("The app is misconfigured. The capture session should have a connection to a preview layer.")
        }
        return previewLayer
    }

    init(previewLayers: [SendableDisplayLayer]) {
        self.previewLayers = previewLayers.compactMap { $0.layer }
        previewStream = previewCapture.previewStream
        
        let (actStream, actCont) = AsyncStream.makeStream(of: CaptureActivity.self)
        activityStream = actStream
        activityContinuation = actCont
        
        let (capStream, capCont) = AsyncStream.makeStream(of: CaptureCapabilities.self)
        capabilitiesStream = capStream
        capabilitiesContinuation = capCont
        
        let (filtStream, filtCont) = AsyncStream.makeStream(of: ImageFilter.self)
        filterStream = filtStream
        filterContinuation = filtCont
        
        let (focStream, focCont) = AsyncStream.makeStream(of: CGPoint.self)
        focusPointStream = focStream
        focusPointContinuation = focCont
        
        // Wire output services to emit activity through the stream
        photoCapture.onActivityChange = { [actCont] activity in
            actCont.yield(activity)
        }
        movieCapture.onActivityChange = { [actCont] activity in
            actCont.yield(activity)
        }
    }

    // MARK: - Authorization
    /// A Boolean value that indicates whether a person authorizes this app to use
    /// device cameras and microphones. If they haven't previously authorized the
    /// app, querying this property prompts them for authorization.
    var isAuthorized: Bool {
        get async {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            // Determine whether a person previously authorized camera access.
            var isAuthorized = status == .authorized
            // If the system hasn't determined their authorization status,
            // explicitly prompt them for approval.
            if status == .notDetermined {
                isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
            }
            return isAuthorized
        }
    }
    
    // MARK: - Capture session life cycle
    func start(with state: CameraState) async throws {
        // Set initial operating state.
        captureMode = state.captureMode
        isHDRVideoEnabled = state.isVideoHDREnabled
        
        // Exit early if not authorized or the session is already running.
        guard await isAuthorized, !captureSession.isRunning else { return }
        // Configure the session and start it.
        try setUpSession()
        captureSession.startRunning()
    }
    
    func stop() {
        guard isSetUp else { return }
        
        captureSession.stopRunning()
    }
    
    // MARK: - Capture setup
    // Performs the initial capture session configuration.
    private func setUpSession() throws {
        // Return early if already set up.
        guard !isSetUp else { return }

        // Observe internal state and notifications.
        observeOutputServices()
        observeNotifications()
        
        do {
            // Retrieve the default camera and microphone.
            let defaultCamera = try deviceLookup.defaultCamera
            let defaultMic = try deviceLookup.defaultMic

            // Add inputs for the default camera and microphone devices.
            activeVideoInput = try addInput(for: defaultCamera)
            try addInput(for: defaultMic)

            // Configure the session preset based on the current capture mode.
            captureSession.sessionPreset = captureMode == .photo ? .photo : .high
            // Add the photo capture output as the default output type.
            try addOutput(photoCapture.output)
            // If the capture mode is set to Video, add a movie capture output.
            if captureMode == .video {
                // Add the movie output as the default output type.
                try addOutput(movieCapture.output)
                setHDRVideoEnabled(isHDRVideoEnabled)
            }
            // Add the preview output.
            try addOutput(previewCapture.output)

            // Configure a rotation coordinator for the default video device.
            createRotationCoordinator(for: defaultCamera)
            // Observe changes to the default camera's subject area.
            observeSubjectAreaChanges(of: defaultCamera)
            // Update the service's advertised capabilities.
            updateCaptureCapabilities()
            
            // Configure Camera Control buttons (iPhone 16+).
            setupControls(for: defaultCamera)
            
            isSetUp = true
        } catch {
            throw CameraError.setupFailed
        }
    }

    // Adds an input to the capture session to connect the specified capture device.
    @discardableResult
    private func addInput(for device: AVCaptureDevice) throws -> AVCaptureDeviceInput {
        let input = try AVCaptureDeviceInput(device: device)
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        } else {
            throw CameraError.addInputFailed
        }
        return input
    }
    
    // Adds an output to the capture session to connect the specified capture device, if allowed.
    private func addOutput(_ output: AVCaptureOutput) throws {
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        } else {
            throw CameraError.addOutputFailed
        }
    }
    
    // The device for the active video input.
    private var currentDevice: AVCaptureDevice {
        guard let device = activeVideoInput?.device else {
            fatalError("No device found for current video input.")
        }
        return device
    }
        
    // MARK: - Camera Controls (iPhone 16+)
    
    private func setupControls(for device: AVCaptureDevice) {
        guard captureSession.supportsControls else { return }
        
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        
        // Zoom slider
        let zoomControl = AVCaptureSystemZoomSlider(device: device)
        if captureSession.canAddControl(zoomControl) {
            captureSession.addControl(zoomControl)
        }
        
        // Filter picker
        let filters = ImageFilter.allCases
        let titles = filters.map(\.description)
        let picker = AVCaptureIndexPicker("Filtro", symbolName: "camera.filters", localizedIndexTitles: titles)
        picker.setActionQueue(sessionQueue) { [filterContinuation] index in
            filterContinuation.yield(filters[index])
        }
        if captureSession.canAddControl(picker) {
            captureSession.addControl(picker)
        }
    }
    
    // MARK: - Capture mode selection
    
    /// Changes the mode of capture, which can be `photo` or `video`.
    ///
    /// - Parameter `captureMode`: The capture mode to enable.
    func setCaptureMode(_ captureMode: CaptureMode) throws {
        // Update the internal capture mode value before performing the session configuration.
        self.captureMode = captureMode
        
        // Change the configuration atomically.
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        
        // Configure the capture session for the selected capture mode.
        switch captureMode {
        case .photo:
            // The app needs to remove the movie capture output to perform Live Photo capture.
            captureSession.sessionPreset = .photo
            captureSession.removeOutput(movieCapture.output)
        case .video:
            captureSession.sessionPreset = .high
            try addOutput(movieCapture.output)
            if isHDRVideoEnabled {
                setHDRVideoEnabled(true)
            }
        }

        // Update the advertised capabilities after reconfiguration.
        updateCaptureCapabilities()
    }
    
    // MARK: - Device selection
    
    /// Changes the capture device that provides video input.
    ///
    /// The app calls this method in response to the user tapping the button in the UI to change cameras.
    /// The implementation switches between the front and back cameras and, in iPadOS,
    /// connected external cameras.
    func selectNextVideoDevice() {
        // The array of available video capture devices.
        let videoDevices = deviceLookup.cameras

        // Find the index of the currently selected video device.
        let selectedIndex = videoDevices.firstIndex(of: currentDevice) ?? 0
        // Get the next index.
        var nextIndex = selectedIndex + 1
        // Wrap around if the next index is invalid.
        if nextIndex == videoDevices.endIndex {
            nextIndex = 0
        }
        
        let nextDevice = videoDevices[nextIndex]
        // Change the session's active capture device.
        changeCaptureDevice(to: nextDevice)
        
        // The app only calls this method in response to the user requesting to switch cameras.
        // Set the new selection as the user's preferred camera.
        AVCaptureDevice.userPreferredCamera = nextDevice
    }
    
    // Changes the device the service uses for video capture.
    private func changeCaptureDevice(to device: AVCaptureDevice) {
        // The service must have a valid video input prior to calling this method.
        guard let currentInput = activeVideoInput else { fatalError() }
        
        // Bracket the following configuration in a begin/commit configuration pair.
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        
        // Remove the existing video input before attempting to connect a new one.
        captureSession.removeInput(currentInput)
        do {
            // Attempt to connect a new input and device to the capture session.
            activeVideoInput = try addInput(for: device)
            // Configure a new rotation coordinator for the new device.
            createRotationCoordinator(for: device)
            // Register for device observations.
            observeSubjectAreaChanges(of: device)
            // Update the service's advertised capabilities.
            updateCaptureCapabilities()
        } catch {
            // Reconnect the existing camera on failure.
            captureSession.addInput(currentInput)
        }
    }
        
    // MARK: - Rotation handling
    
    /// Create a new rotation coordinator for the specified device and observe its state to monitor rotation changes.
    private func createRotationCoordinator(for device: AVCaptureDevice) {
        guard let previewLayer = previewLayers.first else {
            fatalError("No previewLayer connection")
        }
        // Create a new rotation coordinator for this device.
        rotationCoordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: previewLayer)
        
        // Set initial rotation state on the preview and output connections.
        updatePreviewRotation(rotationCoordinator.videoRotationAngleForHorizonLevelPreview)
        updateCaptureRotation(rotationCoordinator.videoRotationAngleForHorizonLevelCapture)
        
        // Cancel previous observations.
        rotationObservers.removeAll()
        
        // Add observers to monitor future changes.
        rotationObservers.append(
            rotationCoordinator.observe(\.videoRotationAngleForHorizonLevelPreview, options: .new) { [weak self] _, change in
                guard let self, let angle = change.newValue else { return }
                Task { await self.updatePreviewRotation(angle) }
            }
        )
        
        rotationObservers.append(
            rotationCoordinator.observe(\.videoRotationAngleForHorizonLevelCapture, options: .new) { [weak self] _, change in
                guard let self, let angle = change.newValue else { return }
                Task { await self.updateCaptureRotation(angle) }
            }
        )
    }
    
    private func updatePreviewRotation(_ angle: CGFloat) {
        guard let videoConnection = previewCapture.output.connection(with: .video) else {
            fatalError("No video connection")
        }

        guard let videoInput = activeVideoInput else {
            fatalError("No video input")
        }

        do {
            try currentDevice.lockForConfiguration()
            if videoConnection.isVideoRotationAngleSupported(angle) {
                videoConnection.videoRotationAngle = angle
            }

            // Determine whether to mirror the video image.
            let isVideoMirrored = videoInput.device.position == .front
            if videoConnection.isVideoMirroringSupported && isVideoMirrored {
                videoConnection.isVideoMirrored = isVideoMirrored
            }
            currentDevice.unlockForConfiguration()
        } catch {
            fatalError("Couldn't update AVCaptureVideoDataOutput connection rotation.")
        }
    }
    
    private func updateCaptureRotation(_ angle: CGFloat) {
        // Update the orientation for all output services.
        outputServices.forEach { $0.setVideoRotationAngle(angle) }
    }
        
    // MARK: - Automatic focus and exposure
    
    /// Performs a one-time automatic focus and expose operation.
    ///
    /// The app calls this method as the result of a person tapping on the preview area.
    func focusAndExpose(at point: CGPoint) {
        // Emit the view-space point for UI overlay
        focusPointContinuation.yield(point)
        do {
            // Perform a user-initiated focus and expose.
            try focusAndExpose(at: pointInMetadataSpace(from: point), isUserInitiated: true)
        } catch {
            print("Unable to perform focus and exposure operation. \(error)")
        }
    }
    
    private func pointInMetadataSpace(from pointInViewSpace: CGPoint) -> CGPoint {
        let fullFrameInOutputCoordinates = previewCapture.output.outputRectConverted(fromMetadataOutputRect: CGRect(origin: .zero, size: .init(width: 1, height: 1)))
        let pointInOutputCoordinates = CGPoint(
            x: pointInViewSpace.x * fullFrameInOutputCoordinates.size.width,
            y: pointInViewSpace.y * fullFrameInOutputCoordinates.height
        )
        return previewCapture.output.metadataOutputRectConverted(fromOutputRect: CGRect(x: pointInOutputCoordinates.x, y: pointInOutputCoordinates.y, width: 0, height: 0)).origin
    }
    
    // Observe notifications of type `subjectAreaDidChangeNotification` for the specified device.
    private func observeSubjectAreaChanges(of device: AVCaptureDevice) {
        // Cancel the previous observation task.
        subjectAreaChangeTask?.cancel()
        subjectAreaChangeTask = Task {
            // Signal true when this notification occurs.
            for await _ in NotificationCenter.default.notifications(named: AVCaptureDevice.subjectAreaDidChangeNotification, object: device).compactMap({ _ in true }) {
                // Perform a system-initiated focus and expose.
                try? focusAndExpose(at: CGPoint(x: 0.5, y: 0.5), isUserInitiated: false)
            }
        }
    }
    private var subjectAreaChangeTask: Task<Void, Never>?
    
    private func focusAndExpose(at devicePoint: CGPoint, isUserInitiated: Bool) throws {
        // Configure the current device.
        let device = currentDevice
        
        // The following mode and point of interest configuration requires obtaining an exclusive lock on the device.
        try device.lockForConfiguration()
        
        let focusMode: AVCaptureDevice.FocusMode = isUserInitiated ? .autoFocus : .continuousAutoFocus
        if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
            device.focusPointOfInterest = devicePoint
            device.focusMode = focusMode
        }
        
        let exposureMode: AVCaptureDevice.ExposureMode = isUserInitiated ? .autoExpose : .continuousAutoExposure
        if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
            device.exposurePointOfInterest = devicePoint
            device.exposureMode = exposureMode
        }
        // Enable subject-area change monitoring when performing a user-initiated automatic focus and exposure operation.
        // If this method enables change monitoring, when the device's subject area changes, the app calls this method a
        // second time and resets the device to continuous automatic focus and exposure.
        device.isSubjectAreaChangeMonitoringEnabled = isUserInitiated
        
        // Release the lock.
        device.unlockForConfiguration()
    }
    
    // MARK: - Photo capture
    func capturePhoto(with features: PhotoFeatures) async throws -> Photo {
        try await photoCapture.capturePhoto(with: features)
    }
    
    // MARK: - Movie capture
    /// Starts recording video. The video records until the user stops recording,
    /// which calls the following `stopRecording()` method.
    func startRecording() {
        movieCapture.startRecording()
    }
    
    /// Stops the recording and returns the captured movie.
    func stopRecording() async throws -> Movie {
        try await movieCapture.stopRecording()
    }
    
    /// Sets whether the app captures HDR video.
    func setHDRVideoEnabled(_ isEnabled: Bool) {
        // Bracket the following configuration in a begin/commit configuration pair.
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        do {
            // If the current device provides a 10-bit HDR format, enable it for use.
            if isEnabled, let format = currentDevice.activeFormat10BitVariant {
                try currentDevice.lockForConfiguration()
                currentDevice.activeFormat = format
                currentDevice.unlockForConfiguration()
                isHDRVideoEnabled = true
            } else if let format = currentDevice.activeFormatStandard {
                try currentDevice.lockForConfiguration()
                currentDevice.activeFormat = format
                currentDevice.unlockForConfiguration()
                isHDRVideoEnabled = false
            }
        } catch {
            print("Unable to obtain lock on device and can't enable HDR video capture.")
        }
    }
    
    // MARK: - Preview capture
    func startPreviewing() {
        previewCapture.startPreviewing(previewLayers: previewLayers, queue: sessionQueue)
    }
    
    func stopPreviewing() {
        previewCapture.stopPreviewing()
    }

    
    // MARK: - Internal state management
    /// Updates the state of the actor to ensure its advertised capabilities are accurate.
    ///
    /// When the capture session changes, such as changing modes or input devices, the service
    /// calls this method to update its configuration and capabilities. The app uses this state to
    /// determine which features to enable in the user interface.
    private func updateCaptureCapabilities() {
        // Update the output service configuration.
        outputServices.forEach { $0.updateConfiguration(for: currentDevice) }
        // Set the capture service's capabilities for the selected mode.
        switch captureMode {
        case .photo: captureCapabilities = photoCapture.capabilities
        case .video: captureCapabilities = movieCapture.capabilities
        }
        capabilitiesContinuation.yield(captureCapabilities)
    }
    
    /// Merge the `captureActivity` values of the photo and movie capture services,
    /// and assign the value to the actor's property.
    private func observeOutputServices() {
        Task {
            for await activity in activityStream {
                self.captureActivity = activity
            }
        }
    }
        
    /// Observe capture-related notifications.
    private func observeNotifications() {
        Task {
            for await reason in NotificationCenter.default.notifications(named: AVCaptureSession.wasInterruptedNotification)
                .compactMap({ $0.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject? })
                .compactMap({ AVCaptureSession.InterruptionReason(rawValue: $0.integerValue) }) {
                /// Set the `isInterrupted` state as appropriate.
                isInterrupted = [.audioDeviceInUseByAnotherClient, .videoDeviceInUseByAnotherClient].contains(reason)
            }
        }
        
        Task {
            // Await notification of the end of an interruption.
            for await _ in NotificationCenter.default.notifications(named: AVCaptureSession.interruptionEndedNotification).compactMap({ _ in () }) {
                isInterrupted = false
            }
        }
        
        Task {
            for await error in NotificationCenter.default.notifications(named: AVCaptureSession.runtimeErrorNotification)
                .compactMap({ $0.userInfo?[AVCaptureSessionErrorKey] as? AVError }) {
                // If the system resets media services, the capture session stops running.
                if error.code == .mediaServicesWereReset {
                    if !captureSession.isRunning {
                        captureSession.startRunning()
                    }
                }
            }
        }
    }
}


