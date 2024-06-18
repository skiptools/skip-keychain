import XCTest
import OSLog
import Foundation
@testable import SkipKeychain

// SKIP INSERT: @org.junit.runner.RunWith(androidx.test.ext.junit.runners.AndroidJUnit4::class)
final class SkipKeychainTests: XCTestCase {
    let key = "SkipKeychainTestsKey"

    override func setUp() {
        guard !isRobolectric else {
            return
        }
        try? Keychain.shared.removeValue(forKey: key)
    }

    func testString() throws {
        try skipRoboelectric()
        let keychain = Keychain.shared
        try XCTAssertNil(keychain.string(forKey: key))
        try keychain.set("value", forKey: key)
        try XCTAssertEqual(keychain.string(forKey: key), "value")
    }

    func testRemoveValueForKey() throws {
        try skipRoboelectric()
        let keychain = Keychain.shared
        try keychain.removeValue(forKey: "nonexistantkey")
        try keychain.set("value", forKey: key)
        try XCTAssertEqual(keychain.string(forKey: key), "value")
        try keychain.removeValue(forKey: key)
        try XCTAssertNil(keychain.string(forKey: key))
    }

    func testKeys() throws {
        try skipRoboelectric()
        let keychain = Keychain.shared
        try XCTAssertFalse(keychain.keys.contains(key))
        try keychain.set("value", forKey: key)
        try XCTAssertTrue(keychain.keys.contains(key))
    }

    func testBool() throws {
        try skipRoboelectric()
        let keychain = Keychain.shared
        try XCTAssertNil(keychain.bool(forKey: key))
        try keychain.set(true, forKey: key)
        try XCTAssertEqual(keychain.bool(forKey: key), true)
        try keychain.set(false, forKey: key)
        try XCTAssertEqual(keychain.bool(forKey: key), false)
    }

    func testInt() throws {
        try skipRoboelectric()
        let keychain = Keychain.shared
        try XCTAssertNil(keychain.int(forKey: key))
        try keychain.set(100, forKey: key)
        try XCTAssertEqual(keychain.int(forKey: key), 100)
    }

    func testDouble() throws {
        try skipRoboelectric()
        let keychain = Keychain.shared
        try XCTAssertNil(keychain.double(forKey: key))
        try keychain.set(99.5, forKey: key)
        try XCTAssertEqual(keychain.double(forKey: key), 99.5)
    }

    private func skipRoboelectric() throws {
        if isRobolectric {
            throw XCTSkip("Roboelectric does not support AndroidKeyStore")
        }
    }
}