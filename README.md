# Snooker App - Analysis and Opponent Finder

## Project Description

This mobile application is designed specifically for snooker players, a sport that, while not very popular in Spain, has a passionate community. The app offers two key functionalities:

1. **Technical Improvement**: It allows players to record and analyze snooker shots in real time. Through video processing and statistical analysis, users can gather data on shot distance, angles, and other key metrics, enabling them to improve their performance.

2. **Opponent Finder**: This feature helps users find opponents for real-life snooker matches. It uses an ELO ranking system to match players of similar skill levels, which is particularly useful in Spain, where snooker is not widely practiced.

## Technologies Used

### Backend:
- **Language**: Python
- **Framework**: FastAPI
- **Database**: MySQL/PostgreSQL (configurable via environment variables)
- **AI Models**: Used for real-time shot detection and analysis.

### Frontend:
- **Language**: Dart
- **Framework**: Flutter
- **Platform**: Android (due to time and resource constraints, there is no iOS version)

## Backend Setup Instructions

1. **Set Environment Variables**:
   - Create a `.env` file in the `backend/src` directory with the following content:
     ```bash
     SQLALCHEMY_DATABASE_URL = "<YOUR_DATABASE_URL>"
     COLOUR_BALL_MODEL_ROUTE = "static/ia_models/Colour-Balls-model.pt"
     KEYPOINTS_MODEL_ROUTE = "static/ia_models/Keypoints-model.pt"
     SNOOKER_TABLE_MAP = "static/snooker_table.png"
     SECRET_KEY = "<YOUR_SECRET_KEY>"
     ALGORITHM = "HS256"
     TOKEN_EXPIRATION = 30
     ACCESS_TOKEN_EXPIRE_MINUTES = '1000'
     PROFILE_IMAGES_DIRECTORY = "static/profile_images/"
     PROJECT_IMAGES_DIRECTORY = "static/project_images/"
     PLAYS_IMAGES_DIRECTORY = "static/plays_images/"
     PROCESSED_VIDEOS_DIRECTORY = "static/processed_videos/"
     EMAIL_USER = "<YOUR_EMAIL>"
     EMAIL_PASSWORD = "<YOUR_PASSWORD>"
     SMTP_SERVER = "<YOUR_SMTP_SERVER>"
     SMTP_PORT = "<YOUR_SMTP_PORT>"
     ```

2. **Create and Activate a Virtual Environment**:
   - From the `backend/src` directory, run:
     ```bash
     python -m venv env
     ```
   - Activate the virtual environment:
     - On Windows: `.\env\Scripts\activate`
     - On macOS/Linux: `source env/bin/activate`

3. **Install Dependencies**:
   - Install the required dependencies using `requirements.txt`:
     ```bash
     pip install -r requirements.txt
     ```

4. **Run the Backend**:
   - Start the backend server:
     ```bash
     python main.py
     ```

5. **Set Up the Database**:
   - Ensure that the database is set up correctly according to the `SQLALCHEMY_DATABASE_URL` in the `.env` file.

## Frontend Setup Instructions

1. **Deploy the Backend**:
   - Use `ngrok` to expose the backend on a public URL:
     - In the backend directory, run:
       ```bash
       ngrok.exe http 8000
       ```
     - Copy the generated `ngrok` URL and paste it into `Frontend/lib/config/constants.dart` under the `root` variable.

2. **Set Up OpenCage API Key**:
   - In the same file `Frontend/lib/config/constants.dart`, add your OpenCage API key to the `apiKey` variable.

3. **Run the App on an Android Device**:
   - Connect an Android device with developer mode enabled.
   - From any `.dart` file, press `F5` to compile and install the app on your device.

## Prerequisites

- **Backend**:
  - Python 3.x
  - MySQL/PostgreSQL (or any SQL database compatible with SQLAlchemy)
  - Dependencies listed in `requirements.txt`

- **Frontend**:
  - Flutter installed on your system.
  - An Android device with developer mode enabled.

## Contribution Guidelines

If you'd like to contribute to this project, please open an issue or fork the repository and submit a pull request with your improvements. Make sure to follow the code style guidelines established in the project.

## License

This project is licensed under the MIT License. See the `LICENSE` file for more details.
