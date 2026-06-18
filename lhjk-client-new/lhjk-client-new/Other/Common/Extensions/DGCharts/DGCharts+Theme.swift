import DGCharts

/// DGCharts 公共样式配置（LineChartView）
extension LineChartView {
    func applyFundeStyle() { applyFundeBaseStyle() }
}

/// DGCharts 公共样式配置（BarChartView）
extension BarChartView {
    func applyFundeStyle() { applyFundeBaseStyle() }
}

/// 公共基础样式（Line/Bar 通用）
extension BarLineChartViewBase {
    fileprivate func applyFundeBaseStyle() {
        // 交互
        doubleTapToZoomEnabled = false
        pinchZoomEnabled = false
        dragEnabled = true
        highlightPerTapEnabled = true

        // X 轴
        xAxis.labelPosition = .bottom
        xAxis.labelFont = .fdMicro
        xAxis.labelTextColor = .fdMuted
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled = true
        xAxis.axisLineColor = .fdBorder
        xAxis.axisLineWidth = 1

        // 左 Y 轴
        leftAxis.labelFont = .fdMicro
        leftAxis.labelTextColor = .fdMuted
        leftAxis.drawGridLinesEnabled = true
        leftAxis.gridColor = UIColor(hexString: "#E8E8E8")
        leftAxis.gridLineDashLengths = [3, 3]
        leftAxis.drawAxisLineEnabled = false
        leftAxis.drawZeroLineEnabled = false

        // 右 Y 轴
        rightAxis.enabled = false

        // 图例
        legend.font = .fdCaption
        legend.textColor = .fdSubtext
        legend.horizontalAlignment = .center
        legend.verticalAlignment = .top
        legend.orientation = .horizontal

        // 通用
        backgroundColor = .clear
        drawGridBackgroundEnabled = false
        noDataText = "暂无数据"
        noDataFont = .fdBody
        noDataTextColor = .fdMuted
    }

    /// 创建 Funde 风格的数据集
    static func makeFundeDataSet(
        entries: [ChartDataEntry],
        label: String,
        color: UIColor,
        fillAlpha: CGFloat = 0.08,
        lineWidth: CGFloat = 2,
        circleRadius: CGFloat = 3,
        circleHoleRadius: CGFloat = 0
    ) -> LineChartDataSet {
        let ds = LineChartDataSet(entries: entries, label: label)
        ds.setColor(color)
        ds.lineWidth = lineWidth
        ds.circleRadius = circleRadius
        ds.circleHoleRadius = circleHoleRadius
        ds.circleColors = [color]
        ds.mode = .linear
        ds.drawValuesEnabled = false
        ds.drawCircleHoleEnabled = false
        ds.highlightEnabled = true
        ds.highlightColor = color
        ds.drawFilledEnabled = false

        if fillAlpha > 0 {
            let gradientColors = [color.withAlphaComponent(fillAlpha).cgColor, color.withAlphaComponent(0).cgColor]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors as CFArray, locations: [0, 1]) {
                ds.fill = LinearGradientFill(gradient: gradient, angle: 90)
            }
            ds.drawFilledEnabled = true
        }

        return ds
    }

    /// 添加 Funde 风格的参考线
    func addFundeLimitLine(_ value: Double, label: String, color: UIColor, dash: Bool = true) {
        let line = ChartLimitLine(limit: value, label: label)
        line.lineColor = color
        line.lineWidth = 1
        line.lineDashLengths = dash ? [4, 4] : nil
        line.labelPosition = .rightTop
        line.valueFont = .fdMicro
        line.valueTextColor = color
        leftAxis.addLimitLine(line)
    }
}
