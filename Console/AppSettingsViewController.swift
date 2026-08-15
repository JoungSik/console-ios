import UIKit

final class AppSettingsViewController: UITableViewController {
    private static let topInsetAdjustment: CGFloat = -16

    private let openWebSettings: (URL) -> Void

    init(openWebSettings: @escaping (URL) -> Void) {
        self.openWebSettings = openWebSettings
        super.init(style: .insetGrouped)
        title = "설정"
        tableView.backgroundColor = AppTheme.background
        tableView.separatorColor = AppTheme.border
        tableView.tintColor = AppTheme.accent
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInset.top = Self.topInsetAdjustment
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else {
            return 0
        }

        switch section {
        case .settings:
            return SettingItem.allCases.count
#if DEBUG
        case .development:
            return DevelopmentItem.allCases.count
#endif
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }

        switch section {
        case .settings:
            return settingsCell(at: indexPath)
#if DEBUG
        case .development:
            return developmentCell(at: indexPath)
#endif
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
#if DEBUG
        guard Section(rawValue: section) == .development else {
            return nil
        }

        return "개발 정보"
#else
        return nil
#endif
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section == Section.allCases.count - 1 else {
            return nil
        }

        return Self.versionDescription
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard Section(rawValue: indexPath.section) == .settings,
              let item = SettingItem(rawValue: indexPath.row) else {
            return
        }

        openWebSettings(item.destination)
    }
}

private extension AppSettingsViewController {
    static var versionDescription: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
        return "버전 \(version)"
    }

    func settingsCell(at indexPath: IndexPath) -> UITableViewCell {
        guard let item = SettingItem(rawValue: indexPath.row) else {
            return UITableViewCell()
        }

        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.backgroundColor = AppTheme.surface
        cell.textLabel?.textColor = AppTheme.primaryText
        cell.textLabel?.text = item.title
        cell.imageView?.image = UIImage(systemName: item.iconName)
        cell.imageView?.tintColor = AppTheme.accent
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default

        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = AppTheme.border
        cell.selectedBackgroundView = selectedBackgroundView

        return cell
    }

#if DEBUG
    func developmentCell(at indexPath: IndexPath) -> UITableViewCell {
        guard let item = DevelopmentItem(rawValue: indexPath.row) else {
            return UITableViewCell()
        }

        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.backgroundColor = AppTheme.surface
        cell.textLabel?.textColor = AppTheme.primaryText
        cell.textLabel?.text = item.title
        cell.detailTextLabel?.textColor = AppTheme.secondaryText
        cell.detailTextLabel?.text = item.value
        cell.selectionStyle = .none
        return cell
    }
#endif

    enum Section: Int, CaseIterable {
        case settings
#if DEBUG
        case development
#endif
    }

    enum SettingItem: Int, CaseIterable {
        case account
        case plugins
        case pushNotifications
        case privacy

        var title: String {
            switch self {
            case .account:
                return "계정 설정"
            case .plugins:
                return "플러그인 설정"
            case .pushNotifications:
                return "푸시 알림"
            case .privacy:
                return "개인정보 처리방침"
            }
        }

        var destination: URL {
            switch self {
            case .account:
                return AppEnvironment.accountURL
            case .plugins:
                return AppEnvironment.pluginsURL
            case .pushNotifications:
                return AppEnvironment.pushNotificationsURL
            case .privacy:
                return AppEnvironment.privacyURL
            }
        }

        var iconName: String {
            switch self {
            case .account:
                return "person.crop.circle"
            case .plugins:
                return "puzzlepiece.extension"
            case .pushNotifications:
                return "bell"
            case .privacy:
                return "hand.raised"
            }
        }
    }

#if DEBUG
    enum DevelopmentItem: Int, CaseIterable {
        case serverAddress
        case buildEnvironment

        var title: String {
            switch self {
            case .serverAddress:
                return "서버 주소"
            case .buildEnvironment:
                return "빌드 환경"
            }
        }

        var value: String {
            switch self {
            case .serverAddress:
                return AppEnvironment.baseURL.absoluteString
            case .buildEnvironment:
                return AppEnvironment.name
            }
        }
    }
#endif
}
