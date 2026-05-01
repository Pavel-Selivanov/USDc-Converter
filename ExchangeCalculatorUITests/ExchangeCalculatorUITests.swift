//
//  ExchangeCalculatorUITests.swift
//  ExchangeCalculatorUITests
//
//  Created by Pavel Selivanov on 5/1/26.
//

import XCTest

final class ExchangeCalculatorUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCalculatorLaunches() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["Exchange calculator"].waitForExistence(timeout: 3))
    }
}

