import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Uygulama başlatıldığında gelen linki işlemek için
    if let url = launchOptions?[.url] as? URL {
      handleDeepLink(url)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // URL işlemi
  private func handleDeepLink(_ url: URL) {
    if url.scheme == "blazesense" && url.host == "reset-password" {
      // Deep link doğruysa yapılacak işlem
      print("Deep Link URL: \(url)")
    }
  }
}
