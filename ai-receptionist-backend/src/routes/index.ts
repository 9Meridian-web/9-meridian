import { Router } from "express";

import authRoutes from "./authRoutes";
import clientRoutes from "./clientRoutes";
import serviceRoutes from "./servicesRoutes";
import bookingRoutes from "./bookingRoutes";
import googleRoutes from "./googleRoutes";
import businessSettingsRoutes from "./businessSettingsRoutes";
import aiRoutes from "./aiRoutes";
import agentRoutes from "./agentRoutes";
import onboardingRoutes from "./onboardingRoutes";
import internalRoutes from "./internalRoutes";
import razorpayRoutes from "./razorpayRoutes";

const router = Router();

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

router.use("/auth", authRoutes);

router.use("/clients", clientRoutes);

router.use("/services", serviceRoutes);

router.use("/bookings", bookingRoutes);

router.use("/google", googleRoutes);

router.use("/business-settings", businessSettingsRoutes);

router.use("/ai", aiRoutes);

router.use("/agents", agentRoutes);

router.use("/onboarding", onboardingRoutes);

router.use("/internal", internalRoutes);

router.use("/payments/razorpay", razorpayRoutes);


export default router;