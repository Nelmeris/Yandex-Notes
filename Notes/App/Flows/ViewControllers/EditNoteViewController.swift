//
//  EditNoteViewController.swift
//  Notes
//
//  Created by Артем Куфаев on 09/07/2019.
//  Copyright © 2019 Артем Куфаев. All rights reserved.
//

import UIKit

class EditNoteViewController: UIViewController {
    
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var contentView: UITextView!
    @IBOutlet weak var dateField: UITextField!
    var staticDateFieldHeight: CGFloat!
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
    
    let storyboardId = "Main"
    let colorPickerId = "ColorPicker"
    
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
    weak var parentVC: UIViewController!
    
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
    
    override func viewDidLoad() {
        configureViews()
        showDatePicker()
        donedatePicker()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        guard isMovingFromParent else { return }
        
        guard let noteTableVC = parentVC as? NoteTableViewController else { return }
        
        guard let title = titleField.text, title != "" else { return }
        guard let content = contentView.text, content != "" else { return }
        let color = selectedColor
        let date = dateSwitch.isOn ? datePicker.date : nil
        
        if note == nil {
            let newNote = Note(title: title, content: content, color: color, importance: .usual, destructionDate: date)
            
            noteTableVC.tableView.beginUpdates()
            noteTableVC.notebook.add(newNote)
            let newIndex = noteTableVC.notes.firstIndex { $0.uid == newNote.uid }!
            noteTableVC.tableView.insertRows(at: [IndexPath(row: newIndex, section: 0)], with: .automatic)
            noteTableVC.tableView.endUpdates()
        } else {
            let newNote = Note(uid: note.uid, title: title, content: content, color: color, importance: note?.importance ?? .usual, destructionDate: date)
            
            guard !(note == newNote) else { return }
            
            let index = noteTableVC.notes.firstIndex { $0.uid == note.uid }!
            
            noteTableVC.tableView.beginUpdates()
            noteTableVC.notebook.update(newNote)
            let newIndex = noteTableVC.notes.firstIndex { $0.uid == newNote.uid }!
            if index == newIndex {
                noteTableVC.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            } else {
                noteTableVC.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                noteTableVC.tableView.insertRows(at: [IndexPath(row: newIndex, section: 0)], with: .automatic)
            }
            noteTableVC.tableView.endUpdates()
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
        //Formate Date
        datePicker.datePickerMode = .dateAndTime
        let now = Date()
        datePicker.minimumDate = now
        
        //ToolBar
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(donedatePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelDatePicker))
        toolbar.setItems([doneButton,spaceButton,cancelButton], animated: false)
        dateField.inputAccessoryView = toolbar
        dateField.inputView = datePicker
    }
    
    @objc func donedatePicker() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        dateField.text = formatter.string(from: datePicker.date)
        self.view.endEditing(true)
    }
    
    @objc func cancelDatePicker() {
        self.view.endEditing(true)
    }
    
}
