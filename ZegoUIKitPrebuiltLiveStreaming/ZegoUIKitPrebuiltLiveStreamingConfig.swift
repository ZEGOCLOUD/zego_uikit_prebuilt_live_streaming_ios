//
//  ZegoUIKitPrebuiltLiveStreamingConfig.swift
//  ZegoUIKit
//
//  Created by zego on 2022/8/22.
//

import UIKit
import ZegoUIKit

@objcMembers
public class ZegoUIKitPrebuiltLiveStreamingConfig: NSObject {
    
    var role: ZegoLiveStreamingRole = .audience
    public var markAsLargeRoom: Bool = false
    public var audioVideoViewConfig: ZegoPrebuiltAudioVideoViewConfig = ZegoPrebuiltAudioVideoViewConfig()
    public var turnOnCameraWhenJoining: Bool = false
    public var turnOnMicrophoneWhenJoining: Bool = false
    public var useSpeakerWhenJoining: Bool = true
    public var canCameraTurnOnByOthers = false
    public var canMicrophoneTurnOnByOthers = false
    public var bottomMenuBarConfig: ZegoBottomMenuBarConfig = ZegoBottomMenuBarConfig()
    public var confirmDialogInfo: ZegoLeaveConfirmDialogInfo?
    public var turnOnYourCameraConfirmDialogInfo: ZegoDialogInfo?
    public var turnOnYourMicrophoneConfirmDialogInfo: ZegoDialogInfo?
    public var translationText: ZegoTranslationText = ZegoTranslationText()
    public var enableCoHosting: Bool = false
    public var enableSignalingPlugin: Bool = false
    public var layout: ZegoLayout?
    
    public override init() {
        bottomMenuBarConfig.hostButtons = [.switchCameraButton,.toggleMicrophoneButton,.toggleCameraButton]
        bottomMenuBarConfig.coHostButtons = [.coHostControlButton,.switchCameraButton,.toggleMicrophoneButton,.toggleCameraButton]
        bottomMenuBarConfig.audienceButtons = [.coHostControlButton]
    }
    
    public static func host(enableSignalingPlugin: Bool = false) -> ZegoUIKitPrebuiltLiveStreamingConfig {
        let config = ZegoUIKitPrebuiltLiveStreamingConfig()
        config.role = .host
        config.enableSignalingPlugin = enableSignalingPlugin
        config.turnOnCameraWhenJoining = true
        config.turnOnMicrophoneWhenJoining = true
        let leaveDiaglog = ZegoLeaveConfirmDialogInfo()
        leaveDiaglog.title = "Stop the Live"
        leaveDiaglog.message = "Are you sure to stop the live?"
        leaveDiaglog.cancelButtonName = "Cancel"
        leaveDiaglog.confirmButtonName = "Stop it"
        config.confirmDialogInfo = leaveDiaglog
        return config
    }
    
    public static func audience(enableSignalingPlugin: Bool = false) -> ZegoUIKitPrebuiltLiveStreamingConfig {
        let config = ZegoUIKitPrebuiltLiveStreamingConfig()
        config.role = .audience
        config.enableSignalingPlugin = enableSignalingPlugin
        return config
    }
}

public class ZegoBottomMenuBarConfig: NSObject {
    public var maxCount: UInt = 5
    public var showInRoomMessageButton: Bool = true
    public var hostButtons: [ZegoMenuBarButtonName] = []
    public var coHostButtons: [ZegoMenuBarButtonName] = []
    public var audienceButtons: [ZegoMenuBarButtonName] = []
}

public class ZegoTranslationText: NSObject {
    public var startLiveStreamingButton: String = "Start"
    public var endCoHostButton: String = "End"
    public var requestCoHostButton: String = "Apply to co-host"
    public var cancelRequestCoHostButton: String = "Cancel the application"
    public var removeCoHostButton: String = "Remove the co-host"
    public var cancelMenuDialogButton: String = "Cancel"
    public var noHostOnline: String = "No host is online."
    public var inviteCoHostButton: String = "Invite %@ to co-host"
    public var memberListTitle: String = "Audience"
    public var sendRequestCoHostToast: String = "You are applying to be a co-host, please wait for confirmation."
    public var hostRejectCoHostRequestToast: String = "Your request to co-host with the host has been refused."
    public var inviteCoHostFailedToast: String = "Failed to connect with the co-host，please try again."
    public var repeatInviteCoHostFailedToast:String = "You've sent the co-host invitation, please wait for confirmation."
    public var audienceRejectInvitationToast: String = "refused to be a co-host."
    public var requestCoHostFailed: String = "Failed to apply for connection."
    public var removeUserMenuDialogButton: String = "remove %@ from the room"
    
    public var cameraPermissionSettingDialogInfo: ZegoDialogInfo = ZegoDialogInfo.init("Can not use Camera!", message: "Please enable camera access in the system settings!", cancelButtonName: "Cancel", confirmButtonName: "Settings")
    public var microphonePermissionSettingDialogInfo: ZegoDialogInfo = ZegoDialogInfo.init("Can not use Microphone!", message: "Please enable microphone access in the system settings!", cancelButtonName: "Cancel", confirmButtonName: "Settings")
    public var receivedCoHostInvitationDialogInfo: ZegoDialogInfo = ZegoDialogInfo.init("Invitation", message: "The host is inviting you to co-host.", cancelButtonName: "Disagree", confirmButtonName: "Agree")
    public var endConnectionDialogInfo: ZegoDialogInfo = ZegoDialogInfo.init("End the connection", message: "Do you want to end the cohosting?")
    
}

public class ZegoDialogInfo: NSObject {
    public var title: String?
    public var message: String?
    public var cancelButtonName: String = "Cancel"
    public var confirmButtonName: String = "OK"
    
    public init(_ title: String, message: String, cancelButtonName: String = "Cancel", confirmButtonName: String = "OK") {
        self.title = title
        self.message = message
        self.cancelButtonName = cancelButtonName
        self.confirmButtonName = confirmButtonName
    }
}

public class ZegoPrebuiltAudioVideoViewConfig: NSObject {
    public var useVideoViewAspectFill: Bool = true
    public var showSoundWavesInAudioMode: Bool = true
}
