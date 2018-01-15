//
//  RecipeCollectionViewLayout.swift
//  BlueRecipes
//
//  Created by Nathan Fennel on 1/14/18.
//  Copyright © 2018 Nathan Fennel. All rights reserved.
//

import UIKit

class RecipeCollectionViewLayout {
    static let inset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

    static var imageWidthToHeightRatio: CGFloat = 1.5555
    static var imageHeight: CGFloat = 93
    static var itemSize = CGSize(width: 144, height: 93)
    static let minimumLineSpacing: CGFloat = 24
    static var numberOfColumns: Int {
        guard let keyWindowWidth = UIApplication.shared.keyWindow?.bounds.width else {
            return 2
        }

        let numberOfColumns = Int(keyWindowWidth / 180)
        return max(numberOfColumns, 2)
    }

    // cell layout constants
    static let cornerRadius: CGFloat = 5
    static let titleLabelImageOffset: CGFloat = 8
    static let favoriteButtonOffset: CGFloat = -6
    static let ingredientsLabelTitleLabelOffset: CGFloat = 3
    static var imageBottomInset: CGFloat { // I really don't like this, but it works
        return ingredientsLabelTitleLabelOffset + titleLabelImageOffset + UIFont.systemFontSize + UIFont.systemFontSize
    }

    static func setup() {
        let arbitraryAmountThatIShouldFigureOutWhyItIsNeeded: CGFloat = 2
        let collectionViewWidth = UIScreen.main.bounds.width - inset.left - inset.right - arbitraryAmountThatIShouldFigureOutWhyItIsNeeded
        let recipeHorizontalSpacing: CGFloat = 8
        let totalHorizontalSpacing = (CGFloat(numberOfColumns) - 1) * recipeHorizontalSpacing
        itemSize.width = (collectionViewWidth - totalHorizontalSpacing) / CGFloat(numberOfColumns)
        imageHeight = itemSize.width / imageWidthToHeightRatio
        itemSize.height = imageHeight + 30
    }

    static var flowLayout: UICollectionViewFlowLayout {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = RecipeCollectionViewLayout.inset
        layout.itemSize = RecipeCollectionViewLayout.itemSize
        layout.minimumLineSpacing = minimumLineSpacing
        return layout
    }
}

