import SwiftUI
import WebKit
import UIKit

private enum TracksideStyle {
    static let background = Color(red: 0.035, green: 0.047, blue: 0.063)
    static let panel = Color(red: 0.075, green: 0.09, blue: 0.11)
    static let accent = Color(red: 0.43, green: 0.91, blue: 0.72)
    static let muted = Color(red: 0.61, green: 0.67, blue: 0.72)
}

struct ContentView: View {
    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var reloadToken = UUID()
    @State private var resetToken = UUID()
    @State private var showInfo = false
    @AppStorage("polytrack.keepScreenAwake") private var keepScreenAwake = true
    @AppStorage("polytrack.gameVersion") private var gameVersion = "0.6.0"

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TracksideStyle.background.ignoresSafeArea()
            PolyTrackWebView(isLoading: $isLoading, loadFailed: $loadFailed,
                             reloadToken: reloadToken, resetToken: resetToken, gameVersion: gameVersion)
                .ignoresSafeArea()

            if !loadFailed {
                Button { showInfo = true } label: {
                    Image(systemName: "info")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(.black.opacity(0.55), in: Circle())
                        .overlay(Circle().strokeBorder(.white.opacity(0.16), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Game information and settings")
                .padding(.top, 12).padding(.trailing, 12)
            }

            if isLoading && !loadFailed {
                VStack(spacing: 17) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 19, style: .continuous)
                            .fill(TracksideStyle.panel).frame(width: 72, height: 72)
                        Image(systemName: "flag.checkered")
                            .font(.system(size: 29, weight: .semibold))
                            .foregroundStyle(TracksideStyle.accent)
                    }
                    VStack(spacing: 6) {
                        Text("POLYTRACK").font(.system(size: 19, weight: .black, design: .rounded))
                            .tracking(2.8).foregroundStyle(.white)
                        Text("PREPARING YOUR SESSION")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .tracking(1.6).foregroundStyle(TracksideStyle.muted)
                    }
                    ProgressView().tint(TracksideStyle.accent).padding(.top, 2)
                }
                .padding(.horizontal, 34).padding(.vertical, 30)
                .background(TracksideStyle.background.opacity(0.97),
                            in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.white.opacity(0.1), lineWidth: 1))
                .shadow(color: .black.opacity(0.35), radius: 30, y: 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if loadFailed {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 22)).foregroundStyle(TracksideStyle.accent)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SESSION COULD NOT START")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .tracking(1).foregroundStyle(TracksideStyle.muted)
                            Text("Unable to load PolyTrack")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }
                    Text("Some local game files may be missing or unreadable. Your saved data and editable files have not been reset.")
                        .font(.system(size: 14)).foregroundStyle(TracksideStyle.muted)
                    Button {
                        reloadToken = UUID(); loadFailed = false; isLoading = true
                    } label: {
                        Label("Try again", systemImage: "arrow.clockwise")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(TracksideStyle.background)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(TracksideStyle.accent,
                                        in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    }.buttonStyle(.plain)
                    Button("Open troubleshooting & info") { showInfo = true }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.82)).frame(maxWidth: .infinity)
                }
                .padding(24).frame(maxWidth: 420)
                .background(TracksideStyle.panel,
                            in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(.white.opacity(0.1), lineWidth: 1))
                .padding(22).frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(TracksideStyle.background.ignoresSafeArea())
            }
        }
        .onAppear { UIApplication.shared.isIdleTimerDisabled = keepScreenAwake }
        .onChange(of: keepScreenAwake) { UIApplication.shared.isIdleTimerDisabled = $0 }
        .onChange(of: gameVersion) { _ in reloadToken = UUID(); isLoading = true; loadFailed = false }
        .animation(.easeInOut(duration: 0.2), value: isLoading)
        .animation(.easeInOut(duration: 0.2), value: loadFailed)
        .preferredColorScheme(.dark).statusBarHidden(true)
        .sheet(isPresented: $showInfo) {
            InfoView { resetToken = UUID() }
                .preferredColorScheme(.dark)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

private struct InfoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false
    @State private var selectedTab = 0
    @AppStorage("polytrack.keepScreenAwake") private var keepScreenAwake = true
    @AppStorage("polytrack.gameVersion") private var gameVersion = "0.6.0"
    let onResetGameData: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Picker("Settings section", selection: $selectedTab) {
                        Text("Settings").tag(0)
                        Text("About").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.bottom, 2)

                    if selectedTab == 0 {
                        VStack(alignment: .leading, spacing: 7) {
                            Text("YOUR SESSION")
                                .font(.system(size: 23, weight: .black, design: .rounded))
                                .tracking(0.5).foregroundStyle(.white)
                            Text("Tune the app for a longer, smoother play session.")
                                .font(.system(size: 14)).foregroundStyle(TracksideStyle.muted)
                        }
                        section("GAME VERSION", symbol: "gamecontroller.fill") {
                            Picker("PolyTrack version", selection: $gameVersion) {
                                Text("0.6.0 · Newer physics").tag("0.6.0")
                                Text("0.5.2 · Classic + mods").tag("0.5.2")
                            }
                            .pickerStyle(.menu)
                            .tint(TracksideStyle.accent)
                            Text(gameVersion == "0.5.2" ? "Classic version with the restored single-player physics mod menu." : "Newer game version. UI mods are available; physics mod compatibility is being developed separately.")
                                .font(.system(size: 12)).foregroundStyle(TracksideStyle.muted)
                        }
                        section("DISPLAY", symbol: "sun.max.fill") {
                            Toggle(isOn: $keepScreenAwake) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Keep screen awake")
                                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                                    Text("Prevent auto-lock while you play.")
                                        .font(.system(size: 12)).foregroundStyle(TracksideStyle.muted)
                                }
                            }
                            .tint(TracksideStyle.accent)
                            .onChange(of: keepScreenAwake) { enabled in
                                UIApplication.shared.isIdleTimerDisabled = enabled
                            }
                        }
                        section("GAME FILES", symbol: "folder") {
                            Text("Your editable game copy is available in Files → On My iPhone or On My iPad → PolyTrack → Game.")
                                .font(.system(size: 14)).foregroundStyle(.white.opacity(0.9))
                            Text("Changes to files are preserved between launches. Back up the folder before editing game code or assets.")
                                .font(.system(size: 13)).foregroundStyle(TracksideStyle.muted)
                        }
                        section("SAVED DATA", symbol: "arrow.counterclockwise") {
                            Text("Clear local progress and browser storage without deleting your editable game files.")
                                .font(.system(size: 13)).foregroundStyle(TracksideStyle.muted)
                            Button(role: .destructive) { confirmReset = true } label: {
                                HStack {
                                    Image(systemName: "trash"); Text("Reset saved game data"); Spacer()
                                    Image(systemName: "chevron.right").font(.system(size: 11, weight: .bold))
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color(red: 1, green: 0.45, blue: 0.42))
                                .padding(13).background(Color.red.opacity(0.09),
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Color.red.opacity(0.2), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .confirmationDialog("Reset saved game data?", isPresented: $confirmReset,
                                                titleVisibility: .visible) {
                                Button("Reset Game Data", role: .destructive) {
                                    onResetGameData(); dismiss()
                                }
                                Button("Cancel", role: .cancel) {}
                            } message: {
                                Text("This clears saved game progress and browser storage. Your app preferences and editable Game folder remain untouched.")
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 10) {
                                Image(systemName: "flag.checkered").font(.system(size: 23, weight: .semibold))
                                    .foregroundStyle(TracksideStyle.accent)
                                Text("POLYTRACK").font(.system(size: 22, weight: .black, design: .rounded))
                                    .tracking(1.8).foregroundStyle(.white)
                            }
                            Text("OFFLINE EDITION  ·  BUILD 0.5.2")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .tracking(1.3).foregroundStyle(TracksideStyle.muted)
                            Text("An independent iOS wrapper for the archived PolyTrack browser game.")
                                .font(.system(size: 14)).foregroundStyle(TracksideStyle.muted)
                        }
                        section("CREDITS & LINKS", symbol: "info.circle") {
                            Text("Original game by Kodub. This unofficial wrapper is not affiliated with or endorsed by the original creator or hosting platforms.")
                                .font(.system(size: 13)).foregroundStyle(TracksideStyle.muted)
                            externalLink("Official PolyTrack page", url: "https://kodub.itch.io/polytrack")
                            externalLink("Kodub website", url: "https://www.kodub.com/")
                            externalLink("Archived build source", url: "https://github.com/StaticQuasar931/polytrack-0.5.2")
                        }
                        Text("Online leaderboards, multiplayer, and other server-dependent features may be unavailable offline.")
                            .font(.system(size: 12)).foregroundStyle(TracksideStyle.muted.opacity(0.85))
                    }
                }
                .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 28)
            }
            .background(TracksideStyle.background)
            .navigationTitle("SETTINGS").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.fontWeight(.semibold).tint(TracksideStyle.accent)
                }
            }
        }
        .onAppear { UIApplication.shared.isIdleTimerDisabled = keepScreenAwake }
    }

    private func section<Content: View>(_ title: String, symbol: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 8) {
                Image(systemName: symbol).foregroundStyle(TracksideStyle.accent)
                Text(title).font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1.2).foregroundStyle(.white.opacity(0.88))
            }
            content()
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(TracksideStyle.panel, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous)
            .strokeBorder(.white.opacity(0.09), lineWidth: 1))
    }

    private func externalLink(_ title: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack {
                Text(title).font(.system(size: 14, weight: .medium)).foregroundStyle(.white)
                Spacer()
                Image(systemName: "arrow.up.right").font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(TracksideStyle.accent)
            }.padding(.vertical, 3)
        }
    }
}
