# Mass Drive App Roadmap (Driver App Breakdown)

เอกสารฉบับนี้ใช้สรุปโครงสร้างฟีเจอร์ของระบบ **Mass Drive App (ฝั่ง Driver)** ตาม Phases ต่างๆ พร้อมรายละเอียดการเชื่อมต่อ API จริงจากระบบ เพื่อใช้สำหรับสื่อสารและนำเสนอทีมผู้พัฒนา (Backend / Frontend / QA)

---

## 🎯 Overall Objective
เพื่อพัฒนาระบบ Driver Application ที่รองรับ Real-time dispatch, Tracking, Job handling, และ Financial dashboard อย่างมีประสิทธิภาพ ด้วยเทคโนโลยี **Flutter, Riverpod, WebSockets, และ REST APIs**

---

## 🛠 Phase 1: Onboarding & Authentication (การสมัครและเข้าระบบ)
**เป้าหมาย:** จัดการสถานะตัวตนของคนขับ ตั้งแต่การสมัคร, การอัปโหลดเอกสารตรวจสอบ จนกระทั่งสามารถล็อกอินพร้อมใช้งาน

### 🔗 Feature & API Mapping
| Feature / หน้าจอ | คำอธิบาย API Endpoint | Method | Payload / Params สำคัญ |
| :--- | :--- | :---: | :--- |
| **1. Request OTP** | ส่งรหัส OTP ไปยังเบอร์โทรศัพท์ของคนขับ | `POST` | `/auth/otp/send`<br>`{"phone": "...", "role": "driver"}` |
| **2. Verify OTP** | ยืนยันรหัส OTP และรับ Token เข้าระบบ | `POST` | `/auth/otp/verify`<br>`{"phone": "...", "code": "...", "role": "driver"}` |
| **3. Email Login** | ช่องทางล็อกอินสำรองผ่าน Email | `POST` | `/auth/login`<br>`{"email": "...", "password": "..."}` |
| **4. Registration** | สมัครสมาชิก (รอบแรก) | `POST` | `/auth/register`<br>`{"fullName": "...", "phone": "...", "password": "..."}` |
| **5. Driver Profile** | ดูข้อมูลและสถานะโปรไฟล์ปัจจุบันของคนขับ | `GET` | `/api/driver/profile` |
| **6. Update Profile** | แก้ไขข้อมูลส่วนตัว (ชื่อ, อีเมล) | `PUT` | `/api/driver/profile` |
| **7. Get Upload URL** | ขอ Presigned URL เพื่ออัปโหลดรูปเอกสาร (S3/Cloud) | `GET` | `/api/media/upload-url` |
| **8. Confirm Document** | ผูกลิงก์รูปภาพเข้ากับประเภทเอกสาร (ID, License) | `POST` | `/api/driver/documents` |
| **9. Registration Status** | ตรวจสอบว่าเอกสารผ่านการอนุมัติแล้วหรือยัง | `GET` | `/api/driver/status` (Check: `pending`/`approved`) |

---

## 🗺 Phase 2: Core Interface & Dispatching Hub (หน้าแรกและการรับงาน)
**เป้าหมาย:** ศูนย์กลางที่คนขับใช้เวลามากที่สุดในการรอรับงาน, จัดการสถานะ Online/Offline และเลือกประเภทบริการ

### 🔗 Feature & API Mapping
| Feature / หน้าจอ | คำอธิบาย API Endpoint | Method | Description |
| :--- | :--- | :---: | :--- |
| **1. Go Online** | เปิดระบบเพื่อเริ่มรับคำสั่งงาน | `POST` | `/api/driver/online` |
| **2. Go Offline** | ปิดระบบเพื่อหยุดพักการรับงาน | `POST` | `/api/driver/offline` |
| **3. Home Discovery** | ดึงข้อมูลแบนเนอร์ข่าวสาร กิจกรรม และแดชบอร์ดหน้าแรก | `GET` | `/api/driver/discovery/home` |
| **4. Vehicle Settings** | เปิด/ปิด ประเภทรถที่ต้องการรับงาน (เช่น มอเตอร์ไซค์, รถเก๋ง) | `POST` | `/api/driver/vehicle-types/:id/toggle` |
| **5. Real-time Tracking** | ส่งพิกัด GPS และรับ Event งานใหม่ (Push) | `WebSocket` | `/ws` (WebSocket connection) |

---

## 🚗 Phase 3: Active Job Lifecycle (กระบวนการดำเนินงานรับส่ง)
**เป้าหมาย:** การบริหารจัดการทริป ตั้งแต่กดรับงาน, เดินทางไปจุดรับ (Pickup), จนกระทั่งส่งถึงจุดหมาย (Drop-off)

