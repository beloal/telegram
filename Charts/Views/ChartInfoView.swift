import UIKit

struct ChartLineInfo {
  let name: String
  let color: UIColor
  let point: CGPoint
  let value: Int
  let left: CGFloat?
  let rigth: CGFloat?
}

protocol ChartInfoViewDelegate: AnyObject {
  func chartInfoView(_ view: ChartInfoView, infoAtPointX pointX: CGFloat) -> (String, [ChartLineInfo])?
}

fileprivate class ChartPointInfoView: UIView {
  let dateLabel = UILabel()
  var valueLabels: [UILabel] = []
  var nameLabels: [UILabel] = []
  let valueStack = UIStackView()
  let nameStack = UIStackView()

  var textColor: UIColor = .white {
    didSet {
      dateLabel.textColor = textColor
      nameLabels.forEach { $0.textColor = textColor }
    }
  }

//  let dateFormatter = DateFormatter()
  let font = UIFont.systemFont(ofSize: 12, weight: .medium)
  let lightFont = UIFont.systemFont(ofSize: 12)

  override init(frame: CGRect) {
    super.init(frame: frame)

    layer.cornerRadius = 5
    clipsToBounds = true
    backgroundColor = UIColor(white: 0.9, alpha: 0.7)
//    dateFormatter.dateFormat = "EEE, dd MMM yyyy"

    dateLabel.textColor = textColor
    addSubview(dateLabel)
    addSubview(valueStack)
    addSubview(nameStack)

    valueStack.alignment = .trailing
    valueStack.axis = .vertical
    nameStack.alignment = .leading
    nameStack.axis = .vertical

    dateLabel.translatesAutoresizingMaskIntoConstraints = false
    valueStack.translatesAutoresizingMaskIntoConstraints = false
    nameStack.translatesAutoresizingMaskIntoConstraints = false

    dateLabel.font = font

    let dl = dateLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 10)
    let dt = dateLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10)
    let dr = dateLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -10)
    let db = dateLabel.bottomAnchor.constraint(equalTo: valueStack.topAnchor)

    let sl = valueStack.leftAnchor.constraint(equalTo: leftAnchor, constant: 10)
    let sr = valueStack.rightAnchor.constraint(equalTo: rightAnchor, constant: -10)
    let sb = valueStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)

    let nl = nameStack.leftAnchor.constraint(equalTo: leftAnchor, constant: 10)
    let nr = nameStack.rightAnchor.constraint(equalTo: rightAnchor, constant: -10)
    let nb = nameStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
    NSLayoutConstraint.activate([dl, dt, dr, db, sl, sr, sb, nl, nr, nb])
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }

  func set(x: CGFloat, date: String, points: [ChartLineInfo]) {
    valueLabels.forEach { $0.removeFromSuperview() }
    valueLabels.removeAll()
    nameLabels.forEach { $0.removeFromSuperview() }
    nameLabels.removeAll()
    for point in points {
      let l = UILabel()
      l.font = lightFont
      l.textColor = point.color
      l.text = String(point.value)
      l.translatesAutoresizingMaskIntoConstraints = false
      valueLabels.append(l)
      valueStack.addArrangedSubview(l)

      let nl = UILabel()
      nl.font = lightFont
      nl.textColor = textColor
      nl.text = point.name
      nl.translatesAutoresizingMaskIntoConstraints = false
      nameLabels.append(nl)
      nameStack.addArrangedSubview(nl)
    }
    dateLabel.text = date// dateFormatter.string(from: date)
  }

  func update(x: CGFloat, date: String, points: [ChartLineInfo]) {
    for i in 0..<valueLabels.count {
      let l = valueLabels[i]
      l.text = String(points[i].value)
      let nl = nameLabels[i]
      nl.text = points[i].name
    }
    dateLabel.text = date// dateFormatter.string(from: date)
  }
}

fileprivate class CircleView: UIView {
  override class var layerClass: AnyClass { return CAShapeLayer.self }

  var color: UIColor? {
    didSet {
      shapeLayer.strokeColor = color?.cgColor
    }
  }

  var shapeLayer: CAShapeLayer {
    return layer as! CAShapeLayer
  }

  override var frame: CGRect {
    didSet {
      let p = UIBezierPath(ovalIn: bounds)
      shapeLayer.path = p.cgPath
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    shapeLayer.strokeColor = color?.cgColor
    shapeLayer.fillColor = UIColor.white.cgColor
    shapeLayer.lineWidth = 2
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }
}

fileprivate class ChartPointIntersectionsView: UIView {
  var intersectionViews: [CircleView] = []

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = UIColor.lightGray
    transform = CGAffineTransform.identity.scaledBy(x: 1, y: -1)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }

  func setPoints(_ points: [ChartLineInfo]) {
    intersectionViews.forEach { $0.removeFromSuperview() }
    intersectionViews.removeAll()

    for point in points {
      let v = CircleView()
      v.color = point.color
      v.frame = CGRect(x: 0, y: 0, width: 6, height: 6)
      v.center = CGPoint(x: bounds.midX, y: point.point.y)
      intersectionViews.append(v)
      addSubview(v)
    }
  }

  func updatePoints(_ points: [ChartLineInfo]) {
    for i in 0..<intersectionViews.count {
      let v = intersectionViews[i]
      let p = points[i]
      v.center = CGPoint(x: bounds.midX, y: p.point.y)
//      UIView.animate(withDuration: ChartAnimation.interactive.rawValue) { [unowned self] in
//        v.center = CGPoint(x: self.bounds.midX, y: p.point.y)
//      }
    }
  }
}

