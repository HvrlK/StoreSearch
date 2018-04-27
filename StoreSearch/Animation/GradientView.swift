//
//  GradientView.swift
//  StoreSearch
//
//  Created by Vitalii Havryliuk on 4/27/18.
//  Copyright © 2018 Vitalii Havryliuk. All rights reserved.
//

import UIKit

class GradientView: UIView {
    
    // MARK: - Methods
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clear
    }
    
    override func draw(_ rect: CGRect) {
        let components: [CGFloat] = [ 0, 0, 0, 0.3, 0, 0, 0, 0.7 ]
        let locations: [CGFloat] = [ 0, 1 ]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorSpace: colorSpace, colorComponents: components, locations: locations, count: 2)
        let x = bounds.midX
        let y = bounds.midY
        let centerPoint = CGPoint(x: x, y : y)
        let radius = max(x, y)
        let context = UIGraphicsGetCurrentContext()
        context?.drawRadialGradient(
            gradient!,
            startCenter: centerPoint,
            startRadius: 0,
            endCenter: centerPoint,
            endRadius: radius,
            options: .drawsAfterEndLocation
        )
    }
    
}
