//
//  EditNoteViewController.swift
//  Notes
//
//  Created by Artem Kufaev on 09/07/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import UIKit

class EditNoteViewController: UIViewController {
    
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var contentView: UITextView!
    @IBOutlet weak var dateField: UITextField!
    @IBOutlet weak var dateFieldHeight: NSLayoutConstraint!
    @IBOutlet weak var checkedColorButton: ColorPickButton! {
        didSet {
            guard self.checkedColorButton != oldValue,
                let value = oldValue else { return }
            value.isChecked = false
        }
        willSet {
            newValue.isChecked = true
        }
    }
    @IBOutlet weak var colorWhiteButton: ColorPickButton!
    @IBOutlet weak var colorRedButton: ColorPickButton!
    @IBOutlet weak var colorGreenButton: ColorPickButton!
    @IBOutlet weak var colorPickerButton: ColorPickButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var dateSwitch: UISwitch!
    
    private let storyboardId = "Main"
    private let colorPickerId = "ColorPicker"
    
    var staticDateFieldHeight: CGFloat!
    
    var selectedColor: UIColor {
        return checkedColorButton.backgroundColor!
    }
    
    var noteTitle: String {
        return self.titleField.text!
    }
    
    var content: String {
        return self.contentView.text!
    }
    
    var date: Date {
        return self.datePicker.date
    }
    
    let datePicker = UIDatePicker()
    var note: Note!
    
    override func viewDidLoad() {
        configureViews()
        showDatePicker()
        doneDatePicker()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        guard isMovingFromParent else { return }
        guard let navigControl = navigationController else { return }
        guard let noteTableVC = navigControl.viewControllers.last as? NoteTableViewController else { return }
        
        guard let title = titleField.text, title != "" else { return }
        guard let content = contentView.text, content != "" else { return }
        let color = selectedColor
        let date = dateSwitch.isOn ? datePicker.date : nil
        
        if note == nil {
            createNote(destination: noteTableVC, title: title, content: content, color: color, date: date)
        } else {
            editNote(destination: noteTableVC, title: title, content: content, color: color, date: date)
        }
    }
    
    func configureViews() {
        staticDateFieldHeight = dateFieldHeight.constant
        
        guard note != nil else {
            titleField.text = ""
            contentView.text = ""
            checkedColorButton = colorWhiteButton
            dateSwitch.isOn = false
            return
        }
        
        titleField.text = note.title
        contentView.text = note.content
        switch note.color {
        case let color where color == colorWhiteButton.backgroundColor:
            checkedColorButton = colorWhiteButton
        case let color where color == colorRedButton.backgroundColor:
            checkedColorButton = colorRedButton
        case let color where color == colorGreenButton.backgroundColor:
            checkedColorButton = colorGreenButton
        default:
            colorPickerButton.backgroundColor = note.color
            checkedColorButton = colorPickerButton
        }
        if let date = note.destructionDate {
            dateSwitch.isOn = true
            datePicker.date = date
            dateSwitchChanged(dateSwitch)
        }
    }
    
    @IBAction func dateSwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            dateField.isHidden = false
            dateFieldHeight.constant = staticDateFieldHeight
        } else {
            dateField.isHidden = true
            dateFieldHeight.constant = 0
        }
    }
    
}

// MARK: - Note maker
extension EditNoteViewController {
    
    private func updateTable(_ dest: NoteTableViewController,
                             _ note: Note,
                             oldNote: Note? = nil,
                             oldIndex: Int? = nil) {
        DispatchQueue.main.async {
            dest.tableView.beginUpdates()
            if let oldNote = oldNote,
                let oldIndex = oldIndex {
                self.updateTableAfterEditNote(dest, note, oldNote: oldNote, oldIndex: oldIndex)
            } else {
                self.updateTableAfterCreateNote(dest, note)
            }
            dest.tableView.endUpdates()
        }
    }
    
    private func updateTableAfterCreateNote(_ dest: NoteTableViewController,
                                            _ newNote: Note) {
        let newIndex = dest.sortedNotes.firstIndex { $0.uid == newNote.uid } ?? 0
        dest.tableView.insertRows(at: [IndexPath(row: newIndex, section: 0)], with: .automatic)
    }
    
