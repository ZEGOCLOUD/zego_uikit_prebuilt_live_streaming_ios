//
//  ZegoUIKitPrebuiltLiveStreamingVC.swift
//  ZegoUIKit
//
//  Created by zego on 2022/8/26.
//

import UIKit
import ZegoUIKitSDK

@objc public protocol ZegoUIKitPrebuiltLiveStreamingVCDelegate: AnyObject {
    @objc optional func getForegroundView(_ userInfo: ZegoUIkitUser?) -> UIView?
    @objc optional func onLeaveLiveStreaming()
}

public class ZegoUIKitPrebuiltLiveStreamingVC: UIViewController {
    
    @objc public weak var delegate: ZegoUIKitPrebuiltLiveStreamingVCDelegate?
    
    var userID: String?
    var userName: String?
    var liveID: String?
    var config: ZegoUIKitPrebuiltLiveStreamingConfig = ZegoUIKitPrebuiltLiveStreamingConfig(0) {
        didSet{
            self.bottomBar.config = config
        }
    }
    
    private let help = ZegoUIKitPrebuiltLiveStreamingVC_Help()
    
    lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = ZegoUIKitLiveStreamIconSetType.live_background_image.load()
        return imageView
    }()
    
    lazy var roomTipLabel: UILabel = {
        let label: UILabel = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = "No host is currently online"
        label.textColor = UIColor.colorWithHexString("#FFFFFF")
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    lazy var audioVideoView: ZegoAudioVideoView = {
        let avView: ZegoAudioVideoView = ZegoAudioVideoView()
        avView.delegate = self.help
        avView.backgroundColor = UIColor.colorWithHexString("#4A4B4D")
        avView.showVoiceWave = self.config.showSoundWavesInAudioMode
        return avView
    }()
    
    lazy var leaveButton: ZegoLeaveButton = {
        let button = ZegoLeaveButton()
        if let confirmDialogInfo = self.config.confirmDialogInfo {
            button.quitConfirmDialogInfo = confirmDialogInfo
        }
        button.delegate = self.help
        button.iconLeave = ZegoUIKitLiveStreamIconSetType.top_close.load()
        return button
    }()
    
    lazy var memberButton: ZegoMemberButton = {
        let button = ZegoMemberButton()
        return button
    }()
    
    lazy var bottomBar: ZegoLiveStreamBottomBar = {
        let bar = ZegoLiveStreamBottomBar()
        bar.config = self.config
        bar.delegate = self.help
        return bar
    }()
    
    lazy var messageView: ZegoInRoomMessageView = {
        let messageList = ZegoInRoomMessageView()
        return messageList
    }()
    
    lazy var inputTextView: ZegoInRoomMessageInput = {
        let messageInputView = ZegoInRoomMessageInput()
        messageInputView.frame = CGRect(x: 0, y: UIScreen.main.bounds.size.height, width: UIScreen.main.bounds.size.width, height: 45)
        return messageInputView
    }()
    
    @objc public init(_ appID: UInt32, appSign: String, userID: String, userName: String, liveID: String, config: ZegoUIKitPrebuiltLiveStreamingConfig) {
        super.init(nibName: nil, bundle: nil)
        ZegoUIKit.shared.initWithAppID(appID: appID, appSign: appSign)
        ZegoUIKit.shared.localUserInfo = ZegoUIkitUser.init(userID, userName)
        ZegoUIKit.shared.addEventHandler(self.help)
        self.userID = userID
        self.userName = userName
        self.liveID = liveID
        self.config = config
        self.help.liveStreamingVC = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.joinRoom()
        self.setupLayout()
        self.view.backgroundColor = UIColor.white
        self.view.addSubview(self.audioVideoView)
        self.view.addSubview(self.backgroundImageView)
        self.view.addSubview(self.roomTipLabel)
        self.view.addSubview(self.leaveButton)
        self.view.addSubview(self.memberButton)
        self.view.addSubview(self.messageView)
        self.view.addSubview(self.bottomBar)
        self.view.addSubview(self.inputTextView)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillChangeFrame(node:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.setupLayout()
    }
    
    @objc public func addButtonToBottomMenuBar(_ button: UIButton) {
        self.bottomBar.addButtonToMenuBar(button)
    }
    
    @objc func keyboardWillChangeFrame(node : Notification){
            print(node.userInfo ?? "")
            // 1.获取动画执行的时间
            let duration = node.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval
            // 2.获取键盘最终 Y值
            let endFrame = (node.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            let y = endFrame.origin.y
            
            //3计算工具栏距离底部的间距
            let margin = UIScreen.main.bounds.size.height - y
            //4.执行动画
            UIView.animate(withDuration: duration) {
                self.view.layoutIfNeeded()
                if margin > 0 {
                    self.inputTextView.frame = CGRect(x: 0, y: UIScreen.main.bounds.size.height - margin - 45, width: UIScreen.main.bounds.size.width, height: 45)
                } else {
                    self.inputTextView.frame = CGRect(x: 0, y: UIScreen.main.bounds.size.height - margin, width: UIScreen.main.bounds.size.width, height: 45)
                }
                
            }
    }
    
    private func setupLayout() {
        self.audioVideoView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height)
        self.backgroundImageView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height)
        self.roomTipLabel.center = CGPoint(x: self.view.bounds.size.width * 0.5, y: self.view.bounds.size.height * 0.5)
        self.roomTipLabel.bounds = CGRect(x: 0, y: 0, width: 180, height: 50)
        self.leaveButton.frame = CGRect(x: self.view.frame.size.width - 50, y: 57, width: 26, height: 26)
        self.leaveButton.backgroundColor = UIColor.colorWithHexString("#1E2740", alpha: 0.4)
        self.leaveButton.layer.masksToBounds = true
        self.leaveButton.layer.cornerRadius = 13
        self.memberButton.frame = CGRect(x: self.view.frame.size.width - 50 - 60, y: 56, width: 53, height: 28)
        self.memberButton.layer.masksToBounds = true
        self.memberButton.layer.cornerRadius = 14
        self.memberButton.backgroundColor = UIColor.colorWithHexString("#1E2740", alpha: 0.4)
        self.bottomBar.frame = CGRect(x: 0, y: self.view.frame.size.height - 62, width: self.view.frame.size.width, height: 62)
        self.messageView.frame = CGRect(x: 16, y: self.view.frame.size.height - 62 - 200, width: UIkitLiveScreenWidth - 16 - 89, height: 200)
    }
    
    private func joinRoom() {
        guard let liveID = self.liveID,
              let userID = self.userID,
              let userName = self.userName
        else { return }
        ZegoUIKit.shared.joinRoom(userID, userName: userName, roomID: liveID)
        ZegoUIKit.shared.turnCameraOn(self.userID ?? "", isOn: self.config.turnOnCameraWhenJoining)
        ZegoUIKit.shared.turnMicrophoneOn(self.userID ?? "", isOn: self.config.turnOnMicrophoneWhenJoining)
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.view.endEditing(true)
    }
    
    deinit {
        ZegoUIKit.shared.leaveRoom()
        print("ZegoUIKitPrebuiltLiveStreamingVC deinit")
    }
    
}

