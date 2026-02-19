# Student Support App

A comprehensive mobile application designed to assist university students with academic and administrative tasks. Built with Flutter and Firebase.

## 🚀 Features

The **Student Support App** provides a centralized platform for students to:

*   **📅 Attendance Tracking:** View real-time attendance records and get notified when attendance drops below the required threshold.
*   **📢 Notices Board:** Stay updated with the latest university announcements and circulars.
*   **📚 Syllabus Access:** Easily access and download course syllabi for various subjects.
*   **📝 Complaint System:** Submit complaints regarding facilities or academic issues and track their status.
*   **💬 Feedback Mechanism:** Provide feedback on courses and university services.
*   **🔗 Useful Resources:** Quick links to important university portals and educational resources.

---

## 🛠️ Technology Stack

*   **Frontend:** [Flutter](https://flutter.dev/) (Dart)
*   **Backend & Cloud Services:** [Firebase](https://firebase.google.com/)
    *   **Authentication:** Secure email/password login.
    *   **Realtime Database / Firestore:** Storing student data, notices, and complaints.
    *   **Cloud Messaging (FCM):** Push notifications for important updates.
*   **Architecture:** Feature-first modular architecture for scalability and maintainability.

---

## 📱 Screenshots

*(Add screenshots of your app here)*

---

## 🏁 Getting Started

Follow these instructions to get a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

*   [Flutter SDK](https://docs.flutter.dev/get-started/install) installed and configured.
*   Android Studio or VS Code with Flutter extensions.
*   A Firebase project set up (see below).

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/AkSinghSidhu/Student-Support-App.git
    cd Student-Support-App
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Firebase Setup:**
    
    > **Important:** This project relies on Firebase. You must configure your own Firebase project to run the app successfully.
    
    Please refer to the detailed **[Firebase Setup Guide](FIREBASE_SETUP.md)** included in this repository for step-by-step instructions on:
    *   Creating a Firebase Project.
    *   Adding the `google-services.json` file to the `android/app` directory.
    *   Enabling Authentication and Database services.

4.  **Run the App:**
    ```bash
    flutter run
    ```

---

## 📂 Project Structure

```
lib/
├── core/           # Core functionality (routes, theme, services)
├── features/       # Feature modules (auth, attendance, notices, etc.)
│   ├── attendance/
│   ├── complaint/
│   ├── home/
│   └── ...
├── shared/         # Shared widgets and utilities
└── main.dart       # App entry point
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1.  Fork the project.
2.  Create your feature branch (`git checkout -b feature/AmazingFeature`).
3.  Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4.  Push to the branch (`git push origin feature/AmazingFeature`).
5.  Open a Pull Request.

---
