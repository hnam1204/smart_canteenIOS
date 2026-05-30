const admin = require("firebase-admin");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");

admin.initializeApp();

const db = admin.firestore();

// ────────────────────────────────────────────────────────────────────
// Helper: create in-app notification document
// ────────────────────────────────────────────────────────────────────
async function addNotificationToDb(uid, { title, body, type, referenceId }) {
  await db.collection("notifications").add({
    userId: uid,
    title,
    message: body,
    type,
    referenceId: referenceId || "",
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

// ────────────────────────────────────────────────────────────────────
// Central Trigger: on notifications document created -> Send FCM & Sync Badge
// ────────────────────────────────────────────────────────────────────
exports.onNotificationCreated = onDocumentCreated("notifications/{notificationId}", async (event) => {
  const notification = event.data.data();
  if (!notification) return;

  const { userId, title, message, type, referenceId } = notification;
  if (!userId) return;

  // Fetch user settings and tokens
  const userDoc = await db.collection("users").doc(userId).get();
  if (!userDoc.exists) return;

  const userData = userDoc.data();

  // Check global and specific notification settings
  if (userData.notificationEnabled === false) return;
  const settings = userData.notificationSettings || {};
  
  if (settings[type] === false) {
    console.log(`Notification of type ${type} is disabled for user ${userId}`);
    return;
  }

  const tokens = userData.fcmTokens || [];
  if (tokens.length === 0) return;

  // Get current unread notifications count for badge
  const unreadSnapshot = await db
    .collection("notifications")
    .where("userId", "==", userId)
    .where("isRead", "==", false)
    .get();
  const unreadCount = unreadSnapshot.size;

  // Build FCM payload
  const payload = {
    notification: {
      title: title || "Smart Canteen",
      body: message || "",
    },
    data: {
      type: type || "system",
      referenceId: referenceId || "",
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: unreadCount,
          "content-available": 1,
        },
      },
    },
  };

  const invalidTokens = [];
  await Promise.all(
    tokens.map(async (token) => {
      try {
        await admin.messaging().send({ ...payload, token });
      } catch (err) {
        if (
          err.code === "messaging/invalid-registration-token" ||
          err.code === "messaging/registration-token-not-registered"
        ) {
          invalidTokens.push(token);
        }
      }
    })
  );

  // Remove stale tokens
  if (invalidTokens.length > 0) {
    await db
      .collection("users")
      .doc(userId)
      .update({
        fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
      });
  }
});

// ────────────────────────────────────────────────────────────────────
// 1. Order status change -> create in-app notification
// ────────────────────────────────────────────────────────────────────
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

  await addNotificationToDb(uid, {
    title: msg.title,
    body: msg.body,
    type: "order",
    referenceId: orderId,
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

    // Only notify when staff replies (senderType == 'staff' or 'admin')
    if (message.senderType !== "staff" && message.senderType !== "admin") return;

    const ticketDoc = await db.collection("support_tickets").doc(event.params.ticketId).get();
    if (!ticketDoc.exists) return;

    const ticket = ticketDoc.data();
    const uid = ticket.userId;
    if (!uid) return;

    await addNotificationToDb(uid, {
      title: "Phản hồi hỗ trợ",
      body: message.text || "Bạn có phản hồi mới từ nhân viên hỗ trợ.",
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
