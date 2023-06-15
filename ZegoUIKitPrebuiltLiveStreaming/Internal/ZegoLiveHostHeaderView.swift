//
//  ZegoLiveHostHeaderView.swift
//  ZegoUIKitPrebuiltLiveStreaming
//
//  Created by zego on 2022/10/31.
//

import UIKit
import ZegoUIKit

class ZegoLiveHostHeaderView: UIView {
    
    var host: ZegoUIKitUser? {
        didSet {
            guard let host = host else {
                self.headLabel.text = ""
                self.headNameLabel.text = ""
                return
            }
            self.setHeadUserName(host.userName ?? "")
        }
    }
    
    lazy var headLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 23, weight: .semibold)
        label.textAlignment = .center
        label.textColor = UIColor.colorWithHexString("#222222")
        label.backgroundColor = UIColor.colorWithHexString("#DBDDE3")
        return label
    }()
    
    lazy var headNameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor.colorWithHexString("#FFFFFF")
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.colorWithHexString("#1E2740", alpha: 0.4)
        self.addSubview(headLabel)
        self.addSubview(headNameLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setupLayout()
    }
    
    func setupLayout() {
        self.headLabel.layer.masksToBounds = true
        self.headLabel.layer.cornerRadius = 14
        self.headLabel.frame = CGRect(x: 3, y: 3, width: 28, height: 28)
        self.headNameLabel.frame = CGRect(x: self.headLabel.frame.maxX + 6, y: 6, width: self.frame.size.width - 31 - 16, height: self.frame.size.height - 12)
    }
    
    private func setHeadUserName(_ userName: String) {
        if userName.count > 0 {
            let firstStr: String = String(userName[userName.startIndex])
            self.headLabel.text = firstStr
        }
        self.headNameLabel.text = userName
    }

}
