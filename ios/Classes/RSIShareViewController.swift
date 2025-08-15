//
//  RSIShareViewController.swift
//  file_share_intent
//
//  Created by Kasem Mohamed on 2024-01-25.
//

import AVFoundation
import MobileCoreServices
import Social
import UIKit

// MARK: - Base Share View Controller (UIViewController-based)

@available(swift, introduced: 5.0)
open class RSIBaseShareViewController: UIViewController {
    var hostAppBundleIdentifier = ""
    var appGroupId = ""
    var sharedMedia: [SharedMediaFile] = []
    
    // Configuration options
    open var showUI: Bool = false
    open var processingMessage: String = "Processing..."
    open var autoRedirect: Bool = true
    
    private var loadingView: UIView?
    private var activityIndicator: UIActivityIndicatorView?
    private var messageLabel: UILabel?
    
    /// Override this method to return false if you don't want to redirect to host app automatically
    /// Default is true
    open func shouldAutoRedirect() -> Bool {
        return autoRedirect
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        // load group and app id from build info
        loadIds()
        
        if showUI {
            setupUI()
        }
        
        // Process attachments immediately
        processAttachments()
    }
    
    private func setupUI() {
        if #available(iOS 13.0, *) {
            view.backgroundColor = UIColor.systemBackground
        } else {
            view.backgroundColor = UIColor.white
        }
        
