//
//  RecipeDataManager.swift
//  BlueRecipes
//
//  Created by Nathan Fennel on 1/14/18.
//  Copyright © 2018 Nathan Fennel. All rights reserved.
//

import Foundation
import Alamofire
import CoreData
import Unbox

// Singleton that retrieves and stores recipes from CoreData & the Food2Fork API
class RecipeDataManager {
    private(set) public static var recipesOrderedSet = NSMutableOrderedSet()
    // Phrases that are currently being searched for. Reduces duplicates
    fileprivate static var pendingSearchTerms = Set<String>()
    // Phrases that have already been searched for and retrieved
    fileprivate static var previouslySearchedTerms = Set<String>()
    // A Running List of all IDs that have been retrieved from the API
    fileprivate static var retrievedIDs = Set<String>()

    /**
     Loads the initial set of recipes.

     First checks to see which ones are saved persistently.
     If none are loaded, then it requests more remotely.

     - Parameter partialCompletion: Executed at the very end of all paged results
     - Parameter completion: Executed at the very end of all paged results
     */
    static func getInitialRecipes(completion: @escaping () -> Void) {
        setupIDTracking()
        setupSearchTerms()
        getAllRecipesFromPeristentStore() // <- this could be broken up to get a small batch at first and then get more asynchronously
        if recipesOrderedSet.count == 0 {
            searchforItemsFromRemoteAPI(maxCount: 20) { (recipeModels) in
                guard let _ = filterNewRecipes(recipes: recipeModels) else {
                        print("It didn't work :(")
                        return
                }
                completion()
            }
        } else {
            completion()
        }
    }

    /**
     Gets more recipes from the API.

     - Parameter forced: Whether to check and see if there are already "enough" recipes loaded
     - Parameter partialCompletion: Executed at the very end of all paged results
     - Parameter completion: Executed at the very end of all paged results
     */
    static func loadMoreRecipes(forced: Bool = false,
                                partialCompletion: @escaping () -> Void,
                                completion: @escaping () -> Void) {
        guard forced || retrievedIDs.count < Constants.preferredMinimumRecipeCount else {
            return
        }

        let lastPage: Int = UserDefaults.standard.integer(forKey: Constants.lastPageKey) + 1
        UserDefaults.standard.set(lastPage, forKey: Constants.lastPageKey)

        let completionWithReturn: ([RecipeModel]?) -> Void = { recipes in
            guard let _ = filterNewRecipes(recipes: recipes) else {
                    print("It didn't work :(")
                    return
            }

            completion()
        }

        searchforItemsFromRemoteAPI(pageNumber: lastPage,
                                    completion: completionWithReturn)
    }

    /**
     Recursively creates requests for searching the api for the provided information.

     - Parameter searchTerms: The words that will be used to search the API
     - Parameter pageNumber: The page number that is being returned (To keep track of concurrent requests)
     - Parameter enforceMaximum: Whether or not to recognize the maximum number of pages to search through
     - Parameter partialCompletion: Executed at the very end of all paged results
     - Parameter completion: Executed at the very end of all paged results
     */
    public static func searchforItemsFromAPI(searchTerms: [String]? = nil,
                                      pageNumber: Int = 1,
                                      enforceMaximum: Bool = false,
                                      preventDuplicates: Bool = true,
                                      partialCompletion: @escaping () -> Void,
                                      completion: @escaping () -> Void) {

        if let combinedTerm = searchTerms?.joined(separator: " "),
            preventDuplicates &&
            (pendingSearchTerms.contains(combinedTerm) ||
            previouslySearchedTerms.contains(combinedTerm)) {
            completion()
            return
        }

        addPendingSearchTerms(searchTerms)
        if !enforceMaximum || (enforceMaximum && pageNumber <= Constants.maxSearchPage) {
            searchforItemsFromRemoteAPI(maxCount: Constants.maxRecipeRequestCount,
                                        searchTerms: searchTerms,
                                        sortOption: .rating,
                                        pageNumber: pageNumber,
                                        completion: { (recipes) in
                                            partialCompletion()
                                            let _ = filterNewRecipes(recipes: recipes)

                                            // If this is the last recursive call, then call completion in this completion block
                                            if pageNumber + 1 >= Constants.maxSearchPage {
                                                commitPendingSearchTerms(searchTerms, success: recipes != nil)
                                                completion()
                                            } else { // Get the next page of results
                                                searchforItemsFromAPI(searchTerms: searchTerms,
                                                                      pageNumber: pageNumber+1,
                                                                      enforceMaximum: true,
                                                                      preventDuplicates: false,
                                                                      partialCompletion: partialCompletion,
                                                                      completion: completion)
                                            }
            })
        }
    }

