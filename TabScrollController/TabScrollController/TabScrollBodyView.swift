//
//  TabScrollBodyView.swift
//  Hello
//
//  Created by 松尾 圭祐 on 2018/11/21.
//  Copyright © 2018年 playmotion. All rights reserved.
//

import UIKit

public protocol TabScrollBodyViewDelegate: class {
    func tabScrollBodyView(_ bodyView: TabScrollBodyView, progress: CGFloat)
    func tabScrollBodyView(_ bodyView: TabScrollBodyView, didContentScroll scrollView: UIScrollView)
    func tabScrollBodyViewNeedRight(_ bodyView: TabScrollBodyView) -> UIView?
    func tabScrollBodyViewNeedLeft(_ bodyView: TabScrollBodyView) -> UIView?
    func tabScrollBodyViewReset(_ bodyView: TabScrollBodyView)
}

public class TabScrollBodyView: UIView {

    struct Const {
        static let maxCellCount: Int = 3
    }

    // MARK: Properties
    private var cells: [TabScrollBodyCell] = []
    private let scrollView = UIScrollView()
    private var isLayoutInitialized: Bool = false
    private var isScrollingByMyself: Bool = false
    internal weak var delegate: TabScrollBodyViewDelegate?
    private var disposeBagKVO: [(NSObject, NSObject, String)] = []

    // MARK: Initialization
    public func dispose() {
        for observing in disposeBagKVO {
            observing.1.removeObserver(observing.0, forKeyPath: observing.2, context: nil)
        }
        disposeBagKVO.removeAll()
    }

    public func setupViews() {

        translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isScrollEnabled = true
        scrollView.isPagingEnabled = true
        scrollView.bounces = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.isDirectionalLockEnabled = true
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }

        addSubview(scrollView)
        scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        scrollView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        scrollView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        backgroundColor = UIColor.clear
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        let _isLayoutInitialized = isLayoutInitialized
        isLayoutInitialized = false
        scrollView.contentSize = CGSize(width: bounds.size.width * CGFloat(cells.count), height: bounds.size.height)
        setupCellLayout()
        isLayoutInitialized = _isLayoutInitialized
    }

    // MARK: Private Methods
    fileprivate func setupCellLayout() {
        let size = frame.size
        for (offset, cell) in cells.enumerated() {
            cell.translatesAutoresizingMaskIntoConstraints = true
            cell.frame.origin.y = 0
            cell.frame.origin.x = CGFloat(offset) * size.width
            cell.frame.size = size
        }
    }

    fileprivate func updateCellLayout() {
        guard isLayoutInitialized else { return }
        guard isScrollingByMyself else { return }

        let pageWidth = scrollView.frame.size.width
        if scrollView.contentOffset.x >= pageWidth * 2 {
            if let view = delegate?.tabScrollBodyViewNeedRight(self) {
                pushToRight(view)
                resetContentOffset()
            }
        } else if scrollView.contentOffset.x <= 0 {
            if let view = delegate?.tabScrollBodyViewNeedLeft(self) {
                pushToLeft(view)
                resetContentOffset()
            }
        }

        let progress = (scrollView.contentOffset.x - pageWidth) / pageWidth
        delegate?.tabScrollBodyView(self, progress: progress)
    }

    fileprivate func resetIfNeeded() {
        guard isLayoutInitialized else { return }
        let pageWidth = scrollView.frame.size.width
        if scrollView.contentOffset.x >= pageWidth * 2 {
            resetContentOffset()
            delegate?.tabScrollBodyViewReset(self)
        } else if scrollView.contentOffset.x <= 0 {
            resetContentOffset()
            delegate?.tabScrollBodyViewReset(self)
        }
    }

    // MARK: Public Methods
    public func setViews(_ views: [UIView]) {
        if views == cells.compactMap({ $0.contentView }) { return }

        cells.forEach { $0.removeFromSuperview() }
        let _cells = views.map { TabScrollBodyCell.create(view: $0) }
        _cells.forEach { self.scrollView.addSubview($0) }
        cells = _cells

        if isLayoutInitialized {
            setupCellLayout()
        } else {
            setNeedsLayout()
            layoutIfNeeded()
            resetContentOffset()
            isLayoutInitialized = true
        }
    }

    internal func observeScrollableContents(scrollView: UIScrollView) {
        dispose()
        let keyPath = #keyPath(UIScrollView.contentOffset)
        scrollView.addObserver(self, forKeyPath: keyPath, options: [.new], context: nil)
        disposeBagKVO.append((self, scrollView, keyPath))
    }

    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(UIScrollView.contentOffset), let scrollView = object as? UIScrollView {
            delegate?.tabScrollBodyView(self, didContentScroll: scrollView)
        }
    }

    public func pushToRight(_ view: UIView) {
        let cell = TabScrollBodyCell.create(view: view)
        var _cells = cells
        if _cells.count > 0 {
            _cells.removeFirst().removeFromSuperview()
        }
        _cells.append(cell)
        scrollView.addSubview(cell)
        cells = _cells
        setupCellLayout()
    }

    public func pushToLeft(_ view: UIView) {
        let cell = TabScrollBodyCell.create(view: view)
        var _cells = cells
        if _cells.count > 0 {
            _cells.removeLast().removeFromSuperview()
        }
        _cells.insert(cell, at: 0)
        scrollView.addSubview(cell)
        cells = _cells
        setupCellLayout()
    }

    public func updateRight(_ view: UIView) {
        let cell = TabScrollBodyCell.create(view: view)
        var _cells = cells
        if _cells.count >= Const.maxCellCount {
            _cells.removeLast().removeFromSuperview()
        }
        _cells.append(cell)
        scrollView.addSubview(cell)
        cells = _cells
        setupCellLayout()
    }

    public func updateLeft(_ view: UIView) {
        let cell = TabScrollBodyCell.create(view: view)
        var _cells = cells
        if _cells.count < Const.maxCellCount {
            _cells.insert(cell, at: 0)
        } else {
            _cells[0] = cell
        }
        scrollView.addSubview(cell)
        cells = _cells
        setupCellLayout()
    }

    public func scrollToRight() {
        isScrollingByMyself = false
        scrollView.isUserInteractionEnabled = false
        let width = scrollView.frame.size.width
        scrollView.setContentOffset(CGPoint(x: width * 2, y: 0), animated: true)
    }

    public func scrollToLeft() {
        isScrollingByMyself = false
        scrollView.isUserInteractionEnabled = false
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }

    public func resetContentOffset() {
        scrollView.setContentOffset(CGPoint(x: scrollView.frame.size.width, y: 0), animated: false)
        scrollView.panGestureRecognizer.isEnabled = false
        scrollView.panGestureRecognizer.isEnabled = true
        scrollView.isUserInteractionEnabled = true
        if cells.count >= 2 {
            scrollView.bringSubviewToFront(cells[1])
        }
    }
}

extension TabScrollBodyView: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isDragging {
            isScrollingByMyself = true
        }
        if !isScrollingByMyself {
            resetIfNeeded()
        }

        updateCellLayout()
    }
}
