import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Nothing needed here, as the view will handle its own updates
        // based on device orientation changes via the NotificationCenter.
    }
}

/// A UIView with an AVCaptureVideoPreviewLayer
final class PreviewView: UIView {
    // We add a new property to store the orientation observer token.
    private var orientationObserver: NSObjectProtocol?

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupOrientationObserver()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupOrientationObserver()
    }
    
    private func setupOrientationObserver() {
        // FIX: A much more reliable way to update the preview layer is by
        // listening to UIDevice.orientationDidChangeNotification.
        orientationObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updatePreviewOrientation()
        }
    }
    
    deinit {
        // Always remove the observer when the view is deallocated.
        if let observer = orientationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func updatePreviewOrientation() {
        guard let connection = videoPreviewLayer.connection,
              connection.isVideoOrientationSupported else {
            return
        }

        let deviceOrientation = UIDevice.current.orientation
        
        switch deviceOrientation {
        case .portrait:
            connection.videoOrientation = .portrait
        case .portraitUpsideDown:
            connection.videoOrientation = .portraitUpsideDown
        case .landscapeLeft:
            connection.videoOrientation = .landscapeRight
        case .landscapeRight:
            connection.videoOrientation = .landscapeLeft
        default:
            // For other orientations like face up/down, we maintain the previous orientation.
            break
        }
    }
}

