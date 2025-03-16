-- ==============================
-- 1. SELECT
-- ==============================

-- 1.1. Find driver details by license number
SELECT * FROM "drivers" WHERE "license_number" = 'AB12345XYZ';

-- 1.2. List all active vehicle registrations
SELECT * FROM "vehicle_registrations" WHERE "expiration_date" > CURRENT_DATE;

-- 1.3. Get tickets issued by a specific officer
SELECT * FROM "tickets" WHERE "officer_id" = 5;

-- 1.4. Find the number of unpaid tickets
SELECT COUNT(*) AS "unpaid_tickets" FROM "tickets" WHERE "status" = 'Pending';

-- 1.5. Find the most common violations
SELECT "violations"."name", COUNT("tickets"."id") AS "violation_count"
FROM "violations"
JOIN "tickets" ON "violations"."id" = "tickets"."violation_id"
GROUP BY "violations"."name"
ORDER BY "violation_count" DESC
LIMIT 5;

-- ==============================
-- 2. INSERT
-- ==============================

-- 2.1. Add a new driver to the database
INSERT INTO "drivers" ("first_name", "last_name", "date_of_birth", "license_number", "address", "phone_number", "email")
VALUES ('John', 'Doe', '1985-06-15', 'XYZ987654', '123 Main St', '555-1234', 'john.doe@email.com');

-- 2.2. Register a new vehicle to a driver
INSERT INTO "vehicles" ("owner_id", "license_plate", "type", "make", "model", "year")
VALUES (1, 'ABC-123', 'Sedan', 'Toyota', 'Camry', 2020);

-- 2.3. Issue a speeding ticket to a driver
INSERT INTO "tickets" ("violation_id", "vehicle_id", "driver_id", "ticket_timestamp", "latitude", "longitude", "fine_amount", "status", "issued_by", "officer_id", "note")
VALUES (2, 1, 1, CURRENT_TIMESTAMP, 40.7128, -74.0060, 150.00, 'Pending', 'Officer', 5, 'Speeding 15 kmph over limit');

-- ==============================
-- 3. UPDATE
-- ==============================

-- 3.1. Mark a ticket as Paid
UPDATE "tickets"
SET "status" = 'Paid'
WHERE "id" = 10;

-- 3.2. Extend the registration of a vehicle
UPDATE "vehicle_registrations"
SET "expiration_date" = DATE("expiration_date", '+1 year')
WHERE "vehicle_id" = 2;

-- 3.3. Change driver phone number
UPDATE "drivers"
SET "phone_number" = '555-9876'
WHERE "id" = 3;

-- ==============================
-- 4. DELETE
-- ==============================

-- 4.1. Remove old calibration logs
DELETE FROM "camera_calibration_log" WHERE "calibration_date" < DATE('now', '-2 years');

-- 4.2. Remove a wrongly issued ticket
DELETE FROM "tickets" WHERE "id" = 15 AND "status" = 'Pending';

-- 4.3. Delete a driver after license suspension
DELETE FROM "drivers" WHERE "id" = 7;
