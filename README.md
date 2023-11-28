# SpeakNote

## Project Overview
SpeakNote is an innovative iOS application designed to revolutionize the way users interact with note-taking apps. Utilizing voice recognition and advanced AI, SpeakNote offers a seamless experience in creating, managing, and retrieving notes through voice commands.

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

## SpeakNote Workflows

### Workflow 1: Basic Note-Taking
1. The user speaks a note.
2. The app sends the audio to Whisper for transcription.
3. Whisper returns the transcribed text.
4. The app sends this text to GPT for interpretation.
5. GPT returns an SQL query (either insert or update).
6. The app executes this SQL query in the local database.
7. The database confirms that the note has been saved.
8. Finally, the app displays a confirmation to the user.

### Workflow 2: Basic Note-Remind
1. The user speaks a question.
2. The app sends the audio to Whisper for transcription.
3. Whisper returns the transcribed text.
4. The app sends this text to GPT for interpretation.
6. it returns an SQL query (a seasch query).
7. The app executes this SQL query in the local database.
9. Finally, the app displays a search result to the user.

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
