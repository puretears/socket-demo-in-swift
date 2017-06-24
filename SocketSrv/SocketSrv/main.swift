//
//  main.swift
//  SocketSrv
//
//  Created by Mars on 23/06/2017.
//  Copyright © 2017 Mars. All rights reserved.
//

import Foundation

do {
    let socket = try Socket(socketFilePath: "/tmp/swift_sock_demo")
    try socket.bind()
    try socket.listen(backlog: 10)
    try socket.accept {
        var buffer: [CChar] = Array<CChar>(repeating: 0, count: 256)
        var numRead = read($0, &buffer, 256)
        
        while numRead > 0 {
            if write(STDOUT_FILENO, &buffer, numRead) != numRead {
                fatalError("Partial write...")
            }
            
            numRead = read($0, &buffer, 256)
        }
        
        if numRead == -1 {
            fatalError("Read file failed")
        }
        
        if close($0) == -1 {
            debugPrint("Cannot close the connection socket file")
        }
    }
}
catch {
    print(error.localizedDescription)
    exit(EXIT_FAILURE)
}



