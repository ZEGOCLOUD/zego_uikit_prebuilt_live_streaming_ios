//
//  PKService.swift
//  ZegoUIKitPrebuiltLiveStreaming
//
//  Created by zego on 2023/9/21.
//

import UIKit
import ZegoExpressEngine
import ZegoUIKit

@objc protocol PKServiceDelegate: AnyObject {
    
    @objc optional func onIncomingPKRequestReceived(requestID: String,
                                                    anotherHostUser: ZegoUIKitUser,
                                                    anotherHostLiveID: String,
                                                    customData: String?)
    @objc optional func onIncomingResumePKRequestReceived(requestID: String)
    @objc optional func onIncomingPKBattleRequestCanceled(anotherHostLiveID: String, anotherHostUser: ZegoUIKitUser, customData: String?)
    @objc optional func onOutgoingPKBattleRequestAccepted(anotherHostLiveID: String, anotherHostUser: ZegoUIKitUser, customData: String?)
    @objc optional func onOutgoingPKBattleRequestRejected(reason: Int, anotherHostUser: ZegoUIKitUser)
    @objc optional func onIncomingPKBattleRequestTimeout(requestID: String, anotherHostUser: ZegoUIKitUser)
    @objc optional func onOutgoingPKBattleRequestTimeout(requestID: String, anotherHost: ZegoUIKitUser)
    
    @objc optional func onPKStarted(roomID: String, userID: String)
    @objc optional func onPKEnded()
    @objc optional func onPKViewAvaliable()
    
    @objc optional func onLocalHostCameraStatus(isOn: Bool)
    @objc optional func onAnotherHostCameraStatus(isOn: Bool)
    
    @objc optional func onAnotherHostIsReconnecting()
    @objc optional func onAnotherHostIsConnected()
    @objc optional func onHostIsReconnecting()
    @objc optional func onHostIsConnected()
    
    @objc optional func onMixerStreamTaskFail(errorCode: Int)
    @objc optional func onStartPlayMixerStream()
    @objc optional func onStopPlayMixerStream()
    @objc optional func onOtherHostMuted(userID: String, mute: Bool)
}

class PKService: NSObject {
    
    var isMuteAnotherHostAudio = false
    var sendPKStartRequest: PKRequest?
    var receivePkRequest: PKRequest?
    var pkInvitations: [String] = []
    let eventDelegates: NSHashTable<PKServiceDelegate> = NSHashTable(options: .weakMemory)
    
    var localUser: ZegoUIKitUser? {
        get {
            return ZegoUIKit.shared.localUserInfo
        }
    }
    var currentPKInfo: PKInfo?
    var roomPKState: RoomPKState = .isNoPK
    
    private var currentMixerTask: ZegoMixerTask?
    private var pkRoomAttribute: [String: String] = [:]
    private var seiTimer: Timer?
    private var checkSEITimer: Timer?
    private var seiDict: [String: Any] = [:]
    
    override init() {
        super.init()
        ZegoUIKit.shared.addEventHandler(self)
    }
    
    
    func addPKDelegate(_ delegate: PKServiceDelegate) {
        eventDelegates.add(delegate)
    }
    
    func isPKInvitation(_ invitationID: String) -> Bool {
        return pkInvitations.contains(invitationID)
    }
    
    private func getPKExtendedData(type: UInt, customData: String?) -> String {
        let currentRoomID: String = ZegoUIKit.shared.room?.roomID ?? ""
        let data = PKExtendedData()
        data.roomID = currentRoomID
        data.userName = localUser?.userName ?? ""
        data.type = type
        data.customData = customData
        return data.toJsonString();
    }
    
    func sendPKBattlesStartRequest(anotherHostUserID: String,
                                   timeout: UInt32,
                                   customData: String?,
                                   callback: UserRequestCallback?) {
        let pkExtendedData = getPKExtendedData(type: PKProtocolType.startPK.rawValue, customData: customData)
        roomPKState = .isRequestPK
        sendUserRequest(userID: anotherHostUserID, timeout: timeout, extendedData: pkExtendedData) { data in
            let code = data?["code"] as! Int
            let invitationID = data?["callID"] as? String ?? ""
            if code == 0 {
                self.sendPKStartRequest = PKRequest(requestID: invitationID, anotherUserID: anotherHostUserID)
            } else {
                self.roomPKState = .isNoPK
            }
            guard let callback = callback else { return }
            callback(code,invitationID)
        }
    }
    
