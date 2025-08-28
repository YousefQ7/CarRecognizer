import AVFoundation
import UIKit

@MainActor
final class CameraController: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var isConfigured = false

    // Keep strong references to delegates until capture finishes
    private var inFlightDelegates: [PhotoCaptureDelegate] = []

    func configureAndStart() async {
        guard await requestCameraAccess() else { return }

        if !isConfigured {
            configureSession()
            isConfigured = true
        }
        start()
    }

    func start() {
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    func stop() {
        guard session.isRunning else { return }
        session.stopRunning()
    }

    private func requestCameraAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { cont in
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    cont.resume(returning: granted)
                }
            }
        default:
            return false
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        // Input
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        // Output
        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            return
        }
        session.addOutput(output)
        output.isHighResolutionCaptureEnabled = true

        session.commitConfiguration()
    }

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        
        // FIX: The core issue is setting the video orientation on the output's connection.
        // This ensures the captured image's metadata is set correctly.
        if let photoConnection = output.connection(with: .video),
           photoConnection.isVideoOrientationSupported {
            
            let deviceOrientation = UIDevice.current.orientation
            switch deviceOrientation {
            case .portrait:
                photoConnection.videoOrientation = .portrait
            case .portraitUpsideDown:
                photoConnection.videoOrientation = .portraitUpsideDown
            case .landscapeLeft:
                // When device is landscapeLeft (home button on right), video should be landscapeRight
                photoConnection.videoOrientation = .landscapeRight
            case .landscapeRight:
                // When device is landscapeRight (home button on left), video should be landscapeLeft
                photoConnection.videoOrientation = .landscapeLeft
            default:
                // For cases like face up/down or unknown, we default to portrait
                // as a safe fallback.
                photoConnection.videoOrientation = .portrait
            }
        }
        
        // Declare first so the closure can reference it
        var delegateRef: PhotoCaptureDelegate!

        delegateRef = PhotoCaptureDelegate { [weak self] image in
            completion(image)
            // Remove THIS delegate instance after it finishes
            if let idx = self?.inFlightDelegates.firstIndex(where: { $0 === delegateRef }) {
                self?.inFlightDelegates.remove(at: idx)
            }
        }

        inFlightDelegates.append(delegateRef)
        output.capturePhoto(with: settings, delegate: delegateRef)
    }

}

// MARK: - Photo Capture Delegate
private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage?) -> Void

    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              var image = UIImage(data: data) else {
            completion(nil)
            return
        }
        
        // FIX: The most reliable way to fix the orientation is to explicitly
        // normalize the UIImage after it's been created. This ensures the
        // final image is always correct, even if the camera's internal
        // metadata is not set perfectly.
        image = image.fixedOrientation()
        completion(image)
    }
}

