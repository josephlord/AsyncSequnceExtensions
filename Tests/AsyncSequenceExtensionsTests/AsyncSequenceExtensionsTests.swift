import XCTest
import AsyncSequenceExtensions
import Foundation


@available(iOS 15.0, *)
final class AsyncSequenceExtensionsTests: XCTestCase {
    let fileUrl = Bundle.module.url(forResource: "TestFile", withExtension: "md")!
    
    func testFileReadable() async throws {
        let data = try! Data(contentsOf: fileUrl)
        let contents = String(data: data, encoding: .utf8)!
        let lines = contents.split(separator: "\n")
        XCTAssertEqual(61, lines.count)
    }

    // Crashes - Probably iOS Bug
//    func testPublisher() async throws {
//        var nonEmptyLineCount = 0
//        for try await line in fileUrl.lines {
//            guard !line.isEmpty else { continue }
//            print(line)
//            nonEmptyLineCount += 1
//        }
//        XCTAssertEqual(61, nonEmptyLineCount)
//    }


}
