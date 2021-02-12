//
//  NewsPageVM.swift
//  BT-Tracking
//
//  Created by Naim Ashhab on 28/07/2020.
//  Copyright © 2020 Covid19CZ. All rights reserved.
//

import Foundation

struct NewsPageVM {
    let imageAsset: ImageAsset
    let headline: String
    let body: String
    let bodyLinkTitle: String?
    let bodyLink: String?

    init(imageAsset: ImageAsset, headline: String, body: String, bodyLinkTitle: String? = nil, bodyLink: String? = nil) {
        self.imageAsset = imageAsset
        self.headline = headline
        self.body = body
        self.bodyLinkTitle = bodyLinkTitle
        self.bodyLink = bodyLink
    }
}
