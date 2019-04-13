import UIKit

protocol ChartPresentationDataDelegate: AnyObject {
  func chartPresentationData(_ data: ChartPresentationData, didSetLineVisble visible: Bool, at index: Int)
}

class ChartPresentationData {
  private let chartData: IChartData
  private var presentationLines: [ChartPresentationLine]
  private let pathBuilder = ChartPathBuilder()

  init(_ chartData: IChartData) {
    self.chartData = chartData
    presentationLines = chartData.lines.map { ChartPresentationLine($0) }
    recalcBounds()
  }

  var linesCount: Int { return chartData.lines.count }
  var pointsCount: Int { return chartData.xAxisLabels.count }
  var type: ChartType { return chartData.type }
  var labels: [String] { return chartData.xAxisLabels }
  var lower = Int.max
  var upper = Int.min
  weak var delegate: ChartPresentationDataDelegate?

  func labelAt(_ point: Int) -> String {
    return chartData.xAxisLabels[point]
  }

  func dateAt(_ point: Int) -> Date {
    return chartData.xAxisDates[point]
  }

  func isLineVisibleAt(_ index: Int) -> Bool {
    return presentationLines[index].isVisible
  }

  func setLineVisible(_ visible: Bool, at index: Int) {
    if !visible {
      let visibleCount = presentationLines.reduce(into: 0) { (r, b) in if b.isVisible { r += 1 } }
      if visibleCount == 1 { return }
    }
    presentationLines[index].isVisible = visible
    recalcBounds()
    delegate?.chartPresentationData(self, didSetLineVisble: visible, at: index)
  }

  func lineAt(_ index: Int) -> ChartPresentationLine {
    return presentationLines[index]
  }

  private func recalcBounds() {
    let visibleLines = presentationLines.filter { $0.isVisible }
    presentationLines.forEach { $0.aggregatedValues = [] }
    pathBuilder.build(presentationLines, type: type)

    var l = Int.max
    var u = Int.min
    visibleLines.forEach {
      l = min($0.minY, l)
      u = max($0.maxY, u)
    }
    lower = l
    upper = u
  }
}

class ChartPresentationLine {
  private let chartLine: IChartLine

  var isVisible = true
  var aggregatedValues: [Int] = []
  var minY: Int = Int.max
  var maxY: Int = Int.min
  var path = UIBezierPath()

  var values: [Int] { return chartLine.values }
  var color: UIColor { return chartLine.color }
  var name: String { return chartLine.name }
  var type: ChartLineType { return chartLine.type }

  init(_ chartLine: IChartLine) {
    self.chartLine = chartLine
//    for val in chartLine.values {
//      if val < minY { minY = val }
//      if val > maxY { maxY = val }
//    }
//    self.p = makePath()
  }
}

protocol IChartPathBuilder {
  func build(_ lines: [ChartPresentationLine])
}

class ChartPathBuilder {
  private let builders: [ChartType: IChartPathBuilder] = [
    .regular : LinePathBuilder(),
    .yScaled : YScaledPathBuilder(),
    .stacked : StackedPathBuilder(),
    .percentage : LinePathBuilder()
  ]

  func build(_ lines: [ChartPresentationLine], type: ChartType) {
    builders[type]?.build(lines)
  }
}

class LinePathBuilder: IChartPathBuilder {
  func build(_ lines: [ChartPresentationLine]) {
    lines.forEach {
      $0.path = makePath(line: $0)
      $0.aggregatedValues = $0.values
    }
  }

  private func makePath(line: ChartPresentationLine) -> UIBezierPath {
    let path = UIBezierPath()
    let values = line.values
    for val in values {
      if val < line.minY { line.minY = val }
      if val > line.maxY { line.maxY = val }
    }
    for i in 0..<values.count {
      let x = CGFloat(i)
      let y = CGFloat(values[i] - line.minY)
      if i == 0 {
        path.move(to: CGPoint(x: x, y: y))
      } else {
        path.addLine(to: CGPoint(x: x, y: y))
      }
    }
    return path
  }
}

class YScaledPathBuilder: IChartPathBuilder {
  func build(_ lines: [ChartPresentationLine]) {
    lines.forEach {
      $0.path = makePath(line: $0)
      $0.aggregatedValues = $0.values
    }
  }

  private func makePath(line: ChartPresentationLine) -> UIBezierPath {
    let path = UIBezierPath()
    let values = line.values
    for val in values {
      if val < line.minY { line.minY = val }
      if val > line.maxY { line.maxY = val }
    }
    for i in 0..<values.count {
      let x = CGFloat(i)
      let y = CGFloat(values[i] - line.minY)
      if i == 0 {
        path.move(to: CGPoint(x: x, y: y))
      } else {
        path.addLine(to: CGPoint(x: x, y: y))
      }
    }
    return path
  }
}

class StackedPathBuilder: IChartPathBuilder {
  func build(_ lines: [ChartPresentationLine]) {
    var prevVisibleLine: ChartPresentationLine? = nil
    for i in 0..<lines.count {
      let line = lines[i]
      var u = Int.min
      for i in 0..<line.values.count {
        let dy = prevVisibleLine?.aggregatedValues[i] ?? 0
        let v = line.values[i] + dy
        line.aggregatedValues.append(v)
        u = max(u, v)
      }
      line.minY = 0
      line.maxY = u
      line.path = makeBarPath(line: line, bottomLine: prevVisibleLine)
      if line.isVisible { prevVisibleLine = line }
    }
  }

  private func makeBarPath(line: ChartPresentationLine, bottomLine: ChartPresentationLine?) -> UIBezierPath {
    let path = UIBezierPath()
    path.move(to: CGPoint(x: 0, y: 0))
    if !line.isVisible {
      guard let bl = bottomLine else {
        line.path.apply(CGAffineTransform.identity.scaledBy(x: 1, y: 0))
        return line.path
      }
      return bl.path
    }

    let aggregatedValues = line.aggregatedValues
    for i in 0..<aggregatedValues.count {
      let x = CGFloat(i)
      let y = CGFloat(aggregatedValues[i] - line.minY)
      path.addLine(to: CGPoint(x: x, y: y))
      path.addLine(to: CGPoint(x: x + 1, y: y))
    }
    path.addLine(to: CGPoint(x: aggregatedValues.count, y: 0))
    path.close()
    return path
  }
}

class PercentagePathBuilder: IChartPathBuilder {
  func build(_ lines: [ChartPresentationLine]) {
    
  }
}
