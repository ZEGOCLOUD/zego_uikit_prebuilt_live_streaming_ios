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
 

enum ZegoUIKitLiveStreamIconSetType: String, Hashable {
    
    case bottom_message
    case top_people
    case icon_more
    case icon_more_light
    case top_close
    case live_background_image
    
    // MARK: - Image handling
    func load() -> UIImage {
        let image = UIImage.resource.loadImage(name: self.rawValue, bundleName: "ZegoUIKitPrebuiltLiveStream") ?? UIImage()
        return image
    }
}

//MARK: - Public
@objc public enum ZegoMenuBarButtonName: Int {
    case leaveButton
    case toggleCameraButton
    case toggleMicrophoneButton
    case switchCameraButton
    case swtichAudioOutputButton
}

public let kRoleHost: UInt = 1
public let kRoleAudience: UInt = 2

