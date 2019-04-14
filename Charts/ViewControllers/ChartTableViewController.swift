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
  var chartsData: [ChartPresentationData]!
  var chartCell: ChartTableViewCell!

  var cells: [ChartTableViewCell] = []

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.register(ChartTableViewCell.self, forCellReuseIdentifier: "ChartCell")
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LineCell")

    let parser: IChartDataParser = ChartDataJsonParser()
    var charts: [ChartPresentationData] = []
    guard var path = Bundle.main.resourceURL else { return }
    path.appendPathComponent("contest")
    try! FileManager.default.contentsOfDirectory(atPath: path.path).sorted().forEach {
      guard let data = try? Data(contentsOf: path.appendingPathComponent($0).appendingPathComponent("overview.json")) else {
        assertionFailure("Can't read file")
        return
      }

      let cd = parser.parseData(data)![0]
      charts.append(ChartPresentationData(cd))
    }
    self.chartsData = charts

    chartsData.forEach {
      let cell = ChartTableViewCell(style: .default, reuseIdentifier: "ChartCell")
      cell.chartData = $0
      cells.append(cell)
    }
}

  // MARK: - Table view data source

  override func numberOfSections(in tableView: UITableView) -> Int {
    return chartsData.count
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let data = chartsData[section]
    return 1 + data.linesCount
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let data = chartsData[indexPath.section]
    if (indexPath.row == 0) {
      return cells[indexPath.section]
    } else {
      let cell = tableView.dequeueReusableCell(withIdentifier: "LineCell", for: indexPath)
      cell.accessoryType = data.isLineVisibleAt(indexPath.row - 1) ? .checkmark : .none
      let chartLine = data.lineAt(indexPath.row - 1)
      cell.textLabel?.text = chartLine.name
      cell.imageView?.image = chartLine.color.image()
      return cell
    }
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    let result: String
    switch section {
    case 0:
      result = "followers"
    case 1:
      result = "actions"
    case 2:
      result = "fruit"
    case 3:
      result = "views"
    case 4:
      result = "fruit proportion"
    default:
      result = ""
    }
    return result
  }

  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if (indexPath.row == 0) {
      return tableView.bounds.width
    }

    return UITableView.automaticDimension
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
    let data = chartsData[indexPath.section]
    let index = indexPath.row - 1
    let visible = data.isLineVisibleAt(index)
    data.setLineVisible(!visible, at: index)
    tableView.reloadRows(at: [indexPath], with: .automatic)
  }

  override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    cells.forEach {
      $0.chartView.rasterize = true
    }
  }

  override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !decelerate {
      cells.forEach {
        $0.chartView.rasterize = false
      }
    }
  }

  override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    cells.forEach {
      $0.chartView.rasterize = false
    }
  }
}
