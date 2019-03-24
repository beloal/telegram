import UIKit

let kAnimationDuration = 0.1

class ChartView: UIView {
  let chartsContainerView = UIView()
  let chartPreviewView = ChartPreviewView()
  let yAxisView = ChartYAxisView()
  let xAxisView = ChartXAxisView()
  var lineViews: [ChartLineView] = []

  var lowerBound = 0
  var upperBound = 0

  var chartData: IChartData! {
    didSet {
      yAxisView.frame = chartsContainerView.bounds
      yAxisView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      yAxisView.transform = CGAffineTransform.identity.scaledBy(x: 1, y: -1)
      chartsContainerView.addSubview(yAxisView)
      
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
//    xAxisView.backgroundColor = UIColor.yellow
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
}

extension ChartView: ChartPreviewViewDelegate {
  func chartPreviewView(_ view: ChartPreviewView, didChangeMinX minX: Int, maxX: Int) {
    var upper = Int.min
    chartData.lines.forEach {
      let subrange = $0.values[minX..<maxX]
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
