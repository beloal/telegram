import UIKit

struct ChartLineInfo {
  let name: String
  let color: UIColor
  let point: CGPoint
  let value: Int
}

protocol ChartInfoViewDelegate: AnyObject {
  func chartInfoView(_ view: ChartInfoView, infoAtPointX pointX: CGFloat) -> (Date, [ChartLineInfo])?
}

fileprivate class ChartPointInfoView: UIView {
  let dateLabel = UILabel()
  let yearLabel = UILabel()
  var valueLabels: [UILabel] = []
  let valueStack = UIStackView()

  let dateFormatter = DateFormatter()
  let yearFormatter = DateFormatter()
  let font = UIFont.systemFont(ofSize: 14, weight: .medium)

  override init(frame: CGRect) {
    super.init(frame: frame)

    layer.cornerRadius = 5
    clipsToBounds = true
    backgroundColor = UIColor(white: 0.9, alpha: 0.7)
    dateFormatter.dateFormat = "MMM dd"
    yearFormatter.dateFormat = "yyyy"

    addSubview(dateLabel)
    addSubview(yearLabel)
    addSubview(valueStack)

    valueStack.alignment = .trailing
    valueStack.axis = .vertical

    dateLabel.translatesAutoresizingMaskIntoConstraints = false
    yearLabel.translatesAutoresizingMaskIntoConstraints = false
    valueStack.translatesAutoresizingMaskIntoConstraints = false

    dateLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
    yearLabel.font = UIFont.systemFont(ofSize: 14, weight: .light)

    let dl = dateLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 10)
    let dt = dateLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10)
    let dr = dateLabel.rightAnchor.constraint(lessThanOrEqualTo: valueStack.leftAnchor, constant: -10)
    let db = dateLabel.bottomAnchor.constraint(equalTo: yearLabel.topAnchor)

    let yl = yearLabel.leftAnchor.constraint(equalTo: dateLabel.leftAnchor)
    let yr = yearLabel.rightAnchor.constraint(equalTo: dateLabel.rightAnchor)
    let yb = yearLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -10)

    let st = valueStack.topAnchor.constraint(equalTo: dateLabel.topAnchor)
    let sr = valueStack.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor, constant: -10)
    let sb = valueStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -10)
    NSLayoutConstraint.activate([
      dl, dt, dr, db,
      yl, yr, yb,
      st, sr, sb
      ])
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }

  func set(x: CGFloat, date: Date, points: [ChartLineInfo]) {
    valueLabels.forEach { $0.removeFromSuperview() }
    valueLabels.removeAll()
    for point in points {
      let l = UILabel()
      l.font = font
      l.textColor = point.color
      l.text = String(point.value)
      l.translatesAutoresizingMaskIntoConstraints = false
      valueLabels.append(l)
      valueStack.addArrangedSubview(l)
    }
    dateLabel.text = dateFormatter.string(from: date)
    yearLabel.text = yearFormatter.string(from: date)
  }

  func update(x: CGFloat, date: Date, points: [ChartLineInfo]) {
    for i in 0..<valueLabels.count {
      let l = valueLabels[i]
      l.text = String(points[i].value)
    }
    dateLabel.text = dateFormatter.string(from: date)
    yearLabel.text = yearFormatter.string(from: date)
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
    }
  }
}

class ChartInfoView: UIView {
  weak var delegate: ChartInfoViewDelegate?

  private let pointInfoView = ChartPointInfoView()
  private let pointsView = ChartPointIntersectionsView(frame: CGRect(x: 0, y: 0, width: 1, height: 0))

  override init(frame: CGRect) {
    super.init(frame: frame)

    isExclusiveTouch = true
    let lp = UILongPressGestureRecognizer(target: self, action: #selector(onPress(_:)))
    lp.minimumPressDuration = 0.1
    addGestureRecognizer(lp)
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
    }

    updateViews(x: intersectionPoints[0].point.x)
  }

  func updateViews(x: CGFloat) {
    pointsView.center = CGPoint(x: x, y: bounds.midY)
    let s = pointInfoView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    pointInfoView.frame.size = s
    pointInfoView.center = CGPoint(x: x, y: pointInfoView.frame.height / 2)
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
  }
}

extension ChartInfoView: UIGestureRecognizerDelegate {
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                         shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
}
