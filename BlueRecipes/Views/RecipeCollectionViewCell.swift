//
//  RecipeCollectionViewCell.swift
//  BlueRecipes
//
//  Created by Nathan Fennel on 1/14/18.
//  Copyright © 2018 Nathan Fennel. All rights reserved.
//

import UIKit
import PureLayout

class RecipeCollectionViewCell: UICollectionViewCell, ImageUpdate {
    fileprivate let titleLabel = UILabel(frame: .zero)
    fileprivate let ingredientsLabel = UILabel(frame: .zero)
    fileprivate let imageBackground = UIView(frame: .zero)
    fileprivate let imageView = UIImageView(frame: .zero)
    fileprivate lazy var favoriteButton: DOFavoriteButton = {
        let button = DOFavoriteButton(frame: CGRect(x: 0, y: 0, width: 33, height: 33), image: UIImage(named: "heart.png"))
        button.addTarget(self, action: #selector(favoriteButtonTouched), for: .touchUpInside)

        return button
    }()

    var recipeModel = RecipeModel() {
        didSet {
            updateView()
        }
    }

    override func layoutSubviews() {
        layoutImage()
        layoutLabels()
        layoutFavoriteButton()
    }

    fileprivate func updateView(animated: Bool = false) {
        titleLabel.text = recipeModel.title
        ingredientsLabel.text = recipeModel.ingredients?.joined(separator: ", ") ?? recipeModel.publisher ?? recipeModel.socialRank
        updateFavoriteButton(animated: animated)
        updateImage()
    }

    func updateImage() {
        if let imageURL = recipeModel.imageURL {
            if imageView.image == nil {
                // animating when the image is `nil` reduces the flickering effect from loading
                UIView.transition(with: imageView,
                                  duration: Constants.animationDuration,
                                  options: .transitionCrossDissolve,
                                  animations: {
                                    self.imageView.image = ImageManager.image(from: imageURL, in: self)
                },
                                  completion: nil
                )
            } else {
                imageView.image = ImageManager.image(from: imageURL)
            }
        } else {
            imageView.image = nil
        }
    }

    func updateFavoriteButton(animated: Bool = false) {
        guard animated else {
            favoriteButton.isSelected = recipeModel.isFavorite
            return
        }

        if recipeModel.isFavorite {
            favoriteButton.select()
        } else {
            favoriteButton.deselect()
        }
    }

    fileprivate func layoutImage() {
        guard !imageBackground.isDescendant(of: contentView) else {
            return
        }

        contentView.addSubview(imageBackground)
        let backgroundInsets = UIEdgeInsetsMake(0, 0, RecipeCollectionViewLayout.imageBottomInset, 0)
        imageBackground.autoPinEdgesToSuperviewEdges(with: backgroundInsets)
        imageBackground.backgroundColor = .backgroundGray
        imageBackground.layer.cornerRadius = RecipeCollectionViewLayout.cornerRadius
        imageBackground.clipsToBounds = true

        imageBackground.addSubview(imageView)
        let insetAmount: CGFloat = 6
        let insets = UIEdgeInsetsMake(insetAmount, insetAmount, insetAmount, insetAmount)
        imageView.autoPinEdgesToSuperviewEdges(with: insets)
        imageView.contentMode = .scaleAspectFit
    }

    fileprivate func layoutLabels() {
        guard !titleLabel.isDescendant(of: contentView) else {
            return
        }

        contentView.addSubview(titleLabel)
        titleLabel.autoPinEdge(toSuperviewEdge: .leading)
        titleLabel.autoPinEdge(toSuperviewEdge: .trailing)
        titleLabel.autoPinEdge(.top, to: .bottom, of: imageBackground, withOffset: RecipeCollectionViewLayout.titleLabelImageOffset)

        contentView.addSubview(ingredientsLabel)
        ingredientsLabel.autoPinEdge(toSuperviewEdge: .leading)
        ingredientsLabel.autoPinEdge(toSuperviewEdge: .trailing)
        ingredientsLabel.autoPinEdge(.top, to: .bottom, of: titleLabel, withOffset: RecipeCollectionViewLayout.ingredientsLabelTitleLabelOffset)
    }

    fileprivate func layoutFavoriteButton() {
        contentView.addSubview(favoriteButton)
        favoriteButton.autoPinEdge(.trailing, to: .trailing, of: imageBackground, withOffset: RecipeCollectionViewLayout.favoriteButtonOffset)
        favoriteButton.autoPinEdge(.bottom, to: .bottom, of: imageBackground, withOffset: 0)
    }

    @objc
    fileprivate func favoriteButtonTouched() {
        recipeModel.isFavorite = !recipeModel.isFavorite
        updateFavoriteButton(animated: true)
    }
}

