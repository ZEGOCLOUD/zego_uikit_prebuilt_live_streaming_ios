//
//  PKExtendedData.swift
//  ZegoUIKitPrebuiltLiveStreaming
//
//  Created by zego on 2023/9/22.
//

import UIKit

public class PKExtendedData: NSObject {
    
    public var roomID: String?
    public var userName: String?
    public var type: UInt = 0
    public var customData: String?
    
    public static func parse(_ extendedData: String) -> PKExtendedData? {
        let data: [String: AnyObject]? = extendedData.live_convertStringToDictionary()
        if let data = data {
            if data.keys.contains("type") {
                let type: UInt = data["type"] as! UInt
                if type == PKProtocolType.startPK.rawValue || type == PKProtocolType.resume.rawValue || type == PKProtocolType.endPK.rawValue {
                    let pkExtendedData: PKExtendedData = PKExtendedData()
                    pkExtendedData.type = type
                    pkExtendedData.roomID = data["room_id"] as? String
                    pkExtendedData.userName = data["user_name"] as? String
                    pkExtendedData.customData = data["custom_data"] as? String
                    return pkExtendedData
                }
            }
        }
        return nil
    }
    
    public func toJsonString() -> String {
        var jsonData: [String: AnyObject] = [:]
        jsonData["room_id"] = roomID as AnyObject?
        jsonData["user_name"] = userName as AnyObject?
        jsonData["type"] = type as AnyObject
        jsonData["custom_data"] = customData as AnyObject?
        return jsonData.live_jsonString
    }

}
