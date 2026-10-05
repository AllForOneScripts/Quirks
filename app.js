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
  ssl: {
    rejectUnauthorized: false
  }
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
      text TEXT,
      verification TEXT,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  `);

  await db.query(`
    ALTER TABLE chat_messages
    ADD COLUMN IF NOT EXISTS text TEXT;
  `);

  await db.query(`
    ALTER TABLE chat_messages
    ADD COLUMN IF NOT EXISTS verification TEXT;
  `);

  await db.query(`
    DO $$
    BEGIN
      IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'chat_messages'
          AND column_name = 'sender'
      ) THEN
        ALTER TABLE chat_messages
        ALTER COLUMN sender DROP NOT NULL;
      END IF;

      IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'chat_messages'
          AND column_name = 'sender_id'
      ) THEN
        ALTER TABLE chat_messages
        ALTER COLUMN sender_id DROP NOT NULL;
      END IF;

      IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'chat_messages'
          AND column_name = 'message'
      ) THEN
        ALTER TABLE chat_messages
        ALTER COLUMN message DROP NOT NULL;

        UPDATE chat_messages
        SET text = message
        WHERE text IS NULL;
      END IF;
    END
    $$;
  `);

  await db.query(`
    DO $$
    DECLARE
      constraint_name TEXT;
    BEGIN
      FOR constraint_name IN
        SELECT con.conname
        FROM pg_constraint con
        JOIN pg_class rel ON rel.oid = con.conrelid
        JOIN pg_namespace ns ON ns.oid = rel.relnamespace
        WHERE rel.relname = 'chat_messages'
          AND ns.nspname = 'public'
          AND con.contype = 'c'
      LOOP
        EXECUTE format(
          'ALTER TABLE public.chat_messages DROP CONSTRAINT %I',
          constraint_name
        );
      END LOOP;
    END
    $$;
  `);

  await db.query(`
    UPDATE chat_messages
    SET verification = CASE
      WHEN verification = 'admin' OR verification = '1' THEN '1'
      ELSE '0'
    END;
  `);

  await db.query(`
    ALTER TABLE chat_messages
    ALTER COLUMN text SET NOT NULL;
  `);

  await db.query(`
    ALTER TABLE chat_messages
    ALTER COLUMN verification SET NOT NULL;
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
    const v = isAdminKey(apiKey) ? "1" : "0";

    if (
      typeof message !== "string" ||
      !message.trim() ||
      message.trim().length > 250
    ) {
      return res.status(400).json({
        error: "Invalid message"
      });
    }

    const result = await db.query(
      `INSERT INTO chat_messages (text, verification)
       VALUES ($1, $2)
       RETURNING id, text, verification`,
      [message.trim(), v]
    );

    const row = result.rows[0];

    return res.status(201).json({
      id: String(row.id),
      text: row.text,
      v: row.verification
    });
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
      `SELECT id, text, verification
       FROM chat_messages
       WHERE id > $1
       ORDER BY id ASC
       LIMIT 100`,
      [after]
    );

    const messages = result.rows.map((row) => ({
      id: String(row.id),
      text: row.text,
      v: row.verification
    }));

    return res.json({ messages });
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
