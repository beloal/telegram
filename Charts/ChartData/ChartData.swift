import UIKit

protocol IChartData {
  var xAxis: [Date] { get }
  var lines: [IChartLine] { get }
}

protocol IChartLine {
  var values: [Int] { get }
  var name: String { get }
  var color: UIColor { get }
}
