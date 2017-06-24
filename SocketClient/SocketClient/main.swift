//
//  main.swift
//  SocketClient
//
//  Created by Mars on 23/06/2017.
//  Copyright © 2017 Mars. All rights reserved.
//

import Foundation

do {
    let socket = try Socket(
        socketFilePath: "/tmp/swift_sock_demo",
        type: .active)
    
    try socket.connect {
        var buffer: [CChar] = Array<CChar>(repeating: 0, count: 256)
        var numRead = read(STDIN_FILENO, &buffer, 256)
        
        while numRead > 0 {
            if write($0, &buffer, numRead) != numRead {
                fatalError("Partial write")
            }
            
            numRead = read(STDIN_FILENO, &buffer, 256)
        }
        
        if numRead == -1 {
            fatalError("Cannot read from stdin")
        }
        
        exit(EXIT_SUCCESS)
    }
}
catch {
    print(error.localizedDescription)
    exit(EXIT_FAILURE)
}


