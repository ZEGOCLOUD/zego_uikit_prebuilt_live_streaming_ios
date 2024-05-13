//
//  ZegoLiveStreamMemberListCell.swift
//  ZegoUIKitPrebuiltLiveStreaming
//
//  Created by zego on 2022/11/2.
//

import UIKit
import ZegoUIKit

protocol ZegoLiveStreamMemberListCellDelegate: AnyObject {
    func moreButtonDidClick(_ user: ZegoUIKitUser)
    func agreeButtonDidClick(_ user: ZegoUIKitUser)
    func disAgreeButtonDidClick(_ user: ZegoUIKitUser)
}

class ZegoLiveStreamMemberListCell: UITableViewCell {
    
    weak var delegate: ZegoLiveStreamMemberListCellDelegate?
    public var translationText: ZegoTranslationText = ZegoTranslationText(language: .ENGLISH)
    var user: ZegoUIKitUser? {
        didSet {
            guard let userName = user?.userName else { return }
            let firstStr: String = String(userName[userName.startIndex])
            headLabel.text = firstStr
            
            self.nameLabel.text = userName
            let width = self.labelWidth(userName, font: UIFont.systemFont(ofSize: 14), height: 20)
            self.nameLabel.frame = CGRect(x: headLabel.frame.maxX + 12, y: 23.5, width: width, height: 20)

            self.identityLabel.frame = CGRect(x: nameLabel.frame.maxX + 2, y: nameLabel.frame.minY, width: 50, height: 20)
            
            if user?.userID == ZegoUIKit.shared.localUserInfo?.userID {
                //is self
                self.moreButton.isHidden = true
            } else {
                self.moreButton.isHidden = enableCoHosting ? false : true
            }
          self.agreeButton.setTitle(self.translationText.receivedCoHostInvitationDialogInfoConfirm, for: .normal)
          self.disAgreeButton.setTitle(self.translationText.receivedCoHostInvitationDialogInfoCancel, for: .normal)

        }
    }
    
    var enableCoHosting: Bool = true
    
    var currentHost: ZegoUIKitUser?
    
    var isHost: Bool = false {
        didSet {
            self.setUserIdentity(isHost, isCoHost: self.isCoHost, isRequestCoHost: self.isRequestCoHost)
            self.setButtonDisplayStatus(isHost, isCoHost: self.isCoHost, isRequestCoHost: self.isRequestCoHost)
        }
    }
    
    var isCoHost: Bool = false {
        didSet {
            self.setUserIdentity(isHost, isCoHost: isCoHost, isRequestCoHost: isRequestCoHost)
            self.setButtonDisplayStatus(isHost, isCoHost: isCoHost, isRequestCoHost: isRequestCoHost)
        }
    }
    
    var isRequestCoHost: Bool = false {
        didSet {
            self.setUserIdentity(isHost, isCoHost: self.isCoHost, isRequestCoHost: self.isRequestCoHost)
            self.setButtonDisplayStatus(isHost, isCoHost: isCoHost, isRequestCoHost: isRequestCoHost)
        }
    }
    
