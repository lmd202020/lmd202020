import SwiftUI
import UIKit
import Darwin

// MARK: - Main app navigation
struct MainView: View {
    @State private var tab = 0
    @AppStorage("md_device_setup_completed") private var deviceSetupCompleted = false
    @State private var showDeviceSetup = false

    var body: some View {
        TabView(selection: $tab) {
            HomeView(selectTab: { tab = $0 })
                .tabItem { Label("Trang Chủ", systemImage: "house.fill") }.tag(0)
            GameView()
                .tabItem { Label("Game", systemImage: "gamecontroller.fill") }.tag(1)
            DeviceOptimizationView()
                .tabItem { Label("Tối Ưu", systemImage: "slider.horizontal.3") }.tag(2)
            LagReductionView()
                .tabItem { Label("Giảm Lag", systemImage: "bolt.fill") }.tag(3)
            SensitivityView()
                .tabItem { Label("Độ Nhạy", systemImage: "scope") }.tag(4)
        }
        .tint(.cyan)
        .background(AppBackground().ignoresSafeArea())
        .fullScreenCover(isPresented: $showDeviceSetup) {
            DeviceSetupView { showDeviceSetup = false }
        }
        .onAppear {
            if !deviceSetupCompleted { showDeviceSetup = true }
        }
    }
}

// MARK: - Device recognition and demo sensitivity onboarding
private struct DeviceProfileInfo {
    let marketingName: String
    let machineIdentifier: String
    let iosVersion: String
    let category: String
    let recommendedValues: [Double]

    static func detect() -> DeviceProfileInfo {
        var system = utsname()
        uname(&system)
        let identifier = withUnsafePointer(to: &system.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
        }
        let version = UIDevice.current.systemVersion
        let modelNames: [String: String] = [
            "iPhone14,2": "iPhone 13 Pro", "iPhone14,3": "iPhone 13 Pro Max",
            "iPhone14,4": "iPhone 13 mini", "iPhone14,5": "iPhone 13",
            "iPhone15,2": "iPhone 14 Pro", "iPhone15,3": "iPhone 14 Pro Max",
            "iPhone15,4": "iPhone 14", "iPhone15,5": "iPhone 14 Plus",
            "iPhone16,1": "iPhone 15 Pro", "iPhone16,2": "iPhone 15 Pro Max",
            "iPhone16,3": "iPhone 15", "iPhone16,4": "iPhone 15 Plus",
            "iPhone17,1": "iPhone 16 Pro", "iPhone17,2": "iPhone 16 Pro Max",
            "iPhone17,3": "iPhone 16", "iPhone17,4": "iPhone 16 Plus"
        ]
        let name = modelNames[identifier] ?? "iPhone (\(identifier))"
        let proMaxModels: Set<String> = ["iPhone15,3", "iPhone16,2", "iPhone17,2"]
        let proModels: Set<String> = ["iPhone15,2", "iPhone16,1", "iPhone17,1"]
        let isProMax = proMaxModels.contains(identifier)
        let isPro = proModels.contains(identifier)
        let isOlder = identifier.hasPrefix("iPhone10,") || identifier.hasPrefix("iPhone11,") || identifier.hasPrefix("iPhone12,")
        let category = isProMax ? "Nhóm Pro Max" : (isPro ? "Nhóm Pro" : (isOlder ? "Nhóm iPhone đời cũ" : "Nhóm iPhone tiêu chuẩn / đời mới"))
        let values: [Double]
        if isProMax {
            values = [190, 188, 180, 170, 95, 160]
        } else if isPro {
            values = [188, 185, 178, 168, 92, 155]
        } else if isOlder {
            values = [178, 175, 165, 155, 82, 145]
        } else {
            values = [185, 182, 175, 165, 88, 150]
        }
        return DeviceProfileInfo(
            marketingName: name,
            machineIdentifier: identifier,
            iosVersion: version,
            category: category,
            recommendedValues: values
        )
    }
}

private struct DeviceSetupView: View {
    let onFinish: () -> Void
    @AppStorage("ff_sens_general") private var general: Double = 185
    @AppStorage("ff_sens_red_dot") private var redDot: Double = 180
    @AppStorage("ff_sens_2x") private var scope2x: Double = 175
    @AppStorage("ff_sens_4x") private var scope4x: Double = 165
    @AppStorage("ff_sens_sniper") private var sniper: Double = 90
    @AppStorage("ff_sens_free_look") private var freeLook: Double = 150
    @AppStorage("md_device_setup_completed") private var completed = false
    @State private var gameVersion = "VN"
    @State private var applied = false
    private let device = DeviceProfileInfo.detect()

