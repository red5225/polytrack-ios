import SwiftUI
import WebKit

struct ContentView: View {
    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var reloadToken = UUID()
    @State private var resetToken = UUID()
    @State private var showCredits = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            PolyTrackWebView(
                isLoading: $isLoading,
                loadFailed: $loadFailed,
                reloadToken: reloadToken,
                resetToken: resetToken
            )
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
                    .accessibilityLabel("Game information, reset, and credits")
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
                    Text("The game files may be missing or incompatible with this iOS version. Open Info for file access and troubleshooting.")
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
            CreditsView {
                resetToken = UUID()
            }
            .preferredColorScheme(.dark)
        }
    }
}

private struct CreditsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false
    let onResetGameData: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("PolyTrack").font(.largeTitle.bold())
                    Text("Original game by Kodub").font(.title3.weight(.semibold))
                    Text("This is an unofficial, non-commercial iOS wrapper bundling an archived PolyTrack v0.5.2 browser build. It is not affiliated with or endorsed by Kodub, CrazyGames, Poki, or itch.io.")
                        .foregroundStyle(.secondary)

                    Divider()
                    Text("Game files").font(.headline)
                    Text("The editable game folder is available in Files under On My iPhone → PolyTrack → Game. You can browse and replace files there. Use a code editor app to edit JavaScript, HTML, and JSON files.")
                        .foregroundStyle(.secondary)
                    Text("Changes to game files are kept when you reopen the app. Keep a backup before editing.")
                        .foregroundStyle(.secondary)

                    Text("Reset saved game data").font(.headline)
                    Text("Clears this app's website storage (progress and settings). It does not delete or restore the editable Game files.")
                        .foregroundStyle(.secondary)
                    Button(role: .destructive) {
                        confirmReset = true
                    } label: {
                        Label("Reset Game Data", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .confirmationDialog(
                        "Reset saved game data?",
                        isPresented: $confirmReset,
                        titleVisibility: .visible
                    ) {
                        Button("Reset Game Data", role: .destructive) {
                            onResetGameData()
                            dismiss()
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This clears saved progress and settings on this device. Your editable game files will remain untouched.")
                    }

                    Divider()
                    Text("Offline play").font(.headline)
                    Text("Local game assets and included tracks are stored on this device. Online leaderboards, multiplayer, community services, and other server-dependent features may not work offline.")
                        .foregroundStyle(.secondary)
                    Link("Play the official PolyTrack page", destination: URL(string: "https://www.crazygames.com/game/polytrack")!)
                    Link("Kodub’s official website", destination: URL(string: "https://www.kodub.com/")!)
                    Link("Official itch.io page", destination: URL(string: "https://kodub.itch.io/polytrack")!)
                    Link("Archived build source and attribution", destination: URL(string: "https://github.com/StaticQuasar931/polytrack-0.5.2")!)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
            }
            .navigationTitle("Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
