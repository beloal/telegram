import UIKit

class ChartHeaderView: UIView {
  private static let dateFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
  private static let zoomOutFont = UIFont.systemFont(ofSize: 12, weight: .regular)

  let datesLabel = UILabel()
  let zoomOutButton = UIButton(type: .system)

  override init(frame: CGRect) {
    super.init(frame: frame)

    datesLabel.font = ChartHeaderView.dateFont
    datesLabel.frame = bounds
    datesLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    datesLabel.textAlignment = .center
    addSubview(datesLabel)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }
}
