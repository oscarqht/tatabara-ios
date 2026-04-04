import XCTest

final class TatabaraUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testWorkoutFlowHappyPath() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.buttons["initialize-workout-button"].waitForExistence(timeout: 2))
        app.buttons["initialize-workout-button"].tap()

        XCTAssertTrue(app.buttons["pause-resume-button"].waitForExistence(timeout: 2))
        app.buttons["pause-resume-button"].tap()
        app.buttons["pause-resume-button"].tap()
        app.buttons["stop-session-button"].tap()

        XCTAssertTrue(app.buttons["initialize-workout-button"].waitForExistence(timeout: 2))
    }
}
