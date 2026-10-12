import SwiftUI

private enum MacTracksideStyle {
    static let background = Color(red: 0.035, green: 0.047, blue: 0.063)
    static let panel = Color(red: 0.075, green: 0.09, blue: 0.11)
    static let accent = Color(red: 0.43, green: 0.91, blue: 0.72)
    static let muted = Color(red: 0.61, green: 0.67, blue: 0.72)
}

private enum LaunchChoice: String, CaseIterable, Identifiable {
    case firstBuild
    case currentBuild

    var id: String { rawValue }
    var directoryName: String { self == .firstBuild ? "Game-FirstBuild" : "Game" }
    var title: String { self == .firstBuild ? "PolyTrack 0.5.2" : "PolyTrack 0.6.0" }
    var subtitle: String { self == .firstBuild ? "Classic release · extra diagnostic popups removed" : "Newer release · diagnostics enabled" }
}

struct MacContentView: View {
    @State private var selectedBuild: LaunchChoice? = nil
    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var reloadToken = UUID()

    var body: some View {
        ZStack {
            MacTracksideStyle.background.ignoresSafeArea()
            if let selectedBuild {
                ZStack(alignment: .topLeading) {
                    MacPolyTrackWebView(isLoading: $isLoading, loadFailed: $loadFailed,
                                        reloadToken: reloadToken,
                                        gameDirectoryName: selectedBuild.directoryName)
                        .ignoresSafeArea()
                    Button {
                        self.selectedBuild = nil
                        isLoading = true
                        loadFailed = false
                    } label: {
                        Label("Versions", systemImage: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(.black.opacity(0.6), in: Capsule())
                            .overlay(Capsule().strokeBorder(.white.opacity(0.15), lineWidth: 1))
                    }
                    .buttonStyle(.plain).foregroundStyle(.white).padding(14)
                }

                if isLoading && !loadFailed {
                    VStack(spacing: 14) {
                        Image(systemName: "flag.checkered")
                            .font(.system(size: 34, weight: .semibold)).foregroundStyle(MacTracksideStyle.accent)
                        Text("POLYTRACK").font(.system(size: 20, weight: .black, design: .rounded))
                            .tracking(2.5).foregroundStyle(.white)
                        Text("PREPARING YOUR SESSION").font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .tracking(1.5).foregroundStyle(MacTracksideStyle.muted)
                        ProgressView().tint(MacTracksideStyle.accent)
                    }.padding(34).background(MacTracksideStyle.panel, in: RoundedRectangle(cornerRadius: 20))
                }
                if loadFailed {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 30)).foregroundStyle(MacTracksideStyle.accent)
                        Text("PolyTrack couldn't start").font(.system(size: 23, weight: .bold, design: .rounded)).foregroundStyle(.white)
                        Text("The selected game's bundled files may be missing or unreadable.")
                            .font(.system(size: 14)).foregroundStyle(MacTracksideStyle.muted)
                        Button {
                            reloadToken = UUID(); isLoading = true; loadFailed = false
                        } label: { Label("Try again", systemImage: "arrow.clockwise").padding(.horizontal, 18).padding(.vertical, 10) }
                            .buttonStyle(.borderedProminent).tint(MacTracksideStyle.accent)
                    }.padding(32).frame(maxWidth: .infinity, maxHeight: .infinity).background(MacTracksideStyle.background)
                }
            } else {
                launchMenu
            }
        }
        .preferredColorScheme(.dark)
    }

    private var launchMenu: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 14) {
                Image(systemName: "flag.checkered").font(.system(size: 30, weight: .bold))
                    .foregroundStyle(MacTracksideStyle.accent).frame(width: 66, height: 66)
                    .background(MacTracksideStyle.panel, in: RoundedRectangle(cornerRadius: 18))
                VStack(alignment: .leading, spacing: 5) {
                    Text("POLYTRACK").font(.system(size: 27, weight: .black, design: .rounded)).tracking(2.4).foregroundStyle(.white)
                    Text("CHOOSE YOUR BUILD").font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(2).foregroundStyle(MacTracksideStyle.muted)
                }
            }
            Text("Select which version to launch.").font(.system(size: 14)).foregroundStyle(MacTracksideStyle.muted)
            ForEach(LaunchChoice.allCases) { choice in
                Button { selectedBuild = choice; isLoading = true; loadFailed = false; reloadToken = UUID() } label: {
                    HStack(spacing: 14) {
                        Image(systemName: choice == .firstBuild ? "play.circle" : "bolt.circle.fill")
                            .font(.system(size: 27)).foregroundStyle(MacTracksideStyle.accent)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(choice.title).font(.system(size: 16, weight: .bold)).foregroundStyle(.white)
                            Text(choice.subtitle).font(.system(size: 12)).foregroundStyle(MacTracksideStyle.muted)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold)).foregroundStyle(MacTracksideStyle.muted)
                    }
                    .padding(18).background(MacTracksideStyle.panel, in: RoundedRectangle(cornerRadius: 15))
                    .overlay(RoundedRectangle(cornerRadius: 15).strokeBorder(.white.opacity(0.1), lineWidth: 1))
                }.buttonStyle(.plain)
            }
            Text("You can return to this menu from the game using the Versions button.")
                .font(.system(size: 11)).foregroundStyle(MacTracksideStyle.muted)
        }
        .padding(34).frame(maxWidth: 560).background(MacTracksideStyle.background)
    }
}
