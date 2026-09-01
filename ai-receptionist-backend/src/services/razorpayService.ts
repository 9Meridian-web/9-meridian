import crypto from "node:crypto";

import { AppError } from "../errors/AppError";
import { env } from "../config/env";
import { createSetupToken } from "../helpers/setupToken";
import { supabase } from "../config/supabase";

interface CheckoutCustomer {
    business_name: string;
    owner_name: string;
    email: string;
    phone: string;
    industry?: string;
    plan?: string;
}

interface RazorpayOrderResponse {
    id: string;
    entity: string;
    amount: number;
    amount_paid: number;
    amount_due: number;
    currency: string;
    status: string;
    receipt: string;
}

interface RazorpayPaymentResponse {
    id: string;
    order_id?: string;
    amount: number;
    currency: string;
    status: string;
}

function basicAuth(): string {
    return Buffer.from(
        `${env.RAZORPAY_KEY_ID}:${env.RAZORPAY_KEY_SECRET}`,
    ).toString("base64");
}

async function razorpayRequest<T>(
    path: string,
    init: RequestInit = {},
): Promise<T> {
    const response = await fetch(
        `https://api.razorpay.com/v1${path}`,
        {
            ...init,
            headers: {
                Authorization: `Basic ${basicAuth()}`,
                "Content-Type": "application/json",
                ...(init.headers ?? {}),
            },
        },
    );

    const text = await response.text();

    let payload: unknown = null;

    try {
        payload = text ? JSON.parse(text) : null;
    } catch {
        payload = text;
    }

    if (!response.ok) {
        const description =
            typeof payload === "object" &&
            payload !== null
                ? String(
                      (
                          payload as {
                              error?: {
                                  description?: string;
                              };
                          }
                      ).error?.description ??
                          "Razorpay request failed.",
                  )
                : "Razorpay request failed.";

        throw new AppError(description, 502);
    }

    return payload as T;
}

function safeCompareHex(
    expected: string,
    received: string,
): boolean {
    try {
        const a = Buffer.from(expected, "hex");
        const b = Buffer.from(received, "hex");

        return (
            a.length === b.length &&
            crypto.timingSafeEqual(a, b)
        );
    } catch {
        return false;
    }
}

export class RazorpayService {

    /**
     * Create Razorpay order
     */
    static async createOrder(
        customer: CheckoutCustomer,
    ): Promise<{
        order_id: string;
        amount: number;
        currency: string;
        key_id: string;
        plan: string;
    }> {

        const plan =
            customer.plan?.trim() ||
            env.RAZORPAY_DEFAULT_PLAN;

        const amountPaise =
            env.RAZORPAY_AMOUNT_PAISE;

        if (
            !Number.isInteger(amountPaise) ||
            amountPaise <= 0
        ) {
            throw new AppError(
                "Invalid Razorpay payment amount.",
                500,
            );
        }

        const receipt = `ar_${crypto
            .randomBytes(10)
            .toString("hex")}`;

        const metadata = {
            business_name:
                customer.business_name.trim(),

            owner_name:
                customer.owner_name.trim(),

            email:
                customer.email.trim().toLowerCase(),

            phone:
                customer.phone.trim(),

            industry:
                customer.industry?.trim() ||
                "general",

            plan,
        };

        /*
         * Create the order on Razorpay.
         *
         * IMPORTANT:
         * Do not send `capture` here.
         * Razorpay's Create Order API does not accept it.
         */

        const order =
            await razorpayRequest<RazorpayOrderResponse>(
                "/orders",
                {
                    method: "POST",

                    body: JSON.stringify({
                        amount: amountPaise,

                        currency:
                            env.RAZORPAY_CURRENCY,

                        receipt,

                        notes: {
                            product:
                                "AI Receptionist",

                            plan,
                        },
                    }),
                },
            );

        /*
         * Save our internal order record.
         */

        const { error } =
            await supabase
                .from("orders")
                .insert({
                    provider: "razorpay",

                    provider_order_id:
                        order.id,

                    provider_payment_id:
                        null,

                    amount:
                        amountPaise / 100,

                    amount_paise:
                        amountPaise,

                    currency:
                        env.RAZORPAY_CURRENCY,

                    status:
                        "created",

                    receipt,

                    metadata,
                });

        /*
         * IMPORTANT:
         * Keep the real Supabase error visible in the
         * backend terminal during development.
         *
         * This allows us to identify a database/schema
         * mismatch instead of returning only a generic
         * "Unable to initialize payment order" message.
         */

        if (error) {

            console.error(
                "\n========== RAZORPAY ORDER DB ERROR ==========",
            );

            console.error({
                message: error.message,
                details: error.details,
                hint: error.hint,
                code: error.code,
            });

            console.error(
                "=============================================\n",
            );

            throw new AppError(
                "Unable to initialize the payment order.",
                500,
            );
        }

        return {
            order_id: order.id,

            amount: order.amount,

            currency: order.currency,

            key_id:
                env.RAZORPAY_KEY_ID,

            plan,
        };
    }


