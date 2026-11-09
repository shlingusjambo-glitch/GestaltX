// SPDX-License-Identifier: GPL-3.0-only
import Foundation
import FoundationModels

enum SiriModelDiagnostics {
    @MainActor static func collect() -> String {
        var lines = ["Siri model diagnostics (read only)",
                     "OS: \(ProcessInfo.processInfo.operatingSystemVersionString)",
                     "Physical memory: \(ProcessInfo.processInfo.physicalMemory) bytes"]
        let capabilities = GXCopySiriCapabilityDiagnostics()
        for key in capabilities.keys.sorted() {
            lines.append("MobileGestalt \(key): \(capabilities[key]!)")
        }
        let model = SystemLanguageModel.default
        let status: String
        switch model.availability {
        case .available: status = "available"
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible: status = "deviceNotEligible"
            case .appleIntelligenceNotEnabled: status = "appleIntelligenceNotEnabled"
            case .modelNotReady: status = "modelNotReady (downloading or another system prerequisite)"
            @unknown default: status = "unknown unavailable reason"
            }
        }
        lines.append("Foundation Models availability: \(status)")
        if #available(iOS 27.0, *) {
            let tier = model.variant == .coreAdvanced3 ? "coreAdvanced3" : model.variant == .core3 ? "core3" : "unknown"
            lines.append("Selected Foundation Models variant: \(tier) (\(model.variant.displayName))")
            if tier == "core3" {
                lines.append("The default API still selects the base model. A product-name spoof has not established advanced-model selection.")
            }
            lines.append("Selected variant is not proof of completed download or Siri voice eligibility.")
        }
        lines.append("This API does not enumerate installed Siri voice assets or identify the model used by a Siri conversation.")
        lines.append("No models were deleted, requested or generated; no settings were changed.")
        return lines.joined(separator: "\n")
    }

    @MainActor static func save() throws -> URL {
        let report = collect()
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("SiriModelDiagnostics.txt")
        try report.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
