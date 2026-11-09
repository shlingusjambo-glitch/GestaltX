import Foundation

enum IdentityTestFailure: Error { case failed(String) }
func check(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() { throw IdentityTestFailure.failed(message) }
}

@main struct IdentitySpoofTests {
    static func main() async throws {
        let fm = FileManager.default
        let directory = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: directory) }
        for ai in [nil, NSNumber(value: false), NSNumber(value: 2)] as [NSNumber?] {
            var extra: [String: Any] = [
                IdentitySpoof.productKey: "iPhone18,3", IdentitySpoof.boardKey: "V57AP",
                IdentitySpoof.platformKey: "t8150", GestaltKeys.regionCode: "US",
                "VasUgeSzVyHdB27g2XpN0g": "TESTSERIAL", "unrelated": Data([4, 5, 6])
            ]
            extra[IdentitySpoof.aiKey] = ai
            let data = try PropertyListSerialization.data(fromPropertyList: [
                "CacheExtra": extra, "CacheData": Data([1, 2, 3]), "CacheUUID": "unchanged"
            ], format: .binary, options: 0)
            let original = try GestaltDocument(data: data)
            let path = directory.appendingPathComponent(UUID().uuidString + ".plist")
            try data.write(to: path)
            let backups = directory.appendingPathComponent(UUID().uuidString)
            let store = GestaltFileStore(deviceURL: path, backupDirectory: backups, deviceID: "fixture",
                                        acquire: { 1 }, release: { _ in })
            var loaded = try await store.loadDevice()
            for profile in IdentitySpoof.profiles {
                for scope in IdentitySpoof.Scope.allCases {
                    let edited = try IdentitySpoof.applying(profile, scope: scope, enableAI: true, to: loaded.document)
                    try check(edited.extra[IdentitySpoof.productKey] as? String == profile.product, "Set target product")
                    try check(edited.extra[IdentitySpoof.boardKey] as? String == (scope == .hardware ? profile.board : "V57AP"), "Respect scope")
                    try check(edited.extra[IdentitySpoof.platformKey] as? String == (scope == .hardware ? profile.platform : "t8150"), "Set platform only with hardware scope")
                    var expected = original
                    for key in IdentitySpoof.keys { expected.set(edited.extra[key], for: key) }
                    try check(edited.matches(expected), "No region, serial, RAM, CacheData or unrelated mutations")
                    _ = try await store.commit(edited, expected: loaded)
                    // Simulate an app relaunch and deletion of visible backup files.
                    for record in try await store.backups() { try await store.deleteBackup(record) }
                    let reopened = GestaltFileStore(deviceURL: path, backupDirectory: backups, deviceID: "fixture",
                                                   acquire: { 1 }, release: { _ in })
                    let baseline = try await reopened.loadDevice()
                    let restored = IdentitySpoof.restoring(baseline.document, from: baseline)
                    try check(restored.matches(original), "Restore exact original values, presence and types after relaunch")
                    _ = try await reopened.commit(restored, expected: baseline)
                    loaded = try await store.loadDevice()
                    try check(loaded.document.matches(original), "Restored data persists")
                }
            }
            var otherEdit = loaded.document
            otherEdit.set("new unrelated value", for: "unrelated")
            let mixed = try IdentitySpoof.applying(IdentitySpoof.profiles[1], scope: .hardware, enableAI: true, to: otherEdit)
            try check(IdentitySpoof.restoring(mixed, from: loaded).extra["unrelated"] as? String == "new unrelated value", "Identity restoration preserves unrelated pending edits")
            let noAIEdit = try IdentitySpoof.applying(IdentitySpoof.profiles[0], scope: .product, enableAI: false, to: original)
            var expectedProductOnly = original
            expectedProductOnly.set(IdentitySpoof.profiles[0].product, for: IdentitySpoof.productKey)
            try check(noAIEdit.matches(expectedProductOnly), "Product-only mutation preserves every other value, including an absent AI field")
            let report = IdentitySpoof.report(mixed)
            try check(!report.contains("TESTSERIAL") && !report.contains("unrelated"), "Report excludes private and unrelated fields")
            var incomplete = original
            incomplete.set(nil, for: IdentitySpoof.boardKey)
            do {
                _ = try IdentitySpoof.applying(IdentitySpoof.profiles[1], scope: .hardware, enableAI: true, to: incomplete)
                throw IdentityTestFailure.failed("Missing hardware fields must reject")
            } catch is GestaltFailure {}
            var ipad = original
            ipad.set("iPad16,1", for: IdentitySpoof.productKey)
            do {
                _ = try IdentitySpoof.applying(IdentitySpoof.profiles[1], scope: .product, enableAI: true, to: ipad)
                throw IdentityTestFailure.failed("Non-iPhone documents must reject")
            } catch is GestaltFailure {}
        }
        print("Identity spoof tests passed: scope isolation, persisted rollback, absent fields, types, privacy and validation.")
    }
}