    /**
     * Verify Razorpay Checkout signature.
     */
    static verifyCheckoutSignature(
        orderId: string,
        paymentId: string,
        signature: string,
    ): boolean {

        const expected =
            crypto
                .createHmac(
                    "sha256",
                    env.RAZORPAY_KEY_SECRET,
                )
                .update(
                    `${orderId}|${paymentId}`,
                )
                .digest("hex");

        return safeCompareHex(
            expected,
            signature,
        );
    }


    /**
     * Verify Razorpay webhook signature.
     */
    static verifyWebhookSignature(
        rawBody: Buffer,
        signature: string,
    ): boolean {

        const expected =
            crypto
                .createHmac(
                    "sha256",
                    env.RAZORPAY_WEBHOOK_SECRET,
                )
                .update(rawBody)
                .digest("hex");

        return safeCompareHex(
            expected,
            signature,
        );
    }


    /**
     * Fetch payment directly from Razorpay.
     */
    static async fetchPayment(
        paymentId: string,
    ): Promise<RazorpayPaymentResponse> {

        return razorpayRequest<RazorpayPaymentResponse>(
            `/payments/${encodeURIComponent(
                paymentId,
            )}`,
        );
    }


    /**
     * Verify Checkout payment and fulfill order.
     */
    static async verifyAndFulfilCheckout(
        input: {
            orderId: string;
            paymentId: string;
            signature: string;
        },
    ): Promise<{
        client_id: string;
        setup_token: string;
        order_id: string;
        status: string;
    }> {

        const {
            data: order,
            error: orderError,
        } = await supabase
            .from("orders")
            .select("*")
            .eq(
                "provider",
                "razorpay",
            )
            .eq(
                "provider_order_id",
                input.orderId,
            )
            .maybeSingle();

        if (orderError) {

            console.error(
                "Razorpay verification DB error:",
                orderError,
            );

            throw new AppError(
                "Unable to verify the payment order.",
                500,
            );
        }

        if (!order) {

            throw new AppError(
                "Payment order not found.",
                404,
            );
        }

        /*
         * If another process has already fulfilled
         * the order, return the existing client.
         */

        if (order.client_id) {

            return {
                client_id:
                    String(order.client_id),

                setup_token:
                    createSetupToken(
                        String(order.client_id),
                    ),

                order_id:
                    String(order.id),

                status:
                    String(order.status),
            };
        }

        /*
         * Verify Razorpay Checkout signature.
         */

        if (
            !this.verifyCheckoutSignature(
                String(
                    order.provider_order_id,
                ),
                input.paymentId,
                input.signature,
            )
        ) {

            throw new AppError(
                "Payment verification failed.",
                400,
            );
        }

        const payment =
            await this.fetchPayment(
                input.paymentId,
            );

        if (
            payment.order_id !==
            String(order.provider_order_id)
        ) {

            throw new AppError(
                "Payment does not belong to this order.",
                400,
            );
        }

        if (
            payment.status !==
            "captured"
        ) {

            throw new AppError(
                "Payment is not captured yet. Please wait for confirmation.",
                409,
            );
        }

        if (
            Number(payment.amount) !==
            Number(order.amount_paise)
        ) {

            throw new AppError(
                "Payment amount does not match the order.",
                400,
            );
        }

        if (
            String(
                payment.currency,
            ).toUpperCase() !==
            String(
                order.currency,
            ).toUpperCase()
        ) {

            throw new AppError(
                "Payment currency does not match the order.",
                400,
            );
        }

        return this.fulfilCapturedPayment(
            String(order.id),
            String(order.provider_order_id),
            input.paymentId,
        );
    }


