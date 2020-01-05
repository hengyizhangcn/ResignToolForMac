//
//  ActivityIndicator.swift
//  ResignTool
//
//  Created by zhy on 2020/1/5.
//  Copyright © 2020 UAMAStudio. All rights reserved.
//

import SwiftUI
import AppKit

/// 自定义菊花批示
struct ActivityIndicator: NSViewRepresentable {
    
    /// 是否 显示动画
    @Binding var shouldAnimate: Bool
    
    /// 生成视图
    /// - Parameter context: 上下文
    func makeNSView(context: NSViewRepresentableContext<ActivityIndicator>) -> NSProgressIndicator {
        let indicator = NSProgressIndicator()
        indicator.style = .spinning
        return indicator
    }
    
    /// 更新视图
    /// - Parameters:
    ///   - nsView: 视图
    ///   - context: 上下文
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
