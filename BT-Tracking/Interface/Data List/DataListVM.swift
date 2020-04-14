//
//  DataListVM.swift
//  BT-Tracking
//
//  Created by Lukáš Foldýna on 23/03/2020.
//  Copyright © 2020 Covid19CZ. All rights reserved.
//

import RealmSwift
import RxCocoa
import RxDataSources
import RxRealm
import RxSwift

final class DataListVM {
    // MARK: - Properties

    let selectedSegmentIndex = PublishRelay<Int>()

    private let scans: Observable<[Scan]>
    private let scanObjects: Results<ScanRealm>
    private let bag = DisposeBag()

    // MARK: - Init

    init() {
        let realm = try! Realm()
        scanObjects = realm.objects(ScanRealm.self)
        scans = Observable.array(from: scanObjects)
            .map { scanned in
                scanned.map { $0.toScan() }
            }
    }

    // MARK: - Sections

    var sections: Driver<[SectionModel]> {
        Observable.combineLatest(scans, selectedSegmentIndex)
            .map { unfilteredScans, selectedSegmentIndex -> [Scan] in
                unfilteredScans.filter { scan in
                    guard let medianRssi = scan.medianRssi else { return false }
                    return selectedSegmentIndex == 0 ? true : (medianRssi >= RemoteValues.criticalExpositionRssi)
                }
            }
            .map { unsortedScans in
                unsortedScans.sorted(by: { scan0, scan1 in scan0.date > scan1.date })
            }
            .map { [unowned self] scans -> [SectionModel] in
                self.section(from: scans)
            }
            .asDriver(onErrorJustReturn: [])
    }
}

// MARK: - Sections helpers

extension DataListVM {
    private func section(from scans: [Scan]) -> [SectionModel] {
        let header = DataListVM.Section.Item.header(scanObjects.distinct(by: ["buid"]).count)
        let items: [DataListVM.Section.Item] = scans.map { .data($0) }
        return [
            SectionModel(model: .list, items: [header] + items)
        ]
    }
}

// MARK: - Sections

extension DataListVM {
    typealias SectionModel = AnimatableSectionModel<Section, Section.Item>

    enum Section: IdentifiableType, Equatable {
        case list

        var identity: String {
            switch self {
            case .list:
                return "list"
            }
        }

        static func ==(lhs: Section, rhs: Section) -> Bool {
            lhs.identity == rhs.identity
        }

        enum Item: IdentifiableType, Equatable {
            case header(Int)
            case data(Scan)

            var identity: String {
                switch self {
                case .header:
                    return "header"
                case let .data(scan):
                    return scan.id
                }
            }

            var date: Date? {
                switch self {
                case .header:
                    return nil
                case let .data(scan):
                    return scan.date
                }
            }

            static func ==(lhs: Item, rhs: Item) -> Bool {
                lhs.identity == rhs.identity && lhs.date == rhs.date
            }
        }
    }
}
