//
//  DiscView.swift
//  Connect4
//
//  Created by Harvey on 20/12/2022.
//

import UIKit

class DiscView: UIView {
    
    var numberLabel: UILabel?
    var discNumber: Int = 0
    { didSet {
        numberLabel?.text = String(discNumber)
    }}

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .red
        layer.cornerRadius = frame.size.width / 2.0
        layer.borderColor = UIColor.black.cgColor
        layer.borderWidth = 0.5

        numberLabel = UILabel(frame: CGRect(x: 22, y: -10, width: 100, height: 70))
        numberLabel!.font = UIFont(name: "Gill Sans", size: 18)
        numberLabel?.isHidden = true
        self.addSubview(numberLabel!)
    }
    
    
     required init?(coder aDecoder: NSCoder) {
         fatalError("init(coder:) not implemented")
     }
    
     override var collisionBoundsType: UIDynamicItemCollisionBoundsType {
         return .ellipse
     }
}
