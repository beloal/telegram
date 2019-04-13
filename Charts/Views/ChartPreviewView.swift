import UIKit

protocol ChartPreviewViewDelegate: AnyObject {
  func chartPreviewView(_ view: ChartPreviewView, didChangeMinX minX: Int, maxX: Int)
}

class ChartPreviewView: UIView {
  let previewContainerView = UIView()
  let viewPortView = UIView()
  let leftBoundView = UIView()
  let rightBoundView = UIView()
  let leftTintView = UIView()
  let rightTintView = UIView()
  var previewViews: [ChartLineView] = []

  var minX = 0
  var maxX = 0
  weak var delegate: ChartPreviewViewDelegate?

  override var frame: CGRect {
    didSet {
      if chartData != nil {
        updateViewPort()
      }
    }
  }

  var chartData: ChartPresentationData! {
    didSet {
      previewViews.forEach { $0.removeFromSuperview() }
      previewViews.removeAll()
      for i in 0..<chartData.linesCount {
        let line = chartData.lineAt(i)
        let v = ChartLineView()
        v.chartLine = line
        v.frame = previewContainerView.bounds
        v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        if let last = previewViews.last {
          previewContainerView.insertSubview(v, belowSubview: last)
        } else {
          previewContainerView.addSubview(v)
        }
        previewViews.append(v)
      }
      previewViews.forEach { $0.setY(min: chartData.lower, max: chartData.upper) }
      let count = chartData.pointsCount - 1
      minX = count - count / 5
      maxX = count
      updateViewPort()
    }
  }

  func setLineVisible(_ visible: Bool, atIndex index: Int) {
    previewViews.forEach { $0.setY(min: chartData.lower, max: chartData.upper, animationStyle: .animated) }
    let pv = previewViews[index]
    UIView.animate(withDuration: kAnimationDuration) {
      pv.alpha = visible ? 1 : 0
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    previewContainerView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(previewContainerView)
    let t = previewContainerView.topAnchor.constraint(equalTo: topAnchor)
    let b = previewContainerView.bottomAnchor.constraint(equalTo: bottomAnchor)
    t.priority = .defaultHigh
    b.priority = .defaultHigh
    t.constant = 3
    b.constant = -3
    NSLayoutConstraint.activate([
      previewContainerView.leftAnchor.constraint(equalTo: leftAnchor),
      previewContainerView.rightAnchor.constraint(equalTo: rightAnchor),
      t,
      b])

    viewPortView.backgroundColor = UIColor(white: 0, alpha: 0.05)
    viewPortView.clipsToBounds = true
    viewPortView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(viewPortView)

    leftBoundView.backgroundColor = UIColor(white: 0, alpha: 0.2)
    rightBoundView.backgroundColor = UIColor(white: 0, alpha: 0.2)
    viewPortView.addSubview(leftBoundView)
    viewPortView.addSubview(rightBoundView)

    let pan = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
    viewPortView.addGestureRecognizer(pan)

    let leftPan = UIPanGestureRecognizer(target: self, action: #selector(onLeftPan(_:)))
    let rightPan = UIPanGestureRecognizer(target: self, action: #selector(onRightPan(_:)))
    leftBoundView.addGestureRecognizer(leftPan)
    rightBoundView.addGestureRecognizer(rightPan)
    clipsToBounds = true
  }

  @objc func onPan(_ sender: UIPanGestureRecognizer) {
    if sender.state == .changed {
      let p = sender.translation(in: viewPortView)
      let count = chartData.labels.count - 1
      let x = Int((viewPortView.frame.minX + p.x) / bounds.width * CGFloat(count))
      let dx = maxX - minX
      let mx = x + dx

      if x > 0 && mx < count {
        viewPortView.frame = viewPortView.frame.offsetBy(dx: p.x, dy: 0)
        sender.setTranslation(CGPoint(x: 0, y: 0), in: viewPortView)
        if x != minX {
          minX = x
          maxX = mx
          delegate?.chartPreviewView(self, didChangeMinX: minX, maxX: maxX)
        }
      } else if minX > 0 && x <= 0 {
        setX(min: 0, max: dx)
      } else if maxX < count && mx >= count {
        setX(min: count - dx, max: count)
      }
    }
  }

  @objc func onLeftPan(_ sender: UIPanGestureRecognizer) {
    if sender.state == .changed {
      let p = sender.translation(in: leftBoundView)
      let count = chartData.labels.count - 1
      let x = Int((viewPortView.frame.minX + p.x) / bounds.width * CGFloat(count))

      if x > 0 && x < maxX && maxX - x >= count / 10 {
        var f = viewPortView.frame
        f = CGRect(x: f.minX + p.x, y: f.minY, width: f.width - p.x, height: f.height)
        viewPortView.frame = f
        rightBoundView.frame = CGRect(x: viewPortView.bounds.width - 14, y: 0, width: 44, height: viewPortView.bounds.height)
        sender.setTranslation(CGPoint(x: 0, y: 0), in: leftBoundView)
        if x != minX {
          minX = x
          delegate?.chartPreviewView(self, didChangeMinX: minX, maxX: maxX)
        }
      } else if x <= 0 && minX > 0 {
        setX(min: 0, max: maxX)
      }
    }
  }

  @objc func onRightPan(_ sender: UIPanGestureRecognizer) {
    let p = sender.translation(in: viewPortView)
    let count = chartData.labels.count - 1
    let mx = Int((viewPortView.frame.maxX + p.x) / bounds.width * CGFloat(count))

    if mx > minX && mx < count && mx - minX >= count / 10 {
      var f = viewPortView.frame
      f = CGRect(x: f.minX, y: f.minY, width: f.width + p.x, height: f.height)
      viewPortView.frame = f
      rightBoundView.frame = CGRect(x: viewPortView.bounds.width - 14, y: 0, width: 44, height: viewPortView.bounds.height)
      sender.setTranslation(CGPoint(x: 0, y: 0), in: leftBoundView)
      if mx != maxX {
        maxX = mx
        delegate?.chartPreviewView(self, didChangeMinX: minX, maxX: maxX)
      }
    } else if mx >= count && maxX < count {
      setX(min: minX, max: count)
    }
  }

  func setX(min: Int, max: Int) {
    assert(min < max)
    minX = min
    maxX = max
    updateViewPort()
    delegate?.chartPreviewView(self, didChangeMinX: minX, maxX: maxX)
  }

  func updateViewPort() {
    let count = CGFloat(chartData.labels.count - 1)
    viewPortView.frame = CGRect(x: CGFloat(minX) / count * bounds.width,
                                y: bounds.minY,
                                width: CGFloat(maxX - minX) / count * bounds.width,
                                height: bounds.height)
    leftBoundView.frame = CGRect(x: -30, y: 0, width: 44, height: viewPortView.bounds.height)
    rightBoundView.frame = CGRect(x: viewPortView.bounds.width - 14, y: 0, width: 44, height: viewPortView.bounds.height)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }
}