class ZegoUIKitPrebuiltLiveStreamingVC_Help: NSObject, AudioVideoViewDelegate, ZegoUIKitEventHandle, ZegoLiveStreamBottomBarDelegate, LeaveButtonDelegate {
    
    weak var liveStreamingVC: ZegoUIKitPrebuiltLiveStreamingVC?
    
    //MARK: -ZegoUIKitEventHandle
    func onRemoteUserLeave(_ userList: [ZegoUIkitUser]) {
        for user in userList {
            if let leaveUserID = user.userID,
               let currentUserID = self.liveStreamingVC?.audioVideoView.userID,
               leaveUserID == currentUserID
            {
                //host leave room
                self.liveStreamingVC?.backgroundImageView.isHidden = false
                self.liveStreamingVC?.roomTipLabel.isHidden = false
                self.liveStreamingVC?.audioVideoView.userID = nil
            }
        }
    }
    
    func onAudioVideoAvailable(_ userList: [ZegoUIkitUser]) {
        for user in userList {
            self.liveStreamingVC?.backgroundImageView.isHidden = true
            self.liveStreamingVC?.roomTipLabel.isHidden = true
            self.liveStreamingVC?.audioVideoView.userID = user.userID
        }
    }
    
    func onAudioVideoUnavailable(_ userList: [ZegoUIkitUser]) {
        
    }
    
    func showHostLeaveAlter() {
        let alter: UIAlertController = UIAlertController.init(title: "Attention", message: "The live is over", preferredStyle: .alert)
        let closeButton: UIAlertAction = UIAlertAction.init(title: "Close", style: .default) { action in
            self.liveStreamingVC?.dismiss(animated: true, completion: nil)
        }
        alter.addAction(closeButton)
        if let liveStreamingVC = liveStreamingVC {
            liveStreamingVC.present(alter, animated: false, completion: nil)
        }
    }
    
    //MARK: -AudioVideoViewDelegate
    func getForegroundView(_ userInfo: ZegoUIkitUser?) -> UIView? {
        return self.liveStreamingVC?.delegate?.getForegroundView?(userInfo)
    }
    
    //MARK: -ZegoLiveStreamBottomBarDelegate
    func onMenuBarMoreButtonClick(_ buttonList: [UIView]) {
        let newList:[UIView] = buttonList
        let vc: ZegoLiveStreamMoreView = ZegoLiveStreamMoreView()
        vc.buttonList = newList
        self.liveStreamingVC?.view.addSubview(vc.view)
        self.liveStreamingVC?.addChild(vc)
    }
    
    func onInRoomMessageButtonClick() {
        self.liveStreamingVC?.inputTextView.startEdit()
    }
    
    //MARK: - LeaveButtonDelegate ZegoLiveStreamBottomBarDelegate
    func onLeaveButtonClick(_ isLeave: Bool) {
        if isLeave {
            self.liveStreamingVC?.dismiss(animated: true)
            self.liveStreamingVC?.delegate?.onLeaveLiveStreaming?()
        }
    }
}