    /**
     Gets details for a single recipe from the API.

     - Parameter recipe: Recipe which details will be retrieved for
     - Parameter completion: Executed after receiving recipe details
     */
    public static func getDetails(for recipe: RecipeModel, completion: @escaping (RecipeModel) -> Void) {
        getRecipesFromAPI(recipeID: recipe.id) { (recipes) in
            guard let recipes = recipes else { return }
            for updatedRecipe in recipes {
                if updatedRecipe == recipe {
                    update(updatedRecipe: updatedRecipe)
                    completion(recipe)
                    return
                }
            }
        }
    }
}

// MARK: Ensuring uniqueness of items
fileprivate extension RecipeDataManager {
    /**
     Filters out all recipes that have already been downloaded and updates ledger with new items.

     - Parameter optionalRecipes: Recipes to save and filter
     - Return: A filtered array of the input with only unique items
     */
    static func filterNewRecipes(recipes optionalRecipes: [RecipeModel]?) -> [RecipeModel]? {
        guard let recipes = optionalRecipes else {
            return optionalRecipes
        }

        var uniqueRecipes = [RecipeModel]()
        for recipe in recipes {
            guard !recipe.alreadyDownloaded else { continue }
            uniqueRecipes.append(recipe)
            retrievedIDs.insert(recipe.id)
            recipesOrderedSet.add(recipe)
        }

        save(recipes: uniqueRecipes)

        return uniqueRecipes
    }
}

// MARK: Helper functions to reduce duplicate calls and objects
fileprivate extension RecipeDataManager {
    static func setupIDTracking() {
        let previousIDs: [String] = {
            if let savedIDs = UserDefaults.standard.array(forKey: Constants.recipeIDsKey) as? [String] {
                return savedIDs
            }

            return [String]()
        }()

        for id in previousIDs {
            retrievedIDs.insert(id)
        }
    }

    static func saveIDTracking() {
        UserDefaults.standard.setValue(retrievedIDs.map{ $0 }, forKey: Constants.recipeIDsKey)
    }

    static func setupSearchTerms() {
        let previousSearchTerms: [String] = {
            if let savedSearchTerms = UserDefaults.standard.array(forKey: Constants.searchedTermsKey) as? [String] {
                return savedSearchTerms
            }

            return [String]()
        }()

        for searchTerm in previousSearchTerms {
            previouslySearchedTerms.insert(searchTerm)
        }
    }

    static func saveSearchTerms() {
        UserDefaults.standard.setValue(previouslySearchedTerms.map{ $0 }, forKey: Constants.searchedTermsKey)
    }

    static func addPendingSearchTerms(_ terms: [String]?) {
        guard let term = terms?.joined(separator: " ") else { return }
        pendingSearchTerms.insert(term)
    }

    static func commitPendingSearchTerms(_ terms: [String]?, success: Bool) {
        guard let term = terms?.joined(separator: " ") else { return }
        pendingSearchTerms.remove(term)
        if success {
            previouslySearchedTerms.insert(term)
            saveSearchTerms()
        }
    }
}

// MARK: Get, Save, and Update Recipes from Core Data
fileprivate extension RecipeDataManager {
    static func getAllRecipesFromPeristentStore() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("Error getting AppDelegate")
            return
        }

        do {
            let context = appDelegate.persistentContainer.viewContext
            let recipes: [Recipe] = try context.fetch(Recipe.fetchRequest())
            for recipe in recipes {
                let recipeModel = try RecipeModel(entity: recipe)
                recipesOrderedSet.add(recipeModel)
            }
        }
        catch {
            print("Fetching Failed \(error)")
        }
    }

    /// Saves the given recipes to core data
    ///
    /// NOTE: There is no checking for duplicates!
    static func save(recipes: [RecipeModel]) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("Error getting AppDelegate")
            return
        }

        let context = appDelegate.persistentContainer.viewContext

        for recipeModel in recipes {
            let _ = recipeModel.recipeEntity(in: context)
        }

        appDelegate.saveContext()
    }

    /// Updates core data and the active memory repository with the updatedRecipe
    static func update(updatedRecipe: RecipeModel) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("Error getting AppDelegate")
            return
        }

        if let recipe = getSavedRecipe(updatedRecipe) {
            updatedRecipe.update(to: recipe)
        }

        appDelegate.saveContext()

        for oldRecipe in recipesOrderedSet {
            guard let oldRecipe = oldRecipe as? RecipeModel else { continue }
            if oldRecipe == updatedRecipe {
                oldRecipe.update(from: updatedRecipe)
            }
        }
    }

    static func getSavedRecipe(_ recipe: RecipeModel?) -> Recipe? {
        guard let recipe = recipe else {
            return nil
        }
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("Error getting AppDelegate")
            return nil
        }

        let context = appDelegate.persistentContainer.viewContext

        guard let objectID = recipe.objectID else {
            let idPredicate = NSPredicate(format: "id = '\(recipe.id)'")
            guard let matchingIDs = get(with: idPredicate),
                let firstMatch = matchingIDs.first else {
                return nil
            }

            return firstMatch
        }

        return context.object(with: objectID) as? Recipe
    }

    static func get(with queryPredicate: NSPredicate) -> [Recipe]? {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("Error getting AppDelegate")
            return nil
        }

        guard let entityName = Recipe.entity().name else {
            print("Error getting entity name \"Recipe.entity().name\"")
            return nil
        }

        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = queryPredicate

        do {
            return try context.fetch(fetchRequest) as? [Recipe]
        } catch {
            print("Fetch Failed: \(error)")
        }

        do {
            try context.save()
        } catch {
            print("Saving Core Data Failed: \(error)")
        }

        return nil
    }
}

