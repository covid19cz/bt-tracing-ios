//
//  AppSettings.swift
//  eRouska
//
//  Created by Lukáš Foldýna on 24/03/2020.
//  Copyright © 2020 Covid19CZ. All rights reserved.
//

import Foundation

struct AppSettings {

    private enum Keys: String {
        case appState
        case appFirstTimeLaunched
        case backgroundModeAlertShown

        case lastDownloadFileName
        case lastProcessedFileName
        case lastUploadDate

        case v2_0NewsLaunched

        // Deprecated
        case lastDataPurgeDate
    }

    /// Firebase Region
    static let firebaseRegion = "europe-west1"

    /// Last application state (paused, running, ...)
    static var state: ActiveAppVM.State? {
        get {
            return ActiveAppVM.State(rawValue: string(forKey: .appState))
        }
        set {
            set(withKey: .appState, value: newValue?.rawValue)
        }
    }

    /// Check if it's first time launch
    static var appFirstTimeLaunched: Bool {
        get {
            return bool(forKey: .appFirstTimeLaunched)
        }
        set {
            set(withKey: .appFirstTimeLaunched, value: newValue)
        }
    }

    /// If background mode off alert was shown
    static var backgroundModeAlertShown: Bool {
        get {
            return bool(forKey: .backgroundModeAlertShown)
        }
        set {
            set(withKey: .backgroundModeAlertShown, value: newValue)
        }
    }

    /// Last download file batch
    static var lastDownloadFileName: String? {
        get {
            return string(forKey: .lastDownloadFileName)
        }
        set {
            set(withKey: .lastDownloadFileName, value: newValue)
        }
    }

    /// Last process file batch
    static var lastProcessedFileName: String? {
        get {
            return string(forKey: .lastProcessedFileName)
        }
        set {
            set(withKey: .lastProcessedFileName, value: newValue)
        }
    }

    /// When it app last time uploaded keys
    static var lastUploadDate: Date? {
        get {
            let rawValue = double(forKey: .lastUploadDate)
            return Date(timeIntervalSince1970: TimeInterval(rawValue))
        }
        set {
            set(withKey: .lastUploadDate, value: newValue?.timeIntervalSince1970)
        }
    }

    /// Check if it's migration to new version
    static var v2_0NewsLaunched: Bool {
        get {
            return bool(forKey: .v2_0NewsLaunched)
        }
        set {
            set(withKey: .v2_0NewsLaunched, value: newValue)
        }
    }

    /// Cleanup data after logout
    static func deleteAllData() {
        KeychainService.eHRID = nil

        backgroundModeAlertShown = false

        state = nil

        lastDownloadFileName = nil
        lastProcessedFileName = nil
        lastUploadDate = nil
    }

    // MARK: - Private

    private static func bool(forKey key: Keys) -> Bool {
        return UserDefaults.standard.bool(forKey: key.rawValue)
    }

    private static func double(forKey key: Keys) -> Double {
        return UserDefaults.standard.double(forKey: key.rawValue)
    }

    private static func string(forKey key: Keys) -> String {
        return UserDefaults.standard.string(forKey: key.rawValue) ?? ""
    }

    private static func set(withKey key: Keys, value: Any?) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }

}
