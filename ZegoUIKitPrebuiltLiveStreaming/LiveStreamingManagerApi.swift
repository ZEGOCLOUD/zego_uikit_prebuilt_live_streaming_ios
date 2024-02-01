//
//  ZegoUIKitPrebuiltLiveStreamingManagerProtocol.swift
//  ZegoUIKitPrebuiltLiveStreaming
//
//  Created by zego on 2024/1/17.
//

import Foundation
import ZegoUIKit

public protocol LiveStreamingManagerApi {
    
    /// Add live event listener
    /// - Parameter delegate: Observer
    func addLiveManagerDelegate(_ delegate: ZegoLiveStreamingManagerDelegate)
    
    /// Get host ID
    /// - Returns: host id
    func getHostID() -> String
    
    /// Is the user a host?
    /// - Parameter userID: Unique identifier for the user
    /// - Returns: The result 'true' indicates that the person is a host, while 'false' indicates that they are not.
    func isHost(_ userID: String) -> Bool
    
    /// Is the current user a host?
    /// - Returns: The return result 'true' represents yes, while 'false' represents no.
    func isCurrentUserHost() -> Bool
    
    /// Is the current user a cohost?
    /// - Returns: The return result 'true' represents yes, while 'false' represents no.
    func isCurrentUserCoHost() -> Bool
    
    /// Sending stop pk request
    func stopPKBattle()
    
    /// Accept PK invitation
    /// - Parameters:
    ///   - requestID: Unique ID for PK request
    ///   - anotherHostLiveID: Sender's live ID
    ///   - anotherHostUser: Sender
    ///   - customData: Custom data
    func acceptIncomingPKBattleRequest(_ requestID: String, anotherHostLiveID: String, anotherHostUser: ZegoUIKitUser, customData: String)
    
    /// Accept PK invitation
    /// - Parameters:
    ///   - requestID: Unique ID for PK request
    ///   - anotherHostLiveID: Sender's live ID
    ///   - anotherHostUser: Sender
    func acceptIncomingPKBattleRequest(_ requestID: String, anotherHostLiveID: String, anotherHostUser: ZegoUIKitUser)
    
    /// Refuse PK invitation
    /// - Parameter requestID: Unique ID for PK request
    func rejectPKBattleStartRequest(_ requestID: String)
    
    /// Whether to block audio from other host
    /// - Parameters:
    ///   - mute: true represents blocking, while false represents receiving.
    ///   - callback: Callback of operation result
    func muteAnotherHostAudio(_ mute: Bool, callback: ZegoUIKitCallBack?)
    
    /// Send PK invitation
    /// - Parameters:
    ///   - anotherHostUserID: Inviting user's ID
    ///   - timeout: Request timeout limit, Default value is 60 seconds
    ///   - customData: Custom data that needs to be passed.
    ///   - callback: Callback for request results
    func sendPKBattleRequest(anotherHostUserID: String,
                                    timeout: UInt32,
                                    customData: String,
                                    callback: UserRequestCallback?)
    
    // Send PK invitation
    /// - Parameters:
    ///   - anotherHostUserID: Inviting user's ID
    ///   - timeout: Request timeout limit, Default value is 60 seconds
    ///   - callback: Callback for request results
    func sendPKBattleRequest(anotherHostUserID: String, timeout: UInt32,callback: UserRequestCallback?)
    
    /// Cancel pk request
    /// - Parameters:
    ///   - customData: Custom data that needs to be passed
    ///   - callback: Cancelled result callback
    func cancelPKBattleRequest(customData: String?, callback: UserRequestCallback?)
    
    /// Leave the room
    func leaveRoom() 
}
