//
//  ZegoEnableChatButton.swift
//  ZegoUIKitPrebuiltLiveStreaming
//
//  Created by zego on 2023/1/4.
//

import UIKit
import ZegoUIKitSDK

class ZegoEnableChatButton: UIButton {
    
    var enableChat: Bool = true {
        didSet {
            if enableChat {
                self.setImage(ZegoUIKitLiveStreamIconSetType.icon_message_normal.load(), for: .normal)
            } else {
                self.setImage(ZegoUIKitLiveStreamIconSetType.icon_message_disable.load(), for: .normal)
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addTarget(self, action: #selector(buttonClick), for: .touchUpInside)
        if enableChat {
            self.setImage(ZegoUIKitLiveStreamIconSetType.icon_message_normal.load(), for: .normal)
        } else {
            self.setImage(ZegoUIKitLiveStreamIconSetType.icon_message_disable.load(), for: .normal)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func buttonClick() {
        enableChat = !enableChat
        if enableChat {
            ZegoUIKit.shared.setRoomProperty("enableChat", value: "1", callback: nil)
        } else {
            ZegoUIKit.shared.setRoomProperty("enableChat", value: "0", callback: nil)
        }
    }

}
