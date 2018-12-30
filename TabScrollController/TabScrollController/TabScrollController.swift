//
//  TabScrollController.swift
//  Hello
//
//  Created by 松尾 圭祐 on 2018/11/21.
//  Copyright © 2018年 playmotion. All rights reserved.
//

import UIKit

public protocol TabScrollControllerContentScrollable {
    var scrollView: UIScrollView? { get }
}

extension UIViewController {
    var tabScrollController: TabScrollController? {
        if let tab = parent as? TabScrollController {
            guard tab.currentIndex != TabScrollController.Const.unspecified else { return nil }
            return tab
        }
        return nil
    }
}

public protocol TabScrollControllerDelegate: class {
    func tabScrollController(tabPagerController: TabScrollController, didChangeTabFromIndex fromIndex: Int?, toIndex: Int)
    func tabScrollControllerDidScrollToUp(tabPagerController: TabScrollController)
    func tabScrollControllerDidScrollToDown(tabPagerController: TabScrollController)
}

public enum TabScrollControllerOptionsKey {
    case headerTitleColor
    case headerTitleFont
    case headerTitleHeight
    case headerBackgroundColor
    case headerNavigationItemsInset
    case tabItemTitleColor
    case tabItemTitleFont
    case tabItemTitleSelectedColor
    case tabItemTitleSelectedFont
    case tabItemHeight
    case tabSelectedBarColor
    case isTabAlphaChange
    case hidingDistance
}

public typealias TabScrollControllerOptions = [TabScrollControllerOptionsKey: Any]

open class TabScrollController: UIViewController {

    struct Const {
        static let unspecified: Int = -1
    }

    // MARK: Public Properties
    public private(set) var currentIndex: Int = Const.unspecified {
        didSet {
            self.updatePositioning()
            if currentIndex != oldValue {
                didChangeCurrentIndex(from: oldValue, to: currentIndex)
            }
        }
    }

    public var currentViewController: UIViewController? {
        guard children.count > 0 && children.count > currentIndex else { return nil }
        return children[currentIndex]
    }

    public weak var delegate: TabScrollControllerDelegate?

    open override var title: String? {
        didSet {
            self.headerTab.titleLabel.text = title
        }
    }

    // MARK: Private Properties
    private var options: TabScrollControllerOptions = [:] {
        didSet {
            if let value = options[.headerTitleColor] as? UIColor {
                headerTab.headerTitleColor = value
            }
            if let value = options[.headerTitleFont] as? UIFont {
                headerTab.headerTitleFont = value
            }
            if let value = options[.headerBackgroundColor] as? UIColor {
                headerTab.headerBackgroundColor = value
            }
            if let value = options[.headerTitleHeight] as? CGFloat {
                headerTab.titleHeight = value
            }
            if let value = options[.headerNavigationItemsInset] as? UIEdgeInsets {
                headerTab.headerNavigationItemsInset = value
            }
            if let value = options[.tabItemTitleColor] as? UIColor {
                headerTab.tabItemTitleColor = value
            }
            if let value = options[.tabItemTitleFont] as? UIFont {
                headerTab.tabItemTitleFont = value
            }
            if let value = options[.tabItemTitleSelectedColor] as? UIColor {
                headerTab.tabItemTitleSelectedColor = value
            }
            if let value = options[.tabItemTitleSelectedFont] as? UIFont {
                headerTab.tabItemTitleSelectedFont = value
            }
            if let value = options[.tabItemHeight] as? CGFloat {
                headerTab.tabItemHeight = value
            }
            if let value = options[.tabSelectedBarColor] as? UIColor {
                headerTab.tabSelectedBarColor = value
            }
            if let value = options[.isTabAlphaChange] as? Bool {
                headerTab.isTabAlphaChange = value
            }
            if let value = options[.hidingDistance] as? CGFloat {
                headerTab.hidingDistance = value
            }
        }
    }

    private var disposeBagKVO: [(NSObject, NSObject, String)] = []
    private var lastContentOffset: CGPoint = CGPoint.zero
    private var isViewTransitioning: Bool = true

    // MARK: UI
    public let headerTab = TabScrollHeaderView()
    public let contentView = TabScrollBodyView()

    // MARK: Initialization
    deinit {
        dispose()
    }

    private func dispose() {
        headerTab.dispose()
        contentView.dispose()
    }

