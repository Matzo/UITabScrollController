//
//  TabScrollHeaderView.swift
//  Hello
//
//  Created by 松尾 圭祐 on 2018/11/21.
//  Copyright © 2018年 playmotion. All rights reserved.
//

import UIKit

public protocol TabScrollHeaderViewDelegate: class {
    func tabScrollHeaderView(headerView: TabScrollHeaderView, didSelectRight index: Int)
    func tabScrollHeaderView(headerView: TabScrollHeaderView, didSelectLeft index: Int)
}

public class TabScrollHeaderView: UIView {

    // MARK: Public Properties
    public internal(set) var alwaysDisplay = false
    public internal(set) var stopAnimation = false
    public var height: CGFloat {
        if #available(iOS 11, *) {
            return titleHeight + tabItemHeight
        } else {
            return titleHeight + tabItemHeight + UIApplication.shared.statusBarFrame.size.height
        }
    }
    public internal(set) var titleHeight: CGFloat = 44
    public internal(set) var tabItemHeight: CGFloat = 44
    public var isShrinked: Bool {
        guard let marginTop = self.marginTop else { return false }
        return marginTop.constant < 0
    }

    // MARK: Private Properties
    internal(set) var hidingDistance: CGFloat = 49
    internal var isTabAlphaChange: Bool = true
    internal var headerTitleFont: UIFont = .systemFont(ofSize: 16)
    internal var headerTitleColor: UIColor = .black
    internal var headerBackgroundColor: UIColor = .white
    internal var tabItemTitleFont: UIFont = .systemFont(ofSize: 10)
    internal var tabItemTitleSelectedFont: UIFont = .boldSystemFont(ofSize: 10)
    internal var tabItemTitleColor: UIColor = .gray
    internal var tabItemTitleSelectedColor: UIColor = .black
    internal var tabSelectedBarColor: UIColor = .red
    internal var headerNavigationItemsInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
    internal private(set) var isAnimating: Bool = false
    internal var loopCountBase: Int = 1
    internal var currentScrollView: UIScrollView?
    internal weak var delegate: TabScrollHeaderViewDelegate?

    private var currentIndex: Int = TabScrollController.Const.unspecified
    private var currentLoopIndex: Int {
        if currentIndex == TabScrollController.Const.unspecified {
            return currentIndex
        } else {
            return currentIndex + items.count * loopCountBase
        }
    }
    private var items: [UITabBarItem] = []
    private var loopCount: Int { return 1 + (loopCountBase*2) }
    private var displayLink: CADisplayLink?

    private var isLayoutInitialized: Bool = false
    private var isScrollingByMyself: Bool = false

    private var titleHeightConstraint: NSLayoutConstraint?
    private var tabHeightConstraint: NSLayoutConstraint?

    // MARK: Views
    internal let titleContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }()

    internal let leftBarItemsView = UIStackView()
    internal let rightBarItemsView = UIStackView()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.clear
        label.textAlignment = .center
        return label
    }()

    let collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.minimumInteritemSpacing = 0
            layout.minimumLineSpacing = 0
            layout.sectionInset.left = 0
            layout.sectionInset.right = 0
        }
        collectionView.bounces = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = UIColor.clear
        collectionView.scrollsToTop = false
        return collectionView
    }()

    lazy var progressViews: [UIView] = {
        return (0..<(self.loopCount)).map { _ in
            let progress = UIView()
            progress.backgroundColor = self.tabSelectedBarColor
            return progress
        }
    }()

    public let backgroundView = UIView()

    var marginTop: NSLayoutConstraint?

    // MARK: Initialization
    deinit {
        dispose()
    }

    func dispose() {
        displayLink?.invalidate()
    }

    public func setupViews() {
        if let link = UIScreen.main.displayLink(withTarget: self,
                                                selector: #selector(TabScrollHeaderView.updateTabAlpha)) {
            link.add(to: .current, forMode: .common)
            self.displayLink = link
        }
        translatesAutoresizingMaskIntoConstraints = false
        titleContainerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        leftBarItemsView.translatesAutoresizingMaskIntoConstraints = false
        rightBarItemsView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleContainerView)
        if #available(iOS 11.0, *) {
            titleContainerView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
            titleContainerView.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor).isActive = true
            titleContainerView.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor).isActive = true
        } else {
            let statusBarSize = UIApplication.shared.statusBarFrame.size
            titleContainerView.topAnchor.constraint(equalTo: topAnchor, constant: statusBarSize.height).isActive = true
            titleContainerView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            titleContainerView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        }
        titleHeightConstraint = titleContainerView.heightAnchor.constraint(equalToConstant: titleHeight)
        titleHeightConstraint?.isActive = true

        titleContainerView.addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: titleContainerView.topAnchor).isActive = true
        titleLabel.leftAnchor.constraint(equalTo: titleContainerView.leftAnchor).isActive = true
        titleLabel.rightAnchor.constraint(equalTo: titleContainerView.rightAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: titleContainerView.bottomAnchor).isActive = true

        let inset = headerNavigationItemsInset
        titleContainerView.addSubview(leftBarItemsView)
        leftBarItemsView.spacing = 0
        leftBarItemsView.alignment = .center
        leftBarItemsView.topAnchor.constraint(equalTo: titleContainerView.topAnchor, constant: inset.top).isActive = true
        leftBarItemsView.leftAnchor.constraint(equalTo: titleContainerView.leftAnchor, constant: inset.left).isActive = true
        leftBarItemsView.bottomAnchor.constraint(equalTo: titleContainerView.bottomAnchor, constant: inset.bottom).isActive = true

        titleContainerView.addSubview(rightBarItemsView)
        rightBarItemsView.spacing = 0
        rightBarItemsView.alignment = .center
        rightBarItemsView.topAnchor.constraint(equalTo: titleContainerView.topAnchor, constant: inset.top).isActive = true
        rightBarItemsView.rightAnchor.constraint(equalTo: titleContainerView.rightAnchor, constant: -inset.right).isActive = true
        rightBarItemsView.bottomAnchor.constraint(equalTo: titleContainerView.bottomAnchor, constant: inset.bottom).isActive = true

        addSubview(collectionView)
        collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
        collectionView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        collectionView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        tabHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: tabItemHeight)
        tabHeightConstraint?.isActive = true
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(TabScrollHeaderCell.self, forCellWithReuseIdentifier: String(describing: TabScrollHeaderCell.self))

        for progressView in progressViews {
            progressView.frame.size = CGSize(width: 100, height: 2)
            progressView.backgroundColor = tabSelectedBarColor
            progressView.layer.cornerRadius = 2
            collectionView.addSubview(progressView)
        }

        titleLabel.textColor = headerTitleColor
        titleLabel.font = headerTitleFont

        backgroundColor = UIColor.clear
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(backgroundView, at: 0)
        backgroundView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        backgroundView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        backgroundView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        backgroundView.backgroundColor = headerBackgroundColor
        if isTabAlphaChange {
            backgroundView.alpha = 0
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        titleHeightConstraint?.constant = titleHeight
        tabHeightConstraint?.constant = tabItemHeight
    }

    // MARK: Private Methods
    private func setupTabScrollPosition() {
        guard isLayoutInitialized else { return }
        guard isScrollingByMyself else { return }

        let loopWidth = collectionView.contentSize.width / CGFloat(loopCount)
        let rightBoundary = loopWidth * CGFloat(1 + loopCountBase)// - collectionView.frame.size.width * 0.5
        let leftBoundary = loopWidth * CGFloat(loopCountBase)// dt - collectionView.frame.size.width * 0.5
        if collectionView.contentOffset.x > rightBoundary {
            resetContentOffsetToLeft()
        } else if collectionView.contentOffset.x < leftBoundary {
            resetContentOffsetToRight()
        }
    }

    private func checkNextIsRight(indexPath: IndexPath) -> Bool {
        let toIndex = indexPath.item.quotientAndRemainder(dividingBy: items.count).remainder

        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let visibleProgressView = progressViews.filter { (progressView) -> Bool in
            progressView.frame.intersects(visibleRect)
        }
        if visibleProgressView.count == 1, let attr = collectionView.layoutAttributesForItem(at: indexPath) {
            return visibleProgressView[0].center.x < attr.center.x
        } else {
            let count = CGFloat(items.count)
            let center = count * 0.5
            let deltaCenter = center - CGFloat(currentIndex)
            let toPosition = (CGFloat(toIndex) + deltaCenter + count).truncatingRemainder(dividingBy: count)
            return toPosition > center
        }
    }

    // MARK: Public Methods
    public func setItems(items: [UITabBarItem], defaultIndex: Int = 0) {
        self.items = items
        collectionView.reloadData()
        selectItem(index: defaultIndex)
    }

    public func selectItem(index: Int) {
        currentIndex = index
        collectionView.reloadData()
        collectionView.layoutIfNeeded()

        if isLayoutInitialized {
            setupTabScrollPosition()
        } else {
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.setNeedsLayout()
            collectionView.layoutIfNeeded()
            resetContentOffsetToLeft()
            isLayoutInitialized = true
        }
        resetProgressViews()
    }

    public func updateProgressView(progress: CGFloat) {
        guard currentIndex != TabScrollController.Const.unspecified else { return }
        guard items.count > 0 else { return }
        isScrollingByMyself = false
        guard let attr = collectionView.collectionViewLayout.layoutAttributesForItem(at: IndexPath(item: currentLoopIndex, section: 0)) else { return }
        let loopWidth = collectionView.contentSize.width / CGFloat(loopCount)
        let offset: CGFloat
        let widthDelta: CGFloat

        if progress > 0 {
            // Move To Right
            guard let rightAttr = collectionView.collectionViewLayout.layoutAttributesForItem(at: IndexPath(item: currentLoopIndex + 1, section: 0)) else { return }
            offset = (rightAttr.center.x - attr.center.x) * progress
            widthDelta = (rightAttr.bounds.size.width - attr.bounds.size.width) * progress
        }
        else if progress < 0 {
            // Move To Left
            guard let leftAttr = collectionView.collectionViewLayout.layoutAttributesForItem(at: IndexPath(item: currentLoopIndex - 1, section: 0)) else { return }
            offset = (attr.center.x - leftAttr.center.x) * progress
            widthDelta = (attr.bounds.size.width - leftAttr.bounds.size.width) * progress
        } else {
            offset = 0
            widthDelta = 0
        }
        for (index, progressView) in progressViews.enumerated() {
            progressView.center.x = loopWidth * CGFloat(index) + attr.center.x + offset
            progressView.frame.origin.y = collectionView.bounds.size.height - progressView.frame.size.height
            progressView.bounds.size.width = attr.frame.size.width + widthDelta
        }

        keepCenter(offset: offset)
    }

    func keepCenter(offset: CGFloat = 0) {
        guard let attr = collectionView.collectionViewLayout.layoutAttributesForItem(at: IndexPath(item: currentLoopIndex, section: 0)) else { return }
        let loopWidth = collectionView.contentSize.width / CGFloat(loopCount)
        var baseCenter = attr.center.x - collectionView.frame.size.width * 0.5
        if baseCenter < loopWidth * CGFloat(loopCountBase) {
            baseCenter += loopWidth
        }
        collectionView.setContentOffset(CGPoint(x: baseCenter + offset, y: 0), animated: false)
    }

    func resetContentOffsetToLeft() {
        let loopWidth = collectionView.contentSize.width / CGFloat(loopCount)
        let position = floor(loopWidth * CGFloat(loopCountBase))
        collectionView.contentOffset.x = position
    }

    func resetContentOffsetToRight() {
        let loopWidth = collectionView.contentSize.width / CGFloat(loopCount)
        let position = floor(loopWidth * CGFloat(1 + loopCountBase))
        collectionView.contentOffset.x = position
    }

    func resetProgressViews() {
        guard currentIndex != TabScrollController.Const.unspecified else { return }
        guard let attr = collectionView.collectionViewLayout.layoutAttributesForItem(at: IndexPath(item: currentIndex, section: 0)) else { return }
        let loopWidth = collectionView.contentSize.width / CGFloat(loopCount)
        for (index, progressView) in progressViews.enumerated() {
            progressView.center.x = loopWidth * CGFloat(index) + attr.center.x
            progressView.frame.origin.y = collectionView.bounds.size.height - progressView.frame.size.height
            progressView.bounds.size.width = attr.frame.size.width
            collectionView.bringSubviewToFront(progressView)
        }
        updateProgressView(progress: 0)
    }
    
    public func showHeader() {
        isAnimating = true
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0,
                       options: .curveLinear, animations: {
                        self.marginTop?.constant = 0
                        self.titleContainerView.alpha = 1
                        self.superview?.setNeedsLayout()
                        self.superview?.layoutIfNeeded()
        }, completion: { (done) in
            self.isAnimating = false
        })
    }
    
    public func hideHeader() {
        isAnimating = true
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0,
                       options: .curveEaseIn, animations: {
                        self.marginTop?.constant = -self.hidingDistance
                        self.titleContainerView.alpha = 0
                        self.superview?.setNeedsLayout()
                        self.superview?.layoutIfNeeded()
        }, completion: { (done) in
            self.isAnimating = false
        })
    }

    @objc public func updateTabAlpha() {

        guard isTabAlphaChange else { return }
        guard let scrollView = currentScrollView else { return }

        var alpha: CGFloat = 0
        alpha = max(alpha, calculateTabAlpha(for: scrollView))

        UIView.animate(withDuration: 0.3) {
            self.backgroundView.alpha = alpha
        }
    }

    public func calculateTabAlpha(for scrollView: UIScrollView) -> CGFloat {
        let minY: CGFloat = -TabScrollControllerUtils.adjustedContentInset(from: scrollView).top
        let y = scrollView.contentOffset.y

        let progress = TabScrollControllerUtils.progress(start: minY, end: minY + hidingDistance, current: y, allowOverflow: false)
        let alpha = TabScrollControllerUtils.progressValue(start: 0, end: 1.0, progress: progress)
        return alpha
    }

    public override func removeFromSuperview() {
        super.removeFromSuperview()
        dispose()
    }
}

