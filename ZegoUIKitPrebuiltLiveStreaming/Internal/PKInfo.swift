//
//  PKInfo.swift
//  ZegoUIKitPrebuiltLiveStreaming
//
//  Created by zego on 2023/9/21.
//

import UIKit
import ZegoUIKit

public class PKInfo: NSObject {
    
    var pkUser: ZegoUIKitUser
    var pkRoom: String
    
    var seq: Int = 0
    var hostUserID: String = ""
    
    init(user: ZegoUIKitUser, pkRoom: String) {
        self.pkUser = user
        self.pkRoom = pkRoom
    }
    
    func getPKStreamID() -> String {
        return "\(pkRoom)_\(pkUser.userID ?? "")_main"
    }
    
    func getMixerStreamID() -> String {
        return "\(ZegoUIKit.shared.room?.roomID ?? "")_mix"
    }

}
