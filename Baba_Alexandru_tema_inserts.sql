-- TEMA INSERTS SQL: Sample Data Loader for DIM_EMPLOYEE and more

-- Insert Employees
INSERT INTO TARGET_DIM_EMPLOYEE (EMPLOYEE_ID, FULL_NAME, EMAIL, ACTIVE, LEGACY_EMPLOYEE_ID)
VALUES (SEQ_EMPLOYEE.NEXTVAL, 'Alessandro Costa', 'alessandro.costa@endava.com', 'Y', 101);
INSERT INTO TARGET_DIM_EMPLOYEE (EMPLOYEE_ID, FULL_NAME, EMAIL, ACTIVE, LEGACY_EMPLOYEE_ID)
VALUES (SEQ_EMPLOYEE.NEXTVAL, 'Antonio Russo', 'antonio.russo@endava.com', 'Y', 102);
INSERT INTO TARGET_DIM_EMPLOYEE (EMPLOYEE_ID, FULL_NAME, EMAIL, ACTIVE, LEGACY_EMPLOYEE_ID)
VALUES (SEQ_EMPLOYEE.NEXTVAL, 'Francesco Greco', 'francesco.greco@endava.com', 'Y', 103);
INSERT INTO TARGET_DIM_EMPLOYEE (EMPLOYEE_ID, FULL_NAME, EMAIL, ACTIVE, LEGACY_EMPLOYEE_ID)
VALUES (SEQ_EMPLOYEE.NEXTVAL, 'Giorgio Rinaldi', 'giorgio.rinaldi@endava.com', 'Y', 104);
INSERT INTO TARGET_DIM_EMPLOYEE (EMPLOYEE_ID, FULL_NAME, EMAIL, ACTIVE, LEGACY_EMPLOYEE_ID)
VALUES (SEQ_EMPLOYEE.NEXTVAL, 'Giovanni Esposito', 'giovanni.esposito@endava.com', 'Y', 105);
INSERT INTO TARGET_DIM_EMPLOYEE (EMPLOYEE_ID, FULL_NAME, EMAIL, ACTIVE, LEGACY_EMPLOYEE_ID)
VALUES (SEQ_EMPLOYEE.NEXTVAL, 'Luca Romano', 'luca.romano@endava.com', 'Y', 106);
INSERT INTO TARGET_DIM_EMPLOYEE (EMPLOYEE_ID, FULL_NAME, EMAIL, ACTIVE, LEGACY_EMPLOYEE_ID)
VALUES (SEQ_EMPLOYEE.NEXTVAL, 'Marco Bianchi', 'marco.bianchi@endava.com', 'Y', 107);
INSERT INTO TARGET_DIM_EMPLOYEE (EMPLOYEE_ID, FULL_NAME, EMAIL, ACTIVE, LEGACY_EMPLOYEE_ID)
VALUES (SEQ_EMPLOYEE.NEXTVAL, 'Matteo Conti', 'matteo.conti@endava.com', 'Y', 108);
INSERT INTO TARGET_DIM_EMPLOYEE (EMPLOYEE_ID, FULL_NAME, EMAIL, ACTIVE, LEGACY_EMPLOYEE_ID)
VALUES (SEQ_EMPLOYEE.NEXTVAL, 'Nicola Moretti', 'nicola.moretti@endava.com', 'Y', 109);
INSERT INTO TARGET_DIM_EMPLOYEE (EMPLOYEE_ID, FULL_NAME, EMAIL, ACTIVE, LEGACY_EMPLOYEE_ID)
VALUES (SEQ_EMPLOYEE.NEXTVAL, 'Stefano De Luca', 'stefano.de@endava.com', 'Y', 110);

COMMIT;

-- Verify
SELECT * FROM TARGET_DIM_EMPLOYEE;

-- Preview staging data (after loading external files)
SELECT * FROM SOURCE_ACTIVITY_TEMP;
SELECT * FROM SOURCE_TRAINING_TEMP;

