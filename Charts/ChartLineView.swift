import UIKit

fileprivate let kAnimationDuration = UIApplication.shared.statusBarOrientationAnimationDuration

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
  private var maxX = 1
  private var minY = 0
  private var maxY = 1
  private var path: UIBezierPath?

  var chartLine: IChartLine! {
    didSet {
      guard let chartLine = chartLine else { return }
      maxX = chartLine.values.count - 1
      minY = chartLine.minY
      maxY = chartLine.maxY
      path = chartLine.makePath()
      let sl = layer as! CAShapeLayer
      sl.strokeColor = chartLine.color.cgColor
      sl.fillColor = UIColor.clear.cgColor
      sl.miterLimit = 0
      updateGraph()
    }
  }

  func setX(min: Int, max: Int, animated: Bool = false) {
    assert(min < max)
    minX = min
    maxX = max
    updateGraph(animationDuration: animated ? kAnimationDuration : 0)
  }

  func setY(min: Int, max: Int, animated: Bool = false) {
    assert(min < max)
    minY = min
    maxY = max
    updateGraph(animationDuration: animated ? kAnimationDuration : 0)
  }

  private func updateGraph(animationDuration: TimeInterval = 0) {
    let xScale = bounds.width / CGFloat(maxX - minX)
    let xTranslate = -bounds.width * CGFloat(minX) / CGFloat(maxX - minX) //CGFloat(0)
    let yScale = (bounds.height - 1) / CGFloat(maxY - minY)
    let yTranslate = (bounds.height - 1) * CGFloat(chartLine.minY - minY) / CGFloat(maxY - minY) + 0.5

    guard let realPath = path?.copy() as? UIBezierPath else { return }
    let scale = CGAffineTransform.identity.scaledBy(x: xScale, y: yScale)
    let translate = CGAffineTransform.identity.translatedBy(x: xTranslate, y: yTranslate)
    let transform = scale.concatenating(translate)
    realPath.apply(transform)

    let sl = layer as! CAShapeLayer
    if animationDuration > 0 {
      let animation = CABasicAnimation(keyPath: "path")
      animation.duration = animationDuration
      animation.fromValue = sl.path
      animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      layer.add(animation, forKey: "path")
    }

    sl.path = realPath.cgPath
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    updateGraph(animationDuration: UIView.inheritedAnimationDuration)
  }
}