    var body: some View {
        ZStack {
            AppBackground().ignoresSafeArea()
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    Spacer(minLength: 18)
                    Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(.cyan)
                        .frame(width: 104, height: 104)
                        .background(.cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 28))
                        .overlay(RoundedRectangle(cornerRadius: 28).stroke(.cyan.opacity(0.45)))
                    VStack(spacing: 7) {
                        Text("NHẬN DIỆN THIẾT BỊ")
                            .font(.system(size: 23, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("MINHDUC AIM SUPPORT PRO")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(1.5).foregroundStyle(.cyan)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Label("THIẾT BỊ ĐÃ NHẬN DIỆN", systemImage: "checkmark.seal.fill")
                            .font(.system(size: 12, weight: .black)).foregroundStyle(.green)
                        deviceRow("Tên thiết bị", device.marketingName)
                        deviceRow("Mã máy", device.machineIdentifier)
                        deviceRow("Phiên bản iOS", device.iosVersion)
                        deviceRow("Nhóm thiết bị", device.category)
                    }.padding(17).panel()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("CHỌN PHIÊN BẢN FREE FIRE")
                            .font(.system(size: 12, weight: .black)).foregroundStyle(.cyan)
                        Picker("Game", selection: $gameVersion) {
                            Text("FREE FIRE VN").tag("VN")
                            Text("FREE FIRE TH").tag("TH")
                        }.pickerStyle(.segmented)
                        Text(gameVersion == "VN" ? "com.garena.ffvn" : "com.dts.freefireth")
                            .font(.system(size: 10, design: .monospaced)).foregroundStyle(.white.opacity(0.5))
                    }.padding(17).panel()

                    VStack(alignment: .leading, spacing: 11) {
                        Label("HỒ SƠ ĐỘ NHẠY DEMO ĐỀ XUẤT", systemImage: "scope")
                            .font(.system(size: 12, weight: .black)).foregroundStyle(.cyan)
                        Text("Được chọn theo nhóm thiết bị. Bạn có thể chỉnh lại sau trong tab Độ nhạy.")
                            .font(.system(size: 10)).foregroundStyle(.white.opacity(0.55))
                        let labels = ["Tổng quan", "Red Dot", "Ống ngắm 2X", "Ống ngắm 4X", "Ống ngắm súng ngắm", "Nhìn xung quanh"]
                        ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                            HStack {
                                Text(label).font(.system(size: 11, weight: .medium)).foregroundStyle(.white.opacity(0.8))
                                Spacer()
                                Text("\(Int(device.recommendedValues[index]))")
                                    .font(.system(size: 15, weight: .black, design: .rounded))
                                    .monospacedDigit().foregroundStyle(.cyan)
                            }
                        }
                        Text("THANG ĐỘ NHẠY 0–200")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                    }.padding(17).panel()

                    Button {
                        applyRecommendedProfile()
                        completed = true
                        applied = true
                        onFinish()
                    } label: {
                        Label("ÁP DỤNG HỒ SƠ DEMO & TIẾP TỤC", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity, minHeight: 54)
                            .background(LinearGradient(colors: [.cyan, .mint], startPoint: .leading, endPoint: .trailing), in: RoundedRectangle(cornerRadius: 15))
                    }
                    Text("Đây là thông số tham khảo để thử nghiệm, không phải độ nhạy được game tự động xác nhận. Ứng dụng không đọc hoặc sửa dữ liệu riêng của Free Fire.")
                        .font(.system(size: 9)).foregroundStyle(.white.opacity(0.42))
                        Spacer(minLength: 20)
                    }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 30)
            }
        }
        .statusBarHidden(false)
    }

    private func deviceRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).font(.system(size: 11)).foregroundStyle(.white.opacity(0.5))
            Spacer()
            Text(value).font(.system(size: 11, weight: .semibold)).foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
        }
    }

    private func applyRecommendedProfile() {
        general = device.recommendedValues[0]
        redDot = device.recommendedValues[1]
        scope2x = device.recommendedValues[2]
        scope4x = device.recommendedValues[3]
        sniper = device.recommendedValues[4]
        freeLook = device.recommendedValues[5]
        UserDefaults.standard.set(gameVersion, forKey: "md_selected_ff_version")
        UserDefaults.standard.set(true, forKey: "md_demo_profile_applied")
    }
}

// MARK: - Home dashboard
struct HomeView: View {
    let selectTab: (Int) -> Void
    private let device = DeviceProfileInfo.detect()

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground().ignoresSafeArea()
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("MINHDUC")
                                    .font(.system(size: 28, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                Text("iOS AIM SUPPORT PRO")
                                    .font(.system(size: 11, weight: .black, design: .monospaced))
                                    .tracking(1.4).foregroundStyle(.cyan)
                            }
                            Spacer()
                            Image("BrandLogo").resizable().scaledToFit()
                                .frame(width: 58, height: 58)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        HStack(spacing: 12) {
                            Image(systemName: "iphone.gen3")
                                .font(.system(size: 28)).foregroundStyle(.cyan)
                                .frame(width: 54, height: 54)
                                .background(.cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(device.marketingName).font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                                Text("iOS \(device.iosVersion)  •  \(device.machineIdentifier)")
                                    .font(.system(size: 9, design: .monospaced)).foregroundStyle(.white.opacity(0.48))
                            }
                            Spacer()
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                        }.padding(14).panel()

                        VStack(alignment: .leading, spacing: 12) {
                            Text("TRUNG TÂM ĐIỀU KHIỂN")
                                .font(.system(size: 12, weight: .black, design: .rounded)).foregroundStyle(.cyan)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                dashboardTile("MỞ GAME", subtitle: "Free Fire VN / TH", icon: "gamecontroller.fill") { selectTab(1) }
                                dashboardTile("TỐI ƯU CẤU HÌNH", subtitle: "Hồ sơ thiết bị", icon: "slider.horizontal.3") { selectTab(2) }
                                dashboardTile("GIẢM LAG MÁY", subtitle: "Chế độ hỗ trợ", icon: "bolt.fill") { selectTab(3) }
                                dashboardTile("ĐỘ NHẠY", subtitle: "Đề xuất theo máy", icon: "scope") { selectTab(4) }
                            }
                        }.padding(16).panel()

                        VStack(alignment: .leading, spacing: 10) {
                            Label("THÔNG TIN THIẾT BỊ", systemImage: "info.circle.fill")
                                .font(.system(size: 12, weight: .black)).foregroundStyle(.cyan)
                            infoRow("Nhóm thiết bị", device.category)
                            infoRow("Mã máy", device.machineIdentifier)
                            infoRow("Phiên bản iOS", device.iosVersion)
                        }.padding(16).panel()

