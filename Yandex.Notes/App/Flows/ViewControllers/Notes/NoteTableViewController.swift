//
//  NoteTableViewController.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 10/07/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import UIKit
import CoreData

protocol NoteTableViewProtocol {
    func setNotes(_ notes: [Note])
    func beginRefreshing()
    func endRefreshing()
    func alert(with title: String, message: String)
}

class NoteTableViewController: UITableViewController {
    
    private let cellReuseIdentifier = "NoteCell"
    private let segueToEditNoteIdentifier = "NoteTableToEditNote"
    
    var context: NSManagedObjectContext!
    var backgroundContext: NSManagedObjectContext!
    var presenter: NoteTableViewPresenterProtocol!
    
    var notes: [Note] = []
    var selectedNote: Note?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(startEditing(sender:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewNote(sender:)))
        configure()
        presenter.loadNotesFromDB()
    }
    
    func configure() {
        title = "Заметки"
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(prepareSyncNotes), for: .allEvents)
        
        presenter = NoteTableViewPresenter(view: self, context: context, backgroundContext: backgroundContext)
    }
    
    @objc func prepareSyncNotes() {
        presenter.resetSyncTimer()
        presenter.syncNotes()
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
        destVC.backgroundContext = self.backgroundContext
        destVC.note = selectedNote
    }

}

// MARK: - UITableViewDelegate
extension NoteTableViewController {
    
    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        selectedNote = notes[indexPath.row]
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
        
        if let date = note.destructionDate {
            cell.destructionDateLabel.text = shortDate(date)
            cell.destructionDateTitle.text = "Destruction at:"
        } else {
            cell.destructionDateLabel.text = ""
            cell.destructionDateTitle.text = ""
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        let note = notes[indexPath.row]
        self.presenter.removeNote(note)
    }
    
}

extension NoteTableViewController: NoteTableViewProtocol {
    
    func beginRefreshing() {
        DispatchQueue.main.async {
            self.tableView.refreshControl?.beginRefreshing()
        }
    }
    
    func setNotes(_ notes: [Note]) {
        if self.notes != notes {
            self.notes = notes
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func endRefreshing() {
        DispatchQueue.main.async {
            guard let refreshControl = self.tableView.refreshControl else { return }
            refreshControl.endRefreshing()
        }
    }
    
    func alert(with title: String, message: String) {
        self.showAlert(with: title, message: message)
    }
    
}
