import UIKit

protocol ITheme {
  var white: UIColor { get }
  var black: UIColor { get }
  var previewSelector: UIColor { get }
  var previewTint: UIColor { get }
  var gridLine: UIColor { get }
  var gridText: UIColor { get }
  var barMask: UIColor { get }
  var background: UIColor { get }
  var chartBackground: UIColor { get }
  var barStyle: UIBarStyle { get }
}

struct Theme {
  public static let didChangeThemeNotificationName: NSNotification.Name = NSNotification.Name(rawValue: "ThemeDidChange")
  private static let dayTheme = DayTheme()
  private static let nightTheme = NightTheme()
  static var isNightTheme = false {
    didSet {
      NotificationCenter.default.post(name: didChangeThemeNotificationName, object: nil)
    }
  }
  static var currentTheme: ITheme { return isNightTheme ? nightTheme : dayTheme }
}

struct DayTheme: ITheme {
  init() {
    white = UIColor.white
    black = UIColor.black
    previewSelector = UIColor(hexString: "#C0D1E1")!
    previewTint = UIColor(hexString: "#E2EEF9")!.withAlphaComponent(0.6)
    gridLine = UIColor(hexString: "#182D3B")!.withAlphaComponent(0.1)
    gridText = UIColor(hexString: "#8E8E93")!
    barMask = UIColor(white: 1, alpha: 0.5)
    background = UIColor(hexString: "#EFEFF3")!
    chartBackground = UIColor.white
    barStyle = .default
  }

  let white: UIColor
  let black: UIColor
  let previewSelector: UIColor
  let previewTint: UIColor
  let gridLine: UIColor
  let gridText: UIColor
  let barMask: UIColor
  let background: UIColor
  let chartBackground: UIColor
  let barStyle: UIBarStyle
}

struct NightTheme: ITheme {
  init() {
    white = UIColor.black
    black = UIColor.white
    previewSelector = UIColor(hexString: "#56626D")!
    previewTint = UIColor(hexString: "#18222D")!.withAlphaComponent(0.6)
    gridLine = UIColor(hexString: "#BACCE1")!.withAlphaComponent(0.2)
    gridText = UIColor(hexString: "#BACCE1")!
    barMask = UIColor(hexString: "#212F3F")!.withAlphaComponent(0.5)
    background = UIColor(hexString: "#1A222C")!
    chartBackground = UIColor(hexString: "#242F3E")!
    barStyle = .black
  }

  let white: UIColor
  let black: UIColor
  let previewSelector: UIColor
  let previewTint: UIColor
  let gridLine: UIColor
  let gridText: UIColor
  let barMask: UIColor
  let background: UIColor
  let chartBackground: UIColor
  let barStyle: UIBarStyle
}
