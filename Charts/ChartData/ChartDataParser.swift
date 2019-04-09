import UIKit

fileprivate extension UIColor {
  convenience init?(hexString: String) {
    let nsString = hexString as NSString
    let rs = nsString.substring(with: NSMakeRange(1, 2))
    let gs = nsString.substring(with: NSMakeRange(3, 2))
    let bs = nsString.substring(with: NSMakeRange(5, 2))
    guard let r = Int(rs, radix: 16),
      let g = Int(gs, radix: 16),
      let b = Int(bs, radix: 16) else {
        assertionFailure("Wrong color format")
        return nil
    }

    self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
  }
}

fileprivate struct ChartData: IChartData {
  var xAxisLabels: [String]
  var xAxisDates: [Date]
  var lines: [IChartLine]
}

fileprivate struct ChartLine: IChartLine {
  init(values: [Int], name: String, color: UIColor) {
    self.values = values
    self.name = name
    self.color = color
    for val in values {
      if val < minY { minY = val }
      if val > maxY { maxY = val }
    }
    self.path = ChartLine.makePath(values: values, minY: minY)
  }

  private static func makePath(values: [Int], minY: Int) -> UIBezierPath {
    let path = UIBezierPath()
    for i in 0..<values.count {
      let x = CGFloat(i)
      let y = CGFloat(values[i] - minY)
      if i == 0 {
        path.move(to: CGPoint(x: x, y: y))
      } else {
        path.addLine(to: CGPoint(x: x, y: y))
      }
    }
    return path
  }

  var values: [Int]
  var name: String
  var color: UIColor
  var minY: Int = Int.max
  var maxY: Int = Int.min
  var path: UIBezierPath
}

fileprivate struct Column {
  var key: String
  var values: [Int]
}

protocol IChartDataParser {
  func parseData(_ data: Data) -> [IChartData]?
}

class ChartDataJsonParser: IChartDataParser {
  let formatter = DateFormatter()

  init() {
    formatter.dateFormat = "MMM dd"
  }

  func parseData(_ data: Data) -> [IChartData]? {
    guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) else {
      assertionFailure("Can't parse data")
      return nil
    }

    guard let jsonArray = jsonObject as? [Any] else {
      assertionFailure("Wrong data format")
      return nil
    }
    
    var result: [IChartData] = []
    for item in jsonArray {
      guard let chartJson = item as? [String : Any],
        let chartData = parseChartJson(chartJson) else {
        assertionFailure("Wrong data format")
        continue
      }
      result.append(chartData)
    }
    return result.isEmpty ? nil : result
  }

  private func parseChartJson(_ chartJson: [String : Any]) -> IChartData? {
    guard let columnsJson = chartJson["columns"] as? [[Any]],
      let columns = parseColumnsJson(columnsJson) else {
        assertionFailure("Wrong data format")
        return nil
    }

    guard let colors = chartJson["colors"] as? [String : String],
      let names = chartJson["names"] as? [String : String],
      let types = chartJson["types"] as? [String : String] else {
        assertionFailure("Wrong data format")
        return nil
    }

    var x: [String]?
    var xd: [Date]?
    var lines: [ChartLine] = []

    for column in columns {
      guard let type = types[column.key] else {
        assertionFailure("Wrong data format")
        return nil
      }

      switch type {
      case "line":
        guard let name = names[column.key],
          let colorString = colors[column.key],
          let color = UIColor(hexString: colorString) else {
            assertionFailure("Wrong data format")
            return nil
        }
        lines.append(ChartLine(values: column.values, name: name, color: color))
      case "x":
        xd = column.values.map { Date(timeIntervalSince1970: TimeInterval($0 / 1000)) }
        x = xd?.map { formatter.string(from: $0) }
      default:
        assertionFailure("Wrong data format")
        return nil
      }
    }
    guard let xAxisLabels = x, let xAxisDates = xd, lines.count > 0 else {
      assertionFailure("Wrong data format")
      return nil
    }

    return ChartData(xAxisLabels: xAxisLabels, xAxisDates: xAxisDates, lines: lines)
  }

  private func parseColumnsJson(_ columnsJson: [[Any]]) -> [Column]? {
    var result: [Column] = []
    for column in columnsJson {
      guard let key = column[0] as? String,
        let values = Array(column.suffix(from: 1)) as? [Int] else {
        assertionFailure("Wrong data format")
        continue
      }
      result.append(Column(key: key, values: values))
    }
    return result.isEmpty ? nil : result
  }
}
