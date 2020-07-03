//  
//  BLEScienceKitCurrentSensorInterface.swift
//  ScienceJournal
//
//  Created by Emilio Pavia on 02/07/2020.
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
import CoreBluetooth

class BLEScienceKitCurrentSensorInterface: BLESensorInterface {
  var identifier: String

  var serviceId: CBUUID

  var providerId: String

  // FIXME: Localize
  var name: String { "Current" }

  var iconName: String { "mkrsci_sensor_current" }

  var animatingIconName: String { "mkrsci_current" }

  var config: Data?

  var peripheral: CBPeripheral?

  var unitDescription: String? { "A" }

  // FIXME: Localize
  var textDescription: String {
    "The amount of flow of charged " +
    "particles between two places" }

  var hasOptions: Bool { false }

  // FIXME: Change
  var learnMoreInformation: Sensor.LearnMore = Sensor.LearnMore(firstParagraph: "",
                                                                secondParagraph: "",
                                                                imageName: "")

  var characteristic: CBUUID { CBUUID(string: identifier) }

  private var serviceScanner: BLEServiceScanner
  private var peripheralInterface: BLEPeripheralInterface?

  private lazy var clock = Clock()

  required init(providerId: String,
                identifier: String,
                serviceId: CBUUID) {
    self.providerId = providerId
    self.identifier = identifier
    self.serviceId = serviceId
    self.serviceScanner = BLEServiceScanner(services: [serviceId])
  }

  func presentOptions(from viewController: UIViewController, completion: @escaping () -> Void) {

  }

  func connect(_ completion: @escaping (Bool) -> Void) {
    serviceScanner.connectToPeripheral(withIdentifier: providerId) { (peripheral, error) in
      // Stop scanning.
      self.serviceScanner.stopScanning()

      guard peripheral != nil else {
        print("[BluetoothSensor] Error connecting to " +
          "peripheral: \(String(describing: error?.peripheral.name)) " +
          "address: \(String(describing: error?.peripheral.identifier))")
        // TODO: Pass along connection error http://b/64684813
        completion(false)
        return
      }

      self.peripheral = peripheral

      completion(true)
    }
  }

  func startObserving(_ listener: @escaping (DataPoint) -> Void) {
    guard let peripheral = peripheral else { return }

    let interface = BLEPeripheralInterface(peripheral: peripheral,
                                           serviceUUID: serviceId,
                                           characteristicUUIDs: [characteristic])
    interface.updatesForCharacteristic(characteristic, block: { [clock] data in
      let float = data.withUnsafeBytes { $0.load(as: Float.self) }
      let dataPoint = DataPoint(x: clock.millisecondsSince1970,
                                y: Double(float))
      listener(dataPoint)
    })
    self.peripheralInterface = interface
  }

  func stopObserving() {
    peripheralInterface?.stopUpdatesForCharacteristic(characteristic)
  }
}