//
//  resignHelper.swift
//  resignTool
//
//  Created by zhanghengyi on 2019/3/6.
//  Copyright © 2019 zhy. All rights reserved.
//

import Foundation

public class ResignHelper {
    
    /// execute the command and get the result
    ///
    /// - Parameters:
    ///   - launchPath: the full path of the command
    ///   - arguments: arguments
    /// - Returns: command execute result
    @discardableResult
    class func runCommand(launchPath: String, arguments: [String]) -> Data {
        let pipe = Pipe()
        let file = pipe.fileHandleForReading
        
        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments
        task.standardOutput = pipe
        task.launch()
        
        let data = file.readDataToEndOfFile()
        
        task.terminate()
        return data
    }
    
    /// remove middle files and directionary
    class func clearMiddleProducts() {
        
        runCommand(launchPath: "/bin/rm", arguments: ["-rf", "mobileprovision.plist"])
        runCommand(launchPath: "/bin/rm", arguments: ["-rf", "Payload"])
        runCommand(launchPath: "/bin/rm", arguments: ["-rf", "entitlements.plist"])
        runCommand(launchPath: "/bin/rm", arguments: ["-rf", "AppThinning.plist"]) //for thin if exists
        runCommand(launchPath: "/bin/rm", arguments: ["-rf", "CallFunction.plist"]) //for callkit if exists
    }
    
    /// abstract plist for app like framework, extension, appex, etc
    /// emphasis: if mobileprovisionPath is exist, abstract plist from the mobileprovisionPath, or from the appPath
    ///
    /// - Parameters:
    ///   - appPath: the appPath can be framework, extension, appex, etc
    ///   - mobileprovisionPath: the path of mobileprovision
    ///   - plistFilePath: target plist file
    class func abstractPlist(_ appPath: String, _ mobileprovisionPathTemp: String?, _ plistFilePath: String) {
        
        if mobileprovisionPathTemp != nil {
            let mobileprovisionData = runCommand(launchPath: "/usr/bin/security", arguments: ["cms", "-D", "-i", mobileprovisionPathTemp!]);

            let fileUrl = URL.init(fileURLWithPath: "mobileprovision.plist")
            do {
                try mobileprovisionData.write(to: fileUrl)
            } catch {
                print(error)
            }
            

            let plistXML = FileManager.default.contents(atPath: fileUrl.path)!
            do {
                //read plist file to dictionary
                let plistDict = try PropertyListSerialization.propertyList(from: plistXML, options: .mutableContainersAndLeaves, format: nil) as! [String: Any]
                
                let EntitlementsDict = plistDict["Entitlements"]

                
                let plistFilePathUrl = URL.init(fileURLWithPath: plistFilePath)
                
                if let plistOutputStream = OutputStream.init(toFileAtPath: plistFilePathUrl.path, append: false) {
                    
                    //should keep the outputstream open
                    plistOutputStream.schedule(in: RunLoop.current, forMode: .default)
                    plistOutputStream.open()
                    
                    //write the new plist content to file
                    PropertyListSerialization.writePropertyList(EntitlementsDict, to: plistOutputStream, format: PropertyListSerialization.PropertyListFormat.xml, options: 0, error: nil)
                }
            } catch {
                print(error)
            }
            
        } else {

            runCommand(launchPath: "/usr/bin/codesign", arguments: ["-d", "--entitlements", plistFilePath, appPath])
            do {
                let fileUrl = URL.init(fileURLWithPath: plistFilePath)
                var entitleData = try Data.init(contentsOf: fileUrl)
                entitleData.removeSubrange(0..<8) //first eight characters are unknown, should be removed
                
                try entitleData.write(to: fileUrl)
            } catch {
                print(error)
            }
        }
        
    }
    
    /// config app version
    ///
    /// - Parameter appPath: the path of the app
    class func configurefreshVersion(_ tempVersion: String?, _ bundleIdentifier: String?, _ appPath: String) {
        
        var refreshVersion = tempVersion
        
        let plistPath = appPath + "/Info.plist"
        let plistXML = FileManager.default.contents(atPath: plistPath)!
        do {
            //read plist file to dictionary
            var plistDict = try PropertyListSerialization.propertyList(from: plistXML, options: .mutableContainersAndLeaves, format: nil) as! [String: Any]
            
            if refreshVersion == nil,
                let shortVersion = plistDict["CFBundleShortVersionString"] as? String{
                
                var versionArray = shortVersion.components(separatedBy: ".")
                if versionArray.count > 0,
                    let lastComponent = versionArray.last {
                    if Int(lastComponent) == nil {
                        versionArray[versionArray.count-1] = "1";
                    } else {
                        versionArray[versionArray.count-1] = String(Int(lastComponent)! + 1)
                    }
                    
                    refreshVersion = versionArray.joined(separator: ".")
                }
            }
            
            if refreshVersion == nil {
                refreshVersion = "1.0.0"
            }
            
            plistDict["CFBundleShortVersionString"] = refreshVersion!
            plistDict["CFBundleVersion"] = refreshVersion!
            
            if bundleIdentifier != nil {
                plistDict["CFBundleIdentifier"] = bundleIdentifier!
            }
            
            if let plistOutputStream = OutputStream.init(toFileAtPath: plistPath, append: false) {
                
                //should keep the outputstream open
                plistOutputStream.schedule(in: RunLoop.current, forMode: .default)
                plistOutputStream.open()
                
                //write the new plist content to file
                PropertyListSerialization.writePropertyList(plistDict, to: plistOutputStream, format: PropertyListSerialization.PropertyListFormat.xml, options: 0, error: nil)
            }
        } catch {
            print(error)
        }
    }
    
