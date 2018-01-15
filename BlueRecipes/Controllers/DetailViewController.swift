//
//  DetailViewController.swift
//  BlueRecipes
//
//  Created by Nathan Fennel on 1/14/18.
//  Copyright © 2018 Nathan Fennel. All rights reserved.
//

import UIKit
import ParallaxHeader
import PureLayout
import SnapKit

class DetailViewController: UIViewController, ImageUpdate {
    /// View that works to hold the scroll view inside the safe area using PureLayout
    fileprivate let tableView = UITableView(frame: .zero, style: .plain)
    fileprivate let imageView = UIImageView(frame: .zero)
    fileprivate let roundIcon = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
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
        setupTableView()
        setupImageView()
        setupFavoriteButton()
        setupBackground()
        setupNavigationController()
    }

    fileprivate func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Constants.cellIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        view.addSubview(tableView)
        tableView.autoPinEdgesToSuperviewMargins()
    }

    fileprivate func setupImageView() {
        imageView.contentMode = .scaleAspectFill

        //setup bur view
        imageView.blurView.setup(style: UIBlurEffectStyle.dark, alpha: 1).enable()

        tableView.parallaxHeader.view = imageView
        tableView.parallaxHeader.minimumHeight = 120
        tableView.parallaxHeader.mode = .centerFill
        tableView.parallaxHeader.parallaxHeaderDidScrollHandler = { parallaxHeader in
            //update alpha of blur view on top of image view
            parallaxHeader.view.blurView.alpha = 1 - parallaxHeader.progress
        }

        roundIcon.layer.borderColor = UIColor.white.cgColor
        roundIcon.layer.borderWidth = 2
        roundIcon.layer.cornerRadius = roundIcon.frame.width / 2
        roundIcon.clipsToBounds = true

        //add round image view to blur content view
        //do not use vibrancyContentView to prevent vibrant effect
        imageView.blurView.blurContentView?.addSubview(roundIcon)
        //add constraints using SnpaKit library
        roundIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(100)
        }

        updateImage()
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
        favoriteButton.isSelected = recipeModel.isFavorite
        navigationItem.title = recipeModel.title
        updateImage()
        UIView.transition(with: imageView,
                          duration: Constants.animationDuration,
                          options: .transitionCrossDissolve,
                          animations: {
                            self.tableView.reloadData()
        },
                          completion: nil
        )
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

        if let image = imageView.image {
            tableView.parallaxHeader.height = min(view.bounds.height * 0.5, image.size.height)
            roundIcon.image = image
        }

        backgroundView.updateColors(from: imageView.image)
    }
}

// MARK: Button Actions
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

extension DetailViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recipeModel.ingredients?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier) ?? UITableViewCell(frame: .zero)

        guard let ingredients = recipeModel.ingredients,
            indexPath.row < ingredients.count else {
                return cell
        }

        cell.backgroundColor = .clear
        cell.textLabel?.numberOfLines = 0

        let ingredient = ingredients[indexPath.row]

        let completed: Bool = {
            if let isCompleted = recipeModel.completedIngredients[ingredient] {
                return isCompleted
            }

            return false
        }()

        if completed {
            let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: ingredient)
            attributeString.addAttribute(.strikethroughStyle, value: 2, range: NSMakeRange(0, attributeString.length))
            cell.textLabel?.attributedText = attributeString
        } else {
            cell.textLabel?.text = ingredient
        }


        return cell
    }
}

extension DetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let ingredients = recipeModel.ingredients,
            indexPath.row < ingredients.count else {
                return
        }

        let ingredient = ingredients[indexPath.row]

        let previousState: Bool = {
            if let isCompleted = recipeModel.completedIngredients[ingredient] {
                return isCompleted
            }

            return false
        }()

        recipeModel.completedIngredients[ingredient] = !previousState

        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}


