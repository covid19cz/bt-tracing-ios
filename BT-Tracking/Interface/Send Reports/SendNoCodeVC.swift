//
//  SendNoCodeVC.swift
//  BT-Tracking
//
//  Created by Lukáš Foldýna on 29.01.2021.
//  Copyright © 2021 Covid19CZ. All rights reserved.
//

import UIKit
import DeviceKit

final class SendNoCodeVC: UIViewController {

    // MARK: -

    private let viewModel = SendNoCodeVM()

    private var diagnosis: Diagnosis?

    // MARK: - Outlets

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var headlineLabel: UILabel!
    @IBOutlet private weak var bodyLabel: UILabel!
    @IBOutlet private weak var actionButton: Button!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.dataSendNoCodeTitle
        if Device.current.diagonal < 4.1 {
            navigationItem.largeTitleDisplayMode = .never
        }

        headlineLabel.text = L10n.dataSendNoCodeHeadline
        bodyLabel.text = L10n.dataSendNoCodeBody
        actionButton.setTitle(L10n.dataSendNoCodeActionTitle)
    }

    @IBAction private func supportAction() {
        if Diagnosis.canSendMail {
            diagnosis = Diagnosis(showFromController: self, screenName: .sendNoCode, kind: .noCode)
        } else if let URL = URL(string: "mailto:info@erouska.cz") {
            openURL(URL: URL)
        }
    }

}
