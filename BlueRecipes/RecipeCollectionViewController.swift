//
//  RecipeCollectionViewController.swift
//  BlueRecipes
//
//  Created by Nathan Fennel on 1/14/18.
//  Copyright © 2018 Nathan Fennel. All rights reserved.
//

import UIKit

/// View controller that shows recipes in a collectionview
class RecipeCollectionViewController: UICollectionViewController {
    /// The controller that maintains all data relating to the
    fileprivate var recipeDataController = RecipeDataController()
    /// Whether or not the view controller is in Search Mode with filters being applied
    fileprivate var filterActive: Bool = false
    /// View Controller used for presenting an recipe in detail
    fileprivate let detailViewController = DetailViewController()

    fileprivate var searchBar: UISearchBar = UISearchBar(frame: .zero)
    fileprivate lazy var searchButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(searchButtonTouched))
    fileprivate lazy var sortButton = UIBarButtonItem.sortButton(target: self, action: #selector(sortButtonTouched))
    var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .appColor
        refreshControl.addTarget(self, action: #selector(refreshControlAction), for: .valueChanged)
        return refreshControl
    }()

    let reuseIdentifier:String = "Cell"

    // MARK: init
    init() {
        RecipeCollectionViewLayout.setup()
        super.init(collectionViewLayout: RecipeCollectionViewLayout.flowLayout)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        RecipeCollectionViewLayout.setup()
        super.init(collectionViewLayout: RecipeCollectionViewLayout.flowLayout)
        commonInit()
    }

    func commonInit() {
        setupCollectionView()
        setupSearchBar()
    }

    // MARK: Lifecycle
    override func viewDidLoad() {
        setupNavigationController()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepareUI()

        enableVisibleFavoriteButtons() // If the user favorited an recipe on the detail page

        if recipeDataController.sortingOption == .byFavorites {
            // If the user changed the favorite status on the detail page then the order needs to be updated
            recipeDataController.sortingOption = .byFavorites
            collectionView?.reloadData()
        }

        setupNavigationController()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        guard filterActive else {
            return
        }

        cancelSearching()
    }

    // MARK: Setup
    func setupNavigationController() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .automatic
        if filterActive {
            navigationItem.titleView = searchBar
            searchBar.becomeFirstResponder()
            navigationItem.setLeftBarButton(nil, animated: true)
            navigationItem.setRightBarButton(nil, animated: true)
        } else {
            navigationItem.title = "BlueRecipes"
            navigationItem.leftBarButtonItem = sortButton
            navigationItem.rightBarButtonItem = searchButton
        }
    }

    // MARK: <UICollectionViewDataSource>
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return recipeDataController.sectionCount()
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if filterActive {
            return recipeDataController.filteredRecipeCount(forSection: section)
        }

        return recipeDataController.recipeCount(forSection: section)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView .dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? RecipeCollectionViewCell ?? RecipeCollectionViewCell()

        let recipe: RecipeModel = {
            if (filterActive) {
                return self.recipeDataController.filteredRecipe(for: indexPath)
            }

            return self.recipeDataController.recipe(for: indexPath)
        }()

        cell.recipeModel = recipe

        return cell
    }

    // MARK: <UICollectionViewDelegateFlowLayout>
    func collectionView(collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAtIndex section: Int) -> UIEdgeInsets{
        return UIEdgeInsetsMake(searchBar.frame.size.height, 0, 0, 0);
    }

    func collectionView(collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeforItemAtIndexPath indexPath: NSIndexPath) -> CGSize{
        return RecipeCollectionViewLayout.itemSize
    }

    // MARK: <UICollectionViewDelegate>
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let recipeModel: RecipeModel = {
            if filterActive {
                return recipeDataController.filteredRecipe(for: indexPath)
            }

            return recipeDataController.recipe(for: indexPath)
        }()

        detailViewController.recipeModel = recipeModel
        navigationController?.pushViewController(detailViewController, animated: true)
    }

    fileprivate func enableVisibleFavoriteButtons() {
        guard let indexPaths = collectionView?.indexPathsForVisibleItems else {
            return
        }

        for indexPath in indexPaths {
            guard let cell = collectionView?.cellForItem(at: indexPath) as? RecipeCollectionViewCell else {
                return
            }

            cell.updateFavoriteButton()
        }
    }

    // MARK: Setup
    func prepareUI() {
        setupRefreshControl()
    }

    func setupCollectionView() {
        guard let collectionView = collectionView else {
            return
        }

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(RecipeCollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.backgroundColor = .white
        view.addSubview(collectionView)
    }

    func setupSearchBar() {
        searchBar.searchBarStyle = .minimal
        searchBar.tintColor = .appColor
        searchBar.barTintColor = .appColor
        searchBar.delegate = self
        searchBar.placeholder = "Search all recipes"
    }

    func setupRefreshControl() {
        guard let collectionView = collectionView else {
            return
        }

        if !refreshControl.isDescendant(of: collectionView) {
            collectionView.addSubview(refreshControl)
        }
    }
}

