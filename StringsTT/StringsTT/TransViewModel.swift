//
//  TransViewModel.swift
//  StringsTT
//
//  Created by EvenLin on 2022/4/1.
//

import Cocoa

typealias Progress = (_ progress: Int, _ all: Int) -> Void

typealias Complete = () -> Void

class TransViewModel: NSObject {
    
    var file = StringFile()
    var tFile = StringFile()
    
    var ttKeys: [String] = []
    
    var language: String = "cht"
    
    private var progressAction: Progress?
    private var completeAction: Complete?
    
    func parseFiles(filePath: String, tFilePath: String) {
        
        file = StringFile()
        file.path = filePath
        tFile = StringFile()
        tFile.path = tFilePath
        
        guard file.dic.count > 0 else {
            print("待翻译的Strings文件没有任何内容， 请检查")
            return
        }
        
        ttKeys = file.keys.filter{tFile.keys.contains($0) == false}
    }
    
    func fileStatusDesc() -> String {
        return "检测到 \(self.file.keys.count) 条数据, 已翻译 \(self.tFile.keys.count), 待翻译 \(self.ttKeys.count), to\(language)"
    }
    
    func startTranslate(progress: Progress?, complete: Complete?) {
        self.progressAction = progress
        self.completeAction = complete
        guard self.ttKeys.count > 0 else {
            complete?()
            return
        }
        self.translateAction()
    }
    
    private func translateAction() {
        let sema = DispatchSemaphore(value: 20)
        let group = DispatchGroup()
        for i in 0..<ttKeys.count {
            DispatchQueue.global().async {
                sema.wait()
                group.enter()
                let key = self.ttKeys[i]
                let content = self.file.dic[key]!
                print("进行到[\(i)]， 正在翻译\(content)")
                Translator.translate(content: content, language: self.language) { result in
                    defer {
                        sema.signal()
                        group.leave()
                    }
                    if let result = result {
                        //去除引号， 防止错误
                        self.tFile.dic[key] = result.replacingOccurrences(of: "\"", with: "")
                    } else {
                        self.tFile.dic[key] = "⚠️⚠️⚠️ Translate Failed ⚠️⚠️⚠️"
                    }
                    let translatedCount = self.tFile.dic.count - self.tFile.keys.count
                    self.progressAction?(translatedCount, self.ttKeys.count)
                }
            }
        }
        group.notify(queue: .main) {
            self.tFile.save()
            self.completeAction?()
        }
    }
    
    func saveTranslatedFile() {
        tFile.save()
    }
    
    func successDescription() -> String {
        guard ttKeys.count > 0 else {
            return "无需翻译"
        }
        var desc = "翻译完成 🎉🎉🎉\n总共翻译 \(ttKeys.count) 条"
        desc += "\n文件已保存到\n\(tFile.path ?? "桌面")"
        return desc
    }
}
