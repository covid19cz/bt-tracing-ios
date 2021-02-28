//
//  SendReportsSymptomVC.swift
//  eRouska
//
//  Created by Lukáš Foldýna on 28.02.2021.
//

import UIKit
import Reachability
import RxSwift
import RxRelay
import DeviceKit
import FirebaseCrashlytics

final class SendReportsSymptomVC: BaseController, SendReporting, HasDependencies {

    // MARK: - Dependencies

    typealias Dependencies = HasExposureService & HasVerificationService & HasReportService & HasDiagnosis

    var dependencies: Dependencies!

    // MARK: -

    var sendReport: SendReport?

    // MARK: - Outlets

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var headlineLabel: UILabel!
    @IBOutlet private weak var bodyLabel: UILabel!
    @IBOutlet private weak var enableLabel: UILabel!
    @IBOutlet private weak var enableSwitch: UISwitch!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var datePicker: UIDatePicker!

    @IBOutlet private weak var buttonsView: ButtonsBackgroundView!
    @IBOutlet private weak var buttonsBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var continueButton: Button!

    override func viewDidLoad() {
        super.viewDidLoad()

        isModalInPresentation = true
        navigationItem.hidesBackButton = true
        if Device.current.diagonal < 4.1 {
            navigationItem.largeTitleDisplayMode = .never
        }

        let currentTime = Date.timeIntervalSinceReferenceDate
        datePicker.minimumDate = Date(timeIntervalSinceReferenceDate: currentTime - 10 * 24 * 60 * 60)
        datePicker.maximumDate = Date()

        buttonsView.connect(with: scrollView)
        buttonsBottomConstraint.constant = ButtonsBackgroundView.BottomMargin

        setupStrings()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        let controller = segue.destination as? SendReporting
        controller?.sendReport = sendReport
    }

    // MARK: - Actions

    @IBAction private func continueAction() {
        log("SendReportSymptomVC: data: \(datePicker.date), symptoms: \(enableSwitch.isOn ? "YES" : "NO")")

        sendReport?.symptoms = enableSwitch.isOn
        sendReport?.symptomsDate = datePicker.date
        AppSettings.sendReport = sendReport

        perform(segue: StoryboardSegue.SendReports.efgs)
    }

}

private extension SendReportsSymptomVC {

    // MARK: - Setup

    func setupStrings() {
        title = L10n.dataSendSymptomsTitle

        headlineLabel.text = L10n.dataSendSymptomsHeadline
        enableLabel.text = L10n.dataSendSymptomsEnable
        bodyLabel.text = L10n.dataSendSymptomsBody
        dateLabel.text = L10n.dataSendSymptomsDate
        continueButton.setTitle(L10n.dataSendSymptomsActionContinue)
    }

}