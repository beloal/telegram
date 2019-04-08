import UIKit

extension IChartLine {
  func makePath() -> UIBezierPath {
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
}

class ChartLineView: UIView {
  override class var layerClass: AnyClass { return CAShapeLayer.self }

  private var minX = 0
  private var maxX = 0
  private var minY = 0
  private var maxY = 0
  private var path: UIBezierPath?

  var lineWidth: CGFloat = 1 {
    didSet {
      shapeLayer.lineWidth = lineWidth
    }
  }

  var chartLine: IChartLine! {
    didSet {
      guard let chartLine = chartLine else { return }
      maxX = chartLine.values.count - 1
      minY = chartLine.minY
      maxY = chartLine.maxY
      path = chartLine.makePath()
      shapeLayer.strokeColor = chartLine.color.cgColor
      shapeLayer.fillColor = UIColor.clear.cgColor
      shapeLayer.lineWidth = lineWidth
      updateGraph()
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    transform = CGAffineTransform.identity.scaledBy(x: 1, y: -1)
    isUserInteractionEnabled = false
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }

  var shapeLayer: CAShapeLayer {
    return layer as! CAShapeLayer
  }

  func setViewport(minX: Int, maxX: Int, minY: Int, maxY: Int, animationStyle: ChartAnimation = .none) {
    assert(minX < maxX && minY < maxY)
    self.minX = minX
    self.maxX = maxX
    self.minY = minY
    self.maxY = maxY
    updateGraph(animationStyle: animationStyle)
  }

  func setX(min: Int, max: Int) {
    assert(min < max)
    minX = min
    maxX = max
    updateGraph()
  }

  func setY(min: Int, max: Int, animationStyle: ChartAnimation = .none) {
    assert(min < max)
    minY = min
    maxY = max
    updateGraph(animationStyle: animationStyle)
  }

  private func updateGraph(animationStyle: ChartAnimation = .none) {
    guard let realPath = path?.copy() as? UIBezierPath else { return }

    let xScale = bounds.width / CGFloat(maxX - minX)
    let xTranslate = -bounds.width * CGFloat(minX) / CGFloat(maxX - minX)
    let yScale = (bounds.height - 1) / CGFloat(maxY - minY)
    let yTranslate = (bounds.height - 1) * CGFloat(chartLine.minY - minY) / CGFloat(maxY - minY) + 0.5
    let scale = CGAffineTransform.identity.scaledBy(x: xScale, y: yScale)
    let translate = CGAffineTransform.identity.translatedBy(x: xTranslate, y: yTranslate)
    let transform = scale.concatenating(translate)
    realPath.apply(transform)

    if animationStyle != .none {
      let timingFunction = CAMediaTimingFunction(name: animationStyle == .interactive ? .linear : .easeInEaseOut)
      if shapeLayer.animationKeys()?.contains("path") ?? false,
        let presentation = shapeLayer.presentation(),
        let path = presentation.path {
        shapeLayer.removeAnimation(forKey: "path")
        shapeLayer.path = path
      }

      let animation = CABasicAnimation(keyPath: "path")
      animation.duration = animationStyle.rawValue
      animation.fromValue = shapeLayer.path
      animation.timingFunction = timingFunction
      layer.add(animation, forKey: "path")
    }

    shapeLayer.path = realPath.cgPath
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    updateGraph()
  }
}
