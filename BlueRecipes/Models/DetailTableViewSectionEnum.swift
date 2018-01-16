//
//  DetailTableViewSectionEnum.swift
//  BlueRecipes
//
//  Created by Nathan Fennel on 1/15/18.
//  Copyright © 2018 Nathan Fennel. All rights reserved.
//

import Foundation

enum detailTableViewSection: Int {
    case title = 0, publisher, socialRank, ingredients

    static let count: Int = 4

    func numberOfRows(with recipeModel: RecipeModel) -> Int {
        switch self {
        case .title:
            return 0
        case .publisher:
            return 2
        case .socialRank:
            return 0 // recipeModel.socialRank != nil ? 1 : 0
        case .ingredients:
            return recipeModel.ingredients?.count ?? 0
        }
    }

    func text(for row: Int, _ recipeModel: RecipeModel) -> String {
        switch self {
        case .title:
            return recipeModel.title
        case .publisher:
            switch row {
            case 0:
                return recipeModel.publisher
            case 1:
                var domainName: String = recipeModel.publisherURLString ?? recipeModel.sourceURLString ?? recipeModel.publisher
                domainName = domainName.stripToDomainAndTLD()
                return "View at \(domainName)"
            default:
                return ""
            }
        case .socialRank:
            guard let socialRank = recipeModel.socialRank else { return "" }
            return "Social Ranking: \(socialRank)"
        case .ingredients:
            guard let ingredients = recipeModel.ingredients,
                ingredients.count > row else { return "" }
            return ingredients[row]
        }
    }

    func url(for row: Int, recipeModel: RecipeModel) -> URL? {
        switch self {
        case .title:
            return recipeModel.food2ForkURL
        case .publisher:
            switch row {
            case 0:
                return recipeModel.publisherURL
            case 1:
                return recipeModel.sourceURL
            default:
                return nil
            }
        case .socialRank:
            return recipeModel.food2ForkURL
        case .ingredients:
            return nil
        }
    }

    func showStrikeThrough(for row: Int, _ recipeModel: RecipeModel) -> Bool {
        guard self == .ingredients,
            let ingredients = recipeModel.ingredients,
            row < ingredients.count else {
            return false
        }

        let ingredient = ingredients[row]
        if let isCompleted = recipeModel.completedIngredients[ingredient] {
            return isCompleted
        }

        return false
    }

    func updateIsCompleted(for row: Int, _ recipeModel: RecipeModel) {
        guard self.useStrikeThrough,
        let ingredients = recipeModel.ingredients,
        row < ingredients.count else {
            return
        }

        let ingredient = ingredients[row]
        let isCompleted = recipeModel.completedIngredients[ingredient] ?? false
        recipeModel.completedIngredients[ingredient] = !isCompleted
    }

    var useStrikeThrough: Bool {
        return self == .ingredients
    }
}
