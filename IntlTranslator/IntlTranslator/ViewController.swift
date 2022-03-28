//
//  ViewController.swift
//  IntlTranslator
//
//  Created by EvenLin on 2022/3/28.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var pathField: NSTextField!
    
    @IBOutlet weak var label: NSTextField!
    
    @IBOutlet weak var language: NSComboBox!
    
    @IBOutlet weak var indicator: NSProgressIndicator!
    
    @IBOutlet weak var transBtn: NSButton!
    
    var originalDic: [String: String] = [:]
    
    var translatedDic: [String: String] = [:]
    
    var transKeys: [String] = []
    var transProgress: Int = 0
    
    var errorArray: [String] = []
    
    var parser: StringsParser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func exportTranslatedFile() {
        guard let outputString = parser?.convertToString(dic: self.translatedDic) else {
            return
        }
        
        if let outPath = parser?.outputPath(language: language.stringValue) {
            do {
                try File(path: outPath).write(contents: outputString)
            } catch let error {
                print(error.localizedDescription)
            }
        } else {
            print("Error output path")
        }
        
    }
    
    @IBAction func didSelectLanguage(_ sender: NSComboBox) {
        print(sender.stringValue)
        self.label.stringValue = "等待翻译"
    }
    
    func reset() {
        self.parser = nil
        self.originalDic.removeAll()
        self.translatedDic.removeAll()
        errorArray.removeAll()
        transKeys.removeAll()
        transProgress = 0
        self.label.stringValue = "正在启动翻译..."
    }
    

    @IBAction func transBtnDidClick(_ sender: NSButton) {
        self.reset()
        
        self.parser = StringsParser(path: pathField.stringValue)
        if let originalDic = parser?.parseString() {
            self.originalDic = originalDic
        }
        guard originalDic.count > 0 else {
            return
        }
        self.indicator.startAnimation(nil)
        self.transKeys = (originalDic as NSDictionary).allKeys as! [String]
        translate()
        
//        for (key, value) in originalDic {
//            guard translatedDic[key] == nil else {
//                continue
//            }
////            print("\(key) = \(value)")
//
//            self.indicator.startAnimation(nil)
//            self.translate(key: key, content: value)
//
//        }
        
    }
    
    func translate() {
        let key = transKeys[transProgress]
        
        guard translatedDic[key] == nil else {
            transProgress += 1
            translate()
            return
        }
        self.translate(key: key, content: originalDic[key]!)
    }
    
    func translate(key: String, content: String) {
        Translator.translate(content: content, language: language.stringValue) { [unowned self] result in
            
            if let result = result {
                self.translatedDic[key] = result
            } else {
                self.translatedDic[key] = "⚠️⚠️⚠️ Translate Failed ⚠️⚠️⚠️"
                self.errorArray.append(key)
            }
            
            DispatchQueue.main.async {
                self.label.stringValue = "Translating \(self.transProgress)/\(self.originalDic.count)"
            }
            if self.translatedDic.count == self.originalDic.count {
                self.indicator.stopAnimation(nil)
                self.successAction()
                
//                if self.errorArray.count > 0 {
//                    DispatchQueue.main.async {
//                        self.label.stringValue = """
//翻译结束
//总共翻译 \(self.originalDic.count) 条
//翻译失败 \(self.errorArray.count) 条
//正在重试失败的翻译
//"""
//                    }
//                    self.retryFailedTranslations()
//                } else {
//                    self.successAction()
//                }
            } else {
                self.transProgress += 1
                self.translate()
            }
            
        }
    }
    
    func successAction() {
        DispatchQueue.main.async {
            self.label.stringValue = """
翻译结束 🎉🎉🎉
总共翻译 \(self.originalDic.count) 条
翻译失败 \(self.errorArray.count) 条
文件已导出到桌面
"""
        }
        self.exportTranslatedFile()
        print(self.originalDic.filter({self.errorArray.contains($0.key)}))
    }
    
    func retryFailedTranslations() {
        print("🌏🌏🌏 重试失败的翻译 🌏🌏🌏")
        var count = 0
        
        var secondErrorArray: [String] = []
        
        for key in errorArray {
            guard let value = originalDic[key] else { continue }
            self.indicator.startAnimation(nil)
            Translator.translate(content: value, language: language.stringValue) { [unowned self] result in
                count += 1
                if let result = result {
                    self.translatedDic[key] = result
                } else {
                    secondErrorArray.append(key)
                    self.translatedDic[key] = "⚠️⚠️⚠️ Translate Failed ⚠️⚠️⚠️"
                }
                DispatchQueue.main.async {
                    self.label.stringValue = "Retry Translating \(count)/\(self.errorArray.count)"
                }
                if count == self.errorArray.count {
                    self.errorArray = secondErrorArray
                    self.indicator.stopAnimation(nil)
                    self.successAction()
                    print("⚠️⚠️⚠️ 翻译错误的键值对 ⚠️⚠️⚠️")
                    print(self.originalDic.filter({self.errorArray.contains($0.key)}))
                }
            }
        }
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
}