    /**
     * Fulfill a captured payment.
     */
    static async fulfilCapturedPayment(
        orderRowId: string,
        providerOrderId: string,
        paymentId: string,
    ): Promise<{
        client_id: string;
        setup_token: string;
        order_id: string;
        status: string;
    }> {

        const {
            data: order,
            error: orderError,
        } = await supabase
            .from("orders")
            .select("*")
            .eq(
                "id",
                orderRowId,
            )
            .eq(
                "provider",
                "razorpay",
            )
            .maybeSingle();

        if (orderError) {

            console.error(
                "Razorpay fulfillment order lookup error:",
                orderError,
            );

            throw new AppError(
                "Unable to load the payment order.",
                500,
            );
        }

        if (!order) {

            throw new AppError(
                "Payment order not found.",
                404,
            );
        }

        /*
         * Already fulfilled.
         */

        if (order.client_id) {

            return {
                client_id:
                    String(order.client_id),

                setup_token:
                    createSetupToken(
                        String(order.client_id),
                    ),

                order_id:
                    String(order.id),

                status:
                    String(order.status),
            };
        }

        const metadata =
            (order.metadata ?? {}) as Record<
                string,
                unknown
            >;

        const required = [
            "business_name",
            "owner_name",
            "email",
            "phone",
        ];

        if (
            required.some(
                (key) => !metadata[key],
            )
        ) {

            throw new AppError(
                "Payment order is missing onboarding information.",
                500,
            );
        }

        /*
         * Create client.
         */

        const clientId =
            crypto.randomUUID();

        const {
            error: clientError,
        } = await supabase
            .from("clients")
            .insert({

                id:
                    clientId,

                business_name:
                    String(
                        metadata.business_name,
                    ),

                owner_name:
                    String(
                        metadata.owner_name,
                    ),

                industry:
                    String(
                        metadata.industry ??
                            "general",
                    ),

                email:
                    String(
                        metadata.email,
                    ).toLowerCase(),

                phone:
                    String(
                        metadata.phone,
                    ),

                locale:
                    "en-IN",

                timezone:
                    "Asia/Kolkata",

                date_format:
                    "yyyy-MM-dd",

                time_format:
                    "12h",

                is_active:
                    true,

                payment_status:
                    "paid",

                onboarding_status:
                    "onboarding",

                plan:
                    String(
                        metadata.plan ??
                            env.RAZORPAY_DEFAULT_PLAN,
                    ),

                payment_order_id:
                    providerOrderId,
            });

        if (clientError) {

            console.error(
                "\n========== CLIENT CREATION ERROR ==========",
            );

            console.error({
                message:
                    clientError.message,

                details:
                    clientError.details,

                hint:
                    clientError.hint,

                code:
                    clientError.code,
            });

            console.error(
                "===========================================\n",
            );

            /*
             * Browser verification and webhook processing
             * can happen at nearly the same time.
             *
             * Check whether another process already created
             * the client.
             */

            const {
                data: existingClient,
            } = await supabase
                .from("clients")
                .select("id")
                .eq(
                    "payment_order_id",
                    providerOrderId,
                )
                .maybeSingle();

            if (!existingClient) {

                throw new AppError(
                    "Unable to create the client after payment confirmation.",
                    500,
                );
            }

            const existingClientId =
                String(
                    existingClient.id,
                );

            const {
                data:
                    updatedExistingOrder,
                error:
                    existingOrderError,
            } = await supabase
                .from("orders")
                .update({

                    client_id:
                        existingClientId,

                    provider_payment_id:
                        paymentId,

                    status:
                        "paid",

                    updated_at:
                        new Date().toISOString(),
                })
                .eq(
                    "id",
                    order.id,
                )
                .select(
                    "id,status,client_id",
                )
                .single();

            if (
                existingOrderError ||
                !updatedExistingOrder
            ) {

                console.error(
                    "Existing order finalization error:",
                    existingOrderError,
                );

                throw new AppError(
                    "Unable to finalize the paid order.",
                    500,
                );
            }

            return {

                client_id:
                    existingClientId,

                setup_token:
                    createSetupToken(
                        existingClientId,
                    ),

                order_id:
                    String(order.id),

                status:
                    "paid",
            };
        }

        /*
         * Attach the newly created client to the order.
         */

        const {
            data: updatedOrder,
            error: updateError,
        } = await supabase
            .from("orders")
            .update({

                client_id:
                    clientId,

                provider_payment_id:
                    paymentId,

                status:
                    "paid",

                updated_at:
                    new Date().toISOString(),
            })
            .eq(
                "id",
                order.id,
            )
            .is(
                "client_id",
                null,
            )
            .select(
                "id,status,client_id",
            )
            .maybeSingle();

        if (
            updateError ||
            !updatedOrder
        ) {

            console.error(
                "Paid order finalization error:",
                updateError,
            );

            /*
             * Only remove the client we just created.
             */

            await supabase
                .from("clients")
                .delete()
                .eq(
                    "id",
                    clientId,
                );

            throw new AppError(
                "Unable to finalize the paid order.",
                500,
            );
        }

        return {

            client_id:
                clientId,

            setup_token:
                createSetupToken(
                    clientId,
                ),

            order_id:
                String(order.id),

            status:
                "paid",
        };
    }


