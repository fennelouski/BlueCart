//
//  RecipeDataController.swift
//  BlueRecipes
//
//  Created by Nathan Fennel on 1/14/18.
//  Copyright © 2018 Nathan Fennel. All rights reserved.
//

import Foundation

// Data Controller that interacts with DataManager to get recipes
class RecipeDataController {
    fileprivate var recipesOrderedSet = NSOrderedSet()
    fileprivate var filteredRecipesArray: [RecipeModel]?
    fileprivate var lastFilterString: String?
    var sortingOption: DataSortingOption = .byFavorites {
        didSet {
            updateSorting()
        }
    }

    init() {
        RecipeDataManager.getInitialRecipes {
            self.recipesOrderedSet = RecipeDataManager.recipesOrderedSet
        }
    }

    func loadMoreRecipes(completion: @escaping () -> Void) {
        func updateRecipes() {
            recipesOrderedSet = RecipeDataManager.recipesOrderedSet
            updateSorting()
            completion()
        }

        RecipeDataManager.loadMoreRecipes(partialCompletion: updateRecipes,
                                          completion: updateRecipes)
    }

    func getRecipeDetails(for recipeModel: RecipeModel, completion: @escaping (RecipeModel) -> Void) {
        RecipeDataManager.getDetails(for: recipeModel, completion: completion)
    }

    func sectionCount() -> Int {
        return 1
    }

    func recipeCount(forSection section: Int) -> Int {
        return recipesOrderedSet.count
    }

    func recipe(for indexPath: IndexPath) -> RecipeModel {
        guard indexPath.row < recipesOrderedSet.count else {
            print("Index Path beyond bounds for recipes \(indexPath.row) > \(recipesOrderedSet.count)")
            return RecipeModel()
        }

        return recipesOrderedSet.object(at: indexPath.row) as! RecipeModel
    }
}

// MARK: Searching
extension RecipeDataController {
    func search(for text: String?,
                partialCompletion: @escaping () -> Void,
                completion: @escaping () -> Void) {
        let searchTerms = text?.components(separatedBy: .whitespacesAndNewlines)
        filterRecipes(by: text)

        let partialCompletion: () -> Void = {
            self.recipesOrderedSet = RecipeDataManager.recipesOrderedSet
            self.filterRecipes(by: self.lastFilterString)
            partialCompletion()
        }

        let completion: () -> Void = {
            self.recipesOrderedSet = RecipeDataManager.recipesOrderedSet
            self.filterRecipes(by: self.lastFilterString)
            completion()
        }

        RecipeDataManager.searchforItemsFromAPI(searchTerms: searchTerms,
                                                pageNumber: 0,
                                                enforceMaximum: true,
                                                partialCompletion: partialCompletion,
                                                completion: completion)

        filterRecipes(by: text)
    }

    func filterRecipes(by optionalText: String?) {
        guard let text = optionalText else {
            clearFilters()
            return
        }

        filteredRecipesArray = recipesOrderedSet.array as? [RecipeModel] ?? RecipeDataManager.recipesOrderedSet.array as? [RecipeModel] ?? [RecipeModel]()

        RecipeDataController.filter(recipes: &filteredRecipesArray!, text: text)
        lastFilterString = text
    }

    /**
     Applies a filter to the `filteredRecipesArray` with the given parameters.

     - Parameter recipes: The recipes that will be searched (in place)
     - Parameter filterString: Optional String that filters out all recipes that don't contain the text in their name.
     Strings are read as `lowercased()` and compared to the filter as `lowercased()`.
     */
    static func filter(recipes: inout [RecipeModel], text filterString: String) {
        var index = 0
        let lowercaseString = filterString.lowercased()
        while index < recipes.count {
            let currentRecipe = recipes[index]
            if currentRecipe.searchableText.contains(lowercaseString) {
                index += 1
            } else {
                recipes.remove(at: index)
            }
        }
    }

    /**
     - Returns: The number of sections filtered results are broken down into using the currently applied filters.
     - TODO: Update to allow discrete filters into different sections.
     */
    func filteredSectionCount() -> Int {
        return 1
    }

    /// Returns the number of recipes with the current filters applied
    func filteredRecipeCount(forSection section: Int) -> Int {
        return filteredRecipesArray?.count ?? 0
    }

    /// Returns the recipe from the filtered collection for the given IndexPath
    func filteredRecipe(for indexPath: IndexPath) -> RecipeModel {
        guard let filteredRecipesArray = filteredRecipesArray,
            indexPath.row < filteredRecipesArray.count else {
                print("Index Path beyond bounds for filtered recipes \(indexPath.row) > \(self.filteredRecipesArray?.count ?? 0)")
                return RecipeModel()
        }

        return filteredRecipesArray[indexPath.row]
    }

    /// Clears all filters currently applied.
    func clearFilters() {
        filteredRecipesArray = nil
        lastFilterString = nil
    }
}

// MARK: Sorting
fileprivate extension RecipeDataController {
    func updateSorting() {
        var recipesArray = recipesOrderedSet.array as! [RecipeModel]

        recipesArray.sort { (recipe1, recipe2) -> Bool in
            switch self.sortingOption {
            case .alphabetically:
                return recipe1.title < recipe2.title
            case .byIngredients:
                guard let ingredients1 = recipe1.ingredients,
                    let ingredients2 = recipe2.ingredients else {
                        return recipe1.food2ForkURLString > recipe2.food2ForkURLString
                }
                return ingredients1.count < ingredients2.count
            case .byFavorites:
                if recipe1.isFavorite == recipe2.isFavorite {
                    return recipe1.id < recipe2.id
                }
                return recipe1.isFavorite
            }
        }
        recipesOrderedSet = NSOrderedSet(array: recipesArray)
    }
}

extension MutableCollection {
    /// Shuffles the contents of this collection in place
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }

        for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            let i = index(firstUnshuffled, offsetBy: d)
            swapAt(firstUnshuffled, i)
        }
    }
}
