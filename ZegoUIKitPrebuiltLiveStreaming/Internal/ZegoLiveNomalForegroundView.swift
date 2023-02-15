//
//  CallNomalForegroundView.swift
//  ZegoUIKit
//
//  Created by zego on 2022/7/28.
//

import UIKit
import ZegoUIKitSDK

class ZegoLiveNomalForegroundView: ZegoBaseAudioVideoForegroundView {
    
    let userNameLabel: UILabel = UILabel()
    let micStateIcon: ZegoMicrophoneStateIcon = ZegoMicrophoneStateIcon(frame: .zero)
    lazy var bottomView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.colorWithHexString("#2A2A2A", alpha: 0.5)
        view.addSubview(self.userNameLabel)
        view.addSubview(self.micStateIcon)
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 6
        return view
    }()
    
    var userInfo: ZegoUIKitUser? {
        didSet {
            guard let userInfo = userInfo else {
                return
            }
            self.userNameLabel.backgroundColor = UIColor.clear
            self.userNameLabel.textAlignment = .center
            self.userNameLabel.text = userInfo.userName
            self.userNameLabel.textColor = UIColor.colorWithHexString("#FFFFFF")
            self.userNameLabel.font = UIFont.systemFont(ofSize: 12)
            self.micStateIcon.userID = userInfo.userID
            self.setupLayOut()
        }
    }
    
    var micStatus: Bool {
        get {
            return ZegoUIKit.shared.isMicrophoneOn(userInfo?.userID ?? "")
        }
    }
    
    override init(frame: CGRect, userID: String?, delegate: ZegoBaseAudioVideoForegroundViewDelegate?) {
        super.init(frame: frame, userID: userID, delegate: delegate)
        self.addSubview(self.bottomView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setupLayOut()
    }
    
    func setupLayOut() {
        var bottomWidth: CGFloat = 5
        if self.micStatus {
            bottomWidth = bottomWidth + 5
        } else {
            bottomWidth = bottomWidth + 18 + 5
        }
        var textWidth: CGFloat = 0
        textWidth = self.textWidth(UIFont.systemFont(ofSize: 12), text: self.userInfo?.userName ?? "")
        if bottomWidth + textWidth + 5 > self.frame.size.width && self.frame.size.width > 0 {
            textWidth = textWidth - (bottomWidth + textWidth + 5) + (self.frame.size.width - 5)
        }
        bottomWidth =  bottomWidth + textWidth + 5
        if bottomWidth > self.frame.size.width && self.frame.size.width > 0 {
            bottomWidth = self.frame.size.width - 10
        }
        
        var rightMargin : CGFloat = 0
        if micStatus {
            rightMargin = 5
            self.micStateIcon.frame = CGRect.init(x: bottomWidth - 5 - 18, y: 2.5, width: 0, height: 18)
        } else {
            rightMargin = 5 + 18
            self.micStateIcon.frame = CGRect.init(x: bottomWidth - 5 - 18, y: 2.5, width: 18, height: 18)
        }
        self.userNameLabel.frame = CGRect.init(x: bottomWidth - rightMargin - 5 - textWidth, y: 2.5, width: textWidth, height: 18)
        
        self.bottomView.frame = CGRect.init(x: self.bounds.size.width - bottomWidth - 2.5, y: self.bounds.size.height - 25.5, width: bottomWidth, height: 23)
    }
    
    func textWidth(_ font: UIFont, text: String) -> CGFloat {
        let maxSize: CGSize = CGSize.init(width: 57, height: 16)
        let attributes = [NSAttributedString.Key.font: font]
        let labelSize: CGRect = NSString(string: text).boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
        return labelSize.width
    }
    
    override func onMicrophoneOn(_ user: ZegoUIKitUser, isOn: Bool) {
        if user.userID == self.userInfo?.userID {
            self.setupLayOut()
        }
    }
}
