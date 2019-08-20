//
//  ColorPickButton
//  Yandex.Notes
//
//  Created by Artem Kufaev on 09/07/2019.
//  Copyright © 2019 Artem Kufaev. All rights reserved.
//

import UIKit

@IBDesignable
class ColorPickButton: DesignableButton {
    
    @IBInspectable var checkmarkerColor: UIColor = .black
    @IBInspectable var checkmarkerThickness: CGFloat = 1.0
    @IBInspectable var isChecked: Bool = false {
        willSet {
            setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        guard isChecked else { return }
        let path = UIBezierPath()
        path.move(to: CGPoint(
            x: bounds.maxX / 4.0,
            y: bounds.midY)
        )
        path.addLine(to: CGPoint(
            x: bounds.midX,
            y: bounds.maxY / 4.0 * 3.0)
        )
        path.addLine(to: CGPoint(
            x: bounds.maxX / 4.0 * 3.0,
            y: bounds.maxY / 4.0)
        )
        path.lineWidth = checkmarkerThickness
        checkmarkerColor.setStroke()
        path.stroke()
    }

}
