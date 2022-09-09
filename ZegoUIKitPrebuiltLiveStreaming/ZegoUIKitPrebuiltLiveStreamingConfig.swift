//
//  ZegoUIKitPrebuiltLiveStreamingConfig.swift
//  ZegoUIKit
//
//  Created by zego on 2022/8/22.
//

import UIKit
import ZegoUIKitSDK

@objcMembers
public class ZegoUIKitPrebuiltLiveStreamingConfig: NSObject {
    
    public var showSoundWavesInAudioMode: Bool = true
    public var turnOnCameraWhenJoining: Bool = true
    public var turnOnMicrophoneWhenJoining: Bool = true
    public var useSpeakerWhenJoining: Bool = true
    public var showInRoomMessageButton: Bool = true
    public var menuBarButtons: [ZegoMenuBarButtonName] = [.switchCameraButton,.toggleMicrophoneButton,.toggleCameraButton]
    public var menuBarButtonsMaxCount: Int = 5
    public var confirmDialogInfo: ZegoLeaveConfirmDialogInfo?
    
    public init(_ role: UInt) {
        if role == 0 || role == 2{
            showSoundWavesInAudioMode = false
            turnOnCameraWhenJoining = false
            turnOnMicrophoneWhenJoining = false
            useSpeakerWhenJoining = true
            showInRoomMessageButton = true
            menuBarButtons = []
            menuBarButtonsMaxCount = 5
        } else if role == 1 {
            showSoundWavesInAudioMode = true
            turnOnCameraWhenJoining = true
            turnOnMicrophoneWhenJoining = true
            useSpeakerWhenJoining = true
            showInRoomMessageButton = true
            menuBarButtons = [.switchCameraButton,.toggleMicrophoneButton,.toggleCameraButton]
            menuBarButtonsMaxCount = 5
        }
     }
}
