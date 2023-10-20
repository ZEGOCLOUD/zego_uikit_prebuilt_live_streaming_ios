//
//  PKContainer.swift
//  ZegoUIKitPrebuiltLiveStreaming
//
//  Created by zego on 2023/10/8.
//

import UIKit
import ZegoUIKit

protocol PKContainerDelegate: AnyObject {
    func getPKBattleForegroundView(_ parentView: UIView, userInfo: ZegoUIKitUser) -> UIView
    func getPKBattleTopView(_ parentView: UIView, userList: [ZegoUIKitUser]) -> UIView
    func getPKBattleBottomView(_ parentView: UIView, userList: [ZegoUIKitUser]) -> UIView
}

class PKContainer: UIView {
    
    weak var delegate: PKContainerDelegate?
    
    var pkInfo: PKInfo? {
        didSet {
            let host = ZegoUIKit.shared.getUser(ZegoLiveStreamingManager.shared.getHostID())
            if let pkInfo = pkInfo,
               let host = host
            {
                let anotherHost = pkInfo.pkUser
                topView.userList = [host, anotherHost]
                bottomBar.userList = [host, anotherHost]
            }
            pkView?.pkInfo = pkInfo
        }
    }
    
    var pkViewAvaliable: Bool = false {
        didSet {
            pkView?.pkViewAvaliable = pkViewAvaliable
        }
    }
    
    var pkView: PKBattleView?
    
    lazy var topView: PKTopView = {
        let view = PKTopView()
        view.delegate = self
        return view
    }()
    
    lazy var bottomBar: PKBottomView = {
        let view = PKBottomView()
        view.delegate = self
        return view
    }()
    
    init(frame: CGRect, role: ZegoLiveStreamingRole) {
        super.init(frame: frame)
        self.addSubview(topView)
        pkView = PKBattleView(frame: CGRect(x: 0, y: 100, width: bounds.size.width, height: bounds.size.width * (333.0 / 375.0)), role: role)
        pkView?.delegate = self
        self.addSubview(pkView!)
        self.addSubview(bottomBar)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        topView.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: 100)
        pkView?.frame = CGRect(x: 0, y: 100, width: bounds.size.width, height: bounds.size.width * (333.0 / 375.0))
        bottomBar.frame = CGRect(x: 0, y: CGRectGetMaxY(pkView!.frame), width: bounds.size.width, height: (bounds.size.height - 100 - bounds.size.width * (333.0 / 375.0)))
    }
    
}

extension PKContainer: PKTopViewDelegate, PKBottomViewDelegate{
    
    func getPKTopViewContainerView(_ parentView: UIView, userList: [ZegoUIKitUser]) -> UIView {
        return self.delegate?.getPKBattleTopView(parentView, userList: userList) ?? UIView()
    }
    
    func getPKBottomViewContainerView(_ parentView: UIView, userList: [ZegoUIKitUser]) -> UIView {
        return self.delegate?.getPKBattleBottomView(parentView, userList: userList) ?? UIView()
    }
}

protocol PKTopViewDelegate: AnyObject {
    func getPKTopViewContainerView(_ parentView: UIView, userList: [ZegoUIKitUser]) -> UIView
}

class PKTopView: UIView {
    
    var userList: [ZegoUIKitUser]? {
        didSet {
            if let userList = userList,
               let delegate = delegate
            {
                containerView = delegate.getPKTopViewContainerView(self, userList: userList)
                self.addSubview(containerView!)
            }
        }
    }
    var containerView: UIView?
    
    weak var delegate: PKTopViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        containerView?.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height)
    }
    
}

protocol PKBottomViewDelegate: AnyObject {
    func getPKBottomViewContainerView(_ parentView: UIView, userList: [ZegoUIKitUser]) -> UIView
}

class PKBottomView: UIView {
    
    var userList: [ZegoUIKitUser]? {
        didSet {
            if let userList = userList,
               let delegate = delegate
            {
                containerView = delegate.getPKBottomViewContainerView(self, userList: userList)
                self.addSubview(containerView!)
            }
        }
    }
    var containerView: UIView?
    
    weak var delegate: PKBottomViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        containerView?.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height)
    }
    
}

extension PKContainer: PKBattleViewDelegate {
    func getPKForegroundView(_ parentView: UIView, userInfo: ZegoUIKitUser) -> UIView {
        return delegate?.getPKBattleForegroundView(parentView, userInfo: userInfo) ?? UIView()
    }
}
