//
//  ExposureService.swift
//  eRouska
//
//  Created by Lukáš Foldýna on 30/04/2020.
//  Copyright © 2020 Covid19CZ. All rights reserved.
//

import Foundation
import ExposureNotification
import RxSwift

protocol HasExposureService {
    var exposure: ExposureServicing { get }
}

protocol ExposureServicing: AnyObject {

    var readyToUse: Completable { get }

    // Activation
    typealias Callback = (Error?) -> Void

    var isActive: Bool { get }
    var isEnabled: Bool { get }

    var status: ENStatus { get }
    var authorizationStatus: ENAuthorizationStatus { get }

    typealias ActivationCallback = (ExposureError?) -> Void
    func activate(callback: ActivationCallback?)
    func deactivate(callback: Callback?)

    // Keys
    typealias KeysCallback = (_ result: Result<[ExposureDiagnosisKey], ExposureError>) -> Void
    func getDiagnosisKeys(callback: @escaping KeysCallback)
    func getTestDiagnosisKeys(callback: @escaping KeysCallback)

    // Traveler
    typealias TravelerCallback = (Result<Bool, Error>) -> Void

    @available(iOS 13.7, *)
    func getUserTraveled(callback: @escaping TravelerCallback)

    // Detection
    typealias DetectCallback = (Result<[Exposure], Error>) -> Void
    var detectingExposures: Bool { get }
    func detectExposures(configuration: ExposureConfiguration, URLs: [URL], callback: @escaping DetectCallback)

    // Bluetooth
    var isBluetoothOn: Bool { get }

}

final class ExposureService: ExposureServicing {

    var readyToUse: Completable

    typealias Callback = (Error?) -> Void

    private var manager: ENManager

    var isActive: Bool {
        [ENStatus.active, .paused].contains(manager.exposureNotificationStatus)
    }

    var isEnabled: Bool {
        manager.exposureNotificationEnabled
    }

    var status: ENStatus {
        manager.exposureNotificationStatus
    }

    var authorizationStatus: ENAuthorizationStatus {
        ENManager.authorizationStatus
    }

    init() {
        manager = ENManager()
        readyToUse = Completable.create { [manager] completable in
            manager.activate { error in
                if let error = error {
                    completable(.error(error))
                } else {
                    completable(.completed)
                }
            }
            return Disposables.create()
        }
    }

    deinit {
        manager.invalidate()
    }

    func activate(callback: ActivationCallback?) {
        print("ExposureService: activating")
        guard !isEnabled, !isActive else {
            callback?(nil)
            return
        }

        let activationCallback: ENErrorHandler = { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                if let code = ENError.Code(rawValue: (error as NSError).code) {
                    callback?(ExposureError.activationError(code))
                } else if self.manager.exposureNotificationStatus == .restricted {
                    callback?(ExposureError.restrictedAccess)
                } else {
                    callback?(ExposureError.error(error))
                }
                return
            }

            DispatchQueue.main.async {
                callback?(nil)
            }
        }

