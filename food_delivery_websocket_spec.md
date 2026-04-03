# Food Delivery WebSocket API Specification (App Driver & Customer App)

This document outlines the WebSocket events and payloads required to synchronize the state between the App Driver and the Customer App during an active food delivery order.

## Base Connection
The connection is managed by the central WebSocket server. Both the Driver App and Customer App connect to the designated `wss://` endpoint using their respective authentication tokens.

## Expected Events (Server -> Customer App)

The Customer App's [LiveFoodTrackingScreen](file:///Users/t.anuraksinlapakun/MassApp/customer-app/lib/features/food_order/presentation/screens/live_food_tracking_screen.dart#12-20) expects the following WebSocket events to update the UI in real-time.

### 1. `ORDER_STATUS_UPDATED`
**Trigger**: When the restaurant accepts the order, finishes preparing, or when the driver picks up and delivers the order.
**Payload**:
```json
{
  "type": "ORDER_STATUS_UPDATED",
  "data": {
    "orderId": "ORD-12345",
    "status": "<STATUS_CODE>"
  }
}
```
**Supported Status Codes**:
- `FINDING_DRIVER`: Searching for a driver.
- `CONFIRMING`: Driver assigned / waiting for restaurant confirmation.
- `PREPARING`: Restaurant is preparing the food.
- `DELIVERY`: Driver has picked up the food and is heading to the customer.
- `COMPLETED`: Food delivered successfully.
- `CANCELLED`: Order was cancelled.

### 2. `DRIVER_LOCATION_UPDATED`
**Trigger**: Sent periodically (e.g., every 5-10 seconds) by the Driver App while the status is `DELIVERY`.
**Payload**:
```json
{
  "type": "DRIVER_LOCATION_UPDATED",
  "data": {
    "orderId": "ORD-12345",
    "driverId": "DRV-987",
    "latitude": 13.7610,
    "longitude": 100.5050,
    "heading": 120.5 
  }
}
```

### 3. `ETA_UPDATED` (Optional but Recommended)
**Trigger**: When the routing engine calculates a new ETA based on the driver's current location.
**Payload**:
```json
{
  "type": "ETA_UPDATED",
  "data": {
    "orderId": "ORD-12345",
    "estimatedMinutes": 15
  }
}
```

## Actionable Events (App Driver -> Server)

The App Driver should emit the following events to trigger the updates above:

1. **Accept Order**: Send API or WebSocket request to transition the order from `FINDING_DRIVER` to `CONFIRMING/PREPARING`.
2. **Pickup Order**: Send API or WebSocket request when picking up the food to transition the status to `DELIVERY`.
3. **Location Sync**: Continuously emit location data while in the `DELIVERY` state.
4. **Complete Order**: Send API or WebSocket request upon successful handoff to the customer, transitioning to `COMPLETED`.

## Customer App Implementation Note
The Customer App will:
1. Connect to the socket via [SocketService](file:///Users/t.anuraksinlapakun/MassApp/customer-app/lib/core/services/socket_service.dart#21-148).
2. Listen to `ORDER_STATUS_UPDATED` to switch between UI states (Finding -> Confirming -> Preparing -> Delivery -> Receipt).
3. Listen to `DRIVER_LOCATION_UPDATED` to smoothly animate the driver's motorcycle icon on the Google Map during the `DELIVERY` phase.
