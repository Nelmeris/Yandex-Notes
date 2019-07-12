//
//  ColorPickerViewController.swift
//  Notes
//
//  Created by Артем Куфаев on 10/07/2019.
//  Copyright © 2019 Артем Куфаев. All rights reserved.
//

import UIKit

class ColorPickerViewController: UIViewController, HSBColorPickerDelegate {

    @IBOutlet weak var colorPreview: DesignableView!
    @IBOutlet weak var colorHEXField: UITextField!
    @IBOutlet weak var brightnessSlider: UISlider!
    @IBOutlet weak var colorPicker: HSBColorPicker!
    
    var color: UIColor!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        colorPicker.delegate = self
        updatePreview()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard let navigControl = navigationController else { return }
        guard let editNoteVC = navigControl.viewControllers.last as? EditNoteViewController else { return }
        editNoteVC.colorPickerButton.backgroundColor = color
        editNoteVC.checkedColorButton = editNoteVC.colorPickerButton
    }
    
    func HSBColorColorPickerTouched(sender: HSBColorPicker, color: UIColor, point: CGPoint, state: UIGestureRecognizer.State) {
        self.color = color
        updatePreview()
    }
    
    func getBrightnessColor() -> UIColor {
        let brightness = brightnessSlider.value * 100 - 50
        return self.color.adjust(by: CGFloat(brightness))!
    }

    @IBAction func brightnessChange(_ sender: Any) {
        updatePreview()
    }
    
    func updatePreview() {
        let color = getBrightnessColor()
        colorPreview.backgroundColor = color
        colorHEXField.text = color.toHexString()
    }
    
    @IBAction func done(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
}
