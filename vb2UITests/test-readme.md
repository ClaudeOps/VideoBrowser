# Video Player Testing Guide

## Overview

This project includes comprehensive testing for the Video Player app with two test targets:
- **Unit Tests** (`vb2Tests`) - Tests business logic and ViewModel
- **UI Tests** (`vb2UITests`) - Tests user interface and interactions

## Test Structure

### Unit Tests (`VideoPlayerViewModelTests.swift`)

Tests the ViewModel logic without UI dependencies:

#### Initialization Tests
- ✅ Initial state verification
- ✅ Default settings values

#### Settings Tests
- ✅ Seek time customization
- ✅ Mute/unmute toggle

#### Sort & Playback Tests
- ✅ Sort option changes
- ✅ All sort options iteration
- ✅ Playback end option changes

#### Persistence Tests
- ✅ Sort option persistence
- ✅ Playback option persistence
- ✅ Seek times persistence
- ✅ Mute state persistence

#### Navigation Tests
- ✅ Previous/Next with empty list
- ✅ Random with empty list

#### Model Tests
- ✅ VideoFile model
- ✅ Enum raw values

#### Performance Tests
- ✅ Sort performance with 1000 items

### UI Tests (`VideoPlayerUITests.swift`)

Tests the user interface and user interactions:

#### Initial State Tests
- ✅ App launches successfully
- ✅ Empty state visible
- ✅ Header exists

#### Menu Bar Tests
- ✅ File menu exists
- ✅ Sort menu exists and items
- ✅ Playback menu exists and items

#### Settings Tests
- ✅ Open/close settings sheet
- ✅ Seek sliders exist
- ✅ Keyboard shortcuts reference

#### Keyboard Shortcut Tests
- ✅ ⌘, opens settings
- ✅ ⌘1-5 sort shortcuts work

#### Window Tests
- ✅ Minimum window size

#### Performance Tests
- ✅ Launch performance metrics

## Running Tests

### In Xcode

1. **Run All Tests**
   - Press `⌘U` or Product → Test

2. **Run Specific Test Class**
   - Click the diamond next to the test class
   - Or right-click → Run

3. **Run Single Test**
   - Click the diamond next to the test method
   - Or right-click → Run

### From Command Line

```bash
# Run all tests
xcodebuild test -scheme vb2 -destination 'platform=macOS'

# Run only unit tests
xcodebuild test -scheme vb2 -destination 'platform=macOS' -only-testing:vb2Tests

# Run only UI tests
xcodebuild test -scheme vb2 -destination 'platform=macOS' -only-testing:vb2UITests

# Run specific test class
xcodebuild test -scheme vb2 -destination 'platform=macOS' -only-testing:vb2Tests/VideoPlayerViewModelTests

# Run specific test method
xcodebuild test -scheme vb2 -destination 'platform=macOS' -only-testing:vb2Tests/VideoPlayerViewModelTests/testInitialState
```

## Test Coverage

### Current Coverage

- **ViewModel Logic**: ~80% coverage
- **User Preferences**: 100% coverage
- **Settings**: 100% coverage
- **Navigation**: Partial (needs mock videos)
- **UI Elements**: ~70% coverage

### Areas Needing More Tests

1. **Video Playback** - Requires mock video files
2. **File Operations** - Move to trash, move to folder
3. **Video Scanning** - Folder enumeration with test files
4. **Seek Operations** - Forward/backward seeking
5. **Progress Bar** - Click/drag interactions

## Adding New Tests

### Unit Test Example

```swift
func testNewFeature() {
    // Arrange
    viewModel.someProperty = initialValue
    
    // Act
    viewModel.someMethod()
    
    // Assert
    XCTAssertEqual(viewModel.someProperty, expectedValue)
}
```

### UI Test Example

```swift
func testNewUIElement() {
    // Find element
    let button = app.buttons["ButtonIdentifier"]
    
    // Verify existence
    XCTAssertTrue(button.exists)
    
    // Interact
    button.click()
    
    // Verify result
    XCTAssertTrue(app.staticTexts["ResultText"].exists)
}
```

## Best Practices

1. **Keep tests isolated** - Each test should be independent
2. **Use setUp/tearDown** - Clean state before/after tests
3. **Clear UserDefaults** - Prevent test pollution
4. **Descriptive names** - `testFeatureUnderSpecificCondition()`
5. **AAA Pattern** - Arrange, Act, Assert
6. **Fast tests** - Mock slow operations
7. **One assertion focus** - Test one thing at a time

## Continuous Integration

### GitHub Actions Example

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run tests
        run: xcodebuild test -scheme vb2 -destination 'platform=macOS'
```

## Troubleshooting

### Tests Failing

1. **Clean build folder**: `⌘⇧K` or Product → Clean Build Folder
2. **Reset simulator**: In simulator, Device → Erase All Content and Settings
3. **Check test scheme**: Ensure test targets are enabled in scheme

### UI Tests Timing Out

1. Increase timeout: `element.waitForExistence(timeout: 10)`
2. Add explicit waits: `sleep(1)` (use sparingly)
3. Check element identifiers: Use Accessibility Inspector

### Settings Sheet Not Opening

If the Settings sheet doesn't appear in tests:
- The keyboard shortcut is **⌘⇧S** (Command+Shift+S), not ⌘,
- ⌘, conflicts with video player seek controls
- Ensure tests use `.typeKey("s", modifierFlags: [.command, .shift])`

### Flaky Tests

1. Make tests deterministic (no random values)
2. Clear state in setUp/tearDown
3. Use waitForExistence instead of exists for UI tests

## Code Coverage

View coverage in Xcode:
1. Enable coverage: Edit Scheme → Test → Options → Code Coverage
2. Run tests: `⌘U`
3. View report: Report Navigator → Coverage tab

Target: **80%+ coverage** for business logic

## Future Improvements

- [ ] Add integration tests with real video files
- [ ] Mock FileManager for file operations
- [ ] Test concurrent scan cancellation
- [ ] Test memory leaks with Instruments
- [ ] Add snapshot tests for UI
- [ ] Performance benchmarks for large playlists
- [ ] Test accessibility features
- [ ] Test keyboard navigation completely

## Resources

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Testing in Xcode](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode)
- [UI Testing Guide](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/chapters/09-ui_testing.html)
