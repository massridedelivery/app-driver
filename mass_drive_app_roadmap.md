# Mass Drive App Roadmap (Grab Driver Clone)

This roadmap outlines the complete development lifecycle for the **Mass Drive App**, structured into logical phases. It also maps your current project files (`lib/features/...`) to track what has been initiated and what remains.

---

## 🎯 Overall Objective
To build a scalable, real-time driver application similar to Grab Driver. The app will feature authentication, real-time geolocation, job dispatch, navigation, earnings tracking, and user profile management using **Flutter**, **Riverpod**, **GoRouter**, and **Firebase**.

---

## 🛠 Phase 1: Foundation, Onboarding & Authentication
**Goal:** Allow drivers to register, log in securely, and set up their profile and vehicle documents.

### Features
- [ ] 1. **Splash Screen:** Initial app load, checking auth state and routing.
- [ ] 2. **Authentication:** Login/Signup via Phone Number & OTP (or Email).
- [ ] 3. **Document Submission:** Uploading ID, Driver's License, and Vehicle Registration.
- [ ] 4. **Profile Management:** Viewing and editing driver details.
- [ ] 5. **Service Type Selection:** Choosing vehicle type (e.g., Bike, Car, SUV) which dictates job eligibility.

### Current Project Mapping
- `lib/features/splash_screen/`: **[Code Present]** Handles initial load and routing.
- `lib/features/auth/`: **[Code Present]** Contains login and OTP logic.
- `lib/features/profile/`: **[Code Present]** View driver details.
- `lib/features/edit_profile/`: **[Code Present]** Update driver details.
- `lib/features/service_type/`: **[Code Present]** Allows driver to select service category.

**Next Steps exactly in Phase 1:**
- Ensure robust validation for document uploads.
- Complete API integration for OTP validation.

---

## 🗺 Phase 2: Core Driver Interface & Map Integration
**Goal:** Provide the primary interface where drivers spend most of their time waiting for jobs.

### Features
- [ ] 1. **Interactive Map:** Displaying current location using Google Maps.
- [ ] 2. **Online/Offline Toggle:** Driver availability status management.
- [ ] 3. **Real-time Location Updates:** Sending driver coordinates to the backend continuously.
- [ ] 4. **Job Dispatch Listener:** Listening for incoming ride requests via WebSockets or Firebase Realtime Database.
- [ ] 5. **Incoming Job UI:** A bottom sheet or modal showing pickup/dropoff, estimated fare, and a timer to accept/decline.

### Current Project Mapping
- `lib/features/home/`: **[Code Present]** The main map interface and online/offline toggle.
- `dependencies`: `google_maps_flutter`, `firebase_core` are already in `pubspec.yaml`.

**Next Steps exactly in Phase 2:**
- Implement the "Incoming Job" pop-up UI with a countdown timer.
- Ensure background location tracking is configured and robust (requires background execution permissions).

---

## 🚗 Phase 3: Active Job Management & Navigation
**Goal:** Handle the end-to-end trip lifecycle once a driver accepts a job.

### Features
- [ ] 1. **Routing and Navigation:** Drawing polyline routes from Driver -> Pickup -> Dropoff.
- [ ] 2. **Trip Status Updates:** Changing status (Arrived at Pickup, Passenger Onboard, En-route to Dropoff, Arrived).
- [ ] 3. **Fare Calculation:** Showing final fare, waiting time fees, and toll charges (if applicable).
- [ ] 4. **Payment Collection:** Cash collection UI or digital payment confirmation.
- [ ] 5. **Cancellation & Dispute:** UI to cancel the job logically with reasons.

### Current Project Mapping
- `lib/features/job_live/`: **[Code Present]** Handles the active job view and actions.

**Next Steps exactly in Phase 3:**
- Integrate third-party map links (opening Waze or Google Maps App) for turn-by-turn navigation.
- Implement the fare summary screen natively inside the app once the trip finishes.

---

## 💰 Phase 4: Earnings, Wallet & History
**Goal:** Provide transparency on daily/weekly earnings and ride history.

### Features
- [ ] 1. **Earnings Dashboard (Income):** High-level view of today's, this week's, and total earnings.
- [ ] 2. **Cash Wallet / Credit Wallet:** Managing top-ups for driver commissions and viewing balance.
- [ ] 3. **Job History:** List of all completed, cancelled, or missed jobs.
- [ ] 4. **Job Detail View:** Viewing precise fare breakdown, route taken, and timestamps of a past trip.

### Current Project Mapping
- `lib/features/income/`: **[Code Present]** Earnings overview.
- `lib/features/history/`: **[Code Present]** List of past jobs.
- `lib/features/history_detail/`: **[Code Present]** In-depth view of a specific historical job.

**Next Steps exactly in Phase 4:**
- Build graphs or charts for income breakdown if not completed.
- Integrate the driver "Wallet" for commission deduction visibility.

---

## ⚙️ Phase 5: Advanced Options, Chat & Account Settings
**Goal:** Complete the ecosystem by adding essential secondary features.

### Features
- [ ] 1. **In-App Chat / Calling:** Communication with the passenger without revealing personal phone numbers.
- [ ] 2. **Notifications & Announcements:** Broadcast messages from admin to drivers (e.g., incentives).
- [ ] 3. **Ratings & Feedback:** Viewing passenger reviews and driver rating.
- [ ] 4. **Settings/Support:** App settings, languge selection (using `easy_localization`), terms of service, and help center.

### Current Project Mapping
- `lib/features/setting/` & `lib/features/settings/`: **[Code Present]** Settings menus.
- `lib/common/`: Likely holds reusable widgets or utilities (needs alignment for chat UI components).
- `dependencies`: `easy_localization` is present for multi-language support.

**Next Steps exactly in Phase 5:**
- Implement real-time chat between Driver and Passenger (usually via Firebase).
- Connect Firebase Cloud Messaging (FCM) for push notifications.

---

## 🚀 Summary of Current Progress
According to your `lib/features/` and `pubspec.yaml`, you have **successfully established the skeleton for all major phases**.
- The core navigation via `GoRouter` is set up (`router/app_routes.dart`).
- UI folders for `auth`, `home`, `job_live`, `history`, `income`, and `settings` are already created.
- Essential dependencies (State Management: Riverpod, Networking: Dio, Maps: Google Maps, Storage: Hive/SecureStorage) are ready.

**Immediate Recommended Actions:**
1. Deep-dive into completing the **Phase 1** Auth Flow with actual backend endpoints using `Dio`.
2. Move to **Phase 2** by displaying the driver's live location on the Map in `home_screen.dart` and setting up the online/offline toggle connection.

---

## 🔄 Development Workflow Protocol
- At the completion of each major feature or phase, the checklist `- [ ]` will be updated to `- [x]`.
- A `git add .` and `git commit -m "..."` will be performed to maintain version history accurately.
