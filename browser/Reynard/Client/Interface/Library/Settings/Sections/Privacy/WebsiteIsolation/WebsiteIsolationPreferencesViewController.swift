//
//  WebsiteIsolationPreferencesViewController.swift
//  Reynard
//
//  Created by Minh Ton on 16/9/26.
//

import GeckoView
import UIKit

final class WebsiteIsolationPreferencesViewController: SettingsTableViewController {
    private let enabledSwitch = UISwitch()
    
    init() {
        super.init(style: .insetGrouped)
        title = NSLocalizedString("Website Isolation", comment: "")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        
        enabledSwitch.isOn = Prefs.WebsiteIsolationPreferences.enabled
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
            footerTitle: NSLocalizedString("Keeps cookies, cache, storage, and connections for each site separate from every other site, so no site can use shared browser state to tell that you also visited another one. This is stricter than the isolation Tracking Protection already applies, and can break sites that rely on cross-site sign-in or shared embeds - if a site stops working, try turning this off for it, or turn it off here entirely.", comment: "")
        )
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = SettingsTableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = NSLocalizedString("Website Isolation", comment: "")
        cell.accessoryView = enabledSwitch
        cell.selectionStyle = .none
        return cell
    }
    
    @objc private func enabledSwitchDidChange(_ sender: UISwitch) {
        Prefs.WebsiteIsolationPreferences.enabled = sender.isOn
        WebsiteIsolationPolicyController.applyWebsiteIsolation()
        reloadOpenTabs()
    }
    
    private func reloadOpenTabs() {
        guard let browserViewController = LibrarySharedUtils.resolvedBrowserViewController(from: self) else {
            return
        }
        for tab in browserViewController.tabManager.regularTabs + browserViewController.tabManager.privateTabs {
            tab.session.reload()
        }
    }
}