    // MARK: UIViewController Lifecycle
    open override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        headerTab.setupViews()
        contentView.setupViews()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        isViewTransitioning = true
    }

    open override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        isViewTransitioning = true
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if isViewTransitioning {
            headerTab.setNeedsLayout()
            headerTab.layoutIfNeeded()
            headerTab.resetProgressViews()

            contentView.setNeedsLayout()
            contentView.layoutIfNeeded()
            contentView.resetContentOffset()
        }
        isViewTransitioning = false
    }

    // MARK: Private Methods
    private func setupViews() {
        view.addSubview(headerTab)
        headerTab.marginTop = headerTab.topAnchor.constraint(equalTo: view.topAnchor)
        headerTab.marginTop?.isActive = true
        headerTab.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        headerTab.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true

        view.addSubview(contentView)
        contentView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        contentView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        contentView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        view.bringSubviewToFront(headerTab)
        headerTab.titleLabel.text = title
        headerTab.delegate = self
        contentView.delegate = self
    }

    private func resetViewControllers() {
        guard self.isViewLoaded else { return }
        if currentIndex == Const.unspecified {
            return
        }

        let left = children[(currentIndex + children.count - 1).quotientAndRemainder(dividingBy: children.count).remainder]
        let center = children[currentIndex]
        let right = children[(currentIndex + 1).quotientAndRemainder(dividingBy: children.count).remainder]

        left.loadViewIfNeeded()
        center.loadViewIfNeeded()
        right.loadViewIfNeeded()

        if left.isViewLoaded && center.isViewLoaded && right.isViewLoaded {
            contentView.setViews([left.view, center.view, right.view])
        }
        contentView.resetContentOffset()
    }

    private func moveViewControllerToRight(_ toIndex: Int) {
        let vc = children[toIndex]
        vc.loadViewIfNeeded()
        contentView.updateRight(vc.view)
        contentView.scrollToRight()
    }

    private func moveViewControllerToLeft(_ toIndex: Int) {
        let vc = children[toIndex]
        vc.loadViewIfNeeded()
        contentView.updateLeft(vc.view)
        contentView.scrollToLeft()
    }

    private func updatePositioning() {
        guard let vc = children[currentIndex] as? TabScrollControllerContentScrollable else { return }
        guard let scrollView = vc.scrollView else { return }
        lastContentOffset = scrollView.contentOffset
        headerTab.currentScrollView = scrollView
        contentView.observeScrollableContents(scrollView: scrollView)
    }

    fileprivate func observeScrollView(scrollView: UIScrollView, contentOffset: CGPoint) {
        guard scrollView.contentSize.height > 0 else { return }
        guard !headerTab.isAnimating else { return }

        let point = contentOffset
        let inset = TabScrollControllerUtils.adjustedContentInset(from: scrollView)
        let minY: CGFloat = -inset.top
        let maxY: CGFloat = scrollView.contentSize.height - scrollView.bounds.size.height + inset.bottom
        let currentPoint = CGPoint(x: point.x, y: max(minY, min(maxY, point.y)))

        if lastContentOffset.y < minY {
            lastContentOffset.y = minY
        }
        guard abs(lastContentOffset.y - currentPoint.y) > 10 else { return }

        if !headerTab.stopAnimation {
            if lastContentOffset.y < currentPoint.y {
                if headerTab.alwaysDisplay {
                    if headerTab.isShrinked {
                        headerTab.showHeader()
                        delegate?.tabScrollControllerDidScrollToUp(tabPagerController: self)
                    }
                } else {
                    if !headerTab.isShrinked {
                        headerTab.hideHeader()
                        delegate?.tabScrollControllerDidScrollToDown(tabPagerController: self)
                    }
                }
            } else {
                if headerTab.isShrinked {
                    headerTab.showHeader()
                    delegate?.tabScrollControllerDidScrollToUp(tabPagerController: self)
                }
            }
        }
        lastContentOffset = currentPoint
    }

    private func adjustContentOffset() {
        if headerTab.isShrinked {
            children.forEach({ (vc) in
                if vc == self.currentViewController { return }
                guard let scrollView = (vc as? TabScrollControllerContentScrollable)?.scrollView else { return }
                let minY = -TabScrollControllerUtils.adjustedContentInset(from: scrollView).top
                    + headerTab.hidingDistance
                if scrollView.contentOffset.y < minY {
                    scrollView.contentOffset.y = minY
                }
            })
        } else {
            children.forEach({ (vc) in
                if vc == self.currentViewController { return }
                guard let scrollView = (vc as? TabScrollControllerContentScrollable)?.scrollView else { return }
                let minY = -TabScrollControllerUtils.adjustedContentInset(from: scrollView).top
                if scrollView.contentOffset.y <= minY + headerTab.hidingDistance {
                    scrollView.contentOffset.y = minY
                }
            })
        }
    }

    private func updateContentInset() {
        children.forEach { (vc) in
            guard let vc = vc as? TabScrollControllerContentScrollable else { return }
            vc.scrollView?.contentInset.top = headerTab.height
            let insetTop = headerTab.height
            vc.scrollView?.setContentOffset(CGPoint(x: 0, y: -insetTop), animated: false)
        }
    }

    private func didChangeCurrentIndex(from: Int, to: Int) {
        let fromIndex = (from == Const.unspecified) ? nil : from
        delegate?.tabScrollController(tabPagerController: self, didChangeTabFromIndex: fromIndex, toIndex: to)
    }

    // MARK: Public Methods
    public func withOptions(_ options: TabScrollControllerOptions) -> TabScrollController {
        self.options = options
        return self
    }

    public func setViewControllers(viewControllers: [UIViewController], defaultTab: Int = 0) {
        for vc in viewControllers {
            self.addChild(vc)
        }

        headerTab.setItems(items: viewControllers.compactMap({ $0.tabBarItem }), defaultIndex: defaultTab)
        select(tabIndex: defaultTab)

        // layout
        updateContentInset()
        updatePositioning()
    }

    public func setNavigationBarRightItems(views: [UIView]) {
        headerTab.rightBarItemsView.arrangedSubviews.forEach({ $0.removeFromSuperview() })
        for view in views {
            headerTab.rightBarItemsView.addArrangedSubview(view)
        }
    }

    public func setNavigationBarLeftItems(views: [UIView]) {
        headerTab.leftBarItemsView.arrangedSubviews.forEach({ $0.removeFromSuperview() })
        for view in views {
            headerTab.leftBarItemsView.addArrangedSubview(view)
        }
    }

    public func select(tabIndex: Int) {
        guard children.count > tabIndex else { return }
        self.currentIndex = tabIndex
        headerTab.selectItem(index: tabIndex)
        resetViewControllers()
    }

    public func selectMoveToRight(_ tabIndex: Int) {
        guard children.count > tabIndex else { return }
        resetViewControllers()
        self.currentIndex = tabIndex
        headerTab.selectItem(index: tabIndex)
        moveViewControllerToRight(tabIndex)
    }

    public func selectMoveToLeft(_ tabIndex: Int) {
        guard children.count > tabIndex else { return }
        resetViewControllers()
        self.currentIndex = tabIndex
        headerTab.selectItem(index: tabIndex)
        moveViewControllerToLeft(tabIndex)
    }

    public func select(viewController: UIViewController) {
        for (index, vc) in children.enumerated() {
            if vc == viewController {
                select(tabIndex: index)
                return
            }
        }
    }
}

