import UIKit

class ChartView: UIView {
  var chartData: IChartData! {
    didSet {
      var minY = Int.max
      var maxY = Int.min
      for line in chartData.lines {
        minY = min(line.minY, minY)
        maxY = max(line.maxY, maxY)
        let v = ChartLineView()
        v.isUserInteractionEnabled = false
        v.transform = CGAffineTransform.identity.scaledBy(x: 1, y: -1)
        v.chartLine = line
        lineViews.append(v)
        addSubview(v)
      }
      lineViews.forEach { $0.setY(min: minY, max: maxY) }

      DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
        self?.lineViews.forEach {
          $0.setX(min: $0.chartLine.values.count / 2,
                  max: $0.chartLine.values.count - 1,
                  animated: true)
        }
      }

      DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
        self?.lineViews.forEach {
          $0.setX(min: $0.chartLine.values.count / 2,
                  max: $0.chartLine.values.count - 20,
                  animated: true)
        }
      }
    }
  }

  var lineViews: [ChartLineView] = []

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }

  private func setup() {
    clipsToBounds = true
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    for view in lineViews {
      view.frame = bounds
    }
  }
}
