//
//  GestaltXApp.swift
//  GestaltX
//

import SwiftUI

@main
struct GestaltXApp: App {
    var body: some Scene {
        WindowGroup {
            if ProcessInfo.processInfo.arguments.contains("--siri-model-diagnostics") {
                Text("Reading model diagnostics…")
                    .task {
                        do {
                            let url = try SiriModelDiagnostics.save()
                            print(try String(contentsOf: url, encoding: .utf8))
                            fflush(stdout)
                            exit(0)
                        } catch {
                            print("Diagnostic failed: \(error.localizedDescription)")
                            fflush(stdout)
                            exit(1)
                        }
                    }
            } else {
                ContentView()
                .environment(\.layoutDirection, Bundle.main.preferredLocalizations.first?.hasPrefix("fa") == true ? .rightToLeft : .leftToRight)
            }
        }
    }
}
