🚗 CarRecognizer

CarRecognizer is an iOS app that identifies the make and model of cars from photos taken directly with your iPhone’s camera. The app uses a custom MobileNetV2 model trained on the Stanford Cars Dataset
, converted to CoreML for fast, on-device inference.

✨ Features

📸 Camera Integration: Capture car photos with a custom AVFoundation-powered camera.

🧠 On-Device Machine Learning: Real-time car make & model recognition using CoreML.

🔄 Image Preprocessing: Resize, normalize, and orientation-correct images before classification.

📊 Prediction Confidence: Displays top predictions with confidence scores.

🔙 Smooth Navigation: One-tap return to camera for repeated use.

🛠️ Tech Stack

Model Training:

PyTorch + Python

MobileNetV2 architecture

Trained on Stanford Cars Dataset (~16k images, 196 classes)

Model Deployment:

PyTorch → CoreML conversion

Optimized for iOS performance

App Development:

Swift + SwiftUI for UI

AVFoundation for camera preview & capture

CoreML + Vision for classification
