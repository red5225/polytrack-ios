import Foundation
import Network

/// Serves bundled game files from a stable loopback HTTP origin.
/// A fixed port is important: browser storage is scoped to origin (including port),
/// so using a random port on every launch made saved game data appear to vanish.
final class PolyTrackLocalServer {
    private let rootURL: URL
    private let queue = DispatchQueue(label: "com.red5225.polytrack.local-server")
    private var listener: NWListener?
    private var didCompleteStart = false
    private let startLock = NSLock()
    private let preferredPort: NWEndpoint.Port?


    init(rootURL: URL, port: NWEndpoint.Port? = NWEndpoint.Port(rawValue: 8765)!) {
        self.rootURL = rootURL.standardizedFileURL
        self.preferredPort = port
    }

    func start(completion: @escaping (Result<URL, Error>) -> Void) {
        do {
            let listener: NWListener
            if let preferredPort {
                do {
                    listener = try NWListener(using: .tcp, on: preferredPort)
                } catch {
                    // If a previous listener is still releasing its stable port, keep the
                    // game launchable on an ephemeral port rather than failing the edition switch.
                    listener = try NWListener(using: .tcp)
                }
            } else {
                // macOS can switch between bundled game versions without racing a fixed-port release.
                listener = try NWListener(using: .tcp)
            }
            self.listener = listener
            listener.newConnectionHandler = { [weak self] connection in
                guard let self else {
                    connection.cancel()
                    return
                }
                self.handle(connection)
            }
            listener.stateUpdateHandler = { [weak self] state in
                guard let self else { return }
                switch state {
                case .ready:
                    guard let actualPort = listener.port,
                          let url = URL(string: "http://127.0.0.1:\(actualPort.rawValue)/index.html") else {
                        self.completeStart(.failure(ServerError.badURL), completion: completion)
                        return
                    }
                    self.completeStart(.success(url), completion: completion)
                case .failed(let error):
                    self.completeStart(.failure(error), completion: completion)
                    listener.cancel()
                default:
                    break
                }
            }
            listener.start(queue: queue)
        } catch {
            completeStart(.failure(error), completion: completion)
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }

    private func completeStart(_ result: Result<URL, Error>,
                               completion: @escaping (Result<URL, Error>) -> Void) {
        startLock.lock()
        let shouldComplete = !didCompleteStart
        didCompleteStart = true
        startLock.unlock()
        if shouldComplete { completion(result) }
    }

    private func handle(_ connection: NWConnection) {
        connection.start(queue: queue)
        receiveHeaders(from: connection, accumulated: Data())
    }

    private func receiveHeaders(from connection: NWConnection, accumulated: Data) {
        if accumulated.range(of: Data("\r\n\r\n".utf8)) != nil {
            respond(to: connection, requestData: accumulated)
            return
        }
        guard accumulated.count < 65_536 else {
            send(connection, status: "400 Bad Request", contentType: "text/plain",
                 body: Data("Bad request".utf8))
            return
        }
        connection.receive(minimumIncompleteLength: 1, maximumLength: 16_384) { [weak self] data, _, isComplete, error in
            guard let self else {
                connection.cancel()
                return
            }
            var next = accumulated
            if let data { next.append(data) }
            if error != nil || (isComplete && data == nil) {
                connection.cancel()
            } else {
                self.receiveHeaders(from: connection, accumulated: next)
            }
        }
    }

    private func respond(to connection: NWConnection, requestData: Data) {
        guard let headerText = String(data: requestData, encoding: .utf8),
              let requestLine = headerText.components(separatedBy: "\r\n").first else {
            send(connection, status: "400 Bad Request", contentType: "text/plain",
                 body: Data("Bad request".utf8))
            return
        }
        let parts = requestLine.split(separator: " ")
        guard parts.count >= 2, (parts[0] == "GET" || parts[0] == "HEAD") else {
            send(connection, status: "405 Method Not Allowed", contentType: "text/plain",
                 body: Data("Method not allowed".utf8))
            return
        }

        let rawTarget = String(parts[1]).components(separatedBy: "?").first ?? "/"
        guard let decodedPath = rawTarget.removingPercentEncoding else {
            send(connection, status: "400 Bad Request", contentType: "text/plain",
                 body: Data("Bad path".utf8))
            return
        }
        let relativePath = decodedPath == "/" ? "index.html" : String(decodedPath.dropFirst())
        let fileURL = rootURL.appendingPathComponent(relativePath).standardizedFileURL
        guard fileURL.path.hasPrefix(rootURL.path + "/") || fileURL == rootURL,
              let data = try? Data(contentsOf: fileURL) else {
            send(connection, status: "404 Not Found", contentType: "text/plain",
                 body: Data("Asset not found".utf8))
            return
        }
        send(connection, status: "200 OK", contentType: Self.mimeType(for: fileURL.pathExtension),
             body: parts[0] == "HEAD" ? Data() : data)
    }

    private func send(_ connection: NWConnection, status: String, contentType: String, body: Data) {
        let headers = "HTTP/1.1 \(status)\r\nContent-Type: \(contentType)\r\nContent-Length: \(body.count)\r\nCache-Control: no-cache\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\n\r\n"
        var response = Data(headers.utf8)
        response.append(body)
        connection.send(content: response, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    private static func mimeType(for ext: String) -> String {
        switch ext.lowercased() {
        case "html", "htm": return "text/html; charset=utf-8"
        case "js", "mjs": return "text/javascript; charset=utf-8"
        case "css": return "text/css; charset=utf-8"
        case "json", "track": return "application/json; charset=utf-8"
        case "wasm": return "application/wasm"
        case "svg": return "image/svg+xml"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "webp": return "image/webp"
        case "ico": return "image/x-icon"
        case "woff": return "font/woff"
        case "woff2": return "font/woff2"
        case "mp3": return "audio/mpeg"
        case "ogg": return "audio/ogg"
        case "wav": return "audio/wav"
        case "mp4": return "video/mp4"
        default: return "application/octet-stream"
        }
    }

    private enum ServerError: Error {
        case badURL
    }
}
