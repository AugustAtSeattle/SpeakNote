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
    var listenButton = UIButton()
    let viewModel = SpeechViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        let notes = DatabaseManager.shared.fetchNotes()
        print("begin notes",notes)
        _ = DatabaseManager.shared.createNote(title: "Test", body: "This is a test")
        print(notes)
        print("end notes",notes)
        // Setup textView and listenButton
        textView.isEditable = false
        textView.isSelectable = false
        textView.font = UIFont.systemFont(ofSize: 20)
        textView.textAlignment = .center
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.text = "Press the button and start speaking"
        
        // Add target to listenButton and swipe gesture recognizer
        listenButton.setTitle("Start Listening", for: .normal)
        listenButton.setTitleColor(.systemBlue, for: .normal)
        listenButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Add textView and listenButton as subviews
        view.addSubview(textView)
        view.addSubview(listenButton)
        
        // Setup constraints for textView and listenButton
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: listenButton.topAnchor),
            listenButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            listenButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            listenButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        // Setup bindings
        setupBindings()
    }

    func setupBindings() {
        listenButton.rx.tap
            .bind(onNext: viewModel.toggleListening)
            .disposed(by: disposeBag)
        
        viewModel.transcribedText.asObservable()
            .bind(to: textView.rx.text)
            .disposed(by: disposeBag)

        viewModel.isListeningRelay
            .asObservable()
            .subscribe(onNext: { [weak listenButton] isListening in
                let buttonTitle = isListening ? "Stop Listening" : "Start Listening"
                listenButton?.setTitle(buttonTitle, for: .normal)
            })
            .disposed(by: disposeBag)
        
//        viewModel.requestSpeechRecognitionPermission()
//            .subscribe(onNext: { [weak self] permissionGranted in
//                if !permissionGranted {
//                    let alert = UIAlertController(title: "Permission Required", message: "Please grant permission to use speech recognition.", preferredStyle: .alert)
//                    alert.addAction(UIAlertAction(title: "OK", style: .default))
//                    self?.present(alert, animated: true)
//                }
//            })
//            .disposed(by: disposeBag)
    }

    // Additional setup and layout code
}
