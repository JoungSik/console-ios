import HotwireNative
import UIKit
import WebKit

final class AppWebViewController: HotwireWebViewController {
    private static let contentTopInset: CGFloat = 16

    override func visitableDidActivateWebView(_ webView: WKWebView) {
        super.visitableDidActivateWebView(webView)

        let scrollView = webView.scrollView
        var contentInset = scrollView.contentInset
        contentInset.top = Self.contentTopInset
        scrollView.contentInset = contentInset

        var scrollIndicatorInsets = scrollView.verticalScrollIndicatorInsets
        scrollIndicatorInsets.top = Self.contentTopInset
        scrollView.verticalScrollIndicatorInsets = scrollIndicatorInsets

        webView.isOpaque = false
        webView.backgroundColor = .clear
        scrollView.backgroundColor = AppTheme.background
    }
}
