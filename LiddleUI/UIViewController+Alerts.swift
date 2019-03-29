//
//  UIViewController+Alerts.swift
//  Pods
//
//  Created by Peter Liddle on 11/22/16.
//
//

import Foundation

extension UIViewController {
    open func showOKAlert(title : String? = nil, message : String? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
