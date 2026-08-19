@preconcurrency import AVFoundation
import SwiftUI
import UIKit

/// Live camera session behind the branded Snap screen.
///
/// The Snap stage used to be a dark gradient standing in for a viewfinder,
/// with the coral shutter merely presenting `UIImagePickerController` — so the
/// real camera appeared only *after* the user thought they had taken a photo.
/// This runs an actual `AVCaptureSession` so the preview is there on arrival
/// and the shutter captures.
@Observable
@MainActor
final class CameraController: NSObject {
    enum Status: Equatable {
        case idle
        /// No usable capture device — the Simulator, mainly.
        case unavailable
        case denied
        case running
    }

    private(set) var status: Status = .idle
    private(set) var canFlip = false
    private(set) var isCapturing = false

    let session = AVCaptureSession()

    private let output = AVCapturePhotoOutput()
    /// Session mutation and start/stop are blocking calls; they must not run
    /// on the main actor or they stutter the whole UI.
    private let sessionQueue = DispatchQueue(label: "com.catsnap.camera.session")
    private var position: AVCaptureDevice.Position = .back
    private var isConfigured = false
    private var captureContinuation: CheckedContinuation<UIImage?, Never>?

    // MARK: - Lifecycle

    func start() async {
        guard status != .running else { return }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            guard await AVCaptureDevice.requestAccess(for: .video) else {
                status = .denied
                return
            }
        case .denied, .restricted:
            status = .denied
            return
        @unknown default:
            status = .denied
            return
        }

        canFlip = Self.device(at: .front) != nil && Self.device(at: .back) != nil

        guard isConfigured || configure(for: position) else {
            status = .unavailable
            return
        }

        let session = self.session
        let queue = self.sessionQueue
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            queue.async {
                if !session.isRunning { session.startRunning() }
                cont.resume()
            }
        }
        status = .running
    }

    func stop() {
        let session = self.session
        sessionQueue.async {
            if session.isRunning { session.stopRunning() }
        }
        if status == .running { status = .idle }
    }

    func flip() {
        guard canFlip else { return }
        position = position == .back ? .front : .back
        _ = configure(for: position)
    }

    // MARK: - Configuration

    private static func device(at position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInDualWideCamera, .builtInWideAngleCamera],
            mediaType: .video,
            position: position
        ).devices.first
    }

    /// Returns false when the platform has no camera at all (Simulator).
    private func configure(for position: AVCaptureDevice.Position) -> Bool {
        guard let device = Self.device(at: position),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return false
        }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .photo
        for existing in session.inputs { session.removeInput(existing) }
        guard session.canAddInput(input) else { return false }
        session.addInput(input)

        if !session.outputs.contains(output) {
            guard session.canAddOutput(output) else { return false }
            session.addOutput(output)
        }

        // Mirror the *preview* for the front camera so it behaves like a
        // mirror, but leave the saved photo unmirrored — this is what Apple's
        // own camera does, and an unmirrored file is the truthful one.
        if let connection = output.connection(with: .video) {
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = false
            }
            applyRotation(to: connection)
        }

        isConfigured = true
        return true
    }

    /// Without this every capture lands rotated — the single most common
    /// AVFoundation bug. `videoRotationAngle` is degrees clockwise from
    /// landscape-right, which is why portrait is 90.
    private func applyRotation(to connection: AVCaptureConnection) {
        let angle: CGFloat
        switch UIDevice.current.orientation {
        case .landscapeLeft:       angle = 0
        case .portraitUpsideDown:  angle = 270
        case .landscapeRight:      angle = 180
        default:                   angle = 90   // .portrait and face up/down
        }
        if connection.isVideoRotationAngleSupported(angle) {
            connection.videoRotationAngle = angle
        }
    }

    // MARK: - Capture

    func capture() async -> UIImage? {
        guard status == .running, !isCapturing else { return nil }
        isCapturing = true
        defer { isCapturing = false }

        if let connection = output.connection(with: .video) {
            applyRotation(to: connection)
        }

        let settings = AVCapturePhotoSettings()
        return await withCheckedContinuation { (cont: CheckedContinuation<UIImage?, Never>) in
            captureContinuation = cont
            output.capturePhoto(with: settings, delegate: self)
        }
    }
}

extension CameraController: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        // fileDataRepresentation() bakes in EXIF orientation, so PhotoUpload
        // and the editor preview both get a correctly-oriented image.
        let image = photo.fileDataRepresentation().flatMap(UIImage.init(data:))
        Task { @MainActor in
            self.captureContinuation?.resume(returning: image)
            self.captureContinuation = nil
        }
    }
}

/// Hosts the session's preview layer. A plain UIView subclass whose backing
/// layer *is* the preview layer, so it resizes with the view for free.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.previewLayer.session = session
    }

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        // swiftlint:disable:next force_cast
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
