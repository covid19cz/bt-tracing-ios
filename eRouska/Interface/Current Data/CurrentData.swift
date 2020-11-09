//
//  CurrentData.swift
//  BT-Tracking
//
//  Created by Naim Ashhab on 26/08/2020.
//  Copyright © 2020 Covid19CZ. All rights reserved.
//

import Foundation
import RealmSwift

final class CurrentDataRealm: Object {

    @objc dynamic var testsTotal: Int = 0
    @objc dynamic var testsIncrease: Int = 0
    @objc dynamic var testsIncreaseDate: Date?
    @objc dynamic var confirmedCasesTotal: Int = 0
    @objc dynamic var confirmedCasesIncrease: Int = 0
    @objc dynamic var confirmedCasesIncreaseDate: Date?
    @objc dynamic var activeCasesTotal: Int = 0
    @objc dynamic var curedTotal: Int = 0
    @objc dynamic var deceasedTotal: Int = 0
    @objc dynamic var currentlyHospitalizedTotal: Int = 0

    @objc dynamic var appDate: Date?
    @objc dynamic var activationsYesterday: Int = 0
    @objc dynamic var activationsTotal: Int = 0
    @objc dynamic var keyPublishersYesterday: Int = 0
    @objc dynamic var keyPublishersTotal: Int = 0
    @objc dynamic var notificationsYesterday: Int = 0
    @objc dynamic var notificationsTotal: Int = 0

    func update(with data: CovidCurrentData) {
        self.testsTotal = data.testsTotal
        self.testsIncrease = data.testsIncrease
        self.testsIncreaseDate = data.testsIncreaseDate

        self.confirmedCasesTotal = data.confirmedCasesTotal
        self.confirmedCasesIncrease = data.confirmedCasesIncrease
        self.confirmedCasesIncreaseDate = data.confirmedCasesIncreaseDate

        self.activeCasesTotal = data.activeCasesTotal
        self.curedTotal = data.curedTotal
        self.deceasedTotal = data.deceasedTotal
        self.currentlyHospitalizedTotal = data.currentlyHospitalizedTotal
    }

    func update(with data: AppCurrentData) {
        self.appDate = data.date
        self.activationsYesterday = data.activationsYesterday
        self.activationsTotal = data.activationsTotal
        self.keyPublishersYesterday = data.keyPublishersYesterday
        self.keyPublishersTotal = data.keyPublishersTotal
        self.notificationsYesterday = data.notificationsYesterday
        self.notificationsTotal = data.notificationsTotal
    }

}

struct CovidCurrentData: Decodable {

    let testsTotal: Int
    let testsIncrease: Int
    let testsIncreaseDate: Date?
    let confirmedCasesTotal: Int
    let confirmedCasesIncrease: Int
    let confirmedCasesIncreaseDate: Date?
    let activeCasesTotal: Int
    let curedTotal: Int
    let deceasedTotal: Int
    let currentlyHospitalizedTotal: Int

    private enum CodingKeys: String, CodingKey {
        case testsTotal, testsIncrease, testsIncreaseDate
        case confirmedCasesTotal, confirmedCasesIncrease, confirmedCasesIncreaseDate
        case activeCasesTotal, curedTotal, deceasedTotal, currentlyHospitalizedTotal
    }

    init(with data: [String: Any]) {
        testsTotal = data[CodingKeys.testsTotal.rawValue] as? Int ?? 0
        testsIncrease = data[CodingKeys.testsIncrease.rawValue] as? Int ?? 0
        if let value = data[CodingKeys.testsIncreaseDate.rawValue] as? String {
            testsIncreaseDate = DateFormatter.serverDateFormatter.date(from: value)
        } else {
            testsIncreaseDate = nil
        }
        confirmedCasesTotal = data[CodingKeys.confirmedCasesTotal.rawValue] as? Int ?? 0
        confirmedCasesIncrease = data[CodingKeys.confirmedCasesIncrease.rawValue] as? Int ?? 0
        if let value = data[CodingKeys.confirmedCasesIncreaseDate.rawValue] as? String {
            confirmedCasesIncreaseDate = DateFormatter.serverDateFormatter.date(from: value)
        } else {
            confirmedCasesIncreaseDate = nil
        }
        activeCasesTotal = data[CodingKeys.activeCasesTotal.rawValue] as? Int ?? 0
        curedTotal = data[CodingKeys.curedTotal.rawValue] as? Int ?? 0
        deceasedTotal = data[CodingKeys.deceasedTotal.rawValue] as? Int ?? 0
        currentlyHospitalizedTotal = data[CodingKeys.currentlyHospitalizedTotal.rawValue] as? Int ?? 0
    }

}

struct AppCurrentData: Decodable {

    let modified: Int
    let date: Date?
    let activationsYesterday: Int
    let activationsTotal: Int
    let keyPublishersYesterday: Int
    let keyPublishersTotal: Int
    let notificationsYesterday: Int
    let notificationsTotal: Int

    private enum CodingKeys: String, CodingKey {
        case modified
        case date
        case activationsYesterday = "activations_yesterday"
        case activationsTotal = "activations_total"
        case keyPublishersYesterday = "key_publishers_yesterday"
        case keyPublishersTotal = "key_publishers_total"
        case notificationsYesterday = "notifications_yesterday"
        case notificationsTotal = "notifications_total"
    }

}
