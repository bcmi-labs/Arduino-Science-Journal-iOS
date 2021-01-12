//  
//  WizardViewController.swift
//  ScienceJournal
//
//  Created by Emilio Pavia on 04/01/21.
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

class WizardViewController: UIViewController {

  let wizardView = WizardView()

  var rootViewController: WizardRootViewController?

  override func loadView() {
    view = wizardView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    let backBarButtton = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    navigationItem.backBarButtonItem = backBarButtton
  }

  @IBAction func close(_ sender: Any) {
    rootViewController?.close()
  }
}