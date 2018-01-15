//
//  UIBarButtonItem+AppButtons.swift
//  BlueRecipes
//
//  Created by Nathan Fennel on 1/14/18.
//  Copyright © 2018 Nathan Fennel. All rights reserved.
//

import UIKit

extension UIBarButtonItem {
    static func sortButton(target: Any?, action: Selector?) -> UIBarButtonItem {
        let sortImage = UIImage(named: "sorting-arrows")
        let sortButton = UIBarButtonItem(image: sortImage,
                                         landscapeImagePhone: sortImage,
                                         style: .plain,
                                         target: target,
                                         action: action)

        return sortButton
    }
}