                        Text("Các chế độ tối ưu trong ứng dụng quản lý hồ sơ và hướng dẫn thiết lập iOS. iOS không cho ứng dụng bên thứ ba ép xung, tự đóng ứng dụng khác hoặc thay đổi cấu hình hệ thống tùy ý.")
                            .font(.system(size: 10)).foregroundStyle(.white.opacity(0.42))
                    }.padding(18)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func dashboardTile(_ title: String, subtitle: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 9) {
                Image(systemName: icon).font(.system(size: 25, weight: .semibold)).foregroundStyle(.cyan)
                Text(title).font(.system(size: 12, weight: .black)).foregroundStyle(.white)
                Text(subtitle).font(.system(size: 9)).foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
            .padding(13)
            .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(.cyan.opacity(0.18)))
        }.buttonStyle(.plain)
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.white.opacity(0.5))
            Spacer()
            Text(value).foregroundStyle(.white)
        }.font(.system(size: 10, weight: .medium))
    }
}

// MARK: - Crosshair Trainer (THỰC SỰ HOẠT ĐỘNG)
struct CrosshairTrainerView: View {
    @AppStorage("bestScore") private var bestScore: Int = 0
    @State private var crosshairPos: CGPoint = .zero
    @State private var targetPos: CGPoint = .zero
    @State private var playfieldSize: CGSize = .zero
    @State private var score = 0
    @State private var hits = 0
    @State private var misses = 0
    @State private var timeLeft = 30
    @State private var isRunning = false
    @State private var showOverlay = false
    @State private var timer: Timer?

    private let crosshairSize: CGFloat = 60
    private let targetSize: CGFloat = 70

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()

                if showOverlay {
                    CrosshairOverlayView(onClose: { showOverlay = false })
                } else {
                    VStack(spacing: 14) {
                        // Header stats
                        HStack(spacing: 10) {
                            MiniStat(title: "ĐIỂM", value: "\(score)", color: .cyan)
                            MiniStat(title: "TRÚNG", value: "\(hits)", color: .green)
                            MiniStat(title: "TRƯỢT", value: "\(misses)", color: .red)
                            MiniStat(title: "BEST", value: "\(bestScore)", color: .yellow)
                        }

                        // Timer bar
                        HStack {
                            Image(systemName: "timer").foregroundStyle(.cyan)
                            Text(isRunning ? "\(timeLeft)s" : "Sẵn sàng")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .foregroundStyle(isRunning ? .cyan : .white.opacity(0.6))
                            Spacer()
                            Button {
                                start()
                            } label: {
                                Label(isRunning ? "Đang chơi..." : "BẮT ĐẦU", systemImage: "play.fill")
                                    .font(.system(size: 12, weight: .black))
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(.cyan, in: Capsule())
                                    .foregroundStyle(.black)
                            }.disabled(isRunning)
                        }.padding(.horizontal, 4)

                        // Play field
                        GeometryReader { geo in
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.black.opacity(0.4))
                                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.08)))

                                // Target
                                if isRunning {
                                    Circle()
                                        .fill(.red.opacity(0.35))
                                        .overlay(Circle().stroke(.red, lineWidth: 2))
                                        .frame(width: targetSize, height: targetSize)
                                        .position(targetPos)
                                }

                                // Crosshair
                                CrosshairShape()
                                    .stroke(isRunning ? .cyan : .white.opacity(0.5), lineWidth: 2)
                                    .frame(width: crosshairSize, height: crosshairSize)
                                    .position(crosshairPos)
                                    .gesture(
                                        DragGesture(coordinateSpace: .named("playfield"))
                                            .onChanged { val in
                                                crosshairPos = clamp(val.location, in: geo.size)
                                            }
                                            .onEnded { _ in
                                                if isRunning { checkHit() }
                                            }
                                    )

                                if !isRunning {
                                    Text("Kéo dấu + đến vòng đỏ\nvà thả ra để tính điểm")
                                        .multilineTextAlignment(.center)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.5))
                                        .allowsHitTesting(false)
                                }
                            }
                            .coordinateSpace(name: "playfield")
                            .onAppear {
                                playfieldSize = geo.size
                                crosshairPos = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                                targetPos = randomPoint(in: geo.size)
                            }
                            .onChange(of: geo.size) { newSize in
                                playfieldSize = newSize
                                if !isRunning {
                                    crosshairPos = CGPoint(x: newSize.width / 2, y: newSize.height / 2)
                                    targetPos = randomPoint(in: newSize)
                                }
                            }
                        }

                        // Overlay mode button
                        Button {
                            showOverlay = true
                        } label: {
                            Label("CHẾ ĐỘ TÂM THAM KHẢO (FULLSCREEN)", systemImage: "scope")
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(.yellow, in: RoundedRectangle(cornerRadius: 12))
                        }

                        Text("Đặt máy cạnh điện thoại chơi game để dùng tâm làm mốc tham khảo. Overlay chỉ hiển thị trong app, iOS không cho vẽ đè lên game khác.")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.42))
                            .multilineTextAlignment(.center)
                    }.padding(18)
                }
            }
            .navigationTitle("Kéo Tâm")
        }
        .onDisappear { stopTimer() }
    }

    // MARK: Logic
    private func start() {
        score = 0; hits = 0; misses = 0; timeLeft = 30; isRunning = true
        if playfieldSize.width > targetSize * 2 && playfieldSize.height > targetSize * 2 {
            targetPos = randomPoint(in: playfieldSize)
        }
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeLeft > 1 {
                timeLeft -= 1
            } else {
                timeLeft = 0
                endGame()
            }
        }
    }

    private func checkHit() {
        let dist = hypot(crosshairPos.x - targetPos.x, crosshairPos.y - targetPos.y)
        let threshold = targetSize / 2
        if dist <= threshold {
            hits += 1
            score += max(10, Int(50 - dist))
            if playfieldSize.width > targetSize * 2 && playfieldSize.height > targetSize * 2 {
                targetPos = randomPoint(in: playfieldSize)
            }
        } else {
            misses += 1
            score = max(0, score - 3)
        }
    }

    private func endGame() {
        isRunning = false
        stopTimer()
        if score > bestScore { bestScore = score }
    }

    private func stopTimer() {
        timer?.invalidate(); timer = nil
    }

    private func clamp(_ p: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: min(max(p.x, crosshairSize/2), size.width - crosshairSize/2),
                y: min(max(p.y, crosshairSize/2), size.height - crosshairSize/2))
    }

    private func randomPoint(in size: CGSize) -> CGPoint {
        CGPoint(x: CGFloat.random(in: targetSize...max(targetSize, size.width - targetSize)),
                y: CGFloat.random(in: targetSize...max(targetSize, size.height - targetSize)))
    }
}