    func sendPKBattlesResumeRequest(userID: String) {
        let pkExtendedData = getPKExtendedData(type: PKProtocolType.resume.rawValue, customData: nil)
        roomPKState = .isRequestPK
        sendUserRequest(userID: userID, timeout: 60, extendedData: pkExtendedData) { data in
            let code = data?["code"] as! Int
            let invitationID = data?["callID"] as? String ?? ""
            if code == 0 {
                self.sendPKStartRequest = PKRequest(requestID: invitationID, anotherUserID: userID)
            } else {
                self.roomPKState = .isNoPK
            }
        }
    }
    
    func sendPKBattlesStopRequest() {
        if roomPKState != .isStartPK { return }
        let pkExtendedData: PKExtendedData = PKExtendedData()
        pkExtendedData.roomID = ZegoUIKit.shared.room?.roomID ?? ""
        pkExtendedData.userName = ZegoUIKit.shared.localUserInfo?.userName ?? ""
        pkExtendedData.type = PKProtocolType.endPK.rawValue
        sendUserRequest(userID: currentPKInfo?.pkUser.userID ?? "", timeout: 60, extendedData: pkExtendedData.toJsonString(), callback: nil)
        delectPKAttributes()
        for delegate in eventDelegates.allObjects {
            ZegoUIKit.shared.stopPlayStream(currentPKInfo?.getPKStreamID() ?? "")
            delegate.onPKEnded?()
        }
    }
    
    func cancelPKBattleRequest(customData: String?, callback: UserRequestCallback?) {
        guard let sendPKStartRequest = sendPKStartRequest else { return }
        roomPKState = .isNoPK
        let pkExtendedData = getPKExtendedData(type: PKProtocolType.startPK.rawValue, customData: customData)
        let requestID = sendPKStartRequest.requestID
        cancelUserRequest(requestID: requestID, extendedData: pkExtendedData) { data in
            let code = data?["code"] as! Int
            guard let callback = callback else { return }
            callback(code,requestID)
        }
        self.sendPKStartRequest = nil
    }
    
    func acceptPKStartRequest(requestID: String,
                              anotherHostLiveID: String,
                              anotherHostUser: ZegoUIKitUser,
                              customData: String?) {
        if let receivePkRequest = receivePkRequest,
           requestID == receivePkRequest.requestID
        {
            self.receivePkRequest = nil
        }
        let pkExtendedData = getPKExtendedData(type: PKProtocolType.startPK.rawValue, customData: customData)
        acceptUserRequest(requestID: requestID, inviterID: anotherHostUser.userID ?? "", extendedData: pkExtendedData) { data in
            if let data = data,
               let code = data["code"] as? Int {
                if code == 0 {
                    self.startPKBattleWith(anotherHostLiveID: anotherHostLiveID, anotherHostUserID: anotherHostUser.userID ?? "", anotherHostName: anotherHostUser.userName ?? "")
                }
            }
        }
    }
    
    func acceptPKResumeRequest(requestID: String, anotherHostUser: ZegoUIKitUser) {
        let pkExtendedData = getPKExtendedData(type: PKProtocolType.resume.rawValue, customData: nil)
        acceptUserRequest(requestID: requestID, inviterID: anotherHostUser.userID ?? "", extendedData: pkExtendedData, callback: nil)
    }
    
    func acceptPKStopRequest(requestID: String, anotherHostUser: ZegoUIKitUser) {
//        currentPkRequest = nil
        let pkExtendedData = getPKExtendedData(type: PKProtocolType.endPK.rawValue, customData: nil)
        acceptUserRequest(requestID: requestID, inviterID: anotherHostUser.userID ?? "", extendedData: pkExtendedData, callback: nil)
    }
    
