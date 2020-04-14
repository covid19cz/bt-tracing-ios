//
//  SectionTitleCell.swift
//  BT-Tracking
//
//  Created by Tomas Svoboda on 22/03/2020.
//  Copyright © 2020 Covid19CZ. All rights reserved.
//

import UIKit

final class SectionTitleCell: UITableViewCell {
    static let identifier = "sectionTitleCell"

    @IBOutlet var titleLabel: UILabel!

    func configure(for title: String) {
        titleLabel.text = title
    }
}
