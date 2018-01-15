//
//  UIAlertAction+AppActions.swift
//  BlueRecipes
//
//  Created by Nathan Fennel on 1/14/18.
//  Copyright © 2018 Nathan Fennel. All rights reserved.
//

import UIKit

extension UIAlertAction {
    static var cancel: UIAlertAction {
        // TODO: Localize!
        return UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    }
}
