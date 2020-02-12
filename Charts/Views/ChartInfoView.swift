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
  enum Alignment {
    case left
    case right
  }

  let captionLabel = UILabel()
  let distanceLabel = UILabel()
  let altitudeLabel = UILabel()
  let stackView = UIStackView()

  let maskLayer = CAShapeLayer()
  var maskPath: UIBezierPath?

  var arrowY: CGFloat? {
    didSet {
      setNeedsLayout()
    }
  }

  var alignment = Alignment.left {
    didSet {
      updateMask()
    }
  }

  var textColor: UIColor = .white {
    didSet {
      captionLabel.textColor = textColor
      distanceLabel.textColor = textColor
      altitudeLabel.textColor = textColor
    }
  }

  let font = UIFont.systemFont(ofSize: 12, weight: .medium)
  let lightFont = UIFont.systemFont(ofSize: 12)

  override init(frame: CGRect) {
    super.init(frame: frame)

    layer.cornerRadius = 5
    backgroundColor = .clear
    layer.shadowColor = UIColor(white: 0, alpha: 1).cgColor
    layer.shadowOpacity = 0.25
    layer.shadowRadius = 2
    layer.shadowOffset = CGSize(width: 0, height: 2)
    maskLayer.fillColor = UIColor.white.cgColor
    layer.addSublayer(maskLayer)

    stackView.alignment = .leading
    stackView.axis = .vertical
    stackView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stackView)

    NSLayoutConstraint.activate([
      stackView.leftAnchor.constraint(equalTo: leftAnchor, constant: 6),
      stackView.topAnchor.constraint(equalTo: topAnchor, constant: 6),
      stackView.rightAnchor.constraint(equalTo: rightAnchor, constant: -6),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6)
    ])

    stackView.addArrangedSubview(captionLabel)
    stackView.addArrangedSubview(distanceLabel)
    stackView.addArrangedSubview(altitudeLabel)
    stackView.setCustomSpacing(6, after: distanceLabel)

    captionLabel.text = "Distance:"

    captionLabel.font = lightFont
    distanceLabel.font = lightFont
    altitudeLabel.font = lightFont

    captionLabel.textColor = textColor
    distanceLabel.textColor = textColor
    altitudeLabel.textColor = textColor
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }

  func set(x: CGFloat, date: String, points: [ChartLineInfo]) {
    distanceLabel.text = date
    altitudeLabel.text = "▲ \(points[0].value)"
  }

  func update(x: CGFloat, date: String, points: [ChartLineInfo]) {
    distanceLabel.text = date
    altitudeLabel.text = "▲ \(points[0].value)"
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    let y = arrowY ?? bounds.midY
    let path = UIBezierPath(roundedRect: bounds, cornerRadius: 3)
    let trianglePath = UIBezierPath()
    trianglePath.move(to: CGPoint(x: bounds.maxX, y: y - 3))
    trianglePath.addLine(to: CGPoint(x: bounds.maxX + 5, y: y))
    trianglePath.addLine(to: CGPoint(x: bounds.maxX, y: y + 3))
    trianglePath.close()
    path.append(trianglePath)
    maskPath = path
    updateMask()
  }

  private func updateMask() {
    guard let path = maskPath?.copy() as? UIBezierPath else { return }
    if alignment == .right {
      path.apply(CGAffineTransform.identity.scaledBy(x: -1, y: 1).translatedBy(x: -bounds.width, y: 0))
    }
    maskLayer.path = path.cgPath
    layer.shadowPath = path.cgPath
  }
}

