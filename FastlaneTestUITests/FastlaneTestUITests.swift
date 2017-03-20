//
//  FastlaneTestUITests.swift
//  FastlaneTestUITests
//
//  Created by Blazej Wdowikowski on 17/03/2017.
//  Copyright © 2017 Krzysztof Kapitan. All rights reserved.
//

import XCTest

class FastlaneTestUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
     }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSnapshots() {
        let app = XCUIApplication()
        snapshot("Mainscreen")
        app.buttons.element(boundBy: 0).tap()
        snapshot("View A")
        app.buttons.element(boundBy: 0).tap()
        app.buttons.element(boundBy: 1).tap()
        snapshot("View B")
    }
    
}