    lazy var headLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.colorWithHexString("#222222")
        label.backgroundColor = UIColor.colorWithHexString("#DBDDE3")
        return label
    }()
    
    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.white
        return label
    }()
    
    lazy var identityLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.white
        return label
    }()

    
    lazy var moreButton: UIButton = {
        let button = UIButton()
        button.setImage(ZegoUIKitLiveStreamIconSetType.member_more.load(), for: .normal)
        button.addTarget(self, action: #selector(moreButtonClick), for: .touchUpInside)
        return button
    }()
    
    lazy var agreeButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.colorWithHexString("#A754FF")
        button.setTitle(self.translationText.receivedCoHostInvitationDialogInfoConfirm, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.setTitleColor(UIColor.white, for: .normal)
        button.isHidden = true
        button.addTarget(self, action: #selector(agreeClick), for: .touchUpInside)
        return button
    }()
    
    lazy var disAgreeButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.colorWithHexString("#FFFFFF", alpha: 0.1)
        button.setTitle(self.translationText.receivedCoHostInvitationDialogInfoCancel, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.setTitleColor(UIColor.colorWithHexString("#A7A6B7"), for: .normal)
        button.addTarget(self, action: #selector(disAgreeClick), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(self.headLabel)
        self.contentView.addSubview(self.nameLabel)
        self.contentView.addSubview(self.identityLabel)
        self.contentView.addSubview(self.moreButton)
        self.contentView.addSubview(self.agreeButton)
        self.contentView.addSubview(self.disAgreeButton)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setupLayout()
    }
    
    func setupLayout() {
        self.headLabel.frame = CGRect(x: 18, y: 12, width: 46, height: 46)
        self.headLabel.layer.masksToBounds = true
        self.headLabel.layer.cornerRadius = 23
        let width = self.labelWidth(self.user?.userName ?? "", font: UIFont.systemFont(ofSize: 14), height: 20)
        self.nameLabel.frame = CGRect(x: headLabel.frame.maxX + 12, y: 23.5, width: width, height: 20)
        self.identityLabel.frame = CGRect(x: nameLabel.frame.maxX + 2, y: nameLabel.frame.minY, width: 100, height: 20)
        self.moreButton.frame = CGRect(x: self.frame.size.width - 30 - 18, y: 20, width: 30, height: 30)
        self.agreeButton.frame = CGRect(x: self.frame.size.width -  63 - 18, y: 19, width: 63, height: 32)
        self.disAgreeButton.frame = CGRect(x: self.agreeButton.frame.minX - 6 - 82, y: 19, width: 82, height: 32)
        self.agreeButton.layer.masksToBounds = true
        self.agreeButton.layer.cornerRadius = 16
        self.disAgreeButton.layer.masksToBounds = true
        self.disAgreeButton.layer.cornerRadius = 16
    }
    
    func setUserIdentity(_ isHost: Bool, isCoHost: Bool, isRequestCoHost: Bool) {
        if isHost {
            if self.user?.userID == ZegoUIKit.shared.localUserInfo?.userID {
              identityLabel.text = self.translationText.userIdentityYouHost
            } else {
              identityLabel.text = self.translationText.userIdentityHost
            }
        } else if isCoHost {
            if self.user?.userID == ZegoUIKit.shared.localUserInfo?.userID {
              identityLabel.text = self.translationText.userIdentityYouCoHost
            } else {
              identityLabel.text = self.translationText.userIdentityCoHost
            }
        } else if isRequestCoHost {
            if user?.userID == ZegoUIKit.shared.localUserInfo?.userID {
                identityLabel.text = self.translationText.userIdentityYou
            } else {
                identityLabel.text = ""
            }
        } else {
            if user?.userID == ZegoUIKit.shared.localUserInfo?.userID {
                identityLabel.text = self.translationText.userIdentityYou
            } else {
                identityLabel.text = ""
            }
        }
    }
    
    func setButtonDisplayStatus(_ isHost: Bool, isCoHost: Bool, isRequestCoHost: Bool) {
        if ZegoUIKit.shared.localUserInfo?.userID == self.currentHost?.userID {
            if isHost {
                self.moreButton.isHidden = true
                self.agreeButton.isHidden = true
                self.disAgreeButton.isHidden = true
            } else if isCoHost {
                self.moreButton.isHidden = enableCoHosting ? false : true
                self.agreeButton.isHidden = true
                self.disAgreeButton.isHidden = true
                
            } else if isRequestCoHost {
                self.moreButton.isHidden = true
                self.agreeButton.isHidden = false
                self.disAgreeButton.isHidden = false
            } else {
                self.moreButton.isHidden = enableCoHosting ? false : true
                self.agreeButton.isHidden = true
                self.disAgreeButton.isHidden = true
            }
        } else {
            self.moreButton.isHidden = true
            self.agreeButton.isHidden = true
            self.disAgreeButton.isHidden = true
        }
        
    }
    
    func labelWidth(_ text: String, font: UIFont, height: CGFloat)->CGFloat{
        let dic = [NSAttributedString.Key.font : font]
        let size = CGSize(width: 120, height: height)
        let rect = text.boundingRect(with: size, options: [.usesFontLeading,.usesLineFragmentOrigin], attributes: dic, context: nil)
        return CGFloat(ceilf(Float(rect.size.width)))
    }
    
           
     
    @objc func moreButtonClick() {
        guard let user = user else {
            return
        }
        self.delegate?.moreButtonDidClick(user)
    }
    
    @objc func agreeClick() {
        guard let user = user else {
            return
        }
        self.delegate?.agreeButtonDidClick(user)
    }
    
    @objc func disAgreeClick() {
        guard let user = user else {
            return
        }
        self.delegate?.disAgreeButtonDidClick(user)
    }

}
