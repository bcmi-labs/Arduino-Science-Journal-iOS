/*
 *  Copyright 2019 Google LLC. All Rights Reserved.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

import UIKit

// A custom transition for `UINavigationController` that looks like a `coverVertical` modal
// transition. It may be possible to use a `UIPresentationController` instead of this, which
// would ensure the animation would be exactly the same, but custom presentations seem to ignore
// the `definesPresentationContext` property and present in full screen from the root VC, which
// covers the AA bar. Using this custom animation also has the advantage of only needing one
// code path to handle post-dismissal cleanup and animation coordination.
final class FauxdalTransitionAnimation: NSObject, UIViewControllerAnimatedTransitioning {

  private let operation: UINavigationController.Operation
  private let transitionDuration: TimeInterval

  init(operation: UINavigationController.Operation, transitionDuration: TimeInterval) {
    self.operation = operation
    self.transitionDuration = transitionDuration
  }

  func transitionDuration(
    using transitionContext: UIViewControllerContextTransitioning?
  ) -> TimeInterval {
    return transitionDuration
  }

  func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    switch operation {
    case .none:
      // TODO: When does this happen?
      transitionContext.completeTransition(true)
    case .push:
      animatePush(using: transitionContext)
    case .pop:
      animatePop(using: transitionContext)
    @unknown default:
      transitionContext.completeTransition(false)
    }
  }

  func animatePush(using transitionContext: UIViewControllerContextTransitioning) {
    guard let toView = transitionContext.view(forKey: .to) else {
      transitionContext.completeTransition(false)
      return
    }

    let duration = transitionDuration(using: transitionContext)
    let toViewHeight = toView.bounds.height

    transitionContext.containerView.addSubview(toView)

    toView.transform = CGAffineTransform(translationX: 0, y: toViewHeight)
    UIView.animate(withDuration: duration, animations: {
      toView.transform = .identity
    }) { completed in
      transitionContext.completeTransition(completed)
    }
  }

  func animatePop(using transitionContext: UIViewControllerContextTransitioning) {
    guard let fromView = transitionContext.view(forKey: .from),
      let toView = transitionContext.view(forKey: .to) else {
      transitionContext.completeTransition(false)
      return
    }

    let duration = transitionDuration(using: transitionContext)
    let fromViewHeight = fromView.bounds.height

    transitionContext.containerView.insertSubview(toView, belowSubview: fromView)

    UIView.animate(withDuration: duration, animations: {
      fromView.transform = CGAffineTransform(translationX: 0, y: fromViewHeight)
    }) { completed in
      fromView.transform = .identity
      transitionContext.completeTransition(completed)
    }
  }
}
