//
//  PKBattleView.swift
//  ZegoUIKitPrebuiltLiveStreaming
//
//  Created by zego on 2023/9/25.
//

import UIKit
import ZegoUIKit

protocol PKBattleViewDelegate: AnyObject {
    func getPKForegroundView(_ parentView: UIView, userInfo: ZegoUIKitUser) -> UIView
}


class PKBattleView: UIView {

    weak var delegate: PKBattleViewDelegate?
    var role: ZegoLiveStreamingRole = .host
    
    var pkInfo: PKInfo? {
        didSet {
            if let pkInfo = pkInfo {
                if role == .host {
                    hostView.userID = pkInfo.hostUserID
                    hostView.startPreviewOnly()
                    anothreHostView.userID = pkInfo.pkUser.userID
                    anothreHostView.streamID = pkInfo.getPKStreamID()
                    anothreHostView.startPlayRemoteAudioVideo(.aspectFill)
                } else {
                    mixerView.streamID = pkInfo.getMixerStreamID()
                    mixerView.startPlayRemoteAudioVideo(.aspectFill)
                }
                leftForgroundView.user = ZegoUIKit.shared.getUser(ZegoLiveStreamingManager.shared.getHostID())
                rightForgroundView.user = pkInfo.pkUser
                leftBackgroundView.text = ZegoUIKit.shared.getUser(ZegoLiveStreamingManager.shared.getHostID())?.userName ?? ""
                rightBackgroundView.text = pkInfo.pkUser.userName ?? ""
            }
        }
    }
    
    var pkViewAvaliable: Bool = false {
        didSet {
            if pkViewAvaliable && role != .host {
                mixerView.isHidden = false
            }
        }
    }
    
    lazy var leftForgroundView: PKForegroundView = {
        let view = PKForegroundView()
        view.delegate = self
        return view
    }()
    
    lazy var rightForgroundView: PKForegroundView = {
        let view = PKForegroundView()
        view.delegate = self
        return view
    }()
    
    lazy var leftBackgroundView: PKBackGroundView = {
        let view = PKBackGroundView()
        view.isHidden = true
        return view
    }()
    
    lazy var rightBackgroundView: PKBackGroundView = {
        let view = PKBackGroundView()
        view.isHidden = true
        return view
    }()
    
    lazy var hostView: PKVideoView = {
        let view = PKVideoView()
        view.backgroundColor = UIColor.black
        return view
    }()
    
    lazy var anothreHostView: PKVideoView = {
        let view = PKVideoView()
        view.backgroundColor = UIColor.black
        return view
    }()
    
    lazy var mixerView: PKVideoView = {
        let view = PKVideoView()
        view.backgroundColor = UIColor.black
        return view
    }()
    
    var leftReconnectView: PKReconnectView = {
        let view = PKReconnectView()
        view.isHidden = true
        return view
    }()
    
    var rightReconnectView: PKReconnectView = {
        let view = PKReconnectView()
        view.isHidden = true
        return view
    }()
    
    init(frame: CGRect, role: ZegoLiveStreamingRole) {
        super.init(frame: frame)
        ZegoUIKit.shared.addEventHandler(self)
        ZegoLiveStreamingManager.shared.addLiveManagerDelegate(self)
        self.role = role
        if role == .host {
            self.addSubview(hostView)
            self.addSubview(anothreHostView)
        } else {
            self.addSubview(mixerView)
        }
        self.addSubview(leftBackgroundView)
        self.addSubview(rightBackgroundView)
        self.addSubview(leftForgroundView)
        self.addSubview(rightForgroundView)
        self.addSubview(leftReconnectView)
        self.addSubview(rightReconnectView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        setupUI()
    }
    
    func setupUI() {
        hostView.frame = CGRect(x: 0, y: 0, width: bounds.size.width * 0.5, height: bounds.size.height)
        anothreHostView.frame = CGRect(x: bounds.size.width * 0.5, y: 0, width: bounds.size.width * 0.5, height: bounds.size.height)
        mixerView.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height)
        leftBackgroundView.frame = CGRect(x: 0, y: 0, width: bounds.size.width * 0.5, height: bounds.size.height)
        rightBackgroundView.frame = CGRect(x: bounds.size.width * 0.5, y: 0, width: bounds.size.width * 0.5, height: bounds.size.height)
        leftForgroundView.frame = CGRect(x: 0, y: 0, width: bounds.size.width * 0.5, height: bounds.size.height)
        rightForgroundView.frame = CGRect(x: bounds.size.width * 0.5, y: 0, width: bounds.size.width * 0.5, height: bounds.size.height)
        leftReconnectView.frame = CGRect(x: 0, y: 0, width: bounds.size.width * 0.5, height: bounds.size.height)
        rightReconnectView.frame = CGRect(x: bounds.size.width * 0.5, y: 0, width: bounds.size.width * 0.5, height: bounds.size.height)
        if ZegoLiveStreamingManager.shared.currentRole == .host {
            leftBackgroundView.isHidden = ZegoUIKit.shared.localUserInfo?.isCameraOn ?? true
        }
    }

}

extension PKBattleView: ZegoUIKitEventHandle, ZegoLiveStreamingManagerDelegate, PKForegroundViewDelegate {
    
