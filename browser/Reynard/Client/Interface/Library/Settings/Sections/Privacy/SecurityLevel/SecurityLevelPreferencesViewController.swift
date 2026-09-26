//
//  SecurityLevelPreferencesViewController.swift
//  Reynard
//
//  Created by Minh Ton on 19/9/26.
//

import GeckoView
import UIKit

final class SecurityLevelPreferencesViewController: SettingsTableViewController {
    init() {
        super.init(style: .insetGrouped)
        title = NSLocalizedString("Security Level", comment: "")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SecurityLevel.allCases.count
    }
    
    override func sectionText(for section: Int) -> SettingsSectionText {
        return SettingsSectionText(
            footerTitle: NSLocalizedString("A shortcut for JavaScript, Fingerprinting Protection, and Website Isolation together - the same three settings are still available individually below if you want to mix and match instead. Turning any of them on or off by hand here no longer matches a preset exactly, so none will show as selected until you pick one again.", comment: "")
        )
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard SecurityLevel.allCases.indices.contains(indexPath.row) else {
            return UITableViewCell()
        }
        
        let level = SecurityLevel.allCases[indexPath.row]
        let cell = SettingsTableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = level.title
        cell.detailTextLabel?.text = level.subtitle
        cell.detailTextLabel?.numberOfLines = 0
        cell.accessoryType = SecurityLevelController.matchesStoredPreset(level) ? .checkmark : .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        guard SecurityLevel.allCases.indices.contains(indexPath.row) else {
            return
        }
        
        SecurityLevelController.apply(SecurityLevel.allCases[indexPath.row])
        tableView.reloadData()
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
