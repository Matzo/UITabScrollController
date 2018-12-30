//
//  ViewController.swift
//  TabScrollController
//
//  Created by 松尾 圭祐 on 2018/11/22.
//  Copyright © 2018年 松尾 圭祐. All rights reserved.
//

import UIKit
import UITabScrollController

class ViewController: UIViewController {

    let tabController = TabScrollController()
        .withOptions([
            .headerBackgroundColor: UIColor.white,
            .isTabAlphaChange: true,
            .hidingDistance: 49,
            .tabItemTitleColor: UIColor.black,
            .tabItemTitleFont: UIFont.systemFont(ofSize: 10),
            .tabItemHeight: 44,
            .headerTitleColor: UIColor.black,
            .headerTitleFont: UIFont.systemFont(ofSize: 16),
            .headerTitleHeight: 44,
            .tabSelectedBarColor: UIColor.green
            ])
    let vc1 = ContentsViewController()
    let vc2 = ContentsViewController()
    let vc3 = ContentsViewController()
    let vc4 = ContentsViewController()
    let vc5 = ContentsViewController()
    let vc6 = ContentsViewController()
    let vc7 = ContentsViewController()
    var vcList: [UIViewController] {
        return [
            self.vc1,
            self.vc2,
            self.vc3,
            self.vc4,
            self.vc5,
            self.vc6,
            self.vc7
        ]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        tabController.delegate = self
        setupViewControllers()
        setupTabController()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        tabController.viewWillTransition(to: size, with: coordinator)
    }

    func setupTabController() {
        tabController.title = "TabScrollController"
        tabController.loadViewIfNeeded()
        view.addSubview(tabController.view)
        tabController.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tabController.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tabController.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        tabController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tabController.setViewControllers(viewControllers: vcList, defaultTab: 0)

        let borderView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 0.5))
        let tabBackgroundView = tabController.headerTab.backgroundView
        borderView.translatesAutoresizingMaskIntoConstraints = false
        borderView.backgroundColor = UIColor.darkGray
        tabBackgroundView.insertSubview(borderView, at: 0)
        borderView.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        borderView.leftAnchor.constraint(equalTo: tabBackgroundView.leftAnchor).isActive = true
        borderView.rightAnchor.constraint(equalTo: tabBackgroundView.rightAnchor).isActive = true
        borderView.bottomAnchor.constraint(equalTo: tabBackgroundView.bottomAnchor).isActive = true

        let leftButton = UIButton(type: .infoLight)
        let rightButton = UIButton(type: .system)
        rightButton.setTitle("Button", for: .normal)
        tabController.setNavigationBarLeftItems(views: [leftButton])
        tabController.setNavigationBarRightItems(views: [rightButton])
    }

    func setupViewControllers() {
        for (index, vc) in vcList.enumerated() {
            vc.loadViewIfNeeded()
            (vc.view as? UITableView)?.delegate = self

            switch index {
            case 0: vc.view.backgroundColor = UIColor.lightGray
            case 1: vc.view.backgroundColor = UIColor.cyan
            case 2: vc.view.backgroundColor = UIColor.orange
            case 3: vc.view.backgroundColor = UIColor.purple
            case 4: vc.view.backgroundColor = UIColor.blue
            case 5: vc.view.backgroundColor = UIColor.darkGray
            case 6: vc.view.backgroundColor = UIColor.brown
            case 7: vc.view.backgroundColor = UIColor.magenta
            default: break
            }

            if index == 3 {
                vc.tabBarItem = UITabBarItem(title: "Long Title Tab Title " + String(describing: index), image: nil, selectedImage: nil)
                vc.tabBarItem.badgeValue = ""
                vc.tabBarItem.badgeColor = UIColor.blue
            } else {
                vc.tabBarItem = UITabBarItem(title: "Tab Title " + String(describing: index), image: nil, selectedImage: nil)
            }

            if index == 0 {
                vc.tabBarItem.badgeValue = ""
                vc.tabBarItem.badgeColor = UIColor.green
            }
            if index == 3 {
                vc.tabBarItem.badgeValue = "3"
                vc.tabBarItem.badgeColor = UIColor.red
            }
        }
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = UIViewController()
        vc.loadViewIfNeeded()
        vc.view.backgroundColor = UIColor.white
        self.present(vc, animated: true) {
            vc.dismiss(animated: true)
        }
    }
}

extension ViewController: TabScrollControllerDelegate {
    func tabScrollControllerDidScrollToUp(tabPagerController: TabScrollController) {
        print("scroll to up")
    }

    func tabScrollControllerDidScrollToDown(tabPagerController: TabScrollController) {
        print("scroll to down")
    }

    func tabScrollController(tabPagerController: TabScrollController, didChangeTabFromIndex fromIndex: Int?, toIndex: Int) {
        print("change tab from: \(fromIndex ?? -1) to: \(toIndex)")
    }
}

