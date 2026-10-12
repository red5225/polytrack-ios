import SwiftUI

private enum MacTracksideStyle {
    static let background = Color(red: 0.035, green: 0.047, blue: 0.063)
    static let panel = Color(red: 0.075, green: 0.09, blue: 0.11)
    static let accent = Color(red: 0.43, green: 0.91, blue: 0.72)
    static let muted = Color(red: 0.61, green: 0.67, blue: 0.72)
}

struct MacContentView: View {
    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var reloadToken = UUID()

    var body: some View {
        ZStack {
            MacTracksideStyle.background.ignoresSafeArea()
            MacPolyTrackWebView(isLoading: $isLoading, loadFailed: $loadFailed, reloadToken: reloadToken)

            if isLoading && !loadFailed {
                VStack(spacing: 14) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(MacTracksideStyle.accent)
                    Text("POLYTRACK")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .tracking(2.5).foregroundStyle(.white)
                    Text("PREPARING YOUR SESSION")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .tracking(1.5).foregroundStyle(MacTracksideStyle.muted)
                    ProgressView().tint(MacTracksideStyle.accent)
                }
                .padding(34)
                .background(MacTracksideStyle.panel, in: RoundedRectangle(cornerRadius: 20))
            }

            if loadFailed {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 30)).foregroundStyle(MacTracksideStyle.accent)
                    Text("PolyTrack couldn't start")
                        .font(.system(size: 23, weight: .bold, design: .rounded)).foregroundStyle(.white)
                    Text("The bundled game files may be missing or unreadable.")
                        .font(.system(size: 14)).foregroundStyle(MacTracksideStyle.muted)
                    Button {
                        reloadToken = UUID()
                        isLoading = true
                        loadFailed = false
                    } label: {
                        Label("Try again", systemImage: "arrow.clockwise")
                            .padding(.horizontal, 18).padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent).tint(MacTracksideStyle.accent)
                }
                .padding(32).frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(MacTracksideStyle.background)
            }
        }
        .preferredColorScheme(.dark)
    }
}
