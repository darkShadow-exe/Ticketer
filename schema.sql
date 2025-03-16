-- ==============================
-- 1. TABLES
-- ==============================

-- 1.1. Table for storing driver information --
CREATE TABLE "drivers" (
    "id" INTEGER,
    "first_name" TEXT NOT NULL,
    "last_name" TEXT NOT NULL,
    "date_of_birth" DATE,
    "license_number" TEXT UNIQUE NOT NULL,
    "address" TEXT,
    "phone_number" TEXT,
    "email" TEXT,
    PRIMARY KEY ("id")
);

-- 1.2. Table for storing vehicle information
CREATE TABLE "vehicles" (
    "id" INTEGER,
    "owner_id" INTEGER,
    "license_plate" TEXT UNIQUE NOT NULL,
    "type" TEXT,
    "make" TEXT,
    "model" TEXT,
    "year" INTEGER,
    PRIMARY KEY ("id", "owner_id"),
    FOREIGN KEY ("owner_id") REFERENCES "drivers"("id")
);

-- 1.3 Table for keeping track of vehicle registrations
CREATE TABLE "vehicle_registrations" (
    "id" INTEGER,
    "vehicle_id" INTEGER,
    "registration_date" DATETIME DEFAULT CURRENT_TIMESTAMP,
    "expiration_date" DATETIME,
    PRIMARY KEY ("id"),
    FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id")
);

-- 1.4. Table for storing officer information
CREATE TABLE "officers" (
    "id" INTEGER,
    "first_name" TEXT NOT NULL,
    "last_name" TEXT NOT NULL,
    "badge_number" TEXT UNIQUE NOT NULL,
    "department" TEXT,
    "hire_date" DATE DEFAULT CURRENT_DATE,
    PRIMARY KEY ("id")
);

-- 1.5. Table for storing technician information
CREATE TABLE "technicians" (
    "id" INTEGER,
    "first_name" TEXT NOT NULL,
    "last_name" TEXT NOT NULL,
    "phone_number" TEXT,
    "email" TEXT,
    "hire_date" DATE DEFAULT CURRENT_DATE,
    PRIMARY KEY ("id")
);

-- 1.6. Table for storing camera information
CREATE TABLE "cameras" (
    "id" INTEGER,
    "latitude" DECIMAL(8, 6) NOT NULL,
    "longitude" DECIMAL(9, 6) NOT NULL, -- https://stackoverflow.com/questions/1196415/what-datatype-to-use-when-storing-latitude-and-longitude-data-in-sql-databases
    "installation_timestamp" DATETIME DEFAULT CURRENT_TIMESTAMP,
    "last_calibration_timestamp" DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ("id")
);

-- 1.7. Logs all calibrations of cameras
CREATE TABLE "camera_calibration_log" (
    "id" INTEGER,
    "camera_id" INTEGER NOT NULL,
    "calibration_date" DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "calibrated_by" INTEGER,
    "notes" TEXT,
    PRIMARY KEY ("id", "camera_id", "calibrated_by"),
    FOREIGN KEY ("camera_id") REFERENCES "cameras"("id"),
    FOREIGN KEY ("calibrated_by") REFERENCES "technicians"("id")
);

-- 1.8.Table for storing violation information
CREATE TABLE "violations" (
    "id" INTEGER,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "fine_amount" DECIMAL(10, 2),
    PRIMARY KEY ("id")
);

-- 1.9. Table for storing ticket information
CREATE TABLE "tickets" (
    "id" INTEGER,
    "violation_id" INTEGER NOT NULL,
    "vehicle_id" INTEGER NOT NULL,
    "driver_id" INTEGER,
    "ticket_timestamp" DATETIME DEFAULT CURRENT_TIMESTAMP,
    "latitude" DECIMAL(8, 6),
    "longitude" DECIMAL(9, 6),
    "fine_amount" DECIMAL(10, 2),
    "status" TEXT CHECK ("status" IN ('Paid', 'Pending', 'Disputed')),
    "issued_by" TEXT CHECK ("issued_by" IN ('Officer', 'Camera')) NOT NULL,
    "officer_id" INTEGER,
    "camera_id" INTEGER,
    "note" TEXT,
    PRIMARY KEY ("id", "violation_id", "vehicle_id", "driver_id"),
    FOREIGN KEY ("violation_id") REFERENCES "violations"("id"),
    FOREIGN KEY ("vehicle_id") REFERENCES "vehicles"("id"),
    FOREIGN KEY ("driver_id") REFERENCES "drivers"("id"),
    FOREIGN KEY ("officer_id") REFERENCES "officers"("id"),
    FOREIGN KEY ("camera_id") REFERENCES "cameras"("id"),
    CHECK (
        ("issued_by" = 'Officer' AND "officer_id" IS NOT NULL AND "camera_id" IS NULL) OR
        ("issued_by" = 'Camera' AND "camera_id" IS NOT NULL AND "officer_id" IS NULL)
    ) -- https://stackoverflow.com/questions/2615477/conditional-sqlite-check-constraint
);

