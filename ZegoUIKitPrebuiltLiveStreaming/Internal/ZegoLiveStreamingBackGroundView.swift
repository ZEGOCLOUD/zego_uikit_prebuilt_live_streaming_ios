//
//  ZegoLiveStreamingBackGroundView.swift
//  ZegoUIKitPrebuiltLiveStreaming
//
//  Created by zego on 2023/2/7.
//

import UIKit

class ZegoLiveStreamingBackGroundView: UIView {
    
    var config: ZegoUIKitPrebuiltLiveStreamingConfig? {
        didSet {
            if config?.role == .host {
                //hiden background
                self.backgroundImageView.isHidden = true
                self.roomTipLabel.isHidden = true
                self.customBackGroundView?.isHidden = true
            } else {
                if liveStatus != "1" {
                    self.backgroundImageView.isHidden = false
                    self.roomTipLabel.isHidden = false
                    self.customBackGroundView?.isHidden = false
                } else {
                    self.backgroundImageView.isHidden = true
                    self.roomTipLabel.isHidden = true
                    self.customBackGroundView?.isHidden = true
                }
            }
            self.roomTipLabel.text = config?.translationText.noHostOnline
        }
    }
    
    var liveStatus: String? {
        didSet {
            if let config = config {
                if config.role != .host {
                    if liveStatus != "1" {
                        self.backgroundImageView.isHidden = false
                        self.roomTipLabel.isHidden = false
                        self.customBackGroundView?.isHidden = false
                    } else {
                        self.backgroundImageView.isHidden = true
                        self.roomTipLabel.isHidden = true
                        self.customBackGroundView?.isHidden = true
                    }
                } else {
                    self.backgroundImageView.isHidden = true
                    self.roomTipLabel.isHidden = true
                    self.customBackGroundView?.isHidden = true
                }
            } else {
                if liveStatus != "1" {
                    self.backgroundImageView.isHidden = false
                    self.roomTipLabel.isHidden = false
                    self.customBackGroundView?.isHidden = false
                } else {
                    self.backgroundImageView.isHidden = true
                    self.roomTipLabel.isHidden = true
                    self.customBackGroundView?.isHidden = true
                }
            }
        }
    }
    
    lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = ZegoUIKitLiveStreamIconSetType.live_background_image.load()
        return imageView
    }()
    
    lazy var roomTipLabel: UILabel = {
        let label: UILabel = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = self.config?.translationText.noHostOnline
        label.textColor = UIColor.colorWithHexString("#FFFFFF")
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    var customBackGroundView: UIView?
    
    public init(frame: CGRect,config: ZegoUIKitPrebuiltLiveStreamingConfig?) {
        super.init(frame: frame)
        if  config != nil{
          self.config = config
        }
        self.addSubview(backgroundImageView)
        self.addSubview(roomTipLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundImageView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        self.roomTipLabel.center = CGPoint(x: self.bounds.size.width * 0.5, y: self.bounds.size.height * 0.5)
        self.roomTipLabel.bounds = CGRect(x: 0, y: 0, width: 180, height: 50)
        self.customBackGroundView?.frame = CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height)
    }
    
    func setCustomBackGroundView(view: UIView) {
        self.customBackGroundView = view
        self.backgroundImageView.removeFromSuperview()
        self.roomTipLabel.removeFromSuperview()
        self.addSubview(view)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return nil
    }

}
