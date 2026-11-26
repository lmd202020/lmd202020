
import SwiftUI
import UIKit

struct MainView:View {
    @State private var tab=0
    var body:some View {
        TabView(selection:$tab) {
            HomeView().tabItem{Label("Trang chủ",systemImage:"house.fill")}.tag(0)
            GameView().tabItem{Label("Game",systemImage:"gamecontroller.fill")}.tag(1)
            AdminView().tabItem{Label("Admin",systemImage:"crown.fill")}.tag(2)
        }.tint(.cyan)
    }
}
struct HomeView:View {
    var body:some View {
        NavigationStack { ZStack { AppBackground(); ScrollView {
            VStack(alignment:.leading,spacing:18) {
                HStack { VStack(alignment:.leading,spacing:5) {
                    Text("ADMIN MINHDUC").font(.system(size:23,weight:.black,design:.rounded)).foregroundStyle(.white)
                    Text("GAMING BOOST CONTROL").font(.system(size:10,weight:.bold,design:.monospaced)).foregroundStyle(.cyan)
                }; Spacer(); Image("AppIcon").resizable().scaledToFit().frame(width:55,height:55).clipShape(RoundedRectangle(cornerRadius:14)) }
                HStack(spacing:12) { StatCard(title:"CHẾ ĐỘ",value:"GAMING",icon:"gamecontroller.fill"); StatCard(title:"BẢO VỆ",value:"SAFE",icon:"checkmark.shield.fill") }
                VStack(alignment:.leading,spacing:12) {
                    Label("TỐI ƯU TRƯỚC KHI CHƠI",systemImage:"sparkles").font(.system(size:14,weight:.black)).foregroundStyle(.cyan)
                    TipRow(icon:"battery.100percent",title:"Pin",detail:"Tắt Chế độ nguồn điện thấp để tránh giới hạn hiệu năng.")
                    TipRow(icon:"thermometer.medium",title:"Nhiệt độ",detail:"Để máy nguội; tháo ốp nếu thiết bị quá nóng.")
                    TipRow(icon:"wifi",title:"Kết nối",detail:"Ưu tiên Wi‑Fi ổn định hoặc mạng di động có tín hiệu tốt.")
                    TipRow(icon:"bell.slash",title:"Thông báo",detail:"Bật chế độ Tập trung khi chơi game trong Cài đặt iOS.")
                    TipRow(icon:"internaldrive",title:"Dung lượng",detail:"Giữ đủ dung lượng trống và đóng tác vụ không cần thiết.")
                }.padding(18).panel()
                Text("Giới hạn iOS: ứng dụng không thể ép FPS, tăng xung CPU/GPU, điều khiển nhiệt độ hay bảo đảm ping/hiệu năng 100%.").font(.system(size:11)).foregroundStyle(.white.opacity(0.45))
            }.padding(18)
        } } }
    }
}
struct GameView:View {
    private let games:[GameItem]=[
        .init(name:"FREE FIRE VIỆT NAM",subtitle:"Garena Free Fire VN",bundle:"com.garena.ffvn",scheme:"freefirevn://"),
        .init(name:"FREE FIRE THÁI LAN",subtitle:"Garena Free Fire TH",bundle:"com.dts.freefireth",scheme:"freefireth://")
    ]
    var body:some View {
        NavigationStack { ZStack { AppBackground(); ScrollView { VStack(alignment:.leading,spacing:14) {
            Text("CHỌN PHIÊN BẢN GAME").font(.system(size:17,weight:.black)).foregroundStyle(.white)
            ForEach(games) { game in VStack(alignment:.leading,spacing:12) {
                HStack { Image(systemName:"flame.fill").font(.system(size:25)).foregroundStyle(.orange).frame(width:48,height:48).background(.orange.opacity(0.12),in:RoundedRectangle(cornerRadius:13))
                    VStack(alignment:.leading,spacing:4) { Text(game.name).font(.system(size:14,weight:.black)).foregroundStyle(.white); Text(game.subtitle).font(.system(size:11)).foregroundStyle(.white.opacity(0.5)) }; Spacer() }
                Button { if let url=URL(string:game.scheme) { UIApplication.shared.open(url) } } label: { Label("MỞ GAME",systemImage:"arrow.up.right.square").font(.system(size:13,weight:.black)).foregroundStyle(.black).frame(maxWidth:.infinity,minHeight:46).background(.cyan,in:RoundedRectangle(cornerRadius:12)) }
                Text("Bundle ID: \(game.bundle)").font(.system(size:9,design:.monospaced)).foregroundStyle(.white.opacity(0.35))
            }.padding(16).panel() }
            Text("Cần cài game tương ứng. Nếu URL scheme không được game đăng ký, hãy mở game thủ công.").font(.system(size:11)).foregroundStyle(.white.opacity(0.45))
        }.padding(18) } } }.navigationTitle("Game").toolbarColorScheme(.dark) }
    }
}
struct AdminView:View {
    @EnvironmentObject private var license:LicenseManager
    @State private var confirmLogout=false
    var body:some View {
        NavigationStack { ZStack { AppBackground(); ScrollView { VStack(spacing:16) {
            Image("AppIcon").resizable().scaledToFit().frame(width:95,height:95).clipShape(RoundedRectangle(cornerRadius:23))
            Text("ADMIN MINHDUC").font(.system(size:21,weight:.black,design:.rounded)).foregroundStyle(.white)
            Text("PREMIUM • GAME SUPPORT").font(.system(size:10,weight:.bold,design:.monospaced)).foregroundStyle(.yellow)
            VStack(alignment:.leading,spacing:12) {
                Label("TRẠNG THÁI LICENSE",systemImage:"checkmark.seal.fill").foregroundStyle(.cyan).font(.system(size:13,weight:.black))
                HStack { Text("Tài khoản"); Spacer(); Text(license.isActive ? "Đã kích hoạt":"Chưa kích hoạt").foregroundStyle(.green) }
                if let expiry=license.expiresAt { HStack { Text("Hết hạn"); Spacer(); Text(expiry) } }
                if let msg=license.message { Text(msg).font(.system(size:11)).foregroundStyle(.white.opacity(0.55)) }
            }.font(.system(size:12,weight:.medium)).foregroundStyle(.white).padding(17).panel()
            Button(role:.destructive) { confirmLogout=true } label: { Label("ĐĂNG XUẤT / XOÁ KEY",systemImage:"rectangle.portrait.and.arrow.right").font(.system(size:13,weight:.black)).foregroundStyle(.white).frame(maxWidth:.infinity,minHeight:48).background(.red.opacity(0.8),in:RoundedRectangle(cornerRadius:12)) }
            Text("Quản lý tạo / khoá / gia hạn License phải thực hiện trên trang quản trị máy chủ. Không nhúng ADMIN_SECRET vào ứng dụng iOS.").font(.system(size:10)).foregroundStyle(.white.opacity(0.42))
        }.padding(20) } } }.navigationTitle("Admin").toolbarColorScheme(.dark).confirmationDialog("Bạn muốn đăng xuất?",isPresented:$confirmLogout,titleVisibility:.visible) {
            Button("Đăng xuất và xoá key",role:.destructive) { license.logout() }; Button("Huỷ",role:.cancel){}
        } }
    }
}
private struct GameItem:Identifiable { let id=UUID(); let name:String; let subtitle:String; let bundle:String; let scheme:String }
private struct StatCard:View {
    let title:String; let value:String; let icon:String
    var body:some View { VStack(alignment:.leading,spacing:8) { Image(systemName:icon).foregroundStyle(.cyan); Text(value).font(.system(size:17,weight:.black,design:.rounded)).foregroundStyle(.white); Text(title).font(.system(size:9,weight:.bold,design:.monospaced)).foregroundStyle(.white.opacity(0.4)) }.frame(maxWidth:.infinity,alignment:.leading).padding(15).panel() }
}
private struct TipRow:View {
    let icon:String; let title:String; let detail:String
    var body:some View { HStack(alignment:.top,spacing:12) { Image(systemName:icon).foregroundStyle(.cyan).frame(width:23); VStack(alignment:.leading,spacing:3) { Text(title).font(.system(size:12,weight:.bold)).foregroundStyle(.white); Text(detail).font(.system(size:11)).foregroundStyle(.white.opacity(0.55)) } } }
}
private struct AppBackground:View {
    var body:some View { ZStack { LinearGradient(colors:[Color(red:0.015,green:0.025,blue:0.05),.black],startPoint:.topLeading,endPoint:.bottomTrailing); Circle().fill(.cyan.opacity(0.08)).frame(width:260).blur(radius:70).offset(x:150,y:-300) }.ignoresSafeArea() }
}
private extension View {
    func panel()->some View { background(.white.opacity(0.055),in:RoundedRectangle(cornerRadius:18)).overlay(RoundedRectangle(cornerRadius:18).stroke(.white.opacity(0.09))) }
}