    /**
     * Lightweight order/payment status lookup, used by the frontend
     * as a fallback when the Razorpay Checkout popup's `handler`
     * callback never fires in the browser (this happens when the
     * browser blocks the third-party cookies Razorpay's hosted
     * checkout sets — Firefox and Safari do this by default, and
     * Chrome does too if the user has an ad blocker/privacy
     * extension enabled). In that situation the payment still
     * completes and the webhook worker already fulfils the order
     * server-side; this just lets the frontend find out about it
     * without relying on the popup's callback.
     */
    static async getOrderStatus(
        providerOrderId: string,
    ): Promise<{
        status: string;
        client_id: string | null;
        setup_token: string | null;
    }> {

        const {
            data: order,
            error,
        } = await supabase
            .from("orders")
            .select("status,client_id")
            .eq(
                "provider",
                "razorpay",
            )
            .eq(
                "provider_order_id",
                providerOrderId,
            )
            .maybeSingle();

        if (error) {

            console.error(
                "Razorpay order status lookup error:",
                error,
            );

            throw new AppError(
                "Unable to check the payment status.",
                500,
            );
        }

        if (!order) {

            throw new AppError(
                "Payment order not found.",
                404,
            );
        }

        if (!order.client_id) {

            return {
                status: String(order.status ?? "created"),
                client_id: null,
                setup_token: null,
            };
        }

        return {
            status: "paid",
            client_id: String(order.client_id),
            setup_token: createSetupToken(
                String(order.client_id),
            ),
        };
    }


