//
//  ZegoLiveStreamBottomBar.swift
//  ZegoUIKit
//
//  Created by zego on 2022/8/26.
//

import UIKit
import ZegoUIKit

protocol ZegoLiveStreamBottomBarDelegate: AnyObject {
    func onMenuBarMoreButtonClick(_ buttonList: [UIView])
    func onInRoomMessageButtonClick()
    func onLeaveButtonClick(_ isLeave: Bool)
    func coHostControlButtonDidClick(_ type: CoHostControlButtonType, sender: ZegoCoHostControlButton)
}

extension ZegoLiveStreamBottomBarDelegate {
    func onMenuBarMoreButtonClick(_ buttonList: [UIView]) { }
    func onInRoomMessageButtonClick() { }
    func onLeaveButtonClick(_ isLeave: Bool){ }
    func coHostControlButtonDidClick(_ type: CoHostControlButtonType, sender: ZegoCoHostControlButton) { }
}

class ZegoLiveStreamBottomBar: UIView {

    var userID: String?
    var position: ZegoBottomMenuBarPosition = .left
    var config: ZegoUIKitPrebuiltLiveStreamingConfig = ZegoUIKitPrebuiltLiveStreamingConfig.audience() {
        didSet {
            self.messageButton.isHidden = !config.bottomMenuBarConfig.showInRoomMessageButton
            if config.role == .host {
                self.barButtons = config.bottomMenuBarConfig.hostButtons
            } else if config.role == .coHost {
                if config.enableCoHosting {
                    self.barButtons = config.bottomMenuBarConfig.coHostButtons
                } else {
                    self.barButtons = config.bottomMenuBarConfig.coHostButtons.filter({$0 != .coHostControlButton})
                }
            } else {
                if config.enableCoHosting {
                    self.barButtons = config.bottomMenuBarConfig.audienceButtons
                } else {
                    self.barButtons = config.bottomMenuBarConfig.audienceButtons.filter({$0 != .coHostControlButton})
                }
            }
        }
    }
    weak var delegate: ZegoLiveStreamBottomBarDelegate?
    
    var audienceInviteList: [ZegoUIKitUser]? {
        didSet {
            for button in self.buttons {
                if button is ZegoCoHostControlButton {
                    let coHostControlButton = button as! ZegoCoHostControlButton
                    coHostControlButton.requestList = audienceInviteList
                }
            }
        }
    }
    
    var liveStatus: String = "0" {
        didSet {
            for button in self.buttons {
                if button is ZegoCoHostControlButton {
                    let coHostControlButton = button as! ZegoCoHostControlButton
                    coHostControlButton.liveStatus = liveStatus
                }
            }
        }
    }
    
    var hostID: String? {
        didSet {
            for button in self.buttons {
                if button is ZegoCoHostControlButton {
                    let newButton = button as! ZegoCoHostControlButton
                    newButton.hostID = hostID
                }
            }
            self.messageButton.hostID = hostID
        }
    }
    
    var isCoHost: Bool = false {
        didSet {
            for button in self.buttons {
                if button is ZegoCoHostControlButton {
                    let coHostControlButton = button as! ZegoCoHostControlButton
                    coHostControlButton.buttonType = self.isCoHost ? .endCoHost : .requestCoHost
                }
            }
        }
    }
    
    
    weak var showQuitDialogVC: UIViewController?
    
    private var buttons: [UIView] = []
    private var moreButtonList: [UIView] = []
    private var hostExtendButtons: [UIButton] = []
    private var coHostExtendButtons: [UIButton] = []
    private var audienceExtendButtons: [UIButton] = []
    
    var barButtons:[ZegoMenuBarButtonName] = [] {
        didSet {
            self.removeAllButton()
            self.moreButtonList.removeAll()
            self.createButton()
            self.setupLayout()
        }
    }
    private let margin: CGFloat = UIkitLiveAdaptLandscapeWidth(16)
    private let itemSpace: CGFloat = UIkitLiveAdaptLandscapeWidth(8)
    
    private lazy var messageButton: ZegoInRoomMessageButton = {
        let button = ZegoInRoomMessageButton()
        button.delegate = self
        return button
    }()
    
