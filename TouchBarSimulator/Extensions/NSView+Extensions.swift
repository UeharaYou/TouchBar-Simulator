//
//  NSView+Extensions.swift
//  TouchBarSimulator
//
//  Created by 上原葉 on 10/2/23.
//

import Foundation

extension NSView {
    public func getFittingRect(withMinimunHeight height: CGFloat) -> CGSize {
        let temperalConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: height)
        temperalConstraint.priority = .required - 1 // just to avoid conflicts from system (height == 0) when there's no super view / not updated until the next runloop event.
        addConstraint(temperalConstraint)
        temperalConstraint.isActive = true
        let fitSize = fittingSize
        temperalConstraint.isActive = false
        removeConstraint(temperalConstraint)
        return fitSize
    }
    public func getFittingRect(withMinimunWidth width: CGFloat) -> CGSize {
        let temperalConstraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: width)
        temperalConstraint.priority = .required - 1 // just to avoid conflicts from system (height == 0) when there's no super view / not updated until the next runloop event.
        addConstraint(temperalConstraint)
        temperalConstraint.isActive = true
        let fitSize = fittingSize
        temperalConstraint.isActive = false
        removeConstraint(temperalConstraint)
        
        return fitSize
    }
}