        // Create loading view
        loadingView = UIView()
        loadingView?.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            loadingView?.backgroundColor = UIColor.systemBackground
        } else {
            loadingView?.backgroundColor = UIColor.white
        }
        view.addSubview(loadingView!)
        
        // Activity indicator
        if #available(iOS 13.0, *) {
            activityIndicator = UIActivityIndicatorView(style: .large)
        } else {
            activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
            activityIndicator?.color = UIColor.darkGray
        }
        activityIndicator?.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator?.startAnimating()
        loadingView?.addSubview(activityIndicator!)
        
        // Message label
        messageLabel = UILabel()
        messageLabel?.text = processingMessage
        messageLabel?.textAlignment = .center
        messageLabel?.font = UIFont.systemFont(ofSize: 16)
        if #available(iOS 13.0, *) {
            messageLabel?.textColor = UIColor.label
        } else {
            messageLabel?.textColor = UIColor.darkGray
        }
        messageLabel?.translatesAutoresizingMaskIntoConstraints = false
        loadingView?.addSubview(messageLabel!)
        
        // Layout constraints
        NSLayoutConstraint.activate([
            loadingView!.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView!.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loadingView!.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            
            activityIndicator!.centerXAnchor.constraint(equalTo: loadingView!.centerXAnchor),
            activityIndicator!.topAnchor.constraint(equalTo: loadingView!.topAnchor, constant: 20),
            
            messageLabel!.centerXAnchor.constraint(equalTo: loadingView!.centerXAnchor),
            messageLabel!.topAnchor.constraint(equalTo: activityIndicator!.bottomAnchor, constant: 16),
            messageLabel!.leadingAnchor.constraint(equalTo: loadingView!.leadingAnchor, constant: 16),
            messageLabel!.trailingAnchor.constraint(equalTo: loadingView!.trailingAnchor, constant: -16),
            messageLabel!.bottomAnchor.constraint(equalTo: loadingView!.bottomAnchor, constant: -20)
        ])
    }
    
    private func processAttachments() {
        guard let extensionContext = extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem],
              let firstItem = inputItems.first,
              let attachments = firstItem.attachments else {
            if shouldAutoRedirect() {
                saveAndRedirect()
            } else {
                completeRequest()
            }
            return
        }
        
        let attachmentCount = attachments.count
        var processedCount = 0
        
        for (index, attachment) in attachments.enumerated() {
            if let nsItemProvider = attachment as? NSItemProvider {
                var processed = false
                
                for type in SharedMediaType.allCases {
                    if nsItemProvider.hasItemConformingToTypeIdentifier(type.toUTTypeIdentifier) {
                        nsItemProvider.loadItem(forTypeIdentifier: type.toUTTypeIdentifier, options: nil) { [weak self] (data, error) in
                            DispatchQueue.main.async {
                                guard let self = self else { return }
                                
                                if let error = error {
                                    self.handleError(error)
                                    return
                                }
                                
                                switch type {
                                case .text:
                                    if let text = data as? String {
                                        self.handleMedia(forLiteral: text, type: type)
                                    }
                                case .url:
                                    if let url = data as? URL {
                                        self.handleMedia(forLiteral: url.absoluteString, type: type)
                                    }
                                default:
                                    if let url = data as? URL {
                                        self.handleMedia(forFile: url, type: type)
                                    } else if let image = data as? UIImage {
                                        self.handleMedia(forUIImage: image, type: type)
                                    }
                                }
                                
                                processedCount += 1
                                if processedCount == attachmentCount {
                                    self.onProcessingComplete()
                                }
                            }
                        }
                        processed = true
                        break
                    }
                }
                
                if !processed {
                    processedCount += 1
                    if processedCount == attachmentCount {
                        onProcessingComplete()
                    }
                }
            } else {
                processedCount += 1
                if processedCount == attachmentCount {
                    onProcessingComplete()
                }
            }
        }
    }
    
    private func onProcessingComplete() {
        if shouldAutoRedirect() {
            saveAndRedirect()
        } else {
            // Override this method in subclasses for custom behavior
            onAttachmentsProcessed()
        }
    }
    
    /// Override this method to add custom behavior after attachments are processed
    /// This is called when shouldAutoRedirect() returns false
    open func onAttachmentsProcessed() {
        completeRequest()
    }
    
    private func handleError(_ error: Error) {
        print("[ERROR] Error loading attachment: \(error)")
        if shouldAutoRedirect() {
            saveAndRedirect()
        } else {
            completeRequest()
        }
    }
    
    private func completeRequest() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    // MARK: - Shared Methods (used by both base classes)
    
    func loadIds() {
        // loading Share extension App Id
        let shareExtensionAppBundleIdentifier = Bundle.main.bundleIdentifier!

        // extract host app bundle id from ShareExtension id
        // by default it's <hostAppBundleIdentifier>.<ShareExtension>
        // for example: "com.walter.sharing.Share-Extension" -> com.walter.sharing
        let lastIndexOfPoint = shareExtensionAppBundleIdentifier.lastIndex(of: ".")
        hostAppBundleIdentifier = String(shareExtensionAppBundleIdentifier[..<lastIndexOfPoint!])
        let defaultAppGroupId = "group.\(hostAppBundleIdentifier)"

        // loading custom AppGroupId from Build Settings or use group.<hostAppBundleIdentifier>
        let customAppGroupId = Bundle.main.object(forInfoDictionaryKey: kAppGroupIdKey) as? String

        appGroupId = customAppGroupId ?? defaultAppGroupId
    }

    func handleMedia(forLiteral item: String, type: SharedMediaType) {
        sharedMedia.append(
            SharedMediaFile(
                path: item,
                mimeType: type == .text ? "text/plain" : nil,
                type: type
            ))
    }

    func handleMedia(forUIImage image: UIImage, type: SharedMediaType) {
        let tempPath = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupId)!.appendingPathComponent(
                "TempImage.png")
        if self.writeTempFile(image, to: tempPath) {
            let newPathDecoded = tempPath.absoluteString.removingPercentEncoding!
            sharedMedia.append(
                SharedMediaFile(
                    path: newPathDecoded,
                    mimeType: type == .image ? "image/png" : nil,
                    type: type
                ))
        }
    }

    func handleMedia(forFile url: URL, type: SharedMediaType) {
        let fileName = getFileName(from: url, type: type)
        let newPath = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupId)!.appendingPathComponent(fileName)

        if copyFile(at: url, to: newPath) {
            // The path should be decoded because Flutter is not expecting url encoded file names
            let newPathDecoded = newPath.absoluteString.removingPercentEncoding!
            if type == .video {
                // Get video thumbnail and duration
                if let videoInfo = getVideoInfo(from: url) {
                    let thumbnailPathDecoded = videoInfo.thumbnail?.removingPercentEncoding
                    sharedMedia.append(
                        SharedMediaFile(
                            path: newPathDecoded,
                            mimeType: url.mimeType(),
                            thumbnail: thumbnailPathDecoded,
                            duration: videoInfo.duration,
                            type: type
                        ))
                }
            } else {
                sharedMedia.append(
                    SharedMediaFile(
                        path: newPathDecoded,
                        mimeType: url.mimeType(),
                        type: type
                    ))
            }
        }
    }

    // Save shared media and redirect to host app
    func saveAndRedirect(message: String? = nil) {
        let userDefaults = UserDefaults(suiteName: appGroupId)
        userDefaults?.set(toData(data: sharedMedia), forKey: kUserDefaultsKey)
        userDefaults?.set(message, forKey: kUserDefaultsMessageKey)
        userDefaults?.synchronize()
        redirectToHostApp()
    }

    private func redirectToHostApp() {
        // ids may not loaded yet so we need loadIds here too
        loadIds()
        let url = URL(string: "\(kSchemePrefix)-\(hostAppBundleIdentifier):share")
        var responder = self as UIResponder?

        if #available(iOS 18.0, *) {
            while responder != nil {
                if let application = responder as? UIApplication {
                    application.open(url!, options: [:], completionHandler: nil)
                }
                responder = responder?.next
            }
        } else {
            let selectorOpenURL = sel_registerName("openURL:")

            while responder != nil {
                if (responder?.responds(to: selectorOpenURL))! {
                    _ = responder?.perform(selectorOpenURL, with: url)
                }
                responder = responder!.next
            }
        }

        extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    private func getFileName(from url: URL, type: SharedMediaType) -> String {
        var name = url.lastPathComponent
        if name.isEmpty {
            switch type {
            case .image:
                name = UUID().uuidString + ".png"
            case .video:
                name = UUID().uuidString + ".mp4"
            case .text:
                name = UUID().uuidString + ".txt"
            default:
                name = UUID().uuidString
            }
        }
        return name
    }

    private func writeTempFile(_ image: UIImage, to dstURL: URL) -> Bool {
        do {
            if FileManager.default.fileExists(atPath: dstURL.path) {
                try FileManager.default.removeItem(at: dstURL)
            }
            if let pngData = image.pngData() {
                try pngData.write(to: dstURL)
                return true
            }
            return false
        } catch (let error) {
            print("Cannot write to temp file: \(error)")
            return false
        }
    }

    private func copyFile(at srcURL: URL, to dstURL: URL) -> Bool {
        do {
            if FileManager.default.fileExists(atPath: dstURL.path) {
                try FileManager.default.removeItem(at: dstURL)
            }
            try FileManager.default.copyItem(at: srcURL, to: dstURL)
        } catch (let error) {
            print("Cannot copy item at \(srcURL) to \(dstURL): \(error)")
            return false
        }
        return true
    }

    private func getVideoInfo(from url: URL) -> (thumbnail: String?, duration: Double)? {
        let asset = AVAsset(url: url)
        let duration = (CMTimeGetSeconds(asset.duration) * 1000).rounded()
        let thumbnailPath = getThumbnailPath(for: url)

        if FileManager.default.fileExists(atPath: thumbnailPath.path) {
            return (thumbnail: thumbnailPath.absoluteString, duration: duration)
        }

        var saved = false
        let assetImgGenerate = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        //        let scale = UIScreen.main.scale
        assetImgGenerate.maximumSize = CGSize(width: 360, height: 360)
        do {
            let time = CMTimeMake(value: 600, timescale: 1)
            let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
            if let pngData = UIImage(cgImage: img).pngData() {
                try pngData.write(to: thumbnailPath)
            }
            saved = true
        } catch {
            saved = false
        }

        return saved ? (thumbnail: thumbnailPath.absoluteString, duration: duration) : nil
    }

    private func getThumbnailPath(for url: URL) -> URL {
        let fileName = Data(url.lastPathComponent.utf8).base64EncodedString().replacingOccurrences(
            of: "==", with: "")
        let path = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)!
            .appendingPathComponent("\(fileName).jpg")
        return path
    }

    private func toData(data: [SharedMediaFile]) -> Data {
        let encodedData = try? JSONEncoder().encode(data)
        return encodedData!
    }
}