    func rejectPKStartRequest(requestID: String, rejectCode: Int) {
        let pkExtendedData = getPKExtendedData(type: PKProtocolType.startPK.rawValue, customData: nil)
        var jsonObject: [String: AnyObject] = pkExtendedData.live_convertStringToDictionary() ?? [:]
        jsonObject["reason"] = rejectCode as AnyObject
        rejectUserRequest(requestID: requestID, extendedData: jsonObject.live_jsonString) { data in
            
        }
        if receivePkRequest?.requestID == requestID {
            receivePkRequest = nil
        }
//        currentPkRequest = nil
    }
    
    func rejectPKResumeRequest(requestID: String) {
        let pkExtendedData = getPKExtendedData(type: PKProtocolType.resume.rawValue, customData: nil)
        rejectUserRequest(requestID: requestID, extendedData: pkExtendedData, callback: nil)
//        currentPkRequest = nil
    }
    
    func startPKBattleWith(anotherHostLiveID: String, anotherHostUserID: String, anotherHostName: String) {
        currentPKInfo = PKInfo(user: ZegoUIKitUser(anotherHostUserID, anotherHostName), pkRoom: anotherHostLiveID)
        currentPKInfo!.seq = currentPKInfo!.seq + 1
        startPK()
    }
}

extension PKService: ZegoUIKitEventHandle {
    
    private func sendUserRequest(userID: String, timeout: UInt32, extendedData: String, callback: PluginCallBack?) {
        ZegoLiveStreamingManager.shared.getSignalingPlugin()?.sendInvitation([userID], timeout: timeout, type: ZegoInvitationType.pk.rawValue, data: extendedData, notificationConfig: nil) { data in
            let invitationID: String = data?["callID"] as? String ?? ""
            self.pkInvitations.append(invitationID)
            guard let callback = callback else { return }
            callback(data)
        }
    }
    
    private func acceptUserRequest(requestID: String, inviterID: String, extendedData: String, callback: PluginCallBack?) {
        var jsonObject: [String: AnyObject] = extendedData.live_convertStringToDictionary() ?? [:]
        jsonObject["invitationID"] = requestID as AnyObject
        ZegoLiveStreamingManager.shared.getSignalingPlugin()?.acceptInvitation(inviterID, data: jsonObject.live_jsonString, callback: callback)
    }

    private func rejectUserRequest(requestID: String, extendedData: String, callback: PluginCallBack?) {
        var jsonObject: [String: AnyObject] = extendedData.live_convertStringToDictionary() ?? [:]
        jsonObject["invitationID"] = requestID as AnyObject
        ZegoLiveStreamingManager.shared.getSignalingPlugin()?.refuseInvitation("", data: jsonObject.live_jsonString)
    }
    
    private func cancelUserRequest(requestID: String, extendedData: String, callback: PluginCallBack?) {
        var jsonObject: [String: AnyObject] = extendedData.live_convertStringToDictionary() ?? [:]
        jsonObject["invitationID"] = requestID as AnyObject
        ZegoLiveStreamingManager.shared.getSignalingPlugin()?.cancelInvitation([sendPKStartRequest?.anotherUserID ?? ""], data: jsonObject.live_jsonString, callback: callback)
    }
    
    func startPK() {
        roomPKState = .isStartPK
        if ZegoLiveStreamingManager.shared.currentRole == .host {
            if let localUser = localUser,
               !localUser.isMicrophoneOn
            {
                ZegoUIKit.shared.turnMicrophoneOn(localUser.userID ?? "", isOn: false, mute: true)
                ZegoUIKit.shared.turnCameraOn(localUser.userID ?? "", isOn: localUser.isCameraOn)
            }
            startMixStreamTask(leftContentType: .video, rightContentType: .video) { data in
                let code = data?["code"] as! Int
                if code == 0 {
                    //set room attribute
                    self.pkRoomAttribute["host"] = self.localUser?.userID ?? ""
                    self.pkRoomAttribute["pk_room"] = self.currentPKInfo?.pkRoom ?? ""
                    self.pkRoomAttribute["pk_user_id"] = self.currentPKInfo?.pkUser.userID ?? ""
                    self.pkRoomAttribute["pk_user_name"] = self.currentPKInfo?.pkUser.userName ?? ""
                    self.pkRoomAttribute["pk_seq"] = "\(self.currentPKInfo?.seq ?? 0)"
                    ZegoLiveStreamingManager.shared.getSignalingPlugin()?.updateRoomProperty(self.pkRoomAttribute, callback: nil)
                    self.createSEITimer()
                    for delegate in self.eventDelegates.allObjects {
                        delegate.onPKStarted?(roomID: self.currentPKInfo?.pkRoom ?? "", userID: self.currentPKInfo?.pkUser.userID ?? "")
                    }
                } else {
                    for delegate in self.eventDelegates.allObjects {
                        delegate.onMixerStreamTaskFail?(errorCode: code)
                    }
                }
            }
        } else {
            for delegate in self.eventDelegates.allObjects {
                delegate.onPKStarted?(roomID: self.currentPKInfo?.pkRoom ?? "", userID: self.currentPKInfo?.pkUser.userID ?? "")
            }
        }
        createCheckSERTimer()
    }
    
