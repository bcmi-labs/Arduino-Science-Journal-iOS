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

import MaterialComponents.MaterialDialogs
import MaterialComponents.MaterialSnackbar

#if SCIENCEJOURNAL_DEV_BUILD || SCIENCEJOURNAL_DOGFOOD_BUILD
public extension Notification.Name {
  /// Posted when root data should be created to test the claim flow.
  static let DEBUG_createRootUserData = NSNotification.Name("GSJ_DEBUG_CreateRootUserData")
  /// Posted when the current user should now be destroyed.
  static let DEBUG_destroyCurrentUser = NSNotification.Name("GSJ_DEBUG_DestroyCurrentUser")
  /// Posted when auth should be forced to test the migration flow.
  static let DEBUG_forceAuth = NSNotification.Name("GSJ_DEBUG_ForceAuth")
}
#endif  // SCIENCEJOURNAL_DEV_BUILD || SCIENCEJOURNAL_DOGFOOD_BUILD

/// A view controller that presents users with a list of various settings.
class SettingsViewController: MaterialHeaderCollectionViewController {

  // MARK: - Data model

  enum SettingsItemType {
    case settingButton
    case settingSwitch
  }
  
  enum SettingsItemAccessory {
    case button(_ action: Selector, _ title: String)
    case `switch`(_ action: Selector, _ inOn: Bool)
    case icon(_ action: Selector)
  }
  
  enum SettingsItem {
    case header(_ text: String)
    case separator
    case item(_ title: String, _ subtitle: String?, _ accessory: SettingsItemAccessory?, _ isColored: Bool)
    case accountItem(_ title: String, _ subtitle: String?, _ image: UIImage?, _ externalLinkLabel: String, 
    _ buttonLabel: String, _ externalLinkAction: Selector, _ buttonAction: Selector)
    case button(_ title: String, _ buttonAction: Selector)
    
    var height: CGFloat {
      switch self {
      case .header: return 52
      case .item: return 52
      case .separator: return 9
      case .accountItem: return 160
      case .button: return 52
      }
    }
  }
  
  // MARK: - Constants

  let headerCellIdentifier = "SettingsHeaderCell"
  let separatorCellIdentifier = "SettingsSeparatorCell"
  let itemCellIdentifier = "SettingsItemCell"
  let accountCellIdentifier = "SettingsAccountCell"
  let buttonCellIdentifier = "SettingsButtonCell"

  // MARK: - Properties

  private var rows: [SettingsItem] = []
  private let driveSyncManager: DriveSyncManager?
  private let accountsManager: AccountsManager
  private let userManager: UserManager
  private let preferenceManager: PreferenceManager

  // MARK: - Public