    private func updateTableAfterEditNote(_ dest: NoteTableViewController,
                                          _ newNote: Note,
                                          oldNote: Note,
                                          oldIndex: Int) {
        let newIndex = dest.sortedNotes.firstIndex { $0.uid == newNote.uid } ?? 0
        if oldIndex == newIndex {
            dest.tableView.reloadRows(at: [IndexPath(row: oldIndex, section: 0)], with: .automatic)
        } else {
            dest.tableView.deleteRows(at: [IndexPath(row: oldIndex, section: 0)], with: .automatic)
            dest.tableView.insertRows(at: [IndexPath(row: newIndex, section: 0)], with: .automatic)
        }
    }
    
    private func createNote(destination dest: NoteTableViewController,
                    title: String,
                    content: String,
                    color: UIColor,
                    date: Date?) {
        let newNote = Note(
            title: title,
            content: content,
            color: color,
            importance: .usual,
            destructionDate: date
        )
        
        let saveNoteOperation = SaveNoteOperation(note: newNote, notebook: FileNotebook.shared, backendQueue: backendQueue, dbQueue: dbQueue)
        saveNoteOperation.saveToDb.completionBlock = {
            self.updateTable(dest, newNote)
        }
        commonQueue.addOperation(saveNoteOperation)
    }
    
    private func editNote(destination dest: NoteTableViewController,
                  title: String,
                  content: String,
                  color: UIColor,
                  date: Date?) {
        let newNote = Note(
            uid: note.uid,
            title: title,
            content: content,
            color: color,
            importance: note.importance,
            destructionDate: date
        )
        
        guard !(note == newNote) else { return }
        
        let removeNoteOperation = RemoveNoteOperation(note: note, notebook: FileNotebook.shared, backendQueue: backendQueue, dbQueue: dbQueue)
        
        let saveNoteOperation = SaveNoteOperation(note: newNote, notebook: FileNotebook.shared, backendQueue: backendQueue, dbQueue: dbQueue)
        saveNoteOperation.addDependency(removeNoteOperation)
        
        let index = dest.sortedNotes.firstIndex { $0.uid == note.uid }!
        saveNoteOperation.saveToDb.completionBlock = {
            self.updateTable(dest, newNote, oldNote: self.note, oldIndex: index)
        }
        
        commonQueue.addOperation(removeNoteOperation)
        commonQueue.addOperation(saveNoteOperation)
    }
    
}

// MARK: - Transitions
extension EditNoteViewController {
    
    func goToColorPicker() {
        let storyboard = UIStoryboard(name: storyboardId, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: colorPickerId) as! ColorPickerViewController
        vc.color = checkedColorButton.backgroundColor
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func changeColor(_ sender: ColorPickButton) {
        guard sender != checkedColorButton else { return }
        guard sender != colorPickerButton || colorPickerButton.backgroundColor != nil else {
            goToColorPicker()
            return
        }
        checkedColorButton = sender
    }
    
    @IBAction func didLongPressOnColorPickerButton(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            guard colorPickerButton.backgroundColor != nil else { return }
            goToColorPicker()
        }
    }
    
}

// MARK: - Keyboard
extension EditNoteViewController {
    
    @objc func keyboardWillShow(notification:NSNotification) {
        var userInfo = notification.userInfo!
        var keyboardFrame: CGRect = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        
        var contentInset: UIEdgeInsets = self.scrollView.contentInset
        contentInset.bottom = keyboardFrame.size.height
        scrollView.contentInset = contentInset
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        let contentInset: UIEdgeInsets = UIEdgeInsets.zero
        scrollView.contentInset = contentInset
    }
    
}

// MARK: - DatePicker
extension EditNoteViewController {
    
    func showDatePicker() {
        datePicker.datePickerMode = .dateAndTime
        datePicker.minimumDate = Date()
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneDatePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelDatePicker))
        toolbar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        dateField.inputAccessoryView = toolbar
        dateField.inputView = datePicker
    }
    
    @objc func doneDatePicker() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        dateField.text = formatter.string(from: datePicker.date)
        self.view.endEditing(true)
    }
    
    @objc func cancelDatePicker() {
        self.view.endEditing(true)
    }
    
}
