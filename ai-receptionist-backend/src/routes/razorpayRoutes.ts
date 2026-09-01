import { Router } from "express";
import { RazorpayController } from "../controllers/razorpayController";

const router = Router();

/* ==========================================
   RAZORPAY PAYMENT ROUTES
========================================== */

router.post(
  "/create-order",
  RazorpayController.createOrder
);

router.post(
  "/verify",
  RazorpayController.verify
);

router.get(
  "/status/:orderId",
  RazorpayController.status
);

router.post(
  "/webhook",
  RazorpayController.webhook
);

export default router;