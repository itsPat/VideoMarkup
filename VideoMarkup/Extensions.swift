//
//  Extensions.swift
//  VideoMarkup
//
//  Created by Pat Trudel on 2020-11-21.
//

import Foundation
import AVKit
import CoreImage
import UIKit
import PhotosUI
import MobileCoreServices

// MARK: - CMTime

extension CMTime {
    var roundedSeconds: TimeInterval {
        return seconds.rounded()
    }
    var hours:  Int { return Int(roundedSeconds / 3600) }
    var minute: Int { return Int(roundedSeconds.truncatingRemainder(dividingBy: 3600) / 60) }
    var second: Int { return Int(roundedSeconds.truncatingRemainder(dividingBy: 60)) }
    var positionalTime: String {
        return hours > 0 ?
            String(format: "%d:%02d:%02d",
                   hours, minute, second) :
            String(format: "%01d:%02d",
                   minute, second)
    }
}

// MARK: - String

extension String {
    
    static var uuid: String {
        return UUID().uuidString
    }
    
    static var id: String {
        return UUID().uuidString.components(separatedBy: "-").last ?? ""
    }
    
    func heightFor(width: CGFloat, using font: UIFont) -> CGFloat {
        return NSString(string: self).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [NSStringDrawingOptions.usesLineFragmentOrigin],
            attributes: [NSAttributedString.Key.font: font],
            context: nil
        ).height
    }
    
    
}

// MARK: - Double

extension Double {
    
    var currencyFormatted: String? {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .currencyAccounting
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: self as NSNumber)
    }
    
    var formattedAndTruncated: String {
        let intValue = Int(self)
        
        if self >= 10000, self <= 999999 {
            return String(format: "%.1fK",
                          locale: Locale.current,
                          intValue/1000).replacingOccurrences(of: ".0", with: "")
        }
        return String(format: "%.2f", self)
    }
    
    var formatted: String {
        return String(format: "%.2f", self)
    }
    
}


// MARK: - Date

extension Date {
    
    func ddmmyyyy() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        let string = dateFormatter.string(from: self)
        return string
    }
    
    func ddmm() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM"
        let string = dateFormatter.string(from: self)
        return string
    }
    
}


// MARK: - TimeInterval

extension TimeInterval {
    
    var date: Date {
        return Date(timeIntervalSince1970: self)
    }
    
}

// MARK: - URL

extension URL {
    
    public func queryValueForKey(_ key: String) -> String? {
        guard let url = URLComponents(string: absoluteString) else {
            return nil
        }
        return url.queryItems?.first { $0.name == key }?.value
    }
    
    public func getTempURLWithContents() -> URL? {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(.uuid).appendingPathExtension(pathExtension)
        do {
            let data = try Data(contentsOf: self)
            try data.write(to: path)
            return path
        } catch {
            print("\(#function) failed with error: \(error.localizedDescription)")
            return nil
        }
    }
    
}


// MARK: - UIView

extension UIView {
    
    public enum ViewStyle {
        case plain, outlined, card,  featured
    }
    
    func apply(style: ViewStyle,
               bgColor: UIColor? = nil,
               borderColor: UIColor? = nil,
               borderWidth: CGFloat? = nil,
               cornerRadius: CGFloat? = nil,
               shadowOffset: CGSize? = nil,
               shadowRadius: CGFloat? = nil,
               shadowOpacity: Float? = nil,
               masksToBounds: Bool? = nil,
               clipsToBounds: Bool? = nil) {
        switch style {
        case .plain: // Corner Radius
            backgroundColor = bgColor ?? backgroundColor
            layer.cornerRadius = cornerRadius ?? 4.0
            layer.borderWidth = 0.0
            layer.shadowOpacity = 0.0
        case .outlined: // Corner Radius + Border
            layer.cornerRadius = cornerRadius ?? 10.0
            layer.borderWidth = borderWidth ?? 0.5
            layer.borderColor = borderColor?.cgColor ?? UIColor.separator.cgColor
            layer.shadowOpacity = 0.0
        case .card: // Corner Radius + Short Shadow
            backgroundColor = bgColor ?? .white
            layer.cornerRadius = cornerRadius ?? 10.0
            layer.shadowOffset = shadowOffset ?? CGSize(width: 0, height: 1)
            layer.shadowRadius = shadowRadius ?? 2
            layer.shadowOpacity = shadowOpacity ?? 0.1
        case .featured: // Corner Radius + Border + Long Shadow
            layer.cornerRadius = cornerRadius ?? 10.0
            layer.borderWidth = borderWidth ?? 0.5
            layer.borderColor = borderColor?.cgColor ?? UIColor.separator.cgColor
            layer.shadowOffset = shadowOffset ?? CGSize(width: 2, height: 6)
            layer.shadowRadius = shadowRadius ?? 8
            layer.shadowOpacity = shadowOpacity ?? 0.1
        }
        self.clipsToBounds = masksToBounds ?? false
        layer.masksToBounds = masksToBounds ?? false
    }
    
