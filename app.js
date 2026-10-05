const express = require("express");
const { Pool } = require("pg");

const app = express();
app.use(express.json({ limit: "2kb" }));

const db = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function start() {
  await db.query(`
    CREATE TABLE IF NOT EXISTS chat_messages (
      id BIGSERIAL PRIMARY KEY,
      sender TEXT NOT NULL,
      sender_id BIGINT NOT NULL,
      message TEXT NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  `);

  app.get("/", (_, res) => {
    res.json({ ok: true });
  });

  app.post("/messages", async (req, res) => {
    const { sender, senderId, message } = req.body || {};

    if (
      typeof sender ~= "string" ||
      typeof message ~= "string" ||
      !sender.trim() ||
      !message.trim() ||
      message.length > 250
    ) {
      return res.status(400).json({ error: "Invalid message" });
    }

    const result = await db.query(
      `INSERT INTO chat_messages (sender, sender_id, message)
       VALUES ($1, $2, $3)
       RETURNING id, sender, sender_id AS "senderId",
                 message, created_at AS "createdAt"`,
      [sender.trim(), senderId, message.trim()]
    );

    res.status(201).json(result.rows[0]);
  });

  app.get("/messages", async (req, res) => {
    const after = Math.max(Number(req.query.after) || 0, 0);

    const result = await db.query(
      `SELECT id, sender, sender_id AS "senderId",
              message, created_at AS "createdAt"
       FROM chat_messages
       WHERE id > $1
       ORDER BY id ASC
       LIMIT 100`,
      [after]
    );

    res.json({ messages: result.rows });
  });

  app.listen(process.env.PORT || 10000, "0.0.0.0");
}

start().catch(console.error);
