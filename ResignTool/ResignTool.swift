//
//  main.swift
//  resignTool
//
//  Created by zhy on 2018/11/6.
//  Copyright © 2018 zhy. All rights reserved.
//

import Foundation

/// 重签名工具
class ResignTool {
    let help =
        "  version: 1.2.0\n" +
            "  usage: resignTool [-h] [-i <path>] [-m <path>] [-v <version>] [-callKit <callkit>]\n" +
            "  -h   this help.\n" +
            "  -i   the path of .ipa file.\n" +
            "  -m   the path of .mobileprovision file.\n" +
            "  -v   the new version of the app.\n" +
            "  -b   the new bundle id of the app.\n" +
            "  -info   the basic info of this ipa(in the future).\n" +
            "       if the version is not set, and 1 will be automatically added to the last of version components which separated by charater '.'.\n" +
    "  Please contact if you have some special demmands."
    
    /// 主包路径
    var ipaPath: String?
    /// 主包签名文件路径
    var mobileprovisionPath: String?
    /// 新版本
    var newVersion: String?
    /// 扩展应用信息
    var appexInfoArray: [[String: String]] = [[:]]
    /// 主对签名后对应的bundleId
    var bundleId: String?
    
    /// 找到.app文件
    ///
    /// - Returns: .app文件
    @discardableResult
    func enumeratePayloadApp() -> String {
        let manager = FileManager.default
        do {
            let contents = try manager.contentsOfDirectory(atPath: "Payload")
            for fileName in contents {
                if fileName.contains(".app") {
                    return manager.currentDirectoryPath + "/Payload/" + fileName
                }
            }
            print("The .app file not exist!")
        } catch {
            print("Error occurs")
            return ""
        }
        return ""
    }
    
    /// 打印帮助
    func showHelp() {
        print(help)
        terminate()
    }
    
    /// terminate process
    func terminate() {
        exit(0)
    }
    
    /// 检查用户输入
    func checkUserInput() {
        let arguments = CommandLine.arguments
        
        //analysize user's input
        for i in 1..<arguments.count {
            
            let arg = arguments[i]
            
            switch (arg) {
            case "-m":
                if arguments.count > i {
                    mobileprovisionPath = arguments[i + 1]
                }
                break
            case "-i":
                if arguments.count > i {
                    ipaPath = arguments[i + 1]
                }
                break
            case "-v":
                if arguments.count > i {
                    newVersion = arguments[i + 1]
                }
                break
            case "-b":
                if arguments.count > i {
                    bundleId = arguments[i + 1]
                }
                break
            case "-h":
                showHelp()
            case "-":
                print("bad option:"+arg)
                terminate()
            default:
                break;
            }
        }
        
        //check user's input
        if ipaPath == nil {
            print("The path of .ipa file doesnot exist, please point it out")
            terminate()
        }
    }
    
    /// 重签名流程
    /// - Parameters:
    ///   - actionProgress: 重签名进程回调
    ///   - resultBlock: 签名结果回调
    func resignAction(_ actionProgress: ((Double) -> ())?, _ resultBlock: ((Bool) -> ())?) {
        
        actionProgress?(0)
        
        // 重置初始值
        ResignHelper.lastTeamName = ""
        ResignHelper.newIPAPath = ""
        
        //remove middle files and directionary
        var appPath = enumeratePayloadApp()
        
        if appPath.count == 0 {
            ResignHelper.clearMiddleProducts()
            
            actionProgress?(1)
            
            //unzip .ipa file to the directory the same with ipaPath
            // because xcrun cannot be used within an App Sandbox.
            // close sandbox
            
            ResignHelper.runCommand(launchPath: "/usr/bin/unzip", arguments: [ipaPath!])
            
            actionProgress?(2)
            
            appPath = enumeratePayloadApp()
        }
        
        //codesign -d --entitlements - SmartHeda.app
        
        //abstract entitlement
        
        //abstract plist for app
        ResignHelper.abstractPlist(appPath, mobileprovisionPath, "entitlements.plist")
        
        actionProgress?(3)
        
        let componentsList = ResignHelper.findComponentsList(appPath)
        
        for appexInfoDict in appexInfoArray {
            if let appexName = appexInfoDict["appexName"],
                let appexBundleId = appexInfoDict["appexBundleId"],
                let appexProvisionPath = appexInfoDict["appexProvisionPath"] {
                
                let appexEntitlementsFilePath = "appexEntitlements.plist"
                let appexPath = appPath + "/PlugIns/" + appexName
                
                //abstract plist for callkit
                ResignHelper.abstractPlist(appexPath, appexProvisionPath, appexEntitlementsFilePath);
                
                actionProgress?(4)
                
                //set the app version
                ResignHelper.configurefreshVersion(newVersion, appexBundleId, appexPath)
                
                //resign appex
                let resignResult = ResignHelper.replaceProvisionAndResign(appexPath, appexProvisionPath, appexEntitlementsFilePath)
                if (!resignResult) {
                    resultBlock?(false)
                    return
                }

                
                actionProgress?(5)
            }
        }
        
        for path in componentsList {
            
            let filePath = appPath + "/Frameworks/" + path
            
            ResignHelper.resignDylibs(filePath, mobileprovisionPath, "entitlements.plist")
            
            actionProgress?(5.5)
        }
        
        //set the app version
        ResignHelper.configurefreshVersion(newVersion, bundleId, appPath)
        
        
        actionProgress?(6)
        
        //resign app
        let resignAppResult = ResignHelper.replaceProvisionAndResign(appPath, mobileprovisionPath, "entitlements.plist")
        if (!resignAppResult) {
            resultBlock?(false)
            return
        }
        
        actionProgress?(7)
        
        //codesign -vv -d SmartHeda.app
        ResignHelper.runCommand(launchPath: "/usr/bin/codesign", arguments: ["-vv", "-d", appPath])
        
        
        actionProgress?(8)
        
        //repacked app
        //zip -r SmartHeda.ipa Payload/
        ResignHelper.repackApp(ipaPath)
        
        
        actionProgress?(9)
        
        //remove middle files and directionary
        ResignHelper.clearMiddleProducts()
        
        
        actionProgress?(10)
    }
}

