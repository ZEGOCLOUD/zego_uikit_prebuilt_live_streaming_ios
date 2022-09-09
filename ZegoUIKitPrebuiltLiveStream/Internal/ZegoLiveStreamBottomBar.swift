//
//  ZegoLiveStreamBottomBar.swift
//  ZegoUIKit
//
//  Created by zego on 2022/8/26.
//

import UIKit
import ZegoUIKitSDK

public protocol ZegoLiveStreamBottomBarDelegate: AnyObject {
    func onMenuBarMoreButtonClick(_ buttonList: [UIView])
    func onInRoomMessageButtonClick()
}

public class ZegoLiveStreamBottomBar: UIView {

    public var userID: String?
    public var config: ZegoUIKitPrebuiltLiveStreamingConfig = ZegoUIKitPrebuiltLiveStreamingConfig(0) {
        didSet {
            self.messageButton.isHidden = !config.showInRoomMessageButton
            self.barButtons = config.menuBarButtons
        }
    }
    public weak var delegate: ZegoLiveStreamBottomBarDelegate?
    
    
    weak var showQuitDialogVC: UIViewController?
    
    private let help = ZegoLiveStreamBottomBar_Help()
    
    private var buttons: [UIView] = []
    private var moreButtonList: [UIView] = []
    private var barButtons:[ZegoMenuBarButtonName] = [] {
        didSet {
            self.createButton()
            self.setupLayout()
        }
    }
    private let margin: CGFloat = UIkitLiveAdaptLandscapeWidth(16)
    private let itemSpace: CGFloat = UIkitLiveAdaptLandscapeWidth(8)
    
    private lazy var messageButton: ZegoInRoomMessageButton = {
        let button = ZegoInRoomMessageButton()
        button.delegate = self.help as? ZegoInRoomMessageButtonDelegate
        button.layer.masksToBounds = true
        button.layer.cornerRadius = itemSize.width * 0.5
        return button
    }()
    
    let itemSize: CGSize = CGSize.init(width: UIkitLiveAdaptLandscapeWidth(36), height: UIkitLiveAdaptLandscapeWidth(36))
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.help.streamBottomBar = self
        self.backgroundColor = UIColor.clear
        self.addSubview(self.messageButton)
        self.createButton()
        self.setupLayout()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.setupLayout()
    }
    
    /// 添加自定义按钮
    /// - Parameter button: <#button description#>
    public func addButtonToMenuBar(_ button: UIButton) {
        if self.buttons.count > self.config.menuBarButtonsMaxCount - 1 {
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
            self.buttons.insert(moreButton, at: 0)
//            self.buttons.replaceSubrange(4...4, with: [moreButton])
        } else {
            self.buttons.append(button)
            self.addSubview(button)
        }
        self.setupLayout()
    }
    
    
    //MARK: -private
    private func setupLayout() {
        self.messageButton.frame = CGRect(x: self.margin, y: UIkitLiveAdaptLandscapeHeight(10), width: itemSize.width, height: itemSize.height)
        switch self.buttons.count {
        case 1:
            break
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
    
    private func layoutViewWithButton() {
        var index: Int = 0
        var lastView: UIView?
        for button in self.buttons {
            if index == 0 {
                button.frame = CGRect.init(x: self.frame.size.width - self.margin - itemSize.width, y: UIkitLiveAdaptLandscapeHeight(10), width: itemSize.width, height: itemSize.height)
            } else {
                if let lastView = lastView {
                    button.frame = CGRect.init(x: lastView.frame.minX - itemSpace - itemSize.width, y: lastView.frame.minY, width: itemSize.width, height: itemSize.height)
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
            if self.config.menuBarButtonsMaxCount < self.barButtons.count && index == self.config.menuBarButtonsMaxCount {
                //显示更多按钮
                let moreButton: ZegoMoreButton = ZegoMoreButton()
                moreButton.addTarget(self, action: #selector(moreClick), for: .touchUpInside)
                self.buttons.insert(moreButton, at: 0)
                self.addSubview(moreButton)
            }
            switch item {
            case .switchCameraButton:
                let flipCameraComponent: ZegoSwitchCameraButton = ZegoSwitchCameraButton()
                if self.config.menuBarButtonsMaxCount < self.barButtons.count && index >= self.config.menuBarButtonsMaxCount {
                    self.moreButtonList.append(flipCameraComponent)
                } else {
                    self.buttons.append(flipCameraComponent)
                    self.addSubview(flipCameraComponent)
                }
            case .toggleCameraButton:
                let switchCameraComponent: ZegoToggleCameraButton = ZegoToggleCameraButton()
                switchCameraComponent.isOn = self.config.turnOnCameraWhenJoining
                switchCameraComponent.userID = ZegoUIKit.shared.localUserInfo?.userID
                if self.config.menuBarButtonsMaxCount < self.barButtons.count && index >= self.config.menuBarButtonsMaxCount {
                    self.moreButtonList.append(switchCameraComponent)
                } else {
                    self.buttons.append(switchCameraComponent)
                    self.addSubview(switchCameraComponent)
                }
            case .toggleMicrophoneButton:
                let micButtonComponent: ZegoToggleMicrophoneButton = ZegoToggleMicrophoneButton()
                micButtonComponent.userID = ZegoUIKit.shared.localUserInfo?.userID
                micButtonComponent.isOn = self.config.turnOnMicrophoneWhenJoining
                if self.config.menuBarButtonsMaxCount < self.barButtons.count && index >= self.config.menuBarButtonsMaxCount {
                    self.moreButtonList.append(micButtonComponent)
                } else {
                    self.buttons.append(micButtonComponent)
                    self.addSubview(micButtonComponent)
                }
            case .swtichAudioOutputButton:
                let audioOutputButtonComponent: ZegoSwitchAudioOutputButton = ZegoSwitchAudioOutputButton()
                audioOutputButtonComponent.useSpeaker = self.config.useSpeakerWhenJoining
                if self.config.menuBarButtonsMaxCount < self.barButtons.count && index >= self.config.menuBarButtonsMaxCount {
                    self.moreButtonList.append(audioOutputButtonComponent)
                } else {
                    self.buttons.append(audioOutputButtonComponent)
                    self.addSubview(audioOutputButtonComponent)
                }
            case .leaveButton:
                let leaveButtonComponent: ZegoLeaveButton = ZegoLeaveButton()
//                endButtonComponent.quitConfirmDialogInfo = self.config.hangUpConfirmDialogInfo ?? ZegoLeaveConfirmDialogInfo()
//                endButtonComponent.delegate = self
                leaveButtonComponent.iconLeave = ZegoUIKitLiveStreamIconSetType.top_close.load()
                if self.config.menuBarButtonsMaxCount < self.barButtons.count && index >= self.config.menuBarButtonsMaxCount {
                    self.moreButtonList.append(leaveButtonComponent)
                } else {
                    self.buttons.append(leaveButtonComponent)
                    self.addSubview(leaveButtonComponent)
                }
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

class ZegoLiveStreamBottomBar_Help: NSObject, ZegoInRoomMessageButtonDelegate {
    
    fileprivate weak var streamBottomBar: ZegoLiveStreamBottomBar?
    
    func inRoomMessageButtonDidClick() {
        self.streamBottomBar?.delegate?.onInRoomMessageButtonClick()
    }
}
