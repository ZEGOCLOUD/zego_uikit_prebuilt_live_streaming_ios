//
//  ZegoInRoomMessageButton.swift
//  ZegoUIKit
//
//  Created by zego on 2022/8/25.
//

import UIKit
import ZegoUIKitSDK

@objc public protocol ZegoInRoomMessageButtonDelegate: AnyObject {
    func inRoomMessageButtonDidClick()
}

extension ZegoInRoomMessageButtonDelegate {
    func inRoomMessageButtonDidClick(){ }
}

public class ZegoInRoomMessageButton: UIButton {
    
    @objc public weak var delegate: ZegoInRoomMessageButtonDelegate?
    
    var hostID: String?
    
    var enableChat: Bool = true {
        didSet {
            if enableChat {
                self.setImage(ZegoUIKitLiveStreamIconSetType.bottom_message.load(), for: .normal)
                self.isUserInteractionEnabled = true
            } else {
                self.setImage(ZegoUIKitLiveStreamIconSetType.bottom_message_disable.load(), for: .normal)
                self.isUserInteractionEnabled = false
            }
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setImage(ZegoUIKitLiveStreamIconSetType.bottom_message.load(), for: .normal)
        self.addTarget(self, action: #selector(buttonClick), for: .touchUpInside)
        ZegoUIKit.shared.addEventHandler(self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func buttonClick() {
        self.delegate?.inRoomMessageButtonDidClick()
    }
    
}

extension ZegoInRoomMessageButton: ZegoUIKitEventHandle {
    
    public func onRoomPropertyUpdated(_ key: String, oldValue: String, newValue: String) {
        if self.hostID != ZegoUIKit.shared.localUserInfo?.userID {
            if key == "enableChat" {
                if newValue  == "0" {
                    enableChat = false
                } else if newValue == "1" {
                    enableChat = true
                }
            }
        }
    }
    
}

