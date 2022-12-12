//
//  ZegoUIKitPrebuiltLiveStreamingVC.swift
//  ZegoUIKit
//
//  Created by zego on 2022/8/26.
//

import UIKit
import ZegoUIKitSDK

@objc public protocol ZegoUIKitPrebuiltLiveStreamingVCDelegate: AnyObject {
    @objc optional func getForegroundView(_ userInfo: ZegoUIKitUser?) -> UIView?
    @objc optional func onLeaveLiveStreaming()
    @objc optional func onLiveStreamingEnded()
}

public class ZegoUIKitPrebuiltLiveStreamingVC: UIViewController {
    
    @objc public weak var delegate: ZegoUIKitPrebuiltLiveStreamingVCDelegate?
    let inputViewHeight: CGFloat = 55
    var userID: String?
    var userName: String?
    var liveID: String?
    var config: ZegoUIKitPrebuiltLiveStreamingConfig = ZegoUIKitPrebuiltLiveStreamingConfig.audience() {
        didSet{
            self.bottomBar.config = config
            self.memberButton.config = config
        }
    }
    
    var currentHost: ZegoUIKitUser? {
        didSet {
            self.bottomBar.hostID = self.currentHost?.userID
            self.memberButton.currentHost = currentHost
            if self.config.role != .host {
                if currentHost != nil {
                    self.headIconView.isHidden = false
                } else {
                    self.headIconView.isHidden = true
                }
            }
        }
    }
    
    var requestCoHostCount: Int = 0
    //host
    var audienceSeatList: [ZegoUIKitUser] = []
    var hostInviteList: [ZegoUIKitUser] = []
    var coHostList: [ZegoUIKitUser] = []
    //audience
    var audienceInviteList: [ZegoUIKitUser] = []
    var audienceReceiveInviteList: [ZegoUIKitUser] = []
    var isShowCameraPermissionAlter: Bool = false
    var isShowMicPermissionAlter: Bool = false
    var liveStatus: String = "0" {
        didSet {
            self.bottomBar.liveStatus = liveStatus
            self.audioVideoContainer.view.isHidden = (liveStatus == "1" || self.config.role == .host) ? false : true
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
        label.text = self.config.translationText.noHostOnline
        label.textColor = UIColor.colorWithHexString("#FFFFFF")
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    lazy var audioVideoContainer: ZegoAudioVideoContainer = {
        let container = ZegoAudioVideoContainer()
        container.delegate = self.help
        let layoutConfig = ZegoLayoutPictureInPictureConfig()
        layoutConfig.smallViewPostion = .bottomRight
        layoutConfig.smallViewSize = CGSize(width: 93, height: 124)
        layoutConfig.spacingBetweenSmallViews = 8
        let audioVideoViewConfig: ZegoAudioVideoViewConfig = ZegoAudioVideoViewConfig()
        audioVideoViewConfig.useVideoViewAspectFill = self.config.audioVideoViewConfig.useVideoViewAspectFill
        audioVideoViewConfig.showSoundWavesInAudioMode = self.config.audioVideoViewConfig.showSoundWavesInAudioMode
        container.setLayout(.pictureInPicture, config: layoutConfig, audioVideoConfig: audioVideoViewConfig)
        container.view.backgroundColor = UIColor.colorWithHexString("#4A4B4D")
        return container
    }()
    
    lazy var leaveButton: ZegoLeaveButton = {
        let button = ZegoLeaveButton()
        if let confirmDialogInfo = self.config.confirmDialogInfo {
            confirmDialogInfo.dialogPresentVC = self
            button.quitConfirmDialogInfo = confirmDialogInfo
        }
        button.delegate = self.help
        button.iconLeave = ZegoUIKitLiveStreamIconSetType.top_close.load()
        return button
    }()
    
    lazy var backButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(backButtonClick), for: .touchUpInside)
        button.setImage(ZegoUIKitLiveStreamIconSetType.icon_comeback.load(), for: .normal)
        return button
    }()
    
    lazy var switchCameraButton: UIButton = {
        let button: ZegoSwitchCameraButton = ZegoSwitchCameraButton()
        button.iconFrontFacingCamera = ZegoUIKitLiveStreamIconSetType.icon_nav_flip.load()
        button.iconBackFacingCamera = ZegoUIKitLiveStreamIconSetType.icon_nav_flip.load()
        return button
    }()
    
    lazy var memberButton: ZegoMemberButton = {
        let button = ZegoMemberButton()
        button.controller = self
        button.delegate = self.help
        button.config = self.config
        return button
    }()
    
    var showRedDot: Bool = false {
        didSet {
            self.redDot.isHidden = !showRedDot
        }
    }
    
    lazy var redDot: UIView = {
        let dot = UIView()
        dot.backgroundColor = UIColor.red
        dot.isHidden = true
        return dot
    }()
    
    lazy var bottomBar: ZegoLiveStreamBottomBar = {
        let bar = ZegoLiveStreamBottomBar()
        bar.config = self.config
        bar.delegate = self.help
        bar.liveStatus = self.liveStatus
        return bar
    }()
    
    lazy var messageView: ZegoInRoomMessageView = {
        let messageList = ZegoInRoomMessageView()
        return messageList
    }()
    