-- Insert aBsence types
INSERT INTO TARGET_DIM_ABSENCE_TYPE (ABSENCE_TYPE_ID, TYPE_NAME) VALUES (SEQ_ABSENCE_TYPE.NEXTVAL, 'Annual Leave');
INSERT INTO TARGET_DIM_ABSENCE_TYPE (ABSENCE_TYPE_ID, TYPE_NAME) VALUES (SEQ_ABSENCE_TYPE.NEXTVAL, 'Medical Leave');
INSERT INTO TARGET_DIM_ABSENCE_TYPE (ABSENCE_TYPE_ID, TYPE_NAME) VALUES (SEQ_ABSENCE_TYPE.NEXTVAL, 'Personal');
INSERT INTO TARGET_DIM_ABSENCE_TYPE (ABSENCE_TYPE_ID, TYPE_NAME) VALUES (SEQ_ABSENCE_TYPE.NEXTVAL, 'Exam');

-- Verify
select * from TARGET_dim_absence_type;

-- Insert cheese-inspired projects
INSERT INTO TARGET_DIM_PROJECT (PROJECT_ID, PROJECT_NAME, CLIENT_NAME, BILLABLE, LEGACY_PROJECT_ID)
VALUES (SEQ_PROJECT.NEXTVAL, 'Brillat-Savarin', 'Fromagerie Royale', 'Y', 101);
INSERT INTO TARGET_DIM_PROJECT (PROJECT_ID, PROJECT_NAME, CLIENT_NAME, BILLABLE, LEGACY_PROJECT_ID)
VALUES (SEQ_PROJECT.NEXTVAL, 'Caciocavallo d’Oro', 'Casa di Lusso', 'Y', 102);
INSERT INTO TARGET_DIM_PROJECT (PROJECT_ID, PROJECT_NAME, CLIENT_NAME, BILLABLE, LEGACY_PROJECT_ID)
VALUES (SEQ_PROJECT.NEXTVAL, 'Bleu de Billionaire', 'Société Prestige', 'N', 103);
COMMIT;

-- Verify
select * from TARGET_dim_project;

-- Populate DIM_DATE for June 2025
DECLARE
  v_date DATE := DATE '2025-06-01';
