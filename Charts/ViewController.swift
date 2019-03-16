import UIKit

class ViewController: UIViewController {
  let parser: IChartDataParser = ChartDataJsonParser()

  override func viewDidLoad() {
    super.viewDidLoad()

    guard let fileUrl = Bundle.main.url(forResource: "chart_data", withExtension: "json") else {
      assertionFailure("File not found")
      return
    }

    guard let data = try? Data(contentsOf: fileUrl) else {
      assertionFailure("Can't read file")
      return
    }

    if let chartData = parser.parseData(data) {
      let chartList = ChartsTableViewController()
      chartList.data = chartData
      navigationController?.setViewControllers([chartList], animated: false)
    }
  }
}


