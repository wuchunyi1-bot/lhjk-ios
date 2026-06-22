#!/usr/bin/env ruby
# 增量添加新 Swift 文件到已有的 Xcode 工程中，不破坏 Pods 等已有引用
# 用法: /opt/homebrew/opt/ruby/bin/ruby add_files_to_project.rb

require 'xcodeproj'

PROJECT_DIR = File.expand_path(File.dirname(__FILE__))
SRC_ROOT = File.join(PROJECT_DIR, 'lhjk-client-new')
PROJECT_PATH = File.join(SRC_ROOT, 'lhjk-client-new.xcodeproj')
TARGET_NAME = 'lhjk-client-new'

# 需要添加的新文件 (相对于 SRC_ROOT)
# 已注册的文件会被自动跳过，只添加新文件
NEW_FILES = [
  # RegisterLogin 模块
  'Other/Common/Extensions/UIColor+Theme.swift',
  'PL/RegisterLogin/Components/BrandHeaderView.swift',
  'PL/RegisterLogin/Components/LoginFieldView.swift',
  'PL/RegisterLogin/Components/OptionChipView.swift',
  'PL/RegisterLogin/OnboardingViewController.swift',
  # My 模块
  'PL/My/Components/FuncRowView.swift',
  'PL/My/Components/SectionTitleView.swift',
  'PL/My/SettingsViewController.swift',
  'PL/My/ProfileViewController.swift',
  'PL/My/PolicyViewController.swift',
  'PL/My/HealthReportViewController.swift',
  'PL/My/AppointmentsViewController.swift',
  'PL/My/DevicesViewController.swift',
  'PL/My/DietPlanViewController.swift',
  'PL/My/MonitoringPlanViewController.swift',
  'PL/My/HealthEvaluationsViewController.swift',
  # BLL/My 路由
  'BLL/My/MyRoutes.swift',
  # DAL/Router
  'DAL/Router/RouteSetup.swift',
  # BLL/RegisterLogin 路由
  'BLL/RegisterLogin/RegisterLoginRoutes.swift',
  # BLL/Home 路由
  'BLL/Home/HomeRoutes.swift',
  # Placeholder
  'Other/Common/Base/PlaceholderViewController.swift',
  # BLL/Health 路由
  'BLL/Health/HealthRoutes.swift',
  # Health Cell
  'PL/Health/MetricCardCell.swift',
  # Health Metrics
  'PL/Health/Metrics/BloodPressureViewController.swift',
  'PL/Health/Metrics/BloodSugarViewController.swift',
  'PL/Health/Metrics/WeightViewController.swift',
  'PL/Health/Metrics/HeartRateViewController.swift',
  'PL/Health/Metrics/MetricRulerView.swift',
  'PL/Health/Metrics/MetricAddViewController.swift',
  'PL/Health/Metrics/SleepViewController.swift',
  'PL/Health/Metrics/SpO2ViewController.swift',
  'PL/Health/Metrics/EcgViewController.swift',
  'PL/Health/Metrics/FundusViewController.swift',
  'PL/Health/Metrics/DigestiveViewController.swift',
  'PL/Health/Metrics/ExerciseFoodViewController.swift',
  # DGCharts Theme
  'Other/Common/Extensions/DGCharts+Theme.swift',
  # Health Record 模块
  'PL/Health/Record/HealthRecordModels.swift',
  'PL/Health/Record/BodyFigureView.swift',
  'PL/Health/Record/RiskBarView.swift',
  'PL/Health/Record/HealthRecordUserInfoCell.swift',
  'PL/Health/Record/HealthRecordBodyCardCell.swift',
  'PL/Health/Record/HealthRecordMetricRowCell.swift',
  'PL/Health/Record/HealthRecordLifestyleCell.swift',
  'PL/Health/Record/HealthRecordHistoryCell.swift',
  'PL/Health/Record/HealthRecordViewController.swift',
  # Health Report — 量化改善指标组件
  'PL/My/Components/StageMetricsCardView.swift',
  # Health Report — 双 TableView Cell
  'PL/My/Report/WeeklyReportCell.swift',
  'PL/My/Report/StageReportCell.swift',
  # Order List
  'PL/My/Order/OrderCardCell.swift',
  'PL/My/Order/OrderListViewController.swift',
  # Service module routes
  'BLL/Service/ServiceRoutes.swift',
  'PL/Service/ServiceListViewController.swift',
  'PL/Service/HealthMallViewController.swift',
  # Me subpages — Membership / Points / Family
  'PL/My/MembershipViewController.swift',
  'PL/My/PointsViewController.swift',
  'PL/My/FamilyViewController.swift',
  # Common extensions
  'Other/Common/Extensions/UIView+Shadow.swift',
  'Other/Common/Extensions/UIButton+Funde.swift',
  # DAL/ECG — 实时心电图波形绘制
  'DAL/ECG/ECGDataBuffer.swift',
  'DAL/ECG/ECGChartView.swift',
  'DAL/ECG/ECGSimulator.swift',
]

puts "📂 Opening project: #{PROJECT_PATH}"
project = Xcodeproj::Project.open(PROJECT_PATH)

# 找到主 target
target = project.targets.find { |t| t.name == TARGET_NAME }
unless target
  abort "❌ Target '#{TARGET_NAME}' not found!"
end

# 找到主 group (应该是第一个，路径与 SRC_ROOT 同名)
main_group = project.main_group.groups.find { |g| g.path == 'lhjk-client-new' || g.name == 'lhjk-client-new' }
unless main_group
  abort "❌ Main group not found!"
end

NEW_FILES.each do |file_path|
  full_path = File.join(SRC_ROOT, file_path)
  unless File.exist?(full_path)
    puts "⚠️  File not found, skipping: #{file_path}"
    next
  end

  # 检查是否已在工程中 (按文件名匹配)
  filename = File.basename(file_path)
  already_exists = target.source_build_phase.files.any? { |bf|
    bf.file_ref&.path == filename
  }

  if already_exists
    puts "⏭️  Already in project, skipping: #{file_path}"
    next
  end

  # 创建嵌套 group (如 PL/RegisterLogin/Components)
  dir_parts = file_path.split('/')
  group_path_parts = dir_parts[0..-2] # 去掉文件名

  current_group = main_group
  group_path_parts.each do |part|
    existing = current_group.groups.find { |g| g.name == part || g.path == part }
    if existing
      current_group = existing
    else
      current_group = current_group.new_group(part, part)
    end
  end

  # 添加文件引用
  file_ref = current_group.new_file(full_path)
  # 确保 sourceTree 正确
  file_ref.source_tree = '<group>'

  # 加入编译
  target.add_file_references([file_ref])

  puts "✅ Added: #{file_path}"
end

# 保存
project.save
puts "\n🎉 Done! Files added. Now open .xcworkspace in Xcode."