    func stopPK() {
        if let currentMixerTask = currentMixerTask {
            ZegoUIKit.shared.stopMixerTask(currentMixerTask) { data in
                let code = data?["code"] as! Int
                if code == 0 {
                    self.currentMixerTask = nil
                }
            }
        }
        delectPKAttributes()
        stopPKAction()
    }
    
    func stopPKAction() {
        guard let _ = currentPKInfo else { return }
        roomPKState = .isNoPK
        ZegoUIKit.shared.stopPlayStream(currentPKInfo?.getPKStreamID() ?? "")
        ZegoUIKit.shared.stopPlayStream(currentPKInfo?.getMixerStreamID() ?? "")
        clearData()
        for delegate in eventDelegates.allObjects {
            delegate.onPKEnded?()
        }
    }
    
    private func startMixStreamTask(leftContentType: ZegoMixerInputContentType, rightContentType: ZegoMixerInputContentType, callback: ZegoUIKitCallBack?) {
        guard let currentRoomID = ZegoUIKit.shared.room?.roomID,
              let localUserID = localUser?.userID,
              let pkInfo = currentPKInfo
        else { return }
        //play another host stream
        let mixerStreamID = currentRoomID + "_mix"
        let localStreamID = ZegoLiveStreamingManager.shared.generateCameraStreamID(roomID: currentRoomID, userID: localUserID)
        let task = ZegoMixerTask(taskID: mixerStreamID)
        let videoConfig = ZegoMixerVideoConfig()
        videoConfig.resolution = CGSize(width: 540 * 2, height: 960)
        videoConfig.bitrate = 1200
        task.setVideoConfig(videoConfig)
        task.setAudioConfig(ZegoMixerAudioConfig.default())
        task.enableSoundLevel(true)
        
        let firstRect = CGRect(x: 0, y: 0, width: 540, height: 960)
        let firstInput = ZegoMixerInput(streamID: localStreamID, contentType: leftContentType, layout: firstRect)
        firstInput.renderMode = .fill
        firstInput.soundLevelID = 0
        firstInput.volume = 100
        
        let secondRect = CGRect(x: 540, y: 0, width: 540, height: 960)
        let secondInput = ZegoMixerInput(streamID: pkInfo.getPKStreamID(), contentType: rightContentType, layout: secondRect)
        secondInput.soundLevelID = 1
        secondInput.volume = 100
        secondInput.renderMode = .fill
        
        task.setInputList([firstInput,secondInput])
        task.setOutputList([ZegoMixerOutput(target: mixerStreamID)])
        
        currentMixerTask = task
        
        ZegoUIKit.shared.startMixerTask(task, callback: callback)
    
    }
    
