const express = require("express");
const { Pool } = require("pg");
const crypto = require("crypto");

const app = express();

app.use(express.json({ limit: "2kb" }));

if (!process.env.DATABASE_URL) {
  throw new Error("Missing DATABASE_URL");
}

if (!process.env.string) {
  throw new Error("Missing string");
}

const db = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

function isAdminKey(value) {
  if (typeof value !== "string" || value.length === 0) {
    return false;
  }

  const received = Buffer.from(value);
  const expected = Buffer.from(process.env.string);

  return (
    received.length === expected.length &&
    crypto.timingSafeEqual(received, expected)
  );
}

async function initializeDatabase() {
  await db.query(`
    CREATE TABLE IF NOT EXISTS chat_messages (
      id BIGSERIAL PRIMARY KEY,
      text TEXT NOT NULL,
      verification TEXT NOT NULL
        CHECK (verification IN ('admin', 'no admin')),
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  `);
}

app.get("/", (_req, res) => {
  res.json({
    ok: true,
    service: "VerificatorOne"
  });
});

app.post("/messages", async (req, res) => {
  try {
    const message = req.body?.message;
    const apiKey = req.get("X-API-Key") || "";
    const verification = isAdminKey(apiKey) ? "admin" : "no admin";

    if (
      typeof message !== "string" ||
      !message.trim() ||
      message.trim().length > 250
    ) {
      return res.status(400).json({
        error: "Invalid message"
      });
    }

    const finalText = `${message.trim()} + ${verification}`;

    const result = await db.query(
      `INSERT INTO chat_messages (text, verification)
       VALUES ($1, $2)
       RETURNING
         id,
         text,
         verification,
         created_at AS "createdAt"`,
      [finalText, verification]
    );

    return res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error("Message error:", error);

    return res.status(500).json({
      error: "Could not save message"
    });
  }
});

app.get("/messages", async (req, res) => {
  try {
    const requestedAfter = Number(req.query.after);
    const after =
      Number.isSafeInteger(requestedAfter) && requestedAfter > 0
        ? requestedAfter
        : 0;

    const result = await db.query(
      `SELECT
         id,
         text,
         verification,
         created_at AS "createdAt"
       FROM chat_messages
       WHERE id > $1
       ORDER BY id ASC
       LIMIT 100`,
      [after]
    );

    return res.json({
      messages: result.rows
    });
  } catch (error) {
    console.error("Read error:", error);

    return res.status(500).json({
      error: "Could not read messages"
    });
  }
});

async function startServer() {
  await initializeDatabase();

  const port = Number(process.env.PORT) || 10000;

  app.listen(port, "0.0.0.0", () => {
    console.log(`VerificatorOne running on port ${port}`);
  });
}

startServer().catch((error) => {
  console.error("Startup error:", error);
  process.exit(1);
});
