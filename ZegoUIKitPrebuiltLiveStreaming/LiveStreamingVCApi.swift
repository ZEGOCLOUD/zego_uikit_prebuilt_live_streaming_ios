//
//  ZegoUIKitPrebuiltLiveStreamingVCProtocol.swift
//  Pods
//
//  Created by zego on 2024/1/17.
//

import Foundation

public protocol LiveStreamingVCApi {
    
    /// Add a custom button to the bottom bar.
    /// - Parameters:
    ///   - button: Custom button
    ///   - role: User identity, specifies under what condition the button is displayed.
    func addButtonToBottomMenuBar(_ button: UIButton, role: ZegoLiveStreamingRole)
    
    /// Custom start live button
    /// - Parameter button: Custom ZegoStartLiveButton
    func setStartLiveButton(_ button: ZegoStartLiveButton)
    
    /// Remove custom buttons that were added to the bottom bar previously.
    /// - Parameter role: The user's identity specifies that only custom buttons added under the corresponding identity should be cleared.
    func clearBottomMenuBarExtendButtons(_ role: ZegoLiveStreamingRole)
    
    /// Custom Live Room Background
    /// - Parameter view: Custom view
    func setBackgroundView(_ view: UIView)
}
