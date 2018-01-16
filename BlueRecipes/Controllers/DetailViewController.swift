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
import SafariServices

class DetailViewController: UIViewController, ImageUpdate {
    /// View that works to hold the scroll view inside the safe area using PureLayout
    fileprivate let tableView = UITableView(frame: .zero, style: .plain)
    fileprivate let imageView = UIImageView(frame: .zero)
    fileprivate let roundIcon = UIImageView(frame: CGRect(x: 0, y: 0, width: Constants.roundIconSize.width, height: Constants.roundIconSize.width))
    fileprivate let favoriteButton = DOFavoriteButton(frame: Constants.defaultButtonRect, image: UIImage(named: "heart.png"))
    fileprivate var favoriteBarButtonItem = UIBarButtonItem()
    fileprivate var publisherButton = UIButton(frame: Constants.defaultButtonRect)
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

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
        setupPublisherButton()
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
        tableView.clipsToBounds = false
        view.addSubview(tableView)
        tableView.autoPinEdge(toSuperviewMargin: .top)
        tableView.autoPinEdge(toSuperviewMargin: .bottom)
        tableView.autoPinEdge(toSuperviewEdge: .leading)
        tableView.autoPinEdge(toSuperviewEdge: .trailing)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: view.bounds.height * 0.25, right: 0)
    }

    fileprivate func setupImageView() {
        imageView.contentMode = .scaleAspectFill

        //setup bur view
        imageView.blurView.setup(style: UIBlurEffectStyle.dark, alpha: 1).enable()
        tableView.parallaxHeader.view = imageView
        tableView.parallaxHeader.minimumHeight = Constants.headerMinimumHeight
        tableView.parallaxHeader.mode = .centerFill
        tableView.parallaxHeader.parallaxHeaderDidScrollHandler = { parallaxHeader in
            //update alpha of blur view on top of image view
            parallaxHeader.view.blurView.alpha = 1 - parallaxHeader.progress
        }

        roundIcon.layer.borderColor = UIColor.white.cgColor
        roundIcon.layer.borderWidth = 2
        roundIcon.layer.cornerRadius = roundIcon.frame.width / 2
        roundIcon.clipsToBounds = true
        roundIcon.contentMode = .scaleAspectFill

        //add round image view to blur content view
        //do not use vibrancyContentView to prevent vibrant effect
        imageView.blurView.blurContentView?.addSubview(roundIcon)
        roundIcon.autoCenterInSuperview()
        roundIcon.autoSetDimensions(to: Constants.publisherIconSize)

        imageView.addParallax(intensity: Constants.parallaxIntensity)
        imageView.blurView.addParallax(intensity: -Constants.parallaxIntensity)

        updateImage()
    }

    fileprivate func setupPublisherButton() {
        imageView.addSubview(publisherButton)
        publisherButton.imageView?.contentMode = .scaleAspectFit
        publisherButton.clipsToBounds = true
        publisherButton.addTarget(self, action: #selector(publisherButtonTouched), for: .touchUpInside)
        publisherButton.autoSetDimensions(to: Constants.defaultButtonRect.size)
        publisherButton.autoPinEdge(toSuperviewMargin: .trailing)
        publisherButton.autoPinEdge(toSuperviewMargin: .bottom)
    }

    fileprivate func setupFavoriteButton() {
        favoriteButton.addTarget(self, action: #selector(favoriteButtonTouched), for: .touchUpInside)
        favoriteBarButtonItem = UIBarButtonItem(customView: favoriteButton)
        navigationItem.rightBarButtonItem = favoriteBarButtonItem
    }

    fileprivate func setupBackground() {
        view.insertSubview(backgroundView, at: 0)
        backgroundView.autoPinEdgesToSuperviewEdges()
    }

    func setupNavigationController() {
        navigationItem.largeTitleDisplayMode = .automatic
        navigationItem.setRightBarButton(favoriteBarButtonItem, animated: true)
    }

    /// Updates the views that use data from recipeModel
    fileprivate func updateRecipeDetails() {
        favoriteButton.isSelected = recipeModel.isFavorite
        navigationItem.title = recipeModel.title
        updateImage()
        UIView.transition(with: tableView,
                          duration: Constants.animationDuration,
                          options: .transitionCrossDissolve,
                          animations: {
                            self.tableView.reloadData()
        },
                          completion: nil
        )

        self.tableView.setContentOffset(CGPoint(x: 0, y:tableView.parallaxHeader.minimumHeight), animated: false)
        publisherButton.setBackgroundImage(recipeModel.publisherImage, for: .normal)
    }

    /// Requests the image from the image manager and lays out the image spacing
    func updateImage() {
        if let imageURL = recipeModel.imageURL {
            let image = ImageManager.image(from: imageURL, in: self)
            if imageView.image == nil {
                // animating when the image is `nil` reduces the flickering effect from loading
                UIView.transition(with: imageView,
                                  duration: Constants.animationDuration,
                                  options: .transitionCrossDissolve,
                                  animations: {
                                    self.imageView.image = image
                },
                                  completion: nil
                )
            } else {
                imageView.image = image
            }
        } else {
            imageView.image = nil
        }

        if let image = imageView.image {
            let navigationBarMaxY = navigationController?.navigationBar.frame.maxY ?? UIApplication.shared.statusBarFrame.maxY
            let approximateSafeAreaHeight = view.bounds.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom - navigationBarMaxY
            var imageScale: CGFloat = 1
            while image.size.height / imageScale > approximateSafeAreaHeight {
                imageScale += 0.5
            }
            imageView.contentScaleFactor = imageScale
            tableView.parallaxHeader.height = min(view.bounds.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom - navigationBarMaxY, image.size.height)
            roundIcon.image = image
        } else {
            roundIcon.image = recipeModel.publisherImage
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

    @objc
    func publisherButtonTouched() {
        guard let url = recipeModel.sourceURL else { return }
        goTo(url)
    }


    func goTo(_ url: URL) {
        let safariViewController = SFSafariViewController(url: url)
        present(safariViewController, animated: true, completion: nil)
    }
}

extension DetailViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return detailTableViewSection.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = detailTableViewSection(rawValue: section)
        return section?.numberOfRows(with: recipeModel) ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier) ?? UITableViewCell(frame: .zero)

        cell.backgroundColor = .clear
        cell.textLabel?.numberOfLines = 0

        guard let section = detailTableViewSection(rawValue: indexPath.section) else {
            return cell
        }

        let text = section.text(for: indexPath.row, recipeModel)
        cell.textLabel?.text = text

        if section.showStrikeThrough(for: indexPath.row, recipeModel) {
            let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: text)
            attributeString.addAttribute(.strikethroughStyle, value: 2, range: NSMakeRange(0, attributeString.length))
            cell.textLabel?.attributedText = attributeString
        }

        return cell
    }
}

extension DetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = detailTableViewSection(rawValue: indexPath.section) else { return }

        if section.useStrikeThrough {
            section.updateIsCompleted(for: indexPath.row, recipeModel)
            tableView.reloadRows(at: [indexPath], with: .automatic)
            return
        }

        tableView.deselectRow(at: indexPath, animated: true)

        guard let url = section.url(for: indexPath.row, recipeModel: recipeModel) else { return }

        goTo(url)
    }
}

