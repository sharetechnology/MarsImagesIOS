//
//  MER.swift
//  MarsImagesIOS
//
//  Created by Mark Powell on 7/28/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import Foundation

class MER: Mission {
    
    let SOL = "Sol"
    let LTST = "LTST"
    let RMC = "RMC"
    let COURSE = "Course"
    
    enum TitleState {
        case    START,
                SOL_NUMBER,
                IMAGESET_ID,
                INSTRUMENT_NAME,
                MARS_LOCAL_TIME,
                DISTANCE,
                YAW,
                PITCH,
                ROLL,
                TILT,
                ROVER_MOTION_COUNTER
    }
    
    override init() {
        super.init()
        self.eyeIndex = 23
        self.instrumentIndex = 1
        self.sampleTypeIndex = 12
        self.cameraFOVs["N"] = 0.78539816
        self.cameraFOVs["P"] = 0.27925268
    }
    
    override func getSortableImageFilename(url: String) -> String {
        let tokens = url.components(separatedBy: "/")
        if tokens.count > 0 {
            let filename = tokens[tokens.count-1]
            if filename.hasPrefix("Sol") {
                return "0" //sort Cornell Pancam images first
            }
            else if (filename.hasPrefix("1") || filename.hasPrefix("2")) && filename.count == 31 {
                let index = filename.index(filename.startIndex, offsetBy: 23)
                return filename.substring(from: index)
            }
            return filename
        }
        return url
    }
    
    override func rowTitle(_ title: String) -> String {
        let merTitle = tokenize(title) as! MERTitle
        if merTitle.instrumentName == "Course Plot" {
            let distanceFormatted = String.localizedStringWithFormat("%.2f", merTitle.distance)
            return "Drive for \(distanceFormatted) meters"
        }
        return merTitle.instrumentName
    }
    
    override func caption(_ title: String) -> String {
        if let t = tokenize(title) as? MERTitle {
            if (t.instrumentName == "Course Plot") {
                return String(format:"Drive for %.2f meters on Sol %d", t.distance, t.sol)
            }
            else {
                return "\(t.instrumentName) image taken on Sol \(t.sol)."
            }
        }
        else {
            return super.caption(title)
        }
    }
    
    override func tokenize(_ title: String) -> Title {
        var mer = MERTitle()
        let tokens = title.components(separatedBy: " ")
        var state = TitleState.START
        for word in tokens {
            if word == SOL {
                state = TitleState.SOL_NUMBER
                continue
            }
            else if word == LTST {
                state = TitleState.MARS_LOCAL_TIME
                continue
            }
            else if word == RMC {
                state = TitleState.ROVER_MOTION_COUNTER
                continue
            }
            var indices:[Int] = []
            switch (state) {
            case .START:
                break
            case .SOL_NUMBER:
                mer.sol = Int(word)!
                state = TitleState.IMAGESET_ID
                break
            case .IMAGESET_ID:
                if word == COURSE {
                    mer = parseCoursePlotTitle(title: title, mer: mer)
                    return mer
                } else {
                    mer.imageSetID = word
                }
                state = TitleState.INSTRUMENT_NAME
                break
            case .INSTRUMENT_NAME:
                if mer.instrumentName.isEmpty {
                    mer.instrumentName = String(word)
                } else {
                    mer.instrumentName.append(" \(word)")
                }
                break
            case .MARS_LOCAL_TIME:
                mer.marsLocalTime = word
                break
            case .ROVER_MOTION_COUNTER:
                indices = word.components(separatedBy: "-").map { Int($0)! }
                mer.siteIndex = indices[0]
                mer.driveIndex = indices[1]
                break
            default:
                print("Unexpected state in parsing image title: \(state)")
                break
            }
        }
        return mer
    }
    
    func parseCoursePlotTitle(title:String, mer: MERTitle) -> MERTitle {
        let tokens = title.components(separatedBy: " ")
        var state = TitleState.START
        for word in tokens {
            if word == COURSE {
                mer.instrumentName = "Course Plot"
            } else if word == "Distance" {
                state = TitleState.DISTANCE
                continue
            } else if word == "yaw" {
                state = TitleState.YAW
                continue
            } else if word == "pitch" {
                state = TitleState.PITCH
                continue
            } else if word == "roll" {
                state = TitleState.ROLL
                continue
            } else if word == "tilt" {
                state = TitleState.TILT
                continue
            } else if word == "RMC" {
                state = TitleState.ROVER_MOTION_COUNTER
                continue
            }
            var indices:[Int] = []
            switch (state) {
            case .START:
                break
            case .DISTANCE:
                mer.distance = Double(word)!
                break
            case .YAW:
                mer.yaw = Double(word)!
                break
            case .PITCH:
                mer.pitch = Double(word)!
                break
            case .ROLL:
                mer.roll = Double(word)!
                break
            case .TILT:
                mer.tilt = Double(word)!
                break
            case .ROVER_MOTION_COUNTER:
                indices = word.components(separatedBy: "-").map { Int($0)! }
                mer.siteIndex = indices[0]
                mer.driveIndex = indices[1]
                break
            default:
                print("Unexpected state in parsing course plot title: \(state)")
            }
        }
        return mer
    }

    override func imageName(imageId: String) -> String {
        
        if imageId.range(of:"False") != nil {
            return "Color"
        }
        
        let irange = imageId.index(imageId.startIndex, offsetBy: instrumentIndex)..<imageId.index(imageId.startIndex, offsetBy: instrumentIndex+1)
        let instrument = imageId[irange]

        if instrument == "N" || instrument == "F" || instrument == "R" {
            let erange = imageId.index(imageId.startIndex, offsetBy: eyeIndex)..<imageId.index(imageId.startIndex, offsetBy:eyeIndex+1)
            let eye = imageId[erange]
            if eye == "L" {
                return "Left"
            } else {
                return "Right"
            }
        } else if instrument == "P" {
            let prange = imageId.index(imageId.startIndex, offsetBy: eyeIndex)..<imageId.index(imageId.startIndex, offsetBy:eyeIndex+2)
            return String(imageId[prange])
        }
        
        return ""
    }

    override func stereoImageIndices(imageIDs: [String]) -> (Int,Int)? {
        let imageid = imageIDs[0]
        let instrument = getInstrument(imageId: imageid)
        if !isStereo(instrument: instrument) {
            return nil
        }
        
        var leftImageIndex = -1;
        var rightImageIndex = -1;
        var index = 0;
        for imageId in imageIDs {
            let eye = getEye(imageId: imageId)
            if leftImageIndex == -1 && eye=="L" && !imageId.hasPrefix("Sol") {
                leftImageIndex = index;
            }
            if rightImageIndex == -1 && eye=="R" {
                rightImageIndex = index;
            }
            index += 1;
        }
        
        if (leftImageIndex >= 0 && rightImageIndex >= 0) {
            return (Int(leftImageIndex), Int(rightImageIndex))
        }
        return nil
    }
    
    func isStereo(instrument:String) -> Bool {
        return instrument == "F" || instrument == "R" || instrument == "N" || instrument == "P"
    }
    
    
    override func getCameraId(imageId: String) -> String {
        if imageId.range(of:"Sol") != nil {
            return "P";
        } else {
            return imageId[1]
        }
    }
    
    override func mastPosition() -> [Double] {
        return [0.456,0.026,-1.0969]
    }
}

class MERTitle: Title {
    var distance = 0.0
    var yaw = 0.0
    var pitch = 0.0
    var roll = 0.0
    var tilt = 0.0
}
