//
//  Logger.swift
//  BT-Tracking
//
//  Created by Lukáš Foldýna on 17/03/2020.
//  Copyright © 2020 Covid19CZ. All rights reserved.
//

import Foundation

func log(_ text: String) {
    #if !PROD
    DispatchQueue.main.async {
        Log.log(text)
        FileLogger.shared.writeLog(text)
    }
    #elseif DEBUG
    print(text)
    #endif
}

protocol LogDelegate: AnyObject {
    func didLog(_ text: String)
}

struct Log {
    weak static var delegate: LogDelegate?

    static func log(_ text: String) {
        delegate?.didLog(text)
        print(text)
    }
}

