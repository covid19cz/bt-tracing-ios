//
//  RiskyEncountersListCell.swift
//  BT-Tracking
//
//  Created by Naim Ashhab on 10/08/2020.
//  Copyright © 2020 Covid19CZ. All rights reserved.
//

import UIKit
import SDWebImage

final class RiskyEncountersListCell: UITableViewCell {
    @IBOutlet weak var customImageView: UIImageView!
    @IBOutlet weak var customTextLabel: UILabel!

    func config(with symptom: AsyncImageTitleViewModel) {
        customImageView.sd_setImage(with: symptom.imageUrl, placeholderImage: nil) // TODO: add placeholder image
        customTextLabel.text = symptom.title
    }
}
