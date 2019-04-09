import Foundation

protocol ITheme {

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

}

struct NightTheme: ITheme {

}
