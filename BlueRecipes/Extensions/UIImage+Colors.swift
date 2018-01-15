//
//  UIImage+Colors.swift
//  BlueRecipes
//
//  Created by Nathan Fennel on 1/14/18.
//  Copyright © 2018 Nathan Fennel. All rights reserved.
//

import UIKit

extension UIImage {
    subscript (x: Int, y: Int) -> UIColor? {
        let point = CGPoint(x: x, y: y)
        return colors(at: [point]).first
    }

    /**
     Finds the colors at the given points.

     - Parameter points: The points to look for colors in the image. Points that are outside of the image size are modulo the corresponding dimension to fit inside of the image.
     - Parameter minimumAlpha: Colors that are returned will not have alpha values below this value.
     */
    func colors(at points: [CGPoint], minimumAlpha: CGFloat = 0) -> [UIColor] {
        var colors = [UIColor]()

        guard let cgImage = cgImage,
            let provider = cgImage.dataProvider,
            let providerData = provider.data,
            let data = CFDataGetBytePtr(providerData) else {
                return colors
        }

        func color(_ point: CGPoint) -> UIColor {
            let x = max(Int(point.x) % Int(size.width), 0)
            let y = max(Int(point.y) % Int(size.height), 0)

            let numberOfComponents = 4
            let pixelData = ((Int(size.width) * y) + x) * numberOfComponents

            let r = CGFloat(data[pixelData]) / 255.0
            let g = CGFloat(data[pixelData + 1]) / 255.0
            let b = CGFloat(data[pixelData + 2]) / 255.0
            let a = min(CGFloat(data[pixelData + 3]) / 255.0, minimumAlpha)

            return UIColor(red: r, green: g, blue: b, alpha: a)
        }

        for point in points {
            colors.append(color(point))
        }

        return colors
    }

    /// Returns colors from a random set of points inside the image
    func randomColors(count: Int, minimumAlpha: CGFloat = 0) -> [UIColor] {
        let points = randomPoints(max: count)
        return colors(at: points, minimumAlpha: minimumAlpha)
    }

    func randomPoints(max: Int = 10) -> [CGPoint] {
        var points = [CGPoint]()

        for _ in 0..<max {
            let x = CGFloat(arc4random_uniform(UInt32(size.width)))
            let y = CGFloat(arc4random_uniform(UInt32(size.height)))
            let randomPoint = CGPoint(x: x, y: y)
            points.append(randomPoint)
        }

        return points
    }
}

