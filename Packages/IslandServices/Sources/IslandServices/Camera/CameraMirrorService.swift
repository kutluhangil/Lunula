import AVFoundation
import AppKit
import Foundation
import Observation
import QuartzCore

private final class CameraSessionController: @unchecked Sendable {
    private let queue = DispatchQueue(label: "com.kutluhangul.lunula.camera-mirror", qos: .userInitiated)
    let session = AVCaptureSession()
    private var configuredInput: AVCaptureDeviceInput?

    func configureIfNeeded(with device: AVCaptureDevice) -> Bool {
        queue.sync {
            if let existing = configuredInput, existing.device.uniqueID == device.uniqueID {
                return true
            }
            session.beginConfiguration()
            defer { session.commitConfiguration() }

            if let existing = configuredInput {
                session.removeInput(existing)
                configuredInput = nil
            }

            if session.canSetSessionPreset(.high) {
                session.sessionPreset = .high
            } else if session.canSetSessionPreset(.medium) {
                session.sessionPreset = .medium
            }

            guard let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) else {
                return false
            }
            session.addInput(input)
            configuredInput = input
            return true
        }
    }

    func startRunning() {
        queue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stopRunningAndReleaseInput() {
        queue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
            if let existing = self.configuredInput {
                self.session.beginConfiguration()
                self.session.removeInput(existing)
                self.session.commitConfiguration()
                self.configuredInput = nil
            }
        }
    }
}

private final class MirroredCameraPreviewView: NSView {
    private let previewLayer: AVCaptureVideoPreviewLayer

    init(session: AVCaptureSession) {
        self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
        super.init(frame: .zero)
        wantsLayer = true
        layer?.masksToBounds = true
        layer?.cornerRadius = 12
        layer?.cornerCurve = .continuous
        layer?.backgroundColor = NSColor.black.cgColor

        previewLayer.videoGravity = .resizeAspectFill
        if let connection = previewLayer.connection, connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = false
        }
        layer?.addSublayer(previewLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        previewLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        previewLayer.bounds = bounds
        previewLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        previewLayer.transform = CATransform3DMakeScale(-1, 1, 1)
        CATransaction.commit()
    }
}

/// On-demand front-camera mirror service (`AVCaptureSession`). Never prompts or opens hardware until explicitly started.
@MainActor @Observable public final class CameraMirrorService {
    public enum MirrorAuthState: Equatable, Sendable {
        case notDetermined
        case authorized
        case denied
        case unavailable
    }

    @ObservationIgnored private var controller: CameraSessionController?

    public private(set) var authState: MirrorAuthState
    public private(set) var isRunning = false

    public init() {
        self.authState = Self.readAuthorizationState()
    }

    public func refreshAuthState() {
        authState = Self.readAuthorizationState()
    }

    @discardableResult
    public func requestPermissionOnly() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            authState = granted ? .authorized : .denied
            return granted
        case .authorized:
            authState = .authorized
            return true
        case .denied, .restricted:
            authState = .denied
            return false
        @unknown default:
            authState = .denied
            return false
        }
    }

    public func startAndMakePreviewView() async -> NSView? {
        guard await requestPermissionOnly() else { return nil }

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
                ?? AVCaptureDevice.default(for: .video)
        else {
            authState = .unavailable
            isRunning = false
            return nil
        }

        let activeController = controller ?? CameraSessionController()
        controller = activeController
        guard activeController.configureIfNeeded(with: device) else {
            authState = .unavailable
            isRunning = false
            return nil
        }

        let view = MirroredCameraPreviewView(session: activeController.session)
        isRunning = true
        activeController.startRunning()
        return view
    }

    public func stop() {
        isRunning = false
        controller?.stopRunningAndReleaseInput()
        controller = nil
    }

    private static func readAuthorizationState() -> MirrorAuthState {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            .notDetermined
        case .authorized:
            .authorized
        case .denied, .restricted:
            .denied
        @unknown default:
            .denied
        }
    }
}
