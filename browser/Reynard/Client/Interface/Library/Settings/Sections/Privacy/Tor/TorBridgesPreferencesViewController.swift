//
//  TorBridgesPreferencesViewController.swift
//  Reynard
//
//  Created by Minh Ton on 16/9/26.
//

import UIKit

final class TorBridgesPreferencesViewController: SettingsTableViewController {
    private enum Row: CaseIterable {
        case useBridges
        case editBridges
    }
    
    private let useBridgesSwitch = UISwitch()
    
    private var displayedRows: [Row] {
        return Prefs.TorPreferences.usesBridges ? Row.allCases : [.useBridges]
    }
    
    init() {
        super.init(style: .insetGrouped)
        title = NSLocalizedString("Bridges", comment: "")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        
        useBridgesSwitch.isOn = Prefs.TorPreferences.usesBridges
        useBridgesSwitch.addTarget(self, action: #selector(useBridgesSwitchDidChange), for: .valueChanged)
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
            footerTitle: NSLocalizedString("A bridge is a Tor relay that isn't publicly listed, for connecting when your network blocks known Tor relay addresses. Plain, obfs4, and Snowflake bridge lines are supported. meek and webtunnel bridge lines are still ignored - this app doesn't have a working transport for those.", comment: "")
        )
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard displayedRows.indices.contains(indexPath.row) else {
            return UITableViewCell()
        }
        
        switch displayedRows[indexPath.row] {
        case .useBridges:
            let cell = SettingsTableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = NSLocalizedString("Use a Bridge", comment: "")
            cell.accessoryView = useBridgesSwitch
            cell.selectionStyle = .none
            return cell
        case .editBridges:
            let lineCount = Prefs.TorPreferences.bridgeLines
                .split(separator: "\n")
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
                .count
            let cell = SettingsTableViewCell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = NSLocalizedString("Bridge Lines", comment: "")
            cell.detailTextLabel?.text = lineCount == 0
                ? NSLocalizedString("None", comment: "")
                : String(format: NSLocalizedString("%d Configured", comment: ""), lineCount)
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        guard displayedRows.indices.contains(indexPath.row), displayedRows[indexPath.row] == .editBridges else {
            return
        }
        
        let destination = TorBridgesEditorViewController()
        navigationController?.pushViewController(destination, animated: true)
    }
    
    @objc private func useBridgesSwitchDidChange(_ sender: UISwitch) {
        Prefs.TorPreferences.usesBridges = sender.isOn
        
        tableView.performBatchUpdates {
            let bridgeLinesIndexPath = [IndexPath(row: 1, section: 0)]
            if sender.isOn {
                tableView.insertRows(at: bridgeLinesIndexPath, with: .automatic)
            } else {
                tableView.deleteRows(at: bridgeLinesIndexPath, with: .automatic)
            }
        }
        
        TorController.shared.reconnect()
    }
}
