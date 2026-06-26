//
//  PacketTunnelProvider.swift
//  BeetleVPN
//
//  Created by rickey on 6/4/26.
//

import Foundation
import NetworkExtension
import Macdss

class PacketTunnelProvider: NEPacketTunnelProvider {

    private var vpnDelegate: VPNDelegate?

    private let tunnelIP = "10.8.0.2"
    private let tunnelRemoteIP = "10.8.0.1"

    override func startTunnel(
        options: [String : NSObject]?,
        completionHandler: @escaping (Error?) -> Void
    ) {

        NSLog("VPN Start...")
        
        guard let opt = options else{
            print("option is nil")
            return
        }
        
        guard let stationId = opt["station_id"] as? Int64 else{
            print("station_id is not set")
            return
        }
        
        guard let baseDir = opt["db_path"] as? String else{
            print("db_path is not set")
            return
        }
        

        let settings =
            NEPacketTunnelNetworkSettings(
                tunnelRemoteAddress: tunnelRemoteIP
            )

        let ipv4 =
            NEIPv4Settings(
                addresses: [tunnelIP],
                subnetMasks: ["255.255.255.255"]
            )

        ipv4.includedRoutes = [
            NEIPv4Route.default()
//            NEIPv4Route(destinationAddress: "0.0.0.0", subnetMask: "128.0.0.0"),
//            NEIPv4Route(destinationAddress: "128.0.0.0", subnetMask: "128.0.0.0")
        ]
        
//        var excludedRoutes: [NEIPv4Route] = []

        // 1. 排除 TUN 自身地址
//        excludedRoutes.append(NEIPv4Route(
//            destinationAddress: tunnelIP,          // 10.8.0.2
//            subnetMask: "255.255.255.255"
//        ))

        // 2. 排除 loopback（最重要）
//        excludedRoutes.append(NEIPv4Route(
//            destinationAddress: "127.0.0.1",
//            subnetMask: "255.0.0.0"                // 127.0.0.0/8 整个 loopback 网段
//        ))
//        
//        excludedRoutes.append(NEIPv4Route(
//                destinationAddress: "10.8.0.2",
//                subnetMask: "255.255.255.255"
//            ))
//
//        ipv4.excludedRoutes = excludedRoutes

        settings.ipv4Settings = ipv4
        

        let dns = NEDNSSettings(
            servers: [
                "8.8.8.8"
            ]
        )

        settings.dnsSettings = dns

        setTunnelNetworkSettings(settings) { [weak self] error in

            guard let self = self else {
                completionHandler(error)
                return
            }

            if let error = error {
                completionHandler(error)
                return
            }

            let ok = self.startGoCore(stationId:stationId,baseDir: baseDir)
            if !ok{
                print("start go core failed")
                completionHandler(nil)
                return
            }

            self.readPackets()

            completionHandler(nil)
        }
    }

    override func stopTunnel(
        with reason: NEProviderStopReason,
        completionHandler: @escaping () -> Void
    ) {

        NSLog("VPN Stop")

        DrawinBeetleLibStopVpn()

        completionHandler()
    }

    private func startGoCore(stationId:Int64, baseDir:String) -> Bool{

        vpnDelegate = VPNDelegate(provider: self)
        
        var err:NSError?
        
        let bypassList = loadBypass(filename:"bypass")
        if bypassList.count == 0{
            print("load bypass failed")
            return false
        }
        
        print("bypass count \(bypassList.count)")
        
        let ok = DrawinBeetleLibStartVpn(
            tunnelIP,
            bypassList,
            baseDir,
            stationId,
            vpnDelegate,
            &err
        )

        if ok {
            NSLog("Go VPN Started")
            return true
        } else {
            NSLog(
                "StartVpn failed: \(err?.localizedDescription ?? "unknown")"
            )

            if let error = err {
                cancelTunnelWithError(error)
            }
            return false
        }
    }

    private func readPackets() {
        packetFlow.readPackets {
            [weak self]
            packets,
            protocols in

            guard let self = self else {
                return
            }

            for packet in packets {

                var err: NSError?

                let ok = DrawinBeetleLibInputPacket(
                    packet,
                    &err
                )

                if !ok {

                    let msg =
                        err?.localizedDescription
                        ?? "unknown"

                    NSLog(
                        "InputPacket failed: \(msg)"
                    )

                    if msg.contains("Tun2Proxy has stopped") {

                        self.cancelTunnelWithError(
                            err
                            ?? NSError(
                                domain: "VPN",
                                code: -1
                            )
                        )

                        return
                    }
                }
            }

            self.readPackets()
        }
    }
    private func loadBypass(filename:String, ext:String="txt") -> String{
        guard let url = Bundle.main.url(forResource: filename, withExtension: ext) else{
            print("can't find bypass file")
            return ""
        }
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            return content
        } catch {
            print("read file failed: \(error)")
            return ""
        }
    }
}