// MARK: TabScrollHeaderViewDelegate
extension TabScrollController: TabScrollHeaderViewDelegate {
    public func tabScrollHeaderView(headerView: TabScrollHeaderView, didSelectRight index: Int) {
        adjustContentOffset()
        selectMoveToRight(index)
    }

    public func tabScrollHeaderView(headerView: TabScrollHeaderView, didSelectLeft index: Int) {
        adjustContentOffset()
        selectMoveToLeft(index)
    }
}

extension TabScrollController: TabScrollBodyViewDelegate {
    public func tabScrollBodyView(_ bodyView: TabScrollBodyView, progress: CGFloat) {
        headerTab.updateProgressView(progress: progress)
        adjustContentOffset()
    }

    public func tabScrollBodyViewNeedRight(_ bodyView: TabScrollBodyView) -> UIView? {
        let rightIndex = (currentIndex + 2).quotientAndRemainder(dividingBy: children.count).remainder
        currentIndex = (currentIndex + 1).quotientAndRemainder(dividingBy: children.count).remainder
        let vc = children[rightIndex]
        vc.loadViewIfNeeded()
        headerTab.selectItem(index: currentIndex)
        return vc.view
    }

    public func tabScrollBodyViewNeedLeft(_ bodyView: TabScrollBodyView) -> UIView? {
        let leftIndex = (children.count + currentIndex - 2).quotientAndRemainder(dividingBy: children.count).remainder
        currentIndex = (children.count + currentIndex - 1).quotientAndRemainder(dividingBy: children.count).remainder
        let vc = children[leftIndex]
        vc.loadViewIfNeeded()
        headerTab.selectItem(index: currentIndex)
        return vc.view
    }

    public func tabScrollBodyViewReset(_ bodyView: TabScrollBodyView) {
        resetViewControllers()
    }

    public func tabScrollBodyView(_ bodyView: TabScrollBodyView, didContentScroll scrollView: UIScrollView) {
        observeScrollView(scrollView: scrollView, contentOffset: scrollView.contentOffset)
    }
}
