import UIKit

protocol ChartPreviewViewDelegate: AnyObject {
  func chartPreviewView(_ view: ChartPreviewView, didChangeMinX minX: Int, maxX: Int)
}

class ChartPreviewView: UIView {
  let previewContainerView = UIView()
  let viewPortView = UIView()
  var previewViews: [ChartLineView] = []

  var minX = 0
  var maxX = 0
  weak var delegate: ChartPreviewViewDelegate?

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
        v.lineWidth = 1
        previewViews.append(v)
        v.frame = previewContainerView.bounds
        v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        previewContainerView.addSubview(v)
      }
      previewViews.forEach { $0.setY(min: minY, max: maxY) }
      let count = chartData.xAxis.count - 1
      setX(min: 0, max: count / 5)
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    previewContainerView.frame = bounds
    previewContainerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    addSubview(previewContainerView)

    viewPortView.backgroundColor = UIColor(white: 0.5, alpha: 0.5)
    addSubview(viewPortView)

    let pan = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
    viewPortView.addGestureRecognizer(pan)
  }

  @objc func onPan(_ sender: UIPanGestureRecognizer) {
    if sender.state == .changed {
      let p = sender.translation(in: viewPortView)
      let count = chartData.xAxis.count - 1
      let x = Int((viewPortView.frame.minX + p.x) / bounds.width * CGFloat(count))
//      print("\(x) \(p)")
      let dx = maxX - minX
      let mx = x + dx
      if x >= 0 && mx <= count {
        viewPortView.frame = viewPortView.frame.offsetBy(dx: p.x, dy: 0)
        sender.setTranslation(CGPoint(x: 0, y: 0), in: viewPortView)
        minX = x
        maxX = mx
        delegate?.chartPreviewView(self, didChangeMinX: minX, maxX: maxX)
      } else if minX > 0 && x < 0 {
        setX(min: 0, max: dx)
      } else if maxX < count && mx > count {
        setX(min: count - dx, max: count)
      }
    }
  }

  func setX(min: Int, max: Int) {
    assert(min < max)
    minX = min
    maxX = max
    updateViewPort()
    delegate?.chartPreviewView(self, didChangeMinX: minX, maxX: maxX)
  }

  func updateViewPort() {
    let count = CGFloat(chartData.xAxis.count - 1)
    viewPortView.frame = CGRect(x: CGFloat(minX) / count * bounds.width,
                                y: bounds.minY,
                                width: CGFloat(maxX - minX) / count * bounds.width,
                                height: bounds.height)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    updateViewPort()
  }
}
