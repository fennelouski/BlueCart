//
//  Constants.swift
//  BlueRecipes
//
//  Created by Nathan Fennel on 1/14/18.
//  Copyright © 2018 Nathan Fennel. All rights reserved.
//

import Foundation

class Constants {
    /// "http://food2fork.com/api/get"
    static let baseRecipeRequestURLString = "http://food2fork.com/api/get"
    /// "http://food2fork.com/api/get" as! URL
    static let baseRecipeRequestURL = URL(string: baseRecipeRequestURLString)!
    /// "http://food2fork.com/api/search"
    static let baseSearchURLString = "http://food2fork.com/api/search"
    /// "http://food2fork.com/api/search" as! URL
    static let baseSearchURL = URL(string: baseSearchURLString)!
}
