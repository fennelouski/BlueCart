//
//  String+HTTPUtilities.swift
//  BlueRecipes
//
//  Created by Nathan Fennel on 1/15/18.
//  Copyright © 2018 Nathan Fennel. All rights reserved.
//

import Foundation

extension String {
    /// Removes some of the most common types of http encoding errors
    func cleaned() -> String {
        let replacements = ["&#8217;" : "'",
                            "&amp;"   : "&",
                            "&#39;"   : "`",
                            "www."    : "",]
        var runningClean = self
        for key in replacements.keys {
            guard let value = replacements[key] else { continue }
            runningClean = runningClean.replacingOccurrences(of: key, with: value)
        }

        return runningClean
    }

    func stripToDomainAndTLD() -> String {
        let slashSet = CharacterSet(charactersIn: "/")
        let periodSet = CharacterSet(charactersIn: ".")
        let components = self.components(separatedBy: slashSet)
        let topLevelDomains = [".com", ".org", ".net", ".gov", ".co"]
        for component in components {
            let subComponents = component.components(separatedBy: periodSet)
            guard let lastComponent = subComponents.last else { return self }
            if topLevelDomains.contains(lastComponent) {
                return component.cleaned()
            }
        }
    }
}
