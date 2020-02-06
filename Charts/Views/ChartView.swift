import UIKit

let kAnimationDuration = 0.3
let df: DateFormatter = {
  let f = DateFormatter()
  f.dateStyle = .medium
  return f
}()

enum ChartAnimation: TimeInterval {
  case none = 0.0
  case animated = 0.3
  case interactive = 0.1
}

class ChartView: UIView {
  let headerView = ChartHeaderView()
  let chartsContainerView = UIView()
  let chartPreviewView = ChartPreviewView()
  let yAxisLeftView = ChartYAxisView()
  var yAxisRightView = ChartYAxisView()
  let xAxisView = ChartXAxisView()
  let chartInfoView = ChartInfoView()
  var lineViews: [ChartLineView] = []
  let chartSettingsView = ChartSettingsView()
  var maxWidth: CGFloat = 0 {
    didSet {
      chartSettingsView.maxWidth = maxWidth
    }
  }
  var height: CGFloat {
    return 105 + 270 + 16 + chartSettingsView.height
  }

  var previewSelectorColor: UIColor = UIColor.white {
    didSet {
      chartPreviewView.selectorColor = previewSelectorColor
    }
  }

  var previewTintColor: UIColor = UIColor.clear {
    didSet {
      chartPreviewView.selectorTintColor = previewTintColor
    }
  }

  var maskColor: UIColor = UIColor.clear {
    didSet {
      chartInfoView.maskColor = maskColor
    }
  }

  var headerTextColor: UIColor = UIColor.white {
    didSet {
      headerView.datesLabel.textColor = headerTextColor
      chartInfoView.textColor = headerTextColor
    }
  }

  var gridTextColor: UIColor = UIColor(white: 0, alpha: 0.2) {
    didSet {
      xAxisView.gridColor = gridTextColor
      yAxisLeftView.gridColor = gridTextColor
    }
  }

  var gridLineColor: UIColor = UIColor(white: 0, alpha: 0.2) {
    didSet {
      yAxisLeftView.gridLineColor = gridLineColor
    }
  }

  var bgColor: UIColor = UIColor.white {
    didSet {
      chartInfoView.bgColor = bgColor
    }
  }

  weak var headerUpdateTimer: Timer?

  var rasterize = false {
    didSet {
      lineViews.forEach {
        $0.layer.shouldRasterize = rasterize
        $0.layer.rasterizationScale = UIScreen.main.scale
      }
    }
  }

  var chartData: ChartPresentationData! {
    didSet {
      chartData.delegate = self
      lineViews.forEach { $0.removeFromSuperview() }
      lineViews.removeAll()
      for i in (0..<chartData.linesCount).reversed() {
        let line = chartData.lineAt(i)
        let v = ChartLineView()
        v.clipsToBounds = true
        v.chartLine = line
        v.lineWidth = 2
        v.frame = chartsContainerView.bounds
        v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        chartsContainerView.addSubview(v)
        lineViews.insert(v, at: 0)
      }

      yAxisLeftView.frame = chartsContainerView.bounds
      yAxisLeftView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      yAxisLeftView.transform = CGAffineTransform.identity.scaledBy(x: 1, y: -1)
      chartsContainerView.addSubview(yAxisLeftView)

      if chartData.type == .yScaled {
        yAxisLeftView.textColor = chartData.lineAt(0).color
        yAxisRightView.textColor = chartData.lineAt(1).color
        yAxisRightView.alignment = .right
        yAxisRightView.frame = chartsContainerView.bounds
        yAxisRightView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        yAxisRightView.transform = CGAffineTransform.identity.scaledBy(x: 1, y: -1)
        chartsContainerView.addSubview(yAxisRightView)
      }

      chartInfoView.frame = chartsContainerView.bounds
      chartInfoView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      chartInfoView.delegate = self
      chartInfoView.bgColor = bgColor
      chartInfoView.maskColor = maskColor
      chartInfoView.textColor = headerTextColor
      chartsContainerView.addSubview(chartInfoView)

      xAxisView.values = chartData.labels
      chartPreviewView.chartData = chartData
      xAxisView.setBounds(lower: chartPreviewView.minX, upper: chartPreviewView.maxX)
      updateCharts()
      updateHeader()
      chartSettingsView.chartData = chartData
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
    headerView.datesLabel.textColor = headerTextColor
    xAxisView.gridColor = gridTextColor
    yAxisLeftView.gridColor = gridTextColor
    yAxisRightView.gridColor = gridTextColor
    yAxisLeftView.gridLineColor = gridTextColor
    yAxisRightView.gridLineColor = gridTextColor
    chartInfoView.bgColor = bgColor
    chartInfoView.maskColor = maskColor
    addSubview(headerView)

    addSubview(chartsContainerView)

    addSubview(chartPreviewView)
    chartPreviewView.delegate = self

    addSubview(xAxisView)
    addSubview(chartSettingsView)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    let headerFrame = CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: 35)
    headerView.frame = headerFrame

    let chartsFrame = CGRect(x: bounds.minX, y: bounds.minY + 35, width: bounds.width, height: 270)
    chartsContainerView.frame = chartsFrame

    let xAxisFrame = CGRect(x: bounds.minX, y: bounds.minY + 270 + 35, width: bounds.width, height: 26)
    xAxisView.frame = xAxisFrame

    let previewFrame = CGRect(x: bounds.minX, y: bounds.minY + 270 + 35 + 26, width: bounds.width, height: 44)
    chartPreviewView.frame = previewFrame

    let settingsViewFrame = CGRect(x: bounds.minX, y: bounds.minY + 270 + 35 + 26 + 44, width: bounds.width, height: chartSettingsView.height)
    chartSettingsView.frame = settingsViewFrame
  }

