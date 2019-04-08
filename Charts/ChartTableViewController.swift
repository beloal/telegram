import UIKit

extension UIColor {
  func image() -> UIImage? {
    let rect = CGRect(x: 0, y: 0, width: 12, height: 12)
    UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.main.scale)
    guard let context = UIGraphicsGetCurrentContext() else { return nil }
    context.addPath(UIBezierPath(roundedRect: rect, cornerRadius: 3).cgPath)
    context.clip()
    context.setFillColor(cgColor)
    context.fill(rect)
    let img = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return img
  }
}

class ChartTableViewController: UITableViewController {
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

    tableView.register(ChartTableViewCell.self, forCellReuseIdentifier: "ChartCell")
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LineCell")
  }

  // MARK: - Table view data source

  override func numberOfSections(in tableView: UITableView) -> Int {
    return data.count
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1 + data[section].lines.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let chartData = data[indexPath.section]
      if (indexPath.row == 0) {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChartCell", for: indexPath) as! ChartTableViewCell
        cell.chartData = chartData
        return cell
      } else {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LineCell", for: indexPath)
        cell.accessoryType = .checkmark// chartCell.linesVisibility[indexPath.row - 1] ? .checkmark : .none
        let chartLine = chartData.lines[indexPath.row - 1]
        cell.textLabel?.text = chartLine.name
        cell.imageView?.image = chartLine.color.image()
        return cell
      }
  }

  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if (indexPath.row == 0) {
      return tableView.bounds.width
    }

    return 44
  }

  override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    return self.tableView(tableView, heightForRowAt: indexPath)
  }

  override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
    if indexPath.row == 0 {
      return nil
    }

    return indexPath
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//    let index = indexPath.row - 1
//    chartCell.setLineVisible(!chartCell.linesVisibility[index], atIndex: index)
//    tableView.reloadRows(at: [indexPath], with: .automatic)
  }
}
