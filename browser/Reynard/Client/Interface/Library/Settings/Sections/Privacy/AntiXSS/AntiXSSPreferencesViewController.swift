//
//  AntiXSSPreferencesViewController.swift
//  Reynard
//
//  Created by Minh Ton on 13/9/26.
//

import UIKit

final class AntiXSSPreferencesViewController: SettingsTableViewController {
    private let enabledSwitch = UISwitch()
    
    init() {
        super.init(style: .insetGrouped)
        title = NSLocalizedString("Anti-XSS Protection", comment: "")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        
        enabledSwitch.isOn = Prefs.AntiXSSPreferences.enabled
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
            footerTitle: NSLocalizedString("Warns before loading a link whose address contains a pattern commonly used in cross-site scripting (XSS) attacks, similar to the XSS filters older versions of Chrome and Safari used to ship. This is a heuristic, client-side check - it can occasionally flag a harmless link, and it can't catch every attack, so it isn't a substitute for a site's own security.", comment: "")
        )
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = SettingsTableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = NSLocalizedString("Anti-XSS Protection", comment: "")
        cell.accessoryView = enabledSwitch
        cell.selectionStyle = .none
        return cell
    }
    
    @objc private func enabledSwitchDidChange(_ sender: UISwitch) {
        Prefs.AntiXSSPreferences.enabled = sender.isOn
    }
}