    lazy var inputTextView: ZegoInRoomMessageInput = {
        let messageInputView = ZegoInRoomMessageInput()
        messageInputView.frame = CGRect(x: 0, y: UIScreen.main.bounds.size.height, width: UIScreen.main.bounds.size.width, height: inputViewHeight)
        return messageInputView
    }()
    
    lazy var startLiveButton: UIButton = {
        let button: UIButton = UIButton()
        button.backgroundColor = UIColor.colorWithHexString("#A754FF")
        button.setTitleColor(UIColor.colorWithHexString("#FFFFFF"), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.setTitle(self.config.translationText.startLiveStreamingButton, for: .normal)
        button.addTarget(self, action: #selector(startLiveClick), for: .touchUpInside)
        return button
    }()
    
    lazy var headIconView: ZegoLiveHostHeaderView = {
        let iconView = ZegoLiveHostHeaderView()
        return iconView
    }()
    
    @objc public init(_ appID: UInt32, appSign: String, userID: String, userName: String, liveID: String, config: ZegoUIKitPrebuiltLiveStreamingConfig) {
        super.init(nibName: nil, bundle: nil)
        ZegoUIKit.shared.initWithAppID(appID: appID, appSign: appSign)
        ZegoUIKitSignalingPluginImpl.shared.initWithAppID(appID: appID, appSign: appSign)
        ZegoUIKitSignalingPluginImpl.shared.login(userID, userName: userName, callback: nil)
        ZegoUIKit.shared.localUserInfo = ZegoUIKitUser.init(userID, userName)
        ZegoUIKit.shared.addEventHandler(self.help)
        self.userID = userID
        self.userName = userName
        self.liveID = liveID
        self.config = config
        if config.role == .host {
            self.currentHost = ZegoUIKitUser.init(userID, userName)
        }
        self.help.liveStreamingVC = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.white
        self.view.addSubview(self.audioVideoContainer.view)
        self.view.addSubview(self.backgroundImageView)
        self.view.addSubview(self.switchCameraButton)
        self.view.addSubview(self.roomTipLabel)
        self.view.addSubview(self.headIconView)
        self.view.addSubview(self.leaveButton)
        self.view.addSubview(self.memberButton)
        self.view.addSubview(self.redDot)
        self.view.addSubview(self.messageView)
        self.view.addSubview(self.bottomBar)
        self.view.addSubview(self.inputTextView)
        self.view.addSubview(self.startLiveButton)
        self.view.addSubview(self.backButton)
        self.memberButton.currentHost = self.currentHost
        self.setupLayout()
        self.setUIDisplayStatus()
        self.joinRoom()
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillChangeFrame(node:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    func setUIDisplayStatus() {
        if self.config.role == .host {
            self.backgroundImageView.isHidden = true
            self.roomTipLabel.isHidden = true
            self.headIconView.host = ZegoUIKit.shared.localUserInfo
            if liveStatus == "1" {
                self.switchCameraButton.isHidden = true
                self.memberButton.isHidden = false
                self.leaveButton.isHidden = false
                self.backButton.isHidden = true
                self.headIconView.isHidden = false
            } else {
                self.switchCameraButton.isHidden = false
                self.memberButton.isHidden = true
                self.leaveButton.isHidden = true
                self.backButton.isHidden = false
                self.headIconView.isHidden = true
            }
        } else {
            self.switchCameraButton.isHidden = true
            self.startLiveButton.isHidden = true
            if self.currentHost == nil {
                self.roomTipLabel.isHidden = false
                self.headIconView.isHidden = true
            } else {
                if liveStatus == "1" {
                    self.roomTipLabel.isHidden = true
                } else {
                    self.roomTipLabel.isHidden = false
                }
                self.headIconView.isHidden = false
            }
            self.memberButton.isHidden = false
            self.leaveButton.isHidden = false
            self.switchCameraButton.isHidden = true
            self.backButton.isHidden = true
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.setupLayout()
    }
    
    @objc public func addButtonToBottomMenuBar(_ button: UIButton, role: ZegoLiveStreamingRole) {
        self.bottomBar.addButtonToMenuBar(button, role: role)
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
                    self.inputTextView.frame = CGRect(x: 0, y: UIScreen.main.bounds.size.height - margin - self.inputViewHeight, width: UIScreen.main.bounds.size.width, height: self.inputViewHeight)
                } else {
                    self.inputTextView.frame = CGRect(x: 0, y: UIScreen.main.bounds.size.height - margin, width: UIScreen.main.bounds.size.width, height: self.inputViewHeight)
                }
                
            }
    }
    
    private func setupLayout() {
        self.audioVideoContainer.view.frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height)
        self.backgroundImageView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height)
        self.roomTipLabel.center = CGPoint(x: self.view.bounds.size.width * 0.5, y: self.view.bounds.size.height * 0.5)
        self.roomTipLabel.bounds = CGRect(x: 0, y: 0, width: 180, height: 50)
        self.headIconView.frame = CGRect(x: 16, y: 53, width: 105, height: 34)
        self.headIconView.layer.masksToBounds = true
        self.headIconView.layer.cornerRadius = 17
        self.backButton.frame = CGRect(x: 4, y: 50, width: 40, height: 40)
        self.switchCameraButton.frame = CGRect(x: self.view.frame.size.width - 52, y: 52, width: 36, height: 36)
        self.leaveButton.frame = CGRect(x: self.view.frame.size.width - 50, y: 57, width: 26, height: 26)
        self.leaveButton.backgroundColor = UIColor.colorWithHexString("#1E2740", alpha: 0.4)
        self.leaveButton.layer.masksToBounds = true
        self.leaveButton.layer.cornerRadius = 13
        self.memberButton.frame = CGRect(x: self.view.frame.size.width - 50 - 60, y: 56, width: 53, height: 28)
        self.memberButton.layer.masksToBounds = true
        self.memberButton.layer.cornerRadius = 14
        self.memberButton.backgroundColor = UIColor.colorWithHexString("#1E2740", alpha: 0.4)
        self.redDot.frame = CGRect(x: self.memberButton.frame.maxX - 8, y: self.memberButton.frame.minY, width: 8, height: 8)
        self.redDot.layer.masksToBounds = true
        self.redDot.layer.cornerRadius = 4
        self.bottomBar.frame = CGRect(x: 0, y: self.view.frame.size.height - 62, width: self.view.frame.size.width, height: 62)
        self.messageView.frame = CGRect(x: 16, y: self.view.frame.size.height - 62 - 200, width: UIkitLiveScreenWidth - 16 - 117, height: 200)
        self.startLiveButton.frame = CGRect(x: (self.view.frame.size.width - 150) / 2, y: self.view.frame.size.height - 44 - 48.5, width: 150, height: 44)
        self.startLiveButton.layer.masksToBounds = true
        self.startLiveButton.layer.cornerRadius = 22
    }
    
    private func joinRoom() {
        guard let liveID = self.liveID,
              let userID = self.userID,
              let userName = self.userName
        else { return }
        ZegoUIKit.shared.joinRoom(userID, userName: userName, roomID: liveID)
        if self.config.turnOnCameraWhenJoining || self.config.turnOnMicrophoneWhenJoining {
            self.requestCameraAndeMicPermission(true)
        }
        ZegoUIKit.shared.turnCameraOn(self.userID ?? "", isOn: self.config.turnOnCameraWhenJoining)
        ZegoUIKit.shared.turnMicrophoneOn(self.userID ?? "", isOn: self.config.turnOnMicrophoneWhenJoining)
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.view.endEditing(true)
    }
    
    public func clearBottomMenuBarExtendButtons(_ role: ZegoLiveStreamingRole) {
        self.bottomBar.clearBottomBarExtendButtons(role)
    }
    
    func updateHostProporty(_ isHost: Bool) {
        self.config.role = .audience
        //update UI
        self.setUIDisplayStatus()
    }
    
    @objc func startLiveClick() {
        //Check the permissions
        if self.isShowCameraPermissionAlter && self.isShowMicPermissionAlter {
            self.setStartLiveStatus()
        } else {
            self.applicationHasMicAndCameraAccess()
        }
    }
    
    @objc func backButtonClick() {
        ZegoUIKit.shared.updateRoomProperties(["live_status": "0", "host": ""]) { data in
            if data?["code"] as! Int == 0 {
                self.dismiss(animated: true)
                self.delegate?.onLeaveLiveStreaming?()
            }
        }
    }
    
    private func setStartLiveStatus() {
        self.liveStatus = "1"
        ZegoUIKit.shared.updateRoomProperties(["host": self.userID ?? "", "live_status": "1"], callback: nil)
        self.startLiveButton.isHidden = true
        self.bottomBar.isHidden = false
        self.setUIDisplayStatus()
    }
    
    func requestCameraAndeMicPermission(_ needDelay: Bool = false) {
        var requestCamerEnd: Bool = false
        var requestMicEnd: Bool = false
        if !ZegoLiveStreamAuthorizedCheck.isCameraAuthorizationDetermined() {
            requestCamerEnd = false
            //not determined
            ZegoLiveStreamAuthorizedCheck.requestCameraAccess {
                //agree
                requestCamerEnd = true
                self.showCameraOrMicAlter(requestCamerEnd, showMic: requestMicEnd, needDelay: false)
            } cancelCompletion: {
                //disagree
                requestCamerEnd = true
                self.showCameraOrMicAlter(requestCamerEnd, showMic: requestMicEnd, needDelay: false)
            }
        } else {
            requestCamerEnd = true
            self.showCameraOrMicAlter(requestCamerEnd, showMic: requestMicEnd, needDelay: needDelay)
        }
        
        if !ZegoLiveStreamAuthorizedCheck.isMicrophoneAuthorizationDetermined() {
            requestMicEnd = false
            //not determined
            ZegoLiveStreamAuthorizedCheck.requestMicphoneAccess {
                //agree
                requestMicEnd = true
                self.showCameraOrMicAlter(requestCamerEnd, showMic: requestMicEnd, needDelay: false)
            } cancelCompletion: {
                //disagree
                requestMicEnd = true
                self.showCameraOrMicAlter(requestCamerEnd, showMic: requestMicEnd, needDelay: false)
            }
        } else {
            requestMicEnd = true
            self.showCameraOrMicAlter(requestCamerEnd, showMic: requestMicEnd, needDelay: needDelay)
        }
    }
    
    func showCameraOrMicAlter(_ showCamera: Bool, showMic: Bool, needDelay: Bool) {
        if needDelay {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.delayExecution(showCamera, showMic: showMic)
            }
        } else {
            self.delayExecution(showCamera, showMic: showMic)
        }
    }
    