    func animate(to style: ViewStyle) {
        UIView.animate(
            withDuration: 0.5,
            delay: 0.0,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 0.5,
            options: .curveLinear,
            animations: { [weak self] in
                self?.apply(style: style)
            }, completion: nil)
    }
    
    func pinToEdgesOfSuperview() {
        guard let superview = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.topAnchor),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor),
            leftAnchor.constraint(equalTo: superview.leftAnchor),
            rightAnchor.constraint(equalTo: superview.rightAnchor)
        ])
    }
    
    func roundTopCorners(radius: CGFloat) {
        let mask = CAShapeLayer()
        mask.path = UIBezierPath(
            roundedRect: bounds,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radius, height: radius)
        ).cgPath
        layer.mask = mask
    }
    
}

// MARK: - UIViewController

extension UIViewController {
    
    func presentAlert(sender: UIView? = nil, title: String? = "Oops", message: String?, preferredStyle: UIAlertController.Style = .alert, confirmStyle: UIAlertAction.Style = .default, confirmTitle: String? = nil, confirmHandler: ((UIAlertAction) -> Void)? = nil, cancelTitle: String? = nil, cancelHandler: ((UIAlertAction) -> Void)? = nil, showCancel: Bool = false) {
        DispatchQueue.main.async { [weak self] in
            let alertVC = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)
            let okAction = UIAlertAction(title: confirmTitle ?? "Ok", style: confirmStyle, handler: confirmHandler)
            alertVC.addAction(okAction)
            
            if let popoverVC = alertVC.popoverPresentationController,
                let sender = sender {
                popoverVC.sourceView = sender
                popoverVC.sourceRect = sender.frame
            }
            
            if showCancel {
                let cancelAction = UIAlertAction(title: cancelTitle ?? "Cancel", style: .cancel, handler: cancelHandler)
                alertVC.addAction(cancelAction)
            }
            self?.present(alertVC, animated: true, completion: nil)
        }
    }
    
    func presentImportOptions(sender: Any?) {
        DispatchQueue.main.async { [weak self] in
            let alertVC = UIAlertController(title: "Select an option", message: nil, preferredStyle: .actionSheet)
            
            alertVC.addAction(UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
                let picker = UIImagePickerController()
                picker.delegate = self as? (UIImagePickerControllerDelegate & UINavigationControllerDelegate)
                picker.sourceType = .photoLibrary
                picker.mediaTypes = [kUTTypeMovie as String, kUTTypeQuickTimeMovie as String, kUTTypeAVIMovie as String]
                self?.present(picker, animated: true, completion: nil)
            })
            
            alertVC.addAction(UIAlertAction(title: "Files", style: .default) { [weak self] (_) in
                guard let self = self else { return }
                let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.movie, .mpeg4Movie, .quickTimeMovie])
                documentPicker.delegate = self as? UIDocumentPickerDelegate
                
                if let popoverVC = documentPicker.popoverPresentationController {
                    if let barButton = sender as? UIBarButtonItem {
                        popoverVC.barButtonItem = barButton
                    } else if let view = sender as? UIView {
                        popoverVC.sourceView = view
                        popoverVC.sourceRect = view.frame
                    }
                }
                
                self.present(documentPicker, animated: true, completion: nil)
            })
            alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            if let popoverVC = alertVC.popoverPresentationController {
                if let barButton = sender as? UIBarButtonItem {
                    popoverVC.barButtonItem = barButton
                } else if let view = sender as? UIView {
                    popoverVC.sourceView = view
                    popoverVC.sourceRect = view.frame
                }
            }
            
            self?.present(alertVC, animated: true, completion: nil)
        }
    }
    
}

// MARK: - UIImageView

extension UIImageView {
    
    func setImageWithAnimation(image: UIImage?, mode: UIView.ContentMode = .scaleAspectFill) {
        guard let image = image else { return }
        DispatchQueue.main.async { [weak self] in
            self?.contentMode = mode
            guard let `self` = self else { return }
            UIView.transition(with: self,
                              duration: 0.25,
                              options: .transitionCrossDissolve,
                              animations: { self.image = image },
                              completion: nil)
        }
    }
    
}

extension UIImage {
    
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
    
}