-- 1.10. Table for logging all changes of tickets
CREATE TABLE "ticket_change_log" (
    "id" INTEGER,
    "ticket_id" INTEGER,
    "old_violation_id" INTEGER,
    "new_violation_id" INTEGER,
    "old_amount" INTEGER,
    "new_amount" INTEGER,
    "old_status" TEXT,
    "new_status" TEXT,
    "change_timestamp" DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY ("id", "ticket_id", "old_violation_id", "new_violation_id"),
    FOREIGN KEY ("ticket_id") REFERENCES "tickets"("id")
);

-- 1.11. Table for keeping track of appeals
CREATE TABLE "appeals" (
    "id" INTEGER,
    "ticket_id" INTEGER,
    "appeal_timestamp" DATETIME DEFAULT CURRENT_TIMESTAMP,
    "appeal_status" TEXT CHECK ("appeal_status" IN ('Pending', 'Accepted', 'Rejected')),
    "reason" TEXT,
    PRIMARY KEY ("id", "ticket_id"),
    FOREIGN KEY ("ticket_id") REFERENCES "tickets"("id")
);

-- 1.12. Table for storing payment information
CREATE TABLE "payments" (
    "id" INTEGER,
    "ticket_id" INTEGER,
    "payment_amount" DECIMAL(10, 2),
    "payment_date" DATETIME DEFAULT CURRENT_TIMESTAMP,
    "payment_method" TEXT,
    PRIMARY KEY ("id", "ticket_id"),
    FOREIGN KEY ("ticket_id") REFERENCES "tickets"("id")
);

-- 1.13. Table for storing points
CREATE TABLE "points" (
    "id" INTEGER,
    "driver_id" INTEGER,
    "points" REAL,
    "date_awarded" DATETIME DEFAULT CURRENT_TIMESTAMP,
    "violation_id" INTEGER,
    "note" TEXT
    PRIMARY KEY ("id", "driver_id"),
    FOREIGN KEY ("driver_id") REFERENCES "drivers"("id"),
    FOREIGN KEY ("violation_id") REFERENCES "violations"("id")
);

-- 1.14. Table for keeping track of license suspensions
CREATE TABLE "license_suspensions" (
    "id" INTEGER,
    "driver_id" INTEGER,
    "suspension_start" DATETIME,
    "suspension_end" DATETIME,
    "reason" TEXT,
    PRIMARY KEY ("id", "driver_id")
    FOREIGN KEY ("driver_id") REFERENCES "drivers"("id")
);

-- ==============================
-- 2. VIEWS
-- ==============================

-- 2.1. View to get all tickets for a specific Driver
CREATE VIEW "driver_ticket_details" AS
SELECT
    "drivers"."id" AS "driver_id",
    "drivers"."first_name" AS "driver_first_name",
    "drivers"."last_name" AS "driver_last_name",
    "violations"."name" AS "violation_name",
    "tickets"."fine_amount",
    "tickets"."status" AS "ticket_status",
    "tickets"."ticket_timestamp",
    "tickets"."issued_by",
    "officers"."first_name" AS "officer_first_name",
    "officers"."last_name" AS "officer_last_name",
    "cameras"."latitude" AS "camera_latitude",
    "cameras"."longitude" AS "camera_longitude",
    "appeals"."appeal_status" AS "appeal_status"
FROM "tickets"
LEFT JOIN "drivers" ON "tickets"."driver_id" = "drivers"."id"
LEFT JOIN "violations" ON "tickets"."violation_id" = "violations"."id"
LEFT JOIN "officers" ON "tickets"."officer_id" = "officers"."id"
LEFT JOIN "cameras" ON "tickets"."camera_id" = "cameras"."id"
LEFT JOIN "appeals" ON "tickets"."id" = "appeals"."ticket_id";

