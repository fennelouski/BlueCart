//
//  APIKeys.swift
//  BlueRecipes
//
//  Created by Nathan Fennel on 1/14/18.
//  Copyright © 2018 Nathan Fennel. All rights reserved.
//

import Foundation

class APIKeys {
    /// "count"
    static let count = "count"
    /// "f2f_url"
    static let food2ForkURL = "f2f_url"
    /// "image_url"
    static let imageURL = "image_url"
    /// "ingredients"
    static let ingredients = "ingredients"
    /// "key"
    static let key = "key"
    /// "page"
    static let page = "page"
    /// "publisher"
    static let publisher = "publisher"
    /// "publisher_url"
    static let publisherURL = "publisher_url"
    /// "q"
    static let query = "q"
    /// "r"
    static let rating = "r"
    /// "rId"
    static let recipeID = "rId"
    /// "recipes"
    static let recipes = "recipes"
    /// "social_rank"
    static let socialRank = "social_rank"
    /// "sort"
    static let sort = "sort"
    /// "source_url"
    static let sourceURL = "source_url"
    /// "title"
    static let title = "title"
    /// "t"
    static let trendScore = "t"
}

enum apiSortOption {
    case rating, trendScore

    var key: String {
        switch self {
        case .rating:
            return APIKeys.rating
        case .trendScore:
            return APIKeys.trendScore
        }
    }

}
