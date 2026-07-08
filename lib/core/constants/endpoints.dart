abstract class Endpoints {
  static const fetchProductDetail = '/v1/product';

  static const paymentRecent = '/v1/payment/recent';
  static const checkoutValidate = '/v1/checkout/validate';
  static const createOrder = '/v1/orders/create-order';
  static const defaultAddress = '/v1/users/addresses/default';

  // MARK: WebSockets
  static const websocketPath = '/ws';

  // MARK: Auth
  static const otpPhoneRequest = '/auth/otp/send';
  static const phoneVerify = '/auth/otp/verify';
  static const login = '/auth/login';
  static const register = '/auth/register';

  // MARK: Driver profile
  static const driverProfile = '/api/driver/profile';
  static const driverOnline = '/api/driver/online';
  static const documentProfilePhoto = '/api/driver/documents/profile-photo';
  static const driverOffline = '/api/driver/offline';
  static const driverStatus = '/api/driver/status';
  static const documentUploadUrl = '/api/media/upload-url';
  static const mediaConfirm = '/api/media/confirm';
  static const documentConfirm = '/api/driver/documents';
  static const mediaView = '/api/media/view';

  static const phoneRegister = '/v1/auth/register-phone';
  static const phoneLogin = '/v1/auth/login-phone';
  static const phoneSelfVerify = '/v1/auth/self-verify-phone';
  static const phoneEdit = '/v1/auth/edit-phone-number';
  static const phoneChangePassword = '/v1/auth/change-password-phone';
  static const logout = '/v1/auth/logout';
  static const refreshToken = '/auth/refresh';


  // MARK: Me
  static const me = '/v1/me';
  static const meUpdate = '/v1/me/update';
  static const meAvatarUpload = '/v1/me/avatar/upload';
  static const meAddresses = '/v1/me/addresses';
  static const createAddress = '/v1/me/addresses/create';
  static const updateAddress = '/v1/me/address/update';
  static const deleteAddress = '/v1/me/address/delete';
  static const deliveryAddress = '/v1/users/addresses';

  // MARK: Shopping
  static const myCart = '/v1/carts/summary';
  static const adjustMiniCarts = '/v1/cart/mini/adjust';
  static const adjustCarts = '/v1/cart/adjust-qty';
  static const usersRequestOtp = '/v1/users/request-otp';
  static const miniCart = '/v1/cart/mini';

  // MARK: Payment
  static const paymentSummary = '/v1/orders/payment-summary';
  static const paymentStatus = '/v1/orders/payment-status';
  static const paymentMethods = '/v1/payment-methods/checkout';
  static const cardList = '/v1/payment/cards';

  // MARK: Consent
  /// /v1/me/consent/missing
  static const missingConsent = '/v1/me/consent/missing';

  /// /v1/me/consent/update
  static const updateConsent = '/v1/me/consent/update';

  // MARK: Content
  static const home = '/v1/content/app/home';
  static const template = '/v1/content/template';
  static const productList = '/v1/product/list';
  static const microSite = '/v1/content/microsites';

  // MARK: Loyalty
  static const loyaltyPointsBalance = '/v1/me/points/balance';
  static const loyaltyPointsHistory = '/v1/me/points/history';

  // MARK: Order
  static const myOrder = '/v1/my-orders';
  static const orderDetail = '/v1/orders/buyer/order-detail';
  static const myOrderToPay = '/v1/orders/buyer/my-orders/to-pay';
  static const toPayOrderDetail = '/v1/orders/buyer/bill-detail';
  static const orderRepayment = '/v1/orders/re-payment';

  // MARK: Loyalty Reward
  static const rewardCampaigns = '/v1/reward/campaign/list';
  static const rewardCampaignsDetail = '/v1/reward/campaign';
  static const rewardCampaignRedeem = '/v1/reward/campaign/redeem';
  static const redeemDetail = '/v1/reward/campaign/redeemed';
  static const rewardMyRedeems = '/v1/reward/redemptions';

  // MARK: Payment
  static const paymentCards = '/v1/payment/save/cards';
  static const paymentDeleteCard = '/v1/payment/card/delete';
  static const paymentAddCard = '/v1/payment/card/add';

  // MARK: Driver Actions & Jobs
  static const driverJobsCancel = '/api/driver/jobs/:id/cancel';
  static const driverJobsStopsArrive =
      '/api/driver/jobs/:id/stops/:stop_id/arrive';
  static const driverJobsStopsDepart =
      '/api/driver/jobs/:id/stops/:stop_id/depart';
  static const driverJobsStatus = '/api/driver/jobs/:id/status';
  static const driverJobsActive = '/api/driver/jobs/active';
  static const driverJobsActiveOffer = '/api/driver/jobs/active_offer';

  /// Cross-vertical "what am I doing now" index (SCRUM-45, v1.6.0-dev20).
  /// Lean summary — probe for `type`+`id`, then fetch detail per vertical.
  static const driverActive = '/api/driver/active';

  // MARK: Wallet & Earnings
  static const driverPayouts = '/api/driver/payouts';
  static const driverPayoutsMethod = '/api/driver/payouts/method';
  static const driverSettleDebt = '/api/driver/settle-debt';
  static String driverSettleDebtSlip(String intentId) =>
      '/api/driver/settle-debt/$intentId/slip';
  static const driverCodStatus = '/api/driver/cod-status';
  static const driverEarnings = '/api/driver/earnings';
  static const driverEarningsTransactions = '/api/driver/earnings/transactions';
  static const driverEarningsTrips = '/api/driver/earnings/trips';
  static const driverTransactions = '/api/driver/transactions';

  // MARK: Quests & Tiers
  static const driverTier = '/api/driver/tier';
  static const driverQuests = '/api/driver/quests';
  static const driverQuestsClaim = '/api/driver/quests/:id/claim';

  // MARK: SOS
  static const sosTrigger = '/api/sos/trigger';
  static const sosResolve = '/api/sos/:id/resolve';

  // MARK: Discovery & Home
  static const driverDiscoveryHome = '/api/driver/discovery/home';

  // MARK: Food Delivery
  static const foodDriverOrdersAccept = '/api/food/driver/orders/:id/accept';
  static const foodDriverOrdersPickedUp =
      '/api/food/driver/orders/:id/picked-up';
  static const foodDriverOrdersDelivered =
      '/api/food/driver/orders/:id/delivered';
  static const foodDriverOrdersActive = '/api/food/driver/orders/active';

  // MARK: Notifications
  static const registerDevice = '/api/notifications/register-device';

  // MARK: Vehicle Settings
  static const vehicleTypeToggle = '/api/driver/vehicle-types/:id/toggle';
}
