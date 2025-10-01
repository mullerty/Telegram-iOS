import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramPresentationData
import AccountContext
import ContextUI
import TelegramCore
import TextFormat
import ReactionSelectionNode
import ViewControllerComponent
import ComponentFlow
import ComponentDisplayAdapters
import ChatMessageBackground
import WallpaperBackgroundNode
import AppBundle
import ActivityIndicator
import RadialStatusNode
import GlassBackgroundComponent

final class SendButton: HighlightTrackingButton {
    enum Kind {
        case send
        case edit
    }
    
    private let kind: Kind
    
    private let containerView: UIView
    private let backgroundView: UIImageView
    private let iconView: UIImageView
    private var activityIndicator: RadialStatusNode?
    
    private var previousIsAnimatedIn: Bool?
    private var sourceCustomContentView: UIView?
    
    init(kind: Kind) {
        self.kind = kind
        
        self.containerView = UIView()
        self.containerView.isUserInteractionEnabled = false
        
        self.backgroundView = UIImageView()
        self.backgroundView.image = generateStretchableFilledCircleImage(diameter: 34.0, color: .white)?.withRenderingMode(.alwaysTemplate)
        
        self.iconView = UIImageView()
        self.iconView.isUserInteractionEnabled = false
        
        super.init(frame: CGRect())
        
        self.containerView.clipsToBounds = true
        self.addSubview(self.containerView)
        
        self.containerView.addSubview(self.backgroundView)
        self.containerView.addSubview(self.iconView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(
        context: AccountContext,
        presentationData: PresentationData,
        backgroundNode: WallpaperBackgroundNode?,
        sourceSendButton: ASDisplayNode,
        isAnimatedIn: Bool,
        isLoadingEffectAnimation: Bool,
        size: CGSize,
        transition: ComponentTransition
    ) {
        let innerSize = CGSize(width: size.width - 3.0 * 2.0, height: size.height - 3.0 * 2.0)
        let containerFrame = CGRect(origin: CGPoint(x: floorToScreenPixels((size.width - innerSize.width) * 0.5), y: floorToScreenPixels((size.height - innerSize.height) * 0.5)), size: innerSize)
        transition.setFrame(view: self.containerView, frame: containerFrame)
        transition.setCornerRadius(layer: self.containerView.layer, cornerRadius: innerSize.height * 0.5)
        
        self.backgroundView.tintColor = presentationData.theme.chat.inputPanel.actionControlFillColor
        transition.setFrame(view: self.backgroundView, frame: CGRect(origin: CGPoint(), size: innerSize))
        
        if self.previousIsAnimatedIn != isAnimatedIn {
            self.previousIsAnimatedIn = isAnimatedIn
            
            var sourceCustomContentViewAlpha: CGFloat = 1.0
            if let sourceCustomContentView = self.sourceCustomContentView {
                sourceCustomContentViewAlpha = sourceCustomContentView.alpha
                sourceCustomContentView.removeFromSuperview()
                self.sourceCustomContentView = nil
            }
            
            if let sourceSendButton = sourceSendButton as? ChatSendMessageActionSheetControllerSourceSendButtonNode {
                if let sourceCustomContentView = sourceSendButton.makeCustomContents() {
                    self.sourceCustomContentView = sourceCustomContentView
                    sourceCustomContentView.alpha = sourceCustomContentViewAlpha
                    self.addSubview(sourceCustomContentView)
                }
            }
        }
        
        if self.iconView.image == nil {
            switch self.kind {
            case .send:
                self.iconView.image = PresentationResourcesChat.chatInputPanelSendIconImage(presentationData.theme)
            case .edit:
                self.iconView.image = PresentationResourcesChat.chatInputPanelApplyIconImage(presentationData.theme)
            }
        }
        
        if let sourceCustomContentView = self.sourceCustomContentView {
            var sourceCustomContentTransition = transition
            if sourceCustomContentView.bounds.isEmpty {
                sourceCustomContentTransition = .immediate
            }
            
            let sourceCustomContentSize = sourceCustomContentView.bounds.size
            let sourceCustomContentFrame = CGRect(origin: CGPoint(x: floorToScreenPixels((innerSize.width - sourceCustomContentSize.width) * 0.5) + UIScreenPixel, y: floorToScreenPixels((innerSize.height - sourceCustomContentSize.height) * 0.5)), size: sourceCustomContentSize).offsetBy(dx: containerFrame.minX, dy: containerFrame.minY)
            sourceCustomContentTransition.setPosition(view: sourceCustomContentView, position: sourceCustomContentFrame.center)
            sourceCustomContentTransition.setBounds(view: sourceCustomContentView, bounds: CGRect(origin: CGPoint(), size: sourceCustomContentFrame.size))
            sourceCustomContentTransition.setAlpha(view: sourceCustomContentView, alpha: isAnimatedIn ? 0.0 : 1.0)
        }
        
        if let icon = self.iconView.image {
            let iconFrame = CGRect(origin: CGPoint(x: floorToScreenPixels((innerSize.width - icon.size.width) * 0.5), y: floorToScreenPixels((innerSize.height - icon.size.height) * 0.5)), size: icon.size)
            transition.setPosition(view: self.iconView, position: iconFrame.center)
            transition.setBounds(view: self.iconView, bounds: CGRect(origin: CGPoint(), size: iconFrame.size))
            
            let iconViewAlpha: CGFloat
            if (self.sourceCustomContentView != nil && !isAnimatedIn) || isLoadingEffectAnimation {
                iconViewAlpha = 0.0
            } else {
                iconViewAlpha = 1.0
            }
            transition.setAlpha(view: self.iconView, alpha: iconViewAlpha)
            transition.setScale(view: self.iconView, scale: isLoadingEffectAnimation ? 0.001 : 1.0)
        }
        
        if isLoadingEffectAnimation {
            var animateIn = false
            let activityIndicator: RadialStatusNode
            if let current = self.activityIndicator {
                activityIndicator = current
            } else {
                animateIn = true
                activityIndicator = RadialStatusNode(
                    backgroundNodeColor: .clear,
                    enableBlur: false,
                    isPreview: false
                )
                activityIndicator.transitionToState(.progress(
                    color: presentationData.theme.list.itemCheckColors.foregroundColor,
                    lineWidth: 2.0,
                    value: nil,
                    cancelEnabled: false,
                    animateRotation: true
                ))
                self.activityIndicator = activityIndicator
                self.containerView.addSubview(activityIndicator.view)
            }
            
            let activityIndicatorSize = CGSize(width: 18.0, height: 18.0)
            let activityIndicatorFrame = CGRect(origin: CGPoint(x: floorToScreenPixels((innerSize.width - activityIndicatorSize.width) * 0.5), y: floor((innerSize.height - activityIndicatorSize.height) * 0.5) + UIScreenPixel), size: activityIndicatorSize)
            if animateIn {
                activityIndicator.view.frame = activityIndicatorFrame
                transition.animateAlpha(view: activityIndicator.view, from: 0.0, to: 1.0)
                transition.animateScale(view: activityIndicator.view, from: 0.001, to: 1.0)
            } else {
                transition.setFrame(view: activityIndicator.view, frame: activityIndicatorFrame)
            }
        } else {
            if let activityIndicator = self.activityIndicator {
                self.activityIndicator = nil
                transition.setAlpha(view: activityIndicator.view, alpha: 0.0, completion: { [weak activityIndicator] _ in
                    activityIndicator?.view.removeFromSuperview()
                })
                transition.setScale(view: activityIndicator.view, scale: 0.001)
            }
        }
    }
    
    func updateGlobalRect(rect: CGRect, within containerSize: CGSize, transition: ComponentTransition) {
    }
}
