//
//  ZegoLiveStreamDefine.swift
//  ZegoUIKit
//
//  Created by zego on 2022/8/25.
//

import Foundation
import UIKit

//MARK: -Internal
let UIkitLiveScreenHeight = UIScreen.main.bounds.size.height
let UIkitLiveScreenWidth = UIScreen.main.bounds.size.width
let UIkitLiveBottomSafeAreaHeight = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0

func UIkitLiveAdaptLandscapeWidth(_ x: CGFloat) -> CGFloat {
    return x * (UIkitLiveScreenWidth / 375.0)
}

func UIkitLiveAdaptLandscapeHeight(_ x: CGFloat) -> CGFloat {
    return x * (UIkitLiveScreenHeight / 818.0)
}

func KeyWindow() -> UIWindow {
    let window: UIWindow = UIApplication.shared.windows.filter({ $0.isKeyWindow }).last!
    return window
}
 

enum ZegoUIKitLiveStreamIconSetType: String, Hashable {
    
    case bottom_message
    case bottom_message_disable
    case top_people
    case icon_more
    case icon_more_light
    case top_close
    case live_background_image
    case bottombar_lianmai
    case lianmai_more
    case member_more
    case icon_nav_flip
    case icon_comeback
    case icon_message_normal
    case icon_message_disable
    
    // MARK: - Image handling
    func load() -> UIImage {
        let image = UIImage.resource.loadImage(name: self.rawValue, bundleName: "ZegoUIKitPrebuiltLiveStreaming") ?? UIImage()
        return image
    }
}

//MARK: - Public
@objc public enum ZegoMenuBarButtonName: Int {
    case leaveButton
    case toggleCameraButton
    case toggleMicrophoneButton
    case switchCameraButton
    case switchAudioOutputButton
    case coHostControlButton
    case enableChatButton
}

@objc public enum ZegoInvitationType: Int {
    case requestCoHost = 2
    case inviteToCoHost = 3
    case removeCoHost = 4
    case pk = 5
}

@objc public enum ZegoBottomMenuBarPosition: Int {
    case left
    case right
}

@objc public enum ZegoLiveStreamingRole: Int {
    case host = 0
    case coHost = 1
    case audience = 2
}
@objc public enum ZegoLiveStreamingPKBattleRejectCode: Int {
    case host_reject
    case use_not_host
    case in_pk
    case live_not_started
    case already_send
    case already_received
}

public let kRoleHost: UInt = 1
public let kRoleAudience: UInt = 2

