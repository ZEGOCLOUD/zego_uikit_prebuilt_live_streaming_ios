//
//  ZegoLiveStreamingManager.swift
//  Pods
//
//  Created by zego on 2023/9/21.
//

import UIKit
import ZegoUIKit
import ZegoPluginAdapter

public typealias UserRequestCallback = (_ errorCode: Int, _ requestID: String) -> ()


extension ZegoLiveStreamingManager: LiveStreamingManagerApi {
    
    public func addLiveManagerDelegate(_ delegate: ZegoLiveStreamingManagerDelegate) {
        eventDelegates.add(delegate)
    }
    
    public func getHostID() -> String {
        guard let hostID = ZegoUIKit.shared.getRoomProperties()["host"] else { return "" }
        return hostID
    }
    
    public func isHost(_ userID: String) -> Bool {
        return userID == getHostID()
    }
    
    public func isCurrentUserHost() -> Bool {
        let localUser = ZegoUIKit.shared.localUserInfo
        return localUser?.userID == getHostID()
    }
    
    public func isCurrentUserCoHost() -> Bool {
        let localUser = ZegoUIKit.shared.localUserInfo
        return localUser != nil && localUser!.userID != getHostID() && (localUser!.isCameraOn || localUser!.isMicrophoneOn);
    }
    
    public func stopPKBattle() {
        pkService?.sendPKBattlesStopRequest()
    }
    
    public func acceptIncomingPKBattleRequest(_ requestID: String, anotherHostLiveID: String, anotherHostUser: ZegoUIKitUser, customData: String) {
        pkService?.acceptPKStartRequest(requestID: requestID, anotherHostLiveID: anotherHostLiveID, anotherHostUser: anotherHostUser, customData: customData)
    }
    
    public func acceptIncomingPKBattleRequest(_ requestID: String, anotherHostLiveID: String, anotherHostUser: ZegoUIKitUser) {
        pkService?.acceptPKStartRequest(requestID: requestID, anotherHostLiveID: anotherHostLiveID, anotherHostUser: anotherHostUser, customData: nil)
    }
    
    public func rejectPKBattleStartRequest(_ requestID: String) {
        pkService?.rejectPKStartRequest(requestID: requestID, rejectCode: ZegoLiveStreamingPKBattleRejectCode.host_reject.rawValue)
    }
    
    
    public func muteAnotherHostAudio(_ mute: Bool, callback: ZegoUIKitCallBack?) {
        pkService?.muteAnotherHostAudio(mute: mute, callback: callback)
    }
    
    
    public func sendPKBattleRequest(anotherHostUserID: String,
                                    timeout: UInt32 = 60,
                                    customData: String,
                                    callback: UserRequestCallback?) {
        pkService?.sendPKBattlesStartRequest(anotherHostUserID: anotherHostUserID, timeout: timeout, customData: customData, callback: callback)
    }
    
    public func sendPKBattleRequest(anotherHostUserID: String, timeout: UInt32 = 60,callback: UserRequestCallback?) {
        pkService?.sendPKBattlesStartRequest(anotherHostUserID: anotherHostUserID, timeout: timeout, customData: nil, callback: callback)
    }
    
    public func cancelPKBattleRequest(customData: String?, callback: UserRequestCallback?) {
        pkService?.cancelPKBattleRequest(customData: customData, callback: callback)
    }
    
    public func leaveRoom() {
        if currentRole == .host {
            stopPKBattle()
        }
        pkService?.clearData()
        ZegoUIKit.shared.leaveRoom()
        if enableSignalingPlugin {
            ZegoUIKit.getSignalingPlugin().leaveRoom { data in
                //                ZegoUIKit.getSignalingPlugin().loginOut()
                ZegoUIKit.shared.removeEventHandler(self)
            }
        }
    }
    
}

@objcMembers
public class ZegoLiveStreamingManager: NSObject {
    
    public static let shared = ZegoLiveStreamingManager()
    public var pkInfo: PKInfo? {
        get {
            return pkService?.currentPKInfo
        }
    }
    
    public var callID: String? {
        get {
            return pkService?.callID
        }
    }
    
    public var pkState: RoomPKState {
        get {
            return pkService?.roomPKState ?? .isNoPK
        }
    }
    
    public var isAnotherHostMuted: Bool {
        get {
            return pkService?.isMuteAnotherHostAudio ?? false
        }
    }
    
    public var sendPKStartRequest: PKRequest? {
        get {
            return pkService?.sendPKStartRequest
        }
    }
    
    public let eventDelegates: NSHashTable<ZegoLiveStreamingManagerDelegate> = NSHashTable(options: .weakMemory)
    