  func updateYScaled(animationStyle: ChartAnimation = .none) {
    for i in 0..<chartData.linesCount {
      var lower = Int.max
      var upper = Int.min
      guard chartData.isLineVisibleAt(i) else { continue }
      let line = chartData.lineAt(i)
      let subrange = line.aggregatedValues[xAxisView.lowerBound...xAxisView.upperBound]
      subrange.forEach {
        upper = Int(max($0, CGFloat(upper)))
        lower = Int(min($0, CGFloat(lower)))
      }

      let step = Int(ceil(CGFloat(upper - lower) / 5))
      upper = lower + step * 5
      var steps: [Int] = []
      for i in 0..<5 {
        steps.append(lower + step * i)
      }

      let yAxisView = i == 0 ? yAxisLeftView : yAxisRightView
      if (yAxisView.upperBound != upper || yAxisView.lowerBound != lower) {
        yAxisView.setBounds(lower: lower, upper: upper, steps: steps, animationStyle: animationStyle)
      }

      let lineView = lineViews[i]
      lineView.setViewport(minX: xAxisView.lowerBound,
                           maxX: xAxisView.upperBound,
                           minY: lower,
                           maxY: upper,
                           animationStyle: animationStyle)

    }
  }

  func updateCharts(animationStyle: ChartAnimation = .none) {
    if chartData.type == .yScaled {
      updateYScaled(animationStyle: animationStyle)
      return
    }

    var lower = Int.max
    var upper = Int.min

    for i in 0..<chartData.linesCount {
      guard chartData.isLineVisibleAt(i) else { continue }
      let line = chartData.lineAt(i)
      if line.type != .line {
        lower = min(line.minY, lower)
      }
      let subrange = line.aggregatedValues[xAxisView.lowerBound...xAxisView.upperBound]
      subrange.forEach {
        upper = Int(max($0, CGFloat(upper)))
        if line.type == .line {
          lower = Int(min($0, CGFloat(lower)))
        }
      }
    }

    let step = Int(ceil(CGFloat(upper - lower) / 5))
    upper = lower + step * 5
    var steps: [Int] = []
    for i in 0..<5 {
      steps.append(lower + step * i)
    }

    if yAxisLeftView.upperBound != upper || yAxisLeftView.lowerBound != lower {
      yAxisLeftView.setBounds(lower: lower, upper: upper, steps: steps, animationStyle: animationStyle)
    }

    lineViews.forEach {
      $0.setViewport(minX: xAxisView.lowerBound,
                     maxX: xAxisView.upperBound,
                     minY: lower,
                     maxY: upper,
                     animationStyle: animationStyle)
    }
  }

