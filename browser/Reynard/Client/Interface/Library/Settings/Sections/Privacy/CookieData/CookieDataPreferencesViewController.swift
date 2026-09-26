//
//  CookieDataPreferencesViewController.swift
//  Reynard
//
//  Created by Minh Ton on 19/9/26.
//

import GeckoView
import UIKit

final class CookieDataPreferencesViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let searchController = UISearchController(searchResultsController: nil)
    
    private var allHosts: [String] = []
    private var isLoading = true
    private var loadErrorMessage: String?
    
    private var filteredHosts: [String] {
        let query = searchController.searchBar.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !query.isEmpty else {
            return allHosts
        }
        return allHosts.filter { $0.localizedCaseInsensitiveContains(query) }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Cookies & Site Data", comment: "")
        view.backgroundColor = .systemBackground
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.largeTitleDisplayMode = .never
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = NSLocalizedString("Search Sites", comment: "")
        definesPresentationContext = true
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("Clear All", comment: ""),
            style: .plain,
            target: self,
            action: #selector(clearAllTapped)
        )
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        reload()
    }
    
    private func reload() {
        isLoading = true
        loadErrorMessage = nil
        tableView.reloadData()
        
        Task { [weak self] in
            do {
                let hosts = try await GeckoStorageController.listStorageHosts()
                await MainActor.run {
                    guard let self else {
                        return
                    }
                    self.allHosts = hosts.sorted()
                    self.isLoading = false
                    self.navigationItem.rightBarButtonItem?.isEnabled = !hosts.isEmpty
                    self.tableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    guard let self else {
                        return
                    }
                    self.isLoading = false
                    self.loadErrorMessage = NSLocalizedString("Couldn't load site data.", comment: "")
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    private func deleteHost(_ host: String) {
        Task {
            try? await GeckoStorageController.clearData(
                forHost: host,
                flags: GeckoStorageClearFlags.cookies | GeckoStorageClearFlags.domStorages
            )
        }
        allHosts.removeAll { $0 == host }
        tableView.reloadData()
        navigationItem.rightBarButtonItem?.isEnabled = !allHosts.isEmpty
    }
    
    @objc private func clearAllTapped() {
        let alert = UIAlertController(
            title: NSLocalizedString("Clear All Site Data?", comment: ""),
            message: NSLocalizedString("This removes cookies and stored data for every site listed here. You'll be signed out of most sites.", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Clear All", comment: ""), style: .destructive) { [weak self] _ in
            self?.clearAll()
        })
        present(alert, animated: true)
    }
    
    private func clearAll() {
        Task {
            try? await GeckoStorageController.clearData(
                flags: GeckoStorageClearFlags.cookies | GeckoStorageClearFlags.domStorages
            )
        }
        allHosts = []
        tableView.reloadData()
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
}

extension CookieDataPreferencesViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        tableView.reloadData()
    }
}

extension CookieDataPreferencesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isLoading || loadErrorMessage != nil || filteredHosts.isEmpty {
            return 1
        }
        return filteredHosts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.selectionStyle = .none
        
        if isLoading {
            cell.textLabel?.text = NSLocalizedString("Loading…", comment: "")
            cell.textLabel?.textColor = .secondaryLabel
            return cell
        }
        
        if let loadErrorMessage {
            cell.textLabel?.text = loadErrorMessage
            cell.textLabel?.textColor = .secondaryLabel
            return cell
        }
        
        guard filteredHosts.indices.contains(indexPath.row) else {
            cell.textLabel?.text = allHosts.isEmpty
                ? NSLocalizedString("No sites have stored data.", comment: "")
                : NSLocalizedString("No matching sites.", comment: "")
            cell.textLabel?.textColor = .secondaryLabel
            return cell
        }
        
        cell.textLabel?.text = filteredHosts[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return !isLoading && loadErrorMessage == nil && filteredHosts.indices.contains(indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard filteredHosts.indices.contains(indexPath.row) else {
            return nil
        }
        let host = filteredHosts[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")) { [weak self] _, _, completion in
            self?.deleteHost(host)
            completion(true)
        }
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
    }
}