class ChartInfoMaskView: UIView {
  let maskLayer = CAShapeLayer()

  override init(frame: CGRect = .zero) {
    super.init(frame: frame)
    maskLayer.fillRule = .evenOdd
    layer.mask = maskLayer
  }

  func updateMask(left: CGFloat, right: CGFloat) {
    let cornersMask = UIBezierPath(rect: bounds)
    let rectMask = UIBezierPath(rect: CGRect(x: left, y: 0, width: right - left, height: bounds.height))
    let result = UIBezierPath()
    result.append(cornersMask)
    result.append(rectMask)
    result.usesEvenOddFillRule = true
    maskLayer.path = result.cgPath
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }
}

class ChartInfoView: UIView {
  weak var delegate: ChartInfoViewDelegate?

  private let pointInfoView = ChartPointInfoView()
  private let pointsView = ChartPointIntersectionsView(frame: CGRect(x: 0, y: 0, width: 1, height: 0))
  private let infoMaskView = ChartInfoMaskView()

  var bgColor: UIColor = UIColor.white {
    didSet {
      pointInfoView.backgroundColor = bgColor
    }
  }

  var textColor: UIColor = UIColor.black {
    didSet {
      pointInfoView.textColor = textColor
    }
  }

  var maskColor: UIColor = UIColor.clear {
    didSet {
      infoMaskView.backgroundColor = maskColor
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    isExclusiveTouch = true
    let lp = UILongPressGestureRecognizer(target: self, action: #selector(onPress(_:)))
    lp.minimumPressDuration = 0.2
    addGestureRecognizer(lp)
    infoMaskView.isUserInteractionEnabled = false
    infoMaskView.alpha = 0
    infoMaskView.backgroundColor = maskColor
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }

  @objc func onPress(_ sender: UILongPressGestureRecognizer) {
    guard let delegate = delegate else { return }
    let x = sender.location(in: self).x
    guard let (date, intersectionPoints) = delegate.chartInfoView(self, infoAtPointX: x) else { return }

    switch sender.state {
    case .possible:
      break
    case .began:
      addSubview(pointsView)
      addSubview(infoMaskView)
      pointsView.setPoints(intersectionPoints)
      pointInfoView.set(x: x, date: date, points: intersectionPoints)
      addSubview(pointInfoView)
    case .changed:
      pointsView.updatePoints(intersectionPoints)
      pointInfoView.update(x: x, date: date, points: intersectionPoints)
    case .ended:
      fallthrough
    case .cancelled:
      fallthrough
    case .failed:
      pointsView.removeFromSuperview()
      pointInfoView.removeFromSuperview()
      infoMaskView.removeFromSuperview()
    }

    updateViews(x: intersectionPoints[0].point.x,
                left: intersectionPoints[0].left,
                right: intersectionPoints[0].rigth)
  }

  func updateViews(x: CGFloat, left: CGFloat?, right: CGFloat?) {
    if let left = left, let right = right {
      infoMaskView.alpha = 1
      pointsView.alpha = 0
      infoMaskView.updateMask(left: left, right: right)
    } else {
      infoMaskView.alpha = 0
      pointsView.alpha = 1
      pointsView.center = CGPoint(x: x, y: bounds.midY)
    }
    let s = pointInfoView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    pointInfoView.frame.size = CGSize(width: 150, height: s.height)
    if x > 170 {
      pointInfoView.center = CGPoint(x: x - 91, y: pointInfoView.frame.height / 2)
    } else {
      pointInfoView.center = CGPoint(x: x + 91, y: pointInfoView.frame.height / 2)
    }
    var f = pointInfoView.frame
    if f.minX < 0 {
      f.origin.x = 0
      pointInfoView.frame = f
    } else if f.minX + f.width > bounds.width {
      f.origin.x = bounds.width - f.width
      pointInfoView.frame = f
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    var f = pointsView.frame
    f.origin.y = bounds.minY
    f.size.height = bounds.height
    pointsView.frame = f
    infoMaskView.frame = bounds
  }
}

extension ChartInfoView: UIGestureRecognizerDelegate {
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                         shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
}
