//
//  TouchBarAnimation.swift
//  TouchBarSimulator
//
//  Created by 上原葉 on 8/28/23.
//

import OSLog
import AppKit

class TouchBarAnimation: NSAnimation {
    public typealias AnimationFunc = (_ currentProgress: Float,_ currentValue: Float) -> Void
    public static let emptyAnimation: AnimationFunc = {_, _ in return}
    
    override var currentProgress: NSAnimation.Progress {
        didSet {
            super.currentProgress = currentProgress
            if isAnimating {
                animation(super.currentProgress,currentValue)
                //_ = animations.map{$0(super.currentProgress,currentValue)}
            }
        }
    }
    public var animation: AnimationFunc  = {(_, _) in return} {
        didSet {
            // immediately stop (cancel) current animation & reset
            if isAnimating {
                stop()
                //NSLog("animation Interrupted: \(currentProgress)")
                currentProgress = 0.0
            }
            //start() // Allow manual triggers
        }
    }

    public convenience init(duration: TimeInterval, animationCurve: NSAnimation.Curve, blockMode: NSAnimation.BlockingMode) {
        self.init(duration: duration, animationCurve: animationCurve)
        self.animationBlockingMode = blockMode
        self.frameRate = 0.0
    }
}

//infix operator +
func + (animationsA: @escaping TouchBarAnimation.AnimationFunc, animationsB: @escaping TouchBarAnimation.AnimationFunc) -> TouchBarAnimation.AnimationFunc {
    return {
        (currentProgress, currentValue) in
        animationsA(currentProgress,currentValue)
        animationsB(currentProgress,currentValue)
        return
    }
}
