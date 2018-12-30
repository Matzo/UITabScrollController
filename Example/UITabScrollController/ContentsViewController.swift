//
//  ContentsViewController.swift
//  TabScrollController
//
//  Created by Matsuo Keisuke on 11/28/18.
//  Copyright © 2018 松尾 圭祐. All rights reserved.
//

import UIKit
import UITabScrollController

class ContentsViewController: UITableViewController {

    var items: [Int] = {
        return (0...50).map({ $0 })
    }()
        
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
        self.tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...
        let item = items[indexPath.row]
        cell.textLabel?.text = "item: \(item)"
        cell.backgroundColor = UIColor.clear

        return cell
    }

}

extension ContentsViewController: TabScrollControllerContentScrollable {
    var scrollView: UIScrollView? {
        return tableView
    }
}