    func delayExecution(_ showCamera: Bool, showMic: Bool) {
        if showCamera && showMic {
            if !ZegoLiveStreamAuthorizedCheck.isCameraAuthorized() {
                ZegoLiveStreamAuthorizedCheck.showCameraUnauthorizedAlert(self.config.translationText, viewController: self) {
                    ZegoLiveStreamAuthorizedCheck.openAppSettings()
                    if !ZegoLiveStreamAuthorizedCheck.isMicrophoneAuthorized() {
                        ZegoLiveStreamAuthorizedCheck.showMicrophoneUnauthorizedAlert(self.config.translationText, viewController: self) {
                            ZegoLiveStreamAuthorizedCheck.openAppSettings()
                        } cancelCompletion: {
                            
                        }
                    }
                } cancelCompletion: {
                    if !ZegoLiveStreamAuthorizedCheck.isMicrophoneAuthorized() {
                        ZegoLiveStreamAuthorizedCheck.showMicrophoneUnauthorizedAlert(self.config.translationText, viewController: self) {
                            ZegoLiveStreamAuthorizedCheck.openAppSettings()
                        } cancelCompletion: {
                            
                        }
                    }
                }
            } else {
                if !ZegoLiveStreamAuthorizedCheck.isMicrophoneAuthorized() {
                    ZegoLiveStreamAuthorizedCheck.showMicrophoneUnauthorizedAlert(self.config.translationText, viewController: self) {
                        ZegoLiveStreamAuthorizedCheck.openAppSettings()
                    } cancelCompletion: {
                        
                    }
                }
            }
        }
    }
    
