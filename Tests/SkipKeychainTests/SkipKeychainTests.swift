import XCTest
import OSLog
import Foundation
@testable import SkipKeychain

let logger: Logger = Logger(subsystem: "test", category: "SkipKeychainTests")

// SKIP INSERT: @org.junit.runner.RunWith(androidx.test.ext.junit.runners.AndroidJUnit4::class)
final class SkipKeychainTests: XCTestCase {
    let key = "SkipKeychainTestsKey"

    func testString() throws {
        try skipRoboelectric()
        let keychain = Keychain.shared
        try keychain.removeValue(forKey: key)
        try XCTAssertNil(keychain.string(forKey: key))
        try keychain.set("value", forKey: key)
        try XCTAssertEqual(keychain.string(forKey: key), "value")
    }

    func testUpdate() throws {
        try skipRoboelectric()
        let keychain = Keychain.shared
        try keychain.removeValue(forKey: key)
        try keychain.set("value", forKey: key)
        try XCTAssertEqual(keychain.string(forKey: key), "value")
        try keychain.set("value2", forKey: key)
        try XCTAssertEqual(keychain.string(forKey: key), "value2")
    }

    func testRemoveValueForKey() throws {
        try skipRoboelectric()
        let keychain = Keychain.shared
        try keychain.removeValue(forKey: key)
        try keychain.removeValue(forKey: "nonexistantkey")
        try keychain.set("value", forKey: key)
        try XCTAssertEqual(keychain.string(forKey: key), "value")
        try keychain.removeValue(forKey: key)
        try XCTAssertNil(keychain.string(forKey: key))
    }

    func testKeys() throws {
        try skipRoboelectric()
        let keychain = Keychain.shared
        try keychain.removeValue(forKey: key)
        try XCTAssertFalse(keychain.keys.contains(key))
        try keychain.set("value", forKey: key)
        try XCTAssertTrue(keychain.keys.contains(key))
    }

    func testBool() throws {
        try skipRoboelectric()
        let keychain = Keychain.shared
        try keychain.removeValue(forKey: key)
        try XCTAssertNil(keychain.bool(forKey: key))
        try keychain.set(true, forKey: key)
        try XCTAssertEqual(keychain.bool(forKey: key), true)
        try keychain.set(false, forKey: key)
        try XCTAssertEqual(keychain.bool(forKey: key), false)
    }

    func testInt() throws {
        try skipRoboelectric()
        let keychain = Keychain.shared
        try keychain.removeValue(forKey: key)
        try XCTAssertNil(keychain.int(forKey: key))
        try keychain.set(100, forKey: key)
        try XCTAssertEqual(keychain.int(forKey: key), 100)
    }

    func testDouble() throws {
        try skipRoboelectric()
        let keychain = Keychain.shared
        try keychain.removeValue(forKey: key)
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
