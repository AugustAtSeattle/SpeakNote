//
//  ViewController.swift
//  SpeakNote
//
//  Created by Sailor on 11/27/23.
//

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
    var micButtonBottomConstraint: NSLayoutConstraint!
    let viewModel = SpeechViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = AppColors.secondaryGreen

        setupMessagesCollectionView()
        setupLiveCaptionView()
        setupMicButton()
        setupConstraints()
        setupBindings()
        configureAudioWaveLayer()
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
            
    @objc func microphoneButtonTapped() {
        print("Microphone button tapped!")
    }

    func setupLiveCaptionView() {
        liveCaptionView.isEditable = false
        liveCaptionView.isSelectable = false
        liveCaptionView.backgroundColor = AppColors.primaryGreen
        liveCaptionView.layer.borderColor = AppColors.borderColor
        liveCaptionView.layer.borderWidth = AppLayout.borderWidth
        liveCaptionView.layer.cornerRadius = 20
        liveCaptionView.font = UIFont.systemFont(ofSize: 30)
        liveCaptionView.textAlignment = .center
        liveCaptionView.translatesAutoresizingMaskIntoConstraints = false
        liveCaptionView.text = "Press the button and start speaking"
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
        micButtonBottomConstraint = micButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            messagesCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            messagesCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppLayout.leadingConstant),
            messagesCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: AppLayout.trailingConstant),
            messagesCollectionView.bottomAnchor.constraint(equalTo: liveCaptionView.topAnchor, constant: -40),
            
            liveCaptionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: AppLayout.leadingConstant),
            liveCaptionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: AppLayout.trailingConstant),
            liveCaptionView.bottomAnchor.constraint(equalTo: micButton.topAnchor, constant: -40),
            liveCaptionView.heightAnchor.constraint(equalToConstant: 60),
            
            micButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            micButton.heightAnchor.constraint(equalToConstant: buttonSize),
            micButton.widthAnchor.constraint(equalToConstant: buttonSize),
            micButtonBottomConstraint
        ])
    }
    
override func viewDidLayoutSubviews() {
    // this is a hack to fix the messageCollectionView's frame being set to the full screen
    messagesCollectionView.frame = CGRect(x: messagesCollectionView.frame.origin.x, y: messagesCollectionView.frame.origin.y + 100, width: messagesCollectionView.frame.size.width, height: messagesCollectionView.frame.size.height - 100)
}

    func setupBindings() {
        micButton.rx.tap
            .bind(onNext: viewModel.toggleListening)
            .disposed(by: disposeBag)
        
        viewModel.transcribedText.asObservable()
            .bind(to: liveCaptionView.rx.text)
            .disposed(by: disposeBag)
        
//        viewModel.recordsText.asObservable()
//            .bind(to: notesTextView.rx.text)
//            .disposed(by: disposeBag)
    
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
                }
            })
            .disposed(by: disposeBag)
    }

    func animateMicButton(isListening: Bool) {
        if isListening {
//            micButtonBottomConstraint.constant = -70 // 60 points up + 10 original margin
//            setTypingIndicatorViewHidden(false, animated: true)
            UIView.animate(withDuration: 0.3, animations: {
                self.micButton.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                self.view.layoutIfNeeded()
            }) { [weak self] _ in
                self?.startWaveAnimation()
            }
        } else {
//            micButtonBottomConstraint.constant = -10
//            setTypingIndicatorViewHidden(false, animated: false)
            UIView.animate(withDuration: 0.3, animations: {
                self.micButton.transform = .identity
                self.view.layoutIfNeeded()
            }) { [weak self] _ in
                self?.stopWaveAnimation()
            }
        }
    }
    
    var waveAnimationTimer: Timer?
        
    func configureAudioWaveLayer() {
        audioWaveLayer.frame = CGRect(x: 0, y: buttonSize / 2 - 20, width: buttonSize, height: 40)
        audioWaveLayer.isHidden = true // Initially hidden
        // Configure the wave layer appearance
        audioWaveLayer.strokeColor = UIColor.green.cgColor
        audioWaveLayer.fillColor = UIColor.gray.cgColor
        audioWaveLayer.lineWidth = 2
        audioWaveLayer.lineCap = .round
        micButton.layer.addSublayer(audioWaveLayer)
    }
    
    func startWaveAnimation() {
//        audioWaveLayer.isHidden = false
//        micButton.setImage(nil, for: .normal)
//        waveAnimationTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateWaveLayer), userInfo: nil, repeats: true)
    }
    
    func stopWaveAnimation() {
//        audioWaveLayer.isHidden = true
//        micButton.setImage(UIImage(named: "mic_icon"), for: .normal)
//        waveAnimationTimer?.invalidate()
//        waveAnimationTimer = nil
    }
    
    @objc func updateWaveLayer() {
        // Generate a random volume level between 0 and 100
        let volumeLevel = CGFloat(arc4random_uniform(101))
        // Calculate the normalized height for the wave
        let normalizedHeight = volumeLevel / 100 * 40 // Max height of 40 points
        // Update the audioWaveLayer path based on the volume level
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 20)) // Middle of the audioWaveLayer height
        path.addLine(to: CGPoint(x: buttonSize / 4, y: 20 - normalizedHeight / 2))
        path.addLine(to: CGPoint(x: buttonSize / 2, y: 20 + normalizedHeight / 2))
        path.addLine(to: CGPoint(x: buttonSize * 3 / 4, y: 20 - normalizedHeight / 2))
        path.addLine(to: CGPoint(x: buttonSize, y: 20)) // Back to middle
        
        audioWaveLayer.path = path.cgPath
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
            avatarView.set(avatar: Avatar(image: UIImage(named: "currentUserProfileImage"), initials: "U"))
        } else if message.sender.senderId == assignedSender.senderId {
            avatarView.set(avatar: Avatar(image: UIImage(named: "assistantProfileImage"), initials: "B"))
        }
    }
    
    func avatarSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return CGSize(width: 30, height: 30) // You can adjust this value to suit your needs.
    }
}

