//
//  NSRect+Extensions.swift
//  TouchBarSimulator
//
//  Created by 上原葉 on 10/5/23.
//

import Foundation

extension CGRect {
    
    enum XPositioning {
        case retained
        case leftOut(padding: Double)
        case left(padding: Double)
        case center
        case right(padding: Double)
        case rightOut(padding: Double)
    }

    enum YPositioning {
        case retained
        case bottomOut(padding: Double)
        case bottom(padding: Double)
        case center
        case top(padding: Double)
        case topOut(padding: Double)
    }
    
    enum Expanding {
        case bottom(padding: Double)
        case top(padding: Double)
        case left(padding: Double)
        case right(padding: Double)
    }
    
    func isSizeConfined(with referenceRect: CGRect) -> Bool {
        return self.width <= referenceRect.width && self.height <= referenceRect.height
    }
    
    func isContained(in referenceRect: CGRect) -> Bool {
        referenceRect.minX <= self.minX && self.maxX <= referenceRect.maxX &&
            referenceRect.minY <= self.minY && self.maxY <= referenceRect.maxY
    }
    
    func sizeConfinedRect(with referenceRect: CGRect) -> CGRect {
        let targetRect = self
        return CGRect(x: targetRect.origin.x,
                      y: targetRect.origin.y,
                      width: min(targetRect.width, referenceRect.width),
                      height: min(targetRect.height, referenceRect.height))
    }
    
    func expandedRect(options: [Expanding], with referenceRect: CGRect) -> CGRect {
        var targetRect = self
        
        if !isContained(in: referenceRect) {
            return targetRect
        }
        
        for option in options {
            switch option {
            case .left(padding: let padding):
                let dWidth = targetRect.minX - referenceRect.minX - padding
                targetRect = CGRect(origin: .init(x: targetRect.origin.x - dWidth, y: targetRect.origin.y),
                                    size: .init(width: targetRect.width + dWidth, height: targetRect.height))
            case .right(padding: let padding):
                let dWidth = referenceRect.maxX - targetRect.maxX - padding
                targetRect = CGRect(origin: targetRect.origin,
                                    size: .init(width: targetRect.width + dWidth, height: targetRect.height))
            case .bottom(padding: let padding):
                let dHeight = targetRect.minY - referenceRect.minY - padding
                targetRect = CGRect(origin: .init(x: targetRect.origin.x, y: targetRect.origin.y - dHeight),
                                    size: .init(width: targetRect.width, height: targetRect.height + dHeight))
            case .top(padding: let padding):
                let dHeight = referenceRect.maxY - targetRect.maxY - padding
                targetRect = CGRect(origin: targetRect.origin,
                                    size: .init(width: targetRect.width, height: targetRect.height + dHeight))
            }
        }
        
        return targetRect
    }
    
    func alignedRect(alignX xPositioning: XPositioning, alignY yPositioning: YPositioning, with referenceRect: CGRect) -> CGRect {
        let targetRect = self
        let targetSize = targetRect.size
        
        let x: Double
        let y: Double
        switch xPositioning {
        case .leftOut (let padding):
            x = referenceRect.minX - targetSize.width - 1 - padding
        case .left (let padding):
            x = referenceRect.minX + padding
        case .center:
            x = referenceRect.midX - targetSize.width / 2
        case .right (let padding):
            x = referenceRect.maxX - targetSize.width - padding
        case .rightOut (let padding):
            x = referenceRect.maxX + 1 + padding
        case .retained:
            x = targetRect.origin.x
        }
        
        switch yPositioning {
        case .bottomOut (let padding):
            y = referenceRect.minY - targetSize.height - 1 - padding
        case .bottom (let padding):
            y = referenceRect.minY + padding
        case .center:
            y = referenceRect.midY - targetSize.height / 2
            
        case .topOut (let padding):
            y = referenceRect.maxY + 1 + padding
        case .top (let padding):
            y = referenceRect.maxY - targetSize.height - padding

        case .retained:
            y = targetRect.origin.y
        }
        
        let origin = CGPoint(x: x, y: y)
        let alignedRect = CGRect(origin: origin, size: targetSize)
        return alignedRect
    }

}
