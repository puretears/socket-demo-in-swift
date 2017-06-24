//
//  Socket.swift
//  SocketSrv
//
//  Created by Mars on 23/06/2017.
//  Copyright © 2017 Mars. All rights reserved.
//

import Foundation


enum SocketException: Error {
    case cannotCreateSocketFile
    case socketPathTooLong
    case socketFileAlreadyExists
    case cannotBindSocketAddress
    case cannotListenOnTheSocketAddress
    case cannotAcceptConnection
    case cannotConnectToSocket
}

enum SocketType {
    case active
    case passive
}

class Socket {
    var socketFd: CInt = -1
    var sockAddrUn: sockaddr_un = sockaddr_un()
    
    func initSockAddr(filePath: String) throws {
        sockAddrUn.sun_family = (sa_family_t)(AF_UNIX)
        
        let pathLength = filePath.unicodeScalars.count
        let sockBuffLength = Mirror(reflecting: sockAddrUn.sun_path).children.count
        
        if (pathLength + 1) > sockBuffLength {
            throw SocketException.socketPathTooLong
        }
        
        memcpy(&sockAddrUn.sun_path, filePath, pathLength)
    }
    
    func bind() throws {
        let rawPointer = UnsafeMutableRawPointer(&sockAddrUn)
        let generalSockAddr = rawPointer.bindMemory(
            to: sockaddr.self,
            capacity: MemoryLayout<sockaddr>.size)
        
        #if os(Linux)
            let bindResult = Glibc.bind(socketFd, generalSockAddr,
                socklen_t(MemoryLayout<sockaddr_un>.size))
        #else
            let bindResult = Darwin.bind(socketFd, generalSockAddr,
                socklen_t(MemoryLayout<sockaddr_un>.size))
        #endif
        
        
        if bindResult == -1 {
            throw SocketException.cannotBindSocketAddress
        }
    }
    
    func listen(backlog: CInt) throws {
        #if os(Linux)
            let result = Glibc.listen(socketFd, backlog)
        #else
            let result = Darwin.listen(socketFd, backlog)
        #endif
        guard result != -1 else {
            throw SocketException.cannotListenOnTheSocketAddress
        }
    }
    
    func accept(action: (CInt) -> Void) throws {
        while true {
            #if os(Linux)
                let connFd = Glibc.accept(socketFd, nil, nil)
            #else
                let connFd = Darwin.accept(socketFd, nil, nil)
            #endif
            
            if connFd == -1 {
                throw SocketException.cannotAcceptConnection
            }
            
            action(connFd)
        }
    }
    
    func connect(action: (CInt) -> Void) throws {
        let rawPointer = UnsafeMutableRawPointer(&sockAddrUn)
        let generalSockAddr = rawPointer.bindMemory(
            to: sockaddr.self,
            capacity: MemoryLayout<sockaddr>.size)
        
        #if os(Linux)
            let isConnected = Glibc.connect(socketFd,
                generalSockAddr,
                socklen_t(MemoryLayout<sockaddr_un>.size))
        #else
            let isConnected = Darwin.connect(socketFd,
                generalSockAddr,
                socklen_t(MemoryLayout<sockaddr_un>.size))
        #endif
        
        if isConnected == -1 {
            throw SocketException.cannotConnectToSocket
        }
        
        action(socketFd)
    }
    
    init(socketFilePath: String, type: SocketType) throws {
        #if os(Linux)
            socketFd = Glibc.socket(AF_UNIX, SOCK_STREAM, 0)
        #else
            socketFd = Darwin.socket(AF_UNIX, SOCK_STREAM, 0)
        #endif
        
        if socketFd == -1 {
            throw SocketException.cannotCreateSocketFile
        }
        
        if (type == .passive) &&
            (remove(socketFilePath) == -1) &&
            (errno != ENOENT) {
            throw SocketException.socketFileAlreadyExists
        }
        
        try initSockAddr(filePath: socketFilePath)        
    }
}

