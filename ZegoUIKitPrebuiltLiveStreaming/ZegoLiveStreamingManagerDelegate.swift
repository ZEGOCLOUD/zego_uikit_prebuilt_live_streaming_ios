//
//  ZegoLiveStreamingManagerDelegate.swift
//  ZegoUIKitPrebuiltLiveStreaming
//
//  Created by zego on 2024/1/18.
//

import Foundation
import ZegoUIKit

@objc public protocol ZegoLiveStreamingManagerDelegate: AnyObject {
    
    @objc optional func onIncomingCohostRequest(inviter: ZegoUIKitUser)
    @objc optional func onIncomingInviteToCohostRequest(inviter: ZegoUIKitUser, invitationID: String)
    @objc optional func onIncomingRemoveCohostRequest(inviter: ZegoUIKitUser)
    @objc optional func onIncomingAcceptCohostRequest(invitee: ZegoUIKitUser, data: String?)
    @objc optional func onIncomingCancelCohostRequest(inviter: ZegoUIKitUser, data: String?)
    @objc optional func onIncomingCancelCohostInvite(inviter: ZegoUIKitUser, data: String?)
    @objc optional func onIncomingRefuseCohostRequest(invitee: ZegoUIKitUser, data: String?)
    @objc optional func onIncomingRefuseCohostInvite(invitee: ZegoUIKitUser, data: String?)
    @objc optional func onIncomingCohostRequestTimeOut(inviter: ZegoUIKitUser, data: String?)
    @objc optional func onIncomingCohostInviteTimeOut(inviter: ZegoUIKitUser, data: String?)
    @objc optional func onIncomingCohostInviteResponseTimeOut(invitees: [ZegoUIKitUser], data: String?)
    @objc optional func onIncomingCohostRequestResponseTimeOut(invitees: [ZegoUIKitUser], data: String?)
    
    
    @objc optional func onIncomingPKRequestReceived(requestID: String, anotherHostUser: ZegoUIKitUser, anotherHostLiveID: String, customData: String?)
    @objc optional func onIncomingResumePKRequestReceived(requestID: String)
    @objc optional func onIncomingPKRequestCancelled(anotherHostLiveID: String, anotherHostUser: ZegoUIKitUser, customData: String?)
    @objc optional func onOutgoingPKRequestAccepted(anotherHostLiveID: String, anotherHostUser: ZegoUIKitUser, customData: String?)
    @objc optional func onOutgoingPKRequestRejected(reason: Int, anotherHostUser: ZegoUIKitUser)
    @objc optional func onIncomingPKRequestTimeout(requestID: String, anotherHostUser: ZegoUIKitUser)
    @objc optional func onOutgoingPKRequestTimeout(requestID: String, anotherHost: ZegoUIKitUser)
    
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
