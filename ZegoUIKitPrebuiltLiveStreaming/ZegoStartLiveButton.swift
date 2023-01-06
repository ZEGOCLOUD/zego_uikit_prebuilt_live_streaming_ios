//
//  ZegoStartLiveButton.swift
//  ZegoUIKitPrebuiltLiveStreaming
//
//  Created by zego on 2023/1/3.
//

import UIKit

protocol ZegoStartLiveButtonDelegate: AnyObject {
    func onStartLiveButtonPressed()
}

extension ZegoStartLiveButtonDelegate {
    func onStartLiveButtonPressed() { }
}

open class ZegoStartLiveButton: UIButton {
    
    weak var delegate: ZegoStartLiveButtonDelegate?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.addTarget(self, action: #selector(buttonClick), for: .touchUpInside)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func buttonClick() {
        self.delegate?.onStartLiveButtonPressed()
    }

}
