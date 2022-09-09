//
//  ZegoInRoomMessageButton.swift
//  ZegoUIKit
//
//  Created by zego on 2022/8/25.
//

import UIKit

@objc public protocol ZegoInRoomMessageButtonDelegate: AnyObject {
    func inRoomMessageButtonDidClick()
}

extension ZegoInRoomMessageButtonDelegate {
    func inRoomMessageButtonDidClick(){ }
}

public class ZegoInRoomMessageButton: UIButton {
    
    @objc public weak var delegate: ZegoInRoomMessageButtonDelegate?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.colorWithHexString("1E2740", alpha: 0.4)
        self.setImage(ZegoUIKitLiveStreamIconSetType.bottom_message.load(), for: .normal)
        self.addTarget(self, action: #selector(buttonClick), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func buttonClick() {
        self.delegate?.inRoomMessageButtonDidClick()
    }
    
}
