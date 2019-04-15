import UIKit

class ChartSettingsView: UIView {

  let spacing: CGFloat = 8

  var maxWidth: CGFloat = 0 {
    didSet {
      calculateLayout()
    }
  }

  private(set) var height: CGFloat = 0

  var buttons: [UIButton] = []

  var chartData: ChartPresentationData! {
    didSet {
      for i in 0..<chartData.linesCount {
        let line = chartData.lineAt(i)
        let b = makeButton(name: line.name, color: line.color)
        b.addTarget(self, action: #selector(onTap(_:)), for: .touchUpInside)
        buttons.append(b)
        addSubview(b)
      }
    }
  }

  func makeButton(name: String, color: UIColor) -> UIButton {
    let b = UIButton(type: .custom)
    b.setImage(UIImage(named: "check"), for: .normal)
    b.setTitleColor(UIColor.white, for: .normal)
    b.tintColor = UIColor.white
    b.setTitle(name, for: .normal)
    b.backgroundColor = color
    let insetAmount: CGFloat = 4
    b.imageEdgeInsets = UIEdgeInsets(top: 0, left: -insetAmount, bottom: 0, right: insetAmount)
    b.titleEdgeInsets = UIEdgeInsets(top: 0, left: insetAmount, bottom: 0, right: -insetAmount)
    b.contentEdgeInsets = UIEdgeInsets(top: 0, left: insetAmount + 10, bottom: 0, right: insetAmount + 10)
    b.layer.cornerRadius = 5
    b.layer.borderColor = color.cgColor
    b.layer.borderWidth = 1
    b.clipsToBounds = true
    b.sizeToFit()
    var f = b.frame
    f.size = CGSize(width: f.width, height: 30)
    b.frame = f
    return b
  }

  func calculateLayout() {
    var x: CGFloat = 0
    var y: CGFloat = 16
    buttons.forEach {
      if x + $0.frame.width > maxWidth - 0 {
        y += ($0.frame.height + spacing)
        x = 0
      }

      var f = $0.frame
      f.origin = CGPoint(x: x, y: y)
      $0.frame = f.integral
      x += (f.width + spacing)
    }
    height = y + 30 + 16
  }

  @objc func onTap(_ sender: UIButton) {
    let i = buttons.index(of: sender)!
    let line = chartData.lineAt(i)
    let visible = chartData.isLineVisibleAt(i)
    if visible {
      sender.setTitleColor(line.color, for: .normal)
      sender.backgroundColor = .clear
    } else {
      sender.setTitleColor(.white, for: .normal)
      sender.backgroundColor = line.color
    }
    chartData.setLineVisible(!visible, at: i)
  }
}
