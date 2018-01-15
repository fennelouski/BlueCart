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
    fileprivate let publisherLabel = UILabel(frame: .zero)
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
        updateLabels()
        layoutFavoriteButton()
    }

    fileprivate func updateView(animated: Bool = false) {
        updateLabels()
        updateFavoriteButton(animated: animated)
        updateImage()
    }

    fileprivate func updateLabels() {
        titleLabel.text = recipeModel.title
        if recipeModel.title.height(withConstrainedWidth: titleLabel.bounds.width, font: titleLabel.font) > 24 {
            publisherLabel.text = nil
        } else {
            publisherLabel.text = recipeModel.publisher
        }
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
        let titleLabelPointSize = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline).pointSize
        titleLabel.font = UIFont.boldSystemFont(ofSize: titleLabelPointSize)
        titleLabel.autoPinEdge(toSuperviewEdge: .leading)
        titleLabel.autoPinEdge(toSuperviewEdge: .trailing)
        titleLabel.autoPinEdge(.top, to: .bottom, of: imageBackground, withOffset: RecipeCollectionViewLayout.titleLabelImageOffset)
        titleLabel.numberOfLines = 2

        contentView.addSubview(publisherLabel)
        publisherLabel.autoPinEdge(toSuperviewEdge: .leading)
        publisherLabel.autoPinEdge(toSuperviewEdge: .trailing)
        publisherLabel.autoPinEdge(.top, to: .bottom, of: titleLabel, withOffset: RecipeCollectionViewLayout.ingredientsLabelTitleLabelOffset)
        let publisherLabelPointSize = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .footnote).pointSize
        publisherLabel.font = UIFont.systemFont(ofSize: publisherLabelPointSize)
        publisherLabel.textColor = UIColor.gray
        publisherLabel.textAlignment = .right
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

extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)

        return ceil(boundingBox.height)
    }

    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)

        return ceil(boundingBox.width)
    }
}


