//
//  IOTPreferenceManager.swift
//  ConvoAI
//
//  Created by qinhui on 2025/3/7.
//

import Foundation

// MARK: - Delegate Protocol
protocol IOTPreferenceManagerDelegate: AnyObject {
    func preferenceManager(_ manager: IOTPreferenceManager, didRemovedDevice device: IOTDevice)
    func preferenceManager(_ manager: IOTPreferenceManager, didAddedDevice device: IOTDevice)
    func preferenceManager(_ manager: IOTPreferenceManager, presetDidUpdated preset: CovIotPreset)
    func preferenceManager(_ manager: IOTPreferenceManager, languageDidUpdated language: CovIotLanguage)
    func preferenceManager(_ manager: IOTPreferenceManager, aiVadStateDidUpdated state: Bool)
    func preferenceManager(_ manager: IOTPreferenceManager, didUpdatedDevice device: IOTDevice)
}

// MARK: - Manager Protocol
protocol IOTPreferenceManagerProtocol: AnyObject {
    func addDelegate(_ delegate: IOTPreferenceManagerDelegate)
    func removeDelegate(_ delegate: IOTPreferenceManagerDelegate)
    func setPresets(presets: [CovIotPreset])
    func deleteAllPresets()
    func allPresets() -> [CovIotPreset]?
    func allDevices() -> [IOTDevice]?
    
    // Additional methods
    func addDevice(device: IOTDevice)
    func removeDevice(deviceId: String)
    
    func updatePreset(_ preset: CovIotPreset)
    func updateLanguage(_ language: CovIotLanguage)
    func updateAiVadState(_ state: Bool)
    
    var currentPreset: CovIotPreset? { get }
    var currentLanguage: CovIotLanguage? { get }
    var isAiVadEnabled: Bool { get }
    
    func updateDeviceName(deviceId: String, newName: String)
}

// MARK: - Preference Model
class IOTPreference {
    var preset: CovIotPreset?
    var language: CovIotLanguage?
    var aiVad = false
}

// MARK: - Manager Implementation
class IOTPreferenceManager: IOTPreferenceManagerProtocol {
    var preference = IOTPreference()
    private var presets: [CovIotPreset]?
    private var devices: [IOTDevice]?
    private var delegates = NSHashTable<AnyObject>.weakObjects()
    
    init() {
        // Initialize with default values if needed
        preference.aiVad = false
    }
    
    // MARK: - Public Properties
    var currentPreset: CovIotPreset? {
        return preference.preset
    }
    
    var currentLanguage: CovIotLanguage? {
        return preference.language
    }
    
    var isAiVadEnabled: Bool {
        return preference.aiVad
    }
    
    // MARK: - Delegate Management
    func addDelegate(_ delegate: IOTPreferenceManagerDelegate) {
        delegates.add(delegate)
    }
    
    func removeDelegate(_ delegate: IOTPreferenceManagerDelegate) {
        delegates.remove(delegate)
    }
    
    // MARK: - Preset Management
    func setPresets(presets: [CovIotPreset]) {
        self.presets = presets
        
        // If no current preset is set, set the first preset as default
        if preference.preset == nil, let firstPreset = presets.first {
            updatePreset(firstPreset)
        }
    }
    
    func deleteAllPresets() {
        presets = nil
        preference.preset = nil
    }
    
    func allDevices() -> [IOTDevice]? {
        return devices
    }
    
    func allPresets() -> [CovIotPreset]? {
        return presets
    }
    
    // MARK: - Update Methods
    func addDevice(device: IOTDevice) {
        if devices == nil {
            devices = []
        }
        
        // Check if device already exists
        guard !devices!.contains(where: { $0.deviceId == device.deviceId }) else {
            return
        }
        
        // Add device to the beginning of the array
        devices!.insert(device, at: 0)
        
        // Notify delegates
        notifyDelegates { $0.preferenceManager(self, didAddedDevice: device) }
        
        // Save to UserDefaults
        saveDevices()
    }
    
    func removeDevice(deviceId: String) {
        guard let index = devices?.firstIndex(where: { $0.deviceId == deviceId }) else {
            return
        }
        
        let device = devices![index]
        devices?.remove(at: index)
        
        // Notify delegates
        notifyDelegates { $0.preferenceManager(self, didRemovedDevice: device) }
        
        // Save to UserDefaults
        saveDevices()
    }
    
    func updatePreset(_ preset: CovIotPreset) {
        preference.preset = preset
        
        // If no language is set, set the first supported language as default
        if preference.language == nil {
            let defaultLanguage = preset.support_languages.first { $0.isDefault } ?? preset.support_languages.first
            if let language = defaultLanguage {
                updateLanguage(language)
            }
        }
        
        notifyDelegates { $0.preferenceManager(self, presetDidUpdated: preset) }
    }
    
    func updateLanguage(_ language: CovIotLanguage) {
        preference.language = language
        notifyDelegates { $0.preferenceManager(self, languageDidUpdated: language) }
    }
    
    func updateAiVadState(_ state: Bool) {
        preference.aiVad = state
        notifyDelegates { $0.preferenceManager(self, aiVadStateDidUpdated: state) }
    }
    
    func updateDeviceName(deviceId: String, newName: String) {
        guard let index = devices?.firstIndex(where: { $0.deviceId == deviceId }) else {
            return
        }
        
        // Create new device with updated name
        let updatedDevice = IOTDevice(name: newName, deviceId: deviceId)
        devices?[index] = updatedDevice
        
        // Notify delegates
        notifyDelegates { $0.preferenceManager(self, didUpdatedDevice: updatedDevice) }
        
        // Save to UserDefaults
        saveDevices()
    }
    
    // MARK: - Private Methods
    private func notifyDelegates(_ notification: (IOTPreferenceManagerDelegate) -> Void) {
        for delegate in delegates.allObjects {
            if let delegate = delegate as? IOTPreferenceManagerDelegate {
                notification(delegate)
            }
        }
    }
    
    private func saveDevices() {
        guard let devices = devices else { return }
        
        if let encoded = try? JSONEncoder().encode(devices) {
            UserDefaults.standard.set(encoded, forKey: "IOTDevices")
        }
    }
    
    private func loadDevices() {
        if let data = UserDefaults.standard.data(forKey: "IOTDevices"),
           let decoded = try? JSONDecoder().decode([IOTDevice].self, from: data) {
            devices = decoded
        }
    }
}

// MARK: - Default Implementation for Delegate Methods
extension IOTPreferenceManagerDelegate {
    func preferenceManager(_ manager: IOTPreferenceManager, didRemovedDevice device: IOTDevice) {}
    func preferenceManager(_ manager: IOTPreferenceManager, didAddedDevice device: IOTDevice) {}
    func preferenceManager(_ manager: IOTPreferenceManager, presetDidUpdated preset: CovIotPreset) {}
    func preferenceManager(_ manager: IOTPreferenceManager, languageDidUpdated language: CovIotLanguage) {}
    func preferenceManager(_ manager: IOTPreferenceManager, aiVadStateDidUpdated state: Bool) {}
    func preferenceManager(_ manager: IOTPreferenceManager, didUpdatedDevice device: IOTDevice) {}
}

struct IOTDevice: Codable {
    let name: String
    let deviceId: String
}

