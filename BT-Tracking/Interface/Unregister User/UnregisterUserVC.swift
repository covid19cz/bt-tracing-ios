//
//  UnregisterUserVC.swift
//  BT-Tracking
//
//  Created by Lukáš Foldýna on 30/03/2020.
//  Copyright © 2020 Covid19CZ. All rights reserved.
//

import FirebaseAuth
import UIKit

final class UnregisterUserVC: UIViewController {
    @IBOutlet private var activityView: UIView!
    @IBOutlet private var textLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        textLabel.text = textLabel.text?.replacingOccurrences(of: "%@", with: Auth.auth().currentUser?.phoneNumber?.phoneFormatted ?? "")
    }

    // MARK: - Actions

    @IBAction private func unregisterAction() {
        activityView.isHidden = false

        AppDelegate.shared.functions.httpsCallable("deleteUser").call { [weak self] _, error in
            guard let self = self else { return }
            self.activityView.isHidden = true

            if let error = error as NSError? {
                Log.log("deleteUser request failed with error: \(error.localizedDescription)")
                self.show(error: error, title: "Chyba při zrušení registrace")
                return
            }

            FileLogger.shared.purgeLogs()
            Log.log("deleteUser request success finished")

            AppDelegate.shared.advertiser.stop()
            AppDelegate.shared.scanner.stop()
            AppDelegate.shared.scannerStore.deleteAllData()

            AppSettings.deleteAllData()

            self.performSegue(withIdentifier: "finish", sender: nil)
        }
    }
}
