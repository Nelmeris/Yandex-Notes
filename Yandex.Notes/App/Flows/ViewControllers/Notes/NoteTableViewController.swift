//
//  NoteTableViewController.swift
//  Notes
//
//  Created by Artem Kufaev on 10/07/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import UIKit
import CoreData

class NoteTableViewController: UITableViewController {
    
    private let cellReuseIdentifier = "NoteCell"
    private let segueToEditNoteIdentifier = "NoteTableToEditNote"
    
    var context: NSManagedObjectContext?
    var backgroundContext: NSManagedObjectContext?
    
    var selectedNote: Note?
    
    var notes: [Note] = []
    var timer: Timer!
    
    func getSortCompare() -> (Note, Note) -> Bool {
        return { lft, rht in
            return lft.createDate > rht.createDate
        }
    }
    
    var sortedNotes: [Note] {
        return notes.sorted(by: getSortCompare())
    }
    
    private func saveNotes(_ notes: [Note]) {
        DispatchQueue.main.async {
            if self.notes != notes {
                self.notes = notes
                self.tableView.reloadData()
            }
            self.tableView.refreshControl?.endRefreshing()
        }
    }
    
    func loadNotesFromDB() {
        guard let backgroundContext = backgroundContext else { return }
        DispatchQueue.main.async {
            self.tableView.refreshControl?.beginRefreshing()
        }
        let loadFromDBOperation = LoadNotesDBOperation(context: backgroundContext)
        loadFromDBOperation.completionBlock = {
            switch loadFromDBOperation.result! {
            case .success(let notes):
                self.saveNotes(notes)
            case .failture(let error):
                print(error.localizedDescription)
            }
        }
        dbQueue.addOperation(loadFromDBOperation)
    }
    
    let noConnectionTimerKey = "no_connection_timer"
    func noConnectionHandler() {
        let userDefaults = UserDefaults.standard
        let time = userDefaults.double(forKey: noConnectionTimerKey)
        userDefaults.value(forKey: noConnectionTimerKey)
        if time == 0 || Date().timeIntervalSince1970 - time > 300 {
            let alert = UIAlertController(title: "Внимание!", message: "Отсутствует подключение к сети", preferredStyle: .alert)
            let alertAction = UIAlertAction(title: "ОК", style: .cancel)
            alert.addAction(alertAction)
            self.present(alert, animated: true)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: noConnectionTimerKey)
        }
    }
    
    func parseUIOperationResult(from result: UIOperationResult) {
        switch result {
        case .success(let notes):
            self.saveNotes(notes)
        case .backendFailture(let notes, let error):
            self.saveNotes(notes)
            switch error {
            case .failed(let netError):
                switch netError {
                case .failedRequest(let requestError):
                    switch requestError {
                    case .noConnection:
                        noConnectionHandler()
                    default:
                        print(requestError.localizedDescription)
                    }
                case .failedResponse(let responseError):
                    print(responseError.localizedDescription)
                }
            default:
                print(error.localizedDescription)
            }
        case .dbFailture(let error):
            fatalError(error.localizedDescription)
        }
    }
    
    @objc func syncNotes() {
        guard let backgroundContext = backgroundContext else { return }
        DispatchQueue.main.async {
            self.tableView.refreshControl?.beginRefreshing()
        }
        let syncNotesOperation = SyncNotesOperation(context: backgroundContext, mainQueue: commonQueue, backendQueue: backendQueue, dbQueue: dbQueue)
        syncNotesOperation.loadFromDB.completionBlock = {
            switch syncNotesOperation.loadFromDB.result! {
            case .success(let notes):
                self.saveNotes(notes)
            case .failture(let error):
                fatalError(error.localizedDescription)
            }
        }
        syncNotesOperation.completionBlock = {
            self.parseUIOperationResult(from: syncNotesOperation.result!)
        }
        commonQueue.addOperation(syncNotesOperation)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(startEditing(sender:)))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(syncNotes))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNewNote(sender:)))
        
        title = "Заметки"
        tableView.separatorStyle = .none
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(syncNotes), for: .allEvents)
        
        loadNotesFromDB()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        syncNotes()
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
        destVC.context = self.context
        destVC.backgroundContext = self.backgroundContext
        destVC.note = selectedNote
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
        guard let backgroundContext = backgroundContext else { return }
        let removeNoteOperation = RemoveNoteOperation(note: note, context: backgroundContext, mainQueue: commonQueue, backendQueue: backendQueue, dbQueue: dbQueue)
        removeNoteOperation.removeFromDB.completionBlock = {
            self.loadNotesFromDB()
        }
        removeNoteOperation.completionBlock = {
            self.parseUIOperationResult(from: removeNoteOperation.result!)
        }
        commonQueue.addOperation(removeNoteOperation)
    }
    
}
