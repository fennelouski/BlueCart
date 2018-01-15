//
//  UIView+Parallax.swift
//  BlueRecipes
//
//  Created by Nathan Fennel on 1/14/18.
//  Copyright © 2018 Nathan Fennel. All rights reserved.
//

import UIKit

extension UIView {
    func addParallax(intensity: CGFloat) {
        let min = -intensity
        let max = intensity

        let xAxis = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        xAxis.minimumRelativeValue = min
        xAxis.maximumRelativeValue = max

        let yAxis = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        yAxis.minimumRelativeValue = min
        yAxis.maximumRelativeValue = max

        let xyGroup = UIMotionEffectGroup()
        xyGroup.motionEffects = [xAxis, yAxis]

        self.addMotionEffect(xyGroup)
    }
}

