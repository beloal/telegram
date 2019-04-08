import UIKit

fileprivate class ChartYAxisInnerView: UIView {
  override class var layerClass: AnyClass { return CAShapeLayer.self }

  private let font = UIFont.systemFont(ofSize: 12, weight: .regular)
  var lowerBound = 0
  var upperBound = 0
  var steps: [Int] = []
  var labels: [UILabel] = []

  private var path: UIBezierPath?

  override var frame: CGRect {
    didSet {
      if upperBound > 0 && lowerBound > 0 {
        updateGrid()
      }
    }
  }

  var shapeLayer: CAShapeLayer {
    return layer as! CAShapeLayer
  }

  func makeLabel(y: Int) -> UILabel {
    let label = UILabel()
    label.font = font
    label.textColor = UIColor(white: 0, alpha: 0.3)
    label.text = "\(y)"
    label.sizeToFit()
    label.transform = CGAffineTransform.identity.scaledBy(x: 1, y: -1)
    return label
  }

  func setBounds(lower: Int, upper: Int, steps: [Int]) {
    lowerBound = lower
    upperBound = upper
    self.steps = steps
    labels.forEach { $0.removeFromSuperview() }
    labels.removeAll()

    let p = UIBezierPath()
    for step in steps {
      p.move(to: CGPoint(x: 0, y: step))
      p.addLine(to: CGPoint(x: 10000, y: step))
      let label = makeLabel(y: step)
      labels.append(label)
      addSubview(label)
    }

    path = p
    shapeLayer.fillColor = UIColor.clear.cgColor
    shapeLayer.strokeColor = UIColor(white: 0, alpha: 0.2).cgColor
    shapeLayer.lineWidth = CGFloat(1) / UIScreen.main.scale

    updateGrid()
  }

  func updateBounds(lower:Int, upper: Int, animationStyle: ChartAnimation = .none) {
    lowerBound = lower
    upperBound = upper
    updateGrid(animationStyle: animationStyle)
  }

  func updateGrid(animationStyle: ChartAnimation = .none) {
    guard let realPath = path?.copy() as? UIBezierPath else { return }

    let yScale = (bounds.height) / CGFloat(upperBound - lowerBound)
    let yTranslate = (bounds.height) * CGFloat(-lowerBound) / CGFloat(upperBound - lowerBound)
    let scale = CGAffineTransform.identity.scaledBy(x: 1, y: yScale)
    let translate = CGAffineTransform.identity.translatedBy(x: 0, y: yTranslate)
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
      let duration = animationStyle.rawValue
      animation.duration = duration
      animation.fromValue = shapeLayer.path
      animation.timingFunction = timingFunction
      layer.add(animation, forKey: "path")
      UIView.animate(withDuration: duration) {
        self.updateLabels()
      }
    } else {
      updateLabels()
    }

    shapeLayer.path = realPath.cgPath
  }

  func updateLabels() {
    for i in 0..<labels.count {
      let y = bounds.height * CGFloat(steps[i] - lowerBound) / CGFloat(upperBound - lowerBound)
      let l = labels[i]
      var f = l.frame
      f.origin = CGPoint(x: 0, y: y)
      l.frame = f.integral
    }
  }
}

class ChartYAxisView: UIView {
  var lowerBound = 0
  var upperBound = 0

  override var frame: CGRect {
    didSet {
      gridView?.updateGrid()
    }
  }

  private var gridView: ChartYAxisInnerView?

  func setBounds(lower: Int, upper: Int, steps: [Int], animationStyle: ChartAnimation = .none) {
    let gv = ChartYAxisInnerView()
    gv.frame = bounds
    gv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    addSubview(gv)

    if let gridView = gridView {
      gv.setBounds(lower: lowerBound, upper: upperBound, steps: steps)
      gv.alpha = 0
      gv.updateBounds(lower: lower, upper:upper, animationStyle: animationStyle)
      gridView.updateBounds(lower: lower, upper:upper, animationStyle: animationStyle)
      UIView.animate(withDuration: animationStyle.rawValue, animations: {
        gv.alpha = 1
        gridView.alpha = 0
      }) { _ in
        gridView.removeFromSuperview()
      }
    } else {
      gv.setBounds(lower: lower, upper: upper, steps: steps)
    }

    gridView = gv
    lowerBound = lower
    upperBound = upper
  }
}
