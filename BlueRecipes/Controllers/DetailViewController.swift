//
//  DetailViewController.swift
//  BlueRecipes
//
//  Created by Nathan Fennel on 1/14/18.
//  Copyright © 2018 Nathan Fennel. All rights reserved.
//

import UIKit
import PureLayout

class DetailViewController: UIViewController, ImageUpdate {
    /// View that works to hold the scroll view inside the safe area using PureLayout
    fileprivate let scrollViewContainer = UIView(frame: .zero)
    fileprivate let scrollView = UIScrollView(frame: .zero)
    fileprivate let imageView = UIImageView(frame: .zero)
    fileprivate let nameLabel = UILabel(frame: .zero)
    fileprivate let descriptionLabel = UILabel(frame: .zero)
    fileprivate let favoriteButton = DOFavoriteButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44), image: UIImage(named: "heart.png"))
    fileprivate let backgroundView = ColorfulBackgroundView(frame: .zero)

    var recipeModel = RecipeModel() {
        didSet {
            updateRecipeDetails()
        }
    }

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupSubviews()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if recipeModel.isFavorite {
            favoriteButton.select()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        favoriteButton.deselect()
    }

    // MARK: Setup
    fileprivate func setupSubviews() {
        setupScrollView()
        setupImageView()
        setupLabels()
        setupFavoriteButton()
        setupBackground()
        setupNavigationController()
    }

    fileprivate func setupScrollView() {
        view.addSubview(scrollViewContainer)
        scrollViewContainer.autoPinEdgesToSuperviewMargins()
        scrollViewContainer.addSubview(scrollView)
        let insets = UIEdgeInsets(top: Constants.defaultInset, left: Constants.defaultInset, bottom: Constants.defaultInset, right: Constants.defaultInset)
        scrollView.autoPinEdgesToSuperviewEdges(with: insets)
        // keeps the scrollview from scrolling horizontally
        let negativeInsets = UIEdgeInsets(top: -Constants.defaultInset,
                                          left: -Constants.defaultInset,
                                          bottom: -Constants.defaultInset,
                                          right: -Constants.defaultInset)
        scrollView.contentInset = negativeInsets
    }

    fileprivate func setupImageView() {
        scrollView.addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
        imageView.contentScaleFactor = UIScreen.main.scale
        imageView.addParallax(intensity: Constants.parallaxIntensity)
        imageView.autoPinEdge(toSuperviewEdge: .leading, withInset: Constants.defaultInset)
        imageView.autoPinEdge(toSuperviewEdge: .trailing, withInset: Constants.defaultInset)
        imageView.autoPinEdge(toSuperviewEdge: .top, withInset: Constants.defaultInset)
        imageView.autoSetDimension(.height, toSize: UIScreen.main.bounds.height * 0.5, relation: .lessThanOrEqual)
        imageView.autoMatch(.width, to: .width, of: scrollView)

        updateImage()
    }

    fileprivate func setupLabels() {
        let nameLabelPointSize = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .headline).pointSize
        nameLabel.font = UIFont.boldSystemFont(ofSize: nameLabelPointSize)
        scrollView.addSubview(nameLabel)
        nameLabel.autoPinEdge(toSuperviewEdge: .leading, withInset: 12)
        nameLabel.autoPinEdge(toSuperviewEdge: .trailing, withInset: 12)
        nameLabel.autoPinEdge(.top, to: .bottom, of: imageView, withOffset: 12)
        nameLabel.numberOfLines = 0

        let descriptionLabelPointSize = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .footnote).pointSize
        descriptionLabel.font = UIFont.systemFont(ofSize: descriptionLabelPointSize)
        scrollView.addSubview(descriptionLabel)
        descriptionLabel.autoPinEdge(.leading, to: .leading, of: nameLabel)
        descriptionLabel.autoPinEdge(.trailing, to: .trailing, of: nameLabel)
        descriptionLabel.autoPinEdge(.top, to: .bottom, of: nameLabel, withOffset: 12)
        descriptionLabel.numberOfLines = 0
    }

    fileprivate func setupFavoriteButton() {
        favoriteButton.addTarget(self, action: #selector(favoriteButtonTouched), for: .touchUpInside)
        let favoriteBarButtonItem = UIBarButtonItem(customView: favoriteButton)
        navigationItem.rightBarButtonItem = favoriteBarButtonItem
    }

    fileprivate func setupBackground() {
        view.insertSubview(backgroundView, at: 0)
        backgroundView.autoPinEdgesToSuperviewEdges()
    }

    func setupNavigationController() {
        navigationItem.largeTitleDisplayMode = .automatic
    }

    /// Updates the views that use data from recipeModel
    fileprivate func updateRecipeDetails() {
        nameLabel.text = recipeModel.title
        let ingredientsText: String? = recipeModel.ingredients?.joined(separator: "\n")
        descriptionLabel.text = ingredientsText
        favoriteButton.isSelected = recipeModel.isFavorite
        navigationItem.title = recipeModel.title
        updateImage()
    }

    /// Requests the image from the image manager and lays out the image spacing
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

        backgroundView.updateColors(from: imageView.image)
    }
}

fileprivate extension DetailViewController {
    @objc
    func favoriteButtonTouched() {
        if !favoriteButton.isSelected {
            favoriteButton.select()
        } else {
            favoriteButton.deselect()
        }

        recipeModel.isFavorite = favoriteButton.isSelected
    }
}
