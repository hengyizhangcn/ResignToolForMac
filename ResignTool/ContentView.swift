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

struct ContentView: View, DropDelegate {
    @State private var ipaPath = ""
    @State private var mobileprovisionPath = ""
    @State private var bundleId = ""
    @State private var newVersion = ""
    @State private var sliderValue: Double = 0
    @State private var pluginInfoDict: [String: String] = [:]
    @State private var appexName = ""
    @State private var appexProvisionPath = ""
    @State private var appexBundleId = ""
    @State private var showResignProgressBar = false
    @State private var shouldUnzipAnimate = false
    private let maxValue: Double = 10
    
    var body: some View {
        VStack {
            HStack {
                Text("安装包:").frame(width: 160.0, height: 30.0, alignment: .trailing)
                TextField("ipa路径", text: $ipaPath)
                Button(action: {
                    self.browseAction()
                }) {
                    Text("浏览")
                }
            }.padding(EdgeInsets(top: 15, leading: 15, bottom: 0, trailing: 15))
            
            VStack {
                HStack {
                    Text("描述文件:").frame(width: 160.0, height: 30.0, alignment: .trailing)
                    TextField("描述文件路径", text: $mobileprovisionPath)
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
                        TextField("描述文件路径，非必填", text: $appexProvisionPath)
                        Button(action: {
                            self.browseAppexMobileProvision()
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
    
    /// 浏览文件
    func browseAppexMobileProvision() {
        let allowedFileTypes = ["mobileprovision"]
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedFileTypes = allowedFileTypes
        openPanel.begin { (result) -> Void in
            if result == .OK {
                let urls = openPanel.urls
                for url in urls {
                    let path = url.path
                    self.appexProvisionPath = path
                    self.appexBundleId = self.abstractBundleId(self.appexProvisionPath)
                }
            }
        }
    }
    
    func handFilePath(_ path: String) {
        if path.hasSuffix(".ipa") || path.hasSuffix(".IPA") {
            self.ipaPath = path
            
            self.shouldUnzipAnimate = true
            DispatchQueue.global().async {
                self.abstractPlugins()
            }
        } else if path.hasSuffix(".mobileprovision") {
            self.mobileprovisionPath = path
            DispatchQueue.global().async {
                self.bundleId = self.abstractBundleId(self.mobileprovisionPath)
            }
        }
    }
    
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
                    }
                }, { (result) in
                    if (!result) {
                        self.showResignProgressBar = false
                    }
                })
            }
        }
    }
    
    /// 提取bundle id
    func abstractBundleId(_ tempMobileprovisionPath: String) -> String {
        let mobileprovisionData = ResignHelper.runCommand(launchPath: "/usr/bin/security", arguments: ["cms", "-D", "-i", tempMobileprovisionPath])
        
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
                        return appId
                    }
                }
            }
        } catch {
            print(error)
        }
        return ""
    }
    
    /// 提取插件 frameworks等
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
            
            let frameworks = try manager.contentsOfDirectory(atPath: appPath + "/Frameworks")
            for fileName in frameworks {
//                let frameworkPath = manager.currentDirectoryPath + "/Frameworks/" + fileName
                pluginInfoDict[fileName] = ""
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
