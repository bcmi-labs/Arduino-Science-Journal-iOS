//  
//  SignUpViewController.swift
//  ScienceJournal
//
//  Created by Emilio Pavia on 24/03/21.
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
import MaterialComponents.MaterialSnackbar
import RxCocoa
import RxSwift

class SignUpViewController: WizardViewController {
  
  let accountsManager: ArduinoAccountsManager
  private(set) var viewModel: SignUpViewModel
  
  var error: [String: Any]? {
    didSet {
      parseError()
    }
  }
  
  private(set) lazy var signUpView = SignUpView(hasSingleSignOn: viewModel.isAdult)
  
  private lazy var disposeBag = DisposeBag()
  
  init(accountsManager: ArduinoAccountsManager, viewModel: SignUpViewModel) {
    self.accountsManager = accountsManager
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    wizardView.contentView = signUpView
    
    signUpView.infoButton.addTarget(self, action: #selector(showInfo(_:)), for: .touchUpInside)
    signUpView.submitButton.addTarget(self, action: #selector(submit(_:)), for: .touchUpInside)
    
    signUpView.socialView.githubButton.addTarget(self, action: #selector(signInWithGitHub(_:)), for: .touchUpInside)
    signUpView.socialView.googleButton.addTarget(self, action: #selector(signInWithGoogle(_:)), for: .touchUpInside)
    signUpView.socialView.appleButton.addTarget(self, action: #selector(signInWithApple(_:)), for: .touchUpInside)
    
    addObservers()
  }
  
  @objc private func showInfo(_ sender: UIButton) {
    let alertController = MDCAlertController(title: nil,
                                             message: String.arduinoSignUpUsernameInfo)
    alertController.addAction(MDCAlertAction(title: String.actionOk))
    alertController.accessibilityViewIsModal = true
    present(alertController, animated: true)
  }
  
  @objc private func submit(_ sender: UIButton) {
    error = nil
    
    if viewModel.isAdult {
      let viewController = SignUpTermsViewController(accountsManager: accountsManager, viewModel: viewModel)
      show(viewController, sender: nil)
    } else {
      
    }
  }
  
  @objc private func signInWithGitHub(_ sender: UIButton) {
    isLoading.onNext(true)
    accountsManager.signIn(with: .github, from: self, completion: completeWithResult)
  }
  
  @objc private func signInWithGoogle(_ sender: UIButton) {
    isLoading.onNext(true)
    accountsManager.signIn(with: .google, from: self, completion: completeWithResult)
  }
  
  @objc private func signInWithApple(_ sender: UIButton) {
    isLoading.onNext(true)
    accountsManager.signIn(with: .apple, from: self, completion: completeWithResult)
  }
  
  private func completeWithResult(_ result: Result<ArduinoAccount, SignInError>) {
    isLoading.onNext(false)
    switch result {
    case .success: rootViewController?.close(isCancelled: false)
    case .failure: break
    }
  }
  
  private func parseError() {
    if let error = error?["error"] as? String, error.hasPrefix("error in email") {
      signUpView.emailError = String.arduinoSignUpEmailInvalidError
      signUpView.usernameError = nil
    } else if let code = error?["code"] as? String, code == "user_exists" {
      if let message = error?["message"] as? String, message.contains("username") {
        signUpView.emailError = nil
        signUpView.usernameError = String.arduinoSignUpUsernameExistsError
      } else {
        signUpView.emailError = String.arduinoSignUpEmailExistsError
        signUpView.usernameError = nil
      }
    } else {
      signUpView.emailError = nil
      signUpView.usernameError = nil
    }
  }
  
  private func addObservers() {
    let hasEmail = signUpView.emailTextField.rx.text.orEmpty
      .map { $0.isValidEmail }
    
    let hasUsername = signUpView.usernameTextField.rx.text.orEmpty
      .map { $0.isValidUsername }
    
    let hasPassword = signUpView.passwordTextField.rx.text.orEmpty
      .map { $0.isValidPassword }
    
    signUpView.emailTextField.rx.text.orEmpty
      .subscribe(onNext: { [weak self] in
        self?.viewModel.email = $0
      })
      .disposed(by: disposeBag)
    
    signUpView.usernameTextField.rx.text.orEmpty
      .subscribe(onNext: { [weak self] in
        self?.viewModel.username = $0
      })
      .disposed(by: disposeBag)
    
    signUpView.passwordTextField.rx.text.orEmpty
      .subscribe(onNext: { [weak self] in
        self?.viewModel.password = $0
      })
      .disposed(by: disposeBag)
    
    Observable.combineLatest(hasEmail, hasUsername, hasPassword)
      .map { $0.0 && $0.1 && $0.2 }
      .bind(to: signUpView.submitButton.rx.isEnabled)
      .disposed(by: disposeBag)
    
    isLoading
      .map { !$0 }
      .observe(on: MainScheduler.instance)
      .bind(to: signUpView.emailTextField.rx.isEnabled)
      .disposed(by: disposeBag)
    
    isLoading
      .map { !$0 }
      .observe(on: MainScheduler.instance)
      .bind(to: signUpView.usernameTextField.rx.isEnabled)
      .disposed(by: disposeBag)
    
    isLoading
      .map { !$0 }
      .observe(on: MainScheduler.instance)
      .bind(to: signUpView.passwordTextField.rx.isEnabled)
      .disposed(by: disposeBag)
    
    isLoading
      .map { !$0 }
      .observe(on: MainScheduler.instance)
      .bind(to: signUpView.socialView.githubButton.rx.isEnabled)
      .disposed(by: disposeBag)
    
    isLoading
      .map { !$0 }
      .observe(on: MainScheduler.instance)
      .bind(to: signUpView.socialView.googleButton.rx.isEnabled)
      .disposed(by: disposeBag)
    
    isLoading
      .map { !$0 }
      .observe(on: MainScheduler.instance)
      .bind(to: signUpView.socialView.appleButton.rx.isEnabled)
      .disposed(by: disposeBag)
    
    isLoading
      .map { !$0 }
      .observe(on: MainScheduler.instance)
      .bind(to: signUpView.usernameTextField.rx.isEnabled)
      .disposed(by: disposeBag)
    
    isLoading
      .map { !$0 }
      .observe(on: MainScheduler.instance)
      .bind(to: signUpView.passwordTextField.rx.isEnabled)
      .disposed(by: disposeBag)
    
    isLoading
      .filter { $0 }
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { [weak self] _ in
        self?.view.endEditing(true)
      })
      .disposed(by: disposeBag)
  }
}