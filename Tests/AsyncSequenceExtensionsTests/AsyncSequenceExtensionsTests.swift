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
    
//    func testPublisher() async throws {
//        var nonEmptyLineCount = 0
//        for try await line in fileUrl.lines {
//            guard !line.isEmpty else { continue }
//            print(line)
//            nonEmptyLineCount += 1
//        }
//        XCTAssertEqual(61, nonEmptyLineCount)
//    }

    func testTimerPublisher() throws {
        let e = expectation(description: "Asynccomplete")
        print("Test running")
        let timerSequence = AsyncTimerSequence(interval: 0.0001)
//        let dFormatter = DateFormatter()
//        dFormatter.dateStyle = .none
//        dFormatter.timeStyle = .medium
//        dFormatter.dateFormat = "HH:mm:ss.SSSS"
        async(priority: .userInteractive) {
            var dates: [CFAbsoluteTime] = []
            var previousTime = CFAbsoluteTimeGetCurrent()
            for try await time in (timerSequence.prefix(30).map { _ in CFAbsoluteTimeGetCurrent() }) {
                dates.append(previousTime - time)
                previousTime = time
            }
//            print(dates.map { dFormatter.string(from: $0) }.joined(separator: "\n"))
            dates.forEach { print($0 * 10000) }
            e.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
        _ = timerSequence
    }
    
}
