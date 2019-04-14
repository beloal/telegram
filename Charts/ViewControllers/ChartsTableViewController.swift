import UIKit

class ChartsTableViewController: UITableViewController {
  var data: [IChartData]!

  override func viewDidLoad() {
    super.viewDidLoad()

//    guard let fileUrl = Bundle.main.url(forResource: "chart_data", withExtension: "json") else {
//      assertionFailure("File not found")
//      return
//    }
//
//    guard let data = try? Data(contentsOf: fileUrl) else {
//      assertionFailure("Can't read file")
//      return
//    }

    let parser: IChartDataParser = ChartDataJsonParser()
//    guard let chartData = parser.parseData(data) else { return }
//    self.data = chartData
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")



    var charts: [IChartData] = []
    guard var path = Bundle.main.resourceURL else { return }
    path.appendPathComponent("contest")
    try! FileManager.default.contentsOfDirectory(atPath: path.path).sorted().forEach {
      guard let data = try? Data(contentsOf: path.appendingPathComponent($0).appendingPathComponent("overview.json")) else {
        assertionFailure("Can't read file")
        return
      }

      let cd = parser.parseData(data)![0]
      charts.append(cd)
    }
    self.data = charts
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
//    vc.data = ChartPresentationData(chartData)
    navigationController?.pushViewController(vc, animated: true)
  }
}