### 🔗 Feature & API Mapping
| Feature / หน้าจอ | คำอธิบาย API Endpoint | Method | Flow Handling |
| :--- | :--- | :---: | :--- |
| **1. Active Offer Recovery** | ตรวจสอบหากมีงานค้างหรือกำลังยื่นข้อเสนอ (เมื่อ App หลุด) | `GET` | `/api/driver/jobs/active_offer` |
| **2. Accept Order** | ยืนยันกดรับคำสั่งซื้ออาหาร / งานขนส่ง | `POST` | `/api/food/driver/orders/:id/accept` |
| **3. Arrive at Stop** | แจ้งเตือนระบบว่าคนขับ "มาถึงจุดหยุด (Stop)" แล้ว | `POST` | `/api/driver/jobs/:id/stops/:stop_id/arrive` |
| **4. Depart from Stop** | แจ้งเตือนว่าคนขับ "ออกเดินทางจากจุดหยุด" แล้ว | `POST` | `/api/driver/jobs/:id/stops/:stop_id/depart` |
| **5. Update Job Status** | การปรับปรุงสถานะทั่วไปของงาน ณ ขณะนั้น | `PATCH` | `/api/driver/jobs/:id/status` |
| **6. Food Picked Up** | (กรณีส่งอาหาร) ยืนยันว่ารับอาหารจากร้านแล้ว | `POST` | `/api/food/driver/orders/:id/picked-up` |
| **7. Food Delivered** | (กรณีส่งอาหาร) ยืนยันว่าจัดส่งถึงมือลูกค้าสำเร็จ | `POST` | `/api/food/driver/orders/:id/delivered` |
| **8. Active Job Info** | ดึงข้อมูลงานปัจจุบันที่กำลังรันอยู่ทั้งหมดเพื่อสร้างเส้นทาง Map | `GET` | `/api/driver/jobs/active` |
| **9. Cancel Job** | ยกเลิกงาน พร้อมระบุเหตุผล (เช่น ผู้โดยสารไม่มา) | `POST` | `/api/driver/jobs/:id/cancel` |

---

### 🍔 Phase 3.1: Food Delivery Feature — Incoming & Job Live (สั่งอาหาร)
**เป้าหมาย:** แยก Flow การรับ-ส่งอาหาร ออกจากการรับ-ส่งผู้โดยสาร เพื่อให้ Driver เห็นข้อมูลที่เกี่ยวข้องกับออเดอร์อาหารโดยเฉพาะ

#### ✅ Completed Features
- [x] **WebSocket Event แยก** — รับ event `food_delivery_offer` แยกจาก `job_offer` (ride) ใน `IncomingJobController`
- [x] **IncomingJobModel** — เพิ่ม fields: `restaurantName`, `deliveryFee`, `subtotal`, `orderItems`, `isFood` computed getter
- [x] **IncomingFoodModal** — UI modal เฉพาะ food (ธีมส้ม) แสดงชื่อร้าน, รายการอาหาร, ค่าส่ง, ยอดรวม
- [x] **IncomingJobScreen** — สลับ Modal อัตโนมัติตาม `job.isFood` (Ride Modal vs Food Modal)
- [x] **FoodLiveScreen** — Full 3-step flow ด้วย REST API:
  - Step 1: `heading_to_restaurant` → กด "ถึงร้านแล้ว" → ส่ง status `ARRIVED_AT_RESTAURANT`
  - Step 2: `at_restaurant` → กด "รับอาหารแล้ว" → `POST /api/food/driver/orders/:id/picked-up`
  - Step 3: `delivering` → กด "ส่งอาหารสำเร็จ" → `POST /api/food/driver/orders/:id/delivered`
- [x] **Accept Food Job** — ใช้ REST API `POST /api/food/driver/orders/:id/accept` แทน WebSocket
- [x] **History** — เพิ่ม `ServiceType.food` + mock data + ไอคอน 🏍️/🍔 แยกประเภท
- [x] **HistoryDetail** — แสดง `OrderItemsSection` สำหรับ food + ชื่อร้านอาหาร
- [x] **ServiceInfoSection** — แสดง "MassFood Delivery" แทน "Saver Bike" ตาม serviceType

#### 🔗 API / WebSocket Summary
| Action | Method | Endpoint / Event |
| :--- | :--- | :--- |
| รับ Offer อาหาร | WebSocket | `food_delivery_offer` |
| กดรับงาน Food | REST POST | `/api/food/driver/orders/:id/accept` |
| แจ้งถึงร้าน | WebSocket | `job_status` → `ARRIVED_AT_RESTAURANT` |
| รับอาหารแล้ว | REST POST | `/api/food/driver/orders/:id/picked-up` |
| ส่งอาหารสำเร็จ | REST POST | `/api/food/driver/orders/:id/delivered` |

