---
title: "Driver Integration Guide"
sync_to_confluence: true
---

# Driver Integration Guide

**Last Updated:** March 10, 2026
**Version:** v1.2.0 (Production Ready)

This guide provides a detailed walkthrough for integrating as a **Driver**, covering both ride-hailing and food delivery features.

---

## 🔴 Important Changes (Must Read)

### 1. Document Verification Required

Drivers must now upload and get approval for 4 required documents before going online:

- ID card
- Driver's license
- Vehicle registration
- Insurance

**Profile Response Updated:**

```json
{
  "user_id": "uuid",
  "verified": true, // NEW - false if documents not approved
  "documents": [
    // NEW
    {
      "type": "id_card",
      "status": "approved|pending|rejected",
      "media_url": "https://...",
      "reviewed_at": "2026-03-01T10:00:00Z",
      "rejection_reason": "Document unclear" // Only when rejected
    }
  ],
  "incentive_tier": "BRONZE", // NEW - gamification tier
  "loyalty_points": 0, // NEW - if also doing customer rides
  "status": "offline"
}
```

**Action Required:**

- Add document upload screen (see "Document Upload" section below)
- Block "Go Online" button if `verified: false`
- Show rejection reason if any document rejected
- Display incentive tier badge (BRONZE/SILVER/GOLD)

---

### 2. FCM Push Notifications Required

All drivers must register for FCM push notifications to receive job offers.

**New Endpoint:**

```http
POST /api/notifications/register-device
```

**Request:**

```json
{
  "device_token": "Firebase-FCM-token",
  "device_type": "ios|android"
}
```

**Action Required:**

- Integrate Firebase SDK
- Call endpoint on every app launch
- Handle push notifications for job offers, chat messages, document status, SOS alerts

---

### 3. Driver Cancellation Now Available

Drivers can cancel accepted/picked-up jobs with required reason.

**New Endpoint:**

```http
POST /api/driver/jobs/:id/cancel
```

**Request:**

```json
{
  "reason": "vehicle_breakdown|customer_unreachable|emergency|long_pickup_time|other"
}
```

**Features:**

- Customer receives FCM notification about cancellation
- Driver status reset to 'online' after cancellation
- Cancellation rate tracked for gamification

---

### 4. Earnings & Payout System

Drivers can now view earnings and request payouts to bank accounts.

**New Endpoints:**

- `GET /api/driver/earnings` - Earnings summary
- `GET /api/driver/earnings/trips` - Trip-by-trip breakdown
- `POST /api/driver/payouts` - Request payout to bank
- `GET /api/driver/payouts` - List payout requests

**Automated T+1 Settlement:**

- Settlement runs daily at 2 AM
- Automatic bank transfers
- WHT certificates generated (3% Thai tax)

---

### 5. Multi-Stop Ride Lifecycle (NEW)

The system now supports up to 3 intermediate waypoints (5 stops total). Drivers manage these stops using specific endpoints while the job is in `PICKED_UP` status.

**New Endpoints:**

- `POST /api/driver/jobs/:id/stops/:stop_id/arrive` - Mark arrival at a waypoint
- `POST /api/driver/jobs/:id/stops/:stop_id/depart` - Mark departure from a waypoint

**Action Required:**

- Display intermediate stops in the job offer
- Show "Arrive at Stop" and "Depart from Stop" buttons sequentially during the trip

---

### 6. New Job Status: ARRIVED_AT_PICKUP

A new status exists between `ACCEPTED` and `PICKED_UP`.

**Status Flow:**
`ACCEPTED` → `ARRIVED_AT_PICKUP` → `PICKED_UP`

**Action Required:**

- Update UI to show "Arrived at Pickup" button after accepting
- Show "Start Trip" (Pick Up) button only after arriving at pickup

---

### 7. Driver Gamification (NEW)

Drivers earn tiers and complete quests for bonuses.

**New Endpoints:**

- `GET /api/driver/tier` - Get current tier and progress
- `GET /api/driver/quests` - List active quests
- `POST /api/driver/quests/:id/claim` - Claim completed quest reward

**Tiers:**

| Tier   | Weekly Jobs | Acceptance Rate | Benefits                                          |
| ------ | ----------- | --------------- | ------------------------------------------------- |
| BRONZE | 0+          | Any             | Base fare                                         |
| SILVER | 30+         | 80%+            | +3 THB/job, 1.2x quest rewards                    |
| GOLD   | 60+         | 90%+            | +7 THB/job, priority dispatch, 1.5x quest rewards |

