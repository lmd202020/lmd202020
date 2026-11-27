import SwiftUI
import UIKit

// MARK: - Main
struct MainView: View {
    @State private var tab = 0
    var body: some View {
        TabView(selection: $tab) {
            HomeView().tabItem { Label("Trang chủ", systemImage: "house.fill") }.tag(0)
            CrosshairTrainerView().tabItem { Label("Luyện tâm", systemImage: "scope") }.tag(1)
            SensitivityView().tabItem { Label("Độ nhạy", systemImage: "slider.horizontal.3") }.tag(2)
            PerformanceView().tabItem { Label("Tối ưu", systemImage: "speedometer") }.tag(3)
            CleanerView().tabItem { Label("Dọn dẹp", systemImage: "trash") }.tag(4)
            GameView().tabItem { Label("Game", systemImage: "gamecontroller.fill") }.tag(5)
            AdminView().tabItem { Label("Cài đặt", systemImage: "gearshape.fill") }.tag(6)
        }.tint(.cyan)
    }
}

// MARK: - Home
struct HomeView: View {
    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("MINHDUC AIM SUPPORT PRO")
                                    .font(.system(size: 23, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                Text("AIM TRAINER • DEVICE CARE")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.cyan)
                            }
                            Spacer()
                            Image("BrandLogo").resizable().scaledToFit()
                                .frame(width: 55, height: 55)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        HStack(spacing: 12) {
                            StatCard(title: "CHẾ ĐỘ", value: "GAMING", icon: "gamecontroller.fill")
                            StatCard(title: "LUYỆN TẬP", value: "AIM", icon: "scope")
                        }
                        VStack(alignment: .leading, spacing: 12) {
                            Label("TỐI ƯU TRƯỚC KHI CHƠI", systemImage: "sparkles")
                                .font(.system(size: 14, weight: .black))
                                .foregroundStyle(.cyan)
                            TipRow(icon: "battery.100percent", title: "Pin", detail: "Tắt Chế độ nguồn điện thấp để tránh giới hạn hiệu năng.")
                            TipRow(icon: "thermometer.medium", title: "Nhiệt độ", detail: "Để máy nguội; tháo ốp nếu thiết bị quá nóng.")
                            TipRow(icon: "wifi", title: "Kết nối", detail: "Ưu tiên Wi‑Fi ổn định hoặc mạng di động có tín hiệu tốt.")
                            TipRow(icon: "bell.slash", title: "Thông báo", detail: "Bật chế độ Tập trung khi chơi game trong Cài đặt iOS.")
                            TipRow(icon: "internaldrive", title: "Dung lượng", detail: "Giữ đủ dung lượng trống và đóng tác vụ không cần thiết.")
                        }.padding(18).panel()
                        Text("Giới hạn iOS: ứng dụng không thể vẽ đè hay can thiệp vào game khác. Trang 'Kéo Tâm' là công cụ luyện tập trong app.")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.45))
                    }.padding(18)
                }
            }
        }
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

    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("FREE FIRE • SENSITIVITY").font(.system(size: 19, weight: .black, design: .rounded)).foregroundStyle(.white)
                            Text("Tùy chỉnh hồ sơ độ nhạy theo thang 0–200").font(.system(size: 12, weight: .medium)).foregroundStyle(.cyan)
                            Text("Giá trị được lưu trên iPhone để bạn tham khảo và nhập thủ công trong game.").font(.system(size: 10)).foregroundStyle(.white.opacity(0.5))
                        }
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
                        Button { UIPasteboard.general.string = clipboardText; copied = true } label: {
                            Label(copied ? "ĐÃ SAO CHÉP HỒ SƠ" : "SAO CHÉP ĐỘ NHẠY", systemImage: copied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 13, weight: .black)).foregroundStyle(.black).frame(maxWidth: .infinity, minHeight: 48)
                                .background(.cyan, in: RoundedRectangle(cornerRadius: 12))
                        }
                        Text("Preset là giá trị tham khảo; hiệu quả tùy thiết bị và thói quen chơi. Ứng dụng không tự ghi cấu hình vào Free Fire.").font(.system(size: 10)).foregroundStyle(.white.opacity(0.42))
                    }.padding(18)
                }
            }.navigationTitle("Độ nhạy Free Fire")
        }
    }

    private var clipboardText: String {
        """
        MINHDUC AIM SUPPORT PRO — FREE FIRE
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


// MARK: - Game
struct GameView: View {
    private let games: [GameItem] = [
        .init(name: "FREE FIRE VIỆT NAM", subtitle: "Garena Free Fire VN",
              bundle: "com.garena.game.kgvn", appStore: "https://apps.apple.com/vn/app/id1300146617"),
        .init(name: "FREE FIRE THÁI LAN", subtitle: "Garena Free Fire TH",
              bundle: "com.dts.freefireth", appStore: "https://apps.apple.com/th/app/id1300146617")
    ]
    var body: some View {
        NavigationView {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("CHỌN PHIÊN BẢN GAME")
                            .font(.system(size: 17, weight: .black))
                            .foregroundStyle(.white)
                        ForEach(games) { game in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 25))
                                        .foregroundStyle(.orange)
                                        .frame(width: 48, height: 48)
                                        .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(game.name)
                                            .font(.system(size: 14, weight: .black))
                                            .foregroundStyle(.white)
                                        Text(game.subtitle)
                                            .font(.system(size: 11))
                                            .foregroundStyle(.white.opacity(0.5))
                                    }
                                    Spacer()
                                }
                                // Mở App Store (scheme freefirevn:// KHÔNG tồn tại)
                                Button {
                                    if let url = URL(string: game.appStore) {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    Label("MỞ / CÀI GAME", systemImage: "arrow.up.right.square")
                                        .font(.system(size: 13, weight: .black))
                                        .foregroundStyle(.black)
                                        .frame(maxWidth: .infinity, minHeight: 46)
                                        .background(.cyan, in: RoundedRectangle(cornerRadius: 12))
                                }
                                // Mở game nếu đã cài (thử mở qua bundle)
                                Button {
                                    let ok = openApp(bundleID: game.bundle)
                                    if !ok {
                                        if let url = URL(string: game.appStore) {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                } label: {
                                    Label("MỞ GAME ĐÃ CÀI", systemImage: "play.fill")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.cyan)
                                        .frame(maxWidth: .infinity, minHeight: 40)
                                        .background(.cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                                }
                                Text("Bundle ID: \(game.bundle)")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.35))
                            }.padding(16).panel()
                        }
                        Text("iOS không có URL scheme chính thức cho Free Fire. Nút 'Mở game đã cài' chỉ hoạt động nếu bạn đã thêm scheme vào Info.plist; nếu không app sẽ chuyển sang App Store.")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.45))
                    }.padding(18)
                }
            }
            .navigationTitle("Game")
        }
    }

    private func openApp(bundleID: String) -> Bool {
        guard let url = URL(string: "\(bundleID)://") else { return false }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            return true
        }
        return false
    }
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
private struct GameItem: Identifiable { let id = UUID(); let name: String; let subtitle: String; let bundle: String; let appStore: String }

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
