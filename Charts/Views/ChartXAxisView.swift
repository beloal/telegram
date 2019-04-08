import UIKit

fileprivate class ChartXAxisInnerView: UIView {
  private let font = UIFont.systemFont(ofSize: 12, weight: .regular)
  var lowerBound = 0
  var upperBound = 0
  var steps: [String] = []
  var labels: [UILabel] = []

  override var frame: CGRect {
    didSet {
      if upperBound > 0 && lowerBound > 0 {
        updateLabels()
      }
    }
  }

  func makeLabel(text: String) -> UILabel {
    let label = UILabel()
    label.font = font
    label.textColor = UIColor(white: 0, alpha: 0.3)
    label.text = text
    label.sizeToFit()
    return label
  }

  func setBounds(lower: Int, upper: Int, steps: [String]) {
    lowerBound = lower
    upperBound = upper
    self.steps = steps
    labels.forEach { $0.removeFromSuperview() }
    labels.removeAll()

    for step in steps {
      let label = makeLabel(text: step)
      labels.append(label)
      addSubview(label)
    }

    updateLabels()
  }

  func updateLabels() {
    let step = CGFloat(upperBound - lowerBound) / CGFloat(labels.count - 1)
    for i in 0..<labels.count {
      let x = bounds.width * step * CGFloat(i) / CGFloat(upperBound - lowerBound)
      let l = labels[i]
      var f = l.frame
      let adjust = bounds.width > 0 ? x / bounds.width : 0
      f.origin = CGPoint(x: x - f.width * adjust, y: 0)
      l.frame = f.integral
    }
  }
}

class ChartXAxisView: UIView {
  let formatter = DateFormatter()
  var lowerBound = 0
  var upperBound = 0

  var labels: [String] = []
  var values: [Date] = [] {
    didSet {
      labels = values.map{ formatter.string(from: $0) }
    }
  }

  private var labelsView: ChartXAxisInnerView?

  override init(frame: CGRect) {
    super.init(frame: frame)
    formatter.dateFormat = "MMM dd"
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }

  func setBounds(lower: Int, upper: Int) {
    lowerBound = lower
    upperBound = upper
    let step = CGFloat(upper - lower) / 5

    var steps: [String] = []
    for i in 0..<5 {
      let x = lower + Int(round(step * CGFloat(i)))
      steps.append(labels[x])
    }
    steps.append(labels[upper])

    let lv = ChartXAxisInnerView()
    lv.frame = bounds
    lv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    addSubview(lv)

    if let labelsView = labelsView {
      labelsView.removeFromSuperview()
    }

    lv.setBounds(lower: lower, upper: upper, steps: steps)
    labelsView = lv
  }
}
