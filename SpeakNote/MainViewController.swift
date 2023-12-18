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

    // Sample data
    var messages: [MessageType] = []
    let currentSender: SenderType = Sender(senderId: "user1", displayName: "User")
    let assistant: SenderType = Sender(senderId: "assistant", displayName: "Assistant")
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadMessages()
        setupMessagesCollectionView()
        setupLiveCaptionView()
        setupMicButton()
        setupConstraints()
        setupBindings()
        configureAudioWaveLayer()
        
//        setupImageView()
        setTypingIndicatorViewHidden(false, animated: true)
    }
    
    func setupMessagesCollectionView() {
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.backgroundColor = UIColor(hex: "b3d4a1")
        self.view.backgroundColor = UIColor(hex: "1d4a04")

        messageInputBar.isHidden = true
        messagesCollectionView.layer.borderColor = UIColor.black.cgColor
        messagesCollectionView.layer.borderWidth = 2.0
        
        messagesCollectionView.translatesAutoresizingMaskIntoConstraints = false
        messagesCollectionView.layer.masksToBounds = true
        messagesCollectionView.layer.cornerRadius = 30
        messagesCollectionView.contentInset = UIEdgeInsets(top: 30, left: 0, bottom: 0, right: 0)
    }
        
    func setupImageView() {
        let microphoneButton = UIButton()
        microphoneButton.translatesAutoresizingMaskIntoConstraints = false

        self.view.addSubview(microphoneButton) // Add this line before setting constraints

        NSLayoutConstraint.activate([
            microphoneButton.widthAnchor.constraint(equalToConstant: 100),
            microphoneButton.heightAnchor.constraint(equalToConstant: 100),
            microphoneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            microphoneButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50)
        ])

        microphoneButton.setImage(UIImage(named: "microphone"), for: .normal)
        microphoneButton.setImage(UIImage(named: "microphone_selected"), for: .selected)
        microphoneButton.addTarget(self, action: #selector(microphoneButtonTapped), for: .touchUpInside)
    }
    
    @objc func microphoneButtonTapped() {
        print("Microphone button tapped!")
    }

    func setupLiveCaptionView() {
        liveCaptionView.isEditable = false
        liveCaptionView.isSelectable = false
        liveCaptionView.backgroundColor = .lightGray
        liveCaptionView.layer.cornerRadius = 20
        liveCaptionView.font = UIFont.systemFont(ofSize: 20)
        liveCaptionView.textAlignment = .center
        liveCaptionView.translatesAutoresizingMaskIntoConstraints = false
        liveCaptionView.text = "Press the button and start speaking"
        view.addSubview(liveCaptionView)
    }

    func setupMicButton() {
        micButton.setImage(UIImage(named: "mic_icon"), for: .normal)
        micButton.translatesAutoresizingMaskIntoConstraints = false
        micButton.layer.cornerRadius = buttonSize / 2
        micButton.clipsToBounds = true
        view.addSubview(micButton)
    }

    func setupConstraints() {
        micButtonBottomConstraint = micButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        
        NSLayoutConstraint.activate([
            messagesCollectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
            messagesCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            messagesCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            messagesCollectionView.bottomAnchor.constraint(equalTo: liveCaptionView.topAnchor, constant: -10),
            
            liveCaptionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            liveCaptionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            liveCaptionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            liveCaptionView.bottomAnchor.constraint(equalTo: micButton.topAnchor, constant: -10),
            liveCaptionView.heightAnchor.constraint(equalToConstant: 60),
            
            micButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            micButton.heightAnchor.constraint(equalToConstant: buttonSize),
            micButton.widthAnchor.constraint(equalToConstant: buttonSize),
            micButtonBottomConstraint
        ])
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
    }

    func animateMicButton(isListening: Bool) {
        if isListening {
            micButtonBottomConstraint.constant = -70 // 60 points up + 10 original margin
            UIView.animate(withDuration: 0.3, animations: {
                self.micButton.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                self.view.layoutIfNeeded()
            }) { [weak self] _ in
                self?.startWaveAnimation()
            }
        } else {
            micButtonBottomConstraint.constant = -10
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
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    // Load some sample messages
    func loadMessages() {
        let message1: MessageType = Message(sender: Sender(senderId: "user1", displayName: "User"), messageId: UUID().uuidString, sentDate: Date(), kind: .text("buy two eggs from Costco"))
        let message2: MessageType = Message(sender: Sender(senderId: "assistant", displayName: "Assistant"), messageId: UUID().uuidString, sentDate: Date(), kind: .text("noted, you will buy two eggs from Costco"))
        let message3: MessageType = Message(sender: Sender(senderId: "user1", displayName: "User"), messageId: UUID().uuidString, sentDate: Date(), kind: .text("have a meetting tomorrow 10"))
        let message4: MessageType = Message(sender: Sender(senderId: "assistant", displayName: "Assistant"), messageId: UUID().uuidString, sentDate: Date(), kind: .text("noted, you will have a meeting tomorrow at 10 am"))
        
        messages = [message1, message2, message3, message4]
        self.messagesCollectionView.reloadData()
    }
}


// MARK: - MessagesLayoutDelegate and MessagesDisplayDelegate
extension MainViewController: MessagesLayoutDelegate, MessagesDisplayDelegate {
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        // Here, you can set image for avatarView based on the sender. You can fetch image for sender from your User model.
        // For instance, if you have a User model with a profileImageURL property:
        if message.sender.senderId == currentSender.senderId {
            avatarView.set(avatar: Avatar(image: UIImage(named: "currentUserProfileImage"), initials: "U"))
        } else if message.sender.senderId == assistant.senderId {
            avatarView.set(avatar: Avatar(image: UIImage(named: "assistantProfileImage"), initials: "B"))
        }
    }
    
    func avatarSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return CGSize(width: 30, height: 30) // You can adjust this value to suit your needs.
    }
}

// Extend MessageKit types for creating sample messages
extension MainViewController {
    struct Sender: SenderType {
        var senderId: String
        var displayName: String
    }
    
    struct Message: MessageType {
        var sender: SenderType
        var messageId: String
        var sentDate: Date
        var kind: MessageKind
    }
}


extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 0

        var rgbValue: UInt64 = 0

        scanner.scanHexInt64(&rgbValue)

        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff

        self.init(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff,
            alpha: 1
        )
    }
}
