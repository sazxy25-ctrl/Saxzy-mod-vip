import SwiftUI
import UniformTypeIdentifiers

@main
struct SaxzyModVIPApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

struct ContentView: View {
    @State private var unlocked = UserDefaults.standard.bool(forKey: "saxzy_unlocked")
    @State private var password = ""
    @State private var files: [URL] = []
    @State private var showingImporter = false
    @State private var showingExporter = false
    @State private var selectedFile: URL?
    @State private var notice = "Welcome to Saxzy Mod VIP"

    private let dark = Color(red: 0.025, green: 0.03, blue: 0.07)
    private let cyan = Color(red: 0.55, green: 0.88, blue: 1.0)

    var body: some View {
        ZStack {
            dark.ignoresSafeArea()
            if unlocked { fileHome } else { login }
        }
        .preferredColorScheme(.dark)
        .fileImporter(isPresented: $showingImporter,
                      allowedContentTypes: [.item],
                      allowsMultipleSelection: true) { result in
            switch result {
            case .success(let urls):
                for url in urls {
                    let access = url.startAccessingSecurityScopedResource()
                    defer { if access { url.stopAccessingSecurityScopedResource() } }
                    let destination = FileManager.default.temporaryDirectory
                        .appendingPathComponent(url.lastPathComponent)
                    do {
                        if FileManager.default.fileExists(atPath: destination.path) {
                            try FileManager.default.removeItem(at: destination)
                        }
                        try FileManager.default.copyItem(at: url, to: destination)
                        files.append(destination)
                    } catch { notice = "Could not import \(url.lastPathComponent)" }
                }
                notice = "Imported \(urls.count) file(s)"
            case .failure(let error): notice = error.localizedDescription
            }
        }
        .sheet(item: $selectedFile) { url in
            ShareSheet(url: url)
                .presentationDetents([.medium])
        }
    }

    private var login: some View {
        VStack(spacing: 20) {
            Spacer()
            Image("LaunchLogo").resizable().scaledToFit()
                .frame(width: 210, height: 210).clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(cyan.opacity(0.7), lineWidth: 1))
            Text("SAXZY MOD VIP").font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(.white)
            Text("PERSONAL EDITION").font(.caption).tracking(4).foregroundColor(cyan)
            SecureField("Create a password", text: $password)
                .textInputAutocapitalization(.never).autocorrectionDisabled()
                .padding().background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 32)
            Button("UNLOCK") {
                guard password.count >= 8 else {
                    notice = "Use at least 8 characters"; return
                }
                UserDefaults.standard.set(true, forKey: "saxzy_unlocked")
                password = ""; unlocked = true
            }
            .font(.headline).foregroundColor(dark).padding()
            .frame(maxWidth: .infinity).background(cyan)
            .clipShape(RoundedRectangle(cornerRadius: 12)).padding(.horizontal, 32)
            Text(notice).font(.footnote).foregroundColor(cyan.opacity(0.8))
            Spacer()
            Text("Set your own password on this device.").font(.caption).foregroundColor(.gray)
        }
    }

    private var fileHome: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Image("LaunchLogo").resizable().scaledToFit().frame(width: 54, height: 54)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    VStack(alignment: .leading) {
                        Text("SAXZY MOD VIP").font(.headline).foregroundColor(.white)
                        Text("File Manager · Personal Edition").font(.caption).foregroundColor(cyan)
                    }
                    Spacer()
                    Button { showingImporter = true } label: {
                        Image(systemName: "plus.circle.fill").font(.title).foregroundColor(cyan)
                    }
                }.padding()
                HStack {
                    Text("MY FILES").font(.caption.bold()).tracking(2).foregroundColor(cyan)
                    Spacer()
                    Text("\(files.count) items").font(.caption).foregroundColor(.gray)
                }.padding(.horizontal)
                List {
                    ForEach(files, id: \.self) { url in
                        HStack {
                            Image(systemName: "doc").foregroundColor(cyan)
                            VStack(alignment: .leading) {
                                Text(url.lastPathComponent).foregroundColor(.white)
                                Text(url.pathExtension.isEmpty ? "FILE" : url.pathExtension.uppercased())
                                    .font(.caption2).foregroundColor(.gray)
                            }
                            Spacer()
                            Button { selectedFile = url } label: {
                                Image(systemName: "square.and.arrow.up").foregroundColor(cyan)
                            }
                        }.listRowBackground(Color.white.opacity(0.05))
                    }
                    .onDelete { files.remove(atOffsets: $0) }
                }.scrollContentBackground(.hidden)
                Text(notice).font(.caption).foregroundColor(cyan).padding()
            }
            .background(dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Lock") {
                        UserDefaults.standard.set(false, forKey: "saxzy_unlocked")
                        unlocked = false
                    }.foregroundColor(cyan)
                }
            }
            .navigationBarHidden(true)
        }
        .tint(cyan)
    }
}

extension URL: Identifiable {
    public var id: String { absoluteString }
}

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
