import UIKit

extension UIColor {
  convenience init?(hexString: String) {
    let nsString = hexString as NSString
    let rs = nsString.substring(with: NSMakeRange(1, 2))
    let gs = nsString.substring(with: NSMakeRange(3, 2))
    let bs = nsString.substring(with: NSMakeRange(5, 2))
    guard let r = Int(rs, radix: 16), let g = Int(gs, radix: 16), let b = Int(bs, radix: 16) else {
        assertionFailure("Wrong color format")
        return nil
    }

    self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
  }
}

fileprivate struct ChartData: IChartData {
  var xAxisLabels: [String]
//  var xAxisDates: [Date]
  var lines: [IChartLine]
  var type: ChartType
}

fileprivate struct ChartLine: IChartLine {
  init(values: [Int], name: String, color: UIColor, type: ChartLineType) {
    self.values = values
    self.name = name
    self.color = color
    self.type = type
  }

  let values: [Int]
  var aggregatedValues: [Int] { return values }
  let name: String
  let color: UIColor
  let type: ChartLineType
}

fileprivate struct Column {
  var key: String
  var values: [Int]
}

protocol IChartDataParser {
  func parseData(_ data: Data) -> [IChartData]?
}

class ChartDataJsonParser: IChartDataParser {
  let formatter: IFormatter

  init(formatter: IFormatter) {
    self.formatter = formatter
//    formatter.dateFormat = "MMM dd"
  }

  func parseData(_ data: Data) -> [IChartData]? {
    guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) else {
      assertionFailure("Can't parse data")
      return nil
    }

    var result: [IChartData] = []
    guard let chartJson = jsonObject as? [String : Any],
      let chartData = parseChartJson(chartJson) else {
      assertionFailure("Wrong data format")
      return nil
    }
    result.append(chartData)
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
    var lines: [IChartLine] = []

    for column in columns {
      guard let type = types[column.key] else {
        assertionFailure("Wrong data format")
        return nil
      }

      switch type {
      case "x":
        x = column.values.map { formatter.string(from: $0 / 1000) }
//        x = xd?.map { formatter.string(from: $0) }
      default:
        guard let name = names[column.key],
          let colorString = colors[column.key],
          let color = UIColor(hexString: colorString),
          let lineType = ChartLineType(rawValue: type) else {
            assertionFailure("Wrong data format")
            return nil
        }
        let line = ChartLine(values: column.values, name: name, color: color, type: lineType)
        lines.append(line)
        if lineType == .line {
          let area = ChartLine(values: column.values, name: name, color: color.withAlphaComponent(0.5), type: .area)
          lines.append(area)
        }
        break
      }
    }
    guard let xAxisLabels = x, lines.count > 0 else {
      assertionFailure("Wrong data format")
      return nil
    }

    var chartType: ChartType = .regular

    if chartJson["y_scaled"] as? Bool ?? false { chartType = .yScaled }
    if chartJson["stacked"] as? Bool ?? false { chartType = .stacked }
    if chartJson["percentage"] as? Bool ?? false { chartType = .percentage }

    return ChartData(xAxisLabels: xAxisLabels,/* xAxisDates: xAxisDates,*/ lines: lines, type: chartType)
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
