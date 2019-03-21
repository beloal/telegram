import UIKit

class ChartView: UIView {
  let chartsContainerView = UIView()
  let chartPreviewView = ChartPreviewView()
  var lineViews: [ChartLineView] = []

  var lowerBound = 0
  var upperBound = 0

  var chartData: IChartData! {
    didSet {
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
    chartsContainerView.backgroundColor = UIColor(white: 0.95, alpha: 1)
    chartsContainerView.clipsToBounds = true

    addSubview(chartPreviewView)
    chartPreviewView.delegate = self
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    let chartsFrame = CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: bounds.height - 70)
    chartsContainerView.frame = chartsFrame

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
    lineViews.forEach { $0.setX(min: minX, max: maxX, animated: true) }
    lineViews.forEach { $0.setY(min: lowerBound, max: upper, animated: true)}
  }
}
