


import SwiftUI

struct ResultView: View {
    let result: CapturedResult
    var onBack: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    Image(uiImage: result.image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .padding()

                    Text(result.label)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 48)
            }

            Button(action: onBack) {
                Image(systemName: "camera")
                    .font(.system(size: 22, weight: .bold))
                    .padding(12)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding(16)
            .tint(.white)
        }
        .toolbar(.hidden)
    }
}
