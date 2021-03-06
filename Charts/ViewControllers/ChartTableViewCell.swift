import UIKit

class ChartTableViewCell: UITableViewCell {
  let chartView = ChartView()
  var chartData: ChartPresentationData? {
    didSet {
      chartView.chartData = chartData
    }
  }
  override var frame: CGRect {
    didSet {
      separatorInset.left = bounds.width
    }
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none

    chartView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(chartView)

    let l = chartView.leftAnchor.constraint(equalTo: contentView.leftAnchor)
    let r = chartView.rightAnchor.constraint(equalTo: contentView.rightAnchor)
    l.constant = 16
    r.constant = -16

    NSLayoutConstraint.activate([l, r,
                                 chartView.topAnchor.constraint(equalTo: contentView.topAnchor),
                                 chartView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
      ])
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }
}
