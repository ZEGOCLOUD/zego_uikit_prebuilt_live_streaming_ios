//
//  PKDefine.swift
//  ZegoUIKitPrebuiltLiveStreaming
//
//  Created by zego on 2023/9/21.
//

import Foundation

public enum PKProtocolType: UInt, Codable {
    // start pk
    case startPK = 91000
    // end pk
    case endPK = 91001
    // resume pk
    case resume = 91002
}

public enum RoomPKState {
    case isNoPK
    case isRequestPK
    case isStartPK
}

enum SEIType: UInt {
    case deviceState
}

