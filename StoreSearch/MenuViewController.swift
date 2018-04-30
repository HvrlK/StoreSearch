//
//  MenuTableViewController.swift
//  StoreSearch
//
//  Created by Vitalii Havryliuk on 4/30/18.
//  Copyright © 2018 Vitalii Havryliuk. All rights reserved.
//

import UIKit

// MARK: - Protocols

protocol MenuViewControllerDelegate: class {
    func menuViewControllerSendSupportEmail(_ controller: MenuViewController)
}

class MenuViewController: UITableViewController {
    
    // MARK: - Properties
    
    weak var delegate: MenuViewControllerDelegate?

    // MARK: - Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {
            delegate?.menuViewControllerSendSupportEmail(self)
        }
    }

}
