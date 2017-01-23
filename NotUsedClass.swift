#!/usr/bin/env xcrun swift
import Foundation

// 该脚本用来检测iOS项目中是否有存在未被使用类文件

// Swift3.0用CommandLine获取用户输入命令
// argc是参数个数

// 遍历所有文件
func enumAllFiles(filePath: String, fileManager: FileManager, handle: (_ element: String) -> Void) {
    let enumerator: FileManager.DirectoryEnumerator = fileManager.enumerator(atPath: filePath)!
    
    while let element = enumerator.nextObject() as? String {
        let absoluteFilePath = filePath + "/" + element
        
        guard fileManager.isReadableFile(atPath: absoluteFilePath) else {
            continue
        }
        handle(element);
    }
}

// 将注释代码替换成""
func replaceComment(content: String, template:String) -> String {
    var pattern = "//.*"
    var regular = try! NSRegularExpression(pattern: pattern, options:.caseInsensitive)
    let mutableStr = NSMutableString.init(string: content)
    regular.replaceMatches(in: mutableStr, options: .reportCompletion, range: NSMakeRange(0, content.characters.count), withTemplate: "")
    
    pattern = "/\\*[\\s\\S]*\\*/"
    regular = try! NSRegularExpression(pattern: pattern, options:.caseInsensitive)
    regular.replaceMatches(in: mutableStr, options: .reportCompletion, range: NSMakeRange(0, mutableStr.length), withTemplate: "")
    
    return mutableStr.description;
}

func isUsedFile(fileName: String, fileContent: String) -> Bool {
//    let pattern = "#import \"" + fileName + "\""
    let pattern = fileName
    return fileContent.contains(pattern)
}

guard CommandLine.argc == 2 else {
    print("Argument cout error: it need a file path for argument!")
    exit(0)
}


// arguments是参数
let argv = CommandLine.arguments
let filePath = argv[1]

let fileManager = FileManager.default

var isDirectory: ObjCBool = ObjCBool(false)
guard fileManager.fileExists(atPath: filePath, isDirectory: &isDirectory) else {
    print("The '\(filePath)' file path is not exit!")
    exit(0)
}

guard isDirectory.boolValue == true else {
    print("The '\(filePath)' is not a directory!")
    exit(0)
}

guard fileManager.isReadableFile(atPath: filePath) else {
    print("The '\(filePath)' file path is not readable!")
    exit(0)
}


var filePaths: Set<String> = Set<String>()
var fileNames: Set<String> = Set<String>()

// 遍历所有文
enumAllFiles(filePath: filePath, fileManager: fileManager) { (absoluteFilePath) in
    // Pods文件夹里面的图片先忽略
    if absoluteFilePath.contains("/Pods/") {
        return
    }
    
    if absoluteFilePath.contains("/watchkitapp/") {
        return
    }
    
    if absoluteFilePath.contains("/watchkitapp Extension/") {
        return
    }
    
    
    if absoluteFilePath.hasSuffix(".h") {
        filePaths.insert(absoluteFilePath)
        if let fileName = absoluteFilePath.components(separatedBy: "/").last {
            guard let originFileName = fileName.components(separatedBy: ".").first else {
                return
            }
            fileNames.insert(originFileName);
        }
        
        
    }
}

var usedFileList: Set<String> = Set<String>()
enumAllFiles(filePath: filePath, fileManager: fileManager) { (absoluteFilePath) in
    // Pods文件夹里面的文件先忽略
    if absoluteFilePath.contains("/Pods/") {
        return
    }
    
    if absoluteFilePath.contains("/watchkitapp/") {
        return
    }
    
    if absoluteFilePath.contains("/watchkitapp Extension/") {
        return
    }
    
    if absoluteFilePath.contains("/FlyingShark/") {
        return
    }
    
    if absoluteFilePath.contains("/Autobuild/") {
        return
    }
    
    if absoluteFilePath.hasSuffix(".m") || absoluteFilePath.hasSuffix(".h") || absoluteFilePath.hasSuffix(".pch") || absoluteFilePath.hasSuffix(".xib") || absoluteFilePath.hasSuffix(".storyboard") {
        
        let originFileNameWithSuffix = absoluteFilePath.components(separatedBy: "/").last
        guard let originFileName = originFileNameWithSuffix?.components(separatedBy: ".").first else {
            return
        }
        
        let url = URL(fileURLWithPath: filePath + "/" + absoluteFilePath)
        var fileContent = try! String(contentsOf: url, encoding: .utf8)
        fileContent = replaceComment(content: fileContent, template: "")
        
        for fileName in fileNames {
            if fileName == originFileName {
                continue
            }
            
            
            if isUsedFile(fileName: fileName, fileContent: fileContent) {
                usedFileList.insert(fileName)
            }
        }
        for file in usedFileList {
            if let i = fileNames.index(of: file) {
                fileNames.remove(at: i)
            }
        }
    }
}


// 打印未使用到的jpg
for file in fileNames {
    print(file + ".h")
}

