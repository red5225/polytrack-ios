import SwiftUI
import WebKit

struct PolyTrackWebView: UIViewRepresentable {
    @Binding var isLoading: Bool
    @Binding var loadFailed: Bool
    let reloadToken: UUID
    let resetToken: UUID
    let gameVersion: String

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.backgroundColor = .black
        webView.isOpaque = false
        webView.scrollView.backgroundColor = .black
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.bounces = false
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = false
        loadGame(in: webView, coordinator: context.coordinator)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if context.coordinator.lastResetToken != resetToken {
            context.coordinator.lastResetToken = resetToken
            isLoading = true
            loadFailed = false
            WKWebsiteDataStore.default().removeData(
                ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                modifiedSince: Date.distantPast
            ) { [weak webView] in
                DispatchQueue.main.async {
                    guard let webView else { return }
                    if let url = webView.url, url.host == "127.0.0.1" {
                        webView.load(URLRequest(url: url))
                    } else {
                        self.loadGame(in: webView, coordinator: context.coordinator)
                    }
                }
            }
            return
        }

        if context.coordinator.lastReloadToken != reloadToken {
            context.coordinator.lastReloadToken = reloadToken
            if let url = webView.url, url.host == "127.0.0.1" {
                webView.reload()
            } else {
                loadGame(in: webView, coordinator: context.coordinator)
            }
        }
    }

    private func editableGameDirectory() throws -> URL {
        let fileManager = FileManager.default
        let documents = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let appFolder = documents.appendingPathComponent("PolyTrack", isDirectory: true)
        let bundleFolderName = gameVersion == "0.5.2" ? "Game-0.5.2" : "Game"
        let editableFolderName = bundleFolderName
        let editableGame = appFolder.appendingPathComponent(editableFolderName, isDirectory: true)

        let candidates = [
            Bundle.main.bundleURL.appendingPathComponent(bundleFolderName, isDirectory: true),
            Bundle.main.resourceURL?.appendingPathComponent(bundleFolderName, isDirectory: true)
        ].compactMap { $0 }
        let bundledGame = candidates.first { fileManager.fileExists(atPath: $0.appendingPathComponent("index.html").path) }
            ?? Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: bundleFolderName)?.deletingLastPathComponent()

        guard let bundledGame else { throw GameFilesError.bundledFilesMissing }
        try fileManager.createDirectory(at: appFolder, withIntermediateDirectories: true)

        let index = editableGame.appendingPathComponent("index.html")
        let bundledVersionURL = bundledGame.appendingPathComponent(".polytrack-ios-version")
        let editableVersionURL = editableGame.appendingPathComponent(".polytrack-ios-version")
        let bundledVersion = (try? String(contentsOf: bundledVersionURL, encoding: .utf8))?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let editableVersion = (try? String(contentsOf: editableVersionURL, encoding: .utf8))?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if !fileManager.fileExists(atPath: index.path) {
            if fileManager.fileExists(atPath: editableGame.path) {
                try fileManager.removeItem(at: editableGame)
            }
            try fileManager.copyItem(at: bundledGame, to: editableGame)
        } else if let bundledVersion, bundledVersion != editableVersion {
            // Upgrade core game files once per bundled version while preserving extra files.
            try mergeBundledFiles(from: bundledGame, to: editableGame)
        }

        let errorScript = "error-failsafe.js"
        let bundledError = bundledGame.appendingPathComponent(errorScript)
        let editableError = editableGame.appendingPathComponent(errorScript)
        if fileManager.fileExists(atPath: bundledError.path) {
            if fileManager.fileExists(atPath: editableError.path) { try? fileManager.removeItem(at: editableError) }
            try fileManager.copyItem(at: bundledError, to: editableError)
        }
        if let html = try? String(contentsOf: index, encoding: .utf8) {
            var updatedHTML = html
            let errorTag = "<script defer src=\\\"./error-failsafe.js\\\"></script>"
            if fileManager.fileExists(atPath: editableError.path) && !updatedHTML.contains(errorTag) {
                guard let headEnd = updatedHTML.range(of: "</head>", options: .caseInsensitive) else {
                    throw GameFilesError.bundledFilesMissing
                }
                updatedHTML.insert(contentsOf: "\\n\\(errorTag)\\n", at: headEnd.lowerBound)
            }
            if updatedHTML != html {
                try updatedHTML.write(to: index, atomically: true, encoding: .utf8)
            }
        }
        return editableGame
    }

    private func mergeBundledFiles(from source: URL, to destination: URL) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
        let items = try fileManager.contentsOfDirectory(
            at: source,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: []
        )
        for item in items {
            let target = destination.appendingPathComponent(item.lastPathComponent)
            let isDirectory = ((try? item.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory) ?? false
            let targetExists = fileManager.fileExists(atPath: target.path)
            let targetIsDirectory = targetExists
                ? (((try? target.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory) ?? false)
                : false

            if isDirectory {
                if targetExists && !targetIsDirectory {
                    try fileManager.removeItem(at: target)
                }
                try fileManager.createDirectory(at: target, withIntermediateDirectories: true)
                try mergeBundledFiles(from: item, to: target)
            } else {
                if targetExists {
                    try fileManager.removeItem(at: target)
                }
                try fileManager.copyItem(at: item, to: target)
            }
        }
    }

    private func loadGame(in webView: WKWebView, coordinator: Coordinator) {
        let gameDirectory: URL
        do {
            gameDirectory = try editableGameDirectory()
        } catch {
            isLoading = false
            loadFailed = true
            return
        }

        isLoading = true
        loadFailed = false
        coordinator.localServer?.stop()
        let server = PolyTrackLocalServer(rootURL: gameDirectory)
        coordinator.localServer = server
        server.start { [weak coordinator, weak webView] result in
            DispatchQueue.main.async {
                guard let coordinator, let webView else { return }
                switch result {
                case .success(let url):
                    webView.load(URLRequest(url: url))
                case .failure:
                    coordinator.parent.isLoading = false
                    coordinator.parent.loadFailed = true
                }
            }
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: PolyTrackWebView
        var lastReloadToken: UUID
        var lastResetToken: UUID
        var localServer: PolyTrackLocalServer?

        init(parent: PolyTrackWebView) {
            self.parent = parent
            self.lastReloadToken = parent.reloadToken
            self.lastResetToken = parent.resetToken
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
                self.parent.loadFailed = false
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.loadFailed = false
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            markFailed()
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            markFailed()
        }

        private func markFailed() {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.loadFailed = true
            }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard navigationAction.navigationType == .linkActivated,
                  let url = navigationAction.request.url,
                  let scheme = url.scheme?.lowercased(),
                  scheme == "http" || scheme == "https" else {
                decisionHandler(.allow)
                return
            }
            if let host = url.host?.lowercased(),
               ["kodub.com", "www.kodub.com", "crazygames.com", "www.crazygames.com", "itch.io", "www.itch.io", "discord.com", "reddit.com", "www.reddit.com"].contains(host) {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }

    private enum GameFilesError: Error {
        case bundledFilesMissing
    }
}
