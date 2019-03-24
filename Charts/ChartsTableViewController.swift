import UIKit

class ChartsTableViewController: UITableViewController {
  var data: [IChartData]!

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

    let parser: IChartDataParser = ChartDataJsonParser()
    guard let chartData = parser.parseData(data) else { return }
    self.data = chartData
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
  }

  // MARK: - Table view data source

  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return data.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    cell.textLabel?.text = "Chart \(indexPath.row + 1)"
    return cell
  }

  // MARK: - Table view delegate

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let chartData = data[indexPath.row]
    let vc = ChartTableViewController(style: .grouped)
    vc.chartData = chartData
    navigationController?.pushViewController(vc, animated: true)
  }
}
