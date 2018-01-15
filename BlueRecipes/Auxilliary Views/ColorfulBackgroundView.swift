//
//  ColorfulBackgroundView.swift
//  I Bought A Deal
//
//  Created by Nathan Fennel on 1/13/18.
//  Copyright © 2018 Nathan Fennel. All rights reserved.
//

import UIKit
import Pastel
import Unbox

class ColorfulBackgroundView: UIView {
    fileprivate var currentPastelView: PastelView?
    fileprivate func pastelView() -> PastelView {
        let pastelView = PastelView(frame: bounds)
        pastelView.animationDuration = Constants.backgroundAnimationDuration
        pastelView.startPastelPoint = .bottomLeft
        pastelView.endPastelPoint = .topRight
        insertSubview(pastelView, at: 0)
        pastelView.autoPinEdgesToSuperviewEdges()
        return pastelView
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        alpha = 0.6
    }

    func updateColors(from imageOptional: UIImage? = nil) {
        currentPastelView?.removeFromSuperview()
        currentPastelView = pastelView()
        if let image = imageOptional {
            let colors = image.randomColors(count: 12, minimumAlpha: 1)
            currentPastelView?.setColors(colors)
        } else {
            resetColors()
        }

        currentPastelView?.startAnimation()
    }

    func resetColors() {
        currentPastelView?.setColors([UIColor(red: 206/255, green: 147/255, blue: 216/255, alpha: 1.0),
                                      UIColor(red: 255/255, green: 154/255, blue: 192/255, alpha: 1.0),
                                      UIColor(red: 183/255, green: 143/255, blue: 207/255, alpha: 1.0),
                                      UIColor(red: 144/255, green: 166/255, blue: 255/255, alpha: 1.0),
                                      UIColor(red: 144/255, green: 205/255, blue: 255/255, alpha: 1.0),
                                      UIColor(red: 175/255, green: 185/255, blue: 191/255, alpha: 1.0),
                                      UIColor(red: 155/255, green: 255/255, blue: 236/255, alpha: 1.0)])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
