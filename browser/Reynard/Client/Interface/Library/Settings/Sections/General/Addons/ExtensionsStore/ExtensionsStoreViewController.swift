//
//  ExtensionsStoreViewController.swift
//  Reynard
//
//  Created by Minh Ton on 19/9/26.
//

import GeckoView
import UIKit

/// Browses and searches real extensions from addons.mozilla.org (via
/// AMOAPIClient) and installs the selected one through the app's existing
/// AddonRuntime - the same native permission-prompt-backed install path
/// used everywhere else add-ons are installed. This screen only lists and
/// links to installs; it doesn't touch install/enable/disable state itself
/// beyond triggering AddonRuntime.install.
final class ExtensionsStoreViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let searchController = UISearchController(searchResultsController: nil)
    
    private var listings: [AMOAddonListing] = []
    private var installedGUIDs: Set<String> = []
    private var currentTask: URLSessionDataTask?
    private var isLoading = false
    private var loadErrorMessage: String?
    private var iconCache: [String: UIImage] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Extensions", comment: "")
        view.backgroundColor = .systemBackground
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.largeTitleDisplayMode = .never
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = NSLocalizedString("Search Extensions", comment: "")
        definesPresentationContext = true
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 72
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        refreshInstalledGUIDs()
        performSearch(query: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshInstalledGUIDs()
        tableView.reloadData()
    }
    
    private func refreshInstalledGUIDs() {
        installedGUIDs = Set(AddonRuntime.shared.installedAddons.map { $0.id })
    }
    
    private func performSearch(query: String?) {
        currentTask?.cancel()
        isLoading = true
        loadErrorMessage = nil
        tableView.reloadData()
        
        currentTask = AMOAPIClient.search(query: query) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else {
                    return
                }
                self.isLoading = false
                switch result {
                case .success(let listings):
                    self.listings = listings
                case .failure:
                    self.listings = []
                    self.loadErrorMessage = NSLocalizedString("Couldn't load extensions. Check your connection and try again.", comment: "")
                }
                self.tableView.reloadData()
            }
        }
    }
}

extension ExtensionsStoreViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        performSearch(query: searchController.searchBar.text)
    }
}

extension ExtensionsStoreViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isLoading || loadErrorMessage != nil || listings.isEmpty {
            return 1
        }
        return listings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.imageView?.image = nil
        cell.accessoryType = .none
        cell.selectionStyle = .default
        
        if isLoading {
            cell.textLabel?.text = NSLocalizedString("Loading…", comment: "")
            cell.selectionStyle = .none
            return cell
        }
        
        if let loadErrorMessage {
            cell.textLabel?.text = loadErrorMessage
            cell.textLabel?.numberOfLines = 0
            cell.selectionStyle = .none
            return cell
        }
        
        guard listings.indices.contains(indexPath.row) else {
            cell.textLabel?.text = NSLocalizedString("No extensions found.", comment: "")
            cell.selectionStyle = .none
            return cell
        }
        
        let listing = listings[indexPath.row]
        cell.textLabel?.text = listing.name ?? listing.slug
        cell.detailTextLabel?.text = listing.summary
        cell.detailTextLabel?.numberOfLines = 2
        cell.accessoryType = installedGUIDs.contains(listing.guid) ? .checkmark : .disclosureIndicator
        cell.imageView?.contentMode = .scaleAspectFit
        cell.imageView?.image = UIImage(systemName: "puzzlepiece.extension")
        loadIcon(for: listing, into: cell, at: indexPath)
        
        return cell
    }
    
    private func loadIcon(for listing: AMOAddonListing, into cell: UITableViewCell, at indexPath: IndexPath) {
        guard let iconURLString = listing.iconURL else {
            return
        }
        
        if let cached = iconCache[iconURLString] {
            cell.imageView?.image = cached
            return
        }
        
        guard let iconURL = URL(string: iconURLString) else {
            return
        }
        
        Task { [weak self, weak tableView] in
            guard let image = await ImagePreviewLoader.image(from: iconURL) else {
                return
            }
            await MainActor.run {
                self?.iconCache[iconURLString] = image
                // Guard against the cell having been reused for a
                // different row by the time this finishes.
                guard let currentCell = tableView?.cellForRow(at: indexPath), currentCell === cell else {
                    return
                }
                currentCell.imageView?.image = image
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard listings.indices.contains(indexPath.row) else {
            return
        }
        let destination = ExtensionsStoreDetailViewController(listing: listings[indexPath.row])
        navigationController?.pushViewController(destination, animated: true)
    }
}
