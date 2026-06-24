//
//  VpnDelegate.swift
//  BeetleVPN
//
//  Created by rickey on 6/4/26.
//

import Foundation
import NetworkExtension
import Macdss

class VPNDelegate: NSObject, DrawinBeetleLibVpnDelegateProtocol {
    weak var provider: PacketTunnelProvider?

    init(provider: PacketTunnelProvider) {
        self.provider = provider
        super.init()
    }

   func bypass(_ fd: Int32) -> Bool {
        NSLog("VPN bypass fd=\(fd)")
        return true
    }

    func vpnClosed() {
        NSLog("VPN closed by Go")

        provider?.cancelTunnelWithError(
            NSError(
                domain: "BeetleVPN",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "VPN closed by core"
                ]
            )
        )
    }

    func write(_ p0: Data?, n: UnsafeMutablePointer<Int>?) throws {
        
        guard let packet = p0 else {
            // 如果 Go 传入了空数据，或者你想表示写入失败，可以直接抛出异常
            // 如果只是想正常返回，可以直接 return
            return
        }
        print("packet count \(packet.count)")
        if packet.count > 0 {
            let version = packet[0] >> 4
            let proto: NSNumber

            if version == 6 {
                proto = NSNumber(value: AF_INET6)
            } else {
                proto = NSNumber(value: AF_INET)
            }

            provider?.packetFlow.writePackets(
                [packet],
                withProtocols: [proto]
            )
        }

        // 设置成功写入的字节数（让 Go 知道写入了多少数据）
        n?.pointee = packet.count
        
        // 正常结束表示成功。如果出错了，可以用 throw NSError(...) 抛出错误
    }
}

