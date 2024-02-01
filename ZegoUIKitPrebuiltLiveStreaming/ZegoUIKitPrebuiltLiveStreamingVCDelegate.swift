//
//  ZegoUIKitPrebuiltLiveStreamingVCDelegate.swift
//  ZegoUIKitPrebuiltLiveStreaming
//
//  Created by zego on 2024/1/18.
//

import Foundation
import ZegoUIKit

@objc public protocol ZegoUIKitPrebuiltLiveStreamingVCDelegate: AnyObject {
    @objc optional func getForegroundView(_ userInfo: ZegoUIKitUser?) -> ZegoBaseAudioVideoForegroundView?
    @objc optional func onLeaveLiveStreaming()
    @objc optional func onLiveStreamingEnded()
    @objc optional func onStartLiveButtonPressed()
    
    @objc optional func getPKBattleForegroundView(_ parentView: UIView, userInfo: ZegoUIKitUser) -> UIView?
    @objc optional func getPKBattleTopView(_ parentView: UIView, userList: [ZegoUIKitUser]) -> UIView?
    @objc optional func getPKBattleBottomView(_ parentView: UIView, userList: [ZegoUIKitUser]) -> UIView?
}
