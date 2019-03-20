//
//  InteractiveProcess.swift
//  iTTYbiTTY
//
//  Created by Raphael Reyna on 3/18/19.
//  Copyright © 2019 Raphael Reyna. All rights reserved.
//

import Foundation
import Darwin

class InteractiveProcess {
    
    var process = Process()
    var masterFile: FileHandle
    var running = false
    
    required init(executable: URL,
                  withArgs args: [String]?) {
        let masterFD = posix_openpt(O_RDWR)
        grantpt(masterFD)
        unlockpt(masterFD)
        self.masterFile = FileHandle.init(fileDescriptor: masterFD)
        let slavePath = String.init(cString: ptsname(masterFD))
        let slaveFile = FileHandle.init(forUpdatingAtPath: slavePath)
        self.process.standardOutput = slaveFile
        self.process.standardInput = slaveFile
        self.process.standardError = slaveFile
        self.process.executableURL = executable
        if args != nil {
            self.process.arguments = args
        }

    }
    
    func start() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                return
            }
            do {
                try self.process.run()
            } catch {
                print("Something went wrong.\n")
            }
        }
        self.running = true
    }
    
    func read() -> String? {
        if self.running {
            let data = self.masterFile.availableData
            let string = String(data: data, encoding: String.Encoding.utf8)
            return string!
        }
        return nil
    }
    
    func write(_ string: String) {
        if self.running {
            let modifiedString = string+"\u{0D}"
            let echoLength = modifiedString.cString(using: String.Encoding.utf8)?.count
            let data = modifiedString.data(using: String.Encoding.utf8)
            self.masterFile.write(data!)
            _ = self.masterFile.readData(ofLength: echoLength!)
            sleep(1)
            self.masterFile.readInBackgroundAndNotify()
        }
    }
    
    deinit {
        self.process.terminate()
        let slave = self.process.standardInput as! FileHandle
        slave.closeFile()
    }
}