// MARK: Searching
extension RecipeCollectionViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count > 0 {
            filterActive    = true
            filterContentForSearchText(searchText: searchText)
            collectionView?.reloadData()
        }
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
        navigationItem.titleView = searchBar
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        filterActive = false
        searchBar.setShowsCancelButton(false, animated: true)
        navigationItem.titleView = nil
        collectionView?.reloadData()
    }

    func filterContentForSearchText(searchText:String) {
        recipeDataController.filterRecipes(by: searchText)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        cancelSearching()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        filterActive = true
        view.endEditing(true)
    }

    func cancelSearching() {
        func searchBarDeactivation() {
            recipeDataController.clearFilters()
            filterActive = false
            searchBar.resignFirstResponder()
            searchBar.text = ""
            setupNavigationController()
            collectionView?.reloadData()
        }

        UIView.transition(with: view,
                          duration: Constants.animationDuration,
                          options: .transitionCrossDissolve,
                          animations: {
                            searchBarDeactivation()
        },
                          completion: nil
        )
    }
}

// MARK: Button Actions
fileprivate extension RecipeCollectionViewController {
    @objc
    func refreshControlAction() {
        cancelSearching()

        let delayTime = 2.0
        DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
            // stop refreshing after 2 seconds
            self.collectionView?.reloadData()
            self.refreshControl.endRefreshing()
        }
    }

    @objc
    func sortButtonTouched() {
        let alertController = UIAlertController(title: "Sorting Options",
                                                message: nil,
                                                preferredStyle: .alert)

        func reloadAndScrollToTop() {
            self.collectionView?.resetScrollPositionToTop(forced: false)
            self.collectionView?.reloadData()
        }

        let alphabetically = UIAlertAction(title: "A-Z", style: .default) { (_) in
            self.recipeDataController.sortingOption = .alphabetically
            reloadAndScrollToTop()
        }
        alertController.addAction(alphabetically)

        let byValue = UIAlertAction(title: "$$$ - ¢", style: .default) { (_) in
            self.recipeDataController.sortingOption = .byIngredients
            reloadAndScrollToTop()
        }
        alertController.addAction(byValue)

        let byFavorites = UIAlertAction(title: "❤️", style: .default) { (_) in
            self.recipeDataController.sortingOption = .byFavorites
            reloadAndScrollToTop()
        }
        alertController.addAction(byFavorites)

        let random = UIAlertAction(title: "🎲", style: .default) { (_) in
            self.recipeDataController.sortingOption = .random
            reloadAndScrollToTop()
        }
        alertController.addAction(random)

        alertController.addAction(UIAlertAction.cancel)

        present(alertController, animated: true, completion: nil)
    }

    @objc
    func searchButtonTouched() {
        func searchBarActivation() {
            navigationItem.titleView = searchBar
            searchBar.becomeFirstResponder()
            navigationItem.setLeftBarButton(nil, animated: true)
            navigationItem.setRightBarButton(nil, animated: true)
        }
        guard let navigationBar = navigationController?.navigationBar else {
            searchBarActivation()
            return
        }

        UIView.transition(with: navigationBar,
                          duration: Constants.animationDuration,
                          options: .transitionCrossDissolve,
                          animations: {
                            searchBarActivation()
        },
                          completion: nil
        )
    }
}

extension UICollectionView {
    /// Sets content offset to the top.
    func resetScrollPositionToTop(forced: Bool = true) {
        guard numberOfItems(inSection: 0) > 0 else {
            // not perfect... :/
            contentOffset = CGPoint(x: -contentInset.left, y: -contentInset.top)
            return
        }

        let firstIndexPath = IndexPath(row: 0, section: 0)

        // TODO: indexPathsForVisibleRecipes is empty?
        for indexPath in indexPathsForVisibleItems {
            if firstIndexPath.row == indexPath.row,
                firstIndexPath.section == indexPath.section {
                return
            }
        }

        scrollToItem(at: firstIndexPath, at: .top, animated: true)
    }
}
