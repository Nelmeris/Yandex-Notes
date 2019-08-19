//
//  ColorPickerView.swift
//  Notes
//
//  Created by Artem Kufaev on 10/07/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import UIKit

internal protocol HSBColorPickerDelegate : NSObjectProtocol {
    func HSBColorColorPickerTouched(sender: HSBColorPicker,
                                    color: UIColor,
                                    point: CGPoint,
                                    state: UIGestureRecognizer.State?)
}

@IBDesignable
class HSBColorPicker : DesignableView {
    
    weak internal var delegate: HSBColorPickerDelegate?
    let saturationExponentTop: Float = 2.0
    let saturationExponentBottom: Float = 1.3
    
    @IBInspectable var elementSize: CGFloat = 1.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var brightnessFactor: CGFloat = 1.0 {
        didSet {
            let point = getPointForColor(color: selectedColor)
            interactWithPoint(point: point)
            setNeedsDisplay()
        }
    }
    
    private var touchCoordinates: CGPoint = .zero {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var selectedColor: UIColor! = .white {
        didSet {
            setNeedsDisplay()
        }
    }
    
    private func initialize() {
        self.clipsToBounds = true
        let touchGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.touchedColor(gestureRecognizer:)))
        touchGesture.minimumPressDuration = 0
        touchGesture.allowableMovement = CGFloat.greatestFiniteMagnitude
        self.addGestureRecognizer(touchGesture)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        for y: CGFloat in stride(from: 0.0, to: rect.height, by: elementSize) {
            var saturation = y < rect.height / 2.0 ?
                CGFloat(2 * y) / rect.height :
                2.0 * CGFloat(rect.height - y) / rect.height
            saturation = CGFloat(
                powf(
                    Float(saturation),
                    y < rect.height / 2.0 ? saturationExponentTop : saturationExponentBottom
                )
            )
            
            let brightness =  brightnessFactor * (
                y < rect.height / 2.0 ?
                    CGFloat(1.0) :
                    2.0 * CGFloat(rect.height - y) / rect.height
            )
            
            for x: CGFloat in stride(from: 0.0, to: rect.width, by: elementSize) {
                let hue = x / rect.width
                let color = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
                context!.setFillColor(color.cgColor)
                context!.fill(CGRect(x: x, y: y, width: elementSize, height: elementSize))
            }
        }
        
        if let selectedColor = selectedColor {
            let cursorCenter = getPointForColor(color: selectedColor)
            context?.setStrokeColor(UIColor.black.cgColor)
            context?.addArc(center: cursorCenter, radius: CGFloat(self.elementSize / 2), startAngle: CGFloat(0), endAngle: CGFloat.pi * 2, clockwise: false)
            context?.strokePath()
        }
    }
    
    func getColorAtPoint(point:CGPoint) -> UIColor {
        let roundedPoint = CGPoint(
            x: elementSize * CGFloat(Int(point.x / elementSize)),
            y: elementSize * CGFloat(Int(point.y / elementSize))
        )
        var saturation = roundedPoint.y < bounds.height / 2.0 ?
            CGFloat(2 * roundedPoint.y) / bounds.height :
            2.0 * CGFloat(bounds.height - roundedPoint.y) / bounds.height
        saturation = CGFloat(powf(Float(saturation), roundedPoint.y < bounds.height / 2.0 ?
            saturationExponentTop : saturationExponentBottom))
        let brightness = (roundedPoint.y < bounds.height / 2.0 ? CGFloat(1.0) : 2.0 * CGFloat(bounds.height - roundedPoint.y) / bounds.height) * brightnessFactor
        let hue = roundedPoint.x / bounds.width
        let color = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
        return color
    }
    
    func getPointForColor(color:UIColor) -> CGPoint {
        var hue: CGFloat = 0.0
        var saturation: CGFloat = 0.0
        var brightness: CGFloat = 0.0
        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil);
        
        var yPos: CGFloat = 0
        let halfHeight = (bounds.height / 2)
        if (brightness >= 0.99) {
            let percentageY = powf(Float(saturation), 1.0 / saturationExponentTop)
            yPos = CGFloat(percentageY) * halfHeight
        } else {
            yPos = halfHeight + halfHeight * (1.0 - brightness)
        }
        let xPos = hue * bounds.width
        return CGPoint(x: xPos, y: yPos)
    }
    
    func selectColor(_ color: UIColor) {
        selectedColor = color
    }
    
    @objc func touchedColor(gestureRecognizer: UILongPressGestureRecognizer) {
        let point = gestureRecognizer.location(in: self)
        let color = getColorAtPoint(point: point)
        self.selectedColor = color
        interactWithPoint(point: point, state: gestureRecognizer.state)
    }
    
    private func interactWithPoint(point: CGPoint, state: UIGestureRecognizer.State? = nil) {
        let color = getColorAtPoint(point: point)
        self.touchCoordinates = point
        self.delegate?.HSBColorColorPickerTouched(sender: self, color: color, point: point, state: state)
    }
    
}