    private func delectPKAttributes() {
        if pkRoomAttribute.keys.isEmpty { return }
        ZegoLiveStreamingManager.shared.getSignalingPlugin()?.deleteRoomProperties(Array(pkRoomAttribute.keys), callBack: nil)
    }

    
    func muteAnotherHostAudio(mute: Bool, isReConnecting: Bool = false, callback: ZegoUIKitCallBack?) {
        guard let pkInfo = currentPKInfo else {
            if let callback = callback {
                callback(["code" : -9999 as AnyObject])
            }
            return
        }
        ZegoUIKit.shared.mutePlayStreamAudio(streamID: pkInfo.getPKStreamID(), mute: mute)
        if mute == isMuteAnotherHostAudio {
            if let callback = callback {
                callback(["code" : -9999 as AnyObject])
            }
            return
        }
        startMixStreamTask(leftContentType: .video, rightContentType: mute ? .videoOnly : .video) { data in
            let code = data?["code"] as! Int
            if code == 0 {
                ZegoUIKit.shared.mutePlayStreamAudio(streamID: pkInfo.getPKStreamID(), mute: mute)
                if !isReConnecting {
                    self.isMuteAnotherHostAudio = mute
                }
                for delegate in self.eventDelegates.allObjects {
                    delegate.onOtherHostMuted?(userID: pkInfo.pkUser.userID ?? "", mute: mute)
                }
            }
            guard let callback = callback else { return }
            callback(["code" : code as AnyObject])
        }
    }
    
