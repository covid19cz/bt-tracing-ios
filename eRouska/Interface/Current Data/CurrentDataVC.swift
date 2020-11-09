//
//  CurrentDataVC.swift
//  BT-Tracking
//
//  Created by Naim Ashhab on 25/08/2020.
//  Copyright © 2020 Covid19CZ. All rights reserved.
//

import UIKit
import RxSwift
import Reachability

final class CurrentDataVC: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var buttonsView: UIView!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var headlineLabel: UILabel!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var actionButton: Button!

    private let viewModel = CurrentDataVM()
    private let disposeBag = DisposeBag()
    private var observer: NSObjectProtocol?

    override func awakeFromNib() {
        super.awakeFromNib()

        title = L10n.dataListTitle
        tabBarItem.title = L10n.dataListTitle
        tabBarItem.image = Asset.myData.image
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        headlineLabel.text = L10n.errorUnknownHeadline
        textLabel.text = L10n.errorUnknownText
        actionButton.setTitle(L10n.errorUnknownTitleRefresh)

        scrollView.alpha = 0
        buttonsView.alpha = 0

        viewModel.needToUpdateView.subscribe(onNext: { [weak self] in
            self?.hideProgress(fromView: true)
            self?.showError(show: false)
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)

        viewModel.observableErrors.subscribe(onNext: { [weak self] error in
            guard error != nil else { return }

            self?.hideProgress(fromView: true)

            // Don't show error when internet connection is not available
            if let connection = try? Reachability().connection, connection == .unavailable {
                self?.showError(show: false)
                self?.tableView.reloadData()
                return
            }

            self?.showError(show: true)
        }).disposed(by: disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.fetchCurrentDataIfNeeded()

        observer = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: nil) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                self?.viewModel.fetchCurrentDataIfNeeded()
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.sections.isEmpty ? showProgress(fromView: true) : hideProgress(fromView: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        guard let observer = observer else { return }
        NotificationCenter.default.removeObserver(observer)
    }

    // MARK: - Actions

    @IBAction private func toRefresh(_ sender: Any) {
        viewModel.fetchCurrentDataIfNeeded()
    }

}

extension CurrentDataVC: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = viewModel.sections[indexPath.section]
        let item = section.items[indexPath.row]
        let textCell = tableView.dequeueReusableCell(withIdentifier: item.subtitle == nil ? "BasicCell" : "SubtitleCell") as? CurrentDataCell
        textCell?.update(icon: item.iconAsset.image, title: item.title, subtitle: item.subtitle)
        textCell?.selectionStyle = section.selectableItems ? .default : .none
        textCell?.accessoryType = section.selectableItems ? .disclosureIndicator : .none
        return textCell ?? UITableViewCell()
    }
}

extension CurrentDataVC: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let headerTitle = viewModel.sections[section].header {
            let header = tableView.dequeueReusableCell(withIdentifier: "HeaderCell")
            header?.textLabel?.text = headerTitle
            header?.textLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
            header?.textLabel?.textColor = .secondaryLabel
            return header
        } else {
            return nil
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return viewModel.sections[section].header == nil ? 0 : 40
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard indexPath.section == 0, let measuresURL = viewModel.measuresURL else { return }
        openURL(URL: measuresURL)
    }

}

private extension CurrentDataVC {

    func showError(show: Bool, animated: Bool = true) {
        UIView.animate(withDuration: animated ? 0.25 : 0, delay: 0, options: .curveEaseInOut) {
            self.tableView.alpha = show ? 0 : 1

            let alpha: CGFloat = show ? 1 : 0
            self.scrollView.alpha = alpha
            self.buttonsView.alpha = alpha
        }
    }

}
