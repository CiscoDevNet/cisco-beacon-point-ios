//
//  OrgsManager.swift
//  Mist
//
//  Created by Cuong Ta on 12/1/15.
//  Copyright © 2015 Mist. All rights reserved.
//

import UIKit
import MistSDK

@objc
open class OrgsManager: NSObject, URLSessionDelegate {
    
    static let envs: [String] = ["S","P","D"];
    
    static let configPath = "/Configs"
    
    static let defaultManager = OrgsManager()
    
    open func importOrgsIfNeeded(){
        if let imported = UserDefaults.standard.object(forKey: "imported-plist") as? Bool {
            if imported {
                print("Already imported")
                return;
            }
        }
        let plistPaths:[String] = Bundle.main.paths(forResourcesOfType: "plist", inDirectory: "")
        for plistPath in plistPaths {
            if let filename = plistPath.components(separatedBy: "/").last {
                if filename != "Info.plist" {
                    if let regex = try? NSRegularExpression(pattern: "(((Production|Staging).+)\\.plist)", options: []) {
                        let matches:[NSTextCheckingResult] = regex.matches(in: filename, options: [], range: NSMakeRange(0,filename.characters.count))
                        for match in matches {
                            var filename = (filename as NSString).substring(with: match.rangeAt(2))
                            let env = (filename as NSString).substring(with: match.rangeAt(3))
                            let envType = env.substring(with: (env.startIndex ..< env.characters.index(env.startIndex, offsetBy: 1)))
                            if let plistJSON = NSDictionary(contentsOfFile: plistPath){
                                let apiJSON:[String:String] = [
                                    "name":"",
                                    "envType":envType,
                                    "origin":"from-plist",
                                    "org_id":(plistJSON["VenueID"] as? String)!,
                                    "secret":(plistJSON["VenuePassword"] as? String)!]
                                filename = filename + ".json"
                                if self.saveOrg(envType, filename: filename, json: apiJSON) {
                                    print("!failed to save")
                                } else {
                                    print("failed to save")
                                }
                            }
                        }
                    }
                }
            }
        }
        UserDefaults.standard.set(true, forKey: "imported-plist")
        UserDefaults.standard.synchronize()
    }
    
    // add org secret with text only
    open func addOrgSecrets(_ str: String, onComplete: @escaping (String,Bool)->()){
        let secrets:[String] = str.components(separatedBy: ",");
        for secret in secrets {
            if let envType:String = detectEnv(secret) {
                MSTOrgCredentialsManager.enrollDevice(withToken: secret, onComplete: { (response: [AnyHashable: Any]!, err: Error!) in
                    if let responseExist = response {
                        if responseExist is [String:String], var json = (responseExist as? [String:String]){
                            if let tempName = json["name"] {
                                var tokenName = tempName.replacingOccurrences(of: "/", with: "_")
                                tokenName = tokenName.replacingOccurrences(of: ":", with: "_")
                                let filename = tokenName
                                
                                // API doesn't return the host and topic. Hence adding it for the correct env
                                json["envType"] = envType
                                json["_tokenSecret"] = secret; // the original token verify secret. Use this to registrer.
                                
                                // TODO: change status to error/warning type
                                if self.saveOrg(envType, filename: filename, json: json) {
                                    let msg = "File saved."
                                    onComplete(msg, true)
                                } else {
                                    let msg = "Error in saving file."
                                    onComplete(msg, false)
                                }
                            }
                        }
                    } else {
                        let msg = "Cannot enroll due to bad/no response from API."
                        print(msg)
                        print(err.localizedDescription)
                        onComplete(msg, false)
                    }
                })
            }
        }
    }
    
