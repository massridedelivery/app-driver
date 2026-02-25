# Driver Integration Guide

This guide provides a detailed walkthrough for integrating a mobile or web application as a **Driver** in the `driver-backend` system.

---

## 1. Authentication

Drivers use email and password for authentication. Ensure you specify `"role": "driver"` during registration.

### Register as a Driver

`POST /auth/register`

```json
{
  "email": "driver@example.com",
  "password": "securepassword123",
  "full_name": "John Doe",
  "role": "driver"
}
```

### Login

`POST /auth/login`

```json
{
  "email": "driver@example.com",
  "password": "securepassword123"
}
```

**Response**:

```json
{
  "access_token": "eyJhbG...",
  "refresh_token": "..."
}
```

---

## 2. Setting Availability

Before receiving job offers, a driver must be "Online".

### Go Online

`POST /api/driver/online`

- **Header**: `Authorization: Bearer <TOKEN>`
- **Effect**: Makes you eligible to receive `job_offer` messages via WebSocket.

### Go Offline

`POST /api/driver/offline`

- **Header**: `Authorization: Bearer <TOKEN>`
- **Effect**: Stops job offers and removes you from the available location pool.

---

## 3. Real-time Communication (WebSocket)

Drivers **must** maintain a WebSocket connection to receive job offers and update their location.

**Connection URL**: `ws://localhost:8080/ws?token=<YOUR_JWT_TOKEN>`

### Continuous Task: Location Updates

Send your GPS coordinates every 5-10 seconds while Online.

```json
{
  "type": "location_update",
  "lat": 13.7563,
  "lng": 100.5018
}
```

---

## 4. Job Lifecycle

### Receiving an Offer (Incoming WS)

```json
{
  "type": "job_offer",
  "job": {
    "id": "uuid-123",
    "pickup_lat": 13.7,
    "pickup_lng": 100.5,
    "pickup_address": "Siam Paragon",
    "dropoff_address": "Suvarnabhumi Airport",
    "fare": 350.5,
    "distance_km": 25.4
  }
}
```

### Accepting a Job

`POST /api/driver/jobs/:id/accept`

- **Response**: `200 OK`
  ```json
  { "message": "job accepted" }
  ```
- Once accepted, other drivers can no longer claim this job.
- You will receive a `job_accepted` WS message confirming your success.

### Updating Status

Use `PATCH /api/driver/jobs/:id/status` to advance the ride:

1. **Pick Up**:
   ```json
   { "status": "PICKED_UP" }
   ```
2. **Complete Trip**:
   ```json
   { "status": "COMPLETED" }
   ```

---

## 5. Profile & Documents

Drivers must upload documents (e.g., driver's license) before they can be verified to drive.

### Upload Document

`POST /api/driver/documents`

- **Body**: `multipart/form-data`
- **Fields**:
  - `document`: (Binary file)
  - `type`: "license", "id_card", or "registration"
  - `doc_number`: "ABC-12345" (optional)

### Get Profile

`GET /api/driver/profile`
**Response**:

```json
{
  "id": "uuid-123",
  "full_name": "John Doe",
  "phone": "0812345678",
  "verification_status": "VERIFIED",
  "rating": 4.8
}
```

---

## 6. Earnings & History

### Earnings Summary

`GET /api/driver/earnings`
**Response**:

```json
{
  "total_earnings": 1540.25,
  "completed_trips": 12,
  "currency": "THB"
}
```

### Trip History

`GET /api/driver/earnings/trips?page=1&limit=10`
**Response**:

```json
{
  "data": [
    {
      "id": "uuid-abc",
      "fare": 150.0,
      "status": "COMPLETED",
      "pickup_address": "...",
      "dropoff_address": "...",
      "created_at": "2023-10-01T10:00:00Z"
    }
  ],
  "page": 1,
  "limit": 10
}
```