    let itemSize: CGSize = CGSize.init(width: UIkitLiveAdaptLandscapeWidth(36), height: UIkitLiveAdaptLandscapeWidth(36))
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.addSubview(self.messageButton)
        self.createButton()
        self.setupLayout()
        ZegoLiveStreamingManager.shared.addLiveManagerDelegate(self)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.setupLayout()
    }
    
    /// - Parameter button: <#button description#>
    public func addButtonToMenuBar(_ button: UIButton, role: ZegoLiveStreamingRole, position:ZegoBottomMenuBarPosition = .left) {
        if role == .host {
          if position == .left {
            self.hostExtendButtons.append(button)
          } else {
            self.hostExtendButtons.insert(button, at: 0)
          }
        } else if role == .coHost {
          if position == .left {
            self.coHostExtendButtons.append(button)
          } else {
            self.coHostExtendButtons.insert(button, at: 0)
            self.position = position
          }
        } else if role == .audience {
          if position == .left {
            self.audienceExtendButtons.append(button)
          } else {
            self.audienceExtendButtons.insert(button, at: 0)
          }
        }
        if role == self.config.role {
            if self.buttons.count > self.config.bottomMenuBarConfig.maxCount - 1 {
                if self.buttons.first is ZegoMoreButton {
                    self.moreButtonList.append(button)
                    return
                }
                //替换最后一个元素
                let moreButton: ZegoMoreButton = ZegoMoreButton()
                moreButton.addTarget(self, action: #selector(moreClick), for: .touchUpInside)
                self.addSubview(moreButton)
                let lastButton: UIButton = self.buttons.last as! UIButton
                lastButton.removeFromSuperview()
                self.moreButtonList.append(lastButton)
                self.moreButtonList.append(button)
                self.buttons.removeLast()
                self.buttons.insert(moreButton, at: 0)
    //            self.buttons.replaceSubrange(4...4, with: [moreButton])
            } else {
                if position == .left {
                  self.buttons.append(button)
                } else {
                  self.buttons.insert(button, at: 0)
                }
                self.addSubview(button)
            }
            self.setupLayout()
        }
    }
    
    func clearBottomBarExtendButtons(_ role: ZegoLiveStreamingRole) {
        switch role {
        case .host:
            self.hostExtendButtons.removeAll()
        case .coHost:
            self.coHostExtendButtons.removeAll()
        case .audience:
            self.audienceExtendButtons.removeAll()
        }
    }
    
    
    //MARK: -private
    private func setupLayout() {
        self.messageButton.frame = CGRect(x: self.margin, y: UIkitLiveAdaptLandscapeHeight(10), width: itemSize.width, height: itemSize.height)
        switch self.buttons.count {
        case 1:
            self.layoutViewWithButton()
        case 2:
            self.layoutViewWithButton()
            break
        case 3:
            self.layoutViewWithButton()
            break
        case 4:
            self.layoutViewWithButton()
            break
        case 5:
            self.layoutViewWithButton()
        default:
            break
        }
    }
    
    private func replayAddAllView() {
        for view in self.subviews {
            view.removeFromSuperview()
        }
        for item in self.buttons {
            self.addSubview(item)
        }
    }
    
    private func removeAllButton() {
        for button in self.buttons {
            button.removeFromSuperview()
        }
    }
    
    private func layoutViewWithButton() {
        var index: Int = 0
        var lastView: UIView?
        for button in self.buttons {
            if index == 0 {
                if button is ZegoCoHostControlButton {
                    let coHostButton = button as! ZegoCoHostControlButton
                    if coHostButton.buttonType == .requestCoHost {
                        coHostButton.frame = CGRect.init(x: self.frame.size.width - self.margin - 165, y: UIkitLiveAdaptLandscapeHeight(10), width: 165, height: itemSize.height)
                    } else if coHostButton.buttonType == .cancelCoHost {
                        coHostButton.frame = CGRect.init(x: self.frame.size.width - self.margin - 210, y: UIkitLiveAdaptLandscapeHeight(10), width: 210, height: itemSize.height)
                    } else if coHostButton.buttonType == .endCoHost {
                        coHostButton.frame = CGRect.init(x: self.frame.size.width - self.margin - 84, y: UIkitLiveAdaptLandscapeHeight(10), width: 84, height: itemSize.height)
                    }
                    coHostButton.layer.masksToBounds = true
                    coHostButton.layer.cornerRadius = 18
                } else {
                    let width = button.bounds.size.width > 0 ? button.bounds.size.width : itemSize.width
                    button.frame = CGRect.init(x: self.frame.size.width - self.margin - width, y: UIkitLiveAdaptLandscapeHeight(10), width: width, height: itemSize.height)
                }
            } else {
                if let lastView = lastView {
                    if button is ZegoCoHostControlButton {
                        let coHostButton = button as! ZegoCoHostControlButton
                        switch coHostButton.buttonType {
                        case .requestCoHost:
                            button.frame = CGRect.init(x: lastView.frame.minX - itemSpace - 165, y: lastView.frame.minY, width: 165, height: itemSize.height)
                        case .cancelCoHost:
                            button.frame = CGRect.init(x: lastView.frame.minX - itemSpace - 210, y: lastView.frame.minY, width: 210, height: itemSize.height)
                        case .endCoHost:
                            button.frame = CGRect.init(x: lastView.frame.minX - itemSpace - 84, y: lastView.frame.minY, width: 84, height: itemSize.height)
                        }
                        coHostButton.layer.masksToBounds = true
                        coHostButton.layer.cornerRadius = 18
                    } else {
                        let width = button.bounds.size.width > 0 ? button.bounds.size.width : itemSize.width
                        button.frame = CGRect.init(x: lastView.frame.minX - itemSpace - width, y: lastView.frame.minY, width: width, height: itemSize.height)
                    }
                }
            }
            lastView = button
            index = index + 1
        }
    }
    
    
    private func createButton() {
        self.buttons.removeAll()
        var index = 0
        for item in self.barButtons {
            index = index + 1
            if self.config.bottomMenuBarConfig.maxCount < self.barButtons.count && index == self.config.bottomMenuBarConfig.maxCount {
                //显示更多按钮
                let moreButton: ZegoMoreButton = ZegoMoreButton()
                moreButton.addTarget(self, action: #selector(moreClick), for: .touchUpInside)
                self.buttons.insert(moreButton, at: 0)
                self.addSubview(moreButton)
            }
            switch item {
            case .switchCameraButton:
                let flipCameraComponent: ZegoSwitchCameraButton = ZegoSwitchCameraButton()
                if self.config.bottomMenuBarConfig.maxCount < self.barButtons.count && index >= self.config.bottomMenuBarConfig.maxCount {
                    self.moreButtonList.append(flipCameraComponent)
                } else {
                    self.buttons.append(flipCameraComponent)
                    self.addSubview(flipCameraComponent)
                }
            case .toggleCameraButton:
                let switchCameraComponent: ZegoToggleCameraButton = ZegoToggleCameraButton()
                switchCameraComponent.isOn = self.config.turnOnCameraWhenJoining
                switchCameraComponent.userID = userID
                if self.config.bottomMenuBarConfig.maxCount < self.barButtons.count && index >= self.config.bottomMenuBarConfig.maxCount {
                    self.moreButtonList.append(switchCameraComponent)
                } else {
                    self.buttons.append(switchCameraComponent)
                    self.addSubview(switchCameraComponent)
                }
            case .toggleMicrophoneButton:
                let micButtonComponent: ZegoToggleMicrophoneButton = ZegoToggleMicrophoneButton()
                micButtonComponent.userID = userID
                micButtonComponent.isOn = self.config.turnOnMicrophoneWhenJoining
                if self.config.bottomMenuBarConfig.maxCount < self.barButtons.count && index >= self.config.bottomMenuBarConfig.maxCount {
                    self.moreButtonList.append(micButtonComponent)
                } else {
                    self.buttons.append(micButtonComponent)
                    self.addSubview(micButtonComponent)
                }
            case .switchAudioOutputButton:
                let audioOutputButtonComponent: ZegoSwitchAudioOutputButton = ZegoSwitchAudioOutputButton()
                audioOutputButtonComponent.useSpeaker = self.config.useSpeakerWhenJoining
                if self.config.bottomMenuBarConfig.maxCount < self.barButtons.count && index >= self.config.bottomMenuBarConfig.maxCount {
                    self.moreButtonList.append(audioOutputButtonComponent)
                } else {
                    self.buttons.append(audioOutputButtonComponent)
                    self.addSubview(audioOutputButtonComponent)
                }
            case .leaveButton:
                let leaveButtonComponent: ZegoLeaveButton = ZegoLeaveButton()
                leaveButtonComponent.delegate = self
                leaveButtonComponent.quitConfirmDialogInfo = self.config.confirmDialogInfo ?? ZegoLeaveConfirmDialogInfo()
                leaveButtonComponent.iconLeave = ZegoUIKitLiveStreamIconSetType.top_close.load()
                if self.config.bottomMenuBarConfig.maxCount < self.barButtons.count && index >= self.config.bottomMenuBarConfig.maxCount {
                    self.moreButtonList.append(leaveButtonComponent)
                } else {
                    self.buttons.append(leaveButtonComponent)
                    self.addSubview(leaveButtonComponent)
                }
            case .coHostControlButton:
                let coHostButton: ZegoCoHostControlButton = ZegoCoHostControlButton(frame: CGRectZero, translationText: self.config.translationText)
                coHostButton.config = self.config
                coHostButton.delegate = self
                coHostButton.liveStatus = self.liveStatus
                coHostButton.buttonType = self.isCoHost ? .endCoHost : .requestCoHost
                coHostButton.hostID = self.hostID
                coHostButton.requestList = self.audienceInviteList
                if self.config.bottomMenuBarConfig.maxCount < self.barButtons.count && index >= self.config.bottomMenuBarConfig.maxCount {
                    self.moreButtonList.append(coHostButton)
                } else {
                    self.buttons.append(coHostButton)
                    self.addSubview(coHostButton)
                }
            case .enableChatButton:
                let enableChatButton: ZegoEnableChatButton = ZegoEnableChatButton()
                if self.config.bottomMenuBarConfig.maxCount < self.barButtons.count && index >= self.config.bottomMenuBarConfig.maxCount {
                    self.moreButtonList.append(enableChatButton)
                } else {
                    self.buttons.append(enableChatButton)
                    self.addSubview(enableChatButton)
                }
            }
        }
        self.createExtendButton()
    }
    
    private func createExtendButton() {
        var extendButtons: [UIButton] = []
        switch self.config.role {
        case .host:
            extendButtons = self.hostExtendButtons
        case .coHost:
            extendButtons = self.coHostExtendButtons
        case .audience:
            extendButtons = self.audienceExtendButtons
        }
        var index = 0
        for button in extendButtons {
            index = index + 1
            if self.config.bottomMenuBarConfig.maxCount < (self.barButtons.count + extendButtons.count) && index == (Int(self.config.bottomMenuBarConfig.maxCount) - self.barButtons.count) {
                //显示更多按钮
                let moreButton: ZegoMoreButton = ZegoMoreButton()
                moreButton.addTarget(self, action: #selector(moreClick), for: .touchUpInside)
                self.buttons.insert(moreButton, at: 0)
                self.addSubview(moreButton)
            }
            if self.config.bottomMenuBarConfig.maxCount < (self.barButtons.count + extendButtons.count) && index >= (Int(self.config.bottomMenuBarConfig.maxCount) - self.barButtons.count) {
                self.moreButtonList.append(button)
            } else {
              if self.position == .right && self.config.role == .coHost {
                  self.buttons.insert(button, at: 0)
                } else {
                  self.buttons.append(button)
                }
                self.addSubview(button)
            }
        }
    }
    
    @objc func moreClick() {
        //更多按钮点击事件
        self.delegate?.onMenuBarMoreButtonClick(self.moreButtonList)
    }

}

class ZegoMoreButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setImage(ZegoUIKitLiveStreamIconSetType.icon_more.load(), for: .normal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ZegoLiveStreamBottomBar: ZegoInRoomMessageButtonDelegate, LeaveButtonDelegate, ZegoCoHostControlButtonDelegate, ZegoLiveStreamingManagerDelegate {
    func inRoomMessageButtonDidClick() {
        self.delegate?.onInRoomMessageButtonClick()
    }
    
    func onLeaveButtonClick(_ isLeave: Bool) {
        if isLeave {
            self.showQuitDialogVC?.dismiss(animated: true, completion: nil)
        }
        self.delegate?.onLeaveButtonClick(isLeave)
    }
    
    func coHostControlButtonDidClick(_ type: CoHostControlButtonType, sender: ZegoCoHostControlButton) {
        self.delegate?.coHostControlButtonDidClick(type, sender: sender)
    }
    
    func coHostButtonTypeDidChange() {
        self.setupLayout()
    }
    
    func onPKStarted(roomID: String, userID: String) {
        for button in buttons {
            if button is ZegoCoHostControlButton {
                button.isHidden = true
            }
            if button is ZegoToggleMicrophoneButton {
                let micButton: ZegoToggleMicrophoneButton = button as! ZegoToggleMicrophoneButton
                micButton.muteMode = true
            }
        }
    }
    
    func onPKEnded() {
        for button in buttons {
            if button is ZegoCoHostControlButton {
                button.isHidden = false
                break
            }
            if button is ZegoToggleMicrophoneButton {
                let micButton: ZegoToggleMicrophoneButton = button as! ZegoToggleMicrophoneButton
                micButton.muteMode = false
            }
        }
    }
}
