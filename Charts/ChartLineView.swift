//
//  ChartLineView.swift
//  Charts
//
//  Created by aleksey.belousov on 16/03/2019.
//  Copyright © 2019 aleksey.belousov. All rights reserved.
//

import UIKit

extension IChartLine {
  func makePath() -> UIBezierPath {
    let path = UIBezierPath()
    for i in 0..<values.count {
      let x = CGFloat(i)
      let y = CGFloat(maxY - values[i])
      if i == 0 {
        path.move(to: CGPoint(x: x, y: y))
      } else {
        path.addLine(to: CGPoint(x: x, y: y))
      }
    }

    return path
  }
}

class ChartLineView: UIView {
  var chartLine: IChartLine? {
    didSet {
      guard let chartLine = chartLine else { return }
      xRange = 0..<chartLine.values.count - 1
      yRange = chartLine.minY..<chartLine.maxY
      path = chartLine.makePath()
      let sl = layer as! CAShapeLayer
      sl.strokeColor = chartLine.color.cgColor
      sl.fillColor = UIColor.clear.cgColor
      setNeedsLayout()
    }
  }

  var xRange: Range = 0..<1
  var yRange: Range = 0..<1
  var path: UIBezierPath?

  override class var layerClass: AnyClass { return CAShapeLayer.self }

  override func layoutSubviews() {
    super.layoutSubviews()

    let xScale = bounds.width / CGFloat(xRange.upperBound)
    let xTranslate = CGFloat(0)
    let yScale = bounds.height / CGFloat(yRange.upperBound - yRange.lowerBound)
    let yTranslate = CGFloat(0)

    let sl = layer as! CAShapeLayer
    guard let realPath = path?.copy() as? UIBezierPath else { return }
    let transform = CGAffineTransform.identity.scaledBy(x: xScale, y: yScale)
      .translatedBy(x: xTranslate, y: yTranslate)
    realPath.apply(transform)
    sl.path = realPath.cgPath
  }
}
