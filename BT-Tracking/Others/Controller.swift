//
//  Controller.swift
//  BT-Tracking
//
//  Created by Lukáš Foldýna on 19/03/2020.
//  Copyright © 2020 Covid19CZ. All rights reserved.
//

import UIKit

extension UIViewController {

    func show(error: Error, title: String = "Chyba") {
        showError(title: title, message: error.localizedDescription)
    }

    func showError(title: String = "Chyba", message: String, okHandler: (() -> Void)? = nil, action: (title: String, handler: (() -> Void)?)? = nil) {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in okHandler?() }))
        action.flatMap({ action in alertController.addAction(UIAlertAction(title: action.title, style: .default, handler: { _ in action.handler?() })) })
        present(alertController, animated: true)
    }

}
