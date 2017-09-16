//
//  CameraModel.swift
//  MarsImagesIOS
//
//  Created by Powell, Mark W (397F) on 8/20/17.
//  Copyright © 2017 Mark Powell. All rights reserved.
//

import Foundation
import SwiftyJSON

class CameraModel {

    static func model(_ json: JSON) -> Model {
        var returnedModel: Model?
        var type = ""
        var mtype:Double
        var mparm:Double
        var width:Double
        var height:Double
        
        let model = json.arrayValue[1]
        let dimensions = json.arrayValue[0]
        type = model["type"].stringValue
        let comps = model["components"].dictionaryValue
        let cDict = comps["c"]?.arrayValue
        let aDict = comps["a"]?.arrayValue
        let hDict = comps["h"]?.arrayValue
        let vDict = comps["v"]?.arrayValue
        let oDict = comps["o"]?.arrayValue
        let rDict = comps["r"]?.arrayValue
        let eDict = comps["e"]?.arrayValue
        mtype = comps["t"]?.doubleValue ?? 0.0
        mparm = comps["p"]?.doubleValue ?? 0.0
        
        let area = dimensions["area"].arrayValue
        width = area[0].doubleValue
        height = area[1].doubleValue

        if type == "CAHV" {
            let cahv = CAHV()
            cahv.c = [cDict![0].doubleValue, cDict![1].doubleValue, cDict![2].doubleValue]
            cahv.a = [aDict![0].doubleValue, aDict![1].doubleValue, aDict![2].doubleValue]
            cahv.h = [hDict![0].doubleValue, hDict![1].doubleValue, hDict![2].doubleValue]
            cahv.v = [vDict![0].doubleValue, vDict![1].doubleValue, vDict![2].doubleValue]
            returnedModel = cahv;
        } else if type == "CAHVOR" {
            let cahvor = CAHVOR()
            cahvor.c = [cDict![0].doubleValue, cDict![1].doubleValue, cDict![2].doubleValue]
            cahvor.a = [aDict![0].doubleValue, aDict![1].doubleValue, aDict![2].doubleValue]
            cahvor.h = [hDict![0].doubleValue, hDict![1].doubleValue, hDict![2].doubleValue]
            cahvor.v = [vDict![0].doubleValue, vDict![1].doubleValue, vDict![2].doubleValue]
            cahvor.o = [oDict![0].doubleValue, oDict![1].doubleValue, oDict![2].doubleValue]
            cahvor.r = [rDict![0].doubleValue, rDict![1].doubleValue, rDict![2].doubleValue]
            returnedModel = cahvor
        } else if type == "CAHVORE" {
            let cahvore = CAHVORE()
            cahvore.c = [cDict![0].doubleValue, cDict![1].doubleValue, cDict![2].doubleValue]
            cahvore.a = [aDict![0].doubleValue, aDict![1].doubleValue, aDict![2].doubleValue]
            cahvore.h = [hDict![0].doubleValue, hDict![1].doubleValue, hDict![2].doubleValue]
            cahvore.v = [vDict![0].doubleValue, vDict![1].doubleValue, vDict![2].doubleValue]
            cahvore.o = [oDict![0].doubleValue, oDict![1].doubleValue, oDict![2].doubleValue]
            cahvore.r = [rDict![0].doubleValue, rDict![1].doubleValue, rDict![2].doubleValue]
            cahvore.e = [eDict![0].doubleValue, eDict![1].doubleValue, eDict![2].doubleValue]
            cahvore.t = mtype
            cahvore.p = mparm
            returnedModel = cahvore
        }
        if var returnedModel = returnedModel {
            returnedModel.xdim = width
            returnedModel.ydim = height
            return returnedModel;
        }
        return CAHV()
    }

}