    var currentRole: ZegoLiveStreamingRole = .audience
    var isLiveStart: Bool {
        get {
            return ZegoUIKit.shared.getRoomProperties()["live_status"] == "1"
        }
    }
    var enableSignalingPlugin: Bool = false
    
    private var pkService: PKService?
    
    public override init() {
        super.init()
        pkService = PKService()
        pkService?.addPKDelegate(self)
    }
    
    func getSignalingPlugin() -> ZegoUIKitSignalingPluginImpl? {
        if enableSignalingPlugin {
            let plugin = ZegoUIKit.getSignalingPlugin().getPlugin(.signaling)
            guard let plugin = plugin else {
                fatalError("signalingPlugin cannot be nil")
            }
            return ZegoUIKit.getSignalingPlugin()
        } else {
            return nil
        }
    }
    
    func initWithAppID(appID: UInt32, appSign: String, enableSignalingPlugin: Bool) {
        ZegoUIKit.shared.addEventHandler(self)
        self.enableSignalingPlugin = enableSignalingPlugin
        ZegoUIKit.shared.initWithAppID(appID: appID, appSign: appSign)
        if enableSignalingPlugin {
            getSignalingPlugin()?.initWithAppID(appID: appID, appSign: appSign)
        }
    }
    
    func login(userID: String, userName: String, callback: PluginCallBack?) {
        if enableSignalingPlugin {
            getSignalingPlugin()?.login(userID, userName: userName, callback: callback)
        } else {
            ZegoUIKit.shared.login(userID, userName: userName)
            guard let callback = callback else { return }
            callback(["code": 0 as AnyObject,
                      "message": "sucess" as AnyObject])
        }
    }
    
    func joinRoom(userID: String, userName: String, roomID: String, markAsLargeRoom: Bool,completion: @escaping(_ errorCode:Int) -> Void) {
        ZegoUIKit.shared.joinRoom(userID, userName: userName, roomID: roomID, markAsLargeRoom: markAsLargeRoom) { data in
        }
        if enableSignalingPlugin {
            getSignalingPlugin()?.joinRoom(roomID: roomID, callback: { data in
                if let code = data?["code"] as? Int {
                    completion(code)
                } else {
                    completion(-1) // 或者您可以选择其他的默认值来表示 data 为空的情况
                }
            })
        } else {
            completion(100)
        }
    }
    
    func stopPKBattleInner() {
        pkService?.stopPK();
    }
    
    
    func startPKBattleWith(anotherHostLiveID: String, anotherHostUserID: String, anotherHostName: String) {
        pkService?.startPKBattleWith(anotherHostLiveID: anotherHostLiveID, anotherHostUserID: anotherHostUserID, anotherHostName: anotherHostName)
    }
    
    public func isPKUser(userID: String) -> Bool {
        return false
    }
    
    //    public func removeRoomData() {
    //        //pkService.removeRoomData()
    //    }
    //
    //    public func removeUserData() {
    //        pkService.removeUserData();
    //        userStatusMap.clear();
    //    }
    
    func generateCameraStreamID(roomID: String, userID: String) -> String {
        return roomID + "_" + userID + "_main"
    }
    
    func startPublishingStream() {
        let currentRoomID = ZegoUIKit.shared.room?.roomID ?? ""
        let streamID = generateCameraStreamID(roomID: currentRoomID, userID: ZegoUIKit.shared.localUserInfo?.userID ?? "")
        ZegoUIKit.shared.startPublishingStream(streamID)
    }
    
    func stopPublishStream() {
        ZegoUIKit.shared.stopPublishingStream()
    }
    
}

extension ZegoLiveStreamingManager: ZegoUIKitEventHandle, PKServiceDelegate {
    
    //MARK: -ZegoUIKitEventHandle
    public func onInvitationReceived(_ inviter: ZegoUIKitUser, type: Int, data: String?) {
        let dataDic: Dictionary? = data?.live_convertStringToDictionary()
        let pluginInvitationID: String = dataDic?["invitationID"] as? String ?? ""
        
        if type == ZegoInvitationType.requestCoHost.rawValue {
            let callID: String = dataDic?["invitationID"] as? String ?? ""
            let reportData = ["call_id": callID as AnyObject,
                              "audience_id": inviter.userID as AnyObject,
                              "action": "apply " as AnyObject,
                              "extended_data": data as AnyObject]
            ReportUtil.sharedInstance().reportEvent(liveStreamHostReceiveApplyReportString, paramsDict: reportData)
            for delgate in eventDelegates.allObjects {
                delgate.onIncomingCohostRequest?(inviter: inviter)
            }
        } else if type == ZegoInvitationType.inviteToCoHost.rawValue {
            for delgate in eventDelegates.allObjects {
                delgate.onIncomingInviteToCohostRequest?(inviter: inviter, invitationID: pluginInvitationID,data: data)
            }
        } else if type == ZegoInvitationType.removeCoHost.rawValue {
            let reportData = ["call_id": pluginInvitationID as AnyObject,
                              "host_id": inviter.userID as AnyObject,
                              "extended_data": data as AnyObject]
            ReportUtil.sharedInstance().reportEvent(liveStreamCo_HostStopReportString, paramsDict: reportData)
            
            for delgate in eventDelegates.allObjects {
                delgate.onIncomingRemoveCohostRequest?(inviter: inviter)
            }
        } else if type == ZegoInvitationType.pk.rawValue {
            pkService?.onPKInvitationReceived(inviter, type: type, data: data)
        }
    }
    
