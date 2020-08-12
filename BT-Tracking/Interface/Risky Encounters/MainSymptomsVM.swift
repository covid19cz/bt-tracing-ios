//
//  MainSymptomsVM.swift
//  BT-Tracking
//
//  Created by Naim Ashhab on 10/08/2020.
//  Copyright © 2020 Covid19CZ. All rights reserved.
//

import Foundation

struct MainSymptomsVM: RiskyEncountersListVM {
    let title = "main_symptoms_title"
    var content: RiskyEncountersListContent? = RemoteValues.symptomsContent
}
