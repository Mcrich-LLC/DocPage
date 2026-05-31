//
//  DocumentationNavigator.swift
//  DocCKit-Test
//
//  Created by Morris Richman on 5/30/26.
//

import SwiftUI
import DocCKit

@Observable
@MainActor
final class DocumentationNavigator: DocCNavigator {
    var reference: Reference?
    var technology: AppleTechnologies.FrameworkSection?
    var isUsingSplitView = false

    // By default this tries to read the app's Info.plist URL schemes.
    // You can also make it explicit:
    var deepLinkScheme = DocCDeepLinkScheme("my-app-docs")

    func setReference(_ reference: Reference?, forceHistory: Bool) {
        self.reference = reference
    }

    func setTechnology(_ technology: AppleTechnologies.FrameworkSection?, noHistory: Bool) {
        self.technology = technology
    }

    func showHomepage() {
        reference = nil
        technology = nil
    }
}
