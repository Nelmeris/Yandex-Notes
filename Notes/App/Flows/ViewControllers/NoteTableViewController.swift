//
//  NoteTableViewController.swift
//  Notes
//
//  Created by Артем Куфаев on 10/07/2019.
//  Copyright © 2019 Артем Куфаев. All rights reserved.
//

import UIKit

class NoteTableViewController: UITableViewController {
    
    var notebook: FileNotebook!
    let cellReuseIdentifier = "NoteCell"
    let segueToEditNoteIdentifier = "NoteTableToEditNote"
    
    var notes: [Note] {
        let notes = self.notebook.notes.sorted { $0.createDate > $1.createDate }
        return notes
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        notebook = FileNotebook()
        notebook.loadFromFile()
        notebook.setAutosave(true)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(startEditing(sender:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewNote(sender:)))
        
        title = "Заметки"
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
    
    var selectedNote: Note?

}

// MARK: - UITableViewDelegate
extension NoteTableViewController {
    
    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        selectedNote = notes[indexPath.row]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destVC = segue.destination as? EditNoteViewController else { return }
        destVC.note = selectedNote
        destVC.parentVC = self
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
        return notes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: cellReuseIdentifier,
            for: indexPath
            ) as? NoteTableViewCell ??
            NoteTableViewCell(style: .default, reuseIdentifier: cellReuseIdentifier)
        
        let note = notes[indexPath.row]
        
        cell.titleLabel.text = note.title
        cell.contentLabel.text = note.content
        cell.colorView.backgroundColor = note.color
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let note = notes[indexPath.row]
            notebook.remove(with: note.uid)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
}