    /**
     * Queue Razorpay webhook.
     */
    static async enqueueWebhook(
        rawBody: Buffer,
        signature: string,
        eventIdFromHeader: string,
    ): Promise<void> {

        /*
         * Verify the webhook against the EXACT raw request body.
         */

        if (
            !this.verifyWebhookSignature(
                rawBody,
                signature,
            )
        ) {

            throw new AppError(
                "Invalid Razorpay webhook signature.",
                400,
            );
        }

        /*
         * Razorpay provides the unique event ID through:
         *
         * x-razorpay-event-id
         *
         * It should NOT be read from event.id.
         */

        const eventId =
            String(
                eventIdFromHeader ??
                    "",
            ).trim();

        if (
            !eventId ||
            eventId.length > 200
        ) {

            throw new AppError(
                "Missing or invalid Razorpay webhook event ID.",
                400,
            );
        }

        /*
         * Parse the verified raw JSON body.
         */

        let payload: unknown;

        try {

            payload =
                JSON.parse(
                    rawBody.toString(
                        "utf8",
                    ),
                );

        } catch {

            throw new AppError(
                "Invalid Razorpay webhook payload.",
                400,
            );
        }

        if (
            !payload ||
            typeof payload !==
                "object" ||
            Array.isArray(payload)
        ) {

            throw new AppError(
                "Invalid Razorpay webhook payload.",
                400,
            );
        }

        const event =
            payload as Record<
                string,
                unknown
            >;

        /*
         * Razorpay webhook event name is inside the JSON body.
         */

        const eventName =
            String(
                event.event ??
                    "",
            ).trim();

        /*
         * created_at is also inside the JSON body.
         */

        const createdAt =
            Number(
                event.created_at ??
                    0,
            );

        if (
            !eventName ||
            !Number.isFinite(
                createdAt,
            ) ||
            createdAt <= 0
        ) {

            throw new AppError(
                "Invalid Razorpay webhook event.",
                400,
            );
        }

        /*
         * IMPORTANT:
         *
         * We intentionally DO NOT reject the webhook just because
         * created_at is older than 5 minutes.
         *
         * Razorpay can retry webhook deliveries.
         * The unique event ID protects us from duplicate processing.
         */

        const { error } =
            await supabase
                .from(
                    "razorpay_webhook_events",
                )
                .insert({

                    event_id:
                        eventId,

                    event_name:
                        eventName,

                    payload:
                        event,

                    signature,

                    received_at:
                        new Date().toISOString(),
                });

        /*
         * Duplicate webhook event:
         *
         * Razorpay may deliver the same event more than once.
         * The unique event_id should make the second insertion fail.
         *
         * We intentionally ignore duplicate/unique errors.
         */

        if (
            error &&
            !/duplicate|unique/i.test(
                error.message,
            )
        ) {

            console.error(
                "Razorpay webhook queue error:",
                error,
            );

            throw new AppError(
                "Unable to queue the Razorpay webhook.",
                500,
            );
        }
    }


    /**
     * Process pending webhook queue.
     */
    static async processWebhookQueue(): Promise<void> {

        const {
            data: events,
            error,
        } = await supabase
            .from(
                "razorpay_webhook_events",
            )
            .select(
                "id,event_id,event_name,payload,attempts",
            )
            .is(
                "processed_at",
                null,
            )
            .lt(
                "attempts",
                10,
            )
            .or(
                `next_attempt_at.is.null,next_attempt_at.lte.${new Date().toISOString()}`,
            )
            .order(
                "received_at",
                {
                    ascending:
                        true,
                },
            )
            .limit(10);

        if (
            error ||
            !events?.length
        ) {

            return;
        }

        for (
            const item of events
        ) {

            const {
                data: claimed,
            } = await supabase
                .from(
                    "razorpay_webhook_events",
                )
                .update({

                    processing_at:
                        new Date().toISOString(),

                    attempts:
                        Number(
                            item.attempts ??
                                0,
                        ) + 1,
                })
                .eq(
                    "id",
                    item.id,
                )
                .is(
                    "processed_at",
                    null,
                )
                .or(
                    `processing_at.is.null,processing_at.lt.${new Date(
                        Date.now() -
                            5 *
                                60 *
                                1000,
                    ).toISOString()}`,
                )
                .select("id")
                .maybeSingle();

            if (!claimed) {

                continue;
            }

            try {

                await this.processWebhookEvent(
                    item.payload as Record<
                        string,
                        unknown
                    >,
                );

                await supabase
                    .from(
                        "razorpay_webhook_events",
                    )
                    .update({

                        processed_at:
                            new Date().toISOString(),

                        last_error:
                            null,
                    })
                    .eq(
                        "id",
                        item.id,
                    );

            } catch (error) {

                const message =
                    error instanceof Error
                        ? error.message
                        : "Webhook processing failed.";

                const attempts =
                    Number(
                        item.attempts ??
                            0,
                    ) + 1;

                const delayMs =
                    Math.min(

                        60 *
                            60 *
                            1000,

                        Math.pow(
                            2,
                            Math.min(
                                attempts,
                                10,
                            ),
                        ) *
                            1000,
                    );

                await supabase
                    .from(
                        "razorpay_webhook_events",
                    )
                    .update({

                        attempts,

                        last_error:
                            message.slice(
                                0,
                                1000,
                            ),

                        next_attempt_at:
                            new Date(
                                Date.now() +
                                    delayMs,
                            ).toISOString(),
                    })
                    .eq(
                        "id",
                        item.id,
                    );
            }
        }
    }


