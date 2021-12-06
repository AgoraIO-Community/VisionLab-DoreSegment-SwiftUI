//
//  ContentView.swift
//  VisionLab-DoreSegment-SwiftUI
//
//  Created by Max Cobb on 06/12/2021.
//

import SwiftUI
import AgoraRtcKit
import AgoraUIKit_iOS

extension ForEach where Data.Element: Hashable, ID == Data.Element, Content: View {
    init(values: Data, content: @escaping (Data.Element) -> Content) {
        self.init(values, id: \.self, content: content)
    }
}

class AgoraViewerHelper: AgoraVideoViewerDelegate {
    static var agview: AgoraViewer = {
        var agSettings = AgoraSettings()
        agSettings.videoConfiguration = .init(size: CGSize(width: 480, height: 360), frameRate: .fps24, bitrate: AgoraVideoBitrateStandard, orientationMode: .fixedPortrait, mirrorMode: .auto)
        return AgoraViewer(
            connectionData: AgoraConnectionData(
                appId: AppKeys.agoraAppId, rtcToken: AppKeys.agoraToken
            ),
            style: .floating,
            agoraSettings: agSettings,
            delegate: AgoraViewerHelper.delegate
        )
    }()
    static var delegate = AgoraViewerHelper()
    func extraButtons() -> [UIButton] {
        let button = UIButton()
        button.setImage(UIImage(
            systemName: "wand.and.stars",
            withConfiguration: UIImage.SymbolConfiguration(scale: .large)
        ), for: .normal)
        button.isSelected = self.virtualBackgroundEnabled
        button.backgroundColor = self.virtualBackgroundEnabled ? .systemGreen : .systemGray
        button.addTarget(self, action: #selector(self.toggleBackground), for: .touchUpInside)
        return [button]
    }

    func registerDoreSegment() {
        // Set API Credentials
        let doreCredentials: [String: String] = [
            "apiKey": AppKeys.visionLabApiKey,
            "license": AppKeys.visionLabApiSecret
        ]
        AgoraViewerHelper.agview.viewer.setExtensionProperty(
            "DoreAI", extension: "DoreSegment", key: "start", codable: doreCredentials
        )
    }

    func joinedChannel(channel: String) {
        registerDoreSegment()
        AgoraViewerHelper.agview.viewer.enableExtension(
            withVendor: "DoreAI", extension: "DoreSegment", enabled: false
        )
    }
    var virtualBackgroundEnabled: Bool = false

    @objc func toggleBackground(_ sender: UIButton) {
        virtualBackgroundEnabled.toggle()
        sender.backgroundColor = self.virtualBackgroundEnabled ? .systemGreen : .systemGray
        if self.virtualBackgroundEnabled {
            let backgroundImg = UIImage(named: "background-boat")
            guard let base64Img = backgroundImg?.pngData()?.base64EncodedString() else {
                fatalError("Background image not found in bundle")
            }
            AgoraViewerHelper.agview.viewer.setExtensionProperty("DoreAI", extension: "DoreSegment", key: "bgImage", value: base64Img)
        }
        AgoraViewerHelper.agview.viewer.enableExtension(
            withVendor: "DoreAI", extension: "DoreSegment", enabled: self.virtualBackgroundEnabled
        )
     }
}


struct ContentView: View {
    @State var joinedChannel: Bool = false

    var body: some View {
        ZStack {
            AgoraViewerHelper.agview
            if !joinedChannel {
                Button("Join Channel") {
                    self.joinChannel()
                }
            }
        }
    }

    func joinChannel() {
        self.joinedChannel = true
        AgoraViewerHelper.agview.viewer.enableExtension(
            withVendor: "DoreAI", extension: "DoreSegment", enabled: true
        )
        AgoraViewerHelper.agview.join(
            channel: "test", with: AppKeys.agoraToken,
            as: .broadcaster
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
