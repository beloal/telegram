import UIKit

protocol IChartData {
  var xAxisLabels: [String] { get }
  var xAxisDates: [Date] { get }
  var lines: [IChartLine] { get }
}

protocol IChartLine {
  var values: [Int] { get }
  var name: String { get }
  var color: UIColor { get }
  var minY: Int { get }
  var maxY: Int { get }
  var path: UIBezierPath { get }
}
