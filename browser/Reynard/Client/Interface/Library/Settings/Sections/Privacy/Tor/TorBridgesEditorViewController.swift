//
//  TorBridgesEditorViewController.swift
//  Reynard
//
//  Created by Minh Ton on 16/9/26.
//

import UIKit

final class TorBridgesEditorViewController: UIViewController {
    private let textView = UITextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Bridge Lines", comment: "")
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveButtonTapped)
        )
        
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.autocapitalizationType = .none
        textView.autocorrectionType = .no
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        textView.spellCheckingType = .no
        textView.keyboardDismissMode = .interactive
        textView.text = Prefs.TorPreferences.bridgeLines
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
        ])
        
        if textView.text.isEmpty {
            textView.text = "# " + NSLocalizedString("One bridge line per line, e.g.:", comment: "") + "\n# Bridge 192.0.2.55:38114 316E643333645F6D79216558614D3931657A5F5F\n"
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }
    
    @objc private func saveButtonTapped() {
        textView.resignFirstResponder()
        Prefs.TorPreferences.bridgeLines = textView.text
        TorController.shared.reconnect()
        navigationController?.popViewController(animated: true)
    }
}
