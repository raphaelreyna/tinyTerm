//
//  AppDelegate.swift
//  tinyTerm
//
//  Created by Raphael Reyna on 3/18/19.
//  Copyright © 2019 Raphael Reyna. All rights reserved.
//

import Cocoa
import HotKey
import Darwin

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {
    
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    var shell: InteractiveProcess?
    var showingWindow: Bool?
    var popover: NSPopover?
    var textView: NSTextView?
    
    @IBOutlet weak var panel: NSPanel!
    @IBOutlet weak var textField: NSTextField!
    
    private var hotKey: HotKey? {
        didSet {
            guard let hotKey = hotKey else {
                return
            }
            hotKey.keyDownHandler = { [weak self] in
                if self!.showingWindow! {
                    self!.panel.orderOut(self)
                    self?.showingWindow = false
                } else {
                    self!.panel.makeKeyAndOrderFront(nil)
                    self?.showingWindow = true
                }
            }
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("StatusBarButtonImage"))
            button.action = #selector(togglePopover(_:))
        }
        self.shell = InteractiveProcess(executable: URL(fileURLWithPath: "/bin/bash"), withArgs: ["-i"])
        hotKey = HotKey(keyCombo: KeyCombo(key: .r, modifiers: [.command, .option]))
        self.shell!.start()
        NSUserNotificationCenter.default.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(handleOutput(_:)), name: FileHandle.readCompletionNotification, object: self.shell!.masterFile)
        self.showingWindow = false
        self.textField.isBezeled = false
        var objects: NSArray?
        Bundle.main.loadNibNamed("PopOverViewController", owner: self, topLevelObjects: &objects)
        for object in objects! {
            if let obj = object as? NSPopover {
                self.popover = obj
            }
        }
        self.textView = self.popover?.contentViewController?.view.subviews.first?.subviews.first as? NSTextView
        self.textView?.string = self.shell!.read()!
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        self.hotKey = nil
        self.shell = nil
    }
    
    func notify(msg: String, responsePlaceHolder: String?) {
        let notification = NSUserNotification()
        notification.identifier = msg
        notification.title = "iTTybiTTy"
        notification.subtitle = "Bash Session"
        notification.informativeText = msg
        notification.soundName = NSUserNotificationDefaultSoundName
        if responsePlaceHolder != nil {
            notification.hasReplyButton = true
            notification.responsePlaceholder = responsePlaceHolder
        }
        let notificationCenter = NSUserNotificationCenter.default
        notificationCenter.deliver(notification)
    }
    
    @objc func handleOutput(_ notification: Notification){
        let data = notification.userInfo![NSFileHandleNotificationDataItem] as! Data
        let outputString = String(data: data, encoding: String.Encoding.utf8)!
        let newString = outputString+"\n"+self.textView!.string
        self.textView!.string = newString
    }
    
    @objc func togglePopover(_ sender: Any?) {
        if popover!.isShown {
            closePopover(sender: sender)
        } else {
            showPopover(sender: sender)
        }
    }
    
    func showPopover(sender: Any?) {
        if let button = statusItem.button {
            popover!.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }
    
    func closePopover(sender: Any?) {
        popover!.performClose(sender)
    }
    
    @IBAction func handleInput(_ sender: Any) {
        let input = self.textField.stringValue
        self.panel.orderOut(self)
        self.showingWindow = false
        self.shell!.write(input)
    }
}

