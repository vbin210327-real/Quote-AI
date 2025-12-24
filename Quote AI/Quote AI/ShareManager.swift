import SwiftUI
import LinkPresentation
import UIKit

class ShareManager {
    static let shared = ShareManager()
    
    private init() {}
    
    @MainActor
    func shareQuote(_ content: String, from viewController: UIViewController?) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        let receiptView = ThermalReceiptView(
            content: content,
            date: Date(),
            referenceID: String(UUID().uuidString.prefix(6)).uppercased()
        )

        let renderer = ImageRenderer(content: receiptView)
        renderer.scale = 3.0 // High quality

        if let uiImage = renderer.uiImage {
            // Return the image directly as the share item
            let shareItem = QuoteShareItem(image: uiImage)
            
            let activityViewController = UIActivityViewController(
                activityItems: [shareItem],
                applicationActivities: nil
            )

            if let vc = viewController {
                if let popoverController = activityViewController.popoverPresentationController {
                    popoverController.sourceView = vc.view
                    popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
                    popoverController.permittedArrowDirections = []
                }
                vc.present(activityViewController, animated: true)
            }
        }
    }
}

class QuoteShareItem: NSObject, UIActivityItemSource {
    let image: UIImage

    init(image: UIImage) {
        self.image = image
        super.init()
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return image
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        // Sharing the image itself (not a URL) is key to a clean header
        return image
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = "Quote AI"
        
        // By NOT providing an originalURL, we tell iOS there is no "source domain" or "filename" to display.
        // The imageProvider ensures the receipt thumbnail still shows up on the right.
        metadata.imageProvider = NSItemProvider(object: image)
        
        return metadata
    }
}
