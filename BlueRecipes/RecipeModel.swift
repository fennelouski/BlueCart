//
//  RecipeModel.swift
//  BlueRecipes
//
//  Created by Nathan Fennel on 1/14/18.
//  Copyright © 2018 Nathan Fennel. All rights reserved.
//

import CoreData
import Foundation
import Unbox

class RecipeModel: NSObject, Unboxable {
    /// Recipe ID as returned by Search Query
    let id: String?
    /// URL of the image
    let imageURLString: String?
    /// URL of the image
    lazy var imageURL: URL? = {
        guard let imageURLString = imageURLString else { return nil }
        return URL(string: imageURLString)
    }()
    /// Original URL String of the recipe on the publisher's site
    let sourceURLString: String?
    /// Original URL of the recipe on the publisher's site
    lazy var sourceURL: URL? = {
        guard let sourceURLString = sourceURLString else { return nil }
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
    let publisherURLString: String?
    /// URL of the recipe on Food2Fork.com
    lazy var publisherURLS: URL? = {
        guard let publisherURLString = publisherURLString else { return nil }
        return URL(string: publisherURLString)
    }()
    /// The Social Ranking of the Recipe (As determined by the Food2Fork.com Ranking Algorithm)
    let socialRank: String?
    /// The ingredients of this recipe
    let ingredients: [String]?

    required init(unboxer: Unboxer) throws {
        id = unboxer.unbox(key: APIKeys.recipeID)
        imageURLString = unboxer.unbox(key: APIKeys.imageURL)
        sourceURLString = unboxer.unbox(key: APIKeys.sourceURL)
        food2ForkURLString = try unboxer.unbox(key: APIKeys.food2ForkURL)
        title = try unboxer.unbox(key: APIKeys.title)
        publisher = try unboxer.unbox(key: APIKeys.publisher)
        publisherURLString = unboxer.unbox(key: APIKeys.publisherURL)
        socialRank = unboxer.unbox(key: APIKeys.socialRank)
        ingredients = unboxer.unbox(key: APIKeys.ingredients)
    }

    
    init(entity: Recipe) throws {
        imageURLString = entity.imageURLString
        sourceURLString = entity.sourceURLString
        id = entity.id
        ingredients = entity.ingredients?.components(separatedBy: Constants.apiConcatenationSeparatorSet)
        
        publisherURLString = entity.publisherURLString
        socialRank = entity.socialRank
        guard let food2ForkURLString = entity.food2ForkURLString,
            let title = entity.title,
            let publisher = entity.publisher else {
                print("\(entity.description)")
                throw BlueRecipeError(title: "Missing property on initialization",
                                      description: "At least one of the required properties for initialization was missing.",
                                      code: BlueRecipeErrorCode.missingInitializationProperty)
        }
        self.food2ForkURLString = food2ForkURLString
        self.title = title
        self.publisher = publisher
        super.init()
    }

    override var description: String {
        var compositeDescription = super.description
        if let id = id {
            compositeDescription += "\nid: \(id)"
        }
        if let imageURLString = imageURLString {
            compositeDescription += "\nimageURLString: \(imageURLString)"
        }
        if let sourceURLString = sourceURLString {
            compositeDescription += "\nsourceURLString: \(sourceURLString)"
        }
        compositeDescription += "\nfood2ForkURLString: \(food2ForkURLString)"
        compositeDescription += "\ntitle: \(title)"
        compositeDescription += "\npublisher: \(publisher)"
        if let publisherURLString = publisherURLString {
            compositeDescription += "\npublisherURLString: \(publisherURLString)"
        }
        compositeDescription += "\nsocialRank: \(socialRank)"
        if let ingredients = ingredients {
            compositeDescription += "\ningredients: \(ingredients)"
        }

        return compositeDescription
    }

    func recipeEntity(from context: NSManagedObjectContext) -> Recipe {
        let recipe = Recipe(context: context)
        recipe.id = id
        recipe.ingredients = ingredients?.joined(separator: Constants.apiConcatenationSeparator)
        recipe.imageURLString = imageURLString
        recipe.sourceURLString = sourceURLString
        recipe.food2ForkURLString = food2ForkURLString
        recipe.title = title
        recipe.publisher = publisher

        return recipe
    }
}

extension Recipe {
    public override var description: String {
        var compositeDescription = super.description
        if let id = id {
            compositeDescription += "\nid: \(id)"
        }
        if let imageURLString = imageURLString {
            compositeDescription += "\nimageURLString: \(imageURLString)"
        }
        if let sourceURLString = sourceURLString {
            compositeDescription += "\nsourceURLString: \(sourceURLString)"
        }
        if let food2ForkURLString = food2ForkURLString {
            compositeDescription += "\nfood2ForkURLString: \(food2ForkURLString)"
        }
        if let title = title {
            compositeDescription += "\ntitle: \(title)"
        }
        if let publisher = publisher {
            compositeDescription += "\n: \(publisher)"
        }
        if let publisherURLString = publisherURLString {
            compositeDescription += "\n: \(publisherURLString)"
        }
        if let socialRank = socialRank {
            compositeDescription += "\n: \(socialRank)"
        }
        if let ingredients = ingredients {
            compositeDescription += "\ningredients: \(ingredients)"
        }

        return compositeDescription

    }
}
