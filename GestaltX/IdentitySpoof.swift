// SPDX-License-Identifier: GPL-3.0-only
import Foundation

/// Experimental cached identity edits. This does not establish model eligibility.
enum IdentitySpoof {
    static let productKey = "h9jDsbgj7xIVeIQ8S3/X3Q"
    static let boardKey = "oYicEKzVTz4/CxxE05pEgQ"
    static let platformKey = "5pYKlGnYYBzGvAlIU8RjEQ"
    static let aiKey = "A62OafQ85EJAiiqKn4agtg"
    static let keys: Set<String> = [productKey, boardKey, platformKey, aiKey]

    struct Profile: Identifiable, Equatable {
        let id: String
        let name: String
        let product: String
        let board: String
        let platform: String
    }

    enum Scope: String, CaseIterable, Identifiable {
        case product = "Product identifier only"
        case hardware = "Product, board and platform"
        var id: String { rawValue }
    }

    static func applying(_ profile: Profile, scope: Scope, enableAI: Bool,
                         to original: GestaltDocument) throws -> GestaltDocument {
        guard profiles.contains(profile),
              let current = original.extra[productKey] as? String, current.hasPrefix("iPhone") else {
            throw GestaltFailure("Identity experiments require an iPhone MobileGestalt document.")
        }
        // Reject partial hardware sets rather than fabricate fields missing from this cache.
        if scope == .hardware {
            guard original.extra[boardKey] is String, original.extra[platformKey] is String else {
                throw GestaltFailure("This cache does not contain the board and platform fields. Use product identifier only.")
            }
        }
        var result = original
        result.set(profile.product, for: productKey)
        if scope == .hardware {
            result.set(profile.board, for: boardKey)
            result.set(profile.platform, for: platformKey)
        }
        if enableAI { result.set(NSNumber(value: true), for: aiKey) }
        return result
    }

    /// Use the durable original-value journal, including absence and exact plist types.
    static func restoring(_ document: GestaltDocument, from baseline: DocumentSnapshot) -> GestaltDocument {
        var result = document
        for key in keys { result.set(baseline.originalValue(for: key), for: key) }
        return result
    }

    /// Deliberately excludes serial numbers, UDIDs, account details and the rest of the plist.
    static func report(_ document: GestaltDocument) -> String {
        let names = [("ProductType", productKey), ("TargetSubType", boardKey),
                     ("HardwarePlatform", platformKey), ("Apple Intelligence capability", aiKey)]
        return (["GestaltX Identity Lab — cached values; voice functionality is unverified"] + names.map { name, key in
            let value = document.extra[key].map { String(describing: $0) } ?? "absent"
            return "\(name): \(value)"
        }).joined(separator: "\n")
    }
}
