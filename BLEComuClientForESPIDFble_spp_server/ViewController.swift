//
//  ViewController.swift
//  BLEComuClientForESPIDFble_spp_server
//
//  Created by Yuuan on 2019/11/26.
//  Copyright © 2019 Yuuan. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController,CBCentralManagerDelegate, CBPeripheralDelegate {
    // セントラルマネージャの状態が変化すると呼ばれる
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("state: \(central.state)")
    }
    
    private var isScanning = false
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!
    private var SPP_DATA_RECV_CHAR_Characteristic: CBCharacteristic!
    private var SPP_DATA_NOTIFY_CHAR_Characteristic: CBCharacteristic!
    private var SPP_COMMAND_CHAR_Characteristic: CBCharacteristic!
    private var SPP_STATUS_CHAR_Characteristic: CBCharacteristic!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // セントラルマネージャ初期化
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    
    // 周辺にあるデバイス＝ペリフェラルを発見すると呼ばれる
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("発見したBLEデバイス: \(peripheral)")
        
        self.peripheral = peripheral
    
        // name に ESP_SPP_SERVER を含むなら接続を試みる
        if let name = peripheral.name, name.hasPrefix("ESP_SPP_SERVER"){
            centralManager.stopScan()
            print("ESP_SPP_SERVER発見。接続を試みる。")
            self.centralManager.connect(peripheral, options: nil)
        }
    }
    
    
    // ペリフェラルへの接続に成功した時に呼ばれる
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("接続成功")
        
        // ペリフェラルのサービスを探索する
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    
    // サービス発見時に呼ばれるメソッド
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let services: NSArray = peripheral.services! as NSArray
        print("\(services.count)個のサービスを発見 \(services)")
        for obj in services {
            if let services = obj as? CBService{
                // ペリフェラルのサービスのキャラクタリスティックを探索する
                peripheral.discoverCharacteristics(nil, for: services)
            }
        }
    }
    
    
    // キャラクタリスティック発見時に呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let characteristics: NSArray = service.characteristics! as NSArray
        print("\(characteristics.count) 個のキャラクタリスティックを発見 \(characteristics)")
        //ここで表示が出るpropertiesについては、iOSxBLEの本の149ページが詳しい。
        
        var str = "(characteristic.uuid)"
        
        for obj in characteristics{
            if let characteristic = obj as? CBCharacteristic{
                str = characteristic.uuid.uuidString
                switch str{
                case "ABF1":
                    SPP_DATA_RECV_CHAR_Characteristic = characteristic
                    print("SPP_DATA_RECV_CHAR charasteristic ABF1 発見")
                case "ABF2":
                    SPP_DATA_NOTIFY_CHAR_Characteristic = characteristic
                    print("SPP_DATA_NOTIFY_CHAR charasteristic ABF2 発見")
                case "ABF3":
                    SPP_COMMAND_CHAR_Characteristic = characteristic
                    print("SPP_COMMAND_CHAR charasteristic ABF3 発見")
                case "ABF4":
                    SPP_STATUS_CHAR_Characteristic = characteristic
                    print("SPP_STATUS_CHAR charasteristic ABF4 発見")
                default: break
                }
            }
        }
    }
    
    
    @IBAction func scanButtonTapped(_ sender: UIButton) {
        if !isScanning{
            // 周辺にあるデバイス＝ペリフェラルを探す
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            isScanning = true
            print("scan started")
            sender.setTitle("STOP SCAN", for: UIControl.State.normal)
        }else{
            centralManager.stopScan()
            isScanning = false
            print("scan stopped")
            sender.setTitle("START SCAN", for: UIControl.State.normal)
        }
    }
    
    
    @IBAction func writeButtonTapped(_ sender: UIButton) {
        // 書き込むデータはabcdefg
        let wrdata: NSData! = "abcdefg\n".data(using: String.Encoding.utf8) as NSData?
        
        peripheral.writeValue(wrdata as Data, for: SPP_DATA_RECV_CHAR_Characteristic, type: CBCharacteristicWriteType.withoutResponse)
        print("ABF1 書いた")
        
        peripheral.readValue(for: SPP_STATUS_CHAR_Characteristic)
        print("ABF4 読んだ")

    }
    
    
    // 読み込みが完了すると呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("読んだ内容... service uuid: \(characteristic.service.uuid), characteristic uuid: \(characteristic.uuid), value: \(characteristic.value)")
    }
    
    
    // 書き込みが完了すると呼ばれる
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("書き込み成功")
    }

}

