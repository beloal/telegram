//
//  ChartView.swift
//  Charts
//
//  Created by aleksey.belousov on 16/03/2019.
//  Copyright © 2019 aleksey.belousov. All rights reserved.
//

import UIKit

class ChartView: UIView {

  var chartData: IChartData!

  private func drawLine(_ line: IChartLine) {
    let maxY = line.values.reduce(0) { $1 > $0 ? $1 : $0 }
    let path = UIBezierPath()
    for i in 0..<line.values.count {
      let x = CGFloat(i) / CGFloat(line.values.count) * bounds.width
      let y = bounds.height - CGFloat(line.values[i]) / CGFloat(maxY) * bounds.height
      if i == 0 {
        path.move(to: CGPoint(x: x, y: y))
      } else {
        path.addLine(to: CGPoint(x: x, y: y))
      }
    }
    line.color.setStroke()
    path.stroke()
  }

  override func draw(_ rect: CGRect) {
    for chartLine in chartData.lines {
      drawLine(chartLine)
    }
  }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

  override func layoutSubviews() {
    super.layoutSubviews()
    setNeedsDisplay()
  }
}