BEGIN
  FOR i IN 1..30 LOOP
    INSERT INTO TARGET_DIM_DATE (
      DATE_ID, CALENDAR_DATE, YEAR, MONTH, DAY, WEEKDAY_NAME, IS_WEEKEND, LEGACY_DATE
    )
    VALUES (
      SEQ_DATE.NEXTVAL,
      v_date,
      EXTRACT(YEAR FROM v_date),
      EXTRACT(MONTH FROM v_date),
      EXTRACT(DAY FROM v_date),
      TO_CHAR(v_date, 'Day'),
      CASE 
        WHEN TO_CHAR(v_date, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH') IN ('SAT', 'SUN') THEN 'Y'
        ELSE 'N'
      END,
      v_date
    );
    v_date := v_date + 1;
  END LOOP;
  COMMIT;
END;
/

-- Verify
select * from TARGET_dim_date;

-- Project assignments for each worker
DECLARE
    CURSOR c_assignments IS
        SELECT 'alessandro.costa@endava.com' AS email, 'Brillat-Savarin' AS project_name FROM DUAL UNION ALL
        SELECT 'antonio.russo@endava.com', 'Caciocavallo d’Oro' FROM DUAL UNION ALL
        SELECT 'francesco.greco@endava.com', 'Bleu de Billionaire' FROM DUAL UNION ALL
        SELECT 'giorgio.rinaldi@endava.com', 'Brillat-Savarin' FROM DUAL UNION ALL
        SELECT 'giovanni.esposito@endava.com', 'Brillat-Savarin' FROM DUAL UNION ALL
        SELECT 'luca.romano@endava.com', 'Bleu de Billionaire' FROM DUAL UNION ALL
        SELECT 'marco.bianchi@endava.com', 'Brillat-Savarin' FROM DUAL UNION ALL
        SELECT 'matteo.conti@endava.com', 'Brillat-Savarin' FROM DUAL UNION ALL
        SELECT 'nicola.moretti@endava.com', 'Caciocavallo d’Oro' FROM DUAL UNION ALL
        SELECT 'stefano.de@endava.com', 'Brillat-Savarin' FROM DUAL;

BEGIN
    FOR rec IN c_assignments LOOP
        FOR rec_date IN (
            SELECT DATE_ID, CALENDAR_DATE 
            FROM TARGET_DIM_DATE 
            WHERE MONTH = 6 AND YEAR = 2025 AND IS_WEEKEND='N' -- we don't work in weekends
        ) LOOP
            INSERT INTO TARGET_FACT_EMPLOYEE_ACTIVITY (
                FACT_ID, EMPLOYEE_ID, DATE_ID, ACTIVITY_TYPE, PROJECT_ID, DURATION_HOURS,
                START_TIME, END_TIME, STATUS, NOTES, SOURCE_ENTRY_ID
            )
            SELECT
                SEQ_FACT_ACTIVITY.NEXTVAL,
                e.EMPLOYEE_ID,
                rec_date.DATE_ID,
                'Work',
                p.PROJECT_ID,
                8,
                TO_TIMESTAMP(rec_date.CALENDAR_DATE || ' 09:00:00', 'YYYY-MM-DD HH24:MI:SS'),
                TO_TIMESTAMP(rec_date.CALENDAR_DATE || ' 17:00:00', 'YYYY-MM-DD HH24:MI:SS'),
                'Approved',
                NULL,
                NULL
            FROM TARGET_DIM_EMPLOYEE e
            JOIN TARGET_DIM_PROJECT p ON p.PROJECT_NAME = rec.project_name
            WHERE e.EMAIL = rec.email;
        END LOOP;
    END LOOP;
END;
/

-- verify
select * from TARGET_fact_employee_activity;

-- Insert SOURCE_TRAINING_TEMP into FACT_EMPLOYEE_ACTIVITY
INSERT INTO TARGET_FACT_EMPLOYEE_ACTIVITY (
    FACT_ID, EMPLOYEE_ID, DATE_ID, ACTIVITY_TYPE, PROJECT_ID, DURATION_HOURS,
    START_TIME, END_TIME, STATUS, NOTES, SOURCE_ENTRY_ID
)
SELECT
    SEQ_FACT_ACTIVITY.NEXTVAL,
    e.EMPLOYEE_ID,
    d.DATE_ID,
    t.ACTIVITY_TYPE,
    NULL,
    ROUND(
        EXTRACT(DAY FROM (t.END_TIME - t.START_TIME)) * 24 +
        EXTRACT(HOUR FROM (t.END_TIME - t.START_TIME)) +
        EXTRACT(MINUTE FROM (t.END_TIME - t.START_TIME)) / 60 +
        EXTRACT(SECOND FROM (t.END_TIME - t.START_TIME)) / 3600,
        2
    ),
    t.START_TIME,
    t.END_TIME,
    'Approved',
    NULL,
    NULL
FROM SOURCE_TRAINING_TEMP t
JOIN TARGET_DIM_EMPLOYEE e ON t.EMAIL = e.EMAIL
JOIN TARGET_DIM_DATE d ON d.CALENDAR_DATE = t.ACTIVITY_DATE
--  Filter out employees who are on annual or medical leave that day
WHERE NOT EXISTS (
    SELECT 1
    FROM TARGET_FACT_EMPLOYEE_ACTIVITY f
    WHERE f.EMPLOYEE_ID = e.EMPLOYEE_ID
      AND f.DATE_ID = d.DATE_ID
      AND f.ACTIVITY_TYPE IN ('Annual Leave', 'Medical Leave')
);

--verify
select * from TARGET_fact_employee_activity;

-- Insert SOURCE_ACTIVITY_TEMP absences into FACT_EMPLOYEE_ACTIVITY
INSERT INTO TARGET_FACT_EMPLOYEE_ACTIVITY (
    FACT_ID, EMPLOYEE_ID, DATE_ID, ACTIVITY_TYPE, PROJECT_ID, DURATION_HOURS,
    START_TIME, END_TIME, STATUS, NOTES, SOURCE_ENTRY_ID
)
SELECT
    SEQ_FACT_ACTIVITY.NEXTVAL,
    (SELECT EMPLOYEE_ID FROM TARGET_DIM_EMPLOYEE e WHERE e.EMAIL = a.EMAIL),
    (SELECT DATE_ID FROM TARGET_DIM_DATE d WHERE d.CALENDAR_DATE = a.ACTIVITY_DATE),
    a.ACTIVITY_TYPE,
    NULL,
    ROUND(
        EXTRACT(DAY FROM (a.END_TIME - a.START_TIME)) * 24 +
        EXTRACT(HOUR FROM (a.END_TIME - a.START_TIME)) +
        EXTRACT(MINUTE FROM (a.END_TIME - a.START_TIME)) / 60 +
        EXTRACT(SECOND FROM (a.END_TIME - a.START_TIME)) / 3600,
        2
    ),
    a.START_TIME,
    a.END_TIME,
    'Approved',
    NULL,
    NULL
FROM SOURCE_ACTIVITY_TEMP a
WHERE a.ACTIVITY_TYPE IN ('Exam', 'Personal');

select * from TARGET_fact_employee_activity;

-- Cleanup Script: Remove Duplicate Absence Entries from TARGET_FACT_EMPLOYEE_ACTIVITY

-- This will retain only the first instance (lowest ROWID) for each employee/date/activity_type
-- and delete all others that are considered duplicates.

DELETE FROM TARGET_FACT_EMPLOYEE_ACTIVITY f
WHERE ROWID NOT IN (
    SELECT MIN(ROWID)
    FROM TARGET_FACT_EMPLOYEE_ACTIVITY
    WHERE ACTIVITY_TYPE IN ('Exam', 'Personal', 'Annual Leave', 'Medical Leave')
    GROUP BY EMPLOYEE_ID, DATE_ID, ACTIVITY_TYPE, START_TIME, END_TIME
)
AND f.ACTIVITY_TYPE IN ('Exam', 'Personal', 'Annual Leave', 'Medical Leave');

COMMIT;
-- verify
select * from TARGET_fact_employee_activity;


-- Populate TARGET_DIM_EMPLOYEE_HISTORY with District, Grade and Line Manager
DECLARE
  v_start_junior   DATE := DATE '2025-06-01';
  v_start_tech     DATE := DATE '2025-06-13';
  v_start_senior   DATE := DATE '2025-06-20';
  v_grade_final    VARCHAR2(50);
  v_employee_id    NUMBER;
  v_district       VARCHAR2(50);
BEGIN
  FOR emp IN (SELECT EMPLOYEE_ID FROM TARGET_DIM_EMPLOYEE ORDER BY EMPLOYEE_ID) LOOP
    v_employee_id := emp.EMPLOYEE_ID;

    v_grade_final := CASE
      WHEN DBMS_RANDOM.VALUE < 0.33 THEN 'Junior Technician'
      WHEN DBMS_RANDOM.VALUE < 0.66 THEN 'Technician'
      ELSE 'Senior Technician'
    END;

    v_district := CASE
      WHEN DBMS_RANDOM.VALUE < 0.33 THEN 'Iasi'
      WHEN DBMS_RANDOM.VALUE < 0.66 THEN 'Cluj'
      ELSE 'Brasov'
    END;

    INSERT INTO TARGET_DIM_EMPLOYEE_HISTORY (
        HISTORY_ID, EMPLOYEE_ID, START_DATE, END_DATE, GRADE,
        DISCIPLINE, LINE_MANAGER, DISTRICT_UNIT
    ) VALUES (
        SEQ_HISTORY.NEXTVAL, v_employee_id, v_start_junior,
        CASE WHEN v_grade_final = 'Junior Technician' THEN NULL ELSE v_start_tech END,
        'Junior Technician', 'Data', 'Bogdan Darabaneanu', v_district
    );

    IF v_grade_final IN ('Technician', 'Senior Technician') THEN
      INSERT INTO TARGET_DIM_EMPLOYEE_HISTORY (
          HISTORY_ID, EMPLOYEE_ID, START_DATE, END_DATE, GRADE,
          DISCIPLINE, LINE_MANAGER, DISTRICT_UNIT
      ) VALUES (
          SEQ_HISTORY.NEXTVAL, v_employee_id, v_start_tech,
          CASE WHEN v_grade_final = 'Technician' THEN NULL ELSE v_start_senior END,
          'Technician', 'Data', 'Bogdan Darabaneanu', v_district
      );
    END IF;

    IF v_grade_final = 'Senior Technician' THEN
      INSERT INTO TARGET_DIM_EMPLOYEE_HISTORY (
          HISTORY_ID, EMPLOYEE_ID, START_DATE, END_DATE, GRADE,
          DISCIPLINE, LINE_MANAGER, DISTRICT_UNIT
      ) VALUES (
          SEQ_HISTORY.NEXTVAL, v_employee_id, v_start_senior,
          NULL,
          'Senior Technician', 'Data', 'Bogdan Darabaneanu', v_district
      );
    END IF;
  END LOOP;
  COMMIT;
END;
/

--verify
select * from TARGET_dim_employee_history;





