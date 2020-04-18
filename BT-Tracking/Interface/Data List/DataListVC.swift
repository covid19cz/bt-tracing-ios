//
//  DataListVC.swift
//  BT-Tracking
//
//  Created by Lukáš Foldýna on 23/03/2020.
//  Copyright © 2020 Covid19CZ. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
#if !targetEnvironment(macCatalyst)
import FirebaseAuth
import FirebaseStorage
#endif
import Reachability

final class DataListVC: UIViewController, UITableViewDelegate {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var buttonsView: ButtonsBackgroundView!
    
    private var dataSource: RxTableViewSectionedAnimatedDataSource<DataListVM.SectionModel>!
    private let viewModel = DataListVM()
    private let bag = DisposeBag()

    private var writer: CSVMakering?

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()

        setupTabBar()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        buttonsView.connect(with: tableView)
        buttonsView.defaultContentInset.bottom += 10
        buttonsView.resetInsets(in: tableView)
        
        setupTableView()
        viewModel.selectedSegmentIndex.accept(0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let indexPath = tableView.indexPathForSelectedRow else { return }
        tableView.deselectRow(at: indexPath, animated: animated)
    }

    // MARK: - TableView

    private func setupTabBar() {
        if #available(iOS 13, *) {
            navigationController?.tabBarItem.image = UIImage(systemName: "doc.plaintext")
        } else {
            navigationController?.tabBarItem.image = UIImage(named: "doc.plaintext")?.resize(toWidth: 20)
        }
    }

    private func setupTableView() {
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableView.automaticDimension

        dataSource = RxTableViewSectionedAnimatedDataSource<DataListVM.SectionModel>(configureCell: { datasource, tableView, indexPath, row in
            let cell: UITableViewCell?
            switch row {
            case .scanningInfo:
                let scanningInfoCell = tableView.dequeueReusableCell(withIdentifier: ScanningInfoCell.identifier, for: indexPath) as? ScanningInfoCell
                cell = scanningInfoCell
            case .aboutData:
                let aboutDataCell = tableView.dequeueReusableCell(withIdentifier: AboutDataCell.identifier, for: indexPath) as? AboutDataCell
                cell = aboutDataCell
            case .header:
                let headerCell = tableView.dequeueReusableCell(withIdentifier: DataHeaderCell.identifier, for: indexPath) as? DataHeaderCell
                headerCell?.configure()
                cell = headerCell
            case .data(let scan):
                let scanCell = tableView.dequeueReusableCell(withIdentifier: DataCell.identifier, for: indexPath) as? DataCell
                scanCell?.configure(for: scan)
                cell = scanCell
            }
            return cell ?? UITableViewCell()
        })

        viewModel.sections
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: bag)

        tableView.rx.setDelegate(self)
            .disposed(by: bag)
        
        tableView.rx.modelSelected(DataListVM.Section.Item.self)
            .filter { $0 == .aboutData }
            .subscribe(onNext: { [weak self] _ in
                self?.navigationController?.pushViewController(DataCollectionInfoVC(), animated: true)
            })
            .disposed(by: bag)

        dataSource.animationConfiguration = AnimationConfiguration(insertAnimation: .fade, reloadAnimation: .none, deleteAnimation: .fade)
    }

    // MARK: - Actions

    @IBAction private func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        viewModel.selectedSegmentIndex.accept(sender.selectedSegmentIndex)
    }

    @IBAction private func sendReportAction() {
        let controller = UIAlertController(
            title: "Požádal vás pracovník hygienické stanice o zaslání seznamu telefonů, se kterými jste se setkali?",
            message: "S odeslanými daty bude Ministerstvo zdravotnictví a jemu podřízení hygienici pracovat na základě vašeho souhlasu podle podmínek zpracování.",
            preferredStyle: .alert
        )
        controller.addAction(UIAlertAction(title: "Ano, odeslat", style: .default, handler: { [weak self] _ in
            self?.sendReport()
        }))
        controller.addAction(UIAlertAction(title: "Ne", style: .cancel, handler: { _ in
            self.showError(
                title: "Sdílejte data jen v případě, že vás pracovník hygienické stanice poprosí o jejich zaslání. To se stane pouze tehdy, když budete v okruhu lidí nakažených koronavirem, nebo test prokáže vaši nákazu",
                message: ""
            )
        }))
        controller.preferredAction = controller.actions.first
        present(controller, animated: true)
    }

}

private extension DataListVC {

    func sendReport() {
        guard (AppSettings.lastUploadDate ?? Date.distantPast) + RemoteValues.uploadWaitingMinutes < Date() else {
            showError(
                title: "Data jsme už odeslali. Prosím počkejte 15 minut a pošlete je znovu.",
                message: ""
            )
            return
        }

        guard let connection = try? Reachability().connection, connection != .unavailable else {
            showError(
                title: "Nepodařilo se nám odeslat data",
                message: "Zkontrolujte připojení k internetu a zkuste to znovu"
            )
            return
        }

        createCSVFile()
    }

    func createCSVFile() {
        showProgress()

        let fileDate = Date()

        writer = CSVMaker(fromDate: nil) // AppSettings.lastUploadDate, set to last upload date, if we want increment upload
        writer?.createFile(callback: { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                self.uploadCSVFile(fileURL: result.fileURL, metadata: result.metadata, fileDate: fileDate)
            } else if let error = error {
                self.hideProgress()
                self.show(error: error, title: "Nepodařilo se vytvořit soubor se setkáními")
            }
        })
    }

    func uploadCSVFile(fileURL: URL, metadata: [String: String], fileDate: Date) {
        let path = "proximity/\(Auth.auth().currentUser?.uid ?? "")/\(KeychainService.BUID ?? "")"
        let fileName = "\(Int(fileDate.timeIntervalSince1970 * 1000)).csv"

        let storage = Storage.storage()
        let storageReference = storage.reference()
        let fileReference = storageReference.child("\(path)/\(fileName)")
        let storageMetadata = StorageMetadata()
        storageMetadata.customMetadata = metadata

        fileReference.putFile(from: fileURL, metadata: storageMetadata) { [weak self] metadata, error in
            guard let self = self else { return }
            self.hideProgress()

            self.writer?.deleteFile()
            if let error = error {
                log("FirebaseUpload: Error \(error.localizedDescription)")

                self.showError(
                    title: "Nepodařilo se nám odeslat data",
                    message: "Zkontrolujte připojení k internetu a zkuste to znovu"
                )
                return
            }
            AppSettings.lastUploadDate = fileDate
            self.performSegue(withIdentifier: "sendReport", sender: nil)
        }
    }

}
