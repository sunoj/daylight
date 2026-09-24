// Tests for supported video-link extraction and source precedence.
// Exports: VideoLinkDetectorTests
// Deps: XCTest, DaylightMenuBarKit, Foundation

import Foundation
import XCTest
@testable import DaylightMenuBarKit

final class VideoLinkDetectorTests: XCTestCase {
    func testEachSupportedVideoHostIsDetectedFromNotes() {
        let hosts = [
            "zoom.us",
            "meet.google.com",
            "teams.microsoft.com",
            "webex.com",
            "whereby.com",
            "chime.aws",
            "bluejeans.com"
        ]

        for host in hosts {
            let url = VideoLinkDetector.detect(url: nil, notes: "Join https://meet.\(host)/room-42 now", location: nil)
            XCTAssertEqual(url?.host, "meet.\(host)", "Expected (host) to be detected")
        }
    }

    func testDirectURLWinsOverLocationAndNotes() {
        let direct = URL(string: "https://zoom.us/j/123")!
        let result = VideoLinkDetector.detect(
            url: direct,
            notes: "https://meet.google.com/notes",
            location: "https://teams.microsoft.com/location"
        )

        XCTAssertEqual(result, direct)
    }

    func testLocationWinsWhenDirectURLIsNotSupported() {
        let location = URL(string: "https://whereby.com/room")!
        let result = VideoLinkDetector.detect(
            url: URL(string: "https://example.com/event"),
            notes: "https://zoom.us/notes",
            location: location.absoluteString
        )

        XCTAssertEqual(result, location)
    }

    func testUnsupportedLinksReturnNil() {
        XCTAssertNil(VideoLinkDetector.detect(url: URL(string: "https://example.com"), notes: "No meeting", location: nil))
    }
}
