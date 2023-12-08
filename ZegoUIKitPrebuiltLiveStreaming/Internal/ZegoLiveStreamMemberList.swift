//
//  ZegoLiveStreamMemberList.swift
//  ZegoUIKitPrebuiltLiveStreaming
//
//  Created by zego on 2022/11/2.
//

import UIKit
import ZegoUIKit

protocol ZegoLiveStreamMemberListDelegate: AnyObject {
    func memberListDidClickMoreButton(_ user: ZegoUIKitUser)
    func memberListDidClickAgree(_ user: ZegoUIKitUser)
    func memberListDidClickDisagree(_ user: ZegoUIKitUser)
}

class ZegoLiveStreamMemberList: UIView {
    
    weak var delegate: ZegoLiveStreamMemberListDelegate?
    
    var translationText: ZegoTranslationText?
    
    var requestCoHostList: [ZegoUIKitUser]? {
        didSet {
            self.reloadMemberList()
        }
    }
    var coHostList: [ZegoUIKitUser] = [] {
        didSet {
            self.reloadMemberList()
        }
    }
    var currentHost: ZegoUIKitUser? {
        didSet {
            self.reloadMemberList()
        }
    }
    
    var config: ZegoUIKitPrebuiltLiveStreamingConfig?
    
    lazy var tapView: UIView = {
        let view = UIView()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(tapClick))
        view.addGestureRecognizer(tap)
        return view
    }()
    
    lazy var memberListView: ZegoMemberList = {
        let listView = ZegoMemberList()
        listView.delegate = self
        listView.registerCell(ZegoLiveStreamMemberListCell.self, forCellReuseIdentifier: "ZegoLiveStreamMemberListCell")
        return listView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.tapView)
        self.addSubview(self.memberListView)
        self.memberListView.tableView.backgroundColor = UIColor.colorWithHexString("#222222")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tapClick() {
        self.removeFromSuperview()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let height: CGFloat = self.frame.size.height * 0.6
        self.tapView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height - height)
        self.memberListView.frame = CGRect(x: 0, y: self.frame.size.height - height, width: self.frame.size.width, height: self.frame.size.height * 0.6)
        self.memberListView.cornerCut(16, corner: [.topLeft,.topRight])
    }
    
    func reloadMemberList() {
        self.memberListView.reloadData()
    }
    
    func isRequestCoHost(_ userInfo: ZegoUIKitUser) -> Bool {
        var isRequestCoHost: Bool = false
        guard let requestCoHostList = requestCoHostList else {
            return isRequestCoHost
        }
        for user in requestCoHostList {
            if userInfo.userID == user.userID && userInfo.userID != self.currentHost?.userID {
                isRequestCoHost = true
                break
            }
        }
        return isRequestCoHost
    }
    
    func isCoHost(_ userInfo: ZegoUIKitUser) -> Bool {
        var isCoHost: Bool = false
        for user in self.coHostList {
            if userInfo.userID == user.userID && userInfo.userID != self.currentHost?.userID {
                isCoHost = true
                break
            }
        }
        return isCoHost
    }

}

extension ZegoLiveStreamMemberList: ZegoMemberListDelegate, ZegoLiveStreamMemberListCellDelegate {
    
    //MARK: -ZegoLiveStreamMemberListCellDelegate
    func moreButtonDidClick(_ user: ZegoUIKitUser) {
        self.delegate?.memberListDidClickMoreButton(user)
        self.removeFromSuperview()
    }
    
    func agreeButtonDidClick(_ user: ZegoUIKitUser) {
        guard let userID = user.userID else { return }
        ZegoLiveStreamingManager.shared.getSignalingPlugin()?.acceptInvitation(userID, data: nil, callback: nil)
        self.requestCoHostList = self.requestCoHostList?.filter{
            return $0.userID != user.userID
        }
        self.memberListView.tableView.reloadData()
        self.delegate?.memberListDidClickAgree(user)
        
    }
    
    func disAgreeButtonDidClick(_ user: ZegoUIKitUser) {
        guard let userID = user.userID else { return }
        ZegoLiveStreamingManager.shared.getSignalingPlugin()?.refuseInvitation(userID, data: nil)
        self.requestCoHostList = self.requestCoHostList?.filter{
            return $0.userID != user.userID
        }
        self.memberListView.tableView.reloadData()
        self.delegate?.memberListDidClickDisagree(user)
        
    }
    
    //MARK: -ZegoMemberListDelegate
    
    func getMemberListItemView(_ tableView: UITableView, indexPath: IndexPath, userInfo: ZegoUIKitUser) -> UITableViewCell? {
        let cell: ZegoLiveStreamMemberListCell = tableView.dequeueReusableCell(withIdentifier: "ZegoLiveStreamMemberListCell") as! ZegoLiveStreamMemberListCell
        cell.selectionStyle = .none
        cell.enableCoHosting = self.config?.enableCoHosting ?? true
        cell.delegate = self
        cell.user = userInfo
        cell.currentHost = self.currentHost
        cell.backgroundColor = UIColor.clear
        cell.isHost = self.currentHost?.userID == userInfo.userID
        cell.isRequestCoHost = self.isRequestCoHost(userInfo)
        cell.isCoHost = self.isCoHost(userInfo)
        return cell
    }
    
    func getMemberListItemHeight(_ userInfo: ZegoUIKitUser) -> CGFloat {
        return 70
    }
    
    func getMemberListviewForHeaderInSection(_ tableView: UITableView, section: Int) -> UIView? {
        let view = UIView()
        let label = UILabel()
        label.frame = CGRect(x: 16, y: 26, width: 150, height: 22)
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 16)
        label.text = String(format: "%@·%d", self.translationText?.memberListTitle ?? "Audience",ZegoUIKit.shared.getAllUsers().count)
        view.addSubview(label)
        return view
    }
    
    func getMemberListHeaderHeight(_ tableView: UITableView, section: Int) -> CGFloat {
        return 58
    }
    
    func sortUserList(_ userList: [ZegoUIKitUser]) -> [ZegoUIKitUser] {
        var newUserList: [ZegoUIKitUser] = []
        var host: ZegoUIKitUser?
        var mySelf: ZegoUIKitUser?
        var coHostUserList: [ZegoUIKitUser] = []
        var requestCoHostUserList: [ZegoUIKitUser] = []
        var audienceUserList: [ZegoUIKitUser] = []
        for user in userList {
            if user.userID == self.currentHost?.userID {
                host = user
            } else if user.userID == ZegoUIKit.shared.localUserInfo?.userID {
                mySelf = user
            } else if isCoHost(user) {
                coHostUserList.append(user)
            } else if isRequestCoHost(user) {
                requestCoHostUserList.append(user)
            } else {
                audienceUserList.append(user)
            }
        }
        if let host = host {
            newUserList.append(host)
        }
        if let mySelf = mySelf {
            if mySelf.userID != host?.userID {
                newUserList.append(mySelf)
            }
        }
        newUserList.append(contentsOf: coHostUserList)
        newUserList.append(contentsOf: requestCoHostUserList)
        newUserList.append(contentsOf: audienceUserList)
        return newUserList
    }

}
