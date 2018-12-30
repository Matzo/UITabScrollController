//
//  TabScrollHeaderCell.swift
//  Hello
//
//  Created by 松尾 圭祐 on 2018/11/21.
//  Copyright © 2018年 playmotion. All rights reserved.
//

import UIKit

public class TabScrollHeaderCell: UICollectionViewCell {

    public let label = UILabel()
    public let badge = UILabel()
    private var badgeWidth: NSLayoutConstraint?
    private var badgeHeight: NSLayoutConstraint?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    func initialize() {
        self.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.textColor = UIColor.blue
        label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true

        self.addSubview(badge)
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.textColor = UIColor.white
        badge.textAlignment = .center
        badge.layer.borderWidth = 0
        badge.layer.cornerRadius = 4
        badge.clipsToBounds = true
        badge.isHidden = true
        badgeWidth = badge.widthAnchor.constraint(equalToConstant: 8)
        badgeWidth?.isActive = true
        badgeHeight = badge.heightAnchor.constraint(equalToConstant: 8)
        badgeHeight?.isActive = true
        badge.centerYAnchor.constraint(equalTo: label.topAnchor).isActive = true
        badge.leftAnchor.constraint(equalTo: label.rightAnchor, constant: 2).isActive = true
    }

    public func configure(_ item: Any, collectionView: UICollectionView, indexPath: IndexPath) {
        guard let tab = item as? UITabBarItem else { return }
        label.text = tab.title
        badge.backgroundColor = tab.badgeColor ?? UIColor.red
        if let value = tab.badgeValue {
            badge.isHidden = false
            if value.isEmpty {
                badge.text = nil
                badgeWidth?.isActive = true
                badgeHeight?.isActive = true
            } else {
                badge.text = value
                badgeWidth?.isActive = false
                badgeHeight?.isActive = false
            }
        } else {
            badge.isHidden = true
        }
    }
}
