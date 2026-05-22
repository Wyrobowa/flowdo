import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Match the Flutter scaffold background so there is no white flash on launch.
    self.backgroundColor = NSColor(red: 0.973, green: 0.973, blue: 0.973, alpha: 1)

    super.awakeFromNib()
  }
}
