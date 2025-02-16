import UIKit
import Flutter
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
    var videoPlayer: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var videoWindow: UIWindow?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        let controller = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "audio_processor", binaryMessenger: controller.binaryMessenger)
        
        channel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            if call.method == "Slow" || call.method == "NotSlow" {
                guard let args = call.arguments as? [String: Any],
                      let videoPath = args["videoPath"] as? String,
                      let speed = args["speed"] as? Float,
                      let x = args["x"] as? CGFloat,
                      let y = args["y"] as? CGFloat,
                      let width = args["width"] as? CGFloat,
                      let height = args["height"] as? CGFloat else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                    return
                }
                self.playVideoWithLayer(mode: call.method, videoPath: videoPath, speed: speed, x: x, y: y, width: width, height: height, result: result)
            } else if call.method == "Stop" {
                self.stopVideo(result: result)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func playVideoWithLayer(mode: String, videoPath: String, speed: Float, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            var filePath = videoPath
            if let resourcePath = Bundle.main.path(forResource: videoPath, ofType: nil) {
                filePath = resourcePath
            }
            
            if !FileManager.default.fileExists(atPath: filePath) {
                result(FlutterError(code: "FILE_NOT_FOUND", message: "指定されたファイルが見つかりません", details: nil))
                return
            }
            
            let playerItem = AVPlayerItem(url: URL(fileURLWithPath: filePath))
            self.videoPlayer = AVPlayer(playerItem: playerItem)
            
            if self.videoWindow == nil {
                self.videoWindow = UIWindow(frame: CGRect(x: x, y: y, width: width, height: height))
                self.videoWindow?.backgroundColor = .black
                self.videoWindow?.windowLevel = UIWindow.Level.alert + 1
                self.videoWindow?.isHidden = false
            }
            
            if self.playerLayer == nil {
                self.playerLayer = AVPlayerLayer(player: self.videoPlayer)
                self.playerLayer?.frame = CGRect(x: 0, y: 0, width: width, height: height)
                self.playerLayer?.videoGravity = .resizeAspect
                self.videoWindow?.layer.addSublayer(self.playerLayer!)
            }
            
            if mode == "Slow" {
                self.configureAudioMix(for: self.videoPlayer!, speed: speed)
            }
            
            self.videoPlayer?.playImmediately(atRate: speed)
            result("再生開始")
        }
    }
    
    func stopVideo(result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            self.videoPlayer?.pause()
            self.videoPlayer = nil
            self.playerLayer?.removeFromSuperlayer()
            self.playerLayer = nil
            self.videoWindow?.isHidden = true
            self.videoWindow = nil
            result("停止完了")
        }
    }
    
    private func configureAudioMix(for player: AVPlayer, speed: Float) {
        guard let currentItem = player.currentItem,
              let audioTrack = currentItem.asset.tracks(withMediaType: .audio).first else { return }
        
        let audioMix = AVMutableAudioMix()
        let audioParameters = AVMutableAudioMixInputParameters(track: audioTrack)
        audioParameters.setVolume(1.0, at: .zero)
        
        audioParameters.audioTimePitchAlgorithm = (speed != 1.0) ? .varispeed : .lowQualityZeroLatency
        
        audioMix.inputParameters = [audioParameters]
        DispatchQueue.main.async {
            currentItem.audioMix = audioMix
        }
    }
}