---

### 8. Scheduled Rides (NEW)

Drivers receive scheduled rides automatically dispatched 15-30 minutes before the scheduled time.

**Features:**

- Same acceptance flow as regular rides
- FCM notification when dispatched
- Shows "Scheduled" badge in job offer

---

### 9. Surge Pricing Awareness (NEW)

During high demand, fares are multiplied by surge multiplier (up to 2.5x).

**Job Offer Includes:**

```json
{
  "type": "job_offer",
  "job": {
    "id": "uuid",
    "fare": 150.0,
    "base_fare": 100.0,
    "surge_multiplier": 1.5, // NEW
    "surge_active": true // NEW
  }
}
```

---

## 1. Profile Setup (UPDATED)

### Get Profile

`GET /api/driver/profile`

**Response:**

```json
{
  "user_id": "uuid",
  "full_name": "John Doe",
  "phone": "+66812345678",
  "rating": 4.8,
  "total_trips": 50,
  "verified": true, // NEW - document verification status
  "documents": [
    // NEW
    {
      "type": "id_card",
      "status": "approved",
      "media_url": "https://...",
      "reviewed_at": "2026-03-01T10:00:00Z"
    }
  ],
  "vehicle_type_ids": ["uuid-1", "uuid-2"],
  "vehicle_types": [
    {
      "id": "uuid-1",
      "name": "car_economy",
      "display_name": "Economy Car",
      "is_enabled": true
    }
  ],
  "vehicle_plate": "กข 1234",
  "vehicle_color": "Silver",
  "vehicle_model": "Camry",
  "vehicle_year": 2020,
  "vehicle_province": "Bangkok",
  "balance": 1500.0,
  "commission_rate": 0.2,
  "incentive_tier": "BRONZE", // NEW - gamification tier
  "acceptance_rate": 95.5, // NEW - for gamification
  "cancellation_rate": 2.1, // NEW - for gamification
  "weekly_completed_jobs": 15, // NEW - current week progress
  "status": "offline"
}
```

### Update Profile

`PUT /api/driver/profile`

```json
{
  "vehicle_type_ids": ["uuid-economy", "uuid-premium"],
  "vehicle_plate": "กข 1234",
  "vehicle_color": "Silver",
  "vehicle_model": "Camry",
  "vehicle_year": 2020,
  "vehicle_province": "Bangkok"
}
```

---

## 2. Document Upload

### Step 1: Request Presigned Upload URL

`POST /api/media/upload-url`

**Request:**

```json
{
  "file_type": "image/jpeg",
  "file_size": 1024000,
  "purpose": "driver_document",
  "document_type": "id_card" // id_card|driver_license|vehicle_registration|insurance|selfie|public_transport_license
}
```

**Response:**

```json
{
  "upload_url": "https://storage.r2.cloudflarestorage.com/bucket/key?X-Amz-Signature=...",
  "file_key": "uploads/drivers/uuid/timestamp.jpg",
  "media_id": "uuid",
  "expires_in": 3600
}
```

### Step 2: Upload File Directly to Storage

Make a PUT request to the `upload_url`:

```http
PUT {upload_url}
Content-Type: image/jpeg

{file-binary-data}
```

### Step 3: Confirm Document Upload

`POST /api/driver/documents`

**Request:**

```json
{
  "document_type": "id_card",
  "file_key": "uploads/drivers/uuid/timestamp.jpg"
}
```

**Response:**

```json
{
  "id": "uuid",
  "type": "id_card",
  "status": "pending",
  "media_url": "https://storage.example.com/doc.jpg",
  "created_at": "2026-03-01T10:00:00Z"
}
```

### Required Documents

All 4 documents must be `approved` before driver can go online:

1. **ID Card** (`id_card`)
2. **Driver's License** (`drivers_license`)
3. **Vehicle Registration** (`vehicle_registration`)
4. **Insurance** (`insurance`)

### Document Status Flow

```
pending → approved → Driver can go online
     ↓
 rejected → Must re-upload (with rejection_reason)
```

**FCM Notification:** Driver receives push notification when document status changes.

### KYC Tiers (NEW)

Drivers can choose onboarding type:

| Type | Required Documents                                   | Can Accept         |
| ---- | ---------------------------------------------------- | ------------------ |
| FOOD | ID, Standard License, Selfie                         | Food delivery only |
| RIDE | ID, Public Transport License, Vehicle Reg, Insurance | Ride-hailing only  |
| BOTH | All documents above                                  | Both ride and food |