// MARK: - Fullscreen crosshair overlay
struct CrosshairOverlayView: View {
    let onClose: () -> Void
    @State private var color: Color = .cyan
    @State private var size: CGFloat = 80
    private let colors: [Color] = [.cyan, .red, .green, .yellow, .white]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            CrosshairShape()
                .stroke(color, lineWidth: 2)
                .frame(width: size, height: size)

            VStack {
                HStack {
                    Button { onClose() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    Spacer()
                }.padding()
                Spacer()
                HStack(spacing: 12) {
                    ForEach(colors, id: \.self) { c in
                        Circle().fill(c).frame(width: 30, height: 30)
                            .overlay(Circle().stroke(.white, lineWidth: color == c ? 3 : 0))
                            .onTapGesture { color = c }
                    }
                    Slider(value: $size, in: 40...200)
                        .tint(.cyan)
                        .frame(width: 120)
                }
                .padding(14)
                .background(.white.opacity(0.08), in: Capsule())
                .padding(.bottom, 30)
            }
        }
    }
}

// MARK: - Crosshair Shape (vẽ dấu +)
struct CrosshairShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX, cy = rect.midY
        let gap: CGFloat = rect.width * 0.18
        // Trục ngang
        p.move(to: CGPoint(x: rect.minX, y: cy))
        p.addLine(to: CGPoint(x: cx - gap, y: cy))
        p.move(to: CGPoint(x: cx + gap, y: cy))
        p.addLine(to: CGPoint(x: rect.maxX, y: cy))
        // Trục dọc
        p.move(to: CGPoint(x: cx, y: rect.minY))
        p.addLine(to: CGPoint(x: cx, y: cy - gap))
        p.move(to: CGPoint(x: cx, y: cy + gap))
        p.addLine(to: CGPoint(x: cx, y: rect.maxY))
        // Chấm giữa
        p.addEllipse(in: CGRect(x: cx - 2, y: cy - 2, width: 4, height: 4))
        return p
    }
}


