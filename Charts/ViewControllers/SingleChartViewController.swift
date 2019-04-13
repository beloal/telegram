import UIKit

class SingleChartViewController: UITableViewController {
  var chartData: ChartPresentationData?

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.register(ChartTableViewCell.self, forCellReuseIdentifier: "ChartCell")
  }

  // MARK: - Table view data source

  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ChartCell", for: indexPath) as! ChartTableViewCell
    cell.chartData = chartData
    return cell
  }

  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return tableView.bounds.width
  }

  override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    return self.tableView(tableView, heightForRowAt: indexPath)
  }

  override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
    return nil
  }
}
