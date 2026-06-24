import SwiftUI
import Combine


@main
struct MyMenuApp: App {
//    @State private var contactCompleted =
//            BeetleVPNManager.shared.hasContactInfo()
    
    @State private var isPacEnabled: Bool = true
    @State private var isTunMode: Bool = false // false = socks5, true = tun
    @StateObject private var vpnManager = BeetleVPNManager.shared

    // 3. 模拟实时流量数据
//    @StateObject private var trafficManager = TrafficManager()
       
    @StateObject private var manager: StationManager

//    @State private var selectedStationId: Int64=1
    @StateObject private var licenseManager = LicenseManager()
    
    init() {
        NotificationCenter.default.addObserver( forName: NSApplication.willTerminateNotification, object: nil, queue: .main ) { _ in BeetleVPNManager.shared.stopVPN() }
        BeetleVPNManager.shared.initialize()
        let lm = LicenseManager()
        _manager = StateObject(wrappedValue: StationManager(licenseManager: lm))
        
        if BeetleVPNManager.shared.isWalletOpened(){
            BeetleVPNManager.shared.loadVPNManager { error in

                if let error = error {
                    print(error)
                } else {
                    print("VPN Manager Ready")
                }
                BeetleVPNManager.shared.initStartVPN()
            }
            
        }
       
           
        if !BeetleVPNManager.shared.hasContactInfo() {
                let window = NSWindow(
                    contentRect: NSRect(
                        x: 0,
                        y: 0,
                        width: 520,
                        height: 460
                    ),
                    styleMask: [
                        .titled,
                        .closable
                    ],
                    backing: .buffered,
                    defer: false
                )

                window.center()
                var shouldTerminateOnClose = true
                
                NotificationCenter.default.addObserver(
                        forName: NSWindow.willCloseNotification,
                        object: window,
                        queue: .main
                    ) { _ in
                        // 只有点击关闭按钮才会执行退出
                        if shouldTerminateOnClose{
                            DispatchQueue.main.async {
                                NSApplication.shared.terminate(nil)
                            }
                        }
                    }
                window.contentView =
                    NSHostingView(
                        rootView: ContactView {
                            email,
                            telegram in
                            shouldTerminateOnClose = false
                            let ok =
                                BeetleVPNManager.shared.submitContact(
                                    email: email,
                                    telegram: telegram,
                                    password: "123"
                                )

                            if ok {
                                window.close()
                            }
                        }
                    )
                
                window.makeKeyAndOrderFront(nil)
            }
    }
    
    
 
    

    var body: some Scene {
        
            MenuBarExtra {
//                Text("⬆️ \(trafficManager.uploadSpeed)   ⬇️ \(trafficManager.downloadSpeed)")
//                   .font(.system(.caption, design: .monospaced))
//
//                Divider()

    //            Button(action: {}) {
    //                Label(licenseManager.licenseStatusText, systemImage: licenseManager.licenseIcon)
    //            }.disabled(true)
                if licenseManager.licenseDayLeft! < 30 {
                    Button(action: {licenseManager.openDAppWebsite()}){
                        Label(licenseManager.licenseStatusText,systemImage: licenseManager.licenseIcon)
                    }
                }else{
//                    HStack{
//                        Image(systemName: licenseManager.licenseIcon)
                        Text(licenseManager.licenseStatusText)
//                    }
                }

                Divider()


                Toggle(isPacEnabled ? "PAC 模式: 已开启" : "PAC 模式: 已关闭", isOn: $isPacEnabled)

                Picker("代理模式", selection: $isTunMode) {
                    Text("Socks5 模式").tag(true)
                    Text("TUN 虚拟网卡").tag(false)
                }
                .pickerStyle(.inline)

                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                                Text("Beetle VPN ID")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Button(action: {
                                    if vpnManager.beetleID != nil{
                                        copyToClipboard(vpnManager.beetleID)
                                    }
                                }) {
                                    Text(truncatedID(getVid()))
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.primary)
                                }
                                .buttonStyle(.plain)           // 去掉按钮默认样式
                                .help(getVid())             // 鼠标悬停显示完整ID
                            }
                            .padding(.vertical, 2)
                Divider()

                Menu("节点列表 (当前: \(manager.getStationName(id: manager.selectStationId)))") {
                    Button(action: { manager.refreshStations() }) {
                        Label(
                            manager.isLoading ? "正在刷新..." : "刷新节点状态",
                            systemImage: manager.isLoading ? "line.3.crossed.swirl.circle.fill" : "arrow.clockwise")
                    }.disabled(manager.isLoading)

                    Divider()

                    Picker("选择节点", selection: Binding<Int64>(
                        get: { manager.selectStationId },
                        set: { manager.setSelectStationId(id:$0) }
                   )) {
                        ForEach(manager.stations) { station in
                            let alignedName = (station.name + "-" + station.state+"-"+station.country).paddingToLength(10)
                            Text("\(station.statusEmoji) \(alignedName) ⏱️ ").tag(station.id)
                        }
                    }.pickerStyle(.inline)
                }

                Divider()

                // --- 基础辅助菜单 ---
                Button("关于 (About)") {
                    NSApp.orderFrontStandardAboutPanel(nil) // 弹出系统自带的 About 窗口
                }

                Button("帮助 (Help)") {
                    if let url = URL(string: "https://your-vpn-help-site.com") {
                        NSWorkspace.shared.open(url) // 点击打开帮助网页
                    }
                }

                Divider()

                Button("退出") {
                    NSApplication.shared.terminate(nil)
//                    BeetleVPNManager.shared.stopVPN()
                }
            } label: {
               // 菜单栏常驻图标和文字（会根据定时器实时刷新数据）
                HStack(spacing: 5) {
                Image(systemName: "network") // 一个网卡网格图标
//                    Text("▲\(trafficManager.uploadSpeed) ▼\(trafficManager.downloadSpeed)")
//                   .font(.system(size: 10, design: .monospaced)) // 使用等宽字体防止数字跳动闪烁
                }
//                TrafficLabelView(
//                        trafficManager: trafficManager
//                    )
            }
    }
    
    
        
    func getVid() ->String{
        guard let vid = vpnManager.beetleID else{
            return "wallet have not created"
        }
        return vid
    }

    // 模拟刷新节点的方法
    func refreshStations() {
        print("正在刷新节点...")
        // 模拟随机改变节点的在线状态
//        for i in 0..<manager.stations.count {
////           manager.stations[i]
//        }
    }
    private func copyToClipboard(_ cpText: String?) {
        guard let text:String = cpText else{
            return
        }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            
            // 可选：显示复制成功提示
            let alert = NSAlert()
            alert.messageText = "copy success"
            alert.informativeText = "Beetle VPN ID:\n \(text) \ncopied to clipboard."
            alert.alertStyle = .informational
            alert.runModal()
        }

        // MARK: - 截断显示（头尾显示，中间省略）
        private func truncatedID(_ id: String) -> String {
            guard id.count > 20 else { return id }
            let head = id.prefix(8)
            let tail = id.suffix(8)
            return "\(head)...\(tail)"
        }
}

extension String {
    func paddingToLength(_ length: Int) -> String {
        let currentLength = self.count
        if currentLength >= length { return self }
    
        return self + String(repeating: "\u{2007}", count: length - currentLength)
    }
}
