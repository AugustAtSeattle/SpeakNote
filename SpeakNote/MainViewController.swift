//
//  ViewController.swift
//  SpeakNote
//
//  Created by Sailor on 11/27/23.
//

// buy icecream from costco
// buy paper towel from costco
// have a tax report done in Walmart
// flu shot in CVS
// buy a new ipad from costco
// I am in costco, what to do?
// I am in Walmart, what to do? 

import UIKit
import Speech
import RxSwift
import RxCocoa
import MessageKit

class MainViewController: MessagesViewController {
    let disposeBag = DisposeBag()
    
    var liveCaptionView = UITextView()
    let audioWaveLayer = CAShapeLayer()
    let buttonSize: CGFloat = 120
    let micButton = UIButton()
    let viewModel = SpeechViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = AppColors.secondaryGreen
        
        setupMessagesCollectionView()
        setupLiveCaptionView()
        setupMicButton()
        setupConstraints()
        setupBindings()
    }
    
    func setupMessagesCollectionView() {
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.backgroundColor = AppColors.primaryGreen
        
        messageInputBar.isHidden = true
        messagesCollectionView.layer.borderColor = AppColors.borderColor
        messagesCollectionView.layer.borderWidth = AppLayout.borderWidth
        
        messagesCollectionView.translatesAutoresizingMaskIntoConstraints = false
        messagesCollectionView.layer.masksToBounds = true
        messagesCollectionView.layer.cornerRadius = 30
        messagesCollectionView.contentInset = UIEdgeInsets(top: 30, left: 0, bottom: 0, right: 0)
    }
        
    func setupLiveCaptionView() {
        liveCaptionView.isEditable = false
        liveCaptionView.isSelectable = false
        liveCaptionView.backgroundColor = AppColors.primaryGreen
        liveCaptionView.layer.borderColor = AppColors.borderColor
        liveCaptionView.layer.borderWidth = AppLayout.borderWidth
        liveCaptionView.layer.cornerRadius = 20
        liveCaptionView.font = UIFont.systemFont(ofSize: 25)
        liveCaptionView.textColor = .white
        liveCaptionView.textAlignment = .center
        liveCaptionView.textContainer.maximumNumberOfLines = 2
        liveCaptionView.textContainer.lineBreakMode = .byTruncatingTail
        liveCaptionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(liveCaptionView)
    }
    
    func setupMicButton() {
        micButton.setImage(UIImage(named: "mic_icon"), for: .normal)
        micButton.translatesAutoresizingMaskIntoConstraints = false
        micButton.layer.borderColor = AppColors.borderColor
        micButton.layer.borderWidth = AppLayout.borderWidth
        micButton.layer.cornerRadius = buttonSize / 2
        micButton.clipsToBounds = true
        view.addSubview(micButton)
    }
    
    
    func setupConstraints() {
        // Deactivate all existing constraints on the view
        NSLayoutConstraint.deactivate(view.constraints)
                
        // Activate custom constraints
        NSLayoutConstraint.activate([
            liveCaptionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppLayout.leadingConstant),
            liveCaptionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: AppLayout.trailingConstant),
            liveCaptionView.bottomAnchor.constraint(equalTo: micButton.topAnchor, constant: -40),
            liveCaptionView.heightAnchor.constraint(equalToConstant: 80),
            
            micButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            micButton.heightAnchor.constraint(equalToConstant: buttonSize),
            micButton.widthAnchor.constraint(equalToConstant: buttonSize),
            micButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),
        ])
    }
    
    override func viewDidLayoutSubviews() {
        let x = AppLayout.leadingConstant
        let y = view.safeAreaLayoutGuide.layoutFrame.minY + 60
        let width = UIScreen.main.bounds.width - 60
        let height = UIScreen.main.bounds.height - 380
        messagesCollectionView.frame = CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(width), height: CGFloat(height))
    }
    
    func setupBindings() {
        micButton.rx.tap
            .bind(onNext: viewModel.toggleListening)
            .disposed(by: disposeBag)
        
        viewModel.transcribedText.asObservable()
            .bind(to: liveCaptionView.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.isListeningRelay
            .asObservable()
            .subscribe(onNext: { [weak self] isListening in
                self?.animateMicButton(isListening: isListening)
            })
            .disposed(by: disposeBag)
        
        viewModel.messages.asObservable()
            .subscribe(onNext: { [weak self] _ in
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadData()
                    self?.messagesCollectionView.scrollToLastItem()
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.isLoadingFromServerRelay
            .asObservable()
            .subscribe(onNext: { [weak self] isLoadingFromServer in
                DispatchQueue.main.async {
                    if isLoadingFromServer {
                        self?.setTypingIndicatorViewHidden(false, animated: true)
                    } else {
                        self?.setTypingIndicatorViewHidden(true, animated: true)
                    }
                }
            })
            .disposed(by: disposeBag)
    }
    
    func animateMicButton(isListening: Bool) {
        if isListening {
            UIView.animate(withDuration: 0.3, animations: {
                self.micButton.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                self.view.layoutIfNeeded()
            }) { [weak self] _ in
            }
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.micButton.transform = .identity
                self.view.layoutIfNeeded()
            }) { [weak self] _ in
            }
        }
    }
    
}


// MARK: - MessagesDataSource
extension MainViewController: MessagesDataSource {
    var currentSender: MessageKit.SenderType {
        return viewModel.currentSender
    }
    
    var assignedSender: MessageKit.SenderType {
        return viewModel.assistantSender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return viewModel.messages.value[indexPath.section]  // Access the value of BehaviorRelay
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return viewModel.messages.value.count  // Access the value of BehaviorRelay
    }
    
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
    }
}

// MARK: - MessagesLayoutDelegate and MessagesDisplayDelegate
extension MainViewController: MessagesLayoutDelegate, MessagesDisplayDelegate {
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        // Here, you can set image for avatarView based on the sender. You can fetch image for sender from your User model.
        // For instance, if you have a User model with a profileImageURL property:
        if message.sender.senderId == currentSender.senderId {
            avatarView.set(avatar: Avatar(image: UIImage(named: "user_profile"), initials: "U"))
        } else if message.sender.senderId == assignedSender.senderId {
            avatarView.set(avatar: Avatar(image: UIImage(named: "assistant_profile"), initials: "B"))
        }
    }
    
    func avatarSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return CGSize(width: 50, height: 50)
    }
}

