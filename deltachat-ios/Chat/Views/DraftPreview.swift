import UIKit
import DcCore

public protocol DraftPreviewDelegate: class {
    func onAttachmentAdded()
    func onCancelAttachment()
    func onCancelQuote()
    func onAttachmentTapped()
}

public class DraftPreview: UIView {

    lazy var cancelButton: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancelImageView)
        view.accessibilityLabel = String.localized("cancel")
        view.isAccessibilityElement = true
        return view
    }()

    private lazy var cancelImageView: UIImageView = {
        let view = UIImageView(image: UIImage())
        view.tintColor = .systemBlue
        view.image = #imageLiteral(resourceName: "ic_close_36pt").withRenderingMode(.alwaysTemplate)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var upperBorder: UIView = {
        let view = UIView()
        view.backgroundColor = DcColors.colorDisabled
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var mainContentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    init() {
        super.init(frame: .zero)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupSubviews() {
        addSubview(upperBorder)
        addSubview(mainContentView)
        addSubview(cancelButton)
        addConstraints([
            upperBorder.constraintAlignLeadingTo(self),
            upperBorder.constraintAlignTrailingTo(self),
            upperBorder.constraintHeightTo(1),
            upperBorder.constraintAlignTopTo(self, paddingTop: 4),
            mainContentView.constraintAlignTopTo(upperBorder, paddingTop: 4),
            mainContentView.constraintAlignLeadingTo(self),
            mainContentView.constraintAlignBottomTo(self, paddingBottom: 4),
            mainContentView.constraintTrailingToLeadingOf(cancelButton, paddingTrailing: -2),
            cancelButton.constraintAlignTrailingTo(self, paddingTrailing: 14),
            cancelButton.constraintWidthTo(36),
            cancelButton.constraintHeightTo(36),
            cancelImageView.constraintAlignLeadingTo(cancelButton, paddingLeading: 6),
            cancelImageView.constraintAlignTrailingTo(cancelButton, paddingTrailing: 6),
            cancelImageView.constraintAlignTopTo(cancelButton, paddingTop: 6),
            cancelImageView.constraintAlignBottomTo(cancelButton, paddingBottom: 6),
            cancelButton.constraintCenterYTo(self),
        ])
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(cancel))
        cancelButton.addGestureRecognizer(recognizer)
        backgroundColor = DcColors.chatBackgroundColor
    }

    @objc public func cancel() {
        safe_fatalError("cancel needs to be implemented in inheriting class")
    }

    public func configure(draft: DraftModel) {
        safe_fatalError("configure needs to be implemented in inheriting class")
    }
}
