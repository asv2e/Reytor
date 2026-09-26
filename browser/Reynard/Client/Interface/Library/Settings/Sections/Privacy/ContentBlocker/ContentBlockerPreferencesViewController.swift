//
//  ContentBlockerPreferencesViewController.swift
//  Reynard
//
//  Created by Minh Ton on 18/9/26.
//

import GeckoView
import UIKit

/// Unlike Tracking Protection (Gecko's built-in URL-classifier categories)
/// this is a general-purpose content blocker in the uBlock Origin sense:
/// filter-list-based network and cosmetic (element-hiding) blocking. Rather
/// than reimplementing filter-list parsing and cosmetic filtering from
/// scratch, this installs the real uBlock Origin WebExtension through the
/// app's existing addon runtime (AddonRuntime.shared.install), which goes
/// through the same native permission-prompt flow as any other add-on
/// install - nothing here bypasses that.
final class ContentBlockerPreferencesViewController: SettingsTableViewController {
    // uBlock Origin's real, stable WebExtension ID
    // (browser_specific_settings.gecko.id in its manifest) - unchanged
    // across releases, used to detect whether it's already installed.
    private static let uBlockOriginID = "uBlock0@raymondhill.net"
    private static let uBlockOriginName = "uBlock Origin"
    
    // AMO's documented "always redirects to the current release" URL
    // (announced on Mozilla's own Add-ons blog) rather than a pinned
    // version link that goes stale.
    private static let uBlockOriginInstallURL = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/"
    
    private var installedAddon: Addon? {
        AddonRuntime.shared.installedAddons.first { $0.id == Self.uBlockOriginID }
    }
    
    private var isInstalling = false
    
    init() {
        super.init(style: .insetGrouped)
        title = NSLocalizedString("Content Blocker", comment: "")
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
        
        Task { [weak self] in
            _ = try? await AddonRuntime.shared.list()
            await MainActor.run {
                self?.tableView.reloadData()
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func sectionText(for section: Int) -> SettingsSectionText {
        let footer = installedAddon != nil
            ? NSLocalizedString("uBlock Origin is installed. Manage its filter lists, permissions, and enabled state from its add-on page.", comment: "")
            : NSLocalizedString("Installs uBlock Origin, a well-established, open-source content blocker, from Mozilla's official add-on store. It blocks ads and trackers using filter lists and element hiding, which is different from - and more thorough than - this app's own Tracking Protection. You'll be asked to approve its permissions before installation completes, the same as any add-on.", comment: "")
        return SettingsSectionText(footerTitle: footer)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let installedAddon {
            let cell = SettingsTableViewCell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = installedAddon.metaData.name ?? Self.uBlockOriginName
            cell.detailTextLabel?.text = installedAddon.metaData.enabled
                ? NSLocalizedString("On", comment: "")
                : NSLocalizedString("Off", comment: "")
            cell.accessoryType = .disclosureIndicator
            return cell
        }
        
        let cell = SettingsTableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = isInstalling
            ? NSLocalizedString("Installing…", comment: "")
            : NSLocalizedString("Install Content Blocker", comment: "")
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = isInstalling ? .secondaryLabel : .systemBlue
        cell.selectionStyle = isInstalling ? .none : .default
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        
        if let installedAddon {
            let destination = AddonDetailsPreferencesViewController(
                addonID: installedAddon.id,
                addonName: installedAddon.metaData.name ?? Self.uBlockOriginName
            )
            navigationController?.pushViewController(destination, animated: true)
            return
        }
        
        guard !isInstalling else {
            return
        }
        install()
    }
    
    private func install() {
        isInstalling = true
        tableView.reloadData()
        
        Task { [weak self] in
            guard let self else {
                return
            }
            
            do {
                let addon = try await AddonRuntime.shared.install(
                    url: Self.uBlockOriginInstallURL,
                    installMethod: .manager
                )
                await MainActor.run {
                    self.isInstalling = false
                    self.tableView.reloadData()
                    let destination = AddonDetailsPreferencesViewController(
                        addonID: addon.id,
                        addonName: addon.metaData.name ?? Self.uBlockOriginName
                    )
                    self.navigationController?.pushViewController(destination, animated: true)
                }
            } catch {
                await MainActor.run {
                    self.isInstalling = false
                    self.tableView.reloadData()
                    AlertPresenter.show(
                        title: NSLocalizedString("Couldn't Install", comment: ""),
                        message: NSLocalizedString("The content blocker couldn't be installed. Check your connection - or that you approved its permissions - and try again.", comment: ""),
                        buttons: [AlertPresenter.Button(title: NSLocalizedString("OK", comment: ""))]
                    )
                }
            }
        }
    }
}