// MARK: - Free Fire Sensitivity Profiles (0–200)
struct SensitivityView: View {
    @AppStorage("ff_sens_general") private var general: Double = 185
    @AppStorage("ff_sens_red_dot") private var redDot: Double = 180
    @AppStorage("ff_sens_2x") private var scope2x: Double = 175
    @AppStorage("ff_sens_4x") private var scope4x: Double = 165
    @AppStorage("ff_sens_sniper") private var sniper: Double = 90
    @AppStorage("ff_sens_free_look") private var freeLook: Double = 150
    @State private var selectedPreset = "Tùy chỉnh"
    @State private var copied = false
    @AppStorage("md_selected_ff_version") private var selectedGame = "VN"
    @State private var launchStatus = ""

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground().ignoresSafeArea()
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("FREE FIRE • SENSITIVITY").font(.system(size: 19, weight: .black, design: .rounded)).foregroundStyle(.white)
                            Text("Tùy chỉnh hồ sơ độ nhạy theo thang 0–200").font(.system(size: 12, weight: .medium)).foregroundStyle(.cyan)
                            Text("Giá trị được lưu trên iPhone để bạn tham khảo và nhập thủ công trong game.").font(.system(size: 10)).foregroundStyle(.white.opacity(0.5))
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            Text("CHỌN PHIÊN BẢN GAME").font(.system(size: 12, weight: .black)).foregroundStyle(.cyan)
                            Picker("Phiên bản", selection: $selectedGame) {
                                Text("FREE FIRE VN").tag("VN")
                                Text("FREE FIRE TH").tag("TH")
                            }
                            .pickerStyle(.segmented)
                            Text(selectedGame == "VN" ? "com.garena.ffvn" : "com.dts.freefireth")
                                .font(.system(size: 10, design: .monospaced)).foregroundStyle(.white.opacity(0.45))
                        }.padding(15).panel()
                        VStack(alignment: .leading, spacing: 10) {
                            Label("ĐỀ XUẤT THEO THIẾT BỊ", systemImage: "iphone.gen3")
                                .font(.system(size: 12, weight: .black)).foregroundStyle(.cyan)
                            Text("\\(detected.marketingName) • \\(detected.category) • iOS \\(detected.iosVersion)")
                                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.55))
                            Button { applyDeviceRecommendation() } label: {
                                Label("TẠO LẠI ĐỘ NHẠY THEO MÁY", systemImage: "wand.and.stars")
                                    .font(.system(size: 11, weight: .black)).foregroundStyle(.black)
                                    .frame(maxWidth: .infinity, minHeight: 42)
                                    .background(.cyan, in: RoundedRectangle(cornerRadius: 10))
                            }
                        }.padding(15).panel()
                        VStack(alignment: .leading, spacing: 10) {
                            Text("CHỌN PRESET").font(.system(size: 12, weight: .black)).foregroundStyle(.cyan)
                            HStack(spacing: 8) { presetButton("Kéo tâm nhẹ"); presetButton("Headshot") }
                            HStack(spacing: 8) { presetButton("Nhanh"); presetButton("Cân bằng") }
                        }.padding(15).panel()
                        VStack(spacing: 18) {
                            sensitivitySlider(title: "Tổng quan", subtitle: "Camera và xoay góc nhìn", value: $general)
                            sensitivitySlider(title: "Red Dot", subtitle: "Ngắm không dùng ống ngắm", value: $redDot)
                            sensitivitySlider(title: "Ống ngắm 2X", subtitle: "Độ nhạy scope 2X", value: $scope2x)
                            sensitivitySlider(title: "Ống ngắm 4X", subtitle: "Độ nhạy scope 4X", value: $scope4x)
                            sensitivitySlider(title: "Ống ngắm súng ngắm", subtitle: "Ngắm tầm xa", value: $sniper)
                            sensitivitySlider(title: "Nhìn xung quanh", subtitle: "Quan sát môi trường", value: $freeLook)
                        }.padding(16).panel()
                        Button {
                            // Apply means save this profile locally and copy it for manual entry in-game.
                            UserDefaults.standard.set(clipboardText, forKey: "md_applied_ff_profile_\(selectedGame)")
                            UIPasteboard.general.string = clipboardText
                            copied = true
                            launchGame()
                        } label: {
                            Label("ÁP DỤNG CẤU HÌNH & MỞ GAME", systemImage: "gamecontroller.fill")
                                .font(.system(size: 13, weight: .black)).foregroundStyle(.black).frame(maxWidth: .infinity, minHeight: 50)
                                .background(.cyan, in: RoundedRectangle(cornerRadius: 12))
                        }
                        Button { UIPasteboard.general.string = clipboardText; copied = true } label: {
                            Label(copied ? "ĐÃ SAO CHÉP HỒ SƠ" : "CHỈ SAO CHÉP CẤU HÌNH", systemImage: copied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 11, weight: .bold)).foregroundStyle(.cyan).frame(maxWidth: .infinity, minHeight: 42)
                                .background(.cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                        }
                        if !launchStatus.isEmpty {
                            Text(launchStatus).font(.system(size: 10, weight: .semibold)).foregroundStyle(.cyan)
                        }
                        Text("Ứng dụng lưu hồ sơ và sao chép thông số để bạn nhập trong game, sau đó gửi yêu cầu mở Free Fire bằng URL scheme. iOS không cho app này tự ghi độ nhạy vào dữ liệu riêng của game.").font(.system(size: 10)).foregroundStyle(.white.opacity(0.42))
                    }.padding(18)
                }
            }.navigationTitle("Độ nhạy Free Fire")
        }
    }

    private func applyDeviceRecommendation() {
        let values = DeviceProfileInfo.detect().recommendedValues
        general = values[0]
        redDot = values[1]
        scope2x = values[2]
        scope4x = values[3]
        sniper = values[4]
        freeLook = values[5]
        selectedPreset = "Theo thiết bị"
    }

    private func launchGame() {
        let schemes = selectedGame == "TH"
            ? ["freefireth://"]
            : ["freefirevn://", "freefire://"]
        openGameScheme(schemes, index: 0)
    }

    private func openGameScheme(_ schemes: [String], index: Int) {
        guard index < schemes.count, let url = URL(string: schemes[index]) else {
            launchStatus = "Không mở được game. Hãy kiểm tra game đã cài và thử mở thủ công."
            return
        }
        UIApplication.shared.open(url, options: [:]) { success in
            DispatchQueue.main.async {
                if success {
                    launchStatus = "Đã gửi yêu cầu mở FREE FIRE \(selectedGame). Hồ sơ đã được lưu và sao chép."
                } else {
                    openGameScheme(schemes, index: index + 1)
                }
            }
        }
    }

    private var clipboardText: String {
        """
        MINHDUC AIM SUPPORT PRO — FREE FIRE \(selectedGame)
        Tổng quan: \(Int(general))
        Red Dot: \(Int(redDot))
        Ống ngắm 2X: \(Int(scope2x))
        Ống ngắm 4X: \(Int(scope4x))
        Ống ngắm súng ngắm: \(Int(sniper))
        Nhìn xung quanh: \(Int(freeLook))
        Thang độ nhạy: 0–200
        """
    }

    private func presetButton(_ name: String) -> some View {
        Button {
            selectedPreset = name
            switch name {
            case "Kéo tâm nhẹ": general = 175; redDot = 170; scope2x = 165; scope4x = 155; sniper = 80; freeLook = 140
            case "Headshot": general = 195; redDot = 190; scope2x = 185; scope4x = 175; sniper = 95; freeLook = 160
            case "Nhanh": general = 200; redDot = 195; scope2x = 190; scope4x = 180; sniper = 105; freeLook = 175
            default: general = 185; redDot = 180; scope2x = 175; scope4x = 165; sniper = 90; freeLook = 150
            }
        } label: {
            Text(name).font(.system(size: 11, weight: .bold)).foregroundStyle(selectedPreset == name ? .black : .white)
                .frame(maxWidth: .infinity, minHeight: 38)
                .background(selectedPreset == name ? Color.cyan : Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 9))
        }
    }

    private func sensitivitySlider(title: String, subtitle: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                    Text(subtitle).font(.system(size: 9)).foregroundStyle(.white.opacity(0.45))
                }
                Spacer()
                Text("\(Int(value.wrappedValue))").font(.system(size: 20, weight: .black, design: .rounded)).monospacedDigit().foregroundStyle(.cyan)
            }
            Slider(value: value, in: 0...200, step: 1).tint(.cyan)
            HStack { Text("0"); Spacer(); Text("TỐI ĐA 200") }.font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundStyle(.white.opacity(0.35))
        }
    }
}


