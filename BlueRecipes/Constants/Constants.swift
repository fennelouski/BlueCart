//
//  Constants.swift
//  BlueRecipes
//
//  Created by Nathan Fennel on 1/14/18.
//  Copyright © 2018 Nathan Fennel. All rights reserved.
//

import UIKit

class Constants {
    /// ","
    static let apiConcatenationSeparator = ","
    /// CharacterSet containing contents of apiConcatenationSeparator
    static let apiConcatenationSeparatorSet = CharacterSet(charactersIn: apiConcatenationSeparator)
    /// 0.3
    static let animationDuration: TimeInterval = 0.3
    /// 2.0
    static let backgroundAnimationDuration: TimeInterval = 2.0
    /// "http://food2fork.com/api/get"
    static let baseRecipeRequestURLString = "http://food2fork.com/api/get"
    /// "http://food2fork.com/api/get" as! URL
    static let baseRecipeRequestURL = URL(string: baseRecipeRequestURLString)!
    /// "http://food2fork.com/api/search"
    static let baseSearchURLString = "http://food2fork.com/api/search"
    /// "http://food2fork.com/api/search" as! URL
    static let baseSearchURL = URL(string: baseSearchURLString)!
    /// "cell identifier"
    static let cellIdentifier = "cell identifier"
    /// 6.0
    static let defaultInset: CGFloat = 6
    /// 0.5
    static let jpegCompressionAmount: CGFloat = 0.5
    /// "lastPageKey"
    static let lastPageKey = "lastPageKey"
    /// 30
    static let maxRecipeRequestCount: Int = 30
    /// 5
    static let maxSearchPage: Int = 5
    /// 6.0
    static let parallaxIntensity: CGFloat = 6
    /// "Food2Fork"
    static let serviceName = "Food2Fork"
}
