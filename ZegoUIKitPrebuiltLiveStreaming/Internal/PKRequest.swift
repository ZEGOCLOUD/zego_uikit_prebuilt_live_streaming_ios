//
//  PKInvitation.swift
//  ZegoUIKitPrebuiltLiveStreaming
//
//  Created by zego on 2023/9/21.
//

import UIKit

public class PKRequest: NSObject {
    var requestID: String
    var anotherUserID: String
    var anotherUserName: String?
    
    init(requestID: String, anotherUserID: String) {
        self.requestID = requestID
        self.anotherUserID = anotherUserID
    }
}