// MARK: - Free Fire launcher
struct GameView: View {
    private let games: [GameItem] = [
        .init(name: "FREE FIRE VN", subtitle: "Phiên bản Việt Nam", bundle: "com.garena.ffvn",
              appStore: "https://apps.apple.com/vn/app/id1300146617", schemes: ["freefirevn://", "freefire://"]),
        .init(name: "FREE FIRE TH", subtitle: "Phiên bản TH", bundle: "com.dts.freefireth",
              appStore: "https://apps.apple.com/th/app/id1300146617", schemes: ["freefireth://"])
    ]
    @State private var launchMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground().ignoresSafeArea()
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("CHỌN PHIÊN BẢN FREE FIRE")
                            .font(.system(size: 18, weight: .black)).foregroundStyle(.white)
                        Text("Chọn đúng phiên bản đã cài trên iPhone.")
                            .font(.system(size: 11)).foregroundStyle(.white.opacity(0.5))
                        ForEach(games) { game in
                            VStack(alignment: .leading, spacing: 13) {
                                HStack(spacing: 12) {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 27)).foregroundStyle(.orange)
                                        .frame(width: 54, height: 54)
                                        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 15))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(game.name).font(.system(size: 16, weight: .black)).foregroundStyle(.white)
                                        Text(game.subtitle).font(.system(size: 11)).foregroundStyle(.white.opacity(0.5))
                                    }
                                    Spacer()
                                }
                                Text("Android Package ID: \(game.bundle)")
                                    .font(.system(size: 9, design: .monospaced)).foregroundStyle(.white.opacity(0.45))
                                Button { openGame(game) } label: {
                                    Label("MỞ FREE FIRE", systemImage: "play.fill")
                                        .font(.system(size: 13, weight: .black)).foregroundStyle(.black)
                                        .frame(maxWidth: .infinity, minHeight: 49)
                                        .background(LinearGradient(colors: [.cyan, .mint], startPoint: .leading, endPoint: .trailing),
                                                    in: RoundedRectangle(cornerRadius: 13))
                                }
                                Button {
                                    if let url = URL(string: game.appStore) { UIApplication.shared.open(url) }
                                } label: {
                                    Label("TẢI / XEM TRÊN APP STORE", systemImage: "arrow.up.right.square")
                                        .font(.system(size: 10, weight: .bold)).foregroundStyle(.cyan)
                                        .frame(maxWidth: .infinity, minHeight: 38)
                                        .background(.cyan.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                                }
                            }.padding(17).panel()
                        }
                        if !launchMessage.isEmpty {
                            Text(launchMessage).font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.cyan).padding(12).panel()
                        }
                        Text("Mã package là định danh Android để phân biệt phiên bản. Trên iOS, ứng dụng mở game bằng URL scheme; nếu game không đăng ký scheme đó, hãy dùng App Store hoặc mở game thủ công.")
                            .font(.system(size: 10)).foregroundStyle(.white.opacity(0.42))
                    }.padding(18)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func openGame(_ game: GameItem) {
        tryOpen(game.schemes, index: 0, fallback: game.appStore, title: game.name)
    }

    private func tryOpen(_ schemes: [String], index: Int, fallback: String, title: String) {
        guard index < schemes.count, let url = URL(string: schemes[index]) else {
            launchMessage = "Không mở được \(title). Hãy kiểm tra game đã cài hoặc dùng nút App Store."
            return
        }
        UIApplication.shared.open(url, options: [:]) { success in
            DispatchQueue.main.async {
                if success {
                    launchMessage = "Đã gửi yêu cầu mở \(title)."
                } else if index + 1 < schemes.count {
                    tryOpen(schemes, index: index + 1, fallback: fallback, title: title)
                } else {
                    launchMessage = "Không mở được \(title). Đang mở App Store."
                    if let storeURL = URL(string: fallback) { UIApplication.shared.open(storeURL) }
                }
            }
        }
    }
}

