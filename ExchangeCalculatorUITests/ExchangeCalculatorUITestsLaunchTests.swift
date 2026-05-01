//
//  ExchangeCalculatorUITestsLaunchTests.swift
//  ExchangeCalculatorUITests
//
//  Created by Pavel Selivanov on 5/1/26.
//

import XCTest

final class ExchangeCalculatorUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

