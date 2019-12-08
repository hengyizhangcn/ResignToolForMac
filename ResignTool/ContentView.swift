//
//  ContentView.swift
//  ResignTool
//
//  Created by zhanghengyi on 2019/11/29.
//  Copyright © 2019 UAMAStudio. All rights reserved.
//

//./resignTool -i /Users/hengyi.zhang/Desktop/重签名/家年华/原包/MerchantAideForJNH.ipa -m /Users/hengyi.zhang/Desktop/重签名/家年华/embedded.mobileprovision -v 5.0.0

// 待办：生成签名记录

import SwiftUI

enum SCFileType {
    case ipa
    case mobileprovision
}

struct ContentView: View, DropDelegate {
    @State var ipaPath: String = ""
    @State var mobileprovisionPath: String = ""
    @State var bundleId: String = ""
    @State var newVersion: String = ""
    
    var body: some View {
        VStack {
            HStack {
                Text("安装包:").frame(width: 60.0, height: 30.0, alignment: .leading)
                TextField("ipa路径", text: $ipaPath)
                Button(action: {
                    self.browseAction()
                }) {
                    Text("浏览")
                        .foregroundColor(Color.black)
                }
            }.padding(EdgeInsets(top: 15, leading: 15, bottom: 0, trailing: 15))
            
            HStack {
                Text("描述文件:").frame(width: 60.0, height: 30.0, alignment: .leading)
                TextField("描述文件路径", text: $mobileprovisionPath)
                Button(action: {
                    self.browseAction()
                }) {
                    Text("浏览")
                        .foregroundColor(Color.black)
                }
            }.padding(EdgeInsets(top: 15, leading: 15, bottom: 0, trailing: 15))
            
            HStack {
                Text("新bundleId: \(bundleId)")
                Spacer()
            }.padding(EdgeInsets(top: 15, leading: 15, bottom: 0, trailing: 15))
            
            HStack {
                Text("版本号:").frame(width: 60.0, height: 30.0, alignment: .leading)
                TextField("默认尾号加1，非必填", text: $newVersion)
            }.padding(EdgeInsets(top: 15, leading: 15, bottom: 0, trailing: 15))
            
            
            HStack {
                Button(action: {
                    self.resignAction()
                }) {
                    Text("重签名")
                        .foregroundColor(Color.black)
                }
            }.padding(EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15))
        }.onDrop(of: [(kUTTypeFileURL as String)], delegate: self)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        let itemProviders = info.itemProviders(for: [(kUTTypeFileURL as String)])
        for itemProvider in itemProviders {
            itemProvider.loadItem(forTypeIdentifier: (kUTTypeFileURL as String), options: nil) {(item, error) in
                if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                    let path = url.path
                    self.handFilePath(path)
                }
            }
        }
        return true
    }
    
    /// 浏览文件
    func browseAction() {
        let allowedFileTypes = ["ipa", "IPA", "mobileprovision"]
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedFileTypes = allowedFileTypes
        openPanel.begin { (result) -> Void in
            if result == .OK {
                let urls = openPanel.urls
                for url in urls {
                    let path = url.path
                    self.handFilePath(path)
                }
            }
        }
    }
    
    func handFilePath(_ path: String) {
        if path.hasSuffix(".ipa") || path.hasSuffix(".IPA") {
            self.ipaPath = path
        } else if path.hasSuffix(".mobileprovision") {
            self.mobileprovisionPath = path
            self.abstractBundleId()
        }
    }
    
    func resignAction() {
        if ipaPath.count == 0 {
            showAlertWith(title: nil, message: "请指定IPA文件", style: .critical)
        } else if mobileprovisionPath.count == 0 {
            showAlertWith(title: nil, message: "请指定描述文件", style: .critical)
        } else {
            //开始签名
            let resignTool = ResignTool()
            resignTool.ipaPath = ipaPath
            resignTool.mobileprovisionPath = mobileprovisionPath
            resignTool.bundleId = bundleId
            resignTool.resignAction()
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
    
    /// 提取bundle id
    func abstractBundleId() {
        let mobileprovisionData = ResignHelper.runCommand(launchPath: "/usr/bin/security", arguments: ["cms", "-D", "-i", mobileprovisionPath])
        
        do {
            let datasourceDictionary = try PropertyListSerialization.propertyList(from: mobileprovisionData, options: [], format: nil)
            
            if let dict = datasourceDictionary as? Dictionary<String, Any> {
                let Entitlements = dict["Entitlements"] as? Dictionary<String, Any>
                if let entitlementsDict = Entitlements {
                    let applicationIdentifier = entitlementsDict["application-identifier"] as? String
                    if let appIdStr = applicationIdentifier {
                        //去除teamId剩下的即为bundleId
                        var arr = appIdStr.split(separator: ".")
                        //去除第一个元素teamId
                        arr.removeFirst()
                        let appId = arr.joined(separator: ".")
                        self.bundleId = appId
                    }
                }
            }
        } catch {
            print(error)
        }
    }
}
