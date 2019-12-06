//
//  RTMainViewController.swift
//  ResignTool
//
//  Created by zhanghengyi on 2019/12/6.
//  Copyright © 2019 UAMAStudio. All rights reserved.
//

import AppKit
import SwiftUI

class RTMainViewController: NSViewController, NSDraggingDestination {
    
    init() {
        super.init(nibName: nil, bundle: nil)
        self.view = NSHostingView(rootView: ContentView())
        
        self.view.registerForDraggedTypes([NSPasteboard.PasteboardType.png])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        print("viewWillAppear")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("viewDidLoad")
    }
    
    func draggingEntered(sender: NSDraggingInfo!) -> NSDragOperation {
        print("Dragging Entered")
        return NSDragOperation.copy
    }

    func draggingUpdated(sender: NSDraggingInfo!) -> NSDragOperation  {
        print("UPDATED")
        return NSDragOperation.copy
    }
}
