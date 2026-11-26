
import SwiftUI
struct LicenseActivationView:View {
    @EnvironmentObject private var license:LicenseManager
    @State private var key=""
    @State private var reveal=false
    var body:some View {
        ZStack {
            LinearGradient(colors:[Color(red:0.01,green:0.02,blue:0.05),Color(red:0.10,green:0.025,blue:0.07),.black],startPoint:.topLeading,endPoint:.bottomTrailing).ignoresSafeArea()
            Circle().fill(.cyan.opacity(0.12)).frame(width:260).blur(radius:70).offset(x:140,y:-260)
            ScrollView { VStack(spacing:22) {
                Spacer(minLength:55)
                Image("AppIcon").resizable().scaledToFit().frame(width:104,height:104).clipShape(RoundedRectangle(cornerRadius:24)).overlay(RoundedRectangle(cornerRadius:24).stroke(.yellow.opacity(0.8),lineWidth:1.4))
                VStack(spacing:6) {
                    Text("ADMIN MINHDUC").font(.system(size:27,weight:.black,design:.rounded)).tracking(1.5).foregroundStyle(.white)
                    Text("GAMING PERFORMANCE • PREMIUM").font(.system(size:10,weight:.bold,design:.monospaced)).tracking(1.5).foregroundStyle(.cyan)
                }
                VStack(alignment:.leading,spacing:16) {
                    Label("KÍCH HOẠT LICENSE",systemImage:"key.fill").font(.system(size:15,weight:.black)).foregroundStyle(.yellow)
                    Text("Nhập License Key được cấp để xác thực thiết bị và sử dụng ứng dụng.").font(.system(size:13)).foregroundStyle(.white.opacity(0.65))
                    HStack {
                        Group { if reveal { TextField("LICENSE-XXXX-XXXX",text:$key) } else { SecureField("LICENSE-XXXX-XXXX",text:$key) } }
                            .textInputAutocapitalization(.characters).autocorrectionDisabled().font(.system(.body,design:.monospaced))
                        Button { reveal.toggle() } label:{Image(systemName:reveal ? "eye.slash":"eye").foregroundStyle(.cyan)}
                    }.padding(16).background(.black.opacity(0.45),in:RoundedRectangle(cornerRadius:14)).overlay(RoundedRectangle(cornerRadius:14).stroke(.cyan.opacity(0.4)))
                    Toggle("Ghi nhớ License Key",isOn:$license.rememberKey).font(.system(size:12,weight:.medium)).tint(.cyan)
                    Button { license.activate(key) } label:{
                        HStack { if license.isBusy { ProgressView().tint(.black) } else { Image(systemName:"checkmark.shield.fill") }; Text(license.isBusy ? "ĐANG XÁC THỰC…" : "XÁC MINH VÀ TIẾP TỤC") }
                            .font(.system(size:14,weight:.black)).foregroundStyle(.black).frame(maxWidth:.infinity,minHeight:52).background(LinearGradient(colors:[.cyan,.mint],startPoint:.leading,endPoint:.trailing),in:RoundedRectangle(cornerRadius:14))
                    }.disabled(key.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || license.isBusy)
                    if let message=license.message { Text(message).font(.system(size:12,weight:.medium)).foregroundStyle(message.contains("hợp lệ") ? .green : .orange).fixedSize(horizontal:false,vertical:true) }
                }.padding(20).background(.white.opacity(0.055),in:RoundedRectangle(cornerRadius:22)).overlay(RoundedRectangle(cornerRadius:22).stroke(.white.opacity(0.12)))
                VStack(spacing:5) {
                    Text("FREE FIRE VN • FREE FIRE TH").font(.system(size:10,weight:.bold,design:.monospaced)).foregroundStyle(.white.opacity(0.45))
                    Text("ADMIN MINHDUC | LICENSE PROTECTED").font(.system(size:9,weight:.medium,design:.monospaced)).foregroundStyle(.white.opacity(0.3))
                }
                Spacer(minLength:35)
            }.padding(.horizontal,24) }
        }
    }
}
