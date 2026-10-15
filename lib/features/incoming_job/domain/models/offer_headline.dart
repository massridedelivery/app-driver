/// The big figure on a job-offer card and what to call it.
///
/// รายได้สุทธิ only when the backend sent the driver's own net
/// (`driver_earnings.driver_net`). Otherwise the figure is what the customer
/// pays, so it must not be called the driver's income (BE #191).
({String label, double amount}) offerHeadline({
  required double fare,
  double? driverNet,
  bool delivery = false,
}) {
  if (driverNet != null) return (label: 'รายได้สุทธิ', amount: driverNet);
  return (label: delivery ? 'ค่าส่ง' : 'ค่าโดยสาร', amount: fare);
}