    fileprivate func applicationHasMicAndCameraAccess() {
        // determined but not authorized
        if !ZegoLiveStreamAuthorizedCheck.isCameraAuthorized() {
            self.isShowCameraPermissionAlter = true
            ZegoLiveStreamAuthorizedCheck.showCameraUnauthorizedAlert(self.config.translationText, viewController: self) {
                ZegoLiveStreamAuthorizedCheck.openAppSettings()
                if !ZegoLiveStreamAuthorizedCheck.isMicrophoneAuthorized() {
                    ZegoLiveStreamAuthorizedCheck.showMicrophoneUnauthorizedAlert(self.config.translationText, viewController: self) {
                        ZegoLiveStreamAuthorizedCheck.openAppSettings()
                    } cancelCompletion: {
                        self.setStartLiveStatus()
                    }
                }
            } cancelCompletion: {
                // determined but not authorized
                self.isShowMicPermissionAlter = true
                if !ZegoLiveStreamAuthorizedCheck.isMicrophoneAuthorized() {
                    ZegoLiveStreamAuthorizedCheck.showMicrophoneUnauthorizedAlert(self.config.translationText, viewController: self) {
                        ZegoLiveStreamAuthorizedCheck.openAppSettings()
                    } cancelCompletion: {
                        self.setStartLiveStatus()
                    }
                } else {
                    self.setStartLiveStatus()
                }
            }
        } else {
            self.isShowCameraPermissionAlter = true
            self.isShowMicPermissionAlter = true
            // determined but not authorized
            if !ZegoLiveStreamAuthorizedCheck.isMicrophoneAuthorized() {
                ZegoLiveStreamAuthorizedCheck.showMicrophoneUnauthorizedAlert(self.config.translationText, viewController: self) {
                    ZegoLiveStreamAuthorizedCheck.openAppSettings()
                } cancelCompletion: {
                    self.setStartLiveStatus()
                }
            } else {
                self.setStartLiveStatus()
            }
        }
        
    }
    
    func updateConfigMenuBar(_ role: ZegoLiveStreamingRole) {
        self.config.role = role
        self.bottomBar.config = self.config
//        guard let menuBarButtons = menuBarButtons else {
//            return
//        }
//        var newMenuBarButtons: [ZegoMenuBarButtonName] = []
//        for buttonName in menuBarButtons {
//            let buttonType: ZegoMenuBarButtonName? = ZegoMenuBarButtonName(rawValue: buttonName)
//            if let buttonType = buttonType {
//                newMenuBarButtons.append(buttonType)
//            }
//        }
//        self.config.bottomMenuBarConfig.buttons = newMenuBarButtons
//        self.bottomBar.config = self.config
    }
    
    func addOrRmoveSeatListUser(_ user: ZegoUIKitUser, isAdd: Bool) {
        if isAdd {
            self.audienceSeatList.append(user)
        } else {
            self.audienceSeatList = self.audienceSeatList.filter({
                return $0.userID != user.userID
            })
        }
        self.updateRequestCoHost(user, isAdd: isAdd)
        self.memberButton.requestCoHostList = self.audienceSeatList
    }
    
