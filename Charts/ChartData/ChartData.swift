import UIKit

enum ChartType {
  case regular
  case yScaled
  case stacked
  case percentage
}

enum ChartLineType: String {
  case line = "line"
  case bar = "bar"
  case area = "area"
}

protocol IChartData {
  var xAxisLabels: [String] { get }
  var xAxisDates: [Date] { get }
  var lines: [IChartLine] { get }
  var type: ChartType { get }
}

protocol IChartLine {
  var values: [Int] { get }
  var name: String { get }
  var color: UIColor { get }
  var type: ChartLineType { get }
}