-- 2.2. View to get all vehicle registration details
CREATE VIEW "vehicle_registration_info" AS
SELECT
    "vehicles"."id" AS "vehicle_id",
    "vehicles"."license_plate",
    "vehicles"."make",
    "vehicles"."model",
    "vehicles"."year",
    "vehicles"."type",
    "vehicles"."owner_id",
    "vehicle_registrations"."registration_date",
    "vehicle_registrations"."expiration_date",
    "drivers"."first_name" AS "owner_first_name",
    "drivers"."last_name" AS "owner_last_name",
    "drivers"."license_number"
FROM "vehicle_registrations"
JOIN "vehicles" ON "vehicle_registrations"."vehicle_id" = "vehicles"."id"
JOIN "drivers" ON "vehicles"."owner_id" = "drivers"."id";

-- 2.3. View to get appeal details for a ticket
CREATE VIEW "appeal_details" AS
SELECT
    "appeals"."id" AS "appeal_id",
    "appeals"."ticket_id",
    "appeals"."appeal_timestamp",
    "appeals"."appeal_status",
    "appeals"."reason",
    "tickets"."fine_amount" AS "ticket_fine",
    "tickets"."status" AS "ticket_status",
    "tickets"."ticket_timestamp",
    "violations"."name" AS "violation_name",
    "drivers"."first_name" AS "driver_first_name",
    "drivers"."last_name" AS "driver_last_name"
FROM "appeals"
JOIN "tickets" ON "appeals"."ticket_id" = "tickets"."id"
JOIN "violations" ON "tickets"."violation_id" = "violations"."id"
JOIN "drivers" ON "tickets"."driver_id" = "drivers"."id";

-- 2.4. View to get payment details for tickets
CREATE VIEW "payments_info" AS
SELECT
    "payments"."id" AS "payment_id",
    "payments"."ticket_id",
    "payments"."payment_amount",
    "payments"."payment_date",
    "payments"."payment_method",
    "tickets"."fine_amount" AS "ticket_fine",
    "tickets"."status" AS "ticket_status",
    "violations"."name" AS "violation_name",
    "drivers"."first_name" AS "driver_first_name",
    "drivers"."last_name" AS "driver_last_name"
FROM "payments"
JOIN "tickets" ON "payments"."ticket_id" = "tickets"."id"
JOIN "violations" ON "tickets"."violation_id" = "violations"."id"
JOIN "drivers" ON "tickets"."driver_id" = "drivers"."id";

-- 2.5. View to get camera calibration activity log
CREATE VIEW "camera_activity_log" AS
SELECT
    "cameras"."id" AS "camera_id",
    "cameras"."latitude",
    "cameras"."longitude",
    "cameras"."installation_timestamp",
    "cameras"."last_calibration_timestamp",
    "technicians"."first_name" AS "technician_first_name",
    "technicians"."last_name" AS "technician_last_name",
    "camera_calibration_log"."calibration_date",
    "camera_calibration_log"."notes"
FROM "camera_calibration_log"
JOIN "cameras" ON "camera_calibration_log"."camera_id" = "cameras"."id"
JOIN "technicians" ON "camera_calibration_log"."calibrated_by" = "technicians"."id";

-- 2.6. View to get license suspension details for a driver
CREATE VIEW "suspension_details" AS
SELECT
    "license_suspensions"."id" AS "suspension_id",
    "license_suspensions"."driver_id",
    "license_suspensions"."suspension_start",
    "license_suspensions"."suspension_end",
    "license_suspensions"."reason",
    "drivers"."first_name" AS "driver_first_name",
    "drivers"."last_name" AS "driver_last_name",
    "drivers"."license_number"
FROM "license_suspensions"
JOIN "drivers" ON "license_suspensions"."driver_id" = "drivers"."id";

-- 2.7. View to get violation summary and fine collection
CREATE VIEW "violation_summary" AS
SELECT
    "violations"."id" AS "violation_id",
    "violations"."name" AS "violation_name",
    COUNT("tickets"."id") AS "number_of_tickets",
    SUM("tickets"."fine_amount") AS "total_fines_collected"
