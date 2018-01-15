//
//  ImageManager.swift
//  BlueRecipes
//
//  Created by Nathan Fennel on 1/14/18.
//  Copyright © 2018 Nathan Fennel. All rights reserved.
//

import UIKit
import Foundation

protocol ImageUpdate {
    func updateImage()
}

class ImageManager {
    /// [url as NSURL : image representation]
    fileprivate static let imageCache = NSCache<NSURL, UIImage>()

    /// A weak data source used to store the association between an Image URL and the object
    /// that is expecting that view
    fileprivate static var imageUpdates = NSMapTable<NSURL, NSObject>(keyOptions: .weakMemory, valueOptions: .weakMemory)

    /// The maximum number of times to try downloading an image before moving it to the end of the Queue
    static var maximumNumberOfTries: Int = 1

    /// The maximum number of concurrent image downloads allowed
    // TODO: Make this dynamic based on system resources available
    fileprivate static let maximumNumberOfConcurrentDownloads: Int = 5

    /**
     Retrieves the image for the given URL.
     Images are first checked in the active memory cache.
     Then, images are checked in the file system.
     Finally, if no image is found then the image is retrieved from the remote URL asynchronously.

     - Parameter url: The remote location for the image. This is also used as the identifier for the image. Images are assumed to be .PNG
     - Parameter imageUpdate: The object to be called when the image is available. This overrides the objects that previously requested this image (independent of the order of the image in the queue).
     - Return: An optionally wrapped image. If the image is not immediately available, then
     */
    static func image(from url: URL, in imageUpdate: (NSObject & ImageUpdate)? = nil) -> UIImage? {
        if let image = imageCache.object(forKey: (url as NSURL)) {
            return image
        }

        if let image = getFromFileSystemImage(named: url.absoluteString) {
            return image
        }

        addImageURLToQueue(url, highPriority: false)
        imageUpdates.setObject(imageUpdate, forKey: (url as NSURL))
        return nil
    }

    fileprivate static func imageRetrieved(image: UIImage, url: URL) {
        let url = (url as NSURL)
        imageCache.setObject(image, forKey: url)
        if let imageUpdate = imageUpdates.object(forKey: url) as? ImageUpdate {
            DispatchQueue.main.async() {
                imageUpdate.updateImage()
            }
            imageUpdates.removeObject(forKey: url)
        }
    }

    /**
     Adds the imageURL to the running queue if needed.
     If the imageURL is already in the queue, nothing changes.

     - Parameter url: The image URL to add to the queue.
     - Parameter highPriority: Flag indicating that this should be moved to the top of the queue. This does not disrupt the current requests.
     */
    static func addImageURLToQueue(_ url: URL, highPriority: Bool) {
        guard !currentDownloads.contains(url) else {
            // no need to change anything
            return
        }

        if highPriority {
            imageURLQueue.insert(url, at: 0)
        } else if !imageURLQueue.contains(url) {
            imageURLQueue.add(url)
        }

        if numberOfCurrentDownloads < maximumNumberOfConcurrentDownloads {
            downloadNextImage()
        }
    }
}

// MARK: Downloading
extension ImageManager {
    /// The current queue of images waiting to download
    private(set) public static var imageURLQueue = NSMutableOrderedSet()
    /// The current set of images that are downloading
    private(set) public static var currentDownloads = NSMutableOrderedSet()
    public static var numberOfCurrentDownloads: Int = 0 {
        didSet {
            if numberOfCurrentDownloads < maximumNumberOfConcurrentDownloads {
                downloadNextImage()
            }
        }
    }

    fileprivate static func downloadNextImage() {
        guard let nextURL = imageURLQueue.firstObject as? URL else {
            return
        }

        downloadImage(url: nextURL)
    }


    fileprivate static func downloadImage(url: URL, tryCount: Int = 0) {
        numberOfCurrentDownloads += 1
        currentDownloads.add(url)
        imageURLQueue.remove(url)
        getDataFromUrl(url: url) { data, response, error in
            guard let data = data, error == nil else {
                if tryCount >= maximumNumberOfTries {
                    downloadImage(url: url, tryCount: tryCount+1)
                    return
                }

                addImageURLToQueue(url, highPriority: false)
                return
            }

            DispatchQueue.main.async() {
                numberOfCurrentDownloads -= 1
                currentDownloads.remove(url)
                guard let image = UIImage(data: data) else {
                    return
                }

                save(image: image, url: url)
            }
        }
    }

    fileprivate static func getDataFromUrl(url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            completion(data, response, error)
            }.resume()
    }
}

// Saving
fileprivate extension ImageManager {
    static func save(image: UIImage, url: URL) {
        let name = url.absoluteString
        let fileManager = FileManager.default
        let imageData = UIImageJPEGRepresentation(image, Constants.jpegCompressionAmount)
        let path = getDirectoryPath(for: name)
        fileManager.createFile(atPath: path as String, contents: imageData, attributes: nil)
        imageRetrieved(image: image, url: url)
    }

    static func getDirectoryPath(for name: String) -> String {
        let _ = FileManager.default
        let strippedName = name.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "")
        let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(strippedName)
        return path
    }

    static func getFromFileSystemImage(named name: String) -> UIImage? {
        let path = getDirectoryPath(for: name)
        if let image = UIImage(contentsOfFile: path) {
            return image
        }

        return nil
    }

    static func deleteImage(named name: String) {
        let fileManager = FileManager.default
        let path = getDirectoryPath(for: name)

        if fileManager.fileExists(atPath: path){
            try? fileManager.removeItem(atPath: path)
        } else {
            print("Failed to delete image named: \(name)")
        }
    }
}
