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

    var textView = UITextView()
    let audioWaveLayer = CAShapeLayer()
    let buttonSize: CGFloat = 120
    let micButton = UIButton()
    var micButtonBottomConstraint: NSLayoutConstraint!
    let viewModel = SpeechViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTextView()
        setupMicButton()
        setupConstraints()
        setupBindings()
        configureAudioWaveLayer()
    }

    func setupTextView() {
        textView.isEditable = false
        textView.isSelectable = false
        textView.backgroundColor = .blue
        textView.font = UIFont.systemFont(ofSize: 20)
        textView.textAlignment = .center
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.text = "Press the button and start speaking"
        view.addSubview(textView)
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
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            textView.bottomAnchor.constraint(equalTo: micButton.topAnchor, constant: -10),
            
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
            .bind(to: textView.rx.text)
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
