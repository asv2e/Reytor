//
//  FingerprintingProtectionPreferencesViewController.swift
//  Reynard
//
//  Created by Minh Ton on 13/9/26.
//

import GeckoView
import UIKit

final class FingerprintingProtectionPreferencesViewController: SettingsTableViewController {
    private enum UX {
        static let optionIndentationLevel = 1
    }
    
    private enum Row: CaseIterable {
        case enabled
        case letterboxing
        case blockWebRTC
        case spoofAcceptLanguage
    }
    
    private let fingerprintingProtectionSwitch = UISwitch()
    private let letterboxingSwitch = UISwitch()
    private let blockWebRTCSwitch = UISwitch()
    private let spoofAcceptLanguageSwitch = UISwitch()
    
    private var displayedRows: [Row] {
        return Prefs.FingerprintingProtectionPreferences.enabled ? Row.allCases : [.enabled]
    }
    
    init() {
        super.init(style: .insetGrouped)
        title = NSLocalizedString("Fingerprinting Protection", tableName: "SettingsLocalizable", comment: "")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        
        fingerprintingProtectionSwitch.isOn = Prefs.FingerprintingProtectionPreferences.enabled
        fingerprintingProtectionSwitch.addTarget(self, action: #selector(fingerprintingProtectionSwitchDidChange), for: .valueChanged)
        
        letterboxingSwitch.isOn = Prefs.FingerprintingProtectionPreferences.letterboxingEnabled
        letterboxingSwitch.addTarget(self, action: #selector(letterboxingSwitchDidChange), for: .valueChanged)
        
        blockWebRTCSwitch.isOn = Prefs.FingerprintingProtectionPreferences.blocksWebRTC
        blockWebRTCSwitch.addTarget(self, action: #selector(blockWebRTCSwitchDidChange), for: .valueChanged)
        
        spoofAcceptLanguageSwitch.isOn = Prefs.FingerprintingProtectionPreferences.spoofsAcceptLanguage
        spoofAcceptLanguageSwitch.addTarget(self, action: #selector(spoofAcceptLanguageSwitchDidChange), for: .valueChanged)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedRows.count
    }
    
    override func sectionText(for section: Int) -> SettingsSectionText {
        return SettingsSectionText(
            footerTitle: NSLocalizedString("Makes it harder for websites to identify or track your device by making it look more like other Reynard users. Some sites may load or behave differently while this is on.", tableName: "SettingsLocalizable", comment: "")
        )
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard displayedRows.indices.contains(indexPath.row) else {
            return UITableViewCell()
        }
        
        switch displayedRows[indexPath.row] {
        case .enabled:
            let cell = SettingsTableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = NSLocalizedString("Fingerprinting Protection", tableName: "SettingsLocalizable", comment: "")
            cell.accessoryView = fingerprintingProtectionSwitch
            cell.selectionStyle = .none
            return cell
        case .letterboxing:
            let cell = SettingsTableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = NSLocalizedString("Letterbox Page Size", tableName: "SettingsLocalizable", comment: "")
            cell.indentationLevel = UX.optionIndentationLevel
            cell.accessoryView = letterboxingSwitch
            cell.selectionStyle = .none
            return cell
        case .blockWebRTC:
            let cell = SettingsTableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = NSLocalizedString("Block WebRTC", tableName: "SettingsLocalizable", comment: "")
            cell.indentationLevel = UX.optionIndentationLevel
            cell.accessoryView = blockWebRTCSwitch
            cell.selectionStyle = .none
            return cell
        case .spoofAcceptLanguage:
            let cell = SettingsTableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = NSLocalizedString("Use Generic Language for Websites", tableName: "SettingsLocalizable", comment: "")
            cell.indentationLevel = UX.optionIndentationLevel
            cell.accessoryView = spoofAcceptLanguageSwitch
            cell.selectionStyle = .none
            return cell
        }
    }
    
    @objc private func fingerprintingProtectionSwitchDidChange(_ sender: UISwitch) {
        let optionIndexPaths = [
            IndexPath(row: 1, section: 0),
            IndexPath(row: 2, section: 0),
            IndexPath(row: 3, section: 0),
        ]
        Prefs.FingerprintingProtectionPreferences.enabled = sender.isOn
        applyAndReloadTabs()
        tableView.performBatchUpdates {
            if sender.isOn {
                tableView.insertRows(at: optionIndexPaths, with: .automatic)
            } else {
                tableView.deleteRows(at: optionIndexPaths, with: .automatic)
            }
        }
    }
    
    @objc private func letterboxingSwitchDidChange(_ sender: UISwitch) {
        Prefs.FingerprintingProtectionPreferences.letterboxingEnabled = sender.isOn
        applyAndReloadTabs()
    }
    
    @objc private func blockWebRTCSwitchDidChange(_ sender: UISwitch) {
        Prefs.FingerprintingProtectionPreferences.blocksWebRTC = sender.isOn
        applyAndReloadTabs()
    }
    
    @objc private func spoofAcceptLanguageSwitchDidChange(_ sender: UISwitch) {
        Prefs.FingerprintingProtectionPreferences.spoofsAcceptLanguage = sender.isOn
        applyAndReloadTabs()
    }
    
    private func applyAndReloadTabs() {
        FingerprintingProtectionPolicyController.applyFingerprintingProtection()
        
        guard let browserViewController = LibrarySharedUtils.resolvedBrowserViewController(from: self) else {
            return
        }
        for tab in browserViewController.tabManager.regularTabs + browserViewController.tabManager.privateTabs {
            tab.session.reload()
        }
    }
}
