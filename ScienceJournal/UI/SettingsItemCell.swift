//  
//  SettingsItemCell.swift
//  ScienceJournal
//
//  Created by Emilio Pavia on 13/04/21.
//  Copyright © 2021 Arduino. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

import UIKit

class SettingsItemCell: UICollectionViewCell {

  var accessoryView: UIView? {
    didSet {
      oldValue?.removeFromSuperview()
      if let view = accessoryView {
        view.setContentHuggingPriority(.required, for: .horizontal)
        stackView.addArrangedSubview(view)
      }
    }
  }
  
  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var subtitleLabel: UILabel!
  
  @IBOutlet private var stackView: UIStackView!
  
  override func awakeFromNib() {
    super.awakeFromNib()
  
    titleLabel.font = ArduinoTypography.regularFont(forSize: ArduinoTypography.FontSize.Small.rawValue)
    titleLabel.textColor = ArduinoColorPalette.grayPalette.tint400
    subtitleLabel.font = ArduinoTypography.boldFont(forSize: ArduinoTypography.FontSize.XXSmall.rawValue)
    subtitleLabel.textColor = ArduinoColorPalette.grayPalette.tint500
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    titleLabel.text = nil
    subtitleLabel.text = nil
    accessoryView = nil
  }

}
