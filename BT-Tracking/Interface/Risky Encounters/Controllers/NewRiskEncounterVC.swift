//
//  NewRiskEncounterVC.swift
//  BT-Tracking
//
//  Created by Lukáš Foldýna on 25/10/2020.
//  Copyright © 2020 Covid19CZ. All rights reserved.
//

import UIKit

final class NewRiskEncounterVC: UIViewController {

    // MARK: -

    private let viewModel = ExposurePermissionVM()

    // MARK: - Outlets

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var headlineLabel: UILabel!
    @IBOutlet private weak var bodyLabel: UILabel!
    @IBOutlet private weak var buttonsView: ButtonsBackgroundView!
    @IBOutlet private weak var continueButton: RoundedButtonFilled!

    // MARK: -

    override func viewDidLoad() {
        super.viewDidLoad()

        buttonsView.connect(with: scrollView)
        setupStrings()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let viewController = segue.destination as? RiskyEncountersListVC else { return }

        switch StoryboardSegue.RiskyEncounters(segue) {
        case .help:
            viewController.viewModel = RiskyEncounterHelpVM()
        default:
            break
        }
    }

}

private extension NewRiskEncounterVC {

    func setupStrings() {
        title = L10n.exposureNotificationTitle
        navigationItem.backBarButtonItem?.title = L10n.back
        navigationItem.rightBarButtonItem?.title = L10n.help

        headlineLabel.text = L10n.exposureNotificationHeadline
        bodyLabel.text = L10n.exposureNotificationBody
        continueButton.setTitle(L10n.exposureNotificationContinue)
    }

}
