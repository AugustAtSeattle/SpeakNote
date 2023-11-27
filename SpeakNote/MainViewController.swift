//
//  ViewController.swift
//  SpeakNote
//
//  Created by Sailor on 11/27/23.
//

import UIKit
import Speech

class MainViewController: UIViewController {
    var textView = UITextView()
    var listenButton = UIButton()
    let viewModel = SpeechViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
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
        listenButton.addTarget(self, action: #selector(toggleListening), for: .touchUpInside)
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
    
    @objc func toggleListening() {
        viewModel.isListening ? viewModel.stopListening() : viewModel.startListening()
    }


    func setupBindings() {
        // Bind ViewModel's transcribedText to textView's text
        viewModel.transcribedTextChanged = { [weak self] newText in
            DispatchQueue.main.async {
                self?.textView.text = newText
            }
        }
        
        
        // Bind ViewModel's isListening to some UI changes if needed
        viewModel.isListeningChanged = { [weak self] isListening in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.listenButton.setTitle(isListening ? "Stop Listening" : "Start Listening", for: .normal)
                self.listenButton.setTitleColor(isListening ? .systemRed : .systemBlue, for: .normal)
            }
        }
    }

    // Additional setup and layout code
}
