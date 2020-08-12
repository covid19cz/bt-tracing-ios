//
//  RiskyEncountersVC.swift
//  BT-Tracking
//
//  Created by Naim Ashhab on 07/08/2020.
//  Copyright © 2020 Covid19CZ. All rights reserved.
//

import UIKit

final class RiskyEncountersPositiveView: UIStackView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
}

final class RiskyEncountersVC: UIViewController {
    @IBOutlet weak var positiveView: RiskyEncountersPositiveView!
    @IBOutlet weak var negativeView: UIStackView!

    @IBOutlet weak var mainSymptomsButton: UIButton!
    @IBOutlet weak var mainSymptomsSeparator: UIView!
    @IBOutlet weak var preventTransmissionButton: UIButton!
    @IBOutlet weak var preventTransmissionSeparator: UIView!
    @IBOutlet weak var previousRiskyEncountersButton: UIButton!
    @IBOutlet weak var previousRiskyEncountersSeparator: UIView!

    private let viewModel = RiskyEncountersVM()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Localizable(viewModel.title)
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeAction))

        positiveView.isHidden = viewModel.riskyEncouterDateToShow == nil
        negativeView.isHidden = !positiveView.isHidden

        [mainSymptomsButton, mainSymptomsSeparator, preventTransmissionButton, preventTransmissionSeparator].forEach {
            $0?.isHidden = positiveView.isHidden
        }
        [previousRiskyEncountersButton, previousRiskyEncountersSeparator].forEach {
            $0?.isHidden = !viewModel.shouldShowPreviousRiskyEncounters
        }

        positiveView.titleLabel.text = viewModel.headline
        positiveView.bodyLabel.text = viewModel.body
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let viewController = segue.destination as? RiskyEncountersListVC else { return }

        if segue.identifier == "mainSymptoms" {
            viewController.viewModel = MainSymptomsVM()
        } else if segue.identifier == "preventTransmission" {
            viewController.viewModel = PreventTransmissionVM()
        }
    }

    @IBAction private func closeAction() {
        dismiss(animated: true)
    }
}
