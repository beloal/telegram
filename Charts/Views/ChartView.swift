import UIKit

let kAnimationDuration = 0.1

class ChartView: UIView {
  let chartsContainerView = UIView()
  let chartPreviewView = ChartPreviewView()
  let yAxisView = ChartYAxisView()
  let xAxisView = ChartXAxisView()
  let chartInfoView = ChartInfoView()
  var lineViews: [ChartLineView] = []

  var lowerBound = 0
  var upperBound = 0

  private(set) var linesVisibility: [Bool] = []

  var chartData: IChartData! {
    didSet {
      yAxisView.frame = chartsContainerView.bounds
      yAxisView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      yAxisView.transform = CGAffineTransform.identity.scaledBy(x: 1, y: -1)
      chartsContainerView.addSubview(yAxisView)
      
      linesVisibility = Array(repeating: true, count: chartData.lines.count)

      var lower = Int.max
      var upper = Int.min
      for line in chartData.lines {
        lower = min(line.minY, lower)
        upper = max(line.maxY, upper)
        let v = ChartLineView()
        v.chartLine = line
        v.lineWidth = 2
        lineViews.append(v)
        v.frame = chartsContainerView.bounds
        v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        chartsContainerView.addSubview(v)
      }

      chartInfoView.frame = chartsContainerView.bounds
      chartInfoView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      chartInfoView.delegate = self
      chartsContainerView.addSubview(chartInfoView)

      let step = (upper - lower) / 6 + 1
      upper = lower + step * 6
      var steps: [Int] = []
      for i in 0..<6 {
        steps.append(lower + step * i)
      }

      yAxisView.setBounds(lower: lower, upper: upper, steps: steps)
      xAxisView.values = chartData.xAxis
      xAxisView.setBounds(lower: 0, upper: chartData.xAxis.count - 1)

      lowerBound = lower
      upperBound = upper
      lineViews.forEach { $0.setY(min: lower, max: upper) }
      chartPreviewView.chartData = chartData
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }

  private func setup() {
    addSubview(chartsContainerView)
    chartsContainerView.clipsToBounds = true

    addSubview(chartPreviewView)
    chartPreviewView.delegate = self

    addSubview(xAxisView)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    let chartsFrame = CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: bounds.height - 70)
    chartsContainerView.frame = chartsFrame

    let xAxisFrame = CGRect(x: bounds.minX, y: bounds.height - 70, width: bounds.width, height: CGFloat(70 - 44))
    xAxisView.frame = xAxisFrame

    let previewFrame = CGRect(x: bounds.minX, y: bounds.height - 44, width: bounds.width, height: 44)
    chartPreviewView.frame = previewFrame
  }

  func setLineVisible(_ visible: Bool, atIndex index: Int) {
    assert(index < linesVisibility.count)
    guard visible != linesVisibility[index] else { return }

    if !visible {
      let visibleCount = linesVisibility.reduce(into: 0) { (r, b) in
        if b { r += 1 }
      }
      if visibleCount == 1  { return }
    }

    linesVisibility[index] = visible
    var lower = Int.max

    for i in 0..<chartData.lines.count {
      guard linesVisibility[i] else { continue }
      let line = chartData.lines[i]
      lower = min(line.minY, lower)
    }

    lowerBound = lower
    chartPreviewView.setLineVisible(visible, atIndex: index)
    chartPreviewView(chartPreviewView, didChangeMinX: xAxisView.lowerBound, maxX: xAxisView.upperBound)

    let lv = lineViews[index]
    UIView.animate(withDuration: kAnimationDuration) {
      lv.alpha = visible ? 1 : 0
    }
  }
}

extension ChartView: ChartPreviewViewDelegate {
  func chartPreviewView(_ view: ChartPreviewView, didChangeMinX minX: Int, maxX: Int) {
    var upper = Int.min

    for i in 0..<chartData.lines.count {
      guard linesVisibility[i] else { continue }
      let line = chartData.lines[i]
      let subrange = line.values[minX..<maxX]
      subrange.forEach { upper = max($0, upper) }
    }

    let step = (upper - lowerBound) / 6 + 1
    upper = lowerBound + step * 6
    var steps: [Int] = []
    for i in 0..<6 {
      steps.append(lowerBound + step * i)
    }

    if (yAxisView.upperBound != upper) {
      yAxisView.setBounds(lower: lowerBound, upper: upper, steps: steps)
    }
    xAxisView.setBounds(lower: minX, upper: maxX)

    lineViews.forEach { $0.setX(min: minX, max: maxX, animated: true) }
    lineViews.forEach { $0.setY(min: lowerBound, max: upper, animated: true)}
  }
}

extension ChartView: ChartInfoViewDelegate {
  func chartInfoView(_ view: ChartInfoView, infoAtPointX pointX: CGFloat) -> (Date, [ChartLineInfo])? {
    let p = convert(CGPoint(x: pointX, y: 0), from: view)
    let x = Int(round((p.x / bounds.width) * CGFloat(xAxisView.upperBound - xAxisView.lowerBound))) + xAxisView.lowerBound
    let px = CGFloat(x - xAxisView.lowerBound) / CGFloat(xAxisView.upperBound - xAxisView.lowerBound) * bounds.width
    guard x < chartData.xAxis.count && x >= 0 else { return nil }
    let date = chartData.xAxis[x]

    var result: [ChartLineInfo] = []
    for i in 0..<chartData.lines.count {
      guard linesVisibility[i] else { continue }
      let line = chartData.lines[i]
      let y = line.values[x]
      let py = chartsContainerView.bounds.height * CGFloat(y - yAxisView.lowerBound) / CGFloat(yAxisView.upperBound - yAxisView.lowerBound)
      result.append(ChartLineInfo(name: line.name,
                                  color: line.color,
                                  point: convert(CGPoint(x: px, y: py), to: view),
                                  value: line.values[x]))
    }

    return (date, result)
  }


}
