import SwiftUI
import Foundation
import Combine
import Macdss



class LicenseManager: ObservableObject{
    private var licenseExpiryDate: Date?=nil
    
    // -1 已经过期，-2 还未申请，>0 剩余天数
    @Published var licenseDayLeft: Int?=nil
    private var licenseDateStr:String?=nil
    
    
    init() {
        refreshLicense()
    }
    
    var licenseStatusText:String{
        if self.licenseDayLeft! == -2{
            return "Click to Purchase License Activation Service"
        }
        if self.licenseDayLeft! == -1{
            return "License has expired. Please renew it"
        }
        if self.licenseDayLeft! == 0{
            return "Warning: License expires today. Please renew"
        }
        if self.licenseDayLeft! < 30 {
            return "Note: License expires in \(self.licenseDayLeft!) days. Please renew"
        }
        return "Activated (Valid until: \(self.licenseDateStr!)"
    }
    
    var licenseIcon: String{
        if self.licenseDayLeft! < 0{
            return "cart.badge.plus"
        }
        
        if self.licenseDayLeft! < 30{
            return "exclamationmark.triangle.fill"
        }
        
        return "checkmark.seal.fill"
    }
    
    func refreshLicense(){
        var err:NSError?
        DrawinBeetleLibRefreshLicense(&err)
        self.licenseDateStr = DrawinBeetleLibGetLicenseExpireDate()
        if licenseDateStr == "no license"{
            self.licenseDayLeft = -2
        }else{
            licenseExpiryDate = dateFromDateString(licenseDateStr!)
            self.licenseDayLeft = daysFromDate(licenseExpiryDate)
        }
    }
    func openDAppWebsite() {
            if let url = URL(string: "http://127.0.0.1:50211") {
                NSWorkspace.shared.open(url)
            }
    }
    
}

func dateFromDateString(_ dateString:String) ->Date?{
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    formatter.timeZone = TimeZone.current
    formatter.locale = Locale(identifier: "en_US_POSIX")
    
    guard let d = formatter.date(from:dateString) else{
        return nil
    }
    
    return d
}

func daysFromDate(_ date:Date?)->Int{
    if date == nil{
        return -2
    }
    
    let secondsDiff = date!.timeIntervalSinceNow
    let days = Int(floor(secondsDiff/86400))
    
    if days < 0{
        return -1
    }
    
    return days
}


