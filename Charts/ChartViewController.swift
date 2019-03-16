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
      // Do any additional setup after loading the view.
  }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
