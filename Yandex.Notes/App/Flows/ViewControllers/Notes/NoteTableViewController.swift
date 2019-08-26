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
        presenter.loadNotes()
//        presenter.startSyncTimer(with: 10)
    }
    
    func configure() {
        title = "Заметки"
        tableView.separatorStyle = .none
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(prepareSyncNotes), for: .valueChanged)
        
        presenter = NoteTableViewPresenter(view: self, context: context, backgroundContext: backgroundContext)
    }
    
    @objc func prepareSyncNotes() {
        UserDefaults.standard.removeObject(forKey: "no_connection_time")
        presenter.loadNotes()
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
        let count = notes.count
        if count == 0 {
            tableView.separatorStyle = .none
        } else {
            tableView.separatorStyle = .singleLine
        }
        return count
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
    
    func beginUpdates() {
        self.tableView.beginUpdates()
    }
    
    private func getIndex(for note: Note, in notes: [Note]) -> Int? {
        return notes.firstIndex(where: { $0.uuid == note.uuid })
    }
    
    private func getNote(for uuid: UUID, in notes: [Note]) -> Note? {
        return notes.first(where: { $0.uuid == uuid })
    }
    
    func setNotes(_ notes: [Note]) {
        if self.notes != notes {
            let oldNotes = self.notes
            
            let removedNotes = Note.getDeletedNotes(in: notes, compare: oldNotes)
            let newNotes = Note.getNewNotes(in: notes, compare: oldNotes)
            let updatedNotes = Note.getUpdatedNotes(in: notes, compare: oldNotes)
            
            var deletedRows: [IndexPath] = removedNotes
                .compactMap { getIndex(for: $0, in: oldNotes) }
                .map { IndexPath(row: $0, section: 0) }
            var insertedRows: [IndexPath] = newNotes
                .compactMap { getIndex(for: $0, in: notes) }
                .map { IndexPath(row: $0, section: 0) }
            let reloadedRows: [IndexPath] = updatedNotes
                .filter { getIndex(for: $0, in: oldNotes) == getIndex(for: $0, in: notes) }
                .compactMap { notes.index(of: $0) }
                .map { IndexPath(row: $0, section: 0) }
            let movedRows: [(at: IndexPath, to: IndexPath)] = updatedNotes
                .filter { (getIndex(for: $0, in: oldNotes) != getIndex(for: $0, in: notes)!) }
                .map { (getIndex(for: $0, in: oldNotes)!, getIndex(for: $0, in: notes)!) }
                .map { (IndexPath(row: $0.0, section: 0), IndexPath(row: $0.1, section: 0)) }
            movedRows.forEach { insertedRows.append($0.to) }
            movedRows.forEach { deletedRows.append($0.at) }
            
            DispatchQueue.main.async {
                self.notes = notes
                self.beginUpdates()
                self.tableView.deleteRows(at: deletedRows, with: .automatic)
                self.tableView.insertRows(at: insertedRows, with: .automatic)
                self.tableView.reloadRows(at: reloadedRows, with: .automatic)
                self.endUpdates()
            }
        }
    }
    
    func endUpdates() {
        self.tableView.endUpdates()
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
