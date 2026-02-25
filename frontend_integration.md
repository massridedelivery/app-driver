# Frontend Integration Guide (MVP2)

This document provides a brief overview of the backend implementation for the Flutter frontend team. It covers the core user flows, REST API expectations, and the WebSocket connection details.

---

## 1. Core User Flows

### A. Authentication Flow (Customer & Driver)

1. **Send OTP:** User opens the app and enters their phone number. App calls `POST /api/auth/otp/send`.
2. **Verify OTP:** User enters the 6-digit OTP. App calls `POST /api/auth/otp/verify`.
3. **Store Tokens:** The backend returns an `access_token` (JWT) and a `refresh_token`. The app stores these securely.
4. **Use Tokens:** All subsequent private API calls must include the header: `Authorization: Bearer <access_token>`.
5. _(Optional) Email/Password:_ Alternatively, users can register and login using `POST /api/auth/register` and `POST /api/auth/login`.

### B. Driver "Go Online" Flow

1. Driver opens the app and toggles "Online".
2. App calls `POST /api/driver/online`.
3. App establishes a WebSocket connection to `ws://localhost:8080/ws`.
4. App begins streaming the driver's GPS location via the WebSocket `location_update` message.

### C. The Ride Flow (Matching to Completion)

1. **Customer Request:** Customer selects generic pickup/dropoff coordinates. App calls `POST /api/customer/jobs/estimate` to get the fare distance and price. If acceptable, the App calls `POST /api/customer/jobs` with the payment method and exact coordinates to dispatch the job.
2. **Backend Dispatch:** Backend finds nearby online drivers and pushes a `job_offer` message via WebSocket to those drivers.
3. **Driver Accept:** A driver taps "Accept" on the offer. App sends an `accept_job` message via WebSocket (or HTTP `POST /api/driver/jobs/:id/accept`).
4. **Customer Notified:** Backend sends a `job_accepted` message to the Customer (and the accepted Driver) via WebSocket containing the assigned Driver's details.
5. **Driver En-Route:** Driver's location updates keep streaming to the backend, which forwards them to the Customer via `driver_location` WebSocket messages.
6. **Status Updates:** Driver taps "Picked Up", "Completed", etc. App sends `job_status` messages via WebSocket. Backend notifies the customer.
   - _Note:_ If `payment_method` is `CARD`, the backend auto-charges the Omise customer upon job completion.
7. **Rate Trip:** Customer gets the completed screen and calls HTTP `POST /api/customer/jobs/:id/rate`.

### D. Promotions & Credit Cards flow

1. **Save Card:** Customer enters card details (via Omise SDK on Flutter). Flutter gets `card_token`. Call `POST /api/payment/card` to save.
2. **Validate Promo:** Customer enters a coupon code. App calls `GET /api/customer/promo/validate?code=XYZ`. Backend returns discount amount.
3. **Request with Promo:** Customer calls `POST /api/customer/jobs` with `payment_method: "CARD"` and `promo_code: "XYZ"`.

---

## 2. Request / Response Standards

- **Base URL:** `http://localhost:8080` (or your local environment IP for mobile, e.g., `http://10.0.2.2:8080` for Android Emulator)
- **Content-Type:** `application/json` (except `/api/driver/documents` which is `multipart/form-data`)
- **Authentication:** `Authorization: Bearer <access_token>`
- **Full API Docs (Swagger):** Run the backend and visit `http://localhost:8080/swagger/` for complete schemas and interactive testing. A Postman collection is also synced to the repository root via Swagger.

### Common Structure

**Success (2xx):**
Returns the requested JSON object or an array.

```json
{
  "id": "u-123",
  "full_name": "John Doe",
  "phone": "+66123456789"
}
```

**Error (4xx/5xx):**
Always returns an `error` key with a human-readable message.

```json
{
  "error": "invalid otp code"
}
```

**Rate Limited (429):**
If you hit an endpoint too frequently (e.g. OTP spam), the server returns `429 Too Many Requests`.

```json
{
  "error": "Too Many Requests"
}
```

---

## 3. WebSocket Connection

The WebSocket connection is crucial for the real-time ride flow. Both Customers and Drivers use the same WebSocket endpoint.