    /**
     * Process supported Razorpay webhook events.
     */
    private static async processWebhookEvent(
        payload: Record<
            string,
            unknown
        >,
    ): Promise<void> {

        const eventName =
            String(
                payload.event ??
                    "",
            );

        /*
         * payment.captured
         */

        if (
            eventName ===
            "payment.captured"
        ) {

            const payment =
                (
                    (
                        payload.payload as Record<
                            string,
                            unknown
                        >
                    )?.payment as Record<
                        string,
                        unknown
                    >
                )?.entity ?? {};

            const paymentId =
                String(
                    (
                        payment as Record<
                            string,
                            unknown
                        >
                    ).id ??
                        "",
                );

            const orderId =
                String(
                    (
                        payment as Record<
                            string,
                            unknown
                        >
                    ).order_id ??
                        "",
                );

            if (
                !paymentId ||
                !orderId
            ) {

                throw new AppError(
                    "Razorpay captured payment is missing identifiers.",
                    400,
                );
            }

            const {
                data: order,
                error,
            } = await supabase
                .from("orders")
                .select(
                    "id,client_id,amount_paise,currency",
                )
                .eq(
                    "provider",
                    "razorpay",
                )
                .eq(
                    "provider_order_id",
                    orderId,
                )
                .maybeSingle();

            if (error) {

                throw new AppError(
                    "Unable to load the Razorpay order.",
                    500,
                );
            }

            if (!order) {

                throw new AppError(
                    "Razorpay order not found in our system.",
                    404,
                );
            }

            /*
             * Validate payment amount.
             */

            if (
                Number(
                    (
                        payment as Record<
                            string,
                            unknown
                        >
                    ).amount,
                ) !==
                Number(
                    order.amount_paise,
                )
            ) {

                throw new AppError(
                    "Razorpay payment amount mismatch.",
                    400,
                );
            }

            /*
             * Validate currency.
             */

            if (
                String(
                    (
                        payment as Record<
                            string,
                            unknown
                        >
                    ).currency,
                ).toUpperCase() !==
                String(
                    order.currency,
                ).toUpperCase()
            ) {

                throw new AppError(
                    "Razorpay payment currency mismatch.",
                    400,
                );
            }

            /*
             * Fulfill captured payment.
             */

            await this.fulfilCapturedPayment(
                String(
                    order.id,
                ),
                orderId,
                paymentId,
            );

            return;
        }


        /*
         * payment.failed
         */

        if (
            eventName ===
            "payment.failed"
        ) {

            const payment =
                (
                    (
                        payload.payload as Record<
                            string,
                            unknown
                        >
                    )?.payment as Record<
                        string,
                        unknown
                    >
                )?.entity ?? {};

            const orderId =
                String(
                    (
                        payment as Record<
                            string,
                            unknown
                        >
                    ).order_id ??
                        "",
                );

            if (orderId) {

                await supabase
                    .from("orders")
                    .update({

                        status:
                            "failed",

                        updated_at:
                            new Date().toISOString(),
                    })
                    .eq(
                        "provider",
                        "razorpay",
                    )
                    .eq(
                        "provider_order_id",
                        orderId,
                    )
                    .is(
                        "client_id",
                        null,
                    );
            }

            return;
        }


        /*
         * order.paid
         *
         * We intentionally don't create the client
         * from this event alone because payment.captured
         * contains the payment identifiers we validate.
         */

        if (
            eventName ===
            "order.paid"
        ) {

            return;
        }


        /*
         * Refund events are currently recorded in the
         * webhook inbox but don't alter client state yet.
         *
         * We'll implement refund lifecycle handling when
         * the business refund policy is finalized.
         */

        if (
            eventName ===
                "refund.created" ||
            eventName ===
                "refund.processed" ||
            eventName ===
                "refund.failed"
        ) {

            return;
        }
    }
}