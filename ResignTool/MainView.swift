//
//  MainView.swift
//  ResignTool
//
//  Created by zhanghengyi on 2019/12/6.
//  Copyright © 2019 UAMAStudio. All rights reserved.
//

import AppKit
import SwiftUI

class MainView: NSView {
    init() {
        super.init(frame: NSRect(x: 0, y: 0, width: 480, height: 300))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
