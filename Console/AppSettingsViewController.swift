import UIKit

final class AppSettingsViewController: UITableViewController {
    private let openAccount: () -> Void
    private let metadata = AppMetadata.current

    init(openAccount: @escaping () -> Void) {
        self.openAccount = openAccount
        super.init(style: .insetGrouped)
        title = "앱 설정"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Section(rawValue: section)?.rowCount ?? 0
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section(rawValue: section)?.title
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.selectionStyle = .none

        switch Section(rawValue: indexPath.section) {
        case .about:
            cell.textLabel?.text = metadata.description
            cell.textLabel?.numberOfLines = 0
            cell.detailTextLabel?.text = nil
        case .environment:
            configureEnvironmentCell(cell, row: indexPath.row)
        case .account:
            cell.textLabel?.text = "웹 계정 설정"
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        case nil:
            break
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if Section(rawValue: indexPath.section) == .account {
            openAccount()
        }
    }

    private func configureEnvironmentCell(_ cell: UITableViewCell, row: Int) {
        switch row {
        case 0:
            cell.textLabel?.text = "환경"
            cell.detailTextLabel?.text = AppEnvironment.name
        case 1:
            cell.textLabel?.text = "서버"
            cell.detailTextLabel?.text = AppEnvironment.baseURL.absoluteString
            cell.detailTextLabel?.adjustsFontSizeToFitWidth = true
        default:
            cell.textLabel?.text = "버전"
            cell.detailTextLabel?.text = versionDescription
        }
    }

    private var versionDescription: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"
        return "\(version) (\(build))"
    }
}

private extension AppSettingsViewController {
    enum Section: Int, CaseIterable {
        case about
        case environment
        case account

        var title: String? {
            switch self {
            case .about:
                return AppMetadata.current.name
            case .environment:
                return "빌드 정보"
            case .account:
                return nil
            }
        }

        var rowCount: Int {
            switch self {
            case .about, .account:
                return 1
            case .environment:
                return 3
            }
        }
    }
}
