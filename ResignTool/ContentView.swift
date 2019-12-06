//
//  ContentView.swift
//  ResignTool
//
//  Created by zhanghengyi on 2019/11/29.
//  Copyright © 2019 UAMAStudio. All rights reserved.
//

//./resignTool -i /Users/hengyi.zhang/Desktop/重签名/家年华/原包/MerchantAideForJNH.ipa -m /Users/hengyi.zhang/Desktop/重签名/家年华/embedded.mobileprovision -v 5.0.0


import SwiftUI

enum SCFileType {
    case ipa
    case mobileprovision
}

struct ContentView: View {
    @State var ipaPath: String = ""
    @State var mobileprovisionPath: String = ""
    @State var bundleId: String = ""
    @State var newVersion: String = ""
    
    var body: some View {
        VStack {
            HStack {
                TextField("ipa路径", text: $ipaPath)
                    .disabled(true)
                Button(action: {
                    self.actionBrowseIpa(.ipa)
                }) {
                    Text("浏览")
                        .foregroundColor(Color.black)
                }
            }.padding(EdgeInsets(top: 15, leading: 15, bottom: 0, trailing: 15))
            
            HStack {
                TextField("描述文件路径", text: $mobileprovisionPath)
                    .disabled(true)
                Button(action: {
                    self.actionBrowseIpa(.mobileprovision)
                }) {
                    Text("浏览")
                        .foregroundColor(Color.black)
                }
            }.padding(EdgeInsets(top: 15, leading: 15, bottom: 0, trailing: 15))
            
            HStack {
                Text("签名后bundleId: \(bundleId)")
                Spacer()
            }.padding(EdgeInsets(top: 15, leading: 15, bottom: 0, trailing: 15))
            
            HStack {
                TextField("新版本号，可不填，默认之前的版本号加1", text: $bundleId)
                Spacer()
            }.padding(EdgeInsets(top: 15, leading: 15, bottom: 0, trailing: 15))
            
            
            HStack {
                Button(action: {
                    self.resignAction()
                }) {
                    Text("重签名")
                        .foregroundColor(Color.black)
                }
            }.padding(EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15))
        }.onAppear {
        }
    }
    
    
    func actionBrowseIpa(_ fileType: SCFileType) -> Void {
        
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        
        var allowedFileTypes: Array<String> = []
        switch fileType {
        case .ipa:
            allowedFileTypes = ["ipa", "IPA"]
            break
        case .mobileprovision:
            allowedFileTypes = ["mobileprovision"]
            break
        }
        
        openPanel.allowedFileTypes = allowedFileTypes
        openPanel.begin { (result) -> Void in
            if result == .OK {
                let path = openPanel.url?.path ?? ""
                switch fileType {
                case .ipa:
                    self.ipaPath = path
                    break
                case .mobileprovision:
                    self.mobileprovisionPath = path
                    break
                }
            }
        }
    }
    
    func resignAction() {
        if ipaPath.count == 0 {
            showAlertWith(title: nil, message: "请指定IPA文件", style: .critical)
        } else if mobileprovisionPath.count == 0 {
            showAlertWith(title: nil, message: "请指定描述文件", style: .critical)
        } else {
            //开始签名
        }
    }
    
    // MARK: - Alert
    
    private func showAlertWith(title: String?, message: String, style: NSAlert.Style) {
        let alert = NSAlert()
        alert.messageText = title ?? "ResignTool"
        alert.informativeText = message
        alert.alertStyle = style
        alert.addButton(withTitle: "关闭")
        if let window = NSApp.keyWindow {
            alert.beginSheetModal(for: window, completionHandler: nil)
        } else {
            alert.runModal()
        }
    }
}
