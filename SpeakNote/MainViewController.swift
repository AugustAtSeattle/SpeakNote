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

class MainViewController: UIViewController {
    let disposeBag = DisposeBag()

    var notesTextView = UITextView()
    var liveCaptionView = UITextView()
    let audioWaveLayer = CAShapeLayer()
    let buttonSize: CGFloat = 120
    let micButton = UIButton()
    var micButtonBottomConstraint: NSLayoutConstraint!
    let viewModel = SpeechViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNotesTextView()
        setupLiveCaptionView()
        setupMicButton()
        setupConstraints()
        setupBindings()
        configureAudioWaveLayer()
    }

    func setupNotesTextView() {
        notesTextView.isEditable = false
        notesTextView.isSelectable = false
        notesTextView.backgroundColor = .lightGray
        notesTextView.layer.cornerRadius = 20
        notesTextView.font = UIFont.systemFont(ofSize: 16)
        notesTextView.textAlignment = .left
        notesTextView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(notesTextView)
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
            notesTextView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            notesTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            notesTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            notesTextView.bottomAnchor.constraint(equalTo: liveCaptionView.topAnchor, constant: -10),
            
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
        
        viewModel.recordsText.asObservable()
            .bind(to: notesTextView.rx.text)
            .disposed(by: disposeBag)
    
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
            }) { _ in
                self.startWaveAnimation()
            }
        } else {
            micButtonBottomConstraint.constant = -10
            UIView.animate(withDuration: 0.3, animations: {
                self.micButton.transform = .identity
                self.view.layoutIfNeeded()
            }) { _ in
                self.stopWaveAnimation()
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
