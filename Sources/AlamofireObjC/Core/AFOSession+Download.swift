import Foundation
import Alamofire

/// Download factories — fresh requests and resume-data continuation.
public extension AFOSession {

    /// Download to a destination chosen by `destination` (temp URL + response → final URL).
    /// When `destination` is nil, Alamofire's default temporary location is used.
    @discardableResult
    @objc func download(_ url: String,
                        method: AFOHTTPMethod,
                        parameters: [String: Any]?,
                        encoding: AFOParameterEncoding,
                        headers: [String: String]?,
                        destination: ((URL, HTTPURLResponse) -> URL)?) -> AFODownloadRequest {
        let request = session.download(url,
                                       method: method.alamofire,
                                       parameters: parameters,
                                       encoding: encoding.makeEncoding(),
                                       headers: AFOHeaders.make(from: headers),
                                       to: Self.bridge(destination))
        return AFODownloadRequest(request: request)
    }

    /// Resume a previously cancelled download from its resume data.
    @discardableResult
    @objc func downloadResuming(with resumeData: Data,
                                destination: ((URL, HTTPURLResponse) -> URL)?) -> AFODownloadRequest {
        let request = session.download(resumingWith: resumeData, to: Self.bridge(destination))
        return AFODownloadRequest(request: request)
    }

    /// Wrap an ObjC destination block into Alamofire's `Destination`, always replacing any
    /// existing file and creating intermediate directories.
    private static func bridge(_ destination: ((URL, HTTPURLResponse) -> URL)?) -> DownloadRequest.Destination? {
        guard let destination = destination else { return nil }
        return { tempURL, response in
            (destination(tempURL, response), [.removePreviousFile, .createIntermediateDirectories])
        }
    }
}
