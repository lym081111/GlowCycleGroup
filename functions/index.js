const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const OpenAI = require("openai");

admin.initializeApp();

const openAiKey = defineSecret("OPENAI_API_KEY");

const productSchema = {
  name: "product_packaging_scan",
  schema: {
    type: "object",
    additionalProperties: false,
    properties: {
      productName: { type: "string" },
      brand: { type: "string" },
      category: {
        type: "string",
        enum: ["Skincare", "Makeup", "Haircare", "Bodycare", "Fragrance", "Others"],
      },
      ingredients: { type: "array", items: { type: "string" } },
      manufactureDate: { type: ["string", "null"], description: "ISO yyyy-mm-dd or null" },
      expiryDate: { type: ["string", "null"], description: "ISO yyyy-mm-dd or null" },
      paoMonths: { type: ["number", "null"] },
      batchNumber: { type: "string" },
      confidence: { type: "number", minimum: 0, maximum: 1 },
    },
    required: [
      "productName",
      "brand",
      "category",
      "ingredients",
      "manufactureDate",
      "expiryDate",
      "paoMonths",
      "batchNumber",
      "confidence",
    ],
  },
  strict: true,
};

const assistantSchema = {
  name: "glow_assistant_reply",
  schema: {
    type: "object",
    additionalProperties: false,
    properties: {
      message: { type: "string" },
      productNames: { type: "array", items: { type: "string" } },
      safetyNote: { type: "string" },
    },
    required: ["message", "productNames", "safetyNote"],
  },
  strict: true,
};

exports.extractProductFromPackaging = onCall(
  { secrets: [openAiKey], timeoutSeconds: 60, memory: "512MiB" },
  async (request) => {
    requireAuth(request);
    const { ocrText = "", imageDataUri = "" } = request.data || {};
    if (!ocrText.trim() && !imageDataUri.startsWith("data:image")) {
      throw new HttpsError("invalid-argument", "OCR text or image data is required.");
    }

    const content = [
      {
        type: "input_text",
        text:
          "Extract beauty product packaging details. Use only visible evidence. " +
          "If a field is not visible, return an empty string or null. OCR text:\n" +
          ocrText.slice(0, 5000),
      },
    ];
    if (imageDataUri.startsWith("data:image")) {
      content.push({ type: "input_image", image_url: imageDataUri });
    }

    const client = new OpenAI({ apiKey: openAiKey.value() });
    const response = await client.responses.create({
      model: "gpt-4.1-mini",
      input: [
        {
          role: "system",
          content:
            "You extract cosmetics and skincare packaging data into safe JSON. " +
            "Only return information you can directly read from the supplied image or OCR. " +
            "For ingredients, only return the INCI/Ingredients list, never marketing claims, usage directions, or warnings. " +
            "For dates, only return a date when it is visibly tied to MFG/MFD/manufactured or EXP/expiry/expires/best before. " +
            "Do not calculate an expiry date from a PAO symbol. Read PAO only from an open-jar number such as 6M or 12M. " +
            "Do not infer a brand, product name, batch number, category, or date. Return empty strings or null when unclear. " +
            "Set confidence below 0.72 when any important requested field is uncertain.",
        },
        { role: "user", content },
      ],
      text: {
        format: {
          type: "json_schema",
          json_schema: productSchema,
        },
      },
    });

    return JSON.parse(response.output_text);
  },
);

exports.glowAssistantReply = onCall(
  { secrets: [openAiKey], timeoutSeconds: 60, memory: "512MiB" },
  async (request) => {
    requireAuth(request);
    const { message = "", inventory = [] } = request.data || {};
    if (!message.trim()) {
      throw new HttpsError("invalid-argument", "Message is required.");
    }

    const isEyeConcern = /\b(?:eye|eyes|eyelid|under-eye|under eye)\b/i.test(message);
    const safeInventory = isEyeConcern
      ? inventory.filter(isEyeCompatibleProduct)
      : inventory;

    const client = new OpenAI({ apiKey: openAiKey.value() });
    const response = await client.responses.create({
      model: "gpt-4.1-mini",
      input: [
        {
          role: "system",
          content:
            "You are Glow Assistant, a cautious beauty inventory assistant. " +
            "You are not a doctor. Do not diagnose. Recommend only safe, non-expired products from the inventory. " +
            "Only put exact product names supplied in the inventory into productNames. " +
            "Reply in this exact reader-friendly order: Skin signal, Suggested routine (numbered 2 to 4 steps), Avoid today, then the safety note field. " +
            "First infer whether the concern is mainly dryness, sensitivity/irritation, breakouts, or eye-area discomfort. Then choose only relevant shelf products by their name, category, ingredients, and notes. " +
            "For sensitivity or redness, prioritise gentle cleanser, barrier support, and moisturising products; avoid acids, retinoids, strong vitamin C, scrubs, and fragrance. " +
            "For breakouts, never stack multiple actives; recommend at most one clearly labelled acne treatment from the shelf and include gentle support. " +
            "When no relevant shelf product exists, say so plainly and give only general low-risk guidance. Never invent a product, ingredient, routine step, or product suitability. " +
            "For any eye, eyelid, or under-eye concern, never recommend lip products, makeup, fragrance, exfoliating acids, retinoids, vitamin C, or any product not explicitly suitable for the eye area. A non-expired product explicitly identified as an eye drop, lubricating eye drop, artificial tear, or ocular lubricant is allowed and should be prioritised for a dry-eye concern. " +
            "For dry, red, itchy, painful, swollen, light-sensitive, discharge, or persistent eye symptoms, advise the user not to put cosmetics in the eye and to seek an optometrist or doctor. " +
            "Warn the user to stop irritating actives and seek medical help for severe, painful, swollen, infected, or persistent symptoms.",
        },
        {
          role: "user",
          content:
            `User concern: ${message}\n\n` +
            `Inventory JSON: ${JSON.stringify(safeInventory).slice(0, 9000)}`,
        },
      ],
      text: {
        format: {
          type: "json_schema",
          json_schema: assistantSchema,
        },
      },
    });

    return JSON.parse(response.output_text);
  },
);

function requireAuth(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Login is required.");
  }
}

function isEyeCompatibleProduct(product) {
  const text = [
    product.name,
    product.category,
    ...(product.ingredients || []),
    product.notes,
  ]
    .join(" ")
    .toLowerCase();
  if (/\b(?:eye\s*drop|eyedrop|artificial\s*tear|lubricat(?:ing|ion)\s*(?:eye\s*)?drop|ocular\s*lubricant)\b/.test(text)) {
    return true;
  }
  if (product.category !== "Skincare") {
    return false;
  }
  return !/\b(?:lip|lipstick|lip balm|tint|gloss|mascara|eyeliner|fragrance|perfume|retinol|retinoid|aha|bha|salicylic|glycolic|lactic|vitamin c|ascorbic|scrub|exfoliat)\b/.test(text);
}
