//
//  ColorPickButton
//  Notes
//
//  Created by Артем Куфаев on 09/07/2019.
//  Copyright © 2019 Артем Куфаев. All rights reserved.
//

import UIKit

@IBDesignable
class ColorPickButton: UIButton {
    
    @IBInspectable var checkmarkerColor: UIColor = .black
    @IBInspectable var checkmarkerThickness: CGFloat = 1.0
    @IBInspectable var isChecked: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        guard isChecked else { return }
        let frame = getCheckmarkerFrame(rect: rect)
        let path = UIBezierPath()
        path.move(to: CGPoint(
            x: frame.origin.x,
            y: frame.origin.y + frame.size.height * 2 / 3
        ))
        path.addLine(to: CGPoint(
            x: frame.origin.x + frame.size.width / 3,
            y: frame.origin.y + frame.size.height
        ))
        path.addLine(to: CGPoint(
            x: frame.origin.x + frame.size.width,
            y: frame.origin.y
        ))
        path.lineWidth = checkmarkerThickness
        checkmarkerColor.setStroke()
        path.stroke()
    }
    
    func getCheckmarkerFrame(rect: CGRect) -> CGRect {
        let origin = CGPoint(x: rect.size.width * 2 / 3 - 5, y: 5)
        let size = CGSize(width: rect.size.width / 3, height: rect.size.height / 3)
        return CGRect(origin: origin, size: size)
    }

}
