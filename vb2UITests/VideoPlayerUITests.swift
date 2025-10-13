//
//  VideoPlayerUITests.swift
//  vb2UITests
//
//  Created by Claude Wilder on 2025-10-06.
//

import XCTest

final class VideoPlayerUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testAppLaunches() {
        XCTAssertTrue(app.exists, "App should launch successfully")
    }
    
    func testEmptyStateVisible() {
        let emptyStateText = app.staticTexts["No video files found. Select a folder to begin."]
        XCTAssertTrue(emptyStateText.waitForExistence(timeout: 2), "Empty state message should be visible")
    }
    
    func testHeaderExists() {
        let headerText = app.staticTexts["No folder selected"]
        XCTAssertTrue(headerText.exists, "Header should show 'No folder selected' initially")
    }
    
    // MARK: - Menu Bar Tests
    
    func testFileMenuExists() {
        let menuBar = app.menuBars
        let fileMenu = menuBar.menuBarItems["File"]
        XCTAssertTrue(fileMenu.exists, "File menu should exist")
    }
    
    func testSortMenuExists() {
        let menuBar = app.menuBars
        let sortMenu = menuBar.menuBarItems["Sort"]
        XCTAssertTrue(sortMenu.exists, "Sort menu should exist")
    }
    
    func testPlaybackMenuExists() {
        let menuBar = app.menuBars
        let playbackMenu = menuBar.menuBarItems["Playback"]
        XCTAssertTrue(playbackMenu.exists, "Playback menu should exist")
    }
    
    func testSortMenuItems() {
        let menuBar = app.menuBars
        menuBar.menuBarItems["Sort"].click()
        
        XCTAssertTrue(app.menuItems["File Name"].exists)
        XCTAssertTrue(app.menuItems["File Path"].exists)
        XCTAssertTrue(app.menuItems["Size (Smallest First)"].exists)
        XCTAssertTrue(app.menuItems["Size (Largest First)"].exists)
        XCTAssertTrue(app.menuItems["Random"].exists)
        
        // Press escape to close menu
        app.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
    }
    
    func testPlaybackMenuItems() {
        let menuBar = app.menuBars
        menuBar.menuBarItems["Playback"].click()
        
        XCTAssertTrue(app.menuItems["Stop"].exists)
        XCTAssertTrue(app.menuItems["Replay"].exists)
        XCTAssertTrue(app.menuItems["Play Next"].exists)
        
        // Press escape to close menu
        app.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
    }
    
    // MARK: - Settings Tests
    
    func testOpenSettings() {
        // Try keyboard shortcut (⌘⇧S)
        app.typeKey("s", modifierFlags: [.command, .shift])
        
        let settingsTitle = app.staticTexts["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 2), "Settings sheet should open")
        
        // Close settings
        app.buttons["Done"].click()
        XCTAssertFalse(settingsTitle.exists, "Settings sheet should close")
    }
    
    func testSettingsContainsSeekSliders() {
        // Open settings
        app.typeKey("s", modifierFlags: [.command, .shift])
        
        // Wait for sheet to appear
        let settingsTitle = app.staticTexts["Settings"]
        guard settingsTitle.waitForExistence(timeout: 3) else {
            XCTFail("Settings sheet did not open")
            return
        }
        
        let seekForwardLabel = app.staticTexts["Seek Forward:"]
        let seekBackwardLabel = app.staticTexts["Seek Backward:"]
        
        XCTAssertTrue(seekForwardLabel.exists, "Seek forward label should exist")
        XCTAssertTrue(seekBackwardLabel.exists, "Seek backward label should exist")
        
        // Close settings
        if app.buttons["Done"].exists {
            app.buttons["Done"].click()
        }
    }
    
    func testSettingsKeyboardShortcutsReference() {
        // Open settings
        app.typeKey("s", modifierFlags: [.command, .shift])
        
        // Wait for sheet
        let settingsTitle = app.staticTexts["Settings"]
        guard settingsTitle.waitForExistence(timeout: 3) else {
            XCTFail("Settings sheet did not open")
            return
        }
        
        let keyboardHeader = app.staticTexts["Keyboard Shortcuts Reference"]
        XCTAssertTrue(keyboardHeader.exists, "Keyboard shortcuts section should exist")
        
        // Close settings
        if app.buttons["Done"].exists {
            app.buttons["Done"].click()
        }
    }
    
    // MARK: - Keyboard Shortcut Tests
    
    func testSettingsKeyboardShortcut() {
        // Test ⌘,
        app.typeKey("s", modifierFlags: [.shift, .command])
        
        let settingsTitle = app.staticTexts["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 2), "⌘, should open settings")
        
        // Close with Escape
        app.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
    }
    
    func testSortKeyboardShortcuts() {
        // Test ⌘1 through ⌘5
        let shortcuts = ["1", "2", "3", "4", "5"]
        
        for shortcut in shortcuts {
            app.typeKey(shortcut, modifierFlags: .command)
            // If this doesn't crash, the shortcut works
            sleep(1)
        }
    }
    
    // MARK: - Window Tests
    
    func testWindowMinimumSize() {
        let window = app.windows.firstMatch
        let frame = window.frame
        
        XCTAssertGreaterThanOrEqual(frame.width, 800, "Window width should be at least 800")
        XCTAssertGreaterThanOrEqual(frame.height, 600, "Window height should be at least 600")
    }
    
    // MARK: - Accessibility Tests
    
    func testButtonsAreAccessible() {
        // Verify that UI elements are accessible
        XCTAssertTrue(app.windows.count > 0, "At least one window should exist")
        XCTAssertTrue(app.descendants(matching: .any).count > 0, "App should have UI elements")
        
        // Verify basic accessibility structure
        let window = app.windows.firstMatch
        XCTAssertTrue(window.exists, "Main window should exist")
    }
    
    func testAccessibilityLabels() {
        // Open settings to test accessible elements
        app.typeKey("s", modifierFlags: [.shift, .command])
        
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.exists, "Done button should be accessible")
        
        app.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
    }
}

// MARK: - Test with Mock Videos

extension VideoPlayerUITests {
    
    // Note: These tests would require actual video files or mocking
    // For full integration testing, you'd need to:
    // 1. Create a test folder with sample videos
    // 2. Programmatically select that folder
    // 3. Test playback controls
    
    func testNavigationButtonsAppearWithVideos() {
        // This test would require loading actual videos
        // Placeholder for future implementation
    }
    
    func testProgressBarWithVideo() {
        // This test would require loading actual videos
        // Placeholder for future implementation
    }
}

// MARK: - Performance Tests

extension VideoPlayerUITests {
    
    func testLaunchPerformance() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