    // add org secre using QR code image
    open func addOrgSecrets(_ str: String, image: UIImage, onComplete: @escaping (String,Bool)->()){
        let secrets:[String] = str.components(separatedBy: ",");
        for secret in secrets {
            if let envType:String = detectEnv(secret) {
                MSTOrgCredentialsManager.enrollDevice(withToken: secret, onComplete: { (response: [AnyHashable : Any]?, error: Error?) in
                    if error != nil {
                        let msg = "Cannot enroll due to bad/no response from API."
                        print(msg)
                        print(error?.localizedDescription ?? "")
                        onComplete(msg, false)
                    } else {
                        if let responseExist = response {
                            if responseExist is [String:String], var json = (responseExist as? [String:String]){
                                if let tempName = json["name"] {
                                    var tokenName = tempName.replacingOccurrences(of: "/", with: "_")
                                    tokenName = tokenName.replacingOccurrences(of: ":", with: "_")
                                    let filename = tokenName
                                    
                                    // API doesn't return the host and topic. Hence adding it for the correct env
                                    json["envType"] = envType
                                    json["_tokenSecret"] = secret; // the original token verify secret. Use this to registrer.
                                    
                                    // TODO: change status to error/warning type
                                    if self.saveOrg(envType, filename: filename, json: json) {
                                        let msg = "Saved"
                                        onComplete(msg, true)
                                    } else {
                                        let msg = "Cannot save"
                                        onComplete(msg, false)
                                    }
                                    
                                    if self.saveImage(envType, filename: filename, image: image) {
                                        let msg = "Saved"
                                        onComplete(msg, true)
                                    } else {
                                        let msg = "Cannot save"
                                        onComplete(msg, false)
                                    }
                                }
                            }
                        }
                    }
                })
            }
        }
    }
    
