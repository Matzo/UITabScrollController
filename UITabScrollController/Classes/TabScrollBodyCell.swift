//
//  TabScrollBodyCell.swift
//  Hello
//
//  Created by 松尾 圭祐 on 2018/11/21.
//  Copyright © 2018年 playmotion. All rights reserved.
//

import UIKit

class TabScrollBodyCell: UIView {

    // MARK: Properties
    var contentView: UIView?

    // MARK: Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    // MARK: Private Methods
    func initialize() {
        self.translatesAutoresizingMaskIntoConstraints = false
    }

    func setupView(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        contentView = view

        addSubview(view)
        view.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        view.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
    }

    // MARK: Public Methods
    static func create(view: UIView) -> TabScrollBodyCell {
        let cell = TabScrollBodyCell()
        cell.setupView(view)
        return cell
    }
}
