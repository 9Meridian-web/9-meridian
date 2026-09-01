import express, { Application, Request, Response, NextFunction } from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import path from "path";

import routes from "./routes";
import { errorHandler } from "./middlewares/errorHandler";
import { requestIdMiddleware } from "./middlewares/requestId";
import { env } from "./config/env";
import { supabase } from "./config/supabase";
import { RazorpayController } from "./controllers/razorpayController";

const app: Application = express();

app.set("trust proxy", env.NODE_ENV === "production" ? 1 : false);
app.disable("x-powered-by");

app.use(requestIdMiddleware);

/* ---------------- Security ---------------- */

app.use(
  helmet({
    contentSecurityPolicy: env.NODE_ENV === "production" ? undefined : false,
    crossOriginEmbedderPolicy: false,
    hsts: env.NODE_ENV === "production" ? undefined : false,
  })
);

/* ---------------- CORS ---------------- */

app.use(
  cors({
    origin: [
      "http://127.0.0.1:8085",
      "http://localhost:8085",
      "http://127.0.0.1:3000",
      "http://localhost:3000",
      "http://127.0.0.1:5500",
      "http://localhost:5500",
    ],
    credentials: true,
  })
);

/* ---------------- Razorpay Webhook ---------------- */

app.post(
  "/api/payments/razorpay/webhook",
  express.raw({
    type: "application/json",
    limit: "512kb",
  }),
  RazorpayController.webhook
);

/* ---------------- Body Parser ---------------- */

app.use(express.json({ limit: "2mb", strict: true }));
app.use(express.urlencoded({ extended: false, limit: "2mb" }));

/* ---------------- Logger ---------------- */

morgan.token("request-id", (_req, res) =>
  String(res.getHeader("x-request-id") ?? "-")
);

app.use(
  morgan(
    env.NODE_ENV === "production"
      ? ":request-id :method :url :status :response-time ms"
      : "[:request-id] :method :url :status :response-time ms"
  )
);

/* ---------------- Health ---------------- */

app.get("/health/live", (_req: Request, res: Response) => {
  res.json({
    success: true,
    status: "live",
  });
});

app.get("/health/ready", async (_req: Request, res: Response) => {
  try {
    const { error } = await supabase
      .from("clients")
      .select("id")
      .limit(1);

    if (error) throw error;

    res.json({
      success: true,
      status: "ready",
    });
  } catch {
    res.status(503).json({
      success: false,
      status: "not_ready",
    });
  }
});

/* ---------------- API ---------------- */

app.use("/api", routes);

/* ---------------- Frontend ---------------- */

const websitePath = path.join(process.cwd(), "9-meridian-website");

app.use(
  express.static(websitePath, {
    index: "index.html",
    extensions: ["html"],
  })
);

app.get("/", (_req: Request, res: Response) => {
  res.sendFile(path.join(websitePath, "index.html"));
});

/* SPA Fallback */

app.get(/^(?!\/api|\/health).*/, (_req: Request, res: Response) => {
  res.sendFile(path.join(websitePath, "index.html"));
});

/* ---------------- 404 ---------------- */

app.use((_req: Request, res: Response) => {
  res.status(404).json({
    success: false,
    message: "Route not found.",
    request_id: res.locals.requestId,
  });
});

/* ---------------- Error Handler ---------------- */

app.use(
  (
    error: Error,
    req: Request,
    res: Response,
    next: NextFunction
  ) => {
    errorHandler(error, req, res, next);
  }
);

export { app };
export default app;