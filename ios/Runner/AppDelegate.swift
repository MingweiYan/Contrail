import Flutter
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 注册后台任务（BGProcessingTask）。identifier 必须与 Info.plist 中
    // BGTaskSchedulerPermittedIdentifiers 以及 Dart 侧 AutoBackupScheduler.uniqueTaskName 保持一致。
    WorkmanagerPlugin.registerBGProcessingTask(withIdentifier: "contrail_auto_backup_periodic")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