// MARK: Search for items from the API
fileprivate extension RecipeDataManager {
    static func searchforItemsFromRemoteAPI(maxCount: Int? = Constants.maxRecipeRequestCount,
                                            searchTerms: [String]? = nil,
                                            sortOption: apiSortOption? = nil,
                                            pageNumber: Int? = nil,
                                            completion: @escaping ([RecipeModel]?) -> Void) {

        var parameters = [APIKeys.key: PrivateConstants.apiKey]
        if let concatenatedSearchTerms = searchTerms?.joined(separator: Constants.apiConcatenationSeparator) {
            parameters[APIKeys.query] = concatenatedSearchTerms
        }
        if let sortKey = sortOption?.key {
            parameters[APIKeys.sort] = sortKey
        }
        if let pageNumber = pageNumber {
            parameters[APIKeys.page] = "\(pageNumber)"
        }

        Alamofire.request(
            Constants.baseSearchURL,
            method: .get,
            parameters: parameters)
            .validate()
            .responseJSON { (response) -> Void in
                guard response.result.isSuccess else {
                    if let error = response.result.error {
                        print("Error while fetching searched recipes: \(error)")
                    } else {
                        print("Error while fetching searched recipes: \(response.result)")
                    }
                    completion(nil)
                    return
                }

                guard let value = response.result.value as? [String: Any],
                    let recipesJSON = value[APIKeys.recipes] as? [[String: Any]] else {
                    print("Malformed data received from \(Constants.serviceName) service while searching")
                    completion(nil)
                    return
                }

                do {
                    let recipes = try recipesJSON.flatMap({ (recipeDictionary) -> RecipeModel? in
                        let recipe: RecipeModel = try unbox(dictionary: recipeDictionary)
                        return recipe
                    })

                    completion(recipes)
                    return
                } catch {
                    print("An error occurred while parsing: \(error)")
                    completion(nil)
                }
        }
    }
}


// MARK: Get individual recipe
fileprivate extension RecipeDataManager {
    static func getRecipesFromAPI(recipeID: String,
                                  completion: @escaping ([RecipeModel]?) -> Void) {
        Alamofire.request(
            Constants.baseRecipeRequestURL,
            method: .get,
            parameters: [APIKeys.key: PrivateConstants.apiKey,
                         APIKeys.rId : recipeID])
            .validate()
            .responseJSON { (response) -> Void in
                guard response.result.isSuccess else {
                    if let error = response.result.error {
                        print("Error while fetching remote recipes: \(error)")
                    } else {
                        print("Error while fetching remote recipes: \(response.result)")
                    }
                    completion(nil)
                    return
                }

                guard let value = response.result.value as? [String: Any] else {
                    print("Malformed data received from \(Constants.serviceName) service while receiving recipe")
                    completion(nil)
                    return
                }

                guard let recipeDictionary = value[APIKeys.recipe] as? [String: Any] else {
                    print("Malformed data received from \(Constants.serviceName) service while receiving recipe \(value.keys) expecting \(APIKeys.recipe)")
                    completion(nil)
                    return
                }

                do {
                    let recipe: RecipeModel = try unbox(dictionary: recipeDictionary)
                    completion([recipe])
                } catch {
                    print("An error occurred while parsing: \(error)")
                    completion(nil)
                }
        }
    }
}

fileprivate extension RecipeModel {
    var alreadyDownloaded: Bool {
        return RecipeDataManager.retrievedIDs.contains(id)
    }
}

fileprivate extension Recipe {
    var alreadyDownloaded: Bool {
        guard let id = self.id else {
            return false // <- Debatable if this would identify that it has already been downloaded or not
        }
        return RecipeDataManager.retrievedIDs.contains(id)
    }
}

