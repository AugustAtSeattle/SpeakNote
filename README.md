__# SpeakNote
[![SpeakNote iOS Build](https://github.com/AugustAtSeattle/SpeakNote/actions/workflows/ios.yml/badge.svg?branch=main)](https://github.com/AugustAtSeattle/SpeakNote/actions/workflows/ios.yml)
## Project Overview
SpeakNote leverages the power of Whisper and GPT to transform note-taking into a hands-free, voice-activated experience on iOS platforms. Users can effortlessly dictate tasks, manage lists, and set reminders—all through intuitive voice commands.

The application utilizes Whisper for superior voice recognition, ensuring accurate transcription of spoken words into text, while GPT's advanced AI capabilities enable smart organization and retrieval of notes. This powerful combination makes SpeakNote an essential tool for efficient and effective task management in a fast-paced world.

<img src="https://github.com/AugustAtSeattle/SpeakNote/assets/24403986/51a43c1f-5564-40a4-a955-17082f8c5a59" width="250" alt="Image 1">
<img src="https://github.com/AugustAtSeattle/SpeakNote/assets/24403986/f36a5717-9c10-494f-8b7f-ab024f565bd8" width="250" alt="Image 2">

## Features
- **Voice-Activated Note Taking**: Easily dictate notes through voice commands.
- **AI-Powered Transcription**: Utilizes GPT Whisper for accurate transcription of spoken words.
- **Intelligent Query Processing**: Leverages ChatGPT to interpret queries and provide relevant note information.
- **Local Secure Storage**: Notes are stored securely on the device, ensuring privacy and data protection.
- _(Planned) Siri Integration_: Future versions aim to integrate with Siri for an enhanced user experience.
- _(Planned) Multilingual Support_: Upcoming support for dual language commands.

## Usage 

- **Creating Notes**: Simply speak to the app to transcribe your thoughts into text notes.
- **Retrieving Notes**: Ask questions or give commands to retrieve your stored notes.
- **Managing Notes**: Edit or delete notes through voice commands.

## Quick Links to Wiki

- [Database Schema](Database-Schema) - Detailed structure of the database used in SpeakNote.
- [SQL Query Composer(GPT API Assitant](SQL-Query-Composer-(OPENAI-Assistants-API)) - A OPENAI Assistants API

### Core Features for MVP
- **Voice-Activated Note-Taking**: Users can speak to the app, and it transcribes their speech into text notes.
- **Local Storage of Notes**: Notes are stored securely in the device's local storage.
- **Basic Query Functionality**: Users can retrieve and view their notes based on simple queries.

### Architectural Design for MVP
- **Model-View-ViewModel (MVVM)**: Ideal for separating UI, business logic, and data modeling, simplifying testing and maintenance.
- **Repository Pattern**: For abstracting data access logic, beneficial for future complex data operations or additional data sources.
- **Observer Pattern**: To update the UI in real-time as new notes are created or existing ones are modified.

### Future Expansion Considerations
- **Siri Integration and Dual Language Support**: Planned for future versions as enhancements. The architecture is designed to be flexible to integrate these features without a major overhaul.
- **Modular Design**: Components like voice recognition and language processing are kept modular for easy upgrades or replacements.
- **Cloud Storage**: Future versions may support cloud storage for notes, enabling users to access their notes across devices.


## How to Contribute
We welcome contributions to the SpeakNote project. If you're interested in contributing, please read our contribution guidelines.

## License
SpeakNote is released under the [MIT License](LICENSE).

## Contact
For feedback, questions, or collaboration, please contact me. You can also [file an issue].
