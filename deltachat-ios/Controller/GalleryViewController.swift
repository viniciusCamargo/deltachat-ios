import UIKit
import DcCore

class GalleryViewController: UIViewController {

    private let dcContext: DcContext
    // MARK: - data
    private var mediaMessageIds: [Int]
    private var items: [Int: GalleryItem] = [:]

    // MARK: - subview specs
    private let gridDefaultSpacing: CGFloat = 5

    private lazy var gridLayout: GridCollectionViewFlowLayout = {
        let layout = GridCollectionViewFlowLayout()
        layout.minimumLineSpacing = gridDefaultSpacing
        layout.minimumInteritemSpacing = gridDefaultSpacing
        layout.format = .square
        return layout
    }()

    private lazy var grid: UICollectionView = {
        let collection = UICollectionView(frame: .zero, collectionViewLayout: gridLayout)
        collection.dataSource = self
        collection.delegate = self
        collection.register(GalleryCell.self, forCellWithReuseIdentifier: GalleryCell.reuseIdentifier)
        collection.contentInset = UIEdgeInsets(top: gridDefaultSpacing, left: gridDefaultSpacing, bottom: gridDefaultSpacing, right: gridDefaultSpacing)
        collection.backgroundColor = DcColors.defaultBackgroundColor
        collection.delaysContentTouches = false
        collection.alwaysBounceVertical = true
        collection.isPrefetchingEnabled = true
        collection.prefetchDataSource = self
        return collection
    }()

    private lazy var timeLabel: GalleryTimeLabel = {
        let view = GalleryTimeLabel()
        view.hide(animated: false)
        return view
    }()

    private lazy var emptyStateView: EmptyStateLabel = {
        let label = EmptyStateLabel()
        label.text = String.localized("tab_gallery_empty_hint")
        label.isHidden = true
        return label
    }()

    init(context: DcContext, mediaMessageIds: [Int]) {
        self.dcContext = context
        self.mediaMessageIds = mediaMessageIds
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        title = String.localized("images_and_videos")
        if mediaMessageIds.isEmpty {
            emptyStateView.isHidden = false
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        grid.reloadData()
        setupContextMenuIfNeeded()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.reloadCollectionViewLayout()
    }

    // MARK: - setup
    private func setupSubviews() {
        view.addSubview(grid)
        grid.translatesAutoresizingMaskIntoConstraints = false
        grid.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        grid.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        grid.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        grid.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        view.addSubview(timeLabel)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10).isActive = true
        timeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        view.addSubview(emptyStateView)
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor).isActive = true
        emptyStateView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor).isActive = true
        emptyStateView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
        emptyStateView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
    }

    private func setupContextMenuIfNeeded() {
        UIMenuController.shared.menuItems = [
            UIMenuItem(title: String.localized("delete"), action: #selector(GalleryCell.itemDelete(_:))),
        ]
        UIMenuController.shared.update()
    }

    // MARK: - updates
    private func updateFloatingTimeLabel() {
        if let indexPath = grid.indexPathsForVisibleItems.min() {
            let msgId = mediaMessageIds[indexPath.row]
            let msg = DcMsg(id: msgId)
            timeLabel.update(date: msg.sentDate)
        }
    }

    private func deleteItem(at indexPath: IndexPath) {
        let msgId = mediaMessageIds.remove(at: indexPath.row)
        self.dcContext.deleteMessage(msgId: msgId)
        self.grid.deleteItems(at: [indexPath])
    }
}

