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
    @IBOutlet weak var checkedColorButton: ColorPickButton!
    @IBOutlet weak var colorPickerButton: ColorPickButton!
    @IBOutlet weak var scrollView: UIScrollView!
    
    let datePicker = UIDatePicker()
    var note: Note!
    
    override func viewDidLoad() {
        titleField.text = note.title
        contentView.text = note.content
        showDatePicker()
        donedatePicker()
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @IBAction func dateSwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            dateField.isHidden = false
        } else {
            dateField.isHidden = true
        }
    }
    
    let colorPickerSegueIdentifier = "OpenColorPicker"
    
    @IBAction func changeColor(_ sender: ColorPickButton) {
        guard sender != checkedColorButton else { return }
        guard sender != colorPickerButton || colorPickerButton.backgroundColor != nil else {
            performSegue(withIdentifier: colorPickerSegueIdentifier, sender: self)
            return
        }
        checkedColorButton.isChecked = false
        sender.isChecked = true
        checkedColorButton = sender
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vc = segue.destination as? ColorPickerViewController else { return }
        vc.color = checkedColorButton.backgroundColor
    }
    
    @IBAction func unwind(segue:UIStoryboardSegue) {
        guard let vc = segue.source as? ColorPickerViewController else { return }
        checkedColorButton.isChecked = false
        checkedColorButton = colorPickerButton
        colorPickerButton.isChecked = true
        colorPickerButton.backgroundColor = vc.getBrightnessColor()
    }
    
    @IBAction func didLongPressOnColorPickerButton(_ sender: UILongPressGestureRecognizer) {
        guard colorPickerButton.backgroundColor != nil else { return }
        performSegue(withIdentifier: colorPickerSegueIdentifier, sender: self)
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
        datePicker.setDate(now, animated: true)
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