    func addOrRemoveHostInviteList(_ user: ZegoUIKitUser, isAdd: Bool) {
        if isAdd {
            self.hostInviteList.append(user)
        } else {
            self.hostInviteList = self.hostInviteList.filter({
                return $0.userID != user.userID
            })
        }
        self.memberButton.hostInviteList = self.hostInviteList
    }
    
    func addOrRemoveAudienceInviteList(_ user: ZegoUIKitUser, isAdd: Bool) {
        if isAdd {
            self.audienceInviteList.append(user)
        } else {
            self.audienceInviteList.removeAll()
        }
        self.bottomBar.audienceInviteList = self.audienceInviteList
    }
    
    func addOrRemoveAudienceReceiveInviteList(_ user: ZegoUIKitUser, isAdd: Bool) {
        if isAdd {
            self.audienceReceiveInviteList.append(user)
        } else {
            self.audienceReceiveInviteList.removeAll()
        }
    }
    
    func updateRequestCoHost(_ user: ZegoUIKitUser, isAdd: Bool) {
        if isAdd {
            self.requestCoHostCount = self.requestCoHostCount + 1
        } else {
            self.requestCoHostCount = (self.requestCoHostCount - 1) < 0 ? 0 : self.requestCoHostCount - 1
        }
        self.showRedDot = self.requestCoHostCount > 0
    }
    
    deinit {
        ZegoUIKit.shared.leaveRoom()
        ZegoUIKitSignalingPluginImpl.shared.loginOut()
        ZegoUIKitSignalingPluginImpl.shared.uninit()
        print("ZegoUIKitPrebuiltLiveStreamingVC deinit")
    }
    
}

class ZegoUIKitPrebuiltLiveStreamingVC_Help: NSObject, ZegoAudioVideoContainerDelegate, ZegoUIKitEventHandle, ZegoLiveStreamBottomBarDelegate, LeaveButtonDelegate, ZegoMemberButtonDelegate {
    
    weak var liveStreamingVC: ZegoUIKitPrebuiltLiveStreamingVC?
    var shouldSortHostAtFirst: Bool = true
    weak var invitateAlter: UIAlertController?
    
    //MARK: -ZegoUIKitEventHandle
    func onRoomStateChanged(_ reason: ZegoUIKitRoomStateChangedReason, errorCode: Int32, extendedData: [AnyHashable : Any], roomID: String) {
        guard let liveStreamingVC = liveStreamingVC,
              let userID = liveStreamingVC.userID
        else {
            return
        }
        if reason == .logined {
            if liveStreamingVC.config.role == .host {
                // set room proporty
                liveStreamingVC.liveStatus = "0"
                let roomProperties: [String : String] = ["live_status" : "0", "host" : userID]
                ZegoUIKit.shared.updateRoomProperties(roomProperties, callback: nil)
                liveStreamingVC.bottomBar.isHidden = true
            }
        }
    }
    
    func onAudioVideoAvailable(_ userList: [ZegoUIKitUser]) {
        guard let liveStreamingVC = liveStreamingVC else { return }
        for user in userList {
            var isOldUser: Bool = false
            for oldUser in liveStreamingVC.coHostList {
                if oldUser.userID == user.userID {
                    isOldUser = true
                    break
                }
            }
            if !isOldUser {
                liveStreamingVC.coHostList.append(user)
            }
        }
        if liveStreamingVC.coHostList.count > 0 && liveStreamingVC.liveStatus == "1" {
            liveStreamingVC.backgroundImageView.isHidden = true
        }
        liveStreamingVC.memberButton.coHostList = liveStreamingVC.coHostList
    }
    
    func onAudioVideoUnavailable(_ userList: [ZegoUIKitUser]) {
        guard let liveStreamingVC = liveStreamingVC else { return }
        for user in userList {
            if user.userID == liveStreamingVC.currentHost?.userID {
                shouldSortHostAtFirst = true
            }
            var index: Int = 0
            for coHost in liveStreamingVC.coHostList {
                if coHost.userID == user.userID {
                    liveStreamingVC.coHostList.remove(at: index)
                    break
                }
                index = index + 1
            }
            liveStreamingVC.addOrRmoveSeatListUser(user, isAdd: false)
            liveStreamingVC.addOrRemoveHostInviteList(user, isAdd: false)
        }
        if liveStreamingVC.coHostList.count == 0 && liveStreamingVC.liveStatus != "1" {
            liveStreamingVC.backgroundImageView.isHidden = false
        }
        liveStreamingVC.memberButton.coHostList = liveStreamingVC.coHostList
    }
    
    func onRoomPropertiesFullUpdated(_ updateKeys: [String], oldProperties: [String : String], properties: [String : String]) {
        guard let liveStreamingVC = liveStreamingVC,
              let userID = liveStreamingVC.userID
        else { return }
        if liveStreamingVC.config.role == .host {
//            var thereIsHostInRoom: Bool = false
//            for key in updateKeys {
//                let value: String? = properties[key]
//                if key == "host" && value != nil && value != "" && value != userID {
//                    thereIsHostInRoom = true
//                    break
//                }
//            }
//            if thereIsHostInRoom {
//                liveStreamingVC.updateHostProporty(false)
//            } else {
//                // start live
//
//            }
        } else {
            guard let live_status = properties["live_status"] else { return }
            liveStreamingVC.liveStatus = live_status
            if live_status == "1" {
                self.liveStreamingVC?.roomTipLabel.isHidden = true
            } else {
                self.liveStreamingVC?.roomTipLabel.isHidden = false
                self.liveStreamingVC?.backgroundImageView.isHidden = false
                liveStreamingVC.coHostList.removeAll()
                liveStreamingVC.memberButton.coHostList = liveStreamingVC.memberButton.coHostList
            }
        }
    }
    
