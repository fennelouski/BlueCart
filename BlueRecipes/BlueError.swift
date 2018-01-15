//
//  BlueError.swift
//  BlueRecipes
//
//  Created by Nathan Fennel on 1/14/18.
//  Copyright © 2018 Nathan Fennel. All rights reserved.
//

import Foundation

// TODO: Add an error enum
// ...then I have all the types

protocol CodeBlue: LocalizedError {
    var title: String? { get }
    var code: Int { get }
}

struct BlueRecipeError: CodeBlue {
    var title: String?
    var code: Int
    var errorDescription: String? {
        return _description
    }
    var failureReason: String? {
        return _description
    }

    private var _description: String

    init(title: String?, description: String, code: Int) {
        self.title = title ?? "Error"
        self._description = description
        self.code = code
    }
}

class BlueRecipeErrorCode {
    /// 7
    static let missingInitializationProperty: Int = 7
}
