//
//  MarsPhoto.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 7/28/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import Foundation
import MediaBrowser
import SDWebImage
import SwiftyJSON

class MarsPhoto: Media {
    
    var url:URL
    var imageset:Imageset
    var indexInImageset:Int
    var isLoading = false
    var sourceUrl:String
    var modelJson:JSON?
    
    weak var leftImage:UIImage?
    weak var rightImage:UIImage?
    var leftAndRight:(String,String)?
    var isIncludedInMosaic:Bool {
        return imageset.title.range(of:"Navcam") != nil
            || imageset.title.range(of:"Mastcam Left") != nil
            || imageset.title.range(of:"Pancam") != nil
    }
    
    required public init (url:URL, imageset: Imageset, indexInImageset: Int, sourceUrl:String, modelJsonString:String?) {
        self.url = url
        self.imageset = imageset
        self.indexInImageset = indexInImageset
        self.sourceUrl = sourceUrl
        if let model = modelJsonString {
            modelJson = JSON(parseJSON:model)
        }
        super.init(url:url)
        self.caption = Mission.currentMission().caption(self.imageset.title)
    }
    
    init (_ imageset: Imageset, leftAndRight:(String,String)) {
        self.imageset = imageset
        self.leftAndRight = leftAndRight
        self.url = URL(string:leftAndRight.0)!
        self.sourceUrl = ""
        self.indexInImageset = 0
        super.init()
        self.caption = Mission.currentMission().caption(self.imageset.title)
    }
    
    func downloadImage(_ url:URL, _ setImageFunc:@escaping (_ image:UIImage?)->()) {
        let manager = SDWebImageManager.shared()

        manager.loadImage(with: url, options: [.allowInvalidSSLCertificates],
                              progress:  { (receivedSize, expectedSize, targetUrl) -> Void in
                                if expectedSize > 0 {
                                    let progress = Float(receivedSize)/Float(expectedSize)
                                    let dict:[String:Any] = ["progress": progress, "photo": self]
                                    NotificationCenter.default.post(name: .mediaLoadingProgressNotification, object: dict)
                                }
        },
                              completed: { (image, data, error, cacheType, finished, imageURL) -> Void in
                                if let error = error {
                                    print("Error: \(url) \(error)")
                                    return
                                }
                                setImageFunc(image)
                                if let leftImage = self.leftImage, let rightImage = self.rightImage {
                                    self.underlyingImage = ImageUtility.anaglyph(left: leftImage, right:rightImage)
                                    self.decompressImageAndFinishLoading()
                                }
        })
    }
    
    override public func performLoadUnderlyingImageAndNotify() {
        isLoading = true
        guard (leftAndRight != nil) else {
            super.performLoadUnderlyingImageAndNotify()
            return
        }
        
        let leftUrl = leftAndRight!.0
        downloadImage(URL(string:leftUrl)!, { image in
            self.leftImage = image
        })
        let rightUrl = leftAndRight!.1
        downloadImage(URL(string:rightUrl)!, { image in
            self.rightImage = image
        })
    }

    func decompressImageAndFinishLoading() {
        if let image = self.underlyingImage {
            DispatchQueue.global().async {
                self.underlyingImage = UIImage.decodedImage(with: image)
                DispatchQueue.main.async {
                    self.imageLoadComplete()
                }
            }
        }
        // FIXME put this in else, or remove? or other?
        //imageLoadComplete()
    }

    func imageLoadComplete() {
        isLoading = false
        NotificationCenter.default.post(name: .mediaLoadingDidEndNotification, object: self)
    }
    
    override func unloadUnderlyingImage() {
        isLoading = false
        super.unloadUnderlyingImage()
    }
    
    func fieldOfView() -> Double {
        let imageId = Mission.imageId(url: sourceUrl)
        let cameraId = Mission.currentMission().getCameraId(imageId: imageId)
        return Mission.currentMission().getCameraFOV(cameraId: cameraId) 
    }
    
    func imageId() -> String {
        return Mission.imageId(url: sourceUrl)
    }
    
    func angularDistance(otherImage:MarsPhoto) -> Double {
        guard modelJson != nil && otherImage.modelJson != nil else {
            return 0.0
        }
        
        let v1 = CameraModelUtils.pointingVector(self.modelJson!)
        let v2 = CameraModelUtils.pointingVector(otherImage.modelJson!)
        let dotProduct = dot(v1,v2)
        return acos(dotProduct)
    }
}

extension Notification.Name {
    static let mediaLoadingDidEndNotification = Notification.Name(MEDIA_LOADING_DID_END_NOTIFICATION)
    static let mediaLoadingProgressNotification = Notification.Name(MEDIA_PROGRESS_NOTIFICATION)
}
