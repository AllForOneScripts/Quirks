const express = require("express");
const { Pool } = require("pg");

const app = express();

app.use(express.json({ limit: "2kb" }));

if (!process.env.DATABASE_URL) {
  throw new Error("Falta la variable de entorno DATABASE_URL.");
}

const db = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false
  }
});

async function initializeDatabase() {
  await db.query(`
    CREATE TABLE IF NOT EXISTS chat_messages (
      id BIGSERIAL PRIMARY KEY,
      sender TEXT NOT NULL,
      sender_id BIGINT NOT NULL,
      message TEXT NOT NULL,
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
    const { sender, senderId, message } = req.body || {};
    const numericSenderId = Number(senderId);

    if (
      typeof sender !== "string" ||
      typeof message !== "string" ||
      !sender.trim() ||
      !message.trim() ||
      sender.trim().length > 32 ||
      message.trim().length > 250 ||
      !Number.isSafeInteger(numericSenderId) ||
      numericSenderId <= 0
    ) {
      return res.status(400).json({
        error: "Invalid message data"
      });
    }

    const result = await db.query(
      `INSERT INTO chat_messages (sender, sender_id, message)
       VALUES ($1, $2, $3)
       RETURNING
         id,
         sender,
         sender_id AS "senderId",
         message,
         created_at AS "createdAt"`,
      [
        sender.trim(),
        numericSenderId,
        message.trim()
      ]
    );

    return res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error("Error saving message:", error);
    return res.status(500).json({
      error: "Could not save message"
    });
  }
});

app.get("/messages", async (req, res) => {
  try {
    const requestedAfter = Number(req.query.after);
    const after = Number.isSafeInteger(requestedAfter) && requestedAfter > 0
      ? requestedAfter
      : 0;

    const result = await db.query(
      `SELECT
         id,
         sender,
         sender_id AS "senderId",
         message,
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
    console.error("Error reading messages:", error);
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
  console.error("Could not start VerificatorOne:", error);
  process.exit(1);
});