    public func onInvitationAccepted(_ invitee: ZegoUIKitUser, data: String?) {
        let dataDic: Dictionary? = data?.live_convertStringToDictionary()
        let pluginInvitationID: String = dataDic?["invitationID"] as? String ?? ""
        let isPKInvitation = pkService?.isPKInvitation(pluginInvitationID) ?? false
        if isPKInvitation {
            pkService?.onPKInvitationAccepted(invitee, data: data)
        } else {
            for delegate in eventDelegates.allObjects {
                delegate.onIncomingAcceptCohostRequest?(invitee: invitee, data: data)
            }
        }
    }
    
    public func onInvitationRefused(_ invitee: ZegoUIKitUser, data: String?) {
        let dataDic: Dictionary? = data?.live_convertStringToDictionary()
        let pluginInvitationID: String = dataDic?["invitationID"] as? String ?? ""
        let isPKInvitation = pkService?.isPKInvitation(pluginInvitationID) ?? false
        if isPKInvitation {
            pkService?.onPKInvitationRefused(invitee, data: data)
        } else {
            for delegate in eventDelegates.allObjects {
                if currentRole == .host {
                    delegate.onIncomingRefuseCohostInvite?(invitee: invitee, data: data)
                } else {
                    delegate.onIncomingRefuseCohostRequest?(invitee: invitee, data: data)
                }
            }
        }
    }
    
    public func onInvitationCanceled(_ inviter: ZegoUIKitUser, data: String?) {
        let dataDic: Dictionary? = data?.live_convertStringToDictionary()
        let pluginInvitationID: String = dataDic?["invitationID"] as? String ?? ""
        let isPKInvitation = pkService?.isPKInvitation(pluginInvitationID) ?? false
        if isPKInvitation {
            //FIXME: PK取消
            pkService?.onPKInvitationCanceled(inviter, data: data)
        } else {
            for delegate in eventDelegates.allObjects {
                if currentRole == .host {
                    //FIXME: 房主收到观众取消申请
                    delegate.onIncomingCancelCohostRequest?(inviter: inviter, data: data)
                } else {
                    //FIXME: 观众收到房主取消邀请
                    delegate.onIncomingCancelCohostInvite?(inviter: inviter, data: data)
                }
            }
        }
    }
    
    public func onInvitationTimeout(_ inviter: ZegoUIKitUser, data: String?) {
        let dataDic: Dictionary? = data?.live_convertStringToDictionary()
        let pluginInvitationID: String = dataDic?["invitationID"] as? String ?? ""
        let isPKInvitation = pkService?.isPKInvitation(pluginInvitationID) ?? false
        if isPKInvitation {
            pkService?.onPKInvitationTimeout(inviter, data: data)
        } else {
            let reportData = ["call_id": pluginInvitationID as AnyObject,
                              "action": "timeout" as AnyObject]
            ReportUtil.sharedInstance().reportEvent(currentRole == .host ? liveStreamHostResponseReportString : liveStreamAudienceInviteTimeOutReportString, paramsDict: reportData)

            for delegate in eventDelegates.allObjects {
                if currentRole == .host {
                    delegate.onIncomingCohostInviteTimeOut?(inviter: inviter, data: data)
                } else {
                    delegate.onIncomingCohostRequestTimeOut?(inviter: inviter, data: data)
                }
            }
        }
    }
    
