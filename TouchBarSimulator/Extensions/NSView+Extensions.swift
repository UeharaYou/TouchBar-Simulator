//
//  NSView+Extensions.swift
//  TouchBarSimulator
//
//  Created by 上原葉 on 10/2/23.
//

import Foundation

extension NSView {
    func getFittingRect(withMinimunHeight height: CGFloat) -> CGSize {
        let temperalConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: height)
        temperalConstraint.priority = .required - 1 // just to avoid conflicts from system (height == 0) when there's no super view / not updated until the next runloop event.
        addConstraint(temperalConstraint)
        temperalConstraint.isActive = true
        let fitSize = fittingSize
        temperalConstraint.isActive = false
        removeConstraint(temperalConstraint)
        return fitSize
    }
    
    func getFittingRect(withMinimunWidth width: CGFloat) -> CGSize {
        let temperalConstraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: width)
        temperalConstraint.priority = .required - 1 // just to avoid conflicts from system (height == 0) when there's no super view / not updated until the next runloop event.
        addConstraint(temperalConstraint)
        temperalConstraint.isActive = true
        let fitSize = fittingSize
        temperalConstraint.isActive = false
        removeConstraint(temperalConstraint)
        
        return fitSize
    }
    
    static func frameView(from frame: NSRect) -> NSView {
        let newView = NSView()
        newView.translatesAutoresizingMaskIntoConstraints = false
        let newViewLayoutConstraints = [
            NSLayoutConstraint.constraints(withVisualFormat: "H:[newView(==width)]", metrics: ["width": frame.width], views: ["newView": newView]),
            NSLayoutConstraint.constraints(withVisualFormat: "V:[newView(==height)]", metrics: ["height": frame.height], views: ["newView": newView])
        ].reduce([], +)
        newView.addConstraints(newViewLayoutConstraints)
        NSLayoutConstraint.activate(newViewLayoutConstraints)
        
        return newView
    }
}
