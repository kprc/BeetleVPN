import SwiftUI
import Foundation
import Combine
import Macdss


// 确保 Station 遵循 Codable 以便解析网络数据，遵循 Identifiable 方便 ForEach 遍历
struct Station: Identifiable, Codable {
    let id: Int64
    let name: String
    let state: String
    let country: String
    let heath: Int
    
    var statusEmoji: String {
        if heath == 0 { return "🔴" }
        if heath < 30 { return "🟡" }
        return "🟢"
    }
    var ping:Int{
        return 100
    }
    var isOnline:Bool{
        if heath>0{
            return true
        }
        return false
    }
}

class StationManager: ObservableObject {
    @Published var stations: [Station] = []
    @Published var isLoading = false // 用于展示刷新中的状态
    @Published var selectStationId:Int64=1
    
    weak var licenseManager: LicenseManager?
    
    init(licenseManager: LicenseManager? = nil){
        self.licenseManager = licenseManager
        getStationList()
       let id=DrawinBeetleLibGetCurStationId()
        if id > 0{
            self.selectStationId = Int64(id)
        }else{
            self.selectStationId = 1
            DrawinBeetleLibSetCurStation(self.selectStationId)
        }
    }
    
    // 模拟从远程 API 下载数据
    func refreshStations() {
        guard !isLoading else { return }
                isLoading = true
        
                var err:NSError?
                DrawinBeetleLibRefreshStations(&err)
                isLoading = false
                
//                guard let url = URL(string: "https://yourdomain.com") else {
//                    isLoading = false
//                    return
//                }
                getStationList()
                
    }
    private func getStationList(){
        var err:NSError?
        let stationstr = DrawinBeetleLibGetStationList(&err)
        let stationData = stationstr.data(using: .utf8)
        
        let decoder = JSONDecoder()
        do{
            stations = try decoder.decode([Station].self, from: stationData!)
        }catch{
            print("unmarshal station string list failed")
        }
    }
    func getStationName(id:Int64)->String{
        guard let st = stations.first(where: { $0.id == id }) else {
                return "" // Return a fallback if the ID doesn't exist
            }
            
        // 2. Safely combine using string interpolation
        return "\(st.name)-\(st.state)-\(st.country)"
    }
    func setSelectStationId(id:Int64){
        self.selectStationId = id
        DrawinBeetleLibSetCurStation(self.selectStationId)
        // stop vpn
        // start newvpn
        guard let licenseManager = licenseManager else {
                    print("⚠️ LicenseManager is not injected, unable to check license authorization")
                    return
        }
                
        if licenseManager.licenseDayLeft == nil || licenseManager.licenseDayLeft! < 0 {
            print("❌ License has expired or is not activated, switching nodes is not allowed")
            // 可选：发出通知或弹窗提示
            showLicenseExpiredAlert()
            return
        }
        let dbpath = BeetleVPNManager.shared.getSharedDirectory()
        
        BeetleVPNManager.shared.restartVPN(stationId: id,dbPath: dbpath.path)
    }
    private func showLicenseExpiredAlert() {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Invalid License"
                alert.informativeText =  "Your License has expired or is not activated. Node switching is not allowed.\nPlease click the License button in the menu to renew."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
}


