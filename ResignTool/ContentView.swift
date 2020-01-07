//
//  ContentView.swift
//  ResignTool
//
//  Created by zhanghengyi on 2019/11/29.
//  Copyright © 2019 UAMAStudio. All rights reserved.
//

//./resignTool -i /Users/hengyi.zhang/Desktop/重签名/家年华/原包/MerchantAideForJNH.ipa -m /Users/hengyi.zhang/Desktop/重签名/家年华/embedded.mobileprovision -v 5.0.0

// 待办：
//1.生成签名记录
//2. “Typora” would like to access files in your Desktop folder.

import SwiftUI

enum SCFileType {
    case ipa
    case mobileprovision
}

/// 主界面
struct ContentView: View, DropDelegate {
    /// 主应用路径
    @State private var ipaPath = ""
    /// 主应用对应的签名文件路径
    @State private var mobileprovisionPath = ""
    /// 主应用签名后的包标识
    @State private var bundleId = ""
    /// 新版本号
    @State private var newVersion = ""
    /// 进度条进度
    @State private var sliderValue: Double = 0
    /// 扩展名称
    @State private var appexName = ""
    /// 扩展对应的签名文件
    @State private var appexProvisionPath = ""
    /// 扩展签名后 的包标识
    @State private var appexBundleId = ""
    /// 是否显示签名进度条
    @State private var showResignProgressBar = false
    /// 是否显示解压动画
    @State private var shouldUnzipAnimate = false
    private let maxValue: Double = 10
    
    var body: some View {
        VStack {
            HStack {
                Text("安装包:").frame(width: 160.0, height: 30.0, alignment: .trailing)
                TextField("ipa路径", text: $ipaPath).disabled(true)
                Button(action: {
                    self.browseAction()
                }) {
                    Text("浏览")
                }
            }.padding(EdgeInsets(top: 15, leading: 15, bottom: 0, trailing: 15))
            
            VStack {
                HStack {
                    Text("描述文件:").frame(width: 160.0, height: 30.0, alignment: .trailing)
                    TextField("描述文件路径", text: $mobileprovisionPath).disabled(true)
                    Button(action: {
                        self.browseAction()
                    }) {
                        Text("浏览")
                    }
                }.padding(EdgeInsets(top: 15, leading: 15, bottom: 0, trailing: 15))
                
                if (mobileprovisionPath.count > 0) {
                    HStack {
                        Text("对应bundleId:").frame(width: 160.0, height: 10.0, alignment: .trailing)
                        Text("\(bundleId)")
                        Spacer()
                    }.padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15))
                        .font(Font.system(size: 8))
                }
                
            }
            
            HStack {
                Text("版本号:").frame(width: 160.0, height: 30.0, alignment: .trailing)
                TextField("非必填", text: $newVersion)
            }.padding(EdgeInsets(top: 15, leading: 15, bottom: 0, trailing: 15))
            
