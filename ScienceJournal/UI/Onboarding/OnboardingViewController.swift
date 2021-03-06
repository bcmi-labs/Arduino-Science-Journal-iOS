//  
//  OnboardingViewController.swift
//  ScienceJournal
//
//  Created by Emilio Pavia on 10/11/2020.
//  Copyright © 2020 Arduino. All rights reserved.
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

class OnboardingViewController: UIViewController {

  @IBOutlet weak var topBar: UIView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var closeButton: UIButton!
  @IBOutlet weak var pageControl: OnboardingPageControl!
  @IBOutlet weak var pageContainer: UIView!

  var onClose: (() -> Void)?

  private let numberOfPages = 7
  
  private lazy var pageViewController: UIPageViewController = {
    let viewController = UIPageViewController(transitionStyle: .scroll,
                                              navigationOrientation: .horizontal,
                                              options: nil)
    viewController.dataSource = self
    viewController.delegate = self
    return viewController
  }()

  private lazy var tapGestureRecognizer: UITapGestureRecognizer = {
    let tap = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
    tap.delegate = self
    return tap
  }()

  override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
    setupTopBar()
    setupPageViewController()
    setupGestureRecognizers()
  }
}

extension OnboardingViewController: UIPageViewControllerDataSource {
  func pageViewController(_ pageViewController: UIPageViewController,
                          viewControllerBefore viewController: UIViewController) -> UIViewController? {
    guard let pageNumber = pageNumber(of: viewController) else { return nil }
    return page(at: pageNumber - 1)
  }

  func pageViewController(_ pageViewController: UIPageViewController,
                          viewControllerAfter viewController: UIViewController) -> UIViewController? {
    guard let pageNumber = pageNumber(of: viewController) else { return nil }
    return page(at: pageNumber + 1)
  }
}

extension OnboardingViewController: UIPageViewControllerDelegate {
  func pageViewController(_ pageViewController: UIPageViewController,
                          didFinishAnimating finished: Bool,
                          previousViewControllers: [UIViewController],
                          transitionCompleted completed: Bool) {

    pageControl.currentPage = pageNumber(of: pageViewController.viewControllers?.first) ?? 0
  }
}

extension OnboardingViewController: UIGestureRecognizerDelegate {
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    guard let page = pageViewController.viewControllers?.first as? OnboardingPageViewController else {
      return true
    }

    let scrollIndicator = page.scrollIndicator
    guard scrollIndicator.bounds.contains(touch.location(in: scrollIndicator)) else {
      return true
    }

    return false
  }
}

private extension OnboardingViewController {
  func setupView() {
    view.backgroundColor = ArduinoColorPalette.grayPalette.tint50
  }

  func setupTopBar() {
    topBar.backgroundColor = ArduinoColorPalette.goldPalette.tint400

    titleLabel.textColor = UIColor.white
    titleLabel.font = ArduinoTypography.monoBoldFont(forSize: ArduinoTypography.FontSize.Small.rawValue)
    titleLabel.attributedText = NSAttributedString(string: String.onboardingNavigationTitle,
                                                   attributes: [.kern: 2])

    pageControl.numberOfPages = numberOfPages
  }

  func setupPageViewController() {
    pageContainer.backgroundColor = ArduinoColorPalette.grayPalette.tint50

    if let page = page(at: 0) {
      pageViewController.setViewControllers([page],
                                            direction: .forward,
                                            animated: false, completion: nil)
    }

    addChild(pageViewController)
    pageContainer.addSubview(pageViewController.view)
    pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
    pageViewController.view.pinToEdgesOfView(pageContainer)
    pageViewController.didMove(toParent: self)
  }

  func setupGestureRecognizers() {
    view.addGestureRecognizer(tapGestureRecognizer)
  }

  func page(at index: Int) -> OnboardingPageViewController? {
    switch index {
    case 0:
      return OnboardingPage1ViewController(
        primaryAction: { [weak self] in self?.onClose?() }
      )
    case 1:
      return OnboardingPage2ViewController()
    case 2:
      return OnboardingPage3ViewController()
    case 3:
      return OnboardingPage4ViewController()
    case 4:
      return OnboardingPage5ViewController()
    case 5:
      return OnboardingPage6ViewController()
    case 6:
      return OnboardingPage7ViewController(
        primaryAction: { [weak self] in self?.onClose?() }
      )
    default:
      return nil
    }
  }

  func pageNumber(of viewController: UIViewController?) -> Int? {
    switch viewController {
    case is OnboardingPage1ViewController:
      return 0
    case is OnboardingPage2ViewController:
      return 1
    case is OnboardingPage3ViewController:
      return 2
    case is OnboardingPage4ViewController:
      return 3
    case is OnboardingPage5ViewController:
      return 4
    case is OnboardingPage6ViewController:
      return 5
    case is OnboardingPage7ViewController:
      return 6
    default:
      return nil
    }
  }

  func goBack() {
    let destination = pageControl.currentPage - 1
    guard let page = page(at: destination) else { return }
    pageControl.currentPage = destination
    pageViewController.setViewControllers([page], direction: .reverse, animated: false)
  }

  func goForward() {
    let destination = pageControl.currentPage + 1
    guard let page = page(at: destination) else { return }
    pageControl.currentPage = destination
    pageViewController.setViewControllers([page], direction: .forward, animated: false)
  }

  @IBAction
  func close(_ sender: UIButton) {
    onClose?()
  }

  @objc
  func didTap(_ sender: UITapGestureRecognizer) {
    guard sender.state == .ended else { return }
    let point = sender.location(in: view)
    let offset = point.x / view.bounds.width
    if offset < 0.25 {
      goBack()
    } else {
      goForward()
    }
  }
}