- **Endpoint:** `ws://localhost:8080/ws`
- **Authentication:** Pass the token as a query parameter: `?token=<access_token>`

### Message Format (JSON)

All messages sent to and received from the WebSocket use this structure:

```json
{
  "type": "string", // Event name
  "data": {} // Dynamic payload based on type
}
```

### A. Messages the App sends to Backend (Upstream)

1. **Driver Location Update:**
   Sent by the Driver app every few seconds while online.

```json
{
  "type": "location_update",
  "lat": 13.7563,
  "lng": 100.5018
}
```

2. **Driver Accept Job:**

```json
{
  "type": "accept_job",
  "job_id": "uuid-here"
}
```

3. **Driver Reject Job:**

```json
{
  "type": "reject_job",
  "job_id": "uuid-here"
}
```

4. **Update Job Status (Driver or Customer cancellation):**
   Allowed statuses: `PICKED_UP`, `COMPLETED`, `CANCELLED`

```json
{
  "type": "job_status",
  "job_id": "uuid-here",
  "status": "COMPLETED"
}
```

### B. Messages the Backend sends to App (Downstream)

1. **Job Offer (To Driver):**
   When a customer requests a ride nearby.

```json
{
  "type": "job_offer",
  "data": {
    "job": {
      "id": "uuid-here",
      "pickup_lat": 13.7,
      "dropoff_lat": 13.8,
      "fare": 150.0
      // ... full job object
    }
  }
}
```

2. **Job Accepted (To Customer):**
   When a driver takes the customer's job. Includes driver details.

```json
{
  "type": "job_accepted",
  "data": {
    "job": {
      "id": "uuid",
      "status": "ACCEPTED",
      "driver_id": "uuid"
    }
  }
}
```

3. **Driver Location Stream (To Customer):**
   Live GPS updates of the assigned driver.

```json
{
  "type": "driver_location",
  "data": {
    "lat": 13.7563,
    "lng": 100.5018
  }
}
```

4. **Job Status Changed (To Both):**
   Sent when status progresses from ACCEPTED -> PICKED_UP -> COMPLETED/CANCELLED.

```json
{
  "type": "job_status",
  "data": {
    "job_id": "uuid-here",
    "status": "PICKED_UP"
  }
}
```

5. **Error Message:**
   Sent if a WebSocket command fails (e.g., trying to accept a job already taken).

```json
{
  "type": "error",
  "data": "job already taken"
}
```

---

## 4. Important Remarks

1. **Driver Location API vs WS:** The backend now supports `POST /api/driver/location` as an alternative to the WebSocket `location_update` message. You can use either one, but the WebSocket is much more efficient for battery and bandwidth during an active ride.
2. **Ping/Pong:** The WebSocket connection will automatically close if idle. The backend sends a standard WebSocket `PING` every ~54 seconds. The Flutter framework usually handles sending the automated `PONG` response, but ensure your WebSocket library handles Keep-Alives.
3. **Reconnection:** Mobile networks drop frequently. The Flutter app must handle WebSocket disconnects (`onClose`) and implement exponential backoff to automatically reconnect (`ws://.../?token=...`) and resync the current state (e.g., calling GET `/api/driver/earnings/trips` or the active job endpoint).

---

## 5. REST API Endpoint Reference

### Authentication API (Public)

#### `POST /api/auth/otp/send`

- **Request:** `{"phone": "+66...", "role": "customer" | "driver"}`
- **Response:** `{ "status": "pending" }`

#### `POST /api/auth/otp/verify`

- **Request:** `{"phone": "+66...", "code": "123456", "role": "customer" | "driver", "full_name": "New User" // Only required for first-time login }`
- **Response:** `{"access_token": "...", "refresh_token": "...", "expires_in": 900}`

#### `POST /auth/register` (Alternative to OTP)

- **Request:** `{"email": "...", "password": "...", "role": "customer" | "driver", "full_name": "..."}`
- **Response:** `{"id": "...", "email": "..."}`

#### `POST /auth/login` (Alternative to OTP)

- **Request:** `{"email": "...", "password": "..."}`
- **Response:** `{"access_token": "...", "refresh_token": "...", "expires_in": 900}`

