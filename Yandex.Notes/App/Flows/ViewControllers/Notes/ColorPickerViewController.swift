//
//  ColorPickerViewController.swift
//  Yandex.Notes
//
//  Created by Artem Kufaev on 10/07/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import UIKit

class ColorPickerViewController: UIViewController, HSBColorPickerDelegate {

    @IBOutlet weak var colorPreview: DesignableView!
    @IBOutlet weak var colorHEXField: UITextField!
    @IBOutlet weak var brightnessSlider: UISlider!
    @IBOutlet weak var colorPicker: HSBColorPicker!
    
    var color: UIColor? = nil {
        didSet {
            updatePreview()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        colorPicker.delegate = self
        colorPicker.selectColor(color ?? .white)
        updatePreview()
    }
    
    func processingColor(in destination: EditNoteViewProtocol) {
        guard let color = color else { return }
        destination.setColor(color)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard let navigControl = navigationController else { return }
        guard let editNoteVC = navigControl.viewControllers.last as? EditNoteViewController else { return }
        processingColor(in: editNoteVC)
    }
    
    func HSBColorColorPickerTouched(sender: HSBColorPicker, color: UIColor, point: CGPoint, state: UIGestureRecognizer.State?) {
        self.color = color
    }

    @IBAction func brightnessChange(_ sender: Any) {
        colorPicker.brightnessFactor = CGFloat(brightnessSlider.value)
    }
    
    func updatePreview() {
        guard let color = color else { return }
        colorPreview?.backgroundColor = color
        colorHEXField?.text = color.toHexString()
    }
    
    @IBAction func done(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
}