FROM "violations"
LEFT JOIN "tickets" ON "violations"."id" = "tickets"."violation_id"
GROUP BY "violations"."id";

-- ==============================
-- 3. INDEXES
-- ==============================

-- 3.1. Index to optimize searching for tickets by driver
CREATE INDEX "tickets_driver_id" ON "tickets"("driver_id");

-- 3.2. Index to optimize searching for tickets by violation
CREATE INDEX "tickets_violation_id" ON "tickets"("violation_id");

-- 3.3. Index to optimize searching for tickets by vehicle
CREATE INDEX "tickets_vehicle_id" ON "tickets"("vehicle_id");

-- 3.4. Index to optimize searching for tickets by status
CREATE INDEX "tickets_status" ON "tickets"("status");

-- 3.5. Index to optimize searching for appeals by ticket
CREATE INDEX "appeals_ticket_id" ON "appeals"("ticket_id");

-- 3.6. Index to optimize searching for payments by ticket
CREATE INDEX "payments_ticket_id" ON "payments"("ticket_id");

-- 3.7. Index to optimize searching for points by driver
CREATE INDEX "points_driver_id" ON "points"("driver_id");

-- 3.8. Index to optimize searching for license suspensions by driver
CREATE INDEX "license_suspensions_driver_id" ON "license_suspensions"("driver_id");

-- 3.9. Index to optimize searching for cameras by latitude and longitude
CREATE INDEX "cameras_latitude_longitude" ON "cameras"("latitude", "longitude");

-- 3.10. Index to optimize searching for vehicles by owner
CREATE INDEX "vehicles_owner_id" ON "vehicles"("owner_id");

-- 3.11. Index to optimize searching for tickets by officer
CREATE INDEX "tickets_officer_id" ON "tickets"("officer_id");

-- 3.12. Index to optimize searching for tickets by camera
CREATE INDEX "tickets_camera_id" ON "tickets"("camera_id");

-- 3.13. Index to optimize searching for camera calibration logs by camera
CREATE INDEX "camera_calibration_log_camera_id" ON "camera_calibration_log"("camera_id");

-- 3.14. Index to optimize searching for vehicles by license plate
CREATE INDEX "vehicles_license_plate" ON "vehicles"("license_plate");

-- 3.15. Index to optimize searching for drivers by license number
CREATE INDEX "drivers_license_number" ON "drivers"("license_number");

-- ==============================
-- 4. TRIGGERS
-- ==============================

-- 4.1. Trigger to update camera calibration timestamp when calibration is logged
CREATE TRIGGER "update_camera_calibration"
AFTER INSERT ON "camera_calibration_log"
FOR EACH ROW
BEGIN
    UPDATE "cameras"
    SET "last_calibration_timestamp" = NEW."calibration_date"
    WHERE "id" = NEW."camera_id";
END;

-- 4.2. Trigger to update ticket status when payment is made
CREATE TRIGGER "update_on_payment"
AFTER INSERT ON "payments"
FOR EACH ROW
BEGIN
    UPDATE "tickets"
    SET "status" = 'Paid'
    WHERE "id" = NEW."ticket_id";
END;

-- 4.3. Trigger to log ticket changes when violation is updated
CREATE TRIGGER "log_ticket_change"
AFTER UPDATE ON "violations"
FOR EACH ROW
BEGIN
    INSERT INTO "ticket_change_log" ("ticket_id", "old_violation_id", "new_violation_id", "old_amount", "new_amount", "old_status", "new_status", "change_timestamp")
    SELECT
        "tickets"."id",
        OLD."id",
        NEW."id",
        OLD."fine_amount",
        NEW."fine_amount",
        "tickets"."status",
        "tickets"."status",
        CURRENT_TIMESTAMP
    FROM "tickets"
    WHERE "tickets"."violation_id" = OLD."id";
END;

-- 4.4. Trigger to automatically suspend a driver if points go below -20
CREATE TRIGGER "suspension_threshold"
AFTER UPDATE ON "drivers"
FOR EACH ROW
BEGIN
    IF NEW."points" < -20 THEN
        INSERT INTO "license_suspensions" ("driver_id", "suspension_start", "suspension_end", "reason")
        VALUES (NEW."id", CURRENT_TIMESTAMP, DATE('now', '+1 year'), 'Exceeded negative points threshold'); --https://www.sqlite.org/lang_datefunc.html
    END IF;
END;


