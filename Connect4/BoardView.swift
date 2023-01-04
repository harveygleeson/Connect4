//
//  BoardView.swift
//  Connect4
//
//  Created by Harvey on 20/12/2022.
//

import UIKit

class BoardView: UIView {

    private let shapeLayer = CAShapeLayer()

    override func layoutSubviews() {
        super.layoutSubviews()
        shapeLayer.frame = self.bounds
        shapeLayer.fillRule = .evenOdd
        
        let path = UIBezierPath(rect: self.bounds)
        
        let viewWidth = self.frame.width
        let viewHeight = self.frame.height

        let columnWidth = viewWidth / 7
        let rowHeight = viewHeight / 6
        
        let origin = CGRect(x: 0, y: 0, width: columnWidth, height: rowHeight)
        print(columnWidth)
        print(rowHeight)
        let discDiameter = min(columnWidth, rowHeight) * 0.86
        let discRadius = discDiameter / 2
        for i in 0 ..< 6 {

            // Calculate change in y
            let yDifference = CGFloat(i) * origin.height
            for j in 0 ..< 7 {

                // Change in x
                let xDifference = CGFloat(j) * origin.width

                // Centerpoint of slot
                let center = CGPoint(x: origin.midX + xDifference, y: origin.midY + yDifference)

                // Create slots
                let discSlot = UIBezierPath(arcCenter: center, radius: discRadius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
                path.append(discSlot)
            }
        }
        
        shapeLayer.path = path.cgPath
        self.layer.mask = shapeLayer
    }
}
