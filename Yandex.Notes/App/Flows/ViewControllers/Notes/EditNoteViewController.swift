//
//  EditNoteViewController.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 09/07/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import UIKit
import CoreData

protocol EditNoteViewProtocol {
    func setColor(_ color: UIColor)
    func setDestructionDate(_ date: Date)
    func goToColorPicker()
    func loadNotesOnDestination(notes: [Note])
}

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
    
    var backgroundContext: NSManagedObjectContext!
    
    var presenter: EditNotePresenterProtocol!
    lazy var parentVC: NoteTableViewController? = {
        guard let navigControl = navigationController else { return nil }
        guard let lastVC = navigControl.viewControllers.last(where: { (controller) -> Bool in
            return controller is NoteTableViewController
        }) else { return nil }
        return (lastVC as! NoteTableViewController)
    }()
    
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
    var note: Note?
    
    override func viewDidLoad() {
        configureViews()
        configureDatePicker()
        doneDatePicker()
        configureColorButtons()
        
        presenter = EditNotePresenter(view: self, backgroundContext: backgroundContext)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        guard isMovingFromParent,
            let noteTableVC = parentVC else { return }
        noteProcessing(noteTableVC: noteTableVC)
    }
    
    func configureViews() {
        let placeholder = "Enter note content..."
        staticDateFieldHeight = dateFieldHeight.constant
        guard let note = note else {
            titleField.text = ""
            contentView.text = ""
            contentView.placeholder = placeholder
            checkedColorButton = colorWhiteButton
            dateSwitch.isOn = false
            return
        }
        
        titleField.text = note.title
        contentView.text = note.content
        contentView.placeholder = placeholder
        setColor(note.color)
        if let date = note.destructionDate {
            setDestructionDate(date)
        }
    }
    
    func configureColorButtons() {
        colorWhiteButton.backgroundColor = .white
        colorGreenButton.backgroundColor = .green
        colorRedButton.backgroundColor = .red
    }
    
    @IBAction func dateSwitchChanged(_ sender: UISwitch) {
        dateField.isHidden = !sender.isOn
        if sender.isOn {
            dateFieldHeight.constant = staticDateFieldHeight
        } else {
            dateFieldHeight.constant = 0
        }
    }
    
}

extension EditNoteViewController: EditNoteViewProtocol {
    
    func loadNotesOnDestination(notes: [Note]) {
        guard let noteTableVC = parentVC else { return }
        noteTableVC.setNotes(notes)
    }
    
    func setColor(_ color: UIColor) {
        let whiteHex = UIColor.white.toHexString()
        let redHex = UIColor.red.toHexString()
        let greenHex = UIColor.green.toHexString()
        switch color.toHexString() {
        case whiteHex:
            checkedColorButton = colorWhiteButton
        case redHex:
            checkedColorButton = colorRedButton
        case greenHex:
            checkedColorButton = colorGreenButton
        default:
            colorPickerButton.backgroundColor = color
            checkedColorButton = colorPickerButton
        }
    }
    
    func setDestructionDate(_ date: Date) {
        dateSwitch.isOn = true
        datePicker.date = date
        dateSwitchChanged(dateSwitch)
    }
    
    func goToColorPicker() {
        performSegue(withIdentifier: "toColorPicker", sender: self)
    }
    
}

// MARK: - Note maker
extension EditNoteViewController {
    
    func noteProcessing(noteTableVC: NoteTableViewController) {
        guard let title = titleField.text, title != "",
            let content = contentView.text, content != "" else {
                noteTableVC.showAlert(with: "Заметка не была создана", message: "Отсутствует содержимое")
                return
        }
        let color = selectedColor
        let date = dateSwitch.isOn ? datePicker.date : nil
        
        let noteData = NoteData(title: title, content: content, color: color, importance: .usual, destructionDate: date)
        if let note = self.note {
            presenter.editNote(note, withData: noteData) { notes in
                guard let notes = notes else { return }
                self.loadNotesOnDestination(notes: notes)
            }
        } else {
            presenter.createNote(withData: noteData) { notes in
                guard let notes = notes else { return }
                self.loadNotesOnDestination(notes: notes)
            }
        }
    }
    
}

// MARK: - Transitions
extension EditNoteViewController {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let colorPicker = segue.destination as? ColorPickerViewController else { return }
        colorPicker.color = checkedColorButton.backgroundColor
    }
    
}

// MARK: - Change color
extension EditNoteViewController {
    
    @IBAction func changeColor(_ sender: ColorPickButton) {
        guard sender != checkedColorButton else { return }
        guard sender != colorPickerButton || colorPickerButton.backgroundColor != nil else {
            presenter.changeColor()
            return
        }
        checkedColorButton = sender
    }
    
    @IBAction func didLongPressOnColorPickerButton(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            guard colorPickerButton.backgroundColor != nil else { return }
            presenter.changeColor()
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
    
    func configureDatePicker() {
        datePicker.datePickerMode = .dateAndTime
        datePicker.minimumDate = Date()
        
        configureDateField()
    }
    
    func configureDateField() {
        dateField.inputView = datePicker
        dateField.inputAccessoryView = createToolbarForDateField()
    }
    
    func createToolbarForDateField() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneDatePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelDatePicker))
        toolbar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        return toolbar
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
