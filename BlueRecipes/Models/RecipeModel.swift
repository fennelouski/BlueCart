//
//  RecipeModel.swift
//  BlueRecipes
//
//  Created by Nathan Fennel on 1/14/18.
//  Copyright © 2018 Nathan Fennel. All rights reserved.
//

import CoreData
import UIKit
import Unbox

class RecipeModel: NSObject, Unboxable {
    /// Recipe ID as returned by Search Query
    let id: String
    /// Whether or not the user has favorited this recipe
    var isFavorite: Bool = false {
        didSet {
            saveFavorite()
        }
    }
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
    /// Image of the publisher based on the publisher url
    lazy var publisherImage: UIImage? = {
        guard let url = publisherURLString ?? sourceURLString else { return nil }
        return ImageManager.getFavicon(for: url) { image in
            print("any success? \(image)")
        }
    }()
    /// URL of the recipe on Food2Fork.com
    lazy var publisherURL: URL? = {
        guard let publisherURLString = publisherURLString else { return nil }
        return URL(string: publisherURLString)
    }()
    /// All text that can be searched in lowercased format
    lazy var searchableText: String = {
        var searchableText = ""
        searchableText += "\nid: \(id)"
        if let sourceURLString = sourceURLString {
            searchableText += "\nsourceURLString: \(sourceURLString)"
        }
        searchableText += "\nfood2ForkURLString: \(food2ForkURLString)"

        searchableText += "\ntitle: \(title)"

        searchableText += "\npublisher: \(publisher)"

        if let publisherURLString = publisherURLString {
            searchableText += "\npublisherURLString: \(publisherURLString)"
        }

        if let ingredients = ingredients {
            searchableText += "\ningredients: \(ingredients.joined(separator: " "))"
        }

        return searchableText.lowercased()
    }()
    /// The Social Ranking of the Recipe (As determined by the Food2Fork.com Ranking Algorithm)
    let socialRank: String?
    /// The ingredients of this recipe
    var ingredients: [String]?
    /// Which steps the user has completed of the ingredients list
    var completedIngredients = [String : Bool]()
    var objectID: NSManagedObjectID?

    override init() {
        id = "invalid id"
        imageURLString = nil
        sourceURLString = nil
        food2ForkURLString = "Food2Fork.com"
        title = "no title"
        publisher = "no publisher"
        publisherURLString = nil
        socialRank = nil
        ingredients = nil
    }

    required init(unboxer: Unboxer) throws {
        id = try unboxer.unbox(key: APIKeys.recipeID)
        imageURLString = unboxer.unbox(key: APIKeys.imageURL)
        sourceURLString = unboxer.unbox(key: APIKeys.sourceURL)
        food2ForkURLString = try unboxer.unbox(key: APIKeys.food2ForkURL)
        title = (try unboxer.unbox(key: APIKeys.title) as String).cleaned()
        publisher = try unboxer.unbox(key: APIKeys.publisher)
        publisherURLString = unboxer.unbox(key: APIKeys.publisherURL)
        socialRank = unboxer.unbox(key: APIKeys.socialRank)
        ingredients = unboxer.unbox(key: APIKeys.ingredients)
        super.init()
        loadFavorite()
    }
    
    init(entity: Recipe) throws {
        imageURLString = entity.imageURLString
        sourceURLString = entity.sourceURLString
        ingredients = entity.ingredients?.cleaned().components(separatedBy: Constants.apiConcatenationSeparatorSet)
        publisherURLString = entity.publisherURLString
        socialRank = entity.socialRank
        isFavorite = entity.isFavorite
        objectID = entity.objectID
        guard let food2ForkURLString = entity.food2ForkURLString,
            let id = entity.id,
            let title = entity.title,
            let publisher = entity.publisher else {
                print("\(entity.description)")
                throw BlueRecipeError(title: "Missing property on initialization",
                                      description: "At least one of the required properties for initialization was missing.",
                                      code: BlueRecipeErrorCode.missingInitializationProperty)
        }
        self.food2ForkURLString = food2ForkURLString
        self.id = id
        self.title = title
        self.publisher = publisher
        super.init()
        loadFavorite()
    }

    override var description: String {
        var compositeDescription = super.description
        compositeDescription += "\nid: \(id)"
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
        if let socialRank = socialRank {
            compositeDescription += "\nsocialRank: \(socialRank)"
        }
        if let ingredients = ingredients {
            compositeDescription += "\ningredients: \(ingredients)"
        }
        compositeDescription += "\nisFavorite: \(isFavorite ? "true" : "false")"

        return compositeDescription
    }

    func recipeEntity(in context: NSManagedObjectContext) -> Recipe {
        let recipe = Recipe(context: context)
        recipe.id = id
        recipe.ingredients = ingredients?.joined(separator: Constants.apiConcatenationSeparator).cleaned()
        recipe.imageURLString = imageURLString
        recipe.sourceURLString = sourceURLString
        recipe.food2ForkURLString = food2ForkURLString
        recipe.title = title
        recipe.publisher = publisher

        return recipe
    }

    func update(to recipe: Recipe) {
        recipe.id = id
        recipe.ingredients = ingredients?.joined(separator: Constants.apiConcatenationSeparator).cleaned()
        recipe.imageURLString = imageURLString
        recipe.sourceURLString = sourceURLString
        recipe.food2ForkURLString = food2ForkURLString
        recipe.title = title
        recipe.publisher = publisher
    }

    func update(from updatedRecipe: RecipeModel) {
        if let objectID = updatedRecipe.objectID {
            self.objectID = objectID
        }
        if let ingredients = updatedRecipe.ingredients {
            self.ingredients = ingredients
        }
        self.completedIngredients = updatedRecipe.completedIngredients
    }


    static func == (lhs: RecipeModel, rhs: RecipeModel) -> Bool {
        return lhs.id == rhs.id
    }

    static func == (lhs: RecipeModel, rhs: Recipe) -> Bool {
        return lhs.id == rhs.id
    }

    static func == (lhs: Recipe, rhs: RecipeModel) -> Bool {
        return rhs.id == lhs.id
    }

    override var hash: Int {
        return id.hash
    }

    override var hashValue: Int {
        return id.hashValue
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
            compositeDescription += "\npublisher: \(publisher)"
        }
        if let publisherURLString = publisherURLString {
            compositeDescription += "\npublisherURLString: \(publisherURLString)"
        }
        if let socialRank = socialRank {
            compositeDescription += "\nsocialRank: \(socialRank)"
        }
        if let ingredients = ingredients {
            compositeDescription += "\ningredients: \(ingredients)"
        }

        return compositeDescription

    }
}

fileprivate extension RecipeModel {
    func saveFavorite() {
        UserDefaults.standard.set(isFavorite, forKey: idKey)
    }

    func loadFavorite() {
        guard let isFavorite = UserDefaults.standard.value(forKey: idKey) as? Bool else {
            return
        }
        self.isFavorite = isFavorite
    }

    fileprivate var idKey: String {
        return "RecipeModelKey\(id)"
    }
}

