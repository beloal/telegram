import UIKit

enum ChartYAxisViewAlignment {
  case left
  case right
}

fileprivate class ChartYAxisInnerView: UIView {
  override class var layerClass: AnyClass { return CAShapeLayer.self }

  private static let font = UIFont.systemFont(ofSize: 12, weight: .regular)
  var lowerBound = 0
  var upperBound = 0
  var steps: [Int] = []
  var labels: [UILabel] = []
  var alignment: ChartYAxisViewAlignment = .left
  var textColor: UIColor?
  var gridColor: UIColor = UIColor(white: 0, alpha: 0.3) {
    didSet {
      if textColor == nil {
        labels.forEach { $0.textColor = gridColor }
      }
    }
  }

  var gridLineColor: UIColor = UIColor.white {
    didSet {
      shapeLayer.strokeColor = gridLineColor.cgColor
    }
  }

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
    label.font = ChartYAxisInnerView.font
    label.textColor = textColor ?? gridColor
    label.text = "\(y)"
    label.frame = CGRect(x: 0, y: 0, width: 100, height: 15)
    label.transform = CGAffineTransform.identity.scaledBy(x: 1, y: -1)
    return label
  }

  func setBounds(lower: Int, upper: Int, steps: [Int]) {
    lowerBound = lower
    upperBound = upper
    self.steps = steps
    labels.forEach { $0.removeFromSuperview() }
    labels.removeAll()

    for step in steps {
      let label = makeLabel(y: step)
      label.textAlignment = alignment == .left ? .left : .right
      labels.append(label)
      addSubview(label)
    }

//    if alignment == .left {
      let p = UIBezierPath()
      for step in steps {
        p.move(to: CGPoint(x: 0, y: step))
        p.addLine(to: CGPoint(x: 10000, y: step))
      }

      path = p
      shapeLayer.fillColor = UIColor.clear.cgColor
      shapeLayer.strokeColor = gridLineColor.cgColor
      shapeLayer.lineWidth = CGFloat(1) / UIScreen.main.scale
//    }
    updateGrid()
  }

  func updateBounds(lower:Int, upper: Int, animationStyle: ChartAnimation = .none) {
    lowerBound = lower
    upperBound = upper
    updateGrid(animationStyle: animationStyle)
  }

  func updateGrid(animationStyle: ChartAnimation = .none) {
    guard let realPath = path?.copy() as? UIBezierPath else {
      if animationStyle != .none {
        UIView.animate(withDuration: animationStyle.rawValue) {
          self.updateLabels()
        }
      } else {
        updateLabels()
      }
      return
    }

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
      f.origin = CGPoint(x: alignment == .left ? 0 : bounds.width - f.width, y: y)
      l.frame = f.integral
    }
  }
}

class ChartYAxisView: UIView {
  var lowerBound = 0
  var upperBound = 0
  var alignment: ChartYAxisViewAlignment = .right
  var textColor: UIColor?

  var gridColor: UIColor = UIColor(white: 0, alpha: 0.3) {
    didSet {
      gridView?.gridColor = gridColor
    }
  }

  var gridLineColor: UIColor = UIColor(white: 0, alpha: 0.3) {
    didSet {
      gridView?.gridLineColor = gridLineColor
    }
  }

  override var frame: CGRect {
    didSet {
      gridView?.updateGrid()
    }
  }

  private var gridView: ChartYAxisInnerView?

  func setBounds(lower: Int, upper: Int, steps: [Int], animationStyle: ChartAnimation = .none) {
    let gv = ChartYAxisInnerView()
    gv.alignment = alignment
    gv.textColor = textColor
    gv.gridColor = gridColor
    gv.gridLineColor = gridLineColor
    gv.frame = bounds
    gv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    addSubview(gv)

    if let gridView = gridView {
      if animationStyle == .animated {
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
        gridView.removeFromSuperview()
      }
    } else {
      gv.setBounds(lower: lower, upper: upper, steps: steps)
    }

    gridView = gv
    lowerBound = lower
    upperBound = upper
  }

  func setLabelsVisible(_ visible: Bool) {
    UIView.animate(withDuration: kAnimationDuration) {
      self.gridView?.labels.forEach {
        $0.alpha = visible ? 1 : 0
      }
    }
  }
}
