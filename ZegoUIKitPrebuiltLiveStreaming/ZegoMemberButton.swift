//
//  ZegoMemberButton.swift
//  ZegoUIKit
//
//  Created by zego on 2022/8/25.
//

import UIKit
import ZegoUIKit

protocol ZegoMemberButtonDelegate: AnyObject {
    func memberListDidClickAgree(_ user: ZegoUIKitUser)
    func memberListDidClickDisagree(_ user: ZegoUIKitUser)
    func memberListDidClickInvitate(_ user: ZegoUIKitUser)
    func memberListDidClickRemoveCoHost(_ user: ZegoUIKitUser)
}

public class ZegoMemberButton: UIButton {
    
    weak var delegate: ZegoMemberButtonDelegate?
    weak var controller: UIViewController?
    var requestCoHostList: [ZegoUIKitUser]? {
        didSet {
            self.memberListView?.requestCoHostList = requestCoHostList
        }
    }
    var hostInviteList: [ZegoUIKitUser]?
    var memberListView: ZegoLiveStreamMemberList?
    var currentHost: ZegoUIKitUser? {
        didSet {
            self.memberListView?.currentHost = currentHost
        }
    }
    var coHostList: [ZegoUIKitUser] = [] {
        didSet {
            self.memberListView?.coHostList = coHostList
        }
    }
    var config: ZegoUIKitPrebuiltLiveStreamingConfig?
    
    private let help: ZegoMemberButton_Help = ZegoMemberButton_Help()
    

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.help.memberButton = self
        ZegoUIKit.shared.addEventHandler(self.help)
        self.addTarget(self, action: #selector(buttonClick), for: .touchUpInside)
        self.setImage(ZegoUIKitLiveStreamIconSetType.top_people.load(), for: .normal) //按钮图标
        self.titleLabel?.font = UIFont.systemFont(ofSize: 12)//文字大小
        self.setTitleColor(UIColor.colorWithHexString("#FFFFFF"), for: .normal)//文字颜色
        self.titleEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 0)
        let number: Int = ZegoUIKit.shared.getAllUsers().count
        self.setTitle(String(format: "%d", number), for: .normal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    @objc func buttonClick() {
        guard let controller = controller else {
            return
        }
        let listView: ZegoLiveStreamMemberList = ZegoLiveStreamMemberList()
        self.memberListView = listView
        listView.config = self.config
        listView.translationText = self.config?.translationText
        listView.coHostList = self.coHostList
        listView.requestCoHostList = self.requestCoHostList
        listView.currentHost = self.currentHost
        listView.frame = CGRect(x: 0, y: 0, width: controller.view.bounds.size.width, height: controller.view.bounds.size.height)
        listView.delegate = self.help
        controller.view.addSubview(listView)
    }

}

class ZegoMemberButton_Help: NSObject, ZegoUIKitEventHandle, ZegoLiveStreamMemberListDelegate, ZegoLiveSheetViewDelegate {
    
    weak var memberButton: ZegoMemberButton?
    
    func memberListDidClickAgree(_ user: ZegoUIKitUser) {
        self.memberButton?.delegate?.memberListDidClickAgree(user)
        self.memberButton?.requestCoHostList = self.memberButton?.requestCoHostList?.filter{
            return $0.userID != user.userID
        }
    }
    
    func memberListDidClickDisagree(_ user: ZegoUIKitUser) {
        self.memberButton?.delegate?.memberListDidClickDisagree(user)
        self.memberButton?.requestCoHostList = self.memberButton?.requestCoHostList?.filter{
            return $0.userID != user.userID
        }
    }
    
    var sheetListData: [String] {
        get {
            if self.isCoHost {
                return [self.memberButton?.config?.translationText.removeCoHostButton ?? "",self.memberButton?.config?.translationText.cancelMenuDialogButton ?? ""]
            } else {
                if let inviteCoHostButton = self.memberButton?.config?.translationText.inviteCoHostButton,
                   let currentUser = currentUser,
                   let currentUserName = currentUser.userName
                {
                    let newInviteCoHostButton = inviteCoHostButton.replacingOccurrences(of: "%@", with: currentUserName)
                    let removeUserInfo = self.memberButton?.config?.translationText.removeUserMenuDialogButton.replacingOccurrences(of: "%@", with: currentUserName) ?? ""
                    if ZegoLiveStreamingManager.shared.pkState == .isStartPK {
                        return [removeUserInfo,self.memberButton?.config?.translationText.cancelMenuDialogButton ?? ""]
                    } else {
                        return [newInviteCoHostButton,removeUserInfo,self.memberButton?.config?.translationText.cancelMenuDialogButton ?? ""]
                    }
                } else {
                    if ZegoLiveStreamingManager.shared.pkState == .isStartPK {
                        return [self.memberButton?.config?.translationText.removeUserMenuDialogButton ?? "",self.memberButton?.config?.translationText.cancelMenuDialogButton ?? ""]
                    } else {
                        return [self.memberButton?.config?.translationText.inviteCoHostButton ?? "",self.memberButton?.config?.translationText.removeUserMenuDialogButton ?? "",self.memberButton?.config?.translationText.cancelMenuDialogButton ?? ""]
                    }
                    
                }
            }
        }
    }
    var currentUser: ZegoUIKitUser?
    
