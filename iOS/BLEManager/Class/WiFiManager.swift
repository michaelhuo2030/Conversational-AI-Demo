//
//  WiFiManager.swift
//  DistributionTool
//
//  Created by LiaoChenliang on 2025/3/4.
//

import Foundation
import CoreLocation
import SystemConfiguration.CaptiveNetwork

public class WiFiManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var completion: ((String?) -> Void)?

    override public init() {
        super.init()
        requestLocationPermission()
        locationManager.delegate = self
    }

    private func _log(_ info: String) {
        // print("info  - \(info)")
    }

    func requestLocationPermission() {
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted,
             .denied:
            _log("用户拒绝或限制了位置服务权限，请在设置中开启")
        // 可以在这里提示用户手动去设置中开启权限
        case .authorizedWhenInUse,
             .authorizedAlways:
            _log("已授权使用位置服务")
        // 在这里可以进行获取 Wi-Fi SSID 的操作
        @unknown default:
            break
        }
    }

    public func getWiFiSSID(completion: @escaping (String?) -> Void) {
        self.completion = completion
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted,
             .denied:
            _log("未授权使用位置服务，无法获取 Wi-Fi SSID")
            completion(nil)
        case .authorizedWhenInUse,
             .authorizedAlways:
            if #available(iOS 14.0, *) {
                if locationManager.accuracyAuthorization == .reducedAccuracy {
                    _log("未开启精确位置服务，无法获取 Wi-Fi SSID")
                    completion(nil)
                } else {
                    fetchWiFiSSID()
                }
            } else {
                fetchWiFiSSID()
            }
        @unknown default:
            completion(nil)
        }
    }

    private func fetchWiFiSSID() {
        if let interfaces = CNCopySupportedInterfaces() as NSArray? {
            for interface in interfaces {
                if let interfaceName = interface as? String,
                   let info = CNCopyCurrentNetworkInfo(interfaceName as CFString) as NSDictionary? {
                    let ssid = info["SSID"] as? String
                    completion?(ssid)
                    return
                }
            }
        }
        completion?(nil)
    }

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse,
             .authorizedAlways:
            if #available(iOS 14.0, *) {
                if locationManager.accuracyAuthorization == .reducedAccuracy {
                    _log("未开启精确位置服务，无法获取 Wi-Fi SSID")
                    completion?(nil)
                } else {
                    fetchWiFiSSID()
                }
            } else {
                fetchWiFiSSID()
            }
        default:
            _log("未授权使用位置服务，无法获取 Wi-Fi SSID")
            completion?(nil)
        }
    }

    @available(iOS 14.0, *) public func locationManager(_ manager: CLLocationManager, didChangeAccuracyAuthorization accuracyAuthorization: CLAccuracyAuthorization) {
        if accuracyAuthorization == .reducedAccuracy {
            _log("未开启精确位置服务，无法获取 Wi-Fi SSID")
            completion?(nil)
        } else {
            fetchWiFiSSID()
        }
    }
}
