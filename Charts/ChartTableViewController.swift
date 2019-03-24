import UIKit

extension UIColor {
  func image() -> UIImage? {
    let rect = CGRect(x: 0, y: 0, width: 12, height: 12)
    UIGraphicsBeginImageContext(rect.size)
    guard let context = UIGraphicsGetCurrentContext() else { return nil }
    context.setFillColor(cgColor)
    context.fill(rect)
    let img = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return img
  }
}

class ChartTableViewController: UITableViewController {
  var chartData: IChartData!
  var chartCell: ChartTableViewCell!

  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.register(ChartTableViewCell.self, forCellReuseIdentifier: "ChartCell")
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LineCell")
  }

  // MARK: - Table view data source

  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1 + chartData.lines.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if (indexPath.section == 0) {
      if (indexPath.row == 0) {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChartCell", for: indexPath) as! ChartTableViewCell
        cell.chartData = chartData
        chartCell = cell
        return cell
      } else {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LineCell", for: indexPath)
        cell.accessoryType = chartCell.linesVisibility[indexPath.row - 1] ? .checkmark : .none
        let chartLine = chartData.lines[indexPath.row - 1]
        cell.textLabel?.text = chartLine.name
        cell.imageView?.image = chartLine.color.image()
        cell.imageView?.layer.cornerRadius = 3
        cell.imageView?.clipsToBounds = true
        return cell
      }
    } else {
      return UITableViewCell()
    }
  }

  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if (indexPath.section == 0 && indexPath.row == 0) {
      return tableView.bounds.width
    }

    return UITableView.automaticDimension
  }

  override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
    if indexPath.section != 0 {
      return nil
    }

    if indexPath.row == 0 {
      return nil
    }

    return indexPath
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let index = indexPath.row - 1
    chartCell.setLineVisible(!chartCell.linesVisibility[index], atIndex: index)
    tableView.reloadRows(at: [indexPath], with: .automatic)
  }
}