#### 📁 Files Modified / Created
- `[NEW]` `lib/features/incoming_job/domain/models/food_order_item_model.dart`
- `[NEW]` `lib/features/incoming_job/presentation/widgets/incoming_food_modal.dart`
- `[NEW]` `lib/features/history_detail/presentation/screens/widgets/order_items_section.dart`
- `[MOD]` `lib/features/incoming_job/domain/models/incoming_job_model.dart`
- `[MOD]` `lib/features/incoming_job/presentation/controllers/incoming_job_controller.dart`
- `[MOD]` `lib/features/incoming_job/presentation/screens/incoming_job_screen.dart`
- `[MOD]` `lib/features/food_live/presentation/screens/food_live_screen.dart`
- `[MOD]` `lib/features/history/domain/models/history_item_model.dart`
- `[MOD]` `lib/features/history/presentation/screens/history_screen.dart`
- `[MOD]` `lib/features/history/presentation/widgets/history_item.dart`
- `[MOD]` `lib/features/history_detail/domain/entities/history_entity.dart`
- `[MOD]` `lib/features/history_detail/presentation/screens/history_detail_screen.dart`
- `[MOD]` `lib/features/history_detail/presentation/screens/widgets/service_info_section.dart`



---

## 💰 Phase 4: Wallet, Earnings & Gamification (การเงินและภารกิจ)
**เป้าหมาย:** โปร่งใสเรื่องรายได้ ประวัติการทำงาน และระบบช่วยกระตุ้นการขับ (Quests)

### 🔗 Feature & API Mapping
| Feature / หน้าจอ | คำอธิบาย API Endpoint | Method | Usage |
| :--- | :--- | :---: | :--- |
| **1. Daily/Weekly Earnings** | สรุปยอดรายได้วันนี้/สัปดาห์นี้ และจำนวนเที่ยว | `GET` | `/api/driver/earnings` |
| **2. Wallet Type/Balance** | ดึงยอดคงเหลือใน Cash Wallet และ Credit Wallet | `GET` | `/driver/wallet/type` |
| **3. Transaction History** | ดูประวัติการทำรายการทางการเงินทั้งหมดย้อนหลัง | `GET` | `/api/driver/transactions` |
| **4. Request Payout** | กดถอนเงินรายได้เข้าบัญชีธนาคารที่ผูกไว้ | `POST` | `/api/driver/payouts` |
| **5. Top Up Wallet** | เติมเงินเครดิตเพื่อนำไปใช้หัก Commission | `POST` | `/api/driver/topup` |
| **6. COD Status monitoring** | ตรวจสอบวงเงินเก็บเงินปลายทางว่าเกินกำหนดหรือไม่ | `GET` | `/api/driver/cod-status` |
| **7. Driver Quests** | ดูรายการภารกิจพิเศษประจำช่วงเวลา | `GET` | `/api/driver/quests` |
| **8. Claim Reward** | รับเงินรางวัลโบนัสหลังจากทำภารกิจสำเร็จ | `POST` | `/api/driver/quests/:id/claim` |
| **9. Loyalty Tier** | ตรวจสอบระดับคนขับ (Silver, Gold, Platinum) | `GET` | `/api/driver/tier` |

---

## ⚙️ Phase 5: Security & System Support (ความปลอดภัยและการตั้งค่าระบบ)
**เป้าหมาย:** ฟีเจอร์ความปลอดภัยและระบบหลังบ้านที่สนับสนุนการทำงาน

### 🔗 Feature & API Mapping
| Feature / หน้าจอ | คำอธิบาย API Endpoint | Method | Impact |
| :--- | :--- | :---: | :--- |
| **1. Push Notifications** | ลงทะเบียน Token อุปกรณ์เพื่อรับ Push Notify / Job Notification | `POST` | `/api/notifications/register-device` |
| **2. SOS Panic Button** | กดปุ่มฉุกเฉินเพื่อแจ้ง Call Center / Admin ทันที | `POST` | `/api/sos/trigger` |
| **3. Resolve SOS** | ยกเลิกหรือยืนยันจบเหตุการณ์ฉุกเฉิน | `POST` | `/api/sos/:id/resolve` |

---

## 🛠 Tech Stack Context (สำหรับนักพัฒนา)
เพื่อให้ทีมเข้าใจโครงสร้าง code เบื้องต้น:
- **Networking**: ใช้ `Dio` Library ร่วมกับ `BaseApiService` เพื่อจัดการ Header, Interceptor และ Refresh Token อัตโนมัติ
- **Clean Architecture**: แบ่ง Layer ชัดเจนเป็น `Data Sources` (API Calls) -> `Repositories` (Data Mapping) -> `Riverpod Controllers` (State Management)
- **Endpoints Registry**: ดูรายชื่อ Endpoint ทั้งหมดได้ที่ `lib/core/constants/endpoints.dart`
