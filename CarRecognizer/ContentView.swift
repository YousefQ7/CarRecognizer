import SwiftUI

struct ContentView: View {
    @StateObject private var camera = CameraController()
    @State private var path: [CapturedResult] = []

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                CameraPreviewView(session: camera.session)
                    .ignoresSafeArea()

                // Capture button on the RIGHT (works great in landscape)
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        Button(action: captureAndClassify) {
                            Circle()
                                .fill(.white)
                                .frame(width: 74, height: 74)
                                .shadow(radius: 6)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationDestination(for: CapturedResult.self) { result in
                ResultView(result: result) {
                    // back to camera
                    path.removeLast()
                }
            }
            .task {
                await camera.configureAndStart()
            }
            .onDisappear {
                camera.stop()
            }
        }
    }

    private func captureAndClassify() {
        camera.capturePhoto { uiImage in
            guard let image = uiImage else { return }
            // Classify on a background queue to keep UI snappy
            DispatchQueue.global(qos: .userInitiated).async {
                let service = CarClassifierService.shared
                let prediction = service.classify(image: image)
                let label: String
                switch prediction {
                case .success(let (index, confidence)):
                    let safeIndex = min(max(index, 0), carLabels.count - 1)
                    let name = carLabels[safeIndex]
                    label = "\(name)  (\(String(format: "%.1f", confidence * 100))%)"
                case .failure:
                    label = "No result"
                }
                let result = CapturedResult(image: image, label: label)
                DispatchQueue.main.async {
                    path.append(result)
                }
            }
        }
    }
}

// Model for navigation
struct CapturedResult: Hashable {
    let image: UIImage
    let label: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(label)
        hasher.combine(image.hashValue) // okay for ephemeral nav
    }

    static func == (lhs: CapturedResult, rhs: CapturedResult) -> Bool {
        lhs.label == rhs.label && lhs.image.pngData() == rhs.image.pngData()
    }
}

