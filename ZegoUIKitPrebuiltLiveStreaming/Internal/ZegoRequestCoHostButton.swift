//
//  ZegoRequestCoHostButton.swift
//  ZegoUIKitPrebuiltLiveStreaming
//
//  Created by zego on 2022/10/27.
//

import UIKit
import ZegoUIKit

protocol ZegoRequestCoHostButtonDelegate: AnyObject {
    func requestCoHostButtonDidClick()
}

class ZegoRequestCoHostButton: ZegoStartInvitationButton {
    
    weak var requestCoHostDelegate: ZegoRequestCoHostButtonDelegate?
    
    var hostID: String?
    
    init(_ type: ZegoInvitationType) {
        super.init(type.rawValue)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func buttonClick() {
        self.requestCoHostDelegate?.requestCoHostButtonDidClick()
    }
}
