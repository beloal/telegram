import UIKit

class ChartViewController: UIViewController {
  @IBOutlet var chartView: ChartView!
  var chartData: IChartData!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    chartView.chartData = chartData
  }
}
