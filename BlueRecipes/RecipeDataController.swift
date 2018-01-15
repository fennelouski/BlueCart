//
//  RecipeDataController.swift
//  BlueRecipes
//
//  Created by Nathan Fennel on 1/14/18.
//  Copyright © 2018 Nathan Fennel. All rights reserved.
//

import Foundation

class RecipeDataController {
    fileprivate var recipesArray = [RecipeModel]()
    fileprivate var filteredRecipesArray: [RecipeModel]?
    fileprivate var lastFilterString: String?
    var sortingOption: DataSortingOption = .random {
        didSet {
            updateSorting()
        }
    }

    init() {
        RecipeDataManager.getInitialRecipes {
            self.recipesArray = RecipeDataManager.recipesArray
        }
    }

    func sectionCount() -> Int {
        return 1
    }

    func recipeCount(forSection section: Int) -> Int {
        return recipesArray.count
    }

    func recipe(for indexPath: IndexPath) -> RecipeModel {
        guard indexPath.row < recipesArray.count else {
            print("Index Path beyond bounds for recipes \(indexPath.row) > \(recipesArray.count)")
            return RecipeModel()
        }

        return recipesArray[indexPath.row]
    }
}

// MARK: Searching
extension RecipeDataController {
    func filterRecipes(by text: String) {
        if filteredRecipesArray == nil {
            filteredRecipesArray = recipesArray
        }

        // If the new text is not a substring of the previous search, then reset the recipes to the complete set
        if lastFilterString != nil,
            !text.contains(lastFilterString!) {
            filteredRecipesArray = recipesArray
        }

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
        if sortingOption == .random {
            recipesArray.shuffle()
            return
        }
        recipesArray.sort { (recipe1, recipe2) -> Bool in
            switch self.sortingOption {
            case .alphabetically, .random:
                return recipe1.title < recipe2.title
            case .byIngredients:
                return recipe1.ingredients?.count ?? 0 < recipe2.ingredients?.count ?? 0
            case .byFavorites:
                if recipe1.isFavorite == recipe2.isFavorite {
                    return recipe1.title < recipe2.title
                }
                return recipe1.isFavorite
            }
        }
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