  /// Designated initializer.
  ///
  /// - Parameters:
  ///   - analyticsReporter: The analytics reporter.
  ///   - driveSyncManager: The drive sync manager.
  ///   - preferenceManager: The preference manager.
  init(analyticsReporter: AnalyticsReporter,
       driveSyncManager: DriveSyncManager?,
       accountsManager: AccountsManager,
       userManager: UserManager,
       preferenceManager: PreferenceManager) {
    self.preferenceManager = preferenceManager
    self.driveSyncManager = driveSyncManager
    self.accountsManager = accountsManager
    self.userManager = userManager
    super.init(analyticsReporter: analyticsReporter)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // Always register collection view cells early to avoid a reload occurring first.
    collectionView?.register(UINib(nibName: "SettingsHeaderCell", bundle: nil),
                             forCellWithReuseIdentifier: headerCellIdentifier)
    collectionView?.register(UINib(nibName: "SettingsSeparatorCell", bundle: nil),
                             forCellWithReuseIdentifier: separatorCellIdentifier)
    collectionView?.register(UINib(nibName: "SettingsItemCell", bundle: nil),
                             forCellWithReuseIdentifier: itemCellIdentifier)
    collectionView?.register(UINib(nibName: "SettingsAccountCell", bundle: nil),
                              forCellWithReuseIdentifier: accountCellIdentifier)
    collectionView?.register(UINib(nibName: "SettingsButtonCell", bundle: nil),
                              forCellWithReuseIdentifier: buttonCellIdentifier)
    
    styler.cellStyle = .default
    collectionView?.backgroundColor = .white

    title = String.actionAccountSettings

    if isPresented {
      appBar.hideStatusBarOverlay()
      let closeMenuItem = MaterialCloseBarButtonItem(target: self,
                                                     action: #selector(closeButtonPressed))
      navigationItem.leftBarButtonItem = closeMenuItem
    } else {
      let backMenuItem = MaterialBackBarButtonItem(target: self,
                                                   action: #selector(backButtonPressed))
      navigationItem.leftBarButtonItem = backMenuItem
    }

    configureSettingsItems()
    
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(close),
                                           name: .userWillBeSignedOut,
                                           object: nil)
    
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(configureSettingsItems),
                                           name: .driveSyncDidEnable,
                                           object: nil)
    
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(configureSettingsItems),
                                           name: .driveSyncDidDisable,
                                           object: nil)
  }

  // MARK: - Private
  
  @objc private func close() {
    if isPresented {
      closeButtonPressed()
    } else {
      backButtonPressed()
    }
  }
  
  // Configure each setting item and add it to the data source.
  @objc private func configureSettingsItems() {
    rows.removeAll()

    if let account = accountsManager.currentAccount {

      let accountImage = UIImage(named: "ic_account_placeholder")
      let externalLinkLabel = "Advanced settings".uppercased()
      let buttonLabel = String.settingsSignOutButton.uppercased()

      rows.append(.accountItem(account.displayName, account.email, accountImage, 
          externalLinkLabel, buttonLabel, #selector(openAdvancedSettings), #selector(signOut)))
      rows.append(.separator)
      
      if account.supportsDriveSync {
        rows.append(.item("Google Drive Sync",
                          nil,
                          .switch(#selector(toggleDriveSync), userManager.isDriveSyncEnabled),
                          true))
        
        if let email = preferenceManager.driveSyncUserEmail {
          rows.append(.item("Google Account", email, .icon(#selector(showMoreInfo)), false))
        } else {
          rows.append(.item("Sign in with your Google account to start using Drive Sync", nil, nil, false))
          rows.append(.button("Learn more".uppercased(), #selector(showMoreInfo)))
        }
        
        if let folder = preferenceManager.driveSyncFolderName {
          rows.append(.item("Sync Folder",
                            folder,
                            .button(#selector(setupDriveSync), "CHANGE"), 
                            false))
        }
      }
    }
    
    collectionView.reloadData()
  }

  // MARK: - User Actions

  @objc private func backButtonPressed() {
    navigationController?.popViewController(animated: true)
  }

  @objc private func closeButtonPressed() {
    dismiss(animated: true)
  }
  
  @objc private func signOut() {
    accountsManager.signOutCurrentAccount()
  }

  // MARK: - Settings Actions

  @objc private func openAdvancedSettings() {
    UIApplication.shared.open(
      URL(string: Constants.ArduinoURLs.advancedSettings + (accountsManager.currentAccount?.ID ?? ""))!,
      options: [:],
      completionHandler: nil)
  }

  @objc private func toggleDriveSync() {
    if userManager.isDriveSyncEnabled {
      accountsManager.disableDriveSync()
    } else {
      setupDriveSync()
    }
  }
  
  @objc private func setupDriveSync() {
    accountsManager.setupDriveSync(fromViewController: self)
  }
  
  @objc private func dataUsageSwitchChanged(sender: UISwitch) {
    let isOptedOut = !sender.isOn
    preferenceManager.hasUserOptedOutOfUsageTracking = isOptedOut
    analyticsReporter.setOptOut(isOptedOut)
  }

  @objc private func showMoreInfo(_ sender: UIButton) {
    let alertController = MDCAlertController(title: nil,
                                             message: String.driveSyncIntroMoreText)
    alertController.addAction(MDCAlertAction(title: String.actionOk))
    alertController.accessibilityViewIsModal = true
    present(alertController, animated: true)
  }

  // MARK: - UICollectionViewDataSource

  override func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
    return rows.count
  }

  override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let settingItem = rows[indexPath.row]
    
    // swiftlint:disable force_cast
    switch settingItem {
    case .accountItem(let title, let subtitle, let image, let externalLinkLabel, let buttonLabel, 
                      let externalLinkAction, let buttonAction):
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: accountCellIdentifier,
                                                    for: indexPath) as! SettingsAccountCell
      cell.titleLabel.text = title
      cell.subtitleLabel.text = subtitle
      cell.imageView.image = image
      cell.externalLink.setTitle(externalLinkLabel, for: .normal)
      cell.button.setTitle(buttonLabel, for: .normal)
      cell.externalLink.addTarget(self, action: externalLinkAction, for: .touchUpInside)
      cell.button.addTarget(self, action: buttonAction, for: .touchUpInside)

      // hide external link for junior accounts
      if accountsManager.currentAccount?.type != .adult {
        cell.externalLinkView.isHidden = true
      }

      return cell

    case .header(let text):
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: headerCellIdentifier,
                                                    for: indexPath) as! SettingsHeaderCell
      cell.textLabel.text = text
      return cell
    case .separator:
      return collectionView.dequeueReusableCell(withReuseIdentifier: separatorCellIdentifier,
                                                for: indexPath)
    case .item(let title, let subtitle, let accessory, let isColored):
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: itemCellIdentifier,
                                                    for: indexPath) as! SettingsItemCell
      cell.titleLabel.text = title
      cell.subtitleLabel.text = subtitle
      cell.titleLabel.numberOfLines = 0

      if isColored {
        cell.titleLabel.textColor = ArduinoColorPalette.tealPalette.tint800
      }
      
      switch accessory {
      case .button(let action, let title):
        let button = WizardButton(title: title, style: .system, size: .regular)
        button.addTarget(self, action: action, for: .touchUpInside)
        cell.accessoryView = button
      case .switch(let action, let isOn):
        let switchControl = UISwitch()
        switchControl.addTarget(self, action: action, for: .valueChanged)
        switchControl.onTintColor = ArduinoColorPalette.tealPalette.tint800
        switchControl.isOn = isOn
        cell.accessoryView = switchControl
      case .icon(let action):
        let icon = UIButton()
        icon.tintColor = ArduinoColorPalette.grayPalette.tint400
        if let image = UIImage(named: "ic_info_36pt") {
          icon.setImage(image, for: UIControl.State.normal)
        }
        icon.addTarget(self, action: action, for: .touchUpInside)
        cell.accessoryView = icon
      default: break
      }
      return cell
    
    case .button(let title, let buttonAction):
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: buttonCellIdentifier,
                                                    for: indexPath) as! SettingsButtonCell
      cell.button.setTitle(title, for: .normal)
      cell.button.addTarget(self, action: buttonAction, for: .touchUpInside)
      return cell
    }
    // swiftlint:enable force_cast
  }
  
  override func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
    let settingsItem = rows[indexPath.row]
    let viewWidth = collectionView.bounds.size.width - view.safeAreaInsetsOrZero.left -
        view.safeAreaInsetsOrZero.right
    return CGSize(width: viewWidth, height: settingsItem.height)
  }
}
