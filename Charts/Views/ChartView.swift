import UIKit

class ChartView: UIView {
  let chartsContainerView = UIView()
  let chartPreviewView = ChartPreviewView()
  var lineViews: [ChartLineView] = []

  var chartData: IChartData! {
    didSet {
      var minY = Int.max
      var maxY = Int.min
      for line in chartData.lines {
        minY = min(line.minY, minY)
        maxY = max(line.maxY, maxY)
        let v = ChartLineView()
        v.isUserInteractionEnabled = false
        v.chartLine = line
        v.lineWidth = 2
        lineViews.append(v)
        v.frame = chartsContainerView.bounds
        v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        chartsContainerView.addSubview(v)
      }

      lineViews.forEach { $0.setY(min: minY, max: maxY) }
      chartPreviewView.chartData = chartData

//      DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
//        self?.lineViews.forEach {
//          $0.setX(min: $0.chartLine.values.count / 2,
//                  max: $0.chartLine.values.count - 1,
//                  animated: true)
//        }
//      }
//
//      DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
//        self?.lineViews.forEach {
//          $0.setX(min: $0.chartLine.values.count / 2,
//                  max: $0.chartLine.values.count - 20,
//                  animated: true)
//        }
//      }
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
//    chartsContainerView.clipsToBounds = true

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
    lineViews.forEach { $0.setX(min: minX, max: maxX) }
  }
}
