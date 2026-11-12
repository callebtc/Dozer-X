import XCTest

final class MenuBarVisibilityStateTests: XCTestCase {
    func testShortcutRevealsEverySectionFromAnyHiddenState() {
        let hiddenStates = [
            MenuBarVisibilityState(hideNormal: true, hideRemove: true),
            MenuBarVisibilityState(hideNormal: true, hideRemove: false),
            MenuBarVisibilityState(hideNormal: false, hideRemove: true)
        ]
        for state in hiddenStates {
            XCTAssertEqual(state.applying(.toggleAll, extraEnabled: true), .expanded)
        }
    }

    func testNextShortcutHidesOnlyConfiguredSections() {
        XCTAssertEqual(
            MenuBarVisibilityState.expanded.applying(.toggleAll, extraEnabled: true),
            MenuBarVisibilityState(hideNormal: true, hideRemove: true)
        )
        XCTAssertEqual(
            MenuBarVisibilityState.expanded.applying(.toggleAll, extraEnabled: false),
            MenuBarVisibilityState(hideNormal: true, hideRemove: false)
        )
    }

    func testNormalDotAndOptionClickHaveDifferentRevealScopes() {
        let bothHidden = MenuBarVisibilityState(hideNormal: true, hideRemove: true)
        let normalShown = MenuBarVisibilityState(hideNormal: false, hideRemove: true)
        XCTAssertEqual(bothHidden.applying(.toggleNormal, extraEnabled: true), normalShown)
        XCTAssertEqual(normalShown.applying(.optionClick, extraEnabled: true), .expanded)
        XCTAssertEqual(MenuBarVisibilityState.expanded.applying(.optionClick, extraEnabled: true), normalShown)
    }

    func testRecoveryRevealsBothSectionsRegardlessOfConfiguration() {
        let bothHidden = MenuBarVisibilityState(hideNormal: true, hideRemove: true)
        XCTAssertEqual(bothHidden.applying(.revealAll, extraEnabled: true), .expanded)
        XCTAssertEqual(bothHidden.applying(.revealAll, extraEnabled: false), .expanded)
    }
}