    // MARK: Deprecated using MistSDK to enroll link
    open func enrollDevice(_ hostname: String, secret: String, onComplete: @escaping (AnyObject?,NSError?)->()){
        if let url = URL(string: "https://"+hostname+"/api/v1/mobile/verify/"+secret) {
            var request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 30)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            let userID: [String:String] = ["device_id":Default.getUUIDString()]; //f824e6db-fd66-48c2-84e0-d4b3ffcd4451
            do {
                print("Attemping to enrollDevice \(userID)");
                request.httpBody = try JSONSerialization.data(withJSONObject: userID, options: [])
            } catch {
                print("Problem unmarshalling request body")
                let err = NSError(domain: "OrgsManager", code: -99, userInfo: [NSLocalizedDescriptionKey: "Problem unmarshalling request body"])
                onComplete(nil, err)
            }
            
            let session = URLSession(configuration: URLSessionConfiguration.ephemeral, delegate: self, delegateQueue: nil)
            session.dataTask(with: request, completionHandler: { (data: Data?, rep: URLResponse?, err:Error?) -> Void in
                do {
                    print("Request: \(request.description)")
                    
                    let json = try JSONSerialization.jsonObject(with: request.httpBody!, options: [])
                    print("RequestBody : \(json)")
                    
                    if (err != nil) {
                        print("Error enrolling the device \(err!.localizedDescription)")
                        onComplete(nil, err! as NSError);
                    } else {
                        print("Attemping to unmarshall the response data")
                        if let dataExists = data {
                            let json = try JSONSerialization.jsonObject(with: dataExists, options: [])
                            print("Received JSON: \(json)")
                            onComplete(json as AnyObject, nil)
                        }
                    }
                } catch {
                    print("Problem unmarshalling request body")
                    onComplete(nil, nil)
                }
            }).resume()
            print("enrollDevice \(url.absoluteString)")
        }
    }
    
    open func getOrgs() -> [String:[String]]? {
        let docPath:String = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        let configsPath = docPath + "/Configs";
        
        let fm = FileManager.default
        var envOrgsMapping = [String:[String]]()
        
        for envType:String in OrgsManager.envs {
            let envDir = configsPath + ("/"+envType);
            if fm.fileExists(atPath: envDir) {
                print("getOrg envDir exists?",envDir,"yes")
                if (envOrgsMapping[envType] == nil) {
                    envOrgsMapping[envType] = [String]()
                }
                if let contents = try? FileManager.default.contentsOfDirectory(atPath: envDir) {
                    for org:String in contents {
                        envOrgsMapping[envType]?.append(org)
                    }
                }
            } else {
                print("getOrg envDir exists?",envDir,"no")
            }
        }
        return envOrgsMapping
    }
    
    fileprivate func createDirIfNotExists(_ pathString: String, subPath: String){
        let dirPath = pathString + subPath
        
        // Check to see if the Configs directory exists, if not create them
        if !FileManager.default.fileExists(atPath: dirPath) {
            do {
                try FileManager.default.createDirectory(atPath: dirPath, withIntermediateDirectories: true, attributes: nil)
                for envType:String in OrgsManager.envs {
                    try FileManager.default.createDirectory(atPath: dirPath + ("/"+envType), withIntermediateDirectories: true, attributes: nil)
                }
            } catch {
                print("Cannot create config directory at ", dirPath)
            }
        }
    }
    
    open func saveOrg(_ envType: String, filename: String, json: [String:String]) -> Bool {
        let docPath:String = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        self.createDirIfNotExists(docPath, subPath: "/Configs")
        let writePath = docPath + ("/Configs/" + envType + "/" + filename + ".json");
        let fm = FileManager.default
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            fm.createFile(atPath: writePath, contents: data, attributes: nil)
            if fm.fileExists(atPath: writePath) {
                return true
            } else {
                return false
            }
        } catch {
            return false
        }
    }
    
    open func readOrg(_ envType:String, filename: String) -> [String:String]? {
        let docPath:String = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        let path = docPath + ("/Configs/" + envType + "/" + filename + ".json");
        
        let fh = FileHandle(forReadingAtPath: path)
        if let data = fh?.readDataToEndOfFile() {
            print("open file",data)
            fh?.closeFile()
            do {
                let org = try JSONSerialization.jsonObject(with: data, options: [])
                if let json = org as? [String:String] {
                    return json
                } else {
                    return nil
                }
            } catch {
                return nil
            }
        } else {
            return nil
        }
    }
    
    open func saveImage(_ envType: String, filename: String, image: UIImage) -> Bool {
        let docPath:String = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        self.createDirIfNotExists(docPath, subPath: "/QRCodeImages")
        let writePath = docPath + ("/QRCodeImages/" + envType + "/" + filename + ".png");
        let fm = FileManager.default
        
        try? UIImagePNGRepresentation(image)?.write(to: URL(fileURLWithPath: writePath), options: [.atomic])
        if fm.fileExists(atPath: writePath) {
            return true
        } else {
            return false
        }
    }
    
    open func readImage(envType: String, filename: String) -> UIImage? {
        let docPath:String = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        let writePath = docPath + ("/QRCodeImages/" + envType + "/" + filename + ".png");
        return UIImage(contentsOfFile: writePath)
    }
    
    static open func deleteAllOrgs() -> Bool {
        let docPath:String = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        let configPath = docPath + "/Configs"
        let fm = FileManager.default
        if fm.fileExists(atPath: configPath) {
            do {
                try fm.removeItem(atPath: configPath)
                if !fm.fileExists(atPath: configPath) {
                    print("\(configPath) is deleted successfully")
                    return true
                } else {
                    print("\(configPath) is deleted unsuccessfully")
                    return false
                }
            } catch {
                print("\(configPath) cannot be deleted")
                return false
            }
        } else {
            print("\(configPath) does not exist")
            return false;
        }
    }
    
    open func deleteOrg(_ envType:String, filename: String) -> Bool {
        let docPath:String = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        let path = docPath + ("/Configs/" + envType + "/" + filename + ".json");
        
        let fm = FileManager.default
        if fm.fileExists(atPath: path) {
            do {
                try fm.removeItem(atPath: path)
                if !fm.fileExists(atPath: path) {
                    print("\(path) is deleted successfully")
                    return true
                } else {
                    print("\(path) is deleted unsuccessfully")
                    return false
                }
            } catch {
                print("\(path) cannot be deleted")
                return false
            }
        } else {
            print("\(path) does not exist")
            return false
        }
    }
    
    static open func debugConfigs(){
        let docPath:String = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        let configPath = docPath + "/Configs"
        
        let fm = FileManager.default
        if fm.fileExists(atPath: configPath) {
            for envType:String in OrgsManager.envs {
                let envPath = configPath + ("/"+envType)
                if let contents = try? fm.contentsOfDirectory(atPath: envPath) {
                    print("contents for \(envType)",contents)
                }
            }
        }
    }
    
    func extractSecret(_ url: URL) -> String {
        let urlStr = url.absoluteString
        var secret = ""
        do {
            let regex = try NSRegularExpression(pattern: "^mist:\\/\\/activate\\/(.+)", options: [])
            let matches = regex.matches(in: urlStr, options: [], range: NSMakeRange(0, urlStr.characters.count))
            if matches.count > 0 {
                let range = urlStr.index(after: urlStr.startIndex)..<urlStr.endIndex
                let substring = urlStr.substring(with: range)
                secret = substring
            }
        } catch {
            print("rege ix bad")
        }
        //        print("what",secret.substringWithRange(Range<String.Index>(start: secret.startIndex, end: secret.startIndex.advancedBy(1))))
        //        print("tempMatches",tempMatches)
        return secret
    }
    
    func detectEnv(_ secret: String) -> String? {
        let env = secret.substring(with: (secret.startIndex ..< secret.characters.index(secret.startIndex, offsetBy: 1)))
        if (OrgsManager.envs.index(of: env) != nil) {
            return env
        }
        return nil
    }
}
