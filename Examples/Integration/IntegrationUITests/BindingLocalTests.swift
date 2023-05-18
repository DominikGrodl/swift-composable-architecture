import TestCases
import XCTest

@MainActor
final class BindingLocalTests: BaseIntegrationTests {
  func testNoBindingWarning_FullScreenCover() {
    app.collectionViews.buttons[TestCase.bindingLocal.rawValue].tap()

    app.buttons["Full-screen-cover"].tap()

    app.textFields["Text"].tap()

    app.buttons["Dismiss"].tap()
  }

  func testOnDisappearWarning_FullScreenCover() {
    self.expectRuntimeWarnings = true

    app.collectionViews.buttons[TestCase.bindingLocal.rawValue].tap()

    app.buttons["Full-screen-cover"].tap()

    app.buttons["Send onDisappear"].tap()

    app.textFields["Text"].tap()

    app.buttons["Dismiss"].tap()
  }

  func testNoBindingWarning_Popover() {
    app.collectionViews.buttons[TestCase.bindingLocal.rawValue].tap()

    app.buttons["Popover"].tap()

    app.textFields["Text"].tap()

    app.buttons["Dismiss"].tap()
  }

  func testOnDisappearWarning_Popover() {
    self.expectRuntimeWarnings = true

    app.collectionViews.buttons[TestCase.bindingLocal.rawValue].tap()

    app.buttons["Popover"].tap()

    app.buttons["Send onDisappear"].tap()

    app.textFields["Text"].tap()

    app.buttons["Dismiss"].tap()
  }

  func testNoBindingWarning_Sheet() {
    app.collectionViews.buttons[TestCase.bindingLocal.rawValue].tap()

    app.buttons["Sheet"].tap()

    app.textFields["Text"].tap()

    app.buttons["Dismiss"].tap()
  }

  func testOnDisappearWarning_Sheet() {
    self.expectRuntimeWarnings = true

    app.collectionViews.buttons[TestCase.bindingLocal.rawValue].tap()

    app.buttons["Sheet"].tap()

    app.buttons["Send onDisappear"].tap()

    app.textFields["Text"].tap()

    app.buttons["Dismiss"].tap()
  }
}