    /// replace provision and resign
    ///
    /// - Parameters:
    ///   - appPath: the appPath can be framework, extension, appex, etc
    ///   - provisionPath: mobileprovision
    ///   - plistFilePath: plist file
    class func replaceProvisionAndResign(_ appPath: String, _ provisionPath: String?, _ plistFilePath: String) {
        var TeamName: String?
        if provisionPath != nil {
            let mobileprovisionData = runCommand(launchPath: "/usr/bin/security", arguments: ["cms", "-D", "-i", provisionPath!])
            
            do {
                let datasourceDictionary = try PropertyListSerialization.propertyList(from: mobileprovisionData, options: [], format: nil)
                
                if let dict = datasourceDictionary as? Dictionary<String, Any> {
                    TeamName = dict["TeamName"] as? String
                }
                
                //replace embedded.mobileprovision
                runCommand(launchPath: "/bin/cp", arguments: [provisionPath!, appPath + "/embedded.mobileprovision"])
            } catch {
                print(error)
            }
            
        } else {
            do {
                //if appPath + "/embedded.mobileprovision" doesnot exist, read team name from the app
                let mobileprovisionData = runCommand(launchPath: "/usr/bin/security", arguments: ["cms", "-D", "-i", appPath + "/embedded.mobileprovision"])
                
                let datasourceDictionary = try PropertyListSerialization.propertyList(from: mobileprovisionData, options: [], format: nil)
                
                if let dict = datasourceDictionary as? Dictionary<String, Any> {
                    TeamName = dict["TeamName"] as? String
                }
            } catch {
                print(error)
            }
        }
        
        //Remove old CodeSignature, can be ignored
        runCommand(launchPath: "/bin/rm", arguments: ["-rf", appPath + "_CodeSignature"])
        
        //resign extension/framework/app etc.
        let teamNameCombinedStr = "iPhone Distribution: " + TeamName!
        runCommand(launchPath: "/usr/bin/codesign", arguments: ["-fs", teamNameCombinedStr, "--entitlements", plistFilePath, appPath])
    }
    
    class func resignDylibs(_ componentFile: String?, _ provisionPath: String?, _ plistFilePath: String) {
        var TeamName: String?
        do {
            //if appPath + "/embedded.mobileprovision" doesnot exist, read team name from the app
            let mobileprovisionData = runCommand(launchPath: "/usr/bin/security", arguments: ["cms", "-D", "-i", provisionPath!])
            
            let datasourceDictionary = try PropertyListSerialization.propertyList(from: mobileprovisionData, options: [], format: nil)
            
            if let dict = datasourceDictionary as? Dictionary<String, Any> {
                TeamName = dict["TeamName"] as? String
            }
        } catch {
            print(error)
        }
        //resign extension/framework/app etc.
        let teamNameCombinedStr = "iPhone Distribution: " + TeamName!
        runCommand(launchPath: "/usr/bin/codesign", arguments: ["-fs", teamNameCombinedStr, "--entitlements", plistFilePath, componentFile!])
    }
    
    /// repack app
    ///
    /// - Parameter tempIpaPath: ipa path
    class func repackApp(_ tempIpaPath: String?) {
        
        let ipaName = URL.init(fileURLWithPath: tempIpaPath!).lastPathComponent
        
        let manager = FileManager.default
        do {
            try manager.createDirectory(atPath: manager.currentDirectoryPath + "/new App/", withIntermediateDirectories: true, attributes: [:])
            runCommand(launchPath: "/usr/bin/zip", arguments: ["-r", manager.currentDirectoryPath + "/new App/" + ipaName , "Payload/", "AppThinning.plist"])
        } catch {
            print(error)
        }
    }
    
    class func findComponentsList(_ tempIpaPath: String) -> Array<Any>? {
        
        let manager = FileManager.default
        let path = tempIpaPath + "/Frameworks"
        
        do {
            let content = try manager.enumerator(atPath: path)
            
            print(content as Any)
            
            return content?.allObjects
        } catch {
            print(error)
        }
    }
}
