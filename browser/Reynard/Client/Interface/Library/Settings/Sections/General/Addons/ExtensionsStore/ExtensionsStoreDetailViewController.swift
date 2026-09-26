//
//  ExtensionsStoreDetailViewController.swift
//  Reynard
//
//  Created by Minh Ton on 19/9/26.
//

import GeckoView
import UIKit

final class ExtensionsStoreDetailViewController: SettingsTableViewController {
    private enum Row: Equatable {
        case summary
        case action
    }
    
    private let listing: AMOAddonListing
    private var isInstalling = false
    private weak var headerIconView: UIImageView?
    
    private var installedAddon: Addon? {
        AddonRuntime.shared.installedAddons.first { $0.id == listing.guid }
    }
    
    private var rows: [Row] {
        (listing.summary?.isEmpty == false) ? [.summary, .action] : [.action]
    }
    
    init(listing: AMOAddonListing) {
        self.listing = listing
        super.init(style: .insetGrouped)
        title = listing.name ?? listing.slug
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        tableView.tableHeaderView = makeHeaderView()
        loadIcon()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard rows.indices.contains(indexPath.row) else {
            return UITableViewCell()
        }
        
        switch rows[indexPath.row] {
        case .summary:
            let cell = SettingsTableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = listing.summary
            cell.textLabel?.numberOfLines = 0
            cell.selectionStyle = .none
            return cell
        case .action:
            if let installedAddon {
                let cell = SettingsTableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = NSLocalizedString("Installed", comment: "")
                cell.textLabel?.textAlignment = .center
                cell.textLabel?.textColor = .secondaryLabel
                cell.accessoryType = .disclosureIndicator
                _ = installedAddon
                return cell
            }
            
            let cell = SettingsTableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = isInstalling
                ? NSLocalizedString("Installing…", comment: "")
                : NSLocalizedString("Add to Reynard", comment: "")
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = isInstalling ? .secondaryLabel : .systemBlue
            cell.selectionStyle = isInstalling ? .none : .default
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        guard rows.indices.contains(indexPath.row), rows[indexPath.row] == .action else {
            return
        }
        
        if let installedAddon {
            let destination = AddonDetailsPreferencesViewController(
                addonID: installedAddon.id,
                addonName: installedAddon.metaData.name ?? listing.name ?? listing.slug
            )
            navigationController?.pushViewController(destination, animated: true)
            return
        }
        
        guard !isInstalling, let installURL = listing.installURL else {
            return
        }
        install(from: installURL)
    }
    
    private func install(from urlString: String) {
        isInstalling = true
        tableView.reloadData()
        
        Task { [weak self] in
            guard let self else {
                return
            }
            
            do {
                let addon = try await AddonRuntime.shared.install(url: urlString, installMethod: .manager)
                await MainActor.run {
                    self.isInstalling = false
                    let destination = AddonDetailsPreferencesViewController(
                        addonID: addon.id,
                        addonName: addon.metaData.name ?? self.listing.name ?? self.listing.slug
                    )
                    self.navigationController?.pushViewController(destination, animated: true)
                }
            } catch {
                await MainActor.run {
                    self.isInstalling = false
                    self.tableView.reloadData()
                    AlertPresenter.show(
                        title: NSLocalizedString("Couldn't Install", comment: ""),
                        message: NSLocalizedString("This extension couldn't be installed. Check your connection - or that you approved its permissions - and try again.", comment: ""),
                        buttons: [AlertPresenter.Button(title: NSLocalizedString("OK", comment: ""))]
                    )
                }
            }
        }
    }
    
    private func makeHeaderView() -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 140))
        
        let iconView = UIImageView(image: UIImage(systemName: "puzzlepiece.extension"))
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .secondaryLabel
        iconView.layer.cornerRadius = 14
        iconView.clipsToBounds = true
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        let nameLabel = UILabel()
        nameLabel.text = listing.name ?? listing.slug
        nameLabel.font = .boldSystemFont(ofSize: 20)
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 2
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let detailLabel = UILabel()
        var detailParts: [String] = []
        if let authors = listing.authorsDisplayText {
            detailParts.append(authors)
        }
        if let ratings = listing.ratings, ratings.count > 0 {
            detailParts.append(String(format: "★ %.1f (%d)", ratings.average, ratings.count))
        }
        detailLabel.text = detailParts.joined(separator: " · ")
        detailLabel.font = .preferredFont(forTextStyle: .footnote)
        detailLabel.textColor = .secondaryLabel
        detailLabel.textAlignment = .center
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(iconView)
        container.addSubview(nameLabel)
        container.addSubview(detailLabel)
        
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            iconView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 56),
            iconView.heightAnchor.constraint(equalToConstant: 56),
            
            nameLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            nameLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
            
            detailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            detailLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            detailLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),
            detailLabel.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -12),
        ])
        
        headerIconView = iconView
        return container
    }
    
    private func loadIcon() {
        guard let iconURLString = listing.iconURL, let iconURL = URL(string: iconURLString) else {
            return
        }
        
        Task { [weak self] in
            guard let image = await ImagePreviewLoader.image(from: iconURL) else {
                return
            }
            await MainActor.run {
                self?.headerIconView?.image = image
            }
        }
    }
}
