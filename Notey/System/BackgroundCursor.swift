import AppKit

enum BackgroundCursor {

    private typealias MainConnection = @convention(c) () -> Int32
    private typealias SetProperty = @convention(c) (Int32, Int32, CFString, CFTypeRef) -> Int32

    @MainActor
    static func enable() {
        let paths = [
            "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight",
            "/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics"
        ]
        for path in paths {
            guard let handle = dlopen(path, RTLD_LAZY),
                  let mainSymbol = dlsym(handle, "CGSMainConnectionID"),
                  let setSymbol = dlsym(handle, "CGSSetConnectionProperty") else { continue }

            let mainConnection = unsafeBitCast(mainSymbol, to: MainConnection.self)
            let setProperty = unsafeBitCast(setSymbol, to: SetProperty.self)
            let connection = mainConnection()
            _ = setProperty(connection, connection, "SetsCursorInBackground" as CFString, kCFBooleanTrue)
            return
        }
    }
}
