//
//  roomCell.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/08/13.
//

import UIKit

class roomCell: UITableViewCell {

    @IBOutlet weak var roomThumbnailImageView: UIImageView!
    @IBOutlet weak var roomNameLabel: UILabel!
    @IBOutlet weak var reserveLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var roomOwnerImageView: UIImageView!
    @IBOutlet weak var mainBackground: UIView!
    @IBOutlet weak var shadow: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        //cell自体の設定
        mainBackground.layer.cornerRadius = 20
        mainBackground.layer.masksToBounds = true
        backgroundColor = .systemGray6
        
        //shadowの設定
        shadow.layer.cornerRadius = 20
        shadow.layer.shadowOffset = CGSize(width: 0, height: 0)
        shadow.layer.shadowRadius = 3
        shadow.layer.shadowOpacity = 0.3
        shadow.layer.shadowPath = UIBezierPath(roundedRect: shadow.bounds, byRoundingCorners: .allCorners ,cornerRadii: CGSize(width: 20, height: 20)).cgPath
        shadow.layer.shouldRasterize = true
        shadow.layer.rasterizationScale = UIScreen.main.scale
        //shadow.layer.masksToBounds = true
        
        //roomThumbnailの画像の左上と左下に丸みと枠線を設ける
        roomThumbnailImageView.layer.cornerRadius = 20
        roomThumbnailImageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        roomThumbnailImageView.layer.masksToBounds = true
        //ownerの画像に丸みと枠線を設ける
        roomOwnerImageView.layer.borderColor = UIColor.black.cgColor
        roomOwnerImageView.layer.borderWidth = 3
        roomOwnerImageView.layer.cornerRadius = 22
        roomOwnerImageView.layer.masksToBounds = true
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
