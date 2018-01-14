//
//  RecipeModel.swift
//  BlueRecipes
//
//  Created by Nathan Fennel on 1/14/18.
//  Copyright © 2018 Nathan Fennel. All rights reserved.
//

import Foundation
import Unbox

class RecipeModel: Unboxable {
    /// Recipe ID as returned by Search Query
    let id: String?
    /// URL of the image
    let imageURLString: String
    /// URL of the image
    lazy var imageURL: URL? = {
        return URL(string: imageURLString)
    }()
    /// Original URL String of the recipe on the publisher's site
    let sourceURLString: String
    /// Original URL of the recipe on the publisher's site
    lazy var sourceURL: URL? = {
        return URL(string: sourceURLString)
    }()
    /// URL String of the recipe on Food2Fork.com
    let food2ForkURLString: String
    /// URL of the recipe on Food2Fork.com
    lazy var food2ForkURL: URL? = {
        return URL(string: food2ForkURLString)
    }()
    /// Title of the recipe
    let title: String
    /// Name of the Publisher
    let publisher: String
    /// Base url of the publisher
    let publisherURL: String
    /// The Social Ranking of the Recipe (As determined by the Food2Fork.com Ranking Algorithm)
    let socialRank: String
    /// The ingredients of this recipe
    let ingredients: [String]

    required init(unboxer: Unboxer) throws {
        id = unboxer.unbox(key: APIKeys.recipeID)
        imageURLString = try unboxer.unbox(key: APIKeys.imageURL)
        sourceURLString = try unboxer.unbox(key: APIKeys.sourceURL)
        food2ForkURLString = try unboxer.unbox(key: APIKeys.food2ForkURL)
        title = try unboxer.unbox(key: APIKeys.title)
        publisher = try unboxer.unbox(key: APIKeys.publisher)
        publisherURL = try unboxer.unbox(key: APIKeys.publisherURL)
        socialRank = try unboxer.unbox(key: APIKeys.socialRank)
        ingredients = try unboxer.unbox(key: APIKeys.ingredients)
    }
}
