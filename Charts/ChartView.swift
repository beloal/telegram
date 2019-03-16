//
//  ChartView.swift
//  Charts
//
//  Created by aleksey.belousov on 16/03/2019.
//  Copyright © 2019 aleksey.belousov. All rights reserved.
//

import UIKit

class ChartView: UIView {
  var chartData: IChartData! {
    didSet {
      for line in chartData.lines {
        let v = ChartLineView()
        v.chartLine = line
        lineViews.append(v)
        addSubview(v)
      }
      setNeedsLayout()
    }
  }

  var lineViews: [ChartLineView] = []

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }

  private func setup() {
    clipsToBounds = true
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    for view in lineViews {
      view.frame = bounds
    }
  }
}
