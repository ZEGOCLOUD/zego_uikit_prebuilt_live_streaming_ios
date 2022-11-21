//
//  ZegoCoHostControlButton.swift
//  ZegoUIKitPrebuiltLiveStreaming
//
//  Created by zego on 2022/10/27.
//

import UIKit
import ZegoUIKitSDK

enum CoHostControlButtonType: Int {
    case requestCoHost
    case cancelCoHost
    case endCoHost
}

protocol ZegoCoHostControlButtonDelegate: AnyObject {
    func coHostControlButtonDidClick(_ type: CoHostControlButtonType, sender: ZegoCoHostControlButton)
    func coHostButtonTypeDidChange()
}

class ZegoCoHostControlButton: UIView {
    
    weak var delegate: ZegoCoHostControlButtonDelegate?
    
    var requestList: [ZegoUIKitUser]?
    
    var hostID: String? {
        didSet {
            guard let hostID = hostID else {
                return
            }
            self.requestCoHostButton.invitees = [hostID]
            self.cancelRequestButton.invitees = [hostID]
        }
    }
    
    var host: ZegoUIKitUser? {
        didSet {
            guard let host = host,
                  let userID = host.userID
            else {
                return
            }
            requestCoHostButton.invitees.append(userID)
            cancelRequestButton.invitees.append(userID)
        }
    }
    
    var liveStatus: String = "0"
    
    var config: ZegoUIKitPrebuiltLiveStreamingConfig = ZegoUIKitPrebuiltLiveStreamingConfig.audience(nil) {
        didSet {
            self.requestCoHostButton.setTitle(config.translationText.requestCoHostButton, for: .normal)
            self.cancelRequestButton.setTitle(config.translationText.cancelRequestCoHostButton, for: .normal)
            self.endCoHostButton.setTitle(config.translationText.endCoHostButton, for: .normal)
        }
    }
    
    lazy var requestCoHostButton: ZegoRequestCoHostButton = {
        let button = ZegoRequestCoHostButton.init(.requestCoHost)
        button.requestCoHostDelegate = self
        button.icon = ZegoUIKitLiveStreamIconSetType.bottombar_lianmai.load()
        button.setTitle(config.translationText.requestCoHostButton, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        let imageEdgeInsets = UIEdgeInsets(top: 0, left: -3, bottom: 0, right: 3)
        let titleEdgeInsets = UIEdgeInsets(top: 0, left: 3, bottom: 0, right: -3)
        button.titleEdgeInsets = titleEdgeInsets
        button.imageEdgeInsets = imageEdgeInsets
        return button
    }()
    
    lazy var cancelRequestButton: ZegoCancelRequestCoHostButton = {
        let button = ZegoCancelRequestCoHostButton()
        button.delegate = self
        button.icon = ZegoUIKitLiveStreamIconSetType.bottombar_lianmai.load()
        button.setTitle(config.translationText.cancelRequestCoHostButton, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        let imageEdgeInsets = UIEdgeInsets(top: 0, left: -3, bottom: 0, right: 3)
        let titleEdgeInsets = UIEdgeInsets(top: 0, left: 3, bottom: 0, right: -3)
        button.titleEdgeInsets = titleEdgeInsets
        button.imageEdgeInsets = imageEdgeInsets
        return button
    }()
    
    lazy var endCoHostButton: ZegoEndCoHostButton = {
        let button = ZegoEndCoHostButton()
        button.delegate = self
        button.setImage(ZegoUIKitLiveStreamIconSetType.bottombar_lianmai.load(), for: .normal)
        button.setTitle(config.translationText.endCoHostButton, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        let imageEdgeInsets = UIEdgeInsets(top: 0, left: -3, bottom: 0, right: 3)
        let titleEdgeInsets = UIEdgeInsets(top: 0, left: 3, bottom: 0, right: -3)
        button.titleEdgeInsets = titleEdgeInsets
        button.imageEdgeInsets = imageEdgeInsets
        return button
    }()
    
    var buttonType: CoHostControlButtonType = .requestCoHost {
        didSet {
            switch buttonType {
            case .requestCoHost:
                self.requestCoHostButton.isHidden = false
                self.cancelRequestButton.isHidden = true
                self.endCoHostButton.isHidden = true
                self.backgroundColor = UIColor.colorWithHexString("#1E2740", alpha: 0.6)
            case .cancelCoHost:
                self.requestCoHostButton.isHidden = true
                self.cancelRequestButton.isHidden = false
                self.endCoHostButton.isHidden = true
                self.backgroundColor = UIColor.colorWithHexString("#1E2740", alpha: 0.6)
            case .endCoHost:
                self.requestCoHostButton.isHidden = true
                self.cancelRequestButton.isHidden = true
                self.endCoHostButton.isHidden = false
                self.backgroundColor = UIColor.colorWithHexString("#FF0D23", alpha: 0.6)
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.requestCoHostButton)
        self.addSubview(self.cancelRequestButton)
        self.addSubview(self.endCoHostButton)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.requestCoHostButton.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        self.cancelRequestButton.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        self.endCoHostButton.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
    }

}

extension ZegoCoHostControlButton: ZegoCancelInvitationButtonDelegate, ZegoEndCoHostButtonDelegate, ZegoRequestCoHostButtonDelegate {
    
    func requestCoHostButtonDidClick() {
        self.delegate?.coHostControlButtonDidClick(.requestCoHost, sender: self)
        if hostID != nil && liveStatus == "1" {
            self.buttonType = .cancelCoHost
            self.delegate?.coHostButtonTypeDidChange()
        }
    }
    
    func onCancelInvitationButtonClick() {
        self.buttonType = .requestCoHost
        self.delegate?.coHostControlButtonDidClick(.cancelCoHost, sender: self)
        self.delegate?.coHostButtonTypeDidChange()
    }
    
    func onEndCoHostButtonDidClick() {
        self.delegate?.coHostControlButtonDidClick(.endCoHost, sender: self)
        self.delegate?.coHostButtonTypeDidChange()
    }
}
