import UIKit
import WordPressShared

func MyProfileViewController(account: WPAccount) -> ImmuTableViewController? {
    guard let api = account.wordPressComRestApi else {
        return nil
    }

    let service = AccountSettingsService(userID: account.userID.intValue, api: api)
    return MyProfileViewController(account: account, service: service)
}

func MyProfileViewController(account: WPAccount, service: AccountSettingsService) -> ImmuTableViewController {
    let controller = MyProfileController(account: account, service: service)
    let viewController = ImmuTableViewController(controller: controller)
    let headerView = MakeHeaderView(account: account)
    headerView.onAddUpdatePhoto = {
        controller.presentGravatarPicker()
    }
    viewController.tableView.tableHeaderView = headerView
    return viewController
}

func MakeHeaderView(account: WPAccount) -> MyProfileHeaderView {
    let defaultImage = UIImage(named: "gravatar")
    let headerView = MyProfileHeaderView.makeFromNib()
    headerView.gravatarImageView.downloadGravatarWithEmail(account.email, placeholderImage: defaultImage!)
    if headerView.gravatarImageView.image == defaultImage {
        headerView.gravatarButton.setTitle(NSLocalizedString("Add a Profile Photo", comment: "Add a profile photo to Me > My Profile"), for: .normal)
    } else {
        headerView.gravatarButton.setTitle("Update Profile Photo", for: .normal)
    }
    return headerView
}

/// MyProfileController requires the `presenter` to be set before using.
/// To avoid problems, it's marked private and should only be initialized using the
/// `MyProfileViewController` factory functions.
private class MyProfileController: SettingsController {
    // MARK: - ImmuTableController

    let title = NSLocalizedString("My Profile", comment: "My Profile view title")

    var immuTableRows: [ImmuTableRow.Type] {
        return [EditableTextRow.self]
    }

    // MARK: - Initialization

    let account: WPAccount
    let service: AccountSettingsService
    var settings: AccountSettings? {
        didSet {
            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: ImmuTableViewController.modelChangedNotification), object: nil)
        }
    }
    var noticeMessage: String? {
        didSet {
            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: ImmuTableViewController.modelChangedNotification), object: nil)
        }
    }

    init(account: WPAccount, service: AccountSettingsService) {
        self.account = account
        self.service = service
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(MyProfileController.loadStatus), name: NSNotification.Name(rawValue: AccountSettingsService.Notifications.refreshStatusChanged), object: nil)
        notificationCenter.addObserver(self, selector: #selector(MyProfileController.loadSettings), name: NSNotification.Name(rawValue: AccountSettingsService.Notifications.accountSettingsChanged), object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func refreshModel() {
        service.refreshSettings()
    }

    @objc func loadStatus() {
        noticeMessage = service.status.errorMessage
    }

    @objc func loadSettings() {
        settings = service.settings
    }

    // MARK: - ImmuTableViewController

    func tableViewModelWithPresenter(_ presenter: ImmuTablePresenter) -> ImmuTable {
        return mapViewModel(settings, presenter: presenter)
    }

    // MARK: - Model mapping

    func mapViewModel(_ settings: AccountSettings?, presenter: ImmuTablePresenter) -> ImmuTable {
        let firstNameRow = EditableTextRow(
            title: NSLocalizedString("First Name", comment: "My Profile first name label"),
            value: settings?.firstName ?? "",
            action: presenter.push(editText(AccountSettingsChange.firstName, service: service)))

        let lastNameRow = EditableTextRow(
            title: NSLocalizedString("Last Name", comment: "My Profile last name label"),
            value: settings?.lastName ?? "",
            action: presenter.push(editText(AccountSettingsChange.lastName, service: service)))

        let displayNameRow = EditableTextRow(
            title: NSLocalizedString("Display Name", comment: "My Profile display name label"),
            value: settings?.displayName ?? "",
            action: presenter.push(editText(AccountSettingsChange.displayName, service: service)))

        let aboutMeRow = EditableTextRow(
            title: NSLocalizedString("About Me", comment: "My Profile 'About me' label"),
            value: settings?.aboutMe ?? "",
            action: presenter.push(editMultilineText(AccountSettingsChange.aboutMe,
                hint: NSLocalizedString("Tell us a bit about you.", comment: "My Profile 'About me' hint text"),
                service: service)))

        return ImmuTable(sections: [
            ImmuTableSection(rows: [
                firstNameRow,
                lastNameRow,
                displayNameRow,
                aboutMeRow
                ])
            ])
    }

    // MARK: Actions

    fileprivate func presentGravatarPicker() {
        WPAppAnalytics.track(.gravatarTapped)

        let pickerViewController = GravatarPickerViewController()
        pickerViewController.onCompletion = { [weak self] image in
            if let updatedGravatarImage = image {
                self?.uploadGravatarImage(updatedGravatarImage)
            }
            self?.dismiss(animated: true, completion: nil)
        }
        pickerViewController.modalPresentationStyle = .formSheet
        self.present(pickerViewController, animated: true, completion: nil)
    }

    // MARK: - Gravatar Helpers

    fileprivate func uploadGravatarImage(_ newGravatar: UIImage) {
        // do stuff
    }
}
