//
//  ZegoLiveStreamMoreView.swift
//  ZegoUIKit
//
//  Created by zego on 2022/8/26.
//

import UIKit

class ZegoLiveStreamMoreView: UIViewController {

    var containerHeight: CGFloat = 0
    
    lazy var containerView: UIView = {
        let view: UIView = UIView()
        view.backgroundColor = UIColor.colorWithHexString("171821")
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 16
        return view
    }()
    
    lazy var topLine: UIView = {
        let view: UIView = UIView()
        view.backgroundColor = UIColor.colorWithHexString("#FFFFFF")
        return view
    }()
    
    override func viewDidLoad() {
        self.view.backgroundColor = UIColor.colorWithHexString("000000", alpha: 0.5)
        self.view.addSubview(self.topLine)
        self.view.addSubview(self.containerView)
        self.setupLayout()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.topLine.bounds = CGRect(x: 0, y: 0, width: UIkitLiveAdaptLandscapeWidth(40), height: UIkitLiveAdaptLandscapeHeight(5))
        self.topLine.center = CGPoint(x: self.view.center.x, y: UIkitLiveAdaptLandscapeHeight(7) + UIkitLiveAdaptLandscapeHeight(2.5))
        self.setupLayout()
    }
    
    var buttonList:[UIView] = [] {
        didSet {
            self.setupLayout()
        }
    }
    
    func setupLayout() {
        var lines: Int = 1
        if buttonList.count % 5 > 0 {
            lines = buttonList.count / 5 + 1
        } else {
            lines = buttonList.count / 5
        }
        let itemHeight: CGFloat = UIkitLiveAdaptLandscapeWidth(38) + UIkitLiveAdaptLandscapeHeight(14) + 2
        let space: CGFloat = UIkitLiveAdaptLandscapeHeight(15) * CGFloat((lines - 1))
        self.containerHeight = itemHeight * CGFloat(lines) + space * CGFloat(lines - 1) + UIkitLiveAdaptLandscapeHeight(47)
        self.containerView.frame = CGRect(x: 0, y: self.view.frame.size.height - self.containerHeight, width: self.view.frame.size.width, height: self.containerHeight)
        
        var index: Int = 0
        var lastView: UIView?
        for button in buttonList {
            button.liveStream_removeAllConstraints()
            self.containerView.addSubview(button)
            if button.bounds.size.width == 0 {
                button.bounds.size = CGSize(width: UIkitLiveAdaptLandscapeWidth(43), height: UIkitLiveAdaptLandscapeHeight(54))
            }
            if button.bounds.size.height == 0 {
                button.bounds.size = CGSize(width: UIkitLiveAdaptLandscapeWidth(43), height: UIkitLiveAdaptLandscapeHeight(54))
            }
            if (index % 5) == 0 {
                //说明是每行第一个
                let y: CGFloat = UIkitLiveAdaptLandscapeHeight(27) + CGFloat((index / 5)) * UIkitLiveAdaptLandscapeHeight(54) + UIkitLiveAdaptLandscapeHeight(15) * CGFloat((index / 5))
                button.frame = CGRect(x: UIkitLiveAdaptLandscapeWidth(28.5), y: y, width: button.bounds.size.width, height: button.bounds.size.height)
            } else {
                if let lastView = lastView {
                    button.frame = CGRect(x: lastView.frame.origin.x + lastView.frame.size.width + UIkitLiveAdaptLandscapeWidth(32), y: lastView.frame.origin.y, width: button.bounds.size.width, height: button.bounds.size.height)
                    
                }
            }
            index = index + 1
            lastView = button
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.view.removeFromSuperview()
        self.removeFromParent()
    }
    
    deinit {
        print("CallMoreView deinit")
    }

}