    func onCameraOn(_ user: ZegoUIKitUser, isOn: Bool) {
        if user.userID == ZegoLiveStreamingManager.shared.getHostID() {
            if ZegoLiveStreamingManager.shared.currentRole == .host {
                hostView.startPreviewOnly()
            }
            leftBackgroundView.isHidden = isOn
        }
    }
    
    func onAnotherHostCameraStatus(isOn: Bool) {
        rightBackgroundView.isHidden = isOn
    }
    
    func onLocalHostCameraStatus(isOn: Bool) {
        leftBackgroundView.isHidden = isOn
    }
    
    func onHostIsConnected() {
        leftReconnectView.isHidden = true
    }
    
    func onHostIsReconnecting() {
        leftReconnectView.isHidden = false
    }
    
    func onAnotherHostIsConnected() {
        rightReconnectView.isHidden = true
    }
    
    func onAnotherHostIsReconnecting() {
        rightReconnectView.isHidden = false
    }
    
    func getForegroundView(_ parentView: UIView, userInfo: ZegoUIKitUser) -> UIView {
        return self.delegate?.getPKForegroundView(parentView, userInfo: userInfo) ?? UIView()
    }
}

class PKVideoView: UIView {
    
    var userID: String?
    var streamID: String?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startPlayRemoteAudioVideo(_ viewMode: ZegoUIKitVideoFillMode) {
        guard let streamID = streamID else { return }
        ZegoUIKit.shared.startPlayStream(streamID, renderView: self, videoModel: viewMode)
        let callID = ZegoLiveStreamingManager.shared.callID
        let reportData = ["call_id": callID as AnyObject,"stream_id": self.streamID as AnyObject,]
        ReportUtil.sharedInstance().reportEvent(liveStreamPKStartPlayStreamReportString, paramsDict: reportData)
    }
    
    func stopPlayRemoteAudioVideo() {
        guard let streamID = streamID else { return }
        ZegoUIKit.shared.stopPlayStream(streamID)
        let callID = ZegoLiveStreamingManager.shared.callID
        let reportData = ["call_id": callID as AnyObject,"stream_id": self.streamID as AnyObject,]
        ReportUtil.sharedInstance().reportEvent(liveStreamPKStartPlayStreamFinishReportString, paramsDict: reportData)
    }
    
    func mutePlayAudio(_ mute: Bool) {
        guard let streamID = streamID else { return }
        ZegoUIKit.shared.mutePlayStreamAudio(streamID: streamID, mute: mute)
    }
    
    func startPreviewOnly() {
        ZegoUIKit.shared.startPreview(self, videoMode: .aspectFill)
    }
    
    func startPublishAudioVideo() {
        guard let streamID = streamID else { return }
        ZegoUIKit.shared.startPublishingStream(streamID)
    }
    
    func stopPublishAudioVideo() {
        ZegoUIKit.shared.stopPublishingStream()
    }
}

class PKReconnectView: UIView {
    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.text = "host is reconnecting..."
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.black
        self.addSubview(textLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        textLabel.frame = CGRect(x: 5, y: (bounds.size.height * 0.5) - 10 , width: bounds.size.width - 10, height: 20)
    }
}

class PKBackGroundView: UIView {
    
    var text: String? {
        didSet {
            guard let text = text else { return }
            if text.count > 0 {
                let firstStr: String = String(text[text.startIndex])
                self.headLabel.text = firstStr
            }
        }
    }
    
    var lastUrl: String?

    lazy var headLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 23, weight: .semibold)
        label.textAlignment = .center
        label.textColor = UIColor.colorWithHexString("#222222")
        label.backgroundColor = UIColor.colorWithHexString("#DBDDE3")
        return label
    }()
    
//    lazy var headImageView: UIImageView = {
//        let imageView = UIImageView()
//        return imageView
//    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.black
        self.addSubview(self.headLabel)
//        self.addSubview(self.headImageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let headW: CGFloat = 0.4 * self.frame.size.width
        let headH: CGFloat = 0.4 * self.frame.size.width
        let headY = (bounds.size.height - headH) * 0.5
        headLabel.frame = CGRect(x: (self.frame.size.width - headW) / 2, y: headY, width: headW, height: headH)
        headLabel.layer.masksToBounds = true
        headLabel.layer.cornerRadius = headW * 0.5
//        self.headImageView.frame = CGRect(x: (self.frame.size.width - headW) / 2, y: headY, width: headW, height: headH)
//        self.headImageView.layer.masksToBounds = true
//        self.headImageView.layer.cornerRadius = headW * 0.5
    }
    
//    func setHeadImageUrl(_ url: String) {
//        if let imageUrl: URL = URL(string: url) {
//            if !UIApplication.shared.canOpenURL(imageUrl){
//                //invalid url
//                return
//            }
//            self.lastUrl = url
//            self.headImageView.downloadedFrom(url: imageUrl)
//        }
//    }
}

protocol PKForegroundViewDelegate: AnyObject {
    func getForegroundView(_ parentView: UIView, userInfo: ZegoUIKitUser) -> UIView
}

class PKForegroundView: UIView {
    
    weak var delegate: PKForegroundViewDelegate?
    var user: ZegoUIKitUser? {
        didSet {
            if let user = user,
               let delegate = delegate
            {
                containerView = delegate.getForegroundView(self, userInfo: user)
                self.addSubview(containerView!)
            }
        }
    }
    
    var containerView: UIView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        containerView?.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height)
    }
}