    public func onInvitationResponseTimeout(_ invitees: [ZegoUIKitUser], data: String?) {
        let dataDic: Dictionary? = data?.live_convertStringToDictionary()
        let pluginInvitationID: String = dataDic?["invitationID"] as? String ?? ""
        let isPKInvitation = pkService?.isPKInvitation(pluginInvitationID) ?? false
        if isPKInvitation {
            pkService?.onPKInvitationResponseTimeout(invitees, data: data)
        } else {
            
            let reportData = ["call_id": pluginInvitationID as AnyObject,
                              "action": "timeout" as AnyObject]
            ReportUtil.sharedInstance().reportEvent(currentRole == .host ? liveStreamHostResponseReportString : liveStreamAudienceInviteTimeOutReportString, paramsDict: reportData)
            for delegate in eventDelegates.allObjects {
                if currentRole == .host {
                    delegate.onIncomingCohostInviteResponseTimeOut?(invitees: invitees, data: data)
                } else {
                    //FIXME: 观众自己的申请无响应超时
                    delegate.onIncomingCohostRequestResponseTimeOut?(invitees: invitees, data: data)
                }
            }
        }
    }
    
    
    //MARK: -PKServiceDelegate
    func onPKStarted(roomID: String, userID: String) {
        for delegate in eventDelegates.allObjects {
            delegate.onPKStarted?(roomID: roomID, userID: userID)
        }
    }
    
    func onPKEnded() {
        for delegate in eventDelegates.allObjects {
            delegate.onPKEnded?()
        }
    }
    
    func onPKViewAvaliable() {
        for delegate in eventDelegates.allObjects {
            delegate.onPKViewAvaliable?()
        }
    }
    
    func onMixerStreamTaskFail(errorCode: Int) {
        for delegate in eventDelegates.allObjects {
            delegate.onMixerStreamTaskFail?(errorCode: errorCode)
        }
    }
    
    func onIncomingPKRequestReceived(requestID: String, anotherHostUser: ZegoUIKitUser, anotherHostLiveID: String, customData: String?) {
        for delegate in eventDelegates.allObjects {
            delegate.onIncomingPKRequestReceived?(requestID: requestID, anotherHostUser: anotherHostUser, anotherHostLiveID: anotherHostLiveID, customData: customData)
        }
    }
    
    func onIncomingResumePKRequestReceived(requestID: String) {
        for delegate in eventDelegates.allObjects {
            delegate.onIncomingResumePKRequestReceived?(requestID: requestID)
        }
    }
    
    func onIncomingPKBattleRequestCanceled(anotherHostLiveID: String, anotherHostUser: ZegoUIKitUser, customData: String?) {
        for delegate in eventDelegates.allObjects {
            delegate.onIncomingPKRequestCancelled?(anotherHostLiveID: anotherHostLiveID, anotherHostUser: anotherHostUser, customData: customData)
        }
    }
    
    func onIncomingPKBattleRequestTimeout(requestID: String, anotherHostUser: ZegoUIKitUser) {
        for delegate in eventDelegates.allObjects {
            delegate.onIncomingPKRequestTimeout?(requestID: requestID, anotherHostUser: anotherHostUser)
        }
    }
    
    func onOutgoingPKBattleRequestRejected(reason: Int, anotherHostUser: ZegoUIKitUser) {
        for delegate in eventDelegates.allObjects {
            delegate.onOutgoingPKRequestRejected?(reason: reason, anotherHostUser: anotherHostUser)
        }
    }
    
    func onOutgoingPKBattleRequestAccepted(anotherHostLiveID: String, anotherHostUser: ZegoUIKitUser, customData: String?) {
        for delegate in eventDelegates.allObjects {
            delegate.onOutgoingPKRequestAccepted?(anotherHostLiveID: anotherHostLiveID, anotherHostUser: anotherHostUser, customData: customData)
        }
    }
    
    func onOutgoingPKBattleRequestTimeout(requestID: String, anotherHost: ZegoUIKitUser) {
        for delegate in eventDelegates.allObjects {
            delegate.onOutgoingPKRequestTimeout?(requestID: requestID, anotherHost: anotherHost)
        }
    }
    
    func onOtherHostMuted(userID: String, mute: Bool) {
        for delegate in eventDelegates.allObjects {
            delegate.onOtherHostMuted?(userID: userID, mute: mute)
        }
    }
    
    func onAnotherHostCameraStatus(isOn: Bool) {
        for delegate in eventDelegates.allObjects {
            delegate.onAnotherHostCameraStatus?(isOn: isOn)
        }
    }
    
    func onLocalHostCameraStatus(isOn: Bool) {
        for delegate in eventDelegates.allObjects {
            delegate.onLocalHostCameraStatus?(isOn: isOn)
        }
    }
    
    func onHostIsConnected() {
        for delegate in eventDelegates.allObjects {
            delegate.onHostIsConnected?()
        }
    }
    
    func onHostIsReconnecting() {
        for delegate in eventDelegates.allObjects {
            delegate.onHostIsReconnecting?()
        }
    }
    
    func onAnotherHostIsConnected() {
        for delegate in eventDelegates.allObjects {
            delegate.onAnotherHostIsConnected?()
        }
    }
    
    func onAnotherHostIsReconnecting() {
        for delegate in eventDelegates.allObjects {
            delegate.onAnotherHostIsReconnecting?()
        }
    }
    
}
