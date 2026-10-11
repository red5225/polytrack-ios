import SwiftUI
import WebKit

struct ContentView: View {
    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var reloadToken = UUID()
    @State private var showCredits = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            PolyTrackWebView(isLoading: $isLoading, loadFailed: $loadFailed, reloadToken: reloadToken)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    Button { showCredits = true } label: {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(10)
                            .background(.black.opacity(0.42), in: Circle())
                    }
                    .accessibilityLabel("Game information and credits")
                    .padding(.top, 8)
                    .padding(.trailing, 8)
                }
                Spacer()
            }

            if isLoading {
                ProgressView("Loading offline game…")
                    .tint(.white)
                    .foregroundStyle(.white)
                    .padding(18)
                    .background(.black.opacity(0.78), in: RoundedRectangle(cornerRadius: 14))
            }

            if loadFailed {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle").font(.system(size: 32))
                    Text("PolyTrack could not start").font(.title3.bold())
                    Text("The bundled game files may be missing or incompatible with this iOS version.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.75))
                    Button("Try again") {
                        reloadToken = UUID()
                        loadFailed = false
                        isLoading = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(24)
                .frame(maxWidth: 420)
                .foregroundStyle(.white)
                .background(.black.opacity(0.94), in: RoundedRectangle(cornerRadius: 18))
                .padding(24)
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .sheet(isPresented: $showCredits) {
            CreditsView().preferredColorScheme(.dark)
        }
    }
}

private struct CreditsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("PolyTrack").font(.largeTitle.bold())
                    Text("Original game by Kodub").font(.title3.weight(.semibold))
                    Text("This is an unofficial, non-commercial iOS wrapper bundling an archived PolyTrack v0.5.0 browser build. It is not affiliated with or endorsed by Kodub, CrazyGames, Poki, or itch.io.")
                        .foregroundStyle(.secondary)
                    Text("Offline play").font(.headline)
                    Text("Local game assets and included tracks are bundled with this app. Online leaderboards, multiplayer, community services, and other server-dependent features may not work offline.")
                        .foregroundStyle(.secondary)
                    Link("Play the official PolyTrack page", destination: URL(string: "https://www.crazygames.com/game/polytrack")!)
                    Link("Kodub’s official website", destination: URL(string: "https://www.kodub.com/")!)
                    Link("Official itch.io page", destination: URL(string: "https://kodub.itch.io/polytrack")!)
                    Link("Archived build source and attribution", destination: URL(string: "https://github.com/Hexcein-moonsters/polytrack")!)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
