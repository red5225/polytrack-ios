import AppKit
import SwiftUI
import WebKit

struct MacPolyTrackWebView: NSViewRepresentable {
    @Binding var isLoading: Bool
    @Binding var loadFailed: Bool
    let reloadToken: UUID
    let gameDirectoryName: String

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        webView.wantsLayer = true
        webView.layer?.backgroundColor = NSColor.black.cgColor
        webView.navigationDelegate = context.coordinator
        context.coordinator.loadGame(in: webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // SwiftUI can reuse the NSViewRepresentable coordinator when its inputs change.
        // Keep the selected bundle directory and bindings current before handling reloads.
        context.coordinator.parent = self
        if context.coordinator.lastReloadToken != reloadToken {
            context.coordinator.lastReloadToken = reloadToken
            context.coordinator.loadGame(in: webView)
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: MacPolyTrackWebView
        var lastReloadToken: UUID
        var localServer: PolyTrackLocalServer?

        init(parent: MacPolyTrackWebView) {
            self.parent = parent
            self.lastReloadToken = parent.reloadToken
        }

        func loadGame(in webView: WKWebView) {
            guard let resources = Bundle.main.resourceURL else { fail(); return }
            let candidates = [
                resources.appendingPathComponent(parent.gameDirectoryName, isDirectory: true),
                Bundle.main.bundleURL.appendingPathComponent(parent.gameDirectoryName, isDirectory: true)
            ]
            guard let gameDirectory = candidates.first(where: {
                FileManager.default.fileExists(atPath: $0.appendingPathComponent("index.html").path)
            }) else { fail(); return }

            parent.isLoading = true
            parent.loadFailed = false
            localServer?.stop()
            let server = PolyTrackLocalServer(rootURL: gameDirectory)
            localServer = server
            server.start { [weak self, weak webView] result in
                DispatchQueue.main.async {
                    guard let self, let webView else { return }
                    switch result {
                    case .success(let url): webView.load(URLRequest(url: url))
                    case .failure: self.fail()
                    }
                }
            }
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async { self.parent.isLoading = true; self.parent.loadFailed = false }
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async { self.parent.isLoading = false; self.parent.loadFailed = false }
        }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { fail() }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { fail() }

        private func fail() {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.loadFailed = true
            }
        }
    }
}
