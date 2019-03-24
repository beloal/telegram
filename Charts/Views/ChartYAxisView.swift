import UIKit

fileprivate class ChartYAxisInnerView: UIView {
  override class var layerClass: AnyClass { return CAShapeLayer.self }

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

  func makeLabel(y: Int) -> UILabel {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
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
    let sl = layer as! CAShapeLayer
    sl.fillColor = UIColor.clear.cgColor
    sl.strokeColor = UIColor(white: 0, alpha: 0.2).cgColor
    sl.lineWidth = CGFloat(1) / UIScreen.main.scale

    updateGrid()
  }

  func updateBounds(lower:Int, upper: Int) {
    lowerBound = lower
    upperBound = upper
    updateGrid(animationDuration: kAnimationDuration)
  }

  func updateGrid(animationDuration: TimeInterval = 0) {
    guard let realPath = path?.copy() as? UIBezierPath else { return }

    let yScale = (bounds.height) / CGFloat(upperBound - lowerBound)
    let yTranslate = (bounds.height) * CGFloat(-lowerBound) / CGFloat(upperBound - lowerBound)
    let scale = CGAffineTransform.identity.scaledBy(x: 1, y: yScale)
    let translate = CGAffineTransform.identity.translatedBy(x: 0, y: yTranslate)
    let transform = scale.concatenating(translate)
    realPath.apply(transform)

    let sl = layer as! CAShapeLayer

    if animationDuration != 0 {
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
      UIView.animate(withDuration: animationDuration) {
        self.updateLabels()
      }
    } else {
      updateLabels()
    }

    sl.path = realPath.cgPath
  }

  func updateLabels() {
    for i in 0..<labels.count {
      let y = bounds.height * CGFloat(steps[i] - lowerBound) / CGFloat(upperBound - lowerBound)
      let l = labels[i]
      var f = l.frame
      f.origin = CGPoint(x: 0, y: y)
      l.frame = f
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

  func setBounds(lower: Int, upper: Int, steps: [Int]) {
    let gv = ChartYAxisInnerView()
    gv.frame = bounds
    gv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    addSubview(gv)

    if let gridView = gridView {
      gv.setBounds(lower: lowerBound, upper: upperBound, steps: steps)
      gv.alpha = 0
      gv.updateBounds(lower: lower, upper:upper)
      gridView.updateBounds(lower: lower, upper:upper)
      UIView.animate(withDuration: kAnimationDuration, animations: {
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