// MARK: - Device configuration optimization
struct DeviceOptimizationView: View {
    @AppStorage("md_config_optimization_enabled") private var enabled = false
    @AppStorage("md_config_focus_enabled") private var focusGuide = true
    @AppStorage("md_config_low_power_checked") private var lowPowerGuide = true
    @AppStorage("md_config_storage_checked") private var storageGuide = true

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground().ignoresSafeArea()
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        header("TỐI ƯU CẤU HÌNH", subtitle: "Bật chế độ hướng dẫn thiết lập iPhone trước khi chơi game.", icon: "slider.horizontal.3")
                        Toggle(isOn: $enabled) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("BẬT TỐI ƯU CẤU HÌNH").font(.system(size: 14, weight: .black)).foregroundStyle(.white)
                                Text(enabled ? "Chế độ hỗ trợ đang bật" : "Chế độ hỗ trợ đang tắt")
                                    .font(.system(size: 10)).foregroundStyle(.white.opacity(0.5))
                            }
                        }.tint(.cyan).padding(16).panel()

                        if enabled {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("CÁC MỤC TỐI ƯU ĐỀ XUẤT")
                                    .font(.system(size: 12, weight: .black)).foregroundStyle(.cyan)
                                Toggle("Bật Tập trung khi chơi game", isOn: $focusGuide).tint(.cyan)
                                Toggle("Kiểm tra Chế độ nguồn điện thấp", isOn: $lowPowerGuide).tint(.cyan)
                                Toggle("Kiểm tra dung lượng trống", isOn: $storageGuide).tint(.cyan)
                                Button { openSettings() } label: {
                                    Label("MỞ CÀI ĐẶT IPHONE", systemImage: "gear")
                                        .font(.system(size: 12, weight: .black)).foregroundStyle(.black)
                                        .frame(maxWidth: .infinity, minHeight: 46)
                                        .background(.cyan, in: RoundedRectangle(cornerRadius: 12))
                                }
                            }.padding(16).panel()
                            Text("Các công tắc này bật/tắt checklist hỗ trợ trong MINHDUC. iOS không cho ứng dụng tự thay đổi các cài đặt hệ thống này.")
                                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.42))
                        } else {
                            Text("Bật công tắc để hiển thị các bước kiểm tra cấu hình thiết bị trước khi chơi.")
                                .font(.system(size: 11)).foregroundStyle(.white.opacity(0.5)).padding(16).panel()
                        }
                    }.padding(18)
                }
            }.navigationBarHidden(true)
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Lag reduction assistance
struct LagReductionView: View {
    @AppStorage("md_lag_mode_enabled") private var enabled = false
    @AppStorage("md_lag_network_checked") private var networkGuide = true
    @AppStorage("md_lag_temperature_checked") private var temperatureGuide = true
    @AppStorage("md_lag_background_checked") private var backgroundGuide = true
    @AppStorage("md_lag_game_checked") private var gameGuide = true

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground().ignoresSafeArea()
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        header("GIẢM LAG MÁY", subtitle: "Bật chế độ hỗ trợ kiểm tra các nguyên nhân gây giật, nóng và mất ổn định.", icon: "bolt.fill")
                        Toggle(isOn: $enabled) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("BẬT GIẢM LAG MÁY").font(.system(size: 14, weight: .black)).foregroundStyle(.white)
                                Text(enabled ? "Chế độ hỗ trợ đang bật" : "Chế độ hỗ trợ đang tắt")
                                    .font(.system(size: 10)).foregroundStyle(.white.opacity(0.5))
                            }
                        }.tint(.cyan).padding(16).panel()
                        if enabled {
                            VStack(alignment: .leading, spacing: 13) {
                                Text("KIỂM TRA TRƯỚC KHI CHƠI")
                                    .font(.system(size: 12, weight: .black)).foregroundStyle(.cyan)
                                Toggle("Kiểm tra kết nối Wi‑Fi / mạng di động", isOn: $networkGuide).tint(.cyan)
                                Toggle("Để thiết bị nguội nếu quá nóng", isOn: $temperatureGuide).tint(.cyan)
                                Toggle("Đóng các tác vụ không cần thiết", isOn: $backgroundGuide).tint(.cyan)
                                Toggle("Dùng cấu hình đồ họa phù hợp trong game", isOn: $gameGuide).tint(.cyan)
                                Button { openSettings() } label: {
                                    Label("MỞ CÀI ĐẶT IPHONE", systemImage: "gear")
                                        .font(.system(size: 12, weight: .black)).foregroundStyle(.black)
                                        .frame(maxWidth: .infinity, minHeight: 46)
                                        .background(.cyan, in: RoundedRectangle(cornerRadius: 12))
                                }
                            }.padding(16).panel()
                            Text("Chế độ này quản lý danh sách hỗ trợ và hướng dẫn. iOS không cho app ép xung CPU/GPU, tự giải phóng RAM hệ thống hoặc đóng ứng dụng khác.")
                                .font(.system(size: 10)).foregroundStyle(.white.opacity(0.42))
                        } else {
                            Text("Bật công tắc để xem checklist giảm lag theo thiết bị.")
                                .font(.system(size: 11)).foregroundStyle(.white.opacity(0.5)).padding(16).panel()
                        }
                    }.padding(18)
                }
            }.navigationBarHidden(true)
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

private func header(_ title: String, subtitle: String, icon: String) -> some View {
    VStack(alignment: .leading, spacing: 9) {
        Image(systemName: icon).font(.system(size: 32, weight: .bold)).foregroundStyle(.cyan)
        Text(title).font(.system(size: 21, weight: .black, design: .rounded)).foregroundStyle(.white)
        Text(subtitle).font(.system(size: 11)).foregroundStyle(.white.opacity(0.55))
    }.padding(17).frame(maxWidth: .infinity, alignment: .leading).panel()
}

// MARK: - Admin
struct AdminView: View {
    @EnvironmentObject private var license: LicenseManager
    @State private var confirmLogout = false
    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        Image("BrandLogo").resizable().scaledToFit()
                            .frame(width: 95, height: 95)
                            .clipShape(RoundedRectangle(cornerRadius: 23))
                        Text("MINHDUC AIM SUPPORT PRO")
                            .font(.system(size: 21, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("AIM SUPPORT • DEVICE TOOLS")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(.yellow)
                        VStack(alignment: .leading, spacing: 12) {
                            Label("TRẠNG THÁI LICENSE", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(.cyan)
                                .font(.system(size: 13, weight: .black))
                            HStack { Text("Tài khoản"); Spacer(); Text(license.isActive ? "Đã kích hoạt" : "Chưa kích hoạt").foregroundStyle(.green) }
                            if let expiry = license.expiresAt { HStack { Text("Hết hạn"); Spacer(); Text(expiry) } }
                            if let msg = license.message { Text(msg).font(.system(size: 11)).foregroundStyle(.white.opacity(0.55)) }
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(17).panel()
                        Button(role: .destructive) { confirmLogout = true } label: {
                            Label("ĐĂNG XUẤT / XOÁ KEY", systemImage: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .background(.red.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
                        }
                        Text("Quản lý License phải thực hiện trên server. Không nhúng ADMIN_SECRET vào app.")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.42))
                    }.padding(20)
                }
            }
            .navigationTitle("Admin")
            .confirmationDialog("Bạn muốn đăng xuất?", isPresented: $confirmLogout, titleVisibility: .visible) {
                Button("Đăng xuất và xoá key", role: .destructive) { license.logout() }
                Button("Huỷ", role: .cancel) {}
            }
        }
    }
}