  func updateHeader() {
    let date1 = chartData.labelAt(xAxisView.lowerBound)
    let date2 = chartData.labelAt(xAxisView.upperBound)
    headerView.datesLabel.text = "\(date1) - \(date2)"// "\(df.string(from: date1)) - \(df.string(from: date2))"
  }
}

extension ChartView: ChartPreviewViewDelegate {
  func chartPreviewView(_ view: ChartPreviewView, didChangeMinX minX: Int, maxX: Int) {

    xAxisView.setBounds(lower: minX, upper: maxX)
    updateCharts(animationStyle: .interactive)

    if let timer = headerUpdateTimer {
      timer.invalidate()
    }

    headerUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { _ in
      self.updateHeader()
    })
  }
}

extension ChartView: ChartInfoViewDelegate {
  func chartInfoView(_ view: ChartInfoView, infoAtPointX pointX: CGFloat) -> (String, [ChartLineInfo])? {
    let p = convert(CGPoint(x: pointX, y: 0), from: view)
    let x = (p.x / bounds.width) * CGFloat(xAxisView.upperBound - xAxisView.lowerBound) + CGFloat(xAxisView.lowerBound)
    let x1 = Int(floor(x))
    let x2 = Int(ceil(x))
//    let px = CGFloat(x - xAxisView.lowerBound) / CGFloat(xAxisView.upperBound - xAxisView.lowerBound) * bounds.width
    guard x1 < chartData.labels.count && x >= 0 else { return nil }
    let date = chartData.labelAt(x1)

    var result: [ChartLineInfo] = []
    for i in 0..<chartData.linesCount {
      guard chartData.isLineVisibleAt(i) else { continue }
      let line = chartData.lineAt(i)
      let y1 = line.values[x1]
      let y2 = line.values[x2]
      let yAxisView: ChartYAxisView
      if chartData.type == .yScaled && i == 1 {
        yAxisView = yAxisRightView
      } else {
        yAxisView = yAxisLeftView
      }

      let dx = x - CGFloat(x1)
      let y = Int(dx * CGFloat(y2 - y1)) + y1
      let py = round(chartsContainerView.bounds.height * CGFloat(y - yAxisView.lowerBound) /
        CGFloat(yAxisView.upperBound - yAxisView.lowerBound))
      var left: CGFloat? = nil
      var right: CGFloat? = nil
      if line.type == .bar {
//        let lx = (CGFloat(x - xAxisView.lowerBound) - 0.5) / CGFloat(xAxisView.upperBound - xAxisView.lowerBound) * bounds.width
//        let rx = (CGFloat(x - xAxisView.lowerBound) + 0.5) / CGFloat(xAxisView.upperBound - xAxisView.lowerBound) * bounds.width
        left = chartsContainerView.convert(CGPoint(x: x1, y: 0), to: view).x
        right = chartsContainerView.convert(CGPoint(x: x2, y: 0), to: view).x
      }

      let v1 = line.values[x1]
      let v2 = line.values[x2]
      let v = Int(dx * CGFloat(v2 - v1)) + v1
      result.append(ChartLineInfo(name: line.name,
                                  color: line.color,
                                  point: chartsContainerView.convert(CGPoint(x: p.x, y: py), to: view),
                                  value: v,
                                  left: left,
                                  rigth: right))
    }

    return (date, result)
  }
}

extension ChartView: ChartPresentationDataDelegate {
  func chartPresentationData(_ data: ChartPresentationData, didSetLineVisble visible: Bool, at index: Int) {
    updateCharts(animationStyle: .animated)
    chartPreviewView.setLineVisible(visible, atIndex: index)
    let lv = lineViews[index]
    UIView.animate(withDuration: kAnimationDuration) {
      lv.alpha = visible ? 1 : 0
    }
    if data.type == .yScaled {
      let yAxisView = index == 0 ? yAxisLeftView : yAxisRightView
      yAxisView.setLabelsVisible(visible)
    }
  }
}
