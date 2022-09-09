//
//  ZegoMemberButton.swift
//  ZegoUIKit
//
//  Created by zego on 2022/8/25.
//

import UIKit
import ZegoUIKitSDK

public class ZegoMemberButton: UIButton {
    
    private let help: ZegoMemberButton_Help = ZegoMemberButton_Help()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.help.memberButton = self
        ZegoUIKit.shared.addEventHandler(self.help)
        self.addTarget(self, action: #selector(buttonClick), for: .touchUpInside)
        self.setImage(ZegoUIKitLiveStreamIconSetType.top_people.load(), for: .normal) //按钮图标
        self.titleLabel?.font = UIFont.systemFont(ofSize: 12)//文字大小
        self.setTitleColor(UIColor.colorWithHexString("#FFFFFF"), for: .normal)//文字颜色
        self.titleEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 0)
        let number: Int = ZegoUIKit.shared.getAllUsers().count
        self.setTitle(String(format: "%d", number), for: .normal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func buttonClick() {
        
    }

}

class ZegoMemberButton_Help: NSObject, ZegoUIKitEventHandle {
    
    var memberButton: ZegoMemberButton?
    
    func onRemoteUserJoin(_ userList: [ZegoUIkitUser]) {
        let number: Int = ZegoUIKit.shared.getAllUsers().count
        self.memberButton?.setTitle(String(format: "%d", number), for: .normal)
    }
    
    func onRemoteUserLeave(_ userList: [ZegoUIkitUser]) {
        let number: Int = ZegoUIKit.shared.getAllUsers().count
        self.memberButton?.setTitle(String(format: "%d", number), for: .normal)
    }
}
