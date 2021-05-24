//  
//  DriveSyncLearnMoreViewController.swift
//  ScienceJournal
//
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
import GoogleSignIn
import GoogleAPIClientForREST
import MaterialComponents.MaterialDialogs

class DriveSyncLearnMoreViewController: ModalViewController {
  
  private(set) lazy var learnMoreView = DriveSyncLearnMoreView()

  init() {
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "Google Drive Sync"
    modalView.contentView = learnMoreView

    let attributedString = NSMutableAttributedString(string: String.driveSyncIntroMoreText)
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = 8
    attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, 
    value: paragraphStyle, range: NSRange(location: 0, length: attributedString.length))

    learnMoreView.label.attributedText = attributedString
  }
}