    var isCoHost: Bool {
        get {
            guard let currentUser = currentUser,
                  let memberButton = memberButton
            else { return false }
            for user in memberButton.coHostList {
                if currentUser.userID == user.userID {
                    return true
                }
            }
            return false
        }
    }
    
    func onRemoteUserJoin(_ userList: [ZegoUIKitUser]) {
        let number: Int = ZegoUIKit.shared.getAllUsers().count
        self.memberButton?.setTitle(String(format: "%d", number), for: .normal)
    }
    
    func onRemoteUserLeave(_ userList: [ZegoUIKitUser]) {
        let number: Int = ZegoUIKit.shared.getAllUsers().count
        self.memberButton?.setTitle(String(format: "%d", number), for: .normal)
    }
    
    //MARK: -ZegoUIKitEventHandle
    func onRoomStateChanged(_ reason: ZegoUIKitRoomStateChangedReason, errorCode: Int32, extendedData: [AnyHashable : Any], roomID: String) {
        if reason == .logined {
            let number: Int = ZegoUIKit.shared.getAllUsers().count
            self.memberButton?.setTitle(String(format: "%d", number), for: .normal)
        }
    }
    
    func memberListDidClickMoreButton(_ user: ZegoUIKitUser) {
        self.currentUser = user
        guard let memberButton = memberButton,
              let controller = memberButton.controller
        else {
            return
        }
        let sheetList = ZegoLiveSheetView()
        sheetList.dataSource = self.sheetListData
        sheetList.frame = CGRect(x: 0, y: 0, width: controller.view.bounds.size.width, height: controller.view.bounds.size.height)
        sheetList.delegate = self
        controller.view.addSubview(sheetList)
    }
    
    //MARK: -ZegoLiveSheetViewDelegate
    func didSelectRowForIndex(_ index: Int) {
        guard let currentUser = currentUser,
              let userID = currentUser.userID,
              let memberButton = self.memberButton
        else {
            return
        }
        if index == 0 {
            //start invite user
            if ZegoLiveStreamingManager.shared.pkState == .isStartPK {
                if isCoHost {
                    self.currentUser = nil
                } else {
                    ZegoUIKit.shared.removeUserFromRoom([userID])
                }
            } else {
                if isCoHost {
                    ZegoUIKitSignalingPluginImpl.shared.sendInvitation([userID], timeout: 60, type: ZegoInvitationType.removeCoHost.rawValue, data: nil, notificationConfig: nil) { data in
                        guard let data = data else { return }
                        if data["code"] as! Int == 0 {
                           
                        } else {
                            
                        }
                    }
                    memberButton.delegate?.memberListDidClickRemoveCoHost(currentUser)
                } else {
                    if let hostInviteList = self.memberButton?.hostInviteList {
                        if hostInviteList.contains(where: {
                            return $0.userID == userID
                        }) {
                            ZegoLiveStreamTipView.showWarn(memberButton.config?.translationText.repeatInviteCoHostFailedToast ?? "", onView: memberButton.controller?.view)
                            return
                        }
                    }
                    
                    ZegoUIKitSignalingPluginImpl.shared.sendInvitation([userID], timeout: 60, type: ZegoInvitationType.inviteToCoHost.rawValue, data: nil, notificationConfig: nil) { data in
                        guard let data = data else { return }
                        if data["code"] as! Int == 0 {
                            memberButton.delegate?.memberListDidClickInvitate(currentUser)
                        } else {
                            ZegoLiveStreamTipView.showWarn(memberButton.config?.translationText.inviteCoHostFailedToast ?? "", onView: self.memberButton?.controller?.view)
                        }
                    }
                }
            }
        } else if index == 1 {
            if ZegoLiveStreamingManager.shared.pkState == .isStartPK {
                self.currentUser = nil
            } else {
                if isCoHost {
                    self.currentUser = nil
                } else {
                    ZegoUIKit.shared.removeUserFromRoom([userID])
                }
            }
        } else {
            self.currentUser = nil
        }
    }
    
}
