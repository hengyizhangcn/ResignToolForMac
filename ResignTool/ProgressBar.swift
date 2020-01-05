//
//  ProgressBar.swift
//  ResignTool
//
//  Created by zhy on 2019/12/8.
//  Copyright © 2019 UAMAStudio. All rights reserved.
//

import SwiftUI
import AppKit

/// 自定义SwiftUI进度条
struct ProgressBar: View {
    /// 当前进度
    private let value: Binding<Double>
    /// 最大值
    private let maxValue: Double
    /// 背景是不可用
    private let backgroundEnabled: Bool
    /// 背景色
    private let backgroundColor: Color
    /// 前景色
    private let foregroundColor: Color
    
    init(value: Binding<Double>,
         maxValue: Double,
         backgroundEnabled: Bool = true,
         backgroundColor: Color = Color(NSColor(red: 245/255,
                                                green: 245/255,
                                                blue: 245/255,
                                                alpha: 1.0)),
         foregroundColor: Color = Color.black) {
        self.value = value
        self.maxValue = maxValue
        self.backgroundEnabled = backgroundEnabled
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }
    
    var body: some View {
        // 1
        ZStack {
            // 2
            GeometryReader { geometryReader in
                // 3
                if self.backgroundEnabled {
                    Capsule()
                        .foregroundColor(self.backgroundColor) // 4
                }
                
                Capsule()
                    .frame(width: self.progress(value: self.value.wrappedValue,
                                                maxValue: self.maxValue,
                                                width: geometryReader.size.width)) // 5
                    .foregroundColor(self.foregroundColor) // 6
                    .animation(.easeIn) // 7
            }
        }
    }
    
    /// 进度设置
    /// - Parameters:
    ///   - value: 当前进度
    ///   - maxValue: 最大进度值
    ///   - width: 宽度
    private func progress(value: Double,
                          maxValue: Double,
                          width: CGFloat) -> CGFloat {
        let percentage = value / maxValue
        return width *  CGFloat(percentage)
    }
}