// MARK: - Legacy Share View Controller (SLComposeServiceViewController-based)

@available(swift, introduced: 5.0)
open class RSIShareViewController: SLComposeServiceViewController {
    // Delegate to the base class for shared functionality
    private lazy var baseController: RSIBaseShareViewController = {
        let controller = RSIBaseShareViewController()
        controller.autoRedirect = false // Let SLComposeServiceViewController handle the flow
        return controller
    }()
    
    var hostAppBundleIdentifier: String {
        get { return baseController.hostAppBundleIdentifier }
        set { baseController.hostAppBundleIdentifier = newValue }
    }
    
    var appGroupId: String {
        get { return baseController.appGroupId }
        set { baseController.appGroupId = newValue }
    }
    
    var sharedMedia: [SharedMediaFile] {
        get { return baseController.sharedMedia }
        set { baseController.sharedMedia = newValue }
    }

    /// Override this method to return false if you don't want to redirect to host app automatically
    /// Default is true
    open func shouldAutoRedirect() -> Bool {
        return true
    }

    open override func isContentValid() -> Bool {
        return true
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        // The base controller will access extensionContext directly
        
        // load group and app id from build info - delegate to base controller
        baseController.loadIds()
    }

    // Redirect to host app when user click on Post
    open override func didSelectPost() {
        baseController.saveAndRedirect(message: contentText)
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Process attachments like original implementation
        if let content = extensionContext!.inputItems[0] as? NSExtensionItem {
            if let contents = content.attachments {
                for (index, attachment) in contents.enumerated() {
                    if let nsItemProvider = attachment as? NSItemProvider {
                        for type in SharedMediaType.allCases {
                            if nsItemProvider.hasItemConformingToTypeIdentifier(
                                type.toUTTypeIdentifier)
                            {
                                nsItemProvider.loadItem(
                                    forTypeIdentifier: type.toUTTypeIdentifier, options: nil
                                ) { [weak self] (data, error: Error?) in
                                    guard let self = self else { return }

                                    if let error = error {
                                        DispatchQueue.main.async {
                                            self.dismissWithError()
                                        }
                                        return
                                    }

                                    DispatchQueue.main.async {
                                        switch type {
                                        case .text:
                                            if let text = data as? String {
                                                self.baseController.handleMedia(forLiteral: text, type: type)
                                            }
                                        case .url:
                                            if let url = data as? URL {
                                                self.baseController.handleMedia(forLiteral: url.absoluteString, type: type)
                                            }
                                        default:
                                            if let url = data as? URL {
                                                self.baseController.handleMedia(forFile: url, type: type)
                                            } else if let image = data as? UIImage {
                                                self.baseController.handleMedia(forUIImage: image, type: type)
                                            }
                                        }
                                        
                                        if index == (content.attachments?.count ?? 0) - 1 {
                                            if self.shouldAutoRedirect() {
                                                self.baseController.saveAndRedirect()
                                            }
                                        }
                                    }
                                }
                                break
                            }
                        }
                    }
                }
            }
        }
    }

    open override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }

    private func dismissWithError() {
        print("[ERROR] Error loading data!")
        let alert = UIAlertController(
            title: "Error", message: "Error loading data", preferredStyle: .alert)

        let action = UIAlertAction(title: "Error", style: .cancel) { _ in
            self.dismiss(animated: true, completion: nil)
        }

        alert.addAction(action)
        present(alert, animated: true, completion: nil)
        extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }
}

// MARK: - Extensions

extension URL {
    public func mimeType() -> String {
        if #available(iOS 14.0, *) {
            if let mimeType = UTType(filenameExtension: self.pathExtension)?.preferredMIMEType {
                return mimeType
            }
        } else {
            if let uti = UTTypeCreatePreferredIdentifierForTag(
                kUTTagClassFilenameExtension, self.pathExtension as NSString, nil)?
                .takeRetainedValue()
            {
                if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?
                    .takeRetainedValue()
                {
                    return mimetype as String
                }
            }
        }

        return "application/octet-stream"
    }
}