// MARK: - Performance support (safe iOS settings guidance)
struct PerformanceView: View {
    private let tips: [(String, String, String)] = [
        ("thermometer.medium", "Giữ nhiệt độ ổn định", "Tránh vừa sạc vừa chơi trong thời gian dài; để máy nguội nếu nóng."),
        ("battery.100percent", "Kiểm tra pin", "Tắt Chế độ nguồn điện thấp khi cần hiệu năng ổn định."),
        ("wifi", "Ổn định kết nối", "Dùng Wi‑Fi ổn định, đứng gần router và hạn chế tải nền."),
        ("moon.fill", "Tập trung khi chơi", "Bật chế độ Tập trung để giảm thông báo làm gián đoạn."),
        ("internaldrive", "Giữ bộ nhớ trống", "Duy trì dung lượng trống phù hợp để iOS hoạt động ổn định.")
    ]
    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("TỐI ƯU TRẢI NGHIỆM").font(.system(size: 20, weight: .black)).foregroundStyle(.white)
                        Text("Các bước hỗ trợ giảm tình trạng giật, nóng máy và gián đoạn khi chơi game. Đây là hướng dẫn an toàn, không ép xung CPU/GPU.")
                            .font(.system(size: 12)).foregroundStyle(.white.opacity(0.55))
                        ForEach(tips.indices, id: \.self) { index in
                            let item = tips[index]
                            TipRow(icon: item.0, title: item.1, detail: item.2)
                                .padding(15).panel()
                        }
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Label("MỞ CÀI ĐẶT IPHONE", systemImage: "gearshape.fill")
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(.black).frame(maxWidth: .infinity, minHeight: 48)
                                .background(.cyan, in: RoundedRectangle(cornerRadius: 12))
                        }
                        Text("Ứng dụng không thể tự tăng FPS, thay đổi xung nhịp, nhiệt độ hoặc ping của game khác.")
                            .font(.system(size: 10)).foregroundStyle(.white.opacity(0.4))
                    }.padding(18)
                }
            }.navigationTitle("Mượt máy • Fix lag")
        }
    }
}

// MARK: - App storage cleaner (only this app's cache)
struct CleanerView: View {
    @State private var cacheBytes: Int64 = 0
    @State private var status = "Chỉ dọn bộ nhớ đệm của MINHDUC AIM SUPPORT PRO."
    @State private var showConfirm = false

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                VStack(spacing: 18) {
                    Image(systemName: "trash.circle.fill").font(.system(size: 58)).foregroundStyle(.cyan)
                    Text("DỌN DẸP BỘ NHỚ ĐỆM").font(.system(size: 19, weight: .black)).foregroundStyle(.white)
                    VStack(spacing: 6) {
                        Text(ByteCountFormatter.string(fromByteCount: cacheBytes, countStyle: .file))
                            .font(.system(size: 30, weight: .black, design: .rounded)).foregroundStyle(.cyan)
                        Text("Dung lượng cache của ứng dụng").font(.system(size: 11)).foregroundStyle(.white.opacity(0.5))
                    }.frame(maxWidth: .infinity).padding(20).panel()
                    Button { showConfirm = true } label: {
                        Label("DỌN CACHE ỨNG DỤNG", systemImage: "sparkles")
                            .font(.system(size: 13, weight: .black)).foregroundStyle(.black)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(.cyan, in: RoundedRectangle(cornerRadius: 12))
                    }
                    Text(status).font(.system(size: 11)).foregroundStyle(.white.opacity(0.6)).multilineTextAlignment(.center)
                    Text("iOS không cho ứng dụng xóa dữ liệu hoặc cache của ứng dụng khác. Ảnh, video và tệp cá nhân không bị xóa.")
                        .font(.system(size: 10)).foregroundStyle(.white.opacity(0.4)).multilineTextAlignment(.center)
                    Spacer()
                }.padding(20)
            }
            .navigationTitle("Dọn rác")
            .onAppear { refreshSize() }
            .confirmationDialog("Xóa cache của ứng dụng này?", isPresented: $showConfirm, titleVisibility: .visible) {
                Button("Xóa cache", role: .destructive) { clearCache() }
                Button("Hủy", role: .cancel) {}
            }
        }
    }

    private func refreshSize() {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheBytes = urls.first.map(folderSize) ?? 0
    }
    private func folderSize(_ url: URL) -> Int64 {
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var total: Int64 = 0
        for case let file as URL in enumerator {
            total += Int64((try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
        return total
    }
    private func clearCache() {
        let manager = FileManager.default
        let urls = manager.urls(for: .cachesDirectory, in: .userDomainMask)
        do {
            if let cache = urls.first {
                for item in try manager.contentsOfDirectory(at: cache, includingPropertiesForKeys: nil) {
                    try manager.removeItem(at: item)
                }
            }
            status = "Đã dọn cache của ứng dụng."
        } catch {
            status = "Không thể dọn một số tệp cache: \(error.localizedDescription)"
        }
        refreshSize()
    }
}

// MARK: - Models & helpers
private struct GameItem: Identifiable {
    var id: String { bundle }
    let name: String
    let subtitle: String
    let bundle: String
    let appStore: String
    let schemes: [String]
}

private struct StatCard: View {
    let title: String; let value: String; let icon: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).foregroundStyle(.cyan)
            Text(value).font(.system(size: 17, weight: .black, design: .rounded)).foregroundStyle(.white)
            Text(title).font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(.white.opacity(0.4))
        }.frame(maxWidth: .infinity, alignment: .leading).padding(15).panel()
    }
}

private struct MiniStat: View {
    let title: String; let value: String; let color: Color
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 18, weight: .black, design: .rounded)).foregroundStyle(color)
            Text(title).font(.system(size: 8, weight: .bold, design: .monospaced)).foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct TipRow: View {
    let icon: String; let title: String; let detail: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).foregroundStyle(.cyan).frame(width: 23)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                Text(detail).font(.system(size: 11)).foregroundStyle(.white.opacity(0.55))
            }
        }
    }
}

private struct AppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.015, green: 0.025, blue: 0.05), .black], startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle().fill(.cyan.opacity(0.08)).frame(width: 260).blur(radius: 70).offset(x: 150, y: -300)
        }.ignoresSafeArea()
    }
}

private extension View {
    func panel() -> some View {
        background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.09)))
    }
}