---

## 3. Selective Availability (Toggle)

Drivers can selectively enable or disable their ride types without going offline. For example, a driver might want to stop receiving "Economy" requests while remaining available for "Premium" ones.

### Toggle Vehicle Type

`PATCH /api/driver/vehicle-types/:id/toggle`

- **URL Param**: `:id` is the Vehicle Type UUID.
- **Body**: `{"enabled": boolean}`

**Effect**:

- If the driver is **Online**, this immediately updates their eligibility in the dispatch pool.
- If **Offline**, the preference is saved and applied next time they go online.

---

## 4. Real-time Communication (WebSocket)

Drivers **must** maintain a WebSocket connection and send frequent `location_update` messages to stay in the **H3 Displacement Pool**.

The backend uses **expanding K-ring searches** (starting from the driver's hex and expanding outwards) to find the most efficient matches. If a driver fails to send a location update for more than 1 minute, they may be dropped from the active discovery sets.

**Connection URL**: `ws://<host>/ws?token=<JWT>`

### Sending Location (Outgoing WS)

Driver must send their current coordinates every 5 seconds.

```json
{
  "type": "location_update",
  "lat": 13.7563,
  "lng": 100.5018
}
```

### Receiving an Offer (Incoming WS)

When a customer requests a ride matching one of your **ENABLED** vehicle types, you receive:

```json
{
  "type": "job_offer",
  "job": {
    "id": "uuid-123",
    "pickup_lat": 13.75,
    "pickup_lng": 100.51,
    "fare": 350.5,
    "base_fare": 280.0,
    "surge_multiplier": 1.25, // NEW
    "surge_active": true, // NEW
    "status": "PENDING"
  }
}
```

> **Smart Throttling & Resync:** If the WebSocket connection drops or your app goes into the background, the server will detect the failure and fall back to sending the _identical_ job payload via **Firebase Cloud Messaging (FCM)**. Furthermore, when your app re-establishes the WebSocket connection, the backend will automatically sync your pending offer if it remains unclaimed by other drivers.
> You may also manually poll `GET /api/driver/jobs/active_offer` upon app foregrounding to recover the active job.

### Quest Progress Updates (NEW)

When completing a ride, drivers receive real-time quest progress:

```json
{
  "type": "quest_progress",
  "quest_id": "uuid",
  "quest_name": "Complete 10 rides today",
  "current_count": 5,
  "target_count": 10,
  "percent_done": 50.0,
  "reward_amount": 100.0
}
```

### Tier Change Notification (NEW)

When driver's tier changes:

```json
{
  "type": "tier_changed",
  "old_tier": "BRONZE",
  "new_tier": "SILVER",
  "benefits": ["+3 THB per job", "1.2x quest rewards"]
}
```

---

## 5. Food Delivery Integration

Drivers can also receive food delivery offers alongside ride offers. Both arrive on the same WebSocket connection.

### Receiving a Food Delivery Offer (Incoming WS)

When a restaurant accepts an order and you are nearby with capacity, you receive:

```json
{
  "type": "food_delivery_offer",
  "order_id": "order-uuid",
  "order": {
    "id": "order-uuid",
    "restaurant_id": "uuid",
    "restaurant_name": "Pad Thai Palace",
    "status": "RESTAURANT_ACCEPTED",
    "food_total": 240.0,
    "delivery_fee": 30.0,
    "total_amount": 270.0,
    "batching_enabled": true, // NEW - may be combined with other orders
    "tier": "STANDARD" // NEW - SAVER|STANDARD|PRIORITY
  }
}
```

### Accepting a Food Delivery

`POST /api/food/driver/orders/:id/accept`

- **Capacity Check**: Max **3 active food orders** per driver (batched delivery).
- **Acceptance Lock**: Uses Redis SETNX — first driver to accept wins. Returns `409` if already taken.

### Food Delivery Lifecycle

After accepting, the driver progresses through:

1. **Picked Up**: `POST /api/food/driver/orders/:id/picked-up` — Confirm food collected from restaurant.
2. **Delivered**: `POST /api/food/driver/orders/:id/delivered` — Confirm delivery to customer.

### Active Food Orders

`GET /api/food/driver/orders/active`

Returns all active food delivery orders assigned to the driver (status: `DRIVER_ASSIGNED` or `DRIVER_PICKED_UP`).

### Batch Delivery (NEW)

Drivers may receive multiple orders in a single batch:

```json
{
  "type": "food_delivery_offer",
  "batch_id": "batch-uuid",
  "orders": [
    {
      "id": "order-1",
      "restaurant_name": "Pad Thai Palace",
      "delivery_address": "123 Street A",
      "delivery_fee": 30.0
    },
    {
      "id": "order-2",
      "restaurant_name": "Burger King",
      "delivery_address": "456 Street B (nearby)",
      "delivery_fee": 25.0
    }
  ],
  "total_delivery_fee": 55.0,
  "optimized_route": ["order-1", "order-2"] // Delivery sequence
}
```

### Key Differences from Ride Jobs

| Aspect             | Ride Job                                                       | Food Delivery                                  |
| :----------------- | :------------------------------------------------------------- | :--------------------------------------------- |
| Message type       | `job_offer`                                                    | `food_delivery_offer`                          |
| Accept endpoint    | `POST /api/driver/jobs/:id/accept`                             | `POST /api/food/driver/orders/:id/accept`      |
| Status progression | PENDING → ACCEPTED → ARRIVED_AT_PICKUP → PICKED_UP → COMPLETED | DRIVER_ASSIGNED → DRIVER_PICKED_UP → DELIVERED |
| Capacity           | 1 ride at a time (busy/free)                                   | Up to 3 batched orders                         |
| Destination        | Customer's dropoff                                             | Restaurant pickup → Customer delivery          |
| Tier pricing       | Surge multiplier                                               | SAVER/STANDARD/PRIORITY delivery fees          |

---

## 6. Driver Cancellation

Drivers can cancel accepted, arrived, or picked-up jobs with a required reason.

### Cancel Job

`POST /api/driver/jobs/:id/cancel`

**Request:**

```json
{
  "reason": "vehicle_breakdown|customer_unreachable|emergency|long_pickup_time|other"
}
```

**Valid Reasons:**

- `vehicle_breakdown` - Vehicle mechanical issue
- `customer_unreachable` - Cannot locate customer
- `emergency` - Personal emergency
- `long_pickup_time` - Pickup time too long
- `other` - Other reason

**Effects:**

- Customer receives FCM notification about cancellation
- Driver status reset to `online` after cancellation
- Cancellation rate increases (affects gamification tier)
- Job becomes available for other drivers

---

## 7. Earnings & Payouts

### Get Earnings Summary

`GET /api/driver/earnings`

**Response:**

```json
{
  "total_earnings": 15000.0,
  "available_balance": 12000.0,
  "pending_payouts": 3000.0,
  "period": {
    "from": "2026-03-01",
    "to": "2026-03-09"
  },
  "trips_completed": 25,
  "breakdown": {
    "ride_earnings": 10000.0,
    "food_earnings": 5000.0,
    "quest_bonuses": 500.0,
    "tier_bonuses": 210.0, // GOLD tier: +7 THB × 30 jobs
    "commissions": -2710.0
  }
}
```

### Get Trip Breakdown

`GET /api/driver/earnings/trips?page=1&limit=10`

**Response:**

```json
{
  "data": [
    {
      "job_id": "uuid",
      "completed_at": "2026-03-01T10:00:00Z",
      "earnings": 150.0,
      "distance_km": 5.2,
      "payment_method": "CASH",
      "type": "RIDE" // or FOOD
    }
  ],
  "page": 1,
  "limit": 10,
  "total": 25
}
```

### Request Payout

`POST /api/driver/payouts`

**Request:**

```json
{
  "amount": 5000.0,
  "bank_account": {
    "bank_name": "Bangkok Bank",
    "account_number": "1234567890",
    "account_holder": "John Doe"
  }
}
```

**Rules:**

- Minimum payout amount: 100 THB
- T+1 automated settlement (no manual approval needed)
- Bank account must be valid
- Wallet ledger integration

**Payout Status Flow:**

```
pending → processing → completed
     ↓
 rejected (with reason)
```

### List Payout Requests

`GET /api/driver/payouts`

**Response:**

```json
[
  {
    "id": "uuid",
    "amount": 5000.0,
    "status": "pending|processing|completed|failed",
    "bank_account": {
      "bank_name": "Bangkok Bank",
      "account_number": "****567890",
      "account_holder": "John Doe"
    },
    "requested_at": "2026-03-01T10:00:00Z",
    "completed_at": "2026-03-02T02:00:00Z", // Settled at 2 AM
    "bank_transfer_ref": "SCB-20260302-001234" // Reference for tracking
  }
]
```

---

## 8. In-App Chat

During active trips, drivers can chat with customers via WebSocket.

### WebSocket Connection

```
ws://<host>/ws/chat?job_id={job_id}
```

### Send Message

```json
{
  "type": "chat_message",
  "room_id": "job:{job_id}",
  "content": "I'm arriving in 5 minutes",
  "msg_type": "text" // or "image"
}
```

### Receive Message

```json
{
  "type": "chat_message",
  "data": {
    "id": "uuid",
    "job_id": "uuid",
    "sender_id": "uuid",
    "sender_type": "driver|customer",
    "content": "Message text",
    "msg_type": "text|image",
    "media_url": "https://storage.example.com/image.jpg",
    "created_at": "2026-03-01T10:00:00Z"
  }
}
```

### Get Chat History

`GET /api/chat/job/:job_id/history`

**Features:**

- Real-time messaging during active trip
- Persistent history in PostgreSQL
- Support for text and image messages
- Image upload via media service
- FCM push fallback when offline

---

## 9. Gamification & Quests (NEW)

### Get Tier Status

`GET /api/driver/tier`

**Response:**

```json
{
  "current_tier": "SILVER",
  "next_tier": "GOLD",
  "weekly_jobs": 25,
  "jobs_to_next_tier": 35, // Need 60 total for GOLD
  "acceptance_rate": 92.5,
  "cancellation_rate": 3.2,
  "benefits": ["+3 THB per job", "1.2x quest rewards"],
  "next_tier_benefits": [
    "+7 THB per job",
    "Priority dispatch",
    "1.5x quest rewards"
  ]
}
```

### List Active Quests

`GET /api/driver/quests`

**Response:**

```json
[
  {
    "quest_id": "uuid",
    "name": "Complete 10 rides today",
    "name_th": "ทำ 10 เที่ยววันนี้",
    "description": "Complete 10 ride jobs before midnight",
    "quest_type": "COMPLETE_N_RIDES",
    "current_count": 5,
    "target_count": 10,
    "status": "IN_PROGRESS",
    "percent_done": 50.0,
    "reward_amount": 100.0,
    "reward_type": "CASH",
    "expires_at": "2026-03-09T23:59:59Z"
  },
  {
    "quest_id": "uuid-2",
    "name": "Peak Hour Hero",
    "description": "Complete 5 rides between 5-8 PM",
    "quest_type": "PEAK_HOUR",
    "time_start": "17:00",
    "time_end": "20:00",
    "current_count": 2,
    "target_count": 5,
    "status": "IN_PROGRESS",
    "reward_amount": 150.0
  }
]
```

### Claim Quest Reward

`POST /api/driver/quests/:id/claim`

**Response:**

```json
{
  "quest_id": "uuid",
  "reward_amount": 100.0,
  "reward_type": "CASH",
  "credited_to_wallet": true,
  "new_balance": 15100.0
}
```

**Quest Types:**

| Type             | Description                                       | Example                   |
| ---------------- | ------------------------------------------------- | ------------------------- |
| COMPLETE_N_RIDES | Complete N rides                                  | 10 rides today            |
| COMPLETE_N_FOOD  | Complete N food deliveries                        | 5 food orders             |
| PEAK_HOUR        | Complete rides during peak hours                  | 5 rides between 5-8 PM    |
| ZONE_SPECIFIC    | Complete rides in specific H3 zones               | 3 rides in Sukhumvit area |
| CONSECUTIVE      | Complete N consecutive rides without cancellation | 5 consecutive rides       |

---

## 10. COD (Cash on Delivery) Management

### Check COD Status

`GET /api/driver/cod-status`

**Response:**

```json
{
  "cod_debt": -250.0, // Negative = owes platform
  "cod_threshold": -500.0, // Block threshold
  "cod_blocked": false, // Can still accept COD orders
  "current_balance": 1500.0
}
```

### Top-Up Wallet (NEW)

`POST /api/driver/topup`

**Request:**

```json
{
  "amount": 1000.0
}
```

**Response:**

```json
{
  "intent_id": "pay_intent_uuid",
  "status": "AWAITING_PAYMENT",
  "qr_code_url": "https://api.omise.co/charges/.../qrcode",
  "expires_at": "2026-03-09T12:10:00Z" // 10 minutes
}
```

**Flow:**

1. Request top-up → Get PromptPay QR code
2. Scan and pay via banking app
3. Webhook confirms payment
4. Wallet balance updated
5. If balance >= threshold → COD unblocked

**COD Blocking:**

- When `balance < cod_threshold` (-500 THB) → `cod_blocked = true`
- Blocked drivers cannot receive COD orders (cash rides/food)
- Card/PromptPay orders still available

---

## 11. Scheduled Rides (NEW)

Drivers receive scheduled rides automatically dispatched 15-30 minutes before the scheduled time.

**Features:**

- Same WebSocket `job_offer` message as regular rides
- Shows `scheduled_at` timestamp in job details
- FCM push notification as backup
- Auto-accepted if driver is online and available

**Job Offer Example:**

```json
{
  "type": "job_offer",
  "job": {
    "id": "uuid",
    "scheduled_at": "2026-03-10T08:00:00Z",
    "is_scheduled": true,
    "pickup_lat": 13.75,
    "pickup_lng": 100.51,
    "fare": 350.5
  }
}
```

---

## 12. SOS/Emergency Button (NEW)

Drivers can trigger SOS in emergency situations.

### Trigger SOS

`POST /api/sos/trigger`

**Request:**

```json
{
  "reason": "aggressive_passenger|accident|medical_emergency|other",
  "lat": 13.7563,
  "lng": 100.5018
}
```

**Response:**

```json
{
  "incident_id": "sos-uuid",
  "status": "ACTIVE",
  "escalation_deadline": "2026-03-09T12:05:00Z", // 5 minutes from trigger
  "authorities_notified": false // Will be true after 5 min if not resolved
}
```

### Resolve SOS

`POST /api/sos/:id/resolve`

**Request:**

```json
{
  "resolution": "false_alarm|issue_resolved|police_arrived"
}
```

**Features:**

- Auto-escalation to authorities after 5 minutes if not resolved
- FCM notifications to emergency contacts
- Admin dashboard for active incidents
- Location tracking during incident

---

## 14. Discovery & Home Feed (NEW)

Drivers can now receive targeted banners and promotions based on their location (H3 zone) and performance metrics.

### Get Home Feed

`GET /api/driver/discovery/home?lat=13.7563&lng=100.5018`

**Response:**

```json
{
  "banners": [
    {
      "id": "banner-uuid",
      "title": "Peak Hour Bonus!",
      "subtitle": "Earn +50 THB for completing 5 rides between 5-8 PM",
      "image_url": "https://storage.example.com/banner.jpg",
      "action_type": "QUEST",
      "action_data": {
        "quest_id": "uuid",
        "target_count": 5,
        "reward_amount": 50.0
      },
      "priority": 1,
      "expires_at": "2026-03-10T20:00:00Z"
    },
    {
      "id": "banner-uuid-2",
      "title": "Surge Area Ahead",
      "subtitle": "1.5x fares in Sukhumvit area",
      "image_url": "https://storage.example.com/surge.jpg",
      "action_type": "MAP",
      "action_data": {
        "center_lat": 13.73,
        "center_lng": 100.56,
        "radius_km": 2.0
      },
      "priority": 2
    }
  ],
  "suggested_zones": [
    {
      "h3_index": "88652834b7fffff",
      "name": "Sukhumvit",
      "demand_level": "HIGH",
      "surge_multiplier": 1.5,
      "active_drivers": 45,
      "active_jobs": 78
    }
  ]
}
```

**Features:**

- Location-aware banners (H3 zone targeting)
- Quest promotion integration
- Surge area suggestions
- Real-time demand heatmap data

---

## 15. Driver App Checklist

Before launching:

- [ ] Document upload flow implemented (4 documents)
- [ ] FCM push notifications integrated
- [ ] WebSocket connection with auto-reconnect
- [ ] Location updates every 5 seconds
- [ ] Job offer acceptance/rejection UI
- [ ] Multi-stop ride support (arrive/depart at waypoints)
- [ ] Food delivery support (pickup + deliver)
- [ ] In-app chat with image support
- [ ] Earnings dashboard with trip breakdown
- [ ] Payout request flow
- [ ] Gamification tier display
- [ ] Quest progress tracking
- [ ] COD top-up flow (PromptPay QR)
- [ ] SOS emergency button
- [ ] Scheduled rides handling
- [ ] Surge pricing indicator
- [ ] Tier/batch delivery support
- [ ] Discovery home feed with banners
- [ ] Suggested zone heatmap
