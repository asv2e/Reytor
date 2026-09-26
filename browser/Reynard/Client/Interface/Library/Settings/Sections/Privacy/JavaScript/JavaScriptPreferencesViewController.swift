//
//  JavaScriptPreferencesViewController.swift
//  Reynard
//
//  Created by Minh Ton on 13/9/26.
//

import GeckoView
import UIKit

final class JavaScriptPreferencesViewController: SettingsTableViewController {
    private enum Section: CaseIterable {
        case `default`
        case exceptions
        case reset

        var text: SettingsSectionText {
            switch self {
            case .default:
                return SettingsSectionText(
                    footerTitle: NSLocalizedString("When on, JavaScript is blocked on every site unless you allow it below. Most sites need JavaScript to work properly.", comment: "")
                )
            case .exceptions:
                return SettingsSectionText(headerTitle: NSLocalizedString("Site Exceptions", comment: ""))
            case .reset:
                return SettingsSectionText()
            }
        }
    }

    private enum Row {
        case blockByDefault
        case site(SiteSettingsRecord)
        case reset
    }

    private let blockByDefaultSwitch = UISwitch()
    private let exceptionSwitchReuseIdentifier = "ExceptionSwitch"
    private var exceptions: [SiteSettingsRecord] = []

    private var displayedSections: [Section] {
        return Section.allCases.filter { section in
            switch section {
            case .default:
                return true
            case .exceptions:
                return !exceptions.isEmpty
            case .reset:
                return !exceptions.isEmpty
            }
        }
    }

    init() {
        super.init(style: .insetGrouped)
        title = NSLocalizedString("JavaScript", comment: "")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        blockByDefaultSwitch.isOn = Prefs.JavaScriptPreferences.blocksByDefault
        blockByDefaultSwitch.addTarget(self, action: #selector(blockByDefaultSwitchDidChange), for: .valueChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadExceptions()
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return displayedSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard displayedSections.indices.contains(section) else {
            return 0
        }

        switch displayedSections[section] {
        case .default:
            return 1
        case .exceptions:
            return exceptions.count
        case .reset:
            return 1
        }
    }

    override func sectionText(for section: Int) -> SettingsSectionText {
        guard displayedSections.indices.contains(section) else {
            return SettingsSectionText()
        }
        return displayedSections[section].text
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = row(at: indexPath) else {
            return UITableViewCell()
        }

        switch row {
        case .blockByDefault:
            let cell = SettingsTableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = NSLocalizedString("Block JavaScript by Default", comment: "")
            cell.accessoryView = blockByDefaultSwitch
            cell.selectionStyle = .none
            return cell
        case .site(let setting):
            let cell = SettingsTableViewCell(style: .default, reuseIdentifier: exceptionSwitchReuseIdentifier)
            cell.textLabel?.text = setting.host
            let allowSwitch = UISwitch()
            allowSwitch.isOn = setting.javascriptBlocked == false
            allowSwitch.tag = indexPath.row
            allowSwitch.addTarget(self, action: #selector(exceptionSwitchDidChange(_:)), for: .valueChanged)
            cell.accessoryView = allowSwitch
            cell.selectionStyle = .none
            return cell
        case .reset:
            let cell = SettingsTableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = NSLocalizedString("Remove All Exceptions", comment: "")
            cell.textLabel?.textColor = .systemRed
            cell.textLabel?.textAlignment = .center
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        guard let row = row(at: indexPath), case .reset = row else {
            return
        }

        _ = SiteSettingsStore.shared.clearAllJavaScriptBlockedSettings()
        reloadExceptions()
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let row = row(at: indexPath), case .site(let setting) = row else {
            return nil
        }

        let deleteAction = UIContextualAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")) { [weak self] _, _, completion in
            _ = SiteSettingsStore.shared.setJavaScriptBlocked(nil, forHost: setting.host)
            self?.reloadExceptions()
            self?.tableView.reloadData()
            completion(true)
        }

        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
    }

    private func reloadExceptions() {
        exceptions = SiteSettingsStore.shared.settingsWithJavaScriptBlocked()
    }

    private func setException(allowed: Bool, host: String) {
        _ = SiteSettingsStore.shared.setJavaScriptBlocked(!allowed, forHost: host)
        reloadExceptions()
    }

    private func row(at indexPath: IndexPath) -> Row? {
        guard displayedSections.indices.contains(indexPath.section) else {
            return nil
        }

        switch displayedSections[indexPath.section] {
        case .default:
            guard indexPath.row == 0 else {
                return nil
            }
            return .blockByDefault
        case .exceptions:
            guard exceptions.indices.contains(indexPath.row) else {
                return nil
            }
            return .site(exceptions[indexPath.row])
        case .reset:
            guard indexPath.row == 0 else {
                return nil
            }
            return .reset
        }
    }

    @objc private func blockByDefaultSwitchDidChange(_ sender: UISwitch) {
        Prefs.JavaScriptPreferences.blocksByDefault = sender.isOn
        reloadOpenTabs()
    }

    @objc private func exceptionSwitchDidChange(_ sender: UISwitch) {
        guard exceptions.indices.contains(sender.tag) else {
            return
        }
        setException(allowed: sender.isOn, host: exceptions[sender.tag].host)
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
