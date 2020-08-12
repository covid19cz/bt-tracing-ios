//
//  AppDependency.swift
//  eRouska
//
//  Created by Lukáš Foldýna on 03/07/2020.
//  Copyright © 2020 Covid19CZ. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFunctions

class AppDependency {

    private(set) lazy var exposureService: ExposureServicing = ExposureService()

    var deviceToken: Data?

    private(set) lazy var functions = Functions.functions(region: AppSettings.firebaseRegion)

    lazy var countryCodes: CountryCodesServicing = CountryCodeService()

    lazy var reporter: ReportServicing = ReportService()

    lazy var verification: VerificationServicing = VerificationService()

    func resetAdvertising() {
        guard KeychainService.BUID != nil else { return } // TODO: Should be eHRID?
        guard exposureService.status == .active || exposureService.status == .paused else { return }
        exposureService.deactivate { _ in }
    }

}