extension TabScrollHeaderView: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isDragging {
            isScrollingByMyself = true
        }
        setupTabScrollPosition()
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let itemIndex = indexPath.item.quotientAndRemainder(dividingBy: items.count).remainder
        guard currentIndex != itemIndex else { return }

        if checkNextIsRight(indexPath: indexPath) {
            delegate?.tabScrollHeaderView(headerView: self, didSelectRight: itemIndex)
        } else {
            delegate?.tabScrollHeaderView(headerView: self, didSelectLeft: itemIndex)
        }
    }

}

extension TabScrollHeaderView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let index = indexPath.item.quotientAndRemainder(dividingBy: items.count).remainder
        let item = items[index]

        guard let title = item.title else { return CGSize.zero }

        let str: NSString = NSString(string: title)
        let maxSize: CGSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: tabItemHeight)
        let att: [NSAttributedString.Key: Any] = [.font: tabItemTitleFont]
        let rect: CGRect = str.boundingRect(with: maxSize, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: att, context: nil)
        let padding: CGFloat = 16

        return CGSize(width: ceil(rect.size.width) + padding*2, height: tabItemHeight)
    }
}

extension TabScrollHeaderView: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count * loopCount
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = String(describing: TabScrollHeaderCell.self)
        let index = indexPath.item.quotientAndRemainder(dividingBy: items.count).remainder
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        if let cell = cell as? TabScrollHeaderCell {
            let item = items[index]
            if index == currentIndex {
                cell.label.font = tabItemTitleSelectedFont
                cell.label.textColor = tabItemTitleSelectedColor
            } else {
                cell.label.font = tabItemTitleFont
                cell.label.textColor = tabItemTitleColor
            }
            cell.configure(item, collectionView: collectionView, indexPath: indexPath)
        }
        return cell
    }
}
