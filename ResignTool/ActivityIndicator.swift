//
//  ActivityIndicator.swift
//  ResignTool
//
//  Created by zhy on 2020/1/5.
//  Copyright © 2020 UAMAStudio. All rights reserved.
//

import SwiftUI
import AppKit

struct ActivityIndicator: NSViewRepresentable {
    
    @Binding var shouldAnimate: Bool
    
    func makeNSView(context: NSViewRepresentableContext<ActivityIndicator>) -> NSProgressIndicator {
        let indicator = NSProgressIndicator()
        indicator.style = .spinning
        return indicator
    }
    
    func updateNSView(_ nsView: NSProgressIndicator, context: NSViewRepresentableContext<ActivityIndicator>) {
        if self.shouldAnimate {
            nsView.startAnimation(nil)
        } else {
            nsView.stopAnimation(nil)
        }
    }
}


//参考资料：
//1.SwiftUI Activity Indicator
//https://programmingwithswift.com/swiftui-activity-indicator/
