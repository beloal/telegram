import UIKit

enum ChartYAxisViewAlignment {
  case left
  case right
}

fileprivate class ChartYAxisInnerView: UIView {
  override class var layerClass: AnyClass { return CAShapeLayer.self }

  private static let font = UIFont.systemFont(ofSize: 12, weight: .regular)
  var lowerBound: CGFloat = 0
  var upperBound: CGFloat = 0
  var steps: [CGFloat] = []
//  var labels: [UILabel] = []
  let lowerLabel: UILabel
  let upperLabel: UILabel
  var alignment: ChartYAxisViewAlignment = .left
  var textColor: UIColor?
  var gridColor: UIColor = UIColor(white: 0, alpha: 0.3) {
    didSet {
      if textColor == nil {
        lowerLabel.textColor = gridColor
        upperLabel.textColor = gridColor
//        labels.forEach { $0.textColor = gridColor }
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

  override init(frame: CGRect) {
    lowerLabel = ChartYAxisInnerView.makeLabel()
    upperLabel = ChartYAxisInnerView.makeLabel()

    super.init(frame: frame)

    lowerLabel.translatesAutoresizingMaskIntoConstraints = false
    upperLabel.translatesAutoresizingMaskIntoConstraints = false

    addSubview(lowerLabel)
    addSubview(upperLabel)

    NSLayoutConstraint.activate([
      lowerLabel.topAnchor.constraint(equalTo: topAnchor),
      lowerLabel.rightAnchor.constraint(equalTo: rightAnchor),
      upperLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
      upperLabel.rightAnchor.constraint(equalTo: rightAnchor)
    ])

    shapeLayer.fillColor = UIColor.clear.cgColor
    shapeLayer.strokeColor = gridLineColor.cgColor
    shapeLayer.lineDashPattern = [2, 3]
    shapeLayer.lineWidth = 1
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  static func makeLabel() -> UILabel {
    let label = UILabel()
    label.font = ChartYAxisInnerView.font
    label.transform = CGAffineTransform.identity.scaledBy(x: 1, y: -1)
    return label
  }

  func setBounds(lower: CGFloat, upper: CGFloat, steps: [CGFloat]) {
    lowerBound = lower
    upperBound = upper
    lowerLabel.text = "\(Int(round(lower)))"
    upperLabel.text = "\(Int(round(upper)))"
    self.steps = steps

    updateGrid()
  }

  func updateBounds(lower: CGFloat, upper: CGFloat, animationStyle: ChartAnimation = .none) {
    lowerBound = lower
    upperBound = upper
    updateGrid(animationStyle: animationStyle)
  }

  func updateGrid(animationStyle: ChartAnimation = .none) {
    let p = UIBezierPath()
    for step in steps {
      p.move(to: CGPoint(x: 0, y: step))
      p.addLine(to: CGPoint(x: bounds.width, y: step))
    }

    let realPath = p

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
    }

    shapeLayer.path = realPath.cgPath
  }
}

class ChartYAxisView: UIView {
  var lowerBound: CGFloat = 0
  var upperBound: CGFloat = 0
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

  func setBounds(lower: CGFloat, upper: CGFloat, steps: [CGFloat], animationStyle: ChartAnimation = .none) {
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
}