    private func createSEITimer() {
        seiTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { timer in
            var dict: [String : AnyObject] = [:]
            dict["type"] = SEIType.deviceState.rawValue as AnyObject
            dict["sender_id"] = self.localUser?.userID as AnyObject
            dict["mic"] = self.localUser?.isMicrophoneOn as AnyObject
            dict["cam"] = self.localUser?.isCameraOn as AnyObject
            ZegoUIKit.shared.sendSEI(dict.live_jsonString)
        })
    }
    
    private func createCheckSERTimer() {
        checkSEITimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { timer in
            let currentTimer = Int(Date().timeIntervalSince1970)
            var isFindAnotherHostKey: Bool = false
            self.seiDict.forEach { (key, value) in
                
                let cameraStatus: Bool = (value as! Dictionary<String, Any>)["cam"] as! Bool
                if key == self.currentPKInfo?.pkUser.userID {
                    isFindAnotherHostKey = true
                    for delegate in self.eventDelegates.allObjects {
                        delegate.onAnotherHostCameraStatus?(isOn: cameraStatus)
                    }
                } else {
                    for delegate in self.eventDelegates.allObjects {
                        delegate.onLocalHostCameraStatus?(isOn: cameraStatus)
                    }
                }
                
                let lastTime = (value as! Dictionary<String, Any>)["time"] as! Int
                if currentTimer - lastTime >= 5 {
                    if key == self.currentPKInfo?.pkUser.userID {
                        for delegate in self.eventDelegates.allObjects {
                            delegate.onAnotherHostIsReconnecting?()
                            self.muteAnotherHostAudio(mute: true, isReConnecting: true, callback: nil)
                        }
                    } else {
                        for delegate in self.eventDelegates.allObjects {
                            delegate.onHostIsReconnecting?()
                        }
                    }
                } else {
                    if key == self.currentPKInfo?.pkUser.userID {
                        for delegate in self.eventDelegates.allObjects {
                            delegate.onAnotherHostIsConnected?()
                            self.muteAnotherHostAudio(mute: self.isMuteAnotherHostAudio, callback: nil)
                        }
                    } else {
                        for delegate in self.eventDelegates.allObjects {
                            delegate.onHostIsConnected?()
                        }
                    }
                }
            }
            if !isFindAnotherHostKey {
                for delegate in self.eventDelegates.allObjects {
                    delegate.onAnotherHostIsReconnecting?()
                    self.muteAnotherHostAudio(mute: true, isReConnecting: true, callback: nil)
                }
            }
        })
    }
    
    func destoryTimer() {
        seiTimer?.invalidate()
        seiTimer = nil
        checkSEITimer?.invalidate()
        checkSEITimer = nil
    }
    
    func clearData() {
        destoryTimer()
        seiDict.removeAll()
        pkRoomAttribute.removeAll()
        currentPKInfo = nil
        roomPKState = .isNoPK
        sendPKStartRequest = nil
        receivePkRequest = nil
        isMuteAnotherHostAudio = false
    }
    
    func onRoomMemberLeft(_ userIDList: [String]?, roomID: String) {
        
    }
    
    func onPlayerRecvAudioFirstFrame(_ streamID: String) {
        if streamID.contains("_mix") {
            muteMainStream()
            for delegate in eventDelegates.allObjects {
                delegate.onPKViewAvaliable?()
            }
        }
    }
    
    func onPlayerRecvVideoFirstFrame(_ streamID: String) {
        if streamID.contains("_mix") {
            muteMainStream()
            for delegate in eventDelegates.allObjects {
                delegate.onPKViewAvaliable?()
            }
        }
    }
    
    func muteMainStream() {
        ZegoUIKit.shared.streamList.forEach { streamID in
            if streamID.hasPrefix("_main") {
                ZegoUIKit.shared.mutePlayStreamAudio(streamID: streamID, mute: true)
                ZegoUIKit.shared.mutePlayStreamVideo(streamID: streamID, mute: true)
            }
        }
    }
    
    func onPlayerRecvSEI(_ seiString: String, streamID: String) {
        var seiData = seiString.live_convertStringToDictionary()
        seiData?["time"] = Int(Date().timeIntervalSince1970) as AnyObject
        let key = seiData?["sender_id"] as? String ?? ""
        seiDict.updateValue(seiData ?? [:], forKey: key)
    }
    
    func onRoomPropertyUpdated(_ key: String, oldValue: String, newValue: String) {
        if key == "host" {
            let hostID = ZegoLiveStreamingManager.shared.getHostID()
            if !hostID.isEmpty {
                if !pkRoomAttribute.keys.isEmpty {
                    let pkUserID = pkRoomAttribute["pk_user_id"]
                    if let pkUserID = pkUserID,
                       !pkUserID.isEmpty
                    {
                        onReceivePKRoomAttribute(pkRoomAttribute)
                    }
                }
            }
        }
    }
    
    
    func onSignalPluginRoomPropertyFullUpdated(_ updateKeys: [String], oldProperties: [String : String], properties: [String : String]) {
        var setProperties: [String: String] = [:]
        var delectProperties: [String: String] = [:]
        updateKeys.forEach { key in
            let value: String = properties[key] ?? ""
            if value.isEmpty {
                delectProperties[key] = ""
            } else {
                setProperties[key] = value
            }
        }
        onRoomAttributesUpdated([setProperties], deleteProperties: [delectProperties])
    }
    
    func onRoomAttributesUpdated(_ setProperties: [[String: String]], deleteProperties: [[String: String]]) {
        deleteProperties.forEach { deleteProperty in
            deleteProperty.forEach { (key, value) in
                pkRoomAttribute.updateValue("", forKey: key)
            }
            if deleteProperty.keys.contains("pk_user_id") {
                guard let _ = currentPKInfo else { return }
                stopPKAction()
            }
        }
        setProperties.forEach { setProperty in
            setProperty.forEach { (key, value) in
                pkRoomAttribute.updateValue(value, forKey: key)
            }
            if setProperty.keys.contains("pk_user_id") {
                onReceivePKRoomAttribute(setProperty)
            }
        }
    }
    
    private func onReceivePKRoomAttribute(_ roomProperties: [String: String]) {
        let pk_user_id: String = roomProperties["pk_user_id"] ?? ""
        let pk_user_name: String = roomProperties["pk_user_name"] ?? ""
        let pk_room: String = roomProperties["pk_room"] ?? ""
        let pk_seq: String = roomProperties["pk_seq"] ?? ""
        let host: String = roomProperties["host"] ?? ""

        let pkInfo: PKInfo = PKInfo(user: ZegoUIKitUser(pk_user_id, pk_user_name), pkRoom: pk_room)
        pkInfo.hostUserID = host
        pkInfo.seq = Int(pk_seq) ?? 0

        if (ZegoLiveStreamingManager.shared.currentRole == .host) {
            // receive attribute but no pkInfo, resume PK
            if (currentPKInfo == nil) {
                if (!ZegoLiveStreamingManager.shared.getHostID().isEmpty) {
                    sendPKBattlesResumeRequest(userID: pk_user_id)
                }
            }
        } else {
            if (currentPKInfo == nil) {
                // normal，audience receive Host PK action
                if (!ZegoLiveStreamingManager.shared.getHostID().isEmpty) {
                    currentPKInfo = pkInfo
                    startPK()
                }
            }
        }
    }
    
    func onPKInvitationReceived(_ inviter: ZegoUIKitUser, type: Int, data: String?) {
        guard let extendedData = data?.live_convertStringToDictionary() else { return }
        guard let pkData = PKExtendedData.parse(data ?? "") else { return }
        let invitationID = extendedData["invitationID"] as? String
        guard let invitationID = invitationID else { return }
        pkInvitations.append(invitationID)
        let pkType: PKProtocolType? = PKProtocolType(rawValue: pkData.type)
        if type != ZegoInvitationType.pk.rawValue {
            return
        }
        let userNotHost: Bool =
        (ZegoUIKit.shared.room?.roomID == nil) || (ZegoLiveStreamingManager.shared.currentRole != .host)
        let alreadySend: Bool = sendPKStartRequest != nil
        let alreadyReceived: Bool = receivePkRequest != nil
        let liveNotStarted:Bool  = !ZegoLiveStreamingManager.shared.isLiveStart
        let isInAPK: Bool = currentPKInfo != nil
        if  pkType == .startPK {
            if userNotHost || alreadySend || alreadyReceived || isInAPK || liveNotStarted {
                var rejectCode: ZegoLiveStreamingPKBattleRejectCode
                if (userNotHost) {
                    rejectCode = ZegoLiveStreamingPKBattleRejectCode.use_not_host
                } else if (isInAPK) {
                    rejectCode = ZegoLiveStreamingPKBattleRejectCode.in_pk
                } else if (alreadySend) {
                    rejectCode = ZegoLiveStreamingPKBattleRejectCode.already_send
                } else if (alreadyReceived) {
                    rejectCode = ZegoLiveStreamingPKBattleRejectCode.already_received
                } else {
                    rejectCode = ZegoLiveStreamingPKBattleRejectCode.live_not_started
                }
                rejectPKStartRequest(requestID: invitationID, rejectCode: rejectCode.rawValue)
                return
            }
            receivePkRequest = PKRequest(requestID: invitationID, anotherUserID: inviter.userID ?? "")
            receivePkRequest?.anotherUserName = inviter.userName
            for delegate in eventDelegates.allObjects {
                delegate.onIncomingPKRequestReceived?(requestID: invitationID, anotherHostUser: inviter, anotherHostLiveID: pkData.roomID ?? "", customData: pkData.customData)
            }
        } else if pkType == .endPK {
            acceptPKStopRequest(requestID: invitationID, anotherHostUser: inviter)
            stopPK()
        } else if pkType == .resume {
            if let _ = currentPKInfo {
                acceptPKResumeRequest(requestID: invitationID, anotherHostUser: inviter)
            } else {
                rejectPKResumeRequest(requestID: invitationID)
            }
        }
    }
    
    func onPKInvitationAccepted(_ invitee: ZegoUIKitUser, data: String?) {
        guard let extendedData = data?.live_convertStringToDictionary() else { return }
        let invitationID = extendedData["invitationID"] as? String
        let pkData = PKExtendedData.parse(data ?? "")
        if let pkData = pkData,
           let _ = invitationID
        {
            let pkRoom: String = pkData.roomID ?? ""
            let pkUserId: String = invitee.userID ?? ""
            let pkUserName: String = pkData.userName ?? ""
    
            if pkData.type == PKProtocolType.startPK.rawValue {
                invitee.userName = pkData.userName
                sendPKStartRequest = nil
                startPKBattleWith(anotherHostLiveID: pkRoom, anotherHostUserID: pkUserId, anotherHostName: pkUserName)
                for delegate in eventDelegates.allObjects {
                    delegate.onOutgoingPKBattleRequestAccepted?(anotherHostLiveID: pkData.roomID ?? "", anotherHostUser: invitee, customData: pkData.customData)
                }
            } else if pkData.type == PKProtocolType.endPK.rawValue {
                stopPK()
            } else  if pkData.type == PKProtocolType.resume.rawValue {
                startPKBattleWith(anotherHostLiveID: pkRoom, anotherHostUserID: pkUserId, anotherHostName: pkUserName)
            }
            pkInvitations.removeAll { element in
                return element == invitationID
            }
        }
    }
    
    func onPKInvitationRefused(_ invitee: ZegoUIKitUser, data: String?) {
        guard let extendedData = data?.live_convertStringToDictionary() else { return }
        let invitationID = extendedData["invitationID"] as? String
        let pkData = PKExtendedData.parse(data ?? "")
        if let sendPKStartRequest = sendPKStartRequest,
           sendPKStartRequest.requestID == invitationID
        {
            invitee.userName = pkData?.userName
            roomPKState = .isNoPK
            self.sendPKStartRequest = nil
            var reason: Int = 0
            if extendedData.keys.contains("reason") {
                reason = extendedData["reason"] as! Int
            }
            for delegate in eventDelegates.allObjects {
                delegate.onOutgoingPKBattleRequestRejected?(reason: reason, anotherHostUser: invitee)
            }
            pkInvitations.removeAll { element in
                return element == invitationID
            }
        } else {
            if let pkData = pkData,
               pkData.type == PKProtocolType.resume.rawValue
            {
                roomPKState = .isNoPK
                delectPKAttributes()
                pkInvitations.removeAll { element in
                    return element == invitationID
                }
            }
        }
    }
    
    func onPKInvitationCanceled(_ inviter: ZegoUIKitUser, data: String?) {
        guard let extendedData = data?.live_convertStringToDictionary() else { return }
        let invitationID = extendedData["invitationID"] as? String
        let pkData = PKExtendedData.parse(data ?? "")
        if let invitationID = invitationID,
           let receivePkRequest = receivePkRequest,
           invitationID == receivePkRequest.requestID
        {
            inviter.userName = receivePkRequest.anotherUserName
            inviter.userID = receivePkRequest.anotherUserID
            self.receivePkRequest = nil
            if let pkData = pkData,
               pkData.type == PKProtocolType.startPK.rawValue
            {
                for delegate in eventDelegates.allObjects {
                    delegate.onIncomingPKBattleRequestCanceled?(anotherHostLiveID: pkData.roomID ?? "", anotherHostUser: inviter, customData: pkData.customData)
                }
            }
            pkInvitations.removeAll { element in
                return element == invitationID
            }
        }
    }
    
    func onPKInvitationTimeout(_ inviter: ZegoUIKitUser, data: String?) {
        guard let extendedData = data?.live_convertStringToDictionary() else { return }
        let invitationID = extendedData["invitationID"] as? String
        if let receivePkRequest = receivePkRequest,
           let invitationID = invitationID,
           receivePkRequest.requestID == invitationID
        {
            let anotherHost: ZegoUIKitUser = ZegoUIKitUser(receivePkRequest.anotherUserID, receivePkRequest.anotherUserName ?? "")
            self.receivePkRequest = nil
            for delegate in eventDelegates.allObjects {
                delegate.onIncomingPKBattleRequestTimeout?(requestID: invitationID, anotherHostUser: anotherHost)
            }
            pkInvitations.removeAll { element in
                return element == invitationID
            }
        }
        
                
    }
    
    func onPKInvitationResponseTimeout(_ invitees: [ZegoUIKitUser], data: String?) {
        guard let extendedData = data?.live_convertStringToDictionary() else { return }
        let invitationID = extendedData["invitationID"] as? String
        if let sendPKStartRequest = sendPKStartRequest,
           let invitationID = invitationID,
           sendPKStartRequest.requestID == invitationID
        {
            let anotherHost: ZegoUIKitUser = ZegoUIKitUser(sendPKStartRequest.anotherUserID,
                sendPKStartRequest.anotherUserName ?? "")
            
            self.sendPKStartRequest = nil
            self.roomPKState = .isNoPK
            for delegate in eventDelegates.allObjects {
                delegate.onOutgoingPKBattleRequestTimeout?(requestID: invitationID, anotherHost: anotherHost)
            }
            pkInvitations.removeAll { element in
                return element == invitationID
            }
        }
    }
    
    func isPKBusiness(type: Int) -> Bool {
        if type == PKProtocolType.startPK.rawValue || type == PKProtocolType.resume.rawValue || type == PKProtocolType.endPK.rawValue {
            return true
        }
        return false
    }
}
