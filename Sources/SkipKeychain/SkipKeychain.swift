// Copyright 2024 Skip
//
// This is free software: you can redistribute and/or modify it
// under the terms of the GNU Lesser General Public License 3.0
// as published by the Free Software Foundation https://fsf.org
import Foundation
#if !SKIP
import Security
#else
import android.content.Context
import android.content.SharedPreferences
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKeys
#endif

/// Secure storage using the iOS keychain and Android encrypted shared preferences.
public struct Keychain {
    /// The shared keychain.
    public static let shared = Keychain()

    private let lock = NSLock()

    /// Retrieve a value.
    public func string(forKey key: String) throws -> String? {
        #if !SKIP
        guard let data = try data(forKey: key) else {
            return nil
        }
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError(invalidValue: true)
        }
        return string
        #else
        do {
            let prefs = try initializePreferences()
            return prefs.getString(key, nil)
        } catch {
            throw KeychainError(message: error.localizedDescription)
        }
        #endif
    }

    /// Retrieve a value, attempting to parse the internal string as an int.
    public func int(forKey key: String) throws -> Int? {
        guard let string = try string(forKey: key) else {
            return nil
        }
        return Int(string)
    }

    /// Retrieve a value, atempting to parse the internal string as a double.
    public func double(forKey key: String) throws -> Double? {
        guard let string = try string(forKey: key) else {
            return nil
        }
        return Double(string)
    }

    /// Retrieve a value, interpresting an internal string value of "true" or "YES" as true and any other non-nil value as false.
    public func bool(forKey key: String) throws -> Bool? {
        guard let string = try string(forKey: key) else {
            return nil
        }
        return string == "true" || string == "YES"
    }

    /// Store a key value pair.
    public func set(_ string: String, forKey key: String, access: KeychainAccess = .unlocked) throws {
        #if !SKIP
        guard let data = string.data(using: .utf8) else {
            throw KeychainError(invalidValue: true)
        }
        try set(data, forKey: key, access: access)
        #else
        do {
            let prefs = try initializePreferences()
            let editor = prefs.edit()
            editor.putString(key, string)
            editor.apply()
        } catch {
            throw KeychainError(message: error.localizedDescription)
        }
        #endif
    }

    /// Store a key value pair. The given int will be stored using its string representation.
    public func set(_ value: Int, forKey key: String, access: KeychainAccess = .unlocked) throws {
        try set(value.description, forKey: key, access: access)
    }

    /// Store a key value pair. The given double will be stored using its string representation.
    public func set(_ value: Double, forKey key: String, access: KeychainAccess = .unlocked) throws {
        try set(value.description, forKey: key, access: access)
    }

    /// Store a key value pair. The given bool will be stored as the string 'true' or 'false'.
    public func set(_ value: Bool, forKey key: String, access: KeychainAccess = .unlocked) throws {
        try set(value ? "true" : "false", forKey: key, access: access)
    }

    #if !SKIP
    private func data(forKey key: String) throws -> Data? {
        lock.lock()
        defer { lock.unlock() }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: kCFBooleanTrue as Any
        ]
        var result: AnyObject?
        let code = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        guard code == errSecSuccess || code == errSecItemNotFound else {
            throw KeychainError(code: code)
        }
        return result as? Data
    }

    private func set(_ data: Data, forKey key: String, access: KeychainAccess) throws {
        lock.lock()
        defer { lock.unlock() }

        try removeHoldingLock(forKey: key)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: access.value
        ]
        let code = SecItemAdd(query as CFDictionary, nil)
        guard code == errSecSuccess else {
            throw KeychainError(code: code)
        }
    }
    #else
    private var preferences: SharedPreferences?

    private func initializePreferences() -> SharedPreferences {
        lock.lock()
        defer { lock.unlock() }

        if let preferences {
            return preferences
        }

        let context = ProcessInfo.processInfo.androidContext
        let alias = MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC)
        preferences = EncryptedSharedPreferences.create("tools.skip.SkipKeychain", alias, context, EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV, EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM)
        return preferences!
    }
    #endif

    /// Delete the value stored for the given key.
    public func removeValue(forKey key: String) throws {
        #if !SKIP
        lock.lock()
        defer { lock.unlock() }
        try removeHoldingLock(forKey: key)
        #else
        do {
            let prefs = try initializePreferences()
            let editor = prefs.edit()
            editor.remove(key)
            editor.apply()
        } catch {
            throw KeychainError(message: error.localizedDescription)
        }
        #endif
    }

    #if !SKIP
    private func removeHoldingLock(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        let code = SecItemDelete(query as CFDictionary)
        guard code == errSecSuccess || code == errSecItemNotFound else {
            throw KeychainError(code: code)
        }
    }
    #endif

    /// Return the set of all stored keys.
    public var keys: [String] {
        get throws {
            #if !SKIP
            lock.lock()
            defer { lock.unlock() }

            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecReturnAttributes as String: true,
                kSecReturnRef as String: true,
                kSecMatchLimit as String: kSecMatchLimitAll,
            ]
            var result: AnyObject?
            let code = withUnsafeMutablePointer(to: &result) {
                SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
            }
            guard code == errSecSuccess || code == errSecItemNotFound else {
                throw KeychainError(code: code)
            }
            guard let dicts = result as? [[String: Any]] else {
                return []
            }
            return dicts.compactMap { $0[kSecAttrAccount as String] as? String }
            #else
            return Array(initializePreferences().getAll().keys)
            #endif
        }
    }

    /// Remove all stored key value pairs.
    public func removeAll() throws {
        #if !SKIP
        lock.lock()
        defer { lock.unlock() }

        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword]
        let code = SecItemDelete(query as CFDictionary)
        guard code == errSecSuccess || code == errSecItemNotFound else {
            throw KeychainError(code: code)
        }
        #else
        do {
            let editor = initializePreferences().edit()
            editor.clear()
            editor.apply()
        } catch {
            throw KeychainError(message: error.localizedDescription)
        }
        #endif
    }
}

/// Access options - **iOS only**.
public enum KeychainAccess {
    /// Accessible when the device is unlocked.
    case unlocked
    /// Accessible only when the device is unlocked, and does not transfer to new devices.
    case unlockedThisDeviceOnly
    /// Accessible after the device is first unlocked until it is restarted.
    case firstUnlock
    /// Accessible after the device is first unlocked until it is restarted, and does not transfer to new devices.
    case firstUnlockThisDeviceOnly
    /// Accessible when the device is unlocked, only if a passcode is set on the device, and does not transfer to new devices.
    case passcodeSetThisDeviceOnly

    #if !SKIP
    var value: String {
        switch self {
        case .unlocked:
            return kSecAttrAccessibleWhenUnlocked as String
        case .unlockedThisDeviceOnly:
            return kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String
        case .firstUnlock:
            return kSecAttrAccessibleAfterFirstUnlock as String
        case .firstUnlockThisDeviceOnly:
            return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
        case .passcodeSetThisDeviceOnly:
            return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly as String
        }
    }
    #endif
}

/// Thrown on keychain error.
public struct KeychainError: Error, CustomStringConvertible {
    let message: String

    init(invalidValue: Bool = false) {
        self.message = invalidValue ? "Invalid value" : "Uknown error"
    }

    init(message: String) {
        self.message = message
    }

    #if !SKIP
    init(code: OSStatus) {
        self.message = SecCopyErrorMessageString(code, nil) as? String ?? "Unknown error"
    }
    #endif

    public var description: String {
        return message
    }
}
