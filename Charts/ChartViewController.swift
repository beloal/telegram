//
//  ChartViewController.swift
//  Charts
//
//  Created by aleksey.belousov on 16/03/2019.
//  Copyright © 2019 aleksey.belousov. All rights reserved.
//

import UIKit

class ChartViewController: UIViewController {
  @IBOutlet var chartView: ChartView!
  var chartData: IChartData!
  
  override func viewDidLoad() {
    super.viewDidLoad()

    chartView.chartData = chartData
  }
}
