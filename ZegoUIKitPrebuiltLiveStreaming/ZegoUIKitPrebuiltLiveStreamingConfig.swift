//
//  ZegoUIKitPrebuiltLiveStreamingConfig.swift
//  ZegoUIKit
//
//  Created by zego on 2022/8/22.
//

import UIKit
import ZegoUIKit

@objc public enum ZegoLiveStreamLanguage : UInt32 {
  case english
  case chinese
}

@objcMembers
public class ZegoUIKitPrebuiltLiveStreamingConfig: NSObject {
    
    var role: ZegoLiveStreamingRole = .audience
    public var translationText: ZegoTranslationText = ZegoTranslationText()
    public var markAsLargeRoom: Bool = false
    public var audioVideoViewConfig: ZegoPrebuiltAudioVideoViewConfig = ZegoPrebuiltAudioVideoViewConfig()
    public var turnOnCameraWhenJoining: Bool = false
    public var turnOnMicrophoneWhenJoining: Bool = false
    public var useSpeakerWhenJoining: Bool = true
    public var canCameraTurnOnByOthers = false
    public var canMicrophoneTurnOnByOthers = false
    public var bottomMenuBarConfig: ZegoBottomMenuBarConfig = ZegoBottomMenuBarConfig()
    public var turnOnYourCameraConfirmDialogInfo: ZegoDialogInfo?
    public var turnOnYourMicrophoneConfirmDialogInfo: ZegoDialogInfo?
    public var enableCoHosting: Bool = false
    public var enableSignalingPlugin: Bool = false
    public var layout: ZegoLayout?
    public var languageCode: ZegoLiveStreamLanguage = .english {
      didSet{
        if languageCode == .chinese {
          translationText = ZegoTranslationTextZH();
        } else {
          translationText = ZegoTranslationText();
        }
      }
    }
    public lazy var confirmDialogInfo: ZegoLeaveConfirmDialogInfo? = {
      let leaveDiaglog = ZegoLeaveConfirmDialogInfo()
    
      leaveDiaglog.title = self.translationText.leaveDialogTitle
      leaveDiaglog.message = self.translationText.leaveDialogMessage
      leaveDiaglog.cancelButtonName = self.translationText.cancelMenuDialogButton
      leaveDiaglog.confirmButtonName = self.translationText.leaveDialogConfimText
      if self.role == .host {
        return leaveDiaglog
      } else {
        return nil
      }
    }()
  
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
//        let leaveDiaglog = ZegoLeaveConfirmDialogInfo()
//      
//        leaveDiaglog.title = self.translationText.leaveDialogTitle
//        leaveDiaglog.message = self.translationText.leaveDialogMessage
//        leaveDiaglog.cancelButtonName = self.translationText.cancelMenuDialogButton
//        leaveDiaglog.confirmButtonName = self.translationText.leaveDialogConfimText
//        config.confirmDialogInfo = leaveDiaglog
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
  
    public var cameraPermissionSettingDialogInfoTitle: String = "Can not use Camera!"
    public var cameraPermissionSettingDialogInfoMessage: String = "Please enable camera access in the system settings!"
    public var cameraPermissionSettingDialogInfoConfirmButton: String = "Settings"
  
    public var microphonePermissionSettingDialogInfoTitle: String = "Can not use Microphone!"
    public var microphonePermissionSettingDialogInfoMessage: String = "Please enable microphone access in the system settings!"
    
    public var receivedCoHostInvitationDialogInfoTitle: String = "Invitation"
    public var receivedCoHostInvitationDialogInfoMessage: String = "The host is inviting you to co-host."
    public var receivedCoHostInvitationDialogInfoConfirm: String = "Agree"
    public var receivedCoHostInvitationDialogInfoCancel: String = "Disagree"
    
    public var endConnectionDialogInfoTitle: String = "End the connection"
    public var endConnectionDialogInfoMessage: String = "Do you want to end the cohosting?"

