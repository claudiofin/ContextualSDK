//
//  SampleAppUITests.swift
//  SampleAppUITests
//
//  XCUITest for the Sample App
//

import XCTest

final class SampleAppUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-skipOnboarding"] // Suggest adding a flag to app, but for now we'll UI interaction
        app.launch()
        
        // Handle Siri Permission View if present
        // Handle Siri Permission View if present
        let enableButton = app.buttons["Enable Apple Intelligence"]
        let continueButton = app.buttons["Continue without AI"]
        
        // Wait for either button to appear
        if enableButton.waitForExistence(timeout: 5) {
            // Add monitor for the system alert
            addUIInterruptionMonitor(withDescription: "Siri Permission") { (alert) -> Bool in
                // Handle "Allow" or localized equivalents
                if alert.buttons["Allow"].exists {
                    alert.buttons["Allow"].tap()
                    return true
                }
                // Try to guess positive action (usually the last button or index 1)
                if alert.buttons.count >= 2 {
                    alert.buttons.element(boundBy: 1).tap()
                    return true
                }
                return false
            }
            
            enableButton.tap()
            // Need a tap to ensure interruption monitor fires if it didn't immediately
            app.tap()
        } else if continueButton.waitForExistence(timeout: 3) {
            continueButton.tap()
        }
        
        // Wait for Tab Bar
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5), "Tab bar did not appear")
    }
    
    // MARK: - Tab Navigation Tests
    
    @MainActor
    func testTabBarExists() throws {
        XCTAssertTrue(app.tabBars.firstMatch.exists)
    }
    
    @MainActor
    func testCanNavigateToAllTabs() throws {
        navigateToTab("Registration")
        XCTAssertTrue(app.navigationBars["Registration"].waitForExistence(timeout: 3))
        
        navigateToTab("Form")
        XCTAssertTrue(app.navigationBars["PDF Form"].waitForExistence(timeout: 3))
        
        navigateToTab("Settings")
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
        
        navigateToTab("Controls")
        XCTAssertTrue(app.navigationBars["Controls Demo"].waitForExistence(timeout: 3))
        
        navigateToTab("Debug")
        XCTAssertTrue(app.navigationBars["Debug"].waitForExistence(timeout: 3))
    }
    
    // Helper to handle "More" tab
    // Helper to handle "More" tab (works for English "More", Italian "Altro", etc.)
    private func navigateToTab(_ name: String) {
        if app.tabBars.buttons[name].exists {
            app.tabBars.buttons[name].tap()
        } else {
            // Check in More/Overflow tab (usually the 5th item, index 4)
            if app.tabBars.buttons.count > 4 {
                let moreButton = app.tabBars.buttons.element(boundBy: 4)
                if moreButton.exists {
                    moreButton.tap()
                    if app.tables.buttons[name].exists {
                        app.tables.buttons[name].tap()
                        return
                    }
                }
            }
            // Fail if not found
             XCTFail("Tab '\(name)' not found")
        }
    }
    
    // MARK: - Onboarding Form Tests
    
    @MainActor
    func testOnboardingFormShowsPersonalDataSection() throws {
        navigateToTab("Registration")
        
        let section = app.staticTexts["Personal Data"]
        XCTAssertTrue(section.waitForExistence(timeout: 5))
    }
    
    @MainActor
    func testOnboardingFormShowsContactSection() throws {
        navigateToTab("Registration")
        
        let section = app.staticTexts["Contact Info"]
        XCTAssertTrue(section.waitForExistence(timeout: 5))
    }
    
    // MARK: - Controls Demo Tests
    
    @MainActor
    func testControlsDemoShowsSignatureSection() throws {
        navigateToTab("Controls")
        
        // Wait for navigation
        XCTAssertTrue(app.navigationBars["Controls Demo"].waitForExistence(timeout: 3))
        
        // Verify signature section exists
        let signatureHeader = app.staticTexts["Signature (PencilKit)"]
        XCTAssertTrue(signatureHeader.waitForExistence(timeout: 5))
    }
    
    @MainActor
    func testControlsDemoShowsColorPickerSection() throws {
        navigateToTab("Controls")
        
        XCTAssertTrue(app.navigationBars["Controls Demo"].waitForExistence(timeout: 3))
        
        let colorHeader = app.staticTexts["Color Picker"]
        XCTAssertTrue(colorHeader.waitForExistence(timeout: 5))
    }
    
    @MainActor
    func testControlsDemoShowsViewModifierSection() throws {
        navigateToTab("Controls")
        
        XCTAssertTrue(app.navigationBars["Controls Demo"].waitForExistence(timeout: 3))
        
        let modifierHeader = app.staticTexts["ViewModifier"]
        XCTAssertTrue(modifierHeader.waitForExistence(timeout: 5))
    }
    
    @MainActor
    func testControlsDemoShowsGenerativeInputSection() throws {
        navigateToTab("Controls")
        
        XCTAssertTrue(app.navigationBars["Controls Demo"].waitForExistence(timeout: 3))
        
        let generativeHeader = app.staticTexts["Generative Input"]
        XCTAssertTrue(generativeHeader.waitForExistence(timeout: 5))
    }
    
    @MainActor
    func testControlsDemoShowsInputSheetSection() throws {
        navigateToTab("Controls")
        
        XCTAssertTrue(app.navigationBars["Controls Demo"].waitForExistence(timeout: 3))
        
        let sheetHeader = app.staticTexts["Input Sheet"]
        XCTAssertTrue(sheetHeader.waitForExistence(timeout: 5))
    }
    
    @MainActor
    func testControlsDemoCanOpenInputSheet() throws {
        navigateToTab("Controls")
        
        XCTAssertTrue(app.navigationBars["Controls Demo"].waitForExistence(timeout: 3))
        
        // Find and tap the "Open Input Sheet" button
        let openSheetButton = app.buttons["Open Input Sheet"]
        if openSheetButton.waitForExistence(timeout: 5) {
            openSheetButton.tap()
            
            // Verify sheet appears
            sleep(1)
            
            // The sheet should have "Notes" label
            let notesLabel = app.staticTexts["Notes"]
            XCTAssertTrue(notesLabel.exists || app.staticTexts["Cancel"].exists)
        }
    }
    
    // MARK: - Debug View Tests
    
    @MainActor
    func testDebugViewHasBrainSelector() throws {
        navigateToTab("Debug")
        
        let picker = app.segmentedControls.firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
    }
    
    @MainActor
    func testDebugViewCanAnalyzeField() throws {
        navigateToTab("Debug")
        
        sleep(1)
        
        let analyzeButton = app.buttons["Analyze"]
        if analyzeButton.waitForExistence(timeout: 3) {
            analyzeButton.tap()
            
            sleep(2)
            
            let strategyLabel = app.staticTexts["Strategy"]
            XCTAssertTrue(strategyLabel.exists || app.staticTexts["native"].exists || app.staticTexts["keyboard"].exists)
        }
    }
    
    // MARK: - Performance Test
    
    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
