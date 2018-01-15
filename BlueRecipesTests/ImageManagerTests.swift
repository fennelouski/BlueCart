//
//  ImageManagerTests.swift
//  BlueRecipesTests
//
//  Created by Nathan Fennel on 1/15/18.
//  Copyright © 2018 Nathan Fennel. All rights reserved.
//

import XCTest
@testable import BlueRecipes

class ImageManagerTests: XCTestCase {
    let imageURL1 = URL(string: "https://res.cloudinary.com/hellofresh/image/upload/dpr_auto,f_auto,fl_lossy,q_80,w_auto:100:1280/v1/hellofresh_s3/image/pineapple-poblano-beef-tacos-b7badad1.jpg")!
    let imageURL2 = URL(string: "https://www.vnutritionandwellness.com/wp-content/uploads/2016/06/walnut-meat-tacos-4-800x531.jpg")!

    override func setUp() {
        super.setUp()
    }

    func testDownloadQueue() {
        ImageManager.addImageURLToQueue(imageURL1, highPriority: false)
        XCTAssertTrue(ImageManager.currentDownloads.contains(imageURL1) || ImageManager.imageURLQueue.contains(imageURL1))
    }

    func testHighPriority() {
        ImageManager.addImageURLToQueue(imageURL2, highPriority: true)
        XCTAssertNotNil(ImageManager.imageURLQueue.firstObject as? URL)
        XCTAssertEqual(ImageManager.imageURLQueue.firstObject as! URL, imageURL2)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testPerformanceExample() {

        // This is an example of a performance test case.
        self.measure {
            let _ = ImageManager.image(from: imageURL1)
            let _ = ImageManager.image(from: imageURL2)
        }
    }
}