            VStack {
                if (appexName.count > 0) {
                    HStack {
                        Text("\(appexName):").frame(width: 160.0, height: 30.0, alignment: .trailing)
                        TextField("描述文件路径，非必填", text: $appexProvisionPath).disabled(true)
                        Button(action: {
                            self.browseAction()
                        }) {
                            Text("浏览")
                        }
                    }.padding(EdgeInsets(top: 15, leading: 15, bottom: 0, trailing: 15))
                    if (appexProvisionPath.count > 0) {
                        HStack {
                            Text("对应bundleId:").frame(width: 160.0, height: 10.0, alignment: .trailing)
                            Text("\(appexBundleId)")
                            Spacer()
                        }.padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15))
                            .font(Font.system(size: 8))
                    }
                }
            }
            
            
            HStack {
                if (shouldUnzipAnimate) {
                    ActivityIndicator(shouldAnimate: $shouldUnzipAnimate)
                } else {
                    Button(action: {
                        self.resignAction()
                    }) {
                        Text("重签名")
                    }
                }
            }.padding(EdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15))
            if (showResignProgressBar) {
                HStack {
                    ProgressBar(value: $sliderValue,
                                maxValue: self.maxValue,
                                foregroundColor: .green)
                        .frame(height: 5)
                }.padding(EdgeInsets(top: 0, leading: 15, bottom: 15, trailing: 15))
            } else if (sliderValue == 10.0) {
                HStack {
                    Text("完成!")
                }.padding(EdgeInsets(top: 0, leading: 15, bottom: 15, trailing: 15))
            }
        }.onDrop(of: [(kUTTypeFileURL as String)], delegate: self)
    }
    
    /// 拖拽代理实现
    /// - Parameter info: 拖拽信息
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
    
    /// 保存文件事件处理
    func saveFileAction() {
        
        let ipaPathUrl = URL(fileURLWithPath: self.ipaPath)
        let ipaName = ipaPathUrl.lastPathComponent
        
        let savePanel = NSSavePanel()
        savePanel.title = "保存安装包"
        savePanel.message = "选择安装包保存的位置"
        savePanel.nameFieldLabel = "另存为:"
        savePanel.nameFieldStringValue = ipaName
        savePanel.tagNames = ["resignTool"]
        savePanel.allowedFileTypes = ["ipa", "IPA"]
        savePanel.isExtensionHidden = false
        savePanel.canCreateDirectories = true
        if let window = NSApp.keyWindow {
            savePanel.beginSheetModal(for: window) { (result) in
                if (result == .OK) {
                    if let targetPath = savePanel.url?.path {
                        ResignHelper.moveIPAFile(tpath: targetPath)
                    }
                }
            }
        }
    }
    
    /// 浏览选择文件
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
    
    /// 处理选择的文件
    /// - Parameter path: 文件路径
    func handFilePath(_ path: String) {
        if path.hasSuffix(".ipa") || path.hasSuffix(".IPA") {
            self.ipaPath = path
            
            // appex 相关信息来自于ipa，需要先清空
            self.appexName = ""
            self.appexBundleId = ""
            self.appexProvisionPath = ""
            // 把状态重置
            self.showResignProgressBar = false
            self.sliderValue = 0.0
            
            self.shouldUnzipAnimate = true
            DispatchQueue.global().async {
                self.abstractPlugins()
            }
        } else if path.hasSuffix(".mobileprovision") {
            DispatchQueue.global().async {
                let (bundleIdTemp, apsEnvironmentTemp) = ResignHelper.abstractBundleId(path)
                if (apsEnvironmentTemp == "production") {
                    self.bundleId = bundleIdTemp
                    self.mobileprovisionPath = path
                } else if (self.appexName.count > 0) {
                    // 如果存在appex，再赋值
                    self.appexBundleId = bundleIdTemp
                    self.appexProvisionPath = path
                }
            }
        }
    }
    
    /// 重签名按钮响应事件
    func resignAction() {
        if ipaPath.count == 0 {
            ResignHelper.showAlertWith(title: nil, message: "请指定IPA文件", style: .critical)
        } else if mobileprovisionPath.count == 0 {
            ResignHelper.showAlertWith(title: nil, message: "请指定描述文件", style: .critical)
        } else {
            //开始签名
            let resignTool = ResignTool()
            resignTool.ipaPath = ipaPath
            resignTool.mobileprovisionPath = mobileprovisionPath
            resignTool.bundleId = bundleId
            if appexName.count > 0 {
                resignTool.appexInfoArray = [["appexName":appexName,
                                              "appexProvisionPath":appexProvisionPath,
                                              "appexBundleId":appexBundleId]]
            }
            resignTool.newVersion = newVersion
            
            showResignProgressBar = true
            DispatchQueue.global().async {
                resignTool.resignAction({(step) in
                    DispatchQueue.main.async {
                        self.sliderValue = step
                        self.showResignProgressBar = self.sliderValue != 10.0
                        if (self.sliderValue == 10.0) {
                            self.saveFileAction()
                        }
                    }
                }, { (result) in
                    if (!result) {
                        self.showResignProgressBar = false
                    }
                })
            }
        }
    }
    
    /// 提取扩展文件
    func abstractPlugins() {
        
        //remove middle files and directionary
        ResignHelper.clearMiddleProducts()
        
        //unzip .ipa file to the directory the same with ipaPath
        // because xcrun cannot be used within an App Sandbox.
        // close sandbox
        
        ResignHelper.runCommand(launchPath: "/usr/bin/unzip", arguments: [self.ipaPath])
        
        let manager = FileManager.default
        do {
            var appPath = ""
            let contents = try manager.contentsOfDirectory(atPath: "Payload")
            for fileName in contents {
                if fileName.contains(".app") {
                    appPath = manager.currentDirectoryPath + "/Payload/" + fileName
                }
            }
            
            let plugIns = try manager.contentsOfDirectory(atPath: appPath + "/PlugIns")
            for fileName in plugIns {
//                let plugInPath = manager.currentDirectoryPath + "/PlugIns/" + fileName
                if fileName.contains(".appex") {
                    appexName = fileName
                }
            }
        } catch {
            print("Error occurs")
        }
        shouldUnzipAnimate = false
    }
}


//参考文档
//1.How do I bind a SwiftUI element to a value in a Dictionary?
//https://stackoverflow.com/questions/56978746/how-do-i-bind-a-swiftui-element-to-a-value-in-a-dictionary