extension GalleryViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { if items[$0.row] == nil {
            let item = GalleryItem(msgId: mediaMessageIds[$0.row])
            items[$0.row] = item
        }}
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension GalleryViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaMessageIds.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let galleryCell = collectionView.dequeueReusableCell(
                withReuseIdentifier: GalleryCell.reuseIdentifier,
                for: indexPath) as? GalleryCell else {
            return UICollectionViewCell()
        }

        let msgId = mediaMessageIds[indexPath.row]
        var item: GalleryItem
        if let galleryItem = items[indexPath.row] {
            item = galleryItem
        } else {
            let galleryItem = GalleryItem(msgId: msgId)
            items[indexPath.row] = galleryItem
            item = galleryItem
        }
        galleryCell.update(item: item)
        UIMenuController.shared.setMenuVisible(false, animated: true)
        return galleryCell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let msgId = mediaMessageIds[indexPath.row]
        showPreview(msgId: msgId)
        collectionView.deselectItem(at: indexPath, animated: true)
        UIMenuController.shared.setMenuVisible(false, animated: true)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        updateFloatingTimeLabel()
        timeLabel.show(animated: true)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateFloatingTimeLabel()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        timeLabel.hide(animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    // MARK: - context menu
    // context menu for iOS 11, 12
    func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return action ==  #selector(GalleryCell.itemDelete(_:))
    }

    func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {

        switch action {
        case #selector(GalleryCell.itemDelete(_:)):
            deleteItem(at: indexPath)
        default:
            break
        }
    }

    // context menu for iOS 13+
    @available(iOS 13, *)
    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        guard let galleryCell = collectionView.cellForItem(at: indexPath) as? GalleryCell, let item = galleryCell.item else {
            return nil
        }

        return UIContextMenuConfiguration(
            identifier: nil,
            previewProvider: {
                return XLPreviewViewController(imageUrl: item.fileUrl)
            },
            actionProvider: { [weak self] _ in
                return self?.makeContextMenu(indexPath: indexPath)
            }
        )
    }

    @available(iOS 13, *)
    private func makeContextMenu(indexPath: IndexPath) -> UIMenu {
        let deleteAction = UIAction(
            title: String.localized("delete"),
            image: UIImage(systemName: "trash")) { _ in
            self.deleteItem(at: indexPath)
        }

        return UIMenu(
            title: "",
            image: nil,
            identifier: nil,
            children: [deleteAction]
        )
    }
}

// MARK: - grid layout + updates
private extension GalleryViewController {
    func reloadCollectionViewLayout() {

        // columns specification
        let phonePortrait = 3
        let phoneLandscape = 4
        let padPortrait = 5
        let padLandscape = 8

        let orientation = UIApplication.shared.statusBarOrientation
        let deviceType = UIDevice.current.userInterfaceIdiom

        var gridDisplay: GridDisplay?
        if deviceType == .phone {
            if orientation.isPortrait {
                gridDisplay = .grid(columns: phonePortrait)
            } else {
                gridDisplay = .grid(columns: phoneLandscape)
            }
        } else if deviceType == .pad {
            if orientation.isPortrait {
                gridDisplay = .grid(columns: padPortrait)
            } else {
                gridDisplay = .grid(columns: padLandscape)
            }
        }

        if let gridDisplay = gridDisplay {
            gridLayout.display = gridDisplay
        } else {
            safe_fatalError("undefined format")
        }
        let containerWidth = view.bounds.width - view.safeAreaInsets.left - view.safeAreaInsets.right - 2 * gridDefaultSpacing
        gridLayout.containerWidth = containerWidth
    }
}

// MARK: - coordinator
extension GalleryViewController {
    func showPreview(msgId: Int) {
        guard let index = mediaMessageIds.index(of: msgId) else {
            return
        }

        let previewController = PreviewController(type: .multi(mediaMessageIds, index))
        present(previewController, animated: true, completion: nil)
    }
}

private class XLPreviewViewController: UIViewController {

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    init(imageUrl: URL?) {
        super.init(nibName: nil, bundle: nil)
        if let url = imageUrl {
            imageView.image = UIImage(named: url.relativePath)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.leftAnchor.constraint(equalTo: view.leftAnchor),
            imageView.rightAnchor.constraint(equalTo: view.rightAnchor),
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let width = view.bounds.width
        if let image = imageView.image {
            let height = image.size.height * (width / image.size.width)
            preferredContentSize = CGSize(width: width, height: height)
        }
    }
}