        switch manager.exposureNotificationStatus {
        case .active, .paused:
            callback?(nil)
        case .disabled, .unknown, .restricted, .unauthorized:
            // Restricted should be not "activatable" but on actual device it always shows as restricted before activation
            manager.setExposureNotificationEnabled(true, completionHandler: activationCallback)
        case .bluetoothOff:
            callback?(ExposureError.bluetoothOff)
        @unknown default:
            callback?(ExposureError.unknown)
        }
    }

    func deactivate(callback: Callback?) {
        print("ExposureService: deactivating")
        guard isEnabled else {
            callback?(nil)
            return
        }

        manager.setExposureNotificationEnabled(false) { error in
            guard error == nil else {
                callback?(error)
                return
            }
            callback?(nil)
        }
    }

    func getDiagnosisKeys(callback: @escaping KeysCallback) {
        manager.getDiagnosisKeys(completionHandler: keysCallback(callback))
    }

    func getTestDiagnosisKeys(callback: @escaping KeysCallback) {
        manager.getTestDiagnosisKeys(completionHandler: keysCallback(callback))
    }

    @available(iOS 13.7, *)
    func getUserTraveled(callback: @escaping TravelerCallback) {
        manager.getUserTraveled(completionHandler: { traveler, error in
            if let error = error {
                callback(.failure(error))
            } else {
                callback(.success(traveler))
            }
        })
    }

    private func keysCallback(_ callback: @escaping KeysCallback) -> ENGetDiagnosisKeysHandler {
        return { keys, error in
            if let error = error, let code = ENError.Code(rawValue: (error as NSError).code) {
                callback(.failure(ExposureError.exposureError(code)))
            } else if let error = error {
                callback(.failure(ExposureError.error(error)))
            } else if keys?.isEmpty == true {
                callback(.failure(ExposureError.noData))
            } else if let keys = keys {
                callback(.success(keys.map { ExposureDiagnosisKey(key: $0) }))
            }
        }
    }

    private(set) var detectingExposures = false

    func detectExposures(configuration: ExposureConfiguration, URLs: [URL], callback: @escaping DetectCallback) {
        guard !detectingExposures else {
            callback(.failure(ExposureError.alreadyRunning))
            return
        }
        detectingExposures = true

        func finish(error: Error? = nil, exposures: [Exposure] = []) {
            finishDetectingExposures(URLs: URLs, error: error, exposures: exposures, callback: callback)
        }

        log("ExposureService detectExposures")
        self.manager.detectExposures(configuration: configuration.configuration, diagnosisKeyURLs: URLs) { summary, error in
            if let error = error {
                finish(error: error)
            } else if let summary = summary {
                log("ExposureService summary \(summary)")

                switch configuration {
                case let configuration as ExposureConfigurationV1:
                    self.processDetectedExposuresV1(configuration: configuration, summary: summary, URLs: URLs, callback: callback)
                case let configuration as ExposureConfigurationV2:
                    if #available(iOS 13.7, *) {
                        self.processDetectedExposuresV2(configuration: configuration, summary: summary, URLs: URLs, callback: callback)
                    } else {
                        log("ExposureService Lower iOS version for V2 than is required!")
                        finish()
                    }
                default:
                    log("ExposureService Unknown exposure configuration version")
                    finish()
                }
            } else {
                finish(error: ExposureError.noData)
            }
        }
    }

    private func processDetectedExposuresV1(configuration: ExposureConfigurationV1, summary: ENExposureDetectionSummary,
                                            URLs: [URL], callback: @escaping DetectCallback) {
        func finish(error: Error? = nil, exposures: [Exposure] = []) {
            finishDetectingExposures(URLs: URLs, error: error, exposures: exposures, callback: callback)
        }

        let computedThreshold: Double = (Double(truncating: summary.attenuationDurations[0]) * configuration.factorLow +
                                            Double(truncating: summary.attenuationDurations[1]) * configuration.factorHigh) / 60 // (minute)

        let threshold = "computed threshold: \(computedThreshold)"
        let factors = "(low: \(configuration.factorLow) high: \(configuration.factorHigh)) required \(configuration.triggerThreshold)"
        log("ExposureService Summary for day \(summary.daysSinceLastExposure) : \(summary.debugDescription) " + threshold + " " + factors)

        if computedThreshold >= Double(configuration.triggerThreshold) {
            log("ExposureService Summary meets requirements")

            guard summary.matchedKeyCount != 0 else {
                finish()
                return
            }
            log("ExposureService getExposureInfo")

            self.manager.getExposureInfo(summary: summary, userExplanation: L10n.exposureDetectedTitle) { exposures, error in
                if let error = error {
                    finish(error: error)
                } else if let exposures = exposures {
                    var filtred: [Date: ENExposureInfo] = [:]
                    for exposure in exposures {
                        if let current = filtred[exposure.date] {
                            if current.totalRiskScoreFullRange < exposure.totalRiskScoreFullRange {
                                filtred[exposure.date] = exposure
                            }
                        } else {
                            filtred[exposure.date] = exposure
                        }
                    }

                    finish(exposures: filtred.values.map {
                        Exposure(
                            id: UUID(),
                            date: $0.date,
                            duration: $0.duration,
                            totalRiskScore: $0.totalRiskScore,
                            transmissionRiskLevel: $0.transmissionRiskLevel,
                            attenuationValue: $0.attenuationValue,
                            attenuationDurations: $0.attenuationDurations.map { $0.intValue }
                        )
                    })
                    log("ExposureService Exposures \(exposures)")
                } else {
                    finish(error: ExposureError.noData)
                }
            }
        } else {
            log("ExposureService Summary does not meet requirements")
            finish()
        }
    }

    @available(iOS 13.7, *)
    private func processDetectedExposuresV2(configuration: ExposureConfigurationV2, summary: ENExposureDetectionSummary,
                                            URLs: [URL], callback: @escaping DetectCallback) {
        func finish(error: Error? = nil, exposures: [Exposure] = []) {
            finishDetectingExposures(URLs: URLs, error: error, exposures: exposures, callback: callback)
        }

        let threshold = "computed threshold: \(summary.maximumRiskScore)"
        let factors = "(low:\(configuration.attenuationDurationThresholds.first ?? 0) high: \(configuration.attenuationDurationThresholds.last ?? 0))"
        log("ExposureService Summary for day \(summary.daysSinceLastExposure) : \(summary.debugDescription) " + threshold + " " + factors)

        guard !summary.daySummaries.isEmpty else {
            finish()
            return
        }
        log("ExposureService getExposureInfo")

        let daySummaries = summary.daySummaries.filter { Int($0.daySummary.maximumScore) >= configuration.minimumScore }
        guard !daySummaries.isEmpty else {
            log("ExposureService no day with score at least 900")
            finish()
            return
        }

        self.manager.getExposureWindows(summary: summary) { windows, error in
            if let error = error {
                finish(error: error)
            } else if let windows = windows {
                let exposures: [Exposure] = windows.compactMap { window in
                    guard let summary = daySummaries.first(where: { $0.date == window.date }) else { return nil }
                    let daySummary = ExposureWindow.DaySummary(
                        maximumScore: summary.daySummary.maximumScore,
                        scoreSum: summary.daySummary.scoreSum,
                        weightedDurationSum: summary.daySummary.weightedDurationSum
                    )

                    let window = ExposureWindow(
                        id: UUID(),
                        date: window.date,
                        calibrationConfidence: Int(window.calibrationConfidence.rawValue),
                        diagnosisReportType: Int(window.diagnosisReportType.rawValue),
                        infectiousness: Int(window.infectiousness.rawValue),
                        scanInstances: window.scanInstances.map {
                            ExposureWindow.Scan(
                                minimumAttenuation: Int($0.minimumAttenuation),
                                typicalAttenuation: Int($0.typicalAttenuation),
                                secondsSinceLastScan: Int($0.secondsSinceLastScan)
                            )
                        },
                        daySummary: daySummary
                    )

                    return Exposure(
                        id: UUID(),
                        date: window.date,
                        duration: 0,
                        totalRiskScore: 0,
                        transmissionRiskLevel: 0,
                        attenuationValue: 0,
                        attenuationDurations: [0],
                        window: window
                    )
                }

                var filtred: [Date: Exposure] = [:]
                for exposure in exposures {
                    if let current = filtred[exposure.date] {
                        if (current.window?.infectiousness ?? 0) < (exposure.window?.infectiousness ?? 0) {
                            filtred[exposure.date] = exposure
                        }
                    } else {
                        filtred[exposure.date] = exposure
                    }
                }
                finish(exposures: filtred.map({ $0.value }))
                log("ExposureService Exposures windows \(windows)")
            } else {
                finish(error: ExposureError.noData)
            }
        }
    }

    func finishDetectingExposures(URLs: [URL], error: Error? = nil, exposures: [Exposure] = [], callback: @escaping DetectCallback) {
        if let error = error {
            callback(.failure(error))
        } else {
            callback(.success(exposures))
        }

        URLs.forEach { try? FileManager.default.removeItem(at: $0) }
        detectingExposures = false
    }

    // MARK: - Bluetooth

    var isBluetoothOn: Bool {
        manager.exposureNotificationStatus != .bluetoothOff
    }

}
