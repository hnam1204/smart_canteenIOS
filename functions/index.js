const admin = require("firebase-admin");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");

admin.initializeApp();

const db = admin.firestore();

// ────────────────────────────────────────────────────────────────────
// Helper: create in-app notification document
// ────────────────────────────────────────────────────────────────────
async function addNotificationToDb(uid, { title, body, type, referenceId, extra = {} }) {
  await db.collection("notifications").add({
    userId: uid,
    title,
    message: body,
    type,
    referenceId: referenceId || "",
    ...extra,
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

// ────────────────────────────────────────────────────────────────────
// 1. Order status change -> create in-app notification
// ────────────────────────────────────────────────────────────────────
async function addManualTransferNotifications(orderId, order) {
  const orderCode = order.orderCode || orderId;
  const counterId = order.counterId || order.pickupCounter || "";
  const basePayload = {
    title: "Khách đã xác nhận chuyển khoản",
    message: `Đơn ${orderCode} đã được khách báo chuyển khoản, vui lòng kiểm tra giao dịch.`,
    type: "payment_manual_confirm",
    referenceId: orderId,
    orderId,
    orderCode,
    counterId,
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  const adminsSnapshot = await db
    .collection("users")
    .where("role", "in", ["admin", "staff"])
    .get();

  if (adminsSnapshot.empty) {
    await db.collection("notifications").add({
      userId: "admin",
      ...basePayload,
    });
    return;
  }

  const batch = db.batch();
  adminsSnapshot.forEach((userDoc) => {
    const notificationRef = db.collection("notifications").doc();
    batch.set(notificationRef, {
      userId: userDoc.id,
      ...basePayload,
    });
  });
  await batch.commit();
}

exports.onCustomerTransferConfirmed = onDocumentUpdated("orders/{orderId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

  if (before.customerConfirmedTransfer === true || after.customerConfirmedTransfer !== true) {
    return;
  }
  if (after.paymentStatus === "paid") return;

  await addManualTransferNotifications(event.params.orderId, after);
});

exports.onOrderStatusChanged = onDocumentUpdated("orders/{orderId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

  if (before.orderStatus === after.orderStatus) return;

  const uid = after.userId;
  if (!uid) return;

  const orderId = event.params.orderId;
  const orderCode = after.orderCode || orderId;

  const statusMessages = {
    confirmed: { title: "Đơn hàng đã xác nhận", body: `Đơn hàng ${orderCode} đã được xác nhận.` },
    preparing: { title: "Đang chuẩn bị đơn hàng", body: `Đơn hàng ${orderCode} đang được chuẩn bị.` },
    ready: { title: "Đơn hàng sẵn sàng nhận", body: `Đơn hàng ${orderCode} đã sẵn sàng để nhận.` },
    delivering: { title: "Đang giao hàng", body: `Đơn hàng ${orderCode} đang được giao.` },
    delivered: { title: "Đã giao hàng", body: `Đơn hàng ${orderCode} đã giao thành công!` },
    completed: { title: "Đơn hàng hoàn thành", body: `Đơn hàng ${orderCode} đã hoàn thành. Cảm ơn bạn!` },
    cancelled: { title: "Đơn hàng đã hủy", body: `Đơn hàng ${orderCode} đã bị hủy.` },
  };

  const msg = statusMessages[after.orderStatus];
  if (!msg) return;
  const isReady = after.orderStatus === "ready" || after.orderStatus === "readyForPickup";
  const counterName = after.counterName || after.pickupCounter || "Quầy nhận món";

  await addNotificationToDb(uid, {
    title: msg.title,
    body: msg.body,
    type: isReady ? "order_ready" : "order",
    referenceId: orderId,
    extra: {
      orderId,
      orderCode,
      counterId: after.counterId || "",
      counterName,
      pickupCounter: after.pickupCounter || counterName,
      data: { orderId, orderCode },
    },
  });
});

// ────────────────────────────────────────────────────────────────────
// 2. Support ticket reply -> create in-app notification
// ────────────────────────────────────────────────────────────────────
exports.onSupportMessageCreated = onDocumentCreated(
  "support_tickets/{ticketId}/messages/{messageId}",
  async (event) => {
    const message = event.data.data();
    if (!message) return;

    // Only notify when staff replies (senderType/senderRole == 'staff' or 'admin')
    const senderType = message.senderType || message.senderRole;
    if (senderType !== "staff" && senderType !== "admin") return;

    const ticketDoc = await db.collection("support_tickets").doc(event.params.ticketId).get();
    if (!ticketDoc.exists) return;

    const ticket = ticketDoc.data();
    const uid = ticket.userId;
    if (!uid) return;

    await addNotificationToDb(uid, {
      title: "Phản hồi hỗ trợ",
      body: message.text || message.message || "Bạn có phản hồi mới từ nhân viên hỗ trợ.",
      type: "support",
      referenceId: event.params.ticketId,
    });
  }
);

// ────────────────────────────────────────────────────────────────────
// 3. New voucher assigned -> create in-app notification
// ────────────────────────────────────────────────────────────────────
exports.onVoucherCreated = onDocumentCreated("user_vouchers/{docId}", async (event) => {
  const data = event.data.data();
  if (!data) return;

  const uid = data.userId;
  if (!uid) return;

  await addNotificationToDb(uid, {
    title: "Voucher mới!",
    body: data.title || "Bạn vừa nhận được một voucher mới. Sử dụng ngay!",
    type: "voucher",
    referenceId: event.params.docId,
  });
});

// ────────────────────────────────────────────────────────────────────
// 4. Review reminder after completed/delivered order -> create in-app notification
// ────────────────────────────────────────────────────────────────────
exports.onOrderCompletedReviewReminder = onDocumentUpdated("orders/{orderId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();

  // Only trigger when transitioning to completed or delivered
  const triggerStatuses = ["completed", "delivered"];
  if (triggerStatuses.includes(before.orderStatus) || !triggerStatuses.includes(after.orderStatus)) {
    return;
  }

  // Skip if already reviewed
  if (after.hasReview) return;

  const uid = after.userId;
  if (!uid) return;

  const orderCode = after.orderCode || event.params.orderId;

  await addNotificationToDb(uid, {
    title: "Đánh giá đơn hàng",
    body: `Hãy đánh giá đơn hàng ${orderCode} để nhận điểm thưởng!`,
    type: "review",
    referenceId: event.params.orderId,
  });
});

// ────────────────────────────────────────────────────────────────────
// 5. Admin creates new voucher -> Broadcast notification to all users
// ────────────────────────────────────────────────────────────────────
exports.onVoucherBroadcast = onDocumentCreated("vouchers/{voucherId}", async (event) => {
  const data = event.data.data();
  if (!data) return;

  const voucherId = event.params.voucherId;
  const voucherTitle = data.title || "Voucher mới dành cho bạn";

  // Query all users
  const usersSnapshot = await db.collection("users").get();
  if (usersSnapshot.empty) return;

  // Add notification to database for all users in parallel
  const batchSize = 500;
  let batch = db.batch();
  let count = 0;

  const promises = [];

  usersSnapshot.forEach((userDoc) => {
    const userRef = db.collection("notifications").doc();
    batch.set(userRef, {
      userId: userDoc.id,
      title: "🎁 Voucher mới dành cho bạn",
      message: `${voucherTitle}. Nhận và sử dụng ngay hôm nay!`,
      type: "voucher",
      referenceId: voucherId,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    count++;
    if (count === batchSize) {
      promises.push(batch.commit());
      batch = db.batch();
      count = 0;
    }
  });

  if (count > 0) {
    promises.push(batch.commit());
  }

  await Promise.all(promises);
});
