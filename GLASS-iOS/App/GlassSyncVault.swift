import Foundation
import CryptoKit
import Security

enum GlassSyncCryptoError: Error {
    case keychain(OSStatus)
    case invalidKey
    case invalidEnvelope
    case encryptionFailed
    case decryptionFailed
}

enum GlassSyncVault {
    private static let service = "com.gorooo.glass.sync"
    private static let account = "payload-encryption-key.v1"
    private static let aad = Data("com.gorooo.glass.sync.payload.v1".utf8)
    private static let envelopePrefix = "glass.aesgcm.v1."

    private static func loadOrCreateKey() throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess, let data = item as? Data, data.count == 32 {
            return SymmetricKey(data: data)
        }
        if status != errSecSuccess && status != errSecItemNotFound {
            throw GlassSyncCryptoError.keychain(status)
        }

        var bytes = Data(count: 32)
        let randomStatus = bytes.withUnsafeMutableBytes { buffer in
            SecRandomCopyBytes(kSecRandomDefault, 32, buffer.baseAddress!)
        }
        guard randomStatus == errSecSuccess else {
            throw GlassSyncCryptoError.keychain(randomStatus)
        }

        let add: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: bytes,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        let addStatus = SecItemAdd(add as CFDictionary, nil)
        if addStatus == errSecDuplicateItem {
            return try loadOrCreateKey()
        }
        guard addStatus == errSecSuccess else {
            throw GlassSyncCryptoError.keychain(addStatus)
        }
        return SymmetricKey(data: bytes)
    }

    static func seal<T: Encodable>(_ value: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        let plaintext = try encoder.encode(value)
        let key = try loadOrCreateKey()
        do {
            let box = try AES.GCM.seal(plaintext, using: key, authenticating: aad)
            guard let combined = box.combined else { throw GlassSyncCryptoError.encryptionFailed }
            return envelopePrefix + combined.base64EncodedString()
        } catch let error as GlassSyncCryptoError {
            throw error
        } catch {
            throw GlassSyncCryptoError.encryptionFailed
        }
    }

    static func open<T: Decodable>(_ envelope: String, as type: T.Type) throws -> T {
        guard envelope.hasPrefix(envelopePrefix),
              let combined = Data(base64Encoded: String(envelope.dropFirst(envelopePrefix.count))),
              let box = try? AES.GCM.SealedBox(combined: combined) else {
            throw GlassSyncCryptoError.invalidEnvelope
        }
        let key = try loadOrCreateKey()
        let plaintext: Data
        do {
            plaintext = try AES.GCM.open(box, using: key, authenticating: aad)
        } catch {
            throw GlassSyncCryptoError.decryptionFailed
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: plaintext)
    }
}

struct GlassSyncTab: Codable, Equatable {
    let id: UUID
    let spaceID: String
    let address: String
}

struct GlassSyncSnapshot: Codable {
    let schemaVersion: Int
    let createdAt: Date
    let bookmarks: [BrowserBookmark]
    let history: [String]
    let spaces: [BrowserSpace]
    let tabs: [GlassSyncTab]
    let activeTabID: UUID?
    let activeSpaceID: String
    let settings: GlassBrowserSettings
}