    func onRoomPropertyUpdated(_ key: String, oldValue: String, newValue: String) {
        if key == "host" {
            self.liveStreamingVC?.currentHost = ZegoUIKit.shared.getUser(newValue)
            self.liveStreamingVC?.headIconView.host = self.liveStreamingVC?.currentHost
            self.liveStreamingVC?.audioVideoContainer.reload()
        } else if key == "live_status" {
            if newValue == "0" {
                shouldSortHostAtFirst = true
                if oldValue == "1" {
                    ZegoUIKit.shared.turnCameraOn(self.liveStreamingVC?.userID ?? "", isOn: false)
                    ZegoUIKit.shared.turnMicrophoneOn(self.liveStreamingVC?.userID ?? "", isOn: false)
                    self.liveStreamingVC?.bottomBar.isCoHost = false
                    self.liveStreamingVC?.delegate?.onLiveStreamingEnded?()
                    if self.liveStreamingVC?.config.role == .coHost {
                        self.liveStreamingVC?.updateConfigMenuBar(.audience)
                    }
                }
                ZegoUIKit.shared.stopPlayingAllAudioVideo()
            } else if newValue == "1" {
                self.liveStreamingVC?.backgroundImageView.isHidden = true
                ZegoUIKit.shared.startPlayingAllAudioVideo()
            } else {
                ZegoUIKit.shared.stopPlayingAllAudioVideo()
            }
        }
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
    
    func onInvitationReceived(_ inviter: ZegoUIKitUser, type: Int, data: String?) {
        guard let liveStreamingVC = liveStreamingVC else { return }
        if liveStreamingVC.config.role == .host {
            liveStreamingVC.addOrRmoveSeatListUser(inviter, isAdd: true)
        } else {
            let dataDic: Dictionary? = data?.live_convertStringToDictionary()
            let pluginInvitationID: String? = dataDic?["invitationID"] as? String
            guard let userID = inviter.userID else { return }
            if ZegoInvitationType(rawValue: type) == .removeCoHost {
                liveStreamingVC.addOrRemoveAudienceInviteList(inviter, isAdd: false)
                liveStreamingVC.addOrRemoveAudienceReceiveInviteList(inviter, isAdd: false)
                liveStreamingVC.bottomBar.isCoHost = false
                ZegoUIKit.shared.turnCameraOn(liveStreamingVC.userID ?? "", isOn: false)
                ZegoUIKit.shared.turnMicrophoneOn(liveStreamingVC.userID ?? "", isOn: false)
                liveStreamingVC.updateConfigMenuBar(.audience)
            } else if ZegoInvitationType(rawValue: type) == .inviteToCoHost {
                liveStreamingVC.addOrRemoveAudienceReceiveInviteList(inviter, isAdd: true)
                self.showInvitationAltr(userID, invitationID: pluginInvitationID)
            }
        }
    }
    
    func showTipView(_ tipStr: String) {
        ZegoLiveStreamTipView.showTip(tipStr,onView: liveStreamingVC?.view)
    }
    
    func showInvitationAltr(_ inviterID: String, invitationID: String?) {
        guard let liveStreamingVC = liveStreamingVC else {
            return
        }
        let title: String = liveStreamingVC.config.translationText.receivedCoHostInvitationDialogInfo.title ?? ""
        let message: String = liveStreamingVC.config.translationText.receivedCoHostInvitationDialogInfo.message ?? ""
        let cancelStr: String = liveStreamingVC.config.translationText.receivedCoHostInvitationDialogInfo.cancelButtonName
        let sureStr: String = liveStreamingVC.config.translationText.receivedCoHostInvitationDialogInfo.confirmButtonName
        
        let alterView: UIAlertController = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        self.invitateAlter = alterView
        let cancelButton: UIAlertAction = UIAlertAction.init(title: cancelStr, style: .cancel) { action in
            let dataDict: [String : AnyObject] = ["invitationID": invitationID as AnyObject]
            ZegoUIKitSignalingPluginImpl.shared.refuseInvitation(inviterID, data: dataDict.live_jsonString)
            liveStreamingVC.addOrRemoveAudienceReceiveInviteList(ZegoUIKitUser.init(inviterID, ""), isAdd: false)
        }
        
        let sureButton: UIAlertAction = UIAlertAction.init(title: sureStr, style: .default) { action in
            liveStreamingVC.requestCameraAndeMicPermission()
            liveStreamingVC.bottomBar.isCoHost = true
            liveStreamingVC.updateConfigMenuBar(.coHost)
            ZegoUIKit.shared.turnCameraOn(liveStreamingVC.userID ?? "", isOn: true)
            ZegoUIKit.shared.turnMicrophoneOn(liveStreamingVC.userID ?? "", isOn: true)
            ZegoUIKitSignalingPluginImpl.shared.acceptInvitation(inviterID, data: nil)
        }
        alterView.addAction(cancelButton)
        alterView.addAction(sureButton)
        liveStreamingVC.present(alterView, animated: false, completion: nil)
        
    }
    
    func onInvitationAccepted(_ invitee: ZegoUIKitUser, data: String?) {
        guard let liveStreamingVC = liveStreamingVC else { return }
        if liveStreamingVC.config.role != .host {
            // is host accept
            // update bottom bar button
            liveStreamingVC.requestCameraAndeMicPermission()
            liveStreamingVC.bottomBar.isCoHost = true
            liveStreamingVC.updateConfigMenuBar(.coHost)
            ZegoUIKit.shared.turnCameraOn(liveStreamingVC.userID ?? "", isOn: true)
            ZegoUIKit.shared.turnMicrophoneOn(liveStreamingVC.userID ?? "", isOn: true)
        }
    }
    
    func onInvitationCanceled(_ inviter: ZegoUIKitUser, data: String?) {
        guard let liveStreamingVC = liveStreamingVC else {
            return
        }
        if liveStreamingVC.config.role == .host {
            liveStreamingVC.addOrRmoveSeatListUser(inviter, isAdd: false)
        } else {
            self.invitateAlter?.dismiss(animated: false)
            liveStreamingVC.addOrRemoveAudienceReceiveInviteList(inviter, isAdd: false)
        }
    }
    
    func onInvitationRefused(_ invitee: ZegoUIKitUser, data: String?) {
        guard let liveStreamingVC = liveStreamingVC else { return }
        if liveStreamingVC.config.role == .host {
            ZegoLiveStreamTipView.showWarn(String(format: "%@ %@", invitee.userName ?? "",liveStreamingVC.config.translationText.audienceRejectInvitationToast), onView: liveStreamingVC.view)
            liveStreamingVC.addOrRmoveSeatListUser(invitee, isAdd: false)
            liveStreamingVC.addOrRemoveHostInviteList(invitee, isAdd: false)
        } else {
            // update bottom bar button
            liveStreamingVC.addOrRemoveAudienceInviteList(invitee, isAdd: false)
            ZegoLiveStreamTipView.showWarn(liveStreamingVC.config.translationText.hostRejectCoHostRequestToast, onView: liveStreamingVC.view)
            liveStreamingVC.updateConfigMenuBar(.audience)
        }
    }
    
    func onInvitationTimeout(_ inviter: ZegoUIKitUser, data: String?) {
        guard let liveStreamingVC = liveStreamingVC else {
            return
        }
        if liveStreamingVC.config.role == .host {
            liveStreamingVC.addOrRmoveSeatListUser(inviter, isAdd: false)
        } else {
            self.invitateAlter?.dismiss(animated: false)
            liveStreamingVC.addOrRemoveAudienceReceiveInviteList(inviter, isAdd: false)
        }
    }
    
    func onInvitationResponseTimeout(_ invitees: [ZegoUIKitUser], data: String?) {
        guard let liveStreamingVC = liveStreamingVC else {
            return
        }
        if liveStreamingVC.config.role == .host {
            for invitee in invitees {
                liveStreamingVC.addOrRemoveHostInviteList(invitee, isAdd: false)
            }
        } else {
            //update bottom bar button
            for invitee in invitees {
                liveStreamingVC.addOrRemoveAudienceInviteList(invitee, isAdd: false)
            }
            liveStreamingVC.bottomBar.isCoHost = false
            liveStreamingVC.updateConfigMenuBar(.audience)
        }
    }
    
    
    //MARK: -ZegoAudioVideoContainerDelegate
    func getForegroundView(_ userInfo: ZegoUIKitUser?) -> UIView? {
        if let foregroundView = self.liveStreamingVC?.delegate?.getForegroundView?(userInfo) {
            return foregroundView
        } else {
            // user nomal foregroundView
            let nomalForegroundView: ZegoLiveNomalForegroundView = ZegoLiveNomalForegroundView.init(frame: .zero)
            nomalForegroundView.userInfo = userInfo
            return nomalForegroundView
        }
    }
    
    func sortAudioVideo(_ userList: [ZegoUIKitUser]) -> [ZegoUIKitUser]? {
        if shouldSortHostAtFirst && userList.contains(where: {
            return $0.userID == liveStreamingVC?.currentHost?.userID
        }) {
            var tempList = userList
            var index: Int = 0
            for user in tempList {
                if user.userID == self.liveStreamingVC?.currentHost?.userID {
                    let host = user
                    tempList.remove(at: index)
                    tempList.insert(host, at: 0)
                    break
                }
                index = index + 1
            }
            self.shouldSortHostAtFirst = false
            return tempList
        }
        return userList
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
    
    func coHostControlButtonDidClick(_ type: CoHostControlButtonType, sender: ZegoCoHostControlButton) {
        guard let liveStreamingVC = liveStreamingVC
        else {
            return
        }
        switch type {
        case .requestCoHost:
            if liveStreamingVC.liveStatus == "0" {
                ZegoLiveStreamTipView.showWarn(liveStreamingVC.config.translationText.requestCoHostFailed, onView: liveStreamingVC.view)
            } else if liveStreamingVC.liveStatus == "1" {
                guard let host = liveStreamingVC.currentHost else { return }
                ZegoLiveStreamTipView.showTip(liveStreamingVC.config.translationText.sendRequestCoHostToast, onView: liveStreamingVC.view)
                liveStreamingVC.addOrRemoveAudienceInviteList(host, isAdd: true)
                ZegoUIKitSignalingPluginImpl.shared.sendInvitation([host.userID ?? ""], timeout: 60, type: ZegoInvitationType.requestCoHost.rawValue, data: nil) { data in
                    guard let data = data else { return }
                    if data["code"] as! Int != 0 {
                        ZegoLiveStreamTipView.showWarn(liveStreamingVC.config.translationText.requestCoHostFailed, onView: liveStreamingVC.view)
                    } else {
                        sender.buttonType = .cancelCoHost
                    }
                }
            }
        case .cancelCoHost:
            guard let host = liveStreamingVC.currentHost else { return }
            liveStreamingVC.addOrRemoveAudienceInviteList(host, isAdd: false)
            liveStreamingVC.bottomBar.isCoHost = false
            ZegoUIKitSignalingPluginImpl.shared.cancelInvitation([host.userID ?? ""], data: nil, callback: nil)
        case .endCoHost:
            self.showEndConnectionAlter(sender)
        }
    }
    
    func showEndConnectionAlter(_ sender: ZegoCoHostControlButton) {
        guard let liveStreamingVC = liveStreamingVC,
              let host = liveStreamingVC.currentHost,
              let userID = liveStreamingVC.userID
        else {
            return
        }
        let alterView: UIAlertController = UIAlertController.init(title: liveStreamingVC.config.translationText.endConnectionDialogInfo.title, message: liveStreamingVC.config.translationText.endConnectionDialogInfo.message, preferredStyle: .alert)
        self.invitateAlter = alterView
        let cancelButton: UIAlertAction = UIAlertAction.init(title: liveStreamingVC.config.translationText.endConnectionDialogInfo.cancelButtonName, style: .cancel) { action in
        }
        
        let sureButton: UIAlertAction = UIAlertAction.init(title: liveStreamingVC.config.translationText.endConnectionDialogInfo.confirmButtonName, style: .default) { action in
            sender.buttonType = .requestCoHost
            liveStreamingVC.addOrRemoveAudienceInviteList(host, isAdd: false)
            liveStreamingVC.addOrRemoveAudienceReceiveInviteList(host, isAdd: false)
            liveStreamingVC.bottomBar.isCoHost = false
            ZegoUIKit.shared.turnCameraOn(userID, isOn: false)
            ZegoUIKit.shared.turnMicrophoneOn(userID, isOn: false)
            liveStreamingVC.updateConfigMenuBar(.audience)
        }
        alterView.addAction(cancelButton)
        alterView.addAction(sureButton)
        liveStreamingVC.present(alterView, animated: false, completion: nil)
    }
    
    //MARK: - LeaveButtonDelegate ZegoLiveStreamBottomBarDelegate
    func onLeaveButtonClick(_ isLeave: Bool) {
        guard let liveStreamingVC = liveStreamingVC else { return }
        if isLeave {
            if liveStreamingVC.config.role == .host {
                var cancelList: [String] = []
                for user in liveStreamingVC.hostInviteList {
                    cancelList.append(user.userID ?? "")
                    ZegoUIKitSignalingPluginImpl.shared.cancelInvitation(cancelList, data: nil, callback: nil)
                }
            } else {
                ZegoUIKitSignalingPluginImpl.shared.cancelInvitation([liveStreamingVC.currentHost?.userID ?? ""], data: nil, callback: nil)
            }
            
            if liveStreamingVC.config.role == .host  {
                if liveStreamingVC.liveStatus == "1" {
                    self.liveStreamingVC?.delegate?.onLiveStreamingEnded?()
                }
                ZegoUIKit.shared.updateRoomProperties(["live_status": "0", "host": ""]) { data in
                    if data?["code"] as! Int == 0 {
                        
                    }
                }
            }
            self.liveStreamingVC?.dismiss(animated: true)
            self.liveStreamingVC?.delegate?.onLeaveLiveStreaming?()
        }
        
    }
    
    //MARK: -ZegoMemberButtonDelegate
    func memberListDidClickAgree(_ user: ZegoUIKitUser) {
        liveStreamingVC?.updateRequestCoHost(user, isAdd: false)
    }
    
    func memberListDidClickDisagree(_ user: ZegoUIKitUser) {
        self.liveStreamingVC?.addOrRmoveSeatListUser(user, isAdd: false)
    }
    
    func memberListDidClickInvitate(_ user: ZegoUIKitUser) {
        guard let liveStreamingVC = liveStreamingVC else {
            return
        }
        liveStreamingVC.addOrRemoveHostInviteList(user, isAdd: true)
    }
    
    func memberListDidClickRemoveCoHost(_ user: ZegoUIKitUser) {
        
    }
}

