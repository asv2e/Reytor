//
//  TorPreferencesViewController.swift
//  Reynard
//
//  Created by Minh Ton on 13/9/26.
//

import GeckoView
import UIKit

final class TorPreferencesViewController: SettingsTableViewController {
    private enum Row: CaseIterable, Equatable {
        case enabled
        case status
        case newCircuit
        case bridges
    }
    
    private let torSwitch = UISwitch()
    
    private var displayedRows: [Row] {
        return Prefs.TorPreferences.enabled ? Row.allCases : [.enabled]
    }
    
    init() {
        super.init(style: .insetGrouped)
        title = NSLocalizedString("Tor Network", comment: "")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        
        torSwitch.isOn = Prefs.TorPreferences.enabled
        torSwitch.addTarget(self, action: #selector(torSwitchDidChange), for: .valueChanged)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(connectionStateDidChange),
            name: .torConnectionStateDidChange,
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedRows.count
    }
    
    override func sectionText(for section: Int) -> SettingsSectionText {
        return SettingsSectionText(
            footerTitle: NSLocalizedString("Routes your browsing through the Tor network for extra anonymity. Some sites may load more slowly, and a few may block Tor traffic entirely.", comment: "")
        )
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard displayedRows.indices.contains(indexPath.row) else {
            return UITableViewCell()
        }
        
        switch displayedRows[indexPath.row] {
        case .enabled:
            let cell = SettingsTableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = NSLocalizedString("Connect via Tor", comment: "")
            cell.accessoryView = torSwitch
            cell.selectionStyle = .none
            return cell
        case .status:
            let cell = SettingsTableViewCell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = NSLocalizedString("Status", comment: "")
            cell.detailTextLabel?.text = statusDescription
            cell.selectionStyle = .none
            return cell
        case .newCircuit:
            return SettingsViewUtils.actionCell(title: NSLocalizedString("New Tor Circuit", comment: ""), tintColor: nil)
        case .bridges:
            let cell = SettingsTableViewCell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = NSLocalizedString("Bridges", comment: "")
            cell.detailTextLabel?.text = Prefs.TorPreferences.usesBridges
                ? NSLocalizedString("On", comment: "")
                : NSLocalizedString("Off", comment: "")
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        guard displayedRows.indices.contains(indexPath.row) else {
            return
        }
        
        switch displayedRows[indexPath.row] {
        case .newCircuit:
            TorController.shared.requestNewIdentity()
        case .bridges:
            let destination = TorBridgesPreferencesViewController()
            navigationController?.pushViewController(destination, animated: true)
        case .enabled, .status:
            break
        }
    }
    
    private var statusDescription: String {
        switch TorController.shared.state {
        case .disabled:
            return NSLocalizedString("Not Connected", comment: "")
        case .bootstrapping(let percent):
            return String(format: NSLocalizedString("Connecting… %d%%", comment: ""), percent)
        case .connected:
            return NSLocalizedString("Connected", comment: "")
        case .failed:
            return NSLocalizedString("Connection Failed", comment: "")
        }
    }
    
    @objc private func torSwitchDidChange(_ sender: UISwitch) {
        TorController.shared.setEnabled(sender.isOn)
        
        let statusAndActionIndexPaths = [
            IndexPath(row: 1, section: 0),
            IndexPath(row: 2, section: 0),
            IndexPath(row: 3, section: 0),
        ]
        tableView.performBatchUpdates {
            if sender.isOn {
                tableView.insertRows(at: statusAndActionIndexPaths, with: .automatic)
            } else {
                tableView.deleteRows(at: statusAndActionIndexPaths, with: .automatic)
            }
        }
        
        reloadOpenTabs()
    }
    
    @objc private func connectionStateDidChange() {
        guard Prefs.TorPreferences.enabled, displayedRows.contains(.status) else {
            return
        }
        tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
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
