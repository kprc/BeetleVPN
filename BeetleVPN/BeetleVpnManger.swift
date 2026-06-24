//
//  BeetleVpnManger.swift
//  BeetleVPN
//
//  Created by rickey on 6/5/26.
//

import Foundation
import NetworkExtension
import Macdss
import Combine


struct LibAddress: Codable {
    let ethAddr: String
    let trxAddr: String
    let btlcAddr: String
    let usdtAddr: String
    

    
    enum CodingKeys: String, CodingKey {
        case ethAddr = "eth_addr"
        case trxAddr = "trx_addr"
        case btlcAddr = "btlc_addr"
        case usdtAddr = "usdt_addr"
    }
}


final class BeetleVPNManager:ObservableObject {
    static let shared = BeetleVPNManager()
    
    private var beetleAddress:LibAddress?
    private var isInitialized:Bool=false
    
    @Published var beetleID:String?
    @Published var connectionState:String = "Idle"
    
    private var tunnelManager: NETunnelProviderManager?
    
    init(){
        NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(vpnStatusChanged),
                    name: .NEVPNStatusDidChange,
                    object: nil
                )
    }
    deinit{
        NotificationCenter.default.removeObserver(self)
    }
    
    

    func initialize() {
        guard !isInitialized else {
            print("BeetleVPN 已经初始化")
            return
        }

        let dbpath = getSharedDirectory()
        
        var err:NSError?
        
        var ok = DrawinBeetleLibInitBeetle(dbpath.path, &err)
        if !ok{
            return
        }
        print("init beetle success")
        
        ok = DrawinBeetleLibIsWalletCreate()
        if !ok{
            print("wallet not created")
            self.isInitialized = true
            return
        }
        ok = DrawinBeetleLibOpenWallet("123", &err)
        if ok{
            print("open wallet success")
                
        }
        
        parseLibAddress()
        
        self.isInitialized = true
        
        beetleID = beetleAddress?.btlcAddr
        
        print("✅ BeetleVPN 初始化成功")
    }
    
    func isWalletOpened() ->Bool{
        return DrawinBeetleLibIsCommunicateWalletOpened()
    }

    func getSharedDirectory() -> URL {
        let fileManager = FileManager.default
        //ios
        //return fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
//        let dbDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
//                .appendingPathComponent(Bundle.main.bundleIdentifier ?? "io.utech.BeetleVPN")
//        try? FileManager.default.createDirectory(at: dbDir, withIntermediateDirectories: true)
//        return dbDir
        let shareContainer = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.7745PS7TY6.io.utech.BeetleVPN")
        let dbDir = shareContainer!.appendingPathComponent("Library/Application Support/BeetleVPN")
                try? fileManager.createDirectory(at: dbDir, withIntermediateDirectories: true)
                return dbDir
    }
    func hasContactInfo()->Bool{
        return DrawinBeetleLibIsWalletCreate()
    }
    func submitContact(email:String, telegram:String, password: String)->Bool{
        var err:NSError?
        let ok = DrawinBeetleLibUserReg(email,telegram,password,&err)
        if ok{
            parseLibAddress()
            beetleID = beetleAddress?.btlcAddr
            print("beetleID is \(beetleID!)")
        }
        return ok
    }
    
    func parseLibAddress() {
        let jsonString = DrawinBeetleLibTokenAddress()
        
        guard let data = jsonString.data(using: .utf8) else {
            print("token address convert to data failed")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let address = try decoder.decode(LibAddress.self, from: data)
            beetleAddress = address
            return
        } catch {
            print("unmarshall token address failed: \(error)")
            return
        }
    }
//    func getBeetleID() ->String?{
//        return beetleAddress?.btlcAddr
//    }
    func loadVPNManager(
        completion: @escaping (Error?) -> Void
    ) {

        NETunnelProviderManager.loadAllFromPreferences {

            managers,
            error in

            if let error = error {

                completion(error)
                return
            }

            if let existing = managers?.first {

                self.tunnelManager = existing

                completion(nil)

                return
            }

            let manager = NETunnelProviderManager()

            let proto = NETunnelProviderProtocol()

            proto.providerBundleIdentifier =
                "io.utech.BeetleVPN.PacketTunnel"

            proto.serverAddress =
                "Beetle VPN"

            manager.protocolConfiguration = proto

            manager.localizedDescription =
                "Beetle VPN"

            manager.isEnabled = true

            manager.saveToPreferences { error in

                if let error = error {

                    completion(error)
                    return
                }

                manager.loadFromPreferences { error in

                    self.tunnelManager = manager

                    completion(error)
                }
            }
        }
    }
    func startVPN(stationId:Int64,dbPath:String) {
        
        guard let manager = tunnelManager else {

            NSLog("VPN manager not loaded")

            return
        }

        do {

            let session =
                manager.connection
                as! NETunnelProviderSession
            
            let options: [String: NSObject] = [
                    "station_id": NSNumber(value: stationId),
                    "db_path":NSString(string:dbPath)
                ]

            try session.startTunnel(options: options)

            NSLog("VPN Start")

        } catch {

            NSLog("VPN Start Failed: \(error)")
        }
    }
    func stopVPN() {

        tunnelManager?
            .connection
            .stopVPNTunnel()

        NSLog("VPN Stop")
    }
    func restartVPN(stationId:Int64, dbPath:String) {

        stopVPN()

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 1
        ) {

            self.startVPN(stationId:stationId,dbPath: dbPath)
        }
    }
    
    func initStartVPN(){
        let sid = DrawinBeetleLibGetCurStationId()
        if sid == -1{
            return
        }
        
        let dbpath = getSharedDirectory()
     
        self.startVPN(stationId: Int64(sid), dbPath: dbpath.path)
    }
    
    @objc private func vpnStatusChanged(_ notification: Notification) {
        // 1. 确保是 NEVPNConnection
            guard let connection = notification.object as? NEVPNConnection else {
                return
            }
            
            // 2. 关键过滤：只处理我们自己的 tunnelManager 的连接
            guard let ourConnection = tunnelManager?.connection else {
                // tunnelManager 还没加载完成，忽略
                return
            }
            
            guard connection === ourConnection else {
                // 不是我们自己的 VPN 配置，忽略
                return
            }
            
            let currentStatus = connection.status
            
            switch currentStatus {
            case .connecting:
                connectionState = "Connectiong"
                print("⏳ PacketTunnel 正在启动中...")
                
            case .connected:
                connectionState = "Connected"
                print("✅ PacketTunnel 已经完全启动，VPN 已连通！")
                
            case .disconnecting:
                connectionState = "Disconnecting"
                print("⏳ PacketTunnel 正在关闭中...")
                
            case .disconnected:
                connectionState = "Disconnected"
                print("❌ PacketTunnel 已经彻底关闭。")
                
            case .invalid:
                connectionState = "Invalid"
                print("⚠️ VPN 配置无效。")
                
            case .reasserting:
                connectionState = "Reasserting"
                print("🔄 VPN 正在尝试重连...")
                
            @unknown default:
                connectionState = "Unknow"
                print("未知 VPN 状态: \(currentStatus.rawValue)")
            }
        }
}
