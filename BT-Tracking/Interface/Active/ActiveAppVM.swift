//
//  ActiveAppViewModel.swift
//  BT-Tracking
//
//  Created by Lukáš Foldýna on 25/03/2020.
//  Copyright © 2020 Covid19CZ. All rights reserved.
//

import UIKit

final class ActiveAppVM {

    enum State: String {
        case enabled
        case paused
        case disabled

        var tabBarIcon: UIImage? {
            if #available(iOS 13.0, *) {
                let name: String
                switch self {
                case .enabled:
                    name = "wifi"
                case .paused:
                    name = "wifi.slash"
                case .disabled:
                    name = "wifi.exclamationmark"
                }
                return UIImage(systemName: name)
            } else {
                return UIImage(named: "wifi")?.resize(toWidth: 30)
            }
        }

        var color: UIColor {
            switch self {
            case .enabled:
                return #colorLiteral(red: 0.6116178036, green: 0.7910612226, blue: 0.3123690188, alpha: 1)
            case .paused:
                return #colorLiteral(red: 0.8926691413, green: 0.5397555232, blue: 0.1979260743, alpha: 1)
            case .disabled:
                return #colorLiteral(red: 0.8860370517, green: 0.2113904059, blue: 0.3562591076, alpha: 1)
            }
        }

        var image: UIImage? {
            switch self {
            case .enabled:
                return UIImage(named: "ScanActive")
            case .paused:
                return UIImage(named: "BluetoothPaused")
            case .disabled:
                return UIImage(named: "BluetoothOff")
            }
        }

        var headline: String {
            switch self {
            case .enabled:
                return "active_head_enabled"
            case .paused:
                return "active_head_paused"
            case .disabled:
                return "active_head_disabled"
            }
        }

        var title: String {
            switch self {
            case .enabled:
                return RemoteValues.activeTitleEnabled
            case .paused:
                return Localizable("active_title_paused")
            case .disabled:
                return Localizable("active_title_disabled")
            }
        }

        var footer: String? {
            switch self {
            case .enabled:
                return "active_footer"
            default:
                return nil
            }
        }

        var actionTitle: String {
            switch self {
            case .enabled:
                return "active_button_enabled"
            case .paused:
                return "active_button_paused"
            case .disabled:
                return "active_button_disabled"
            }
        }

        var actionStyle: Button.Style {
            switch self {
            case .enabled:
                return .clear
            default:
                return .filled
            }
        }
    }

    let title = "app_name"
    let back = "back"
    let tabTitle = "app_name"

    let shareApp = "share_app"
    let shareAppMessage = "share_app_message"

    let tips = "active_tips_title"
    let firstTip = "active_tip_1"
    let secondTip = "active_tip_2"

    let menuAbout = "about"
    let menuDebug = "debug"
    let menuCancelRegistration = "cancel_registration_button"
    let menuCancel = "close"

    let backgroundModeTitle = "active_background_mode_title"
    let backgroundModeMessage = "active_background_mode_title"
    let backgroundModeAction = "active_background_mode_settings"
    let backgroundModeCancel = "active_background_mode_cancel"

    private(set) var state: State

    func cardShadowColor(traitCollection: UITraitCollection) -> CGColor {
        if #available(iOS 13.0, *) {
            return UIColor.label.resolvedColor(with: traitCollection).withAlphaComponent(0.2).cgColor
        } else {
            return UIColor.black.withAlphaComponent(0.2).cgColor
        }
    }

    let advertiser: BTAdvertising = AppDelegate.shared.advertiser
    let scanner: BTScannering = AppDelegate.shared.scanner
    var lastBluetoothState: Bool // true enabled

    init(bluetoothActive: Bool) {
        self.lastBluetoothState = bluetoothActive

        if !bluetoothActive {
            state = .disabled
        } else {
            state = (AppSettings.state == .disabled ? .enabled : AppSettings.state) ?? .enabled
        }
    }

}