    public var leaveDialogTitle: String = "Stop the Live"
    public var leaveDialogMessage: String = "Are you sure to stop the live?"
    public var leaveDialogConfimText: String = "Stop it"
    
    public var dialogOkText: String = "OK"
    public var userIdentityYouHost: String = "(You,Host)"
    public var userIdentityHost: String = "(Host)"
    public var userIdentityYouCoHost: String = "(You,Co-host)"
    public var userIdentityCoHost: String = "(Co-host)"
    public var userIdentityYou: String = "(You)"
    public var pkingNotRequestCoHost: String = "cannot apply coHost because PK"

}

class ZegoTranslationTextZH : ZegoTranslationText {
  override init() {
    super.init()
    startLiveStreamingButton = "开始"
    endCoHostButton = "结束"
    requestCoHostButton = "申请连麦"
    cancelRequestCoHostButton = "取消申请"
    removeCoHostButton = "取消连麦"
    cancelMenuDialogButton = "取消"
    noHostOnline = "主播不在线。"
    inviteCoHostButton = "邀请 %@ 连麦"
    memberListTitle = "观众"
    sendRequestCoHostToast = "您正在申请连麦，请等待确认。"
    hostRejectCoHostRequestToast = "您的连麦申请已被拒绝。"
    inviteCoHostFailedToast = "连麦失败，请重试。"
    repeatInviteCoHostFailedToast = "您已发送连麦邀请，请等待确认。"
    audienceRejectInvitationToast = "拒绝连麦。"
    requestCoHostFailed = "申请连麦失败。"
    removeUserMenuDialogButton = "将 %@ 踢出房间"
    
    cameraPermissionSettingDialogInfoTitle = "无法使用摄像头！"
    cameraPermissionSettingDialogInfoMessage = "请在系统设置中启用摄像头访问！"
    cameraPermissionSettingDialogInfoConfirmButton = "设置"
  
    microphonePermissionSettingDialogInfoTitle = "无法使用麦克风！!"
    microphonePermissionSettingDialogInfoMessage = "请在系统设置中启用麦克风访问！"
    
    receivedCoHostInvitationDialogInfoTitle = "邀请"
    receivedCoHostInvitationDialogInfoMessage = "房主邀请您上麦"
    receivedCoHostInvitationDialogInfoConfirm = "同意"
    receivedCoHostInvitationDialogInfoCancel = "不同意"
    
    endConnectionDialogInfoTitle = "结束连接"
    endConnectionDialogInfoMessage = "您确定要结束连麦吗？"

    leaveDialogTitle = "停止直播"
    leaveDialogMessage = "您确定要停止直播吗？"
    leaveDialogConfimText = "停止直播"
    
    dialogOkText = "确定"
    userIdentityYouHost = "(我,房主)"
    userIdentityHost = "(主播)"
    userIdentityYouCoHost = "(我,连麦用户)"
    userIdentityCoHost = "(连麦用户)"
    userIdentityYou = "(我)"
    pkingNotRequestCoHost = "pk中不可以申请连麦"
  }
}

public class ZegoDialogInfo: NSObject {
    public var title: String?
    public var message: String?
    public var cancelButtonName: String?
    public var confirmButtonName: String?
    public var translationText: ZegoTranslationText = ZegoTranslationText()
    public init(_ title: String, message: String, cancelButtonName: String? , confirmButtonName: String? ,languageCode: ZegoLiveStreamLanguage) {
        self.title = title
        self.message = message
        if languageCode == .chinese {
          translationText = ZegoTranslationTextZH();
        } else {
          translationText = ZegoTranslationText();
        }
        self.cancelButtonName = cancelButtonName ?? translationText.cancelMenuDialogButton
        self.confirmButtonName = confirmButtonName ?? translationText.dialogOkText
    }
}

public class ZegoPrebuiltAudioVideoViewConfig: NSObject {
    public var useVideoViewAspectFill: Bool = true
    public var showSoundWavesInAudioMode: Bool = true
}
