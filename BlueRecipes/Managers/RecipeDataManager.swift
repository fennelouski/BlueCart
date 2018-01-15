//
//  RecipeDataManager.swift
//  BlueRecipes
//
//  Created by Nathan Fennel on 1/14/18.
//  Copyright © 2018 Nathan Fennel. All rights reserved.
//

import Foundation
import Alamofire
import Unbox

// Singleton that retrieves and stores recipes from CoreData & the Food2Fork API
class RecipeDataManager {
    private(set) public static var recipesArray = [RecipeModel]()
    private(set) public static var recipesDictionary = [String : RecipeModel]()

    static func getInitialRecipes(completion: @escaping () -> Void) {
        getAllRecipesFromPeristentStore()
        if recipesArray.isEmpty {
            searchforItemsFromAPI(maxCount: 20) { (recipeModels) in
                guard let recipeModels = recipeModels,
                    recipeModels.count > 0 else {
                        print("It didn't work :(")
                        return
                }
                save(recipes: recipeModels)
                completion()
            }
        } else {
            completion()
        }
    }

    static func loadMoreRecipes(partialCompletion: @escaping () -> Void,
                                completion: @escaping () -> Void) {
        let lastPage: Int = UserDefaults.standard.integer(forKey: Constants.lastPageKey) + 1

        let partialCompletion: ([RecipeModel]?) -> Void = { (recipeModels) in
            guard let recipeModels = recipeModels,
                recipeModels.count > 0 else {
                    print("It didn't work :(")
                    return
            }
            save(recipes: recipeModels)
            partialCompletion()
        }

        searchforItemsFromAPI(pageNumber: lastPage,
                              partialCompletion: partialCompletion,
                              completion: completion)
    }

    /**
     Adds the imageURL to the running queue if needed.
     If the imageURL is already in the queue, nothing changes.

     - Parameter searchTerms: The words that will be used to search the API
     - Parameter pageNumber: The page number that is being returned (To keep track of concurrent requests)
     - Parameter enforceMaximum: Whether or not to recognize the maximum number of pages to search through
     - Parameter partialCompletion: Executed at the very end of all paged results
     - Parameter completion: Executed at the very end of all paged results
     */
    static func searchforItemsFromAPI(searchTerms: [String]? = nil,
                                      pageNumber: Int = 1,
                                      enforceMaximum: Bool = false,
                                      partialCompletion: @escaping ([RecipeModel]?) -> Void,
                                      completion: @escaping () -> Void) {
        if enforceMaximum && pageNumber <= Constants.maxSearchPage {
            searchforItemsFromAPI(maxCount: Constants.maxRecipeRequestCount,
                                  searchTerms: searchTerms,
                                  sortOption: .rating,
                                  pageNumber: pageNumber,
                                  completion: { (recipes) in
                                    if let recipes = recipes {
                                        var recipesToSave = [RecipeModel]()
                                        for recipe in recipes {
                                            if recipesDictionary[recipe.food2ForkURLString] != nil {
                                                recipesDictionary[recipe.food2ForkURLString] = recipe
                                                recipesArray.append(recipe)
                                                recipesToSave.append(recipe)
                                            }
                                        }
                                        save(recipes: recipes)
                                    }
                                    partialCompletion(recipes)
                                    searchforItemsFromAPI(searchTerms: searchTerms,
                                                          pageNumber: pageNumber+1,
                                                          enforceMaximum: true,
                                                          partialCompletion: partialCompletion,
                                                          completion: completion)
            })
        } else {
            completion()
            print("recipes count: \(recipesArray.count)")
        }
    }
}

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
                recipesArray.append(recipeModel)
            }
        }
        catch {
            print("Fetching Failed \(error)")
        }
    }

    static func save(recipes: [RecipeModel]) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("Error getting AppDelegate")
            return
        }

        let context = appDelegate.persistentContainer.viewContext

        for recipeModel in recipes {
            let _ = recipeModel.recipeEntity(from: context)
        }

        appDelegate.saveContext()

    }
}

fileprivate extension RecipeDataManager {
    static func searchforItemsFromAPI(maxCount: Int? = Constants.maxRecipeRequestCount,
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

                if let value = response.result.value {
                    print("\(value)")
                } else {
                    print("\(response)")
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

    static func getRecipesFromAPI(recipeID: String,
                           completion: @escaping ([RecipeModel]?) -> Void) {
        Alamofire.request(
            Constants.baseRecipeRequestURL,
            method: .get,
            parameters: [APIKeys.key: PrivateConstants.apiKey,
                         APIKeys.recipeID : recipeID])
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

                guard let value = response.result.value as? [[String: Any]] else {
                    print("Malformed data received from \(Constants.serviceName) service while receiving recipe")
                    completion(nil)
                    return
                }

                do {
                    let recipes = try value.flatMap({ (recipeDictionary) -> RecipeModel? in
                        let recipe: RecipeModel = try unbox(dictionary: recipeDictionary)
                        return recipe
                    })

                    completion(recipes)
                } catch {
                    print("An error occurred while parsing: \(error)")
                    completion(nil)
                }
        }
    }
}
