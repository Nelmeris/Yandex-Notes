//
//  NoteTableViewController.swift
//  Notes
//
//  Created by Artem Kufaev on 10/07/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import UIKit

class NoteTableViewController: UITableViewController {
    
    private let cellReuseIdentifier = "NoteCell"
    private let segueToEditNoteIdentifier = "NoteTableToEditNote"
    
    var selectedNote: Note?
    
    var sortedNotes: [Note] {
        return FileNotebook.shared.notes.sorted { $0.createDate > $1.createDate }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(startEditing(sender:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewNote(sender:)))
        
        title = "Заметки"
    }
    
    func loadNotes() {
        let loadNotesOperation = LoadNotesOperation(notebook: FileNotebook.shared, backendQueue: backendQueue, dbQueue: dbQueue)
        loadNotesOperation.completionBlock = {
            print("Main load operation completed")
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        commonQueue.addOperation(loadNotesOperation)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadNotes()
    }
    
    @objc func startEditing(sender: UIBarButtonItem) {
        if tableView.isEditing {
            sender.title = "Edit"
            sender.style = .plain
        } else {
            sender.title = "Done"
            sender.style = .done
        }
        tableView.setEditing(!tableView.isEditing, animated: true)
    }
    
    @objc func addNewNote(sender: UIBarButtonItem) {
        selectedNote = nil
        performSegue(withIdentifier: segueToEditNoteIdentifier, sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destVC = segue.destination as? EditNoteViewController else { return }
        destVC.note = selectedNote
    }

}

extension NoteTableViewController: AuthViewControllerDelegate {
    
    func handleTokenChanged(token: String) {
        UserDefaults.standard.set(token, forKey: "access_token")
        loadNotes()
    }
    
}

// MARK: - UITableViewDelegate
extension NoteTableViewController {
    
    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        selectedNote = sortedNotes[indexPath.row]
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
}

// MARK: - UITableViewDataSource
extension NoteTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedNotes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: cellReuseIdentifier,
            for: indexPath
            ) as? NoteTableViewCell ??
            NoteTableViewCell(style: .default, reuseIdentifier: cellReuseIdentifier)
        
        let note = sortedNotes[indexPath.row]
        
        cell.titleLabel.text = note.title
        cell.contentLabel.text = note.content
        cell.colorView.backgroundColor = note.color
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let note = sortedNotes[indexPath.row]
        tableView.beginUpdates()
        let removeNoteOperation = RemoveNoteOperation(note: note, notebook: FileNotebook.shared, backendQueue: backendQueue, dbQueue: dbQueue)
        removeNoteOperation.completionBlock = {
            DispatchQueue.main.async {
                tableView.deleteRows(at: [indexPath], with: .fade)
                tableView.endUpdates()
            }
        }
        commonQueue.addOperation(removeNoteOperation)
    }
    
}
