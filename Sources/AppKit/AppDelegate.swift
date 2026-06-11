/**
 @SkillID QuickNavAppDelegate
 @Description QuickNav 的 AppKit 生命周期入口，只负责单实例保护和把启动/退出转交给应用协调器。
 @Capabilities 响应 NSApplicationDelegate 生命周期、维护进程级文件锁、持有 QuickNavApplicationCoordinator。
 @LastUpdatedBy Codex
 */
import AppKit
import Darwin
import os

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    // 应用级日志，主要用于记录重复实例启动等生命周期事件。
    private let logger = Logger(subsystem: "QuickNav", category: "App")

    // Coordinator 类似前端应用里的 composition root：集中装配 store、服务和控制器。
    private var coordinator: QuickNavApplicationCoordinator?

    // SwiftPM 和 Xcode 都能直接启动 QuickNav。这里用进程级文件锁避免多个实例同时常驻菜单栏。
    private var instanceLockFileDescriptor: CInt = -1

    public override init() {
        super.init()
    }

    /**
     @name applicationDidFinishLaunching
     @description 应用启动完成后只处理单实例保护，再把业务对象装配交给 QuickNavApplicationCoordinator。
     */
    public func applicationDidFinishLaunching(_ notification: Notification) {
        guard acquireSingleInstanceLock() else {
            logger.info("Another QuickNav instance is already running. Terminating duplicate instance.")
            NSApp.terminate(nil)
            return
        }

        let coordinator = QuickNavApplicationCoordinator()
        self.coordinator = coordinator
        coordinator.start()
    }

    /**
     @name applicationWillTerminate
     @description 应用退出前释放系统级资源；Coordinator 负责 Carbon hotkey，AppDelegate 负责文件锁。
     */
    public func applicationWillTerminate(_ notification: Notification) {
        coordinator?.stop()
        releaseSingleInstanceLock()
    }

    /**
     @name acquireSingleInstanceLock
     @description 通过 Application Support 下的 flock 文件锁保证同一用户会话中只运行一个 QuickNav 实例。
     @discussion Xcode 调试和 swift run 可能同时启动不同路径的 QuickNav 二进制，单靠 bundle identifier 不稳定。
     */
    private func acquireSingleInstanceLock() -> Bool {
        let fileManager = FileManager.default

        guard let supportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return true
        }

        let quickNavDirectory = supportDirectory.appendingPathComponent("QuickNav", isDirectory: true)
        try? fileManager.createDirectory(at: quickNavDirectory, withIntermediateDirectories: true)

        let lockURL = quickNavDirectory.appendingPathComponent("quicknav.lock")
        let descriptor = open(lockURL.path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard descriptor >= 0 else {
            return true
        }

        guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
            close(descriptor)
            return false
        }

        instanceLockFileDescriptor = descriptor
        ftruncate(descriptor, 0)

        let pidText = "\(getpid())\n"
        pidText.withCString { pointer in
            _ = write(descriptor, pointer, strlen(pointer))
        }

        return true
    }

    /**
     @name releaseSingleInstanceLock
     @description 应用退出时释放单实例文件锁，避免影响下一次正常启动。
     */
    private func releaseSingleInstanceLock() {
        guard instanceLockFileDescriptor >= 0 else {
            return
        }

        flock(instanceLockFileDescriptor, LOCK_UN)
        close(instanceLockFileDescriptor)
        instanceLockFileDescriptor = -1
    }
}
