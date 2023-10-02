//
//  DefaultsManager.swift
//  TouchBar Simulator
//
//  Created by 上原葉 on 8/13/23.
//

import Foundation
import CoreGraphics
import Defaults

extension TouchBarWindow.Docking: Defaults.Serializable {}
extension CGPoint: Defaults.Serializable {}
extension CGRect: Defaults.Serializable {}
extension CGSize: Defaults.Serializable {}

extension Defaults.Keys {
    static let windowDocking = Key<TouchBarWindow.Docking>("windowDocking", default: .floating)
    static let lastFloatingPosition = Key<CGPoint>("lastFloatingPosition", default: CGPoint(x: 0, y: 0))
    static let lastWindowFrame = Key<CGRect>("lastWindowFrame", default: CGRect(x: 0, y: 0, width: 1014, height: 60))
    static let windowDetectionTimeOut = Key<TimeInterval>("windowDetectionTimeOut", default: TimeInterval(1.5))
}
