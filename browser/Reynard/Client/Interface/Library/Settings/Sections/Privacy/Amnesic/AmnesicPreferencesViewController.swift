//
//  AmnesicPreferencesViewController.swift
//  Reynard
//
//  Created by Minh Ton on 16/9/26.
//

import UIKit

final class AmnesicPreferencesViewController: SettingsTableViewController {
    private let enabledSwitch = UISwitch()
    
    init() {
        super.init(style: .insetGrouped)
        title = NSLocalizedString("Amnesic Mode", comment: "")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        
        enabledSwitch.isOn = Prefs.AmnesicPreferences.enabled
        enabledSwitch.addTarget(self, action: #selector(enabledSwitchDidChange), for: .valueChanged)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func sectionText(for section: Int) -> SettingsSectionText {
        return SettingsSectionText(
            footerTitle: NSLocalizedString("Every tab behaves like a private tab: no history, cookies, cache, or list of open tabs is ever saved to disk. Turning this on clears history, cookies, cache, and the saved tab list immediately. It applies to new tabs going forward - tabs already open keep their current mode until you close and reopen them.", comment: "")
        )
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = SettingsTableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = NSLocalizedString("Amnesic Mode", comment: "")
        cell.accessoryView = enabledSwitch
        cell.selectionStyle = .none
        return cell
    }
    
    @objc private func enabledSwitchDidChange(_ sender: UISwitch) {
        AmnesicModeController.setEnabled(sender.isOn)
    }
}
