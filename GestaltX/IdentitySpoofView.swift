// SPDX-License-Identifier: GPL-3.0-only
import SwiftUI

struct IdentitySpoofSection: View {
    @EnvironmentObject private var model: GestaltManager
    @State private var profileID = "18pro"
    @State private var scope = IdentitySpoof.Scope.product
    @State private var enableAI = false

    private var profile: IdentitySpoof.Profile {
        IdentitySpoof.profiles.first { $0.id == profileID } ?? IdentitySpoof.profiles[0]
    }

    var body: some View {
        Section {
            Text("Experiment with the identity used for Siri model eligibility. Expressive Voices are not confirmed to work.")
                .font(.footnote).foregroundStyle(.secondary)
            Picker("Report as", selection: $profileID) {
                ForEach(IdentitySpoof.profiles) { Text($0.name).tag($0.id) }
            }
            Picker("Change", selection: $scope) {
                ForEach(IdentitySpoof.Scope.allCases) { Text($0.rawValue).tag($0) }
            }
            Toggle("Also enable AI capability", isOn: $enableAI)
            Text("Target: \(profile.product) · \(profile.board) · \(profile.platform)")
                .font(.caption.monospaced()).textSelection(.enabled)
            Button("Stage Selected Identity") {
                model.stageIdentity(profile, scope: scope, enableAI: enableAI)
            }.disabled(!model.hasDocument)
            Button("Stage Original Identity") { model.stageOriginalIdentity() }
                .disabled(!model.canRestoreIdentity)
            if let document = model.preview {
                ShareLink("Share Identity Report", item: IdentitySpoof.report(document))
                Text("Report shows pending cached values, not a successful voice unlock.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Text("Review Changes and Apply writes the experiment. Restart manually, then test Siri. To undo, stage the original identity, review, apply and restart. Original values are saved before writing.")
                .font(.footnote).foregroundStyle(.secondary)
        } header: {
            Text("Siri Identity Lab · Experimental")
        } footer: {
            Text("Hardware identity spoofing can disrupt Face ID and model downloads. It does not add RAM or change the processor. Keep an exported original plist and a device backup. A failed boot can require a device restore.")
        }
    }
}