fileprivate class CircleView: UIView {
  override class var layerClass: AnyClass { return CAShapeLayer.self }

  var color: UIColor? {
    didSet {
      shapeLayer.fillColor = color?.withAlphaComponent(0.5).cgColor
      ringLayer.fillColor = UIColor.white.cgColor
      centerLayer.fillColor = color?.cgColor
    }
  }

  var shapeLayer: CAShapeLayer {
    return layer as! CAShapeLayer
  }

  let ringLayer = CAShapeLayer()
  let centerLayer = CAShapeLayer()

  override var frame: CGRect {
    didSet {
      let p = UIBezierPath(ovalIn: bounds)
      shapeLayer.path = p.cgPath
      ringLayer.frame = shapeLayer.bounds.insetBy(dx: shapeLayer.bounds.width / 6, dy: shapeLayer.bounds.height / 6)
      ringLayer.path = UIBezierPath(ovalIn: ringLayer.bounds).cgPath
      centerLayer.frame = shapeLayer.bounds.insetBy(dx: shapeLayer.bounds.width / 3, dy: shapeLayer.bounds.height / 3)
      centerLayer.path = UIBezierPath(ovalIn: centerLayer.bounds).cgPath
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    shapeLayer.fillColor = color?.withAlphaComponent(0.5).cgColor
    shapeLayer.lineWidth = 4
    shapeLayer.fillRule = .evenOdd
    shapeLayer.addSublayer(ringLayer)
    shapeLayer.addSublayer(centerLayer)
    ringLayer.fillColor = UIColor.white.cgColor
    centerLayer.fillColor = color?.cgColor
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }
}

fileprivate class ChartPointIntersectionsView: UIView {
  var intersectionViews: [CircleView] = []

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = UIColor(red: 0.14, green: 0.61, blue: 0.95, alpha: 0.5)
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
      v.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
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
  private let pointsView = ChartPointIntersectionsView(frame: CGRect(x: 0, y: 0, width: 2, height: 0))
  private let infoMaskView = ChartInfoMaskView()
  private var lineInfo: ChartLineInfo?

  var bgColor: UIColor = UIColor.white {
    didSet {
//      pointInfoView.backgroundColor = bgColor
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

  private var captured = false

  override init(frame: CGRect) {
    super.init(frame: frame)

    isExclusiveTouch = true
    let panGR = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
    addGestureRecognizer(panGR)
    infoMaskView.isUserInteractionEnabled = false
    infoMaskView.alpha = 0
    infoMaskView.backgroundColor = maskColor
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }

  func update(_ x: CGFloat? = nil) {
    let x = x ?? pointsView.center.x
    guard let delegate = delegate,
      let (date, intersectionPoints) = delegate.chartInfoView(self, infoAtPointX: x) else { return }
    lineInfo = intersectionPoints[0]
//    UIView.animate(withDuration: 0.1) { [unowned self] in
      self.pointsView.updatePoints(intersectionPoints)
//    }
    pointInfoView.update(x: x, date: date, points: intersectionPoints)
    let y = max(pointInfoView.frame.height / 2 + 5,
                min(bounds.height - pointInfoView.frame.height / 2 - 5, bounds.height - lineInfo!.point.y));
    pointInfoView.center = CGPoint(x: pointInfoView.center.x, y: y)
    let arrowPoint = convert(CGPoint(x: 0, y: bounds.height - lineInfo!.point.y), to: pointInfoView)
    pointInfoView.arrowY = arrowPoint.y
  }

  @objc func onPan(_ sender: UIPanGestureRecognizer) {
    let x = sender.location(in: self).x
    switch sender.state {
    case .possible:
      break
    case .began:
      guard let lineInfo = lineInfo else { return }
      captured = abs(x - lineInfo.point.x) < 22
    case .changed:
      if captured {
        if x < bounds.minX || x > bounds.maxX {
          return
        }
        update(x)
        updateViews(point: lineInfo!.point, left: nil, right: nil)
      }
    case .ended, .cancelled, .failed:
      captured = false
    @unknown default:
      fatalError()
    }
  }

  func updateViews(point: CGPoint, left: CGFloat?, right: CGFloat?) {
    if let left = left, let right = right {
      infoMaskView.alpha = 1
      pointsView.alpha = 0
      infoMaskView.updateMask(left: left, right: right)
    } else {
      infoMaskView.alpha = 0
      pointsView.alpha = 1
      pointsView.center = CGPoint(x: point.x, y: bounds.midY)
    }
    let s = pointInfoView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    pointInfoView.frame.size = s
    let orientationChangeX = pointInfoView.alignment == .left ? s.width + 40 : bounds.width - s.width - 40
    if point.x > orientationChangeX {
      pointInfoView.alignment = .left
      pointInfoView.center = CGPoint(x: point.x - s.width / 2 - 20, y: pointInfoView.center.y)
    } else {
      pointInfoView.alignment = .right
      pointInfoView.center = CGPoint(x: point.x + s.width / 2 + 20, y: pointInfoView.center.y)
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
    if lineInfo == nil, bounds.width > 0 {
      let x = bounds.width / 1.5
      guard let (date, intersectionPoints) = delegate?.chartInfoView(self, infoAtPointX: x) else { return }
      addSubview(pointsView)
      addSubview(pointInfoView)
      lineInfo = intersectionPoints[0]
      pointsView.setPoints(intersectionPoints)
      pointInfoView.set(x: x, date: date, points: intersectionPoints)
      updateViews(point: lineInfo!.point, left: nil, right: nil)
    }
  }
}

extension ChartInfoView: UIGestureRecognizerDelegate {
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                         shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
}