---

### Customer API (Requires Bearer Token)

#### `GET /api/customer/profile`

- **Response:** `{"user_id": "...", "full_name": "...", "phone": "...", "rating": 5.0}`

#### `PUT /api/customer/profile`

- **Request:** `{"full_name": "Updated Name", "emergency_contact": "...", "preferences": {"quiet_ride": true, "ac_temp": "cool"}}`
- **Response:** Returns updated profile.

#### `GET /api/customer/places`

- **Response:** `[{"id": "...", "name": "Work", "lat": 1.2, "lng": 3.4}]`

#### `POST /api/customer/places`

- **Request:** `{"name": "...", "lat": 12.34, "lng": 45.67}`
- **Response:** Returns created place object.

#### `POST /api/customer/jobs/estimate` (Estimate Fare)

- **Request:**
  ```json
  {
    "pickup_lat": 13.75,
    "pickup_lng": 100.5,
    "dropoff_lat": 13.78,
    "dropoff_lng": 100.55,
    "promo_code": "DISCOUNT50" // Optional
  }
  ```
- **Response:** `{"distance_km": 5.4, "duration_min": 12.0, "base_fare": 150.0, "discount": 50.0, "total_fare": 100.0}`

#### `POST /api/customer/jobs` (Request a Ride)

- **Request:**
  ```json
  {
    "pickup_lat": 13.75,
    "pickup_lng": 100.5,
    "pickup_address": "Siam Paragon",
    "dropoff_lat": 13.78,
    "dropoff_lng": 100.55,
    "dropoff_address": "Chatuchak",
    "payment_method": "CASH", // Required: "CASH", "CARD", or "PROMPTPAY"
    "promo_code": "DISCOUNT50" // Optional
  }
  ```
- **Response (Job Created):** `{"id": "job-uuid", "status": "PENDING", "fare": 150.0, "discount": 50.0, "final_fare": 100.0 ...}`

#### `GET /api/customer/promo/validate`

- **Query:** `?code=DISCOUNT50`
- **Response:** `{"code": "DISCOUNT50", "discount_type": "flat", "discount_value": 50.0, "valid": true}`

#### `POST /api/payment/card` (Save card)

- **Request:** `{"card_token": "tokn_test_...", "email": "user@example.com"}`
- **Response:** `{"message": "card saved successfully"}`

#### `GET /api/customer/jobs/:id`

- **Response:** Returns job details.

#### `POST /api/customer/jobs/:id/rate`

- **Request:** `{"rating": 5, "comment": "Great ride"}`
- **Response:** `200 OK`

---

### Driver API (Requires Bearer Token)

#### `GET /api/driver/profile`

- **Response:** `{"user_id": "...", "full_name": "...", "vehicle_type": "...", "vehicle_plate": "...", "status": "offline", "balance": 0}`

#### `PUT /api/driver/profile`

- **Request:** `{"vehicle_type": "car", "vehicle_plate": "1234", "vehicle_color": "Red"}`
- **Response:** Returns updated profile.

#### `POST /api/driver/online`

- **Response:** `{"status": "online"}`

#### `POST /api/driver/offline`

- **Response:** `{"status": "offline"}`

#### `POST /api/driver/location`

- **Request:** `{"lat": 13.75, "lng": 100.50}`
- **Response:** `{"status": "location updated"}` (Also streams to the customer)

#### `GET /api/driver/jobs/active`

- **Response:** Returns the current actively assigned `Job` object (if any) or null/404. Used to restore state on app reload.

#### `POST /api/driver/jobs/:id/accept`

- **Response:** `200 OK` (Assigns driver to job and updates status to ACCEPTED)

#### `PATCH /api/driver/jobs/:id/status`

- **Request:** `{"status": "PICKED_UP" | "COMPLETED" | "CANCELLED"}`
- **Response:** `200 OK`

#### `GET /api/driver/earnings`

- **Response:** `{"balance": 1500.0, "total_trips": 12}`

#### `GET /api/driver/earnings/trips?page=1&limit=10`

- **Response:** `{"data": [...], "page": 1, "limit": 10}`
