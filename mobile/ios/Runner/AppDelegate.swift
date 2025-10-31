import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // 카카오맵 SDK 초기화
    if let kakaoAppKey = Bundle.main.object(forInfoDictionaryKey: "KAKAO_APP_KEY") as? String {
        print("✅ 카카오맵 앱 키 로드 성공: \(kakaoAppKey)")
    } else {
        print("❌ 카카오맵 앱 키 로드 실패")
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
