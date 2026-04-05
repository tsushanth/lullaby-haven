import XCTest

@MainActor
class ScreenshotTests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        setupSnapshot(app)
        app.launch()
    }

    func testScreenshots() {
        sleep(3)
        snapshot("01_Home")

        app.tabBars.buttons["Library"].tap()
        sleep(1)
        snapshot("02_Library")

        app.tabBars.buttons["Mixer"].tap()
        sleep(1)
        snapshot("03_Mixer")

        app.tabBars.buttons["Favorites"].tap()
        sleep(1)
        snapshot("04_Favorites")

        app.tabBars.buttons["Settings"].tap()
        sleep(1)
        snapshot("05_Settings")
    }
}
