//
//  main.swift
//  resignTool
//
//  Created by zhy on 2018/11/6.
//  Copyright © 2018 zhy. All rights reserved.
//

import Foundation

class ResignTool {
    let help =
        "  version: 1.2.0\n" +
            "  usage: resignTool [-h] [-i <path>] [-m <path>] [-v <version>] [-callKit <callkit>]\n" +
            "  -h   this help.\n" +
            "  -i   the path of .ipa file.\n" +
            "  -m   the path of .mobileprovision file.\n" +
            "  -v   the new version of the app.\n" +
            "  -callKit   the callkit mobileprovision file(This is customed option).\n" +
            "  -b   the new bundle id of the app.\n" +
            "  -info   the basic info of this ipa(in the future).\n" +
            "       if the version is not set, and 1 will be automatically added to the last of version components which separated by charater '.'.\n" +
    "  Please contact if you have some special demmands."
    
    var ipaPath: String?
    var mobileprovisionPath: String?
    var newVersion: String?
    var callKitMobileProvision: String?
    var bundleId: String?
    
    /// enumerate Payload directory, find out the .app file
    ///
    /// - Returns: .app file name
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
            terminate()
        } catch {
            print("Error occurs")
            terminate()
        }
        return ""
    }
    
    /// print help
    func showHelp() {
        print(help)
        terminate()
    }
    
    /// terminate process
    func terminate() {
        exit(0)
    }
    
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
            case "-callKit":
                if arguments.count > i {
                    callKitMobileProvision = arguments[i + 1]
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
    
    func resignAction() {
        //remove middle files and directionary
        ResignHelper.clearMiddleProducts()
        
        //unzip .ipa file to the directory the same with ipaPath
        // because xcrun cannot be used within an App Sandbox.
        // close sandbox
        
        ResignHelper.runCommand(launchPath: "/usr/bin/unzip", arguments: [ipaPath!])
        
        //codesign -d --entitlements - SmartHeda.app
        
        //abstract entitlement
        let appPath = enumeratePayloadApp()
        
        //abstract plist for app
        ResignHelper.abstractPlist(appPath, mobileprovisionPath, "entitlements.plist")
        
        let componentsList = ResignHelper.findComponentsList(appPath)
        
        if callKitMobileProvision != nil {
            let callKitPlistFilePath = "CallFunction.plist"
            let callKitAppexPath = appPath + "/PlugIns/CallFunction.appex"
            
            //abstract plist for callkit
            ResignHelper.abstractPlist(callKitAppexPath, nil, callKitPlistFilePath);
            
            //resign appex
            ResignHelper.replaceProvisionAndResign(callKitAppexPath, callKitMobileProvision, callKitPlistFilePath)
        } else if componentsList != nil {
            for path in componentsList! {
                let filePath = appPath + "/Frameworks/" + (path as! String)
                
                ResignHelper.resignDylibs(filePath, mobileprovisionPath, "entitlements.plist")
            }
        }
        
        //set the app version
        ResignHelper.configurefreshVersion(newVersion, bundleId, appPath)
        
        //resign app
        ResignHelper.replaceProvisionAndResign(appPath, mobileprovisionPath, "entitlements.plist")
        
        //codesign -vv -d SmartHeda.app
        ResignHelper.runCommand(launchPath: "/usr/bin/codesign", arguments: ["-vv", "-d", appPath])
        
        //repacked app
        //zip -r SmartHeda.ipa Payload/
        ResignHelper.repackApp(ipaPath)
        
        //remove middle files and directionary
        ResignHelper.clearMiddleProducts()
        
        print("Done!")
    }
    
    func copyFile(fpath:String, tpath:String) {
        do{
            //如果已存在，先删除，否则拷贝不了
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: tpath){
                try fileManager.removeItem(atPath: tpath)
            }
            
            try fileManager.copyItem(atPath: fpath, toPath: tpath)
            
        }catch{}
        
    }
}

