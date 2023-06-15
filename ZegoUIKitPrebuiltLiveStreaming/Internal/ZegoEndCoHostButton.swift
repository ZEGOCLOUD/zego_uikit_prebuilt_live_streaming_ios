//
//  ZegoEndCoHostButton.swift
//  ZegoUIKitPrebuiltLiveStreaming
//
//  Created by zego on 2022/10/27.
//

import UIKit
import ZegoUIKit

protocol ZegoEndCoHostButtonDelegate: AnyObject {
    func onEndCoHostButtonDidClick()
}

class ZegoEndCoHostButton: UIButton {
    
    weak var delegate: ZegoEndCoHostButtonDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addTarget(self, action: #selector(buttonClick), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func buttonClick() {
        guard let userID = ZegoUIKit.shared.localUserInfo?.userID else { return }
        self.delegate?.onEndCoHostButtonDidClick()
    }
}
