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
      let sl = layer as! CAShapeLayer
      sl.lineWidth = lineWidth
    }
  }

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
      sl.lineWidth = lineWidth
      updateGraph()
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    transform = CGAffineTransform.identity.scaledBy(x: 1, y: -1)
    isUserInteractionEnabled = false
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
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
    guard let realPath = path?.copy() as? UIBezierPath else { return }

    let xScale = bounds.width / CGFloat(maxX - minX)
    let xTranslate = -bounds.width * CGFloat(minX) / CGFloat(maxX - minX)
    let yScale = (bounds.height - 1) / CGFloat(maxY - minY)
    let yTranslate = (bounds.height - 1) * CGFloat(chartLine.minY - minY) / CGFloat(maxY - minY) + 0.5
    let scale = CGAffineTransform.identity.scaledBy(x: xScale, y: yScale)
    let translate = CGAffineTransform.identity.translatedBy(x: xTranslate, y: yTranslate)
    let transform = scale.concatenating(translate)
    realPath.apply(transform)

    let sl = layer as! CAShapeLayer
    if animationDuration > 0 {
      var timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      if sl.animationKeys()?.contains("path") ?? false,
        let presentation = sl.presentation(),
        let path = presentation.path {
        sl.removeAnimation(forKey: "path")
        sl.path = path
        timingFunction = CAMediaTimingFunction(name: .linear)
      }

      let animation = CABasicAnimation(keyPath: "path")
      animation.duration = animationDuration
      animation.fromValue = sl.path
      animation.timingFunction = timingFunction
      layer.add(animation, forKey: "path")
    }

    sl.path = realPath.cgPath
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    updateGraph(animationDuration: UIView.inheritedAnimationDuration)
  }
}
