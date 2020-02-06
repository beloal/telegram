import UIKit
import MapKit

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

fileprivate struct ChartDateFofmatter: IFormatter {
  private let formatter = DateFormatter()

  init() {
    formatter.dateFormat = "MMM dd"
  }

  func string(from value: Int) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(value))
    return formatter.string(from: date)
  }
}

fileprivate struct ChartDistanceFormatter: IFormatter {
  private let formatter = MKDistanceFormatter()

  init() {
    formatter.unitStyle = .abbreviated
    formatter.units = .metric
  }

  func string(from value: Int) -> String {
    formatter.string(fromDistance: CLLocationDistance(value / 1_000_000))
  }
}

class ChartTableViewController: UITableViewController {
  var chartsData: [ChartPresentationData]!
  var chartCell: ChartTableViewCell!

  var cells: [ChartTableViewCell] = []
  var themeBarItem: UIBarButtonItem!

  override func viewDidLoad() {
    super.viewDidLoad()

    themeBarItem = UIBarButtonItem(title: Theme.isNightTheme ? "Day Mode" : "Night Mode",
                                   style: .plain,
                                   target: self,
                                   action: #selector(onThemeChange(_:)))
    self.navigationItem.rightBarButtonItem = themeBarItem

    tableView.register(ChartTableViewCell.self, forCellReuseIdentifier: "ChartCell")
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LineCell")

    let parser: IChartDataParser = ChartDataJsonParser(formatter: ChartDistanceFormatter())
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

    guard let kmlPath = Bundle.main.resourceURL else { return }
    let kmlData = try! Data(contentsOf: kmlPath.appendingPathComponent("points"))
    let kmlString = String(data: kmlData, encoding: .utf8)
    let points = KmlPoints(kmlString!.trimmingCharacters(in: .newlines))
    self.chartsData = charts

//    chartsData.forEach {
      let cell = ChartTableViewCell(style: .default, reuseIdentifier: "ChartCell")
      cell.chartData = chartsData[0]
      cells.append(cell)
      cell.chartView.maxWidth = UIScreen.main.bounds.width
//    }

    updateColors()
  }

  func updateColors() {
    let theme = Theme.currentTheme
    tableView.backgroundColor = theme.background
    tableView.separatorColor = theme.gridLine
    tableView.visibleCells.forEach {
      $0.backgroundColor = theme.chartBackground
      $0.textLabel?.textColor = theme.black
    }
    cells.forEach {
      $0.backgroundColor = theme.chartBackground
      $0.chartView.previewSelectorColor = theme.previewSelector
      $0.chartView.previewTintColor = theme.previewTint
      $0.chartView.gridTextColor = theme.gridText
      $0.chartView.gridLineColor = theme.gridLine
      $0.chartView.headerTextColor = theme.black
      $0.chartView.bgColor = theme.background
      $0.chartView.maskColor = theme.barMask
    }
    self.navigationController?.navigationBar.barStyle = theme.barStyle
    themeBarItem.title = Theme.isNightTheme ? "Day Mode" : "Night Mode"
  }

  @objc func onThemeChange(_ sender: AnyObject) {
    Theme.isNightTheme = !Theme.isNightTheme
    updateColors()
  }

  // MARK: - Table view data source

  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1// chartsData.count
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
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
      cell.backgroundColor = Theme.currentTheme.chartBackground
      cell.textLabel?.textColor = Theme.currentTheme.black
      return cell
    }
  }

//  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//    let result: String
//    switch section {
//    case 0:
//      result = "followers"
//    case 1:
//      result = "actions"
//    case 2:
//      result = "fruit"
//    case 3:
//      result = "views"
//    case 4:
//      result = "fruit proportion"
//    default:
//      result = ""
//    }
//    return result
//  }

  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if (indexPath.row == 0) {
      return cells[indexPath.section].chartView.height
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
