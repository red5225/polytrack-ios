import SwiftUI
import WebKit

struct ContentView: View {
    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var reloadToken = UUID()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            PolyTrackWebView(isLoading: $isLoading, loadFailed: $loadFailed, reloadToken: reloadToken)
                .ignoresSafeArea()

            if isLoading {
                VStack(spacing: 12) {
                    ProgressView().tint(.white)
                    Text("Loading PolyTrack…")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .padding(20)
                .background(.black.opacity(0.8), in: RoundedRectangle(cornerRadius: 16))
            }

            if loadFailed {
                VStack(spacing: 14) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 36))
                    Text("Couldn’t load PolyTrack")
                        .font(.title3.bold())
                    Text("Check your internet connection, then try again.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.75))
                    Button("Try Again") { reloadToken = UUID(); loadFailed = false; isLoading = true }
                        .buttonStyle(.borderedProminent)
                }
                .foregroundStyle(.white)
                .padding(28)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black)
            }
        }
        .statusBarHidden(true)
    }
}
