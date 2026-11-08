-- ============================================================
-- Helpdesk Ticketing — Demo Schema
-- Run in APEX: SQL Workshop > SQL Commands
-- ============================================================

BEGIN EXECUTE IMMEDIATE 'DROP TABLE tickets CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE agents CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE agents (
  agent_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  agent_name  VARCHAR2(120) NOT NULL
);

CREATE TABLE tickets (
  ticket_id       NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  subject         VARCHAR2(200) NOT NULL,
  requester_name  VARCHAR2(120) NOT NULL,
  priority        VARCHAR2(10) DEFAULT 'MEDIUM'
                    CHECK (priority IN ('LOW','MEDIUM','URGENT')),
  status          VARCHAR2(20) DEFAULT 'NEW'
                    CHECK (status IN ('NEW','IN_PROGRESS','WAITING','RESOLVED')),
  agent_id        NUMBER REFERENCES agents(agent_id),
  created_date    DATE DEFAULT SYSDATE,
  resolved_date   DATE,
  description     VARCHAR2(1000)
);

INSERT INTO agents (agent_name) VALUES ('Devon Ashwood');
INSERT INTO agents (agent_name) VALUES ('Ana Souza');

INSERT INTO tickets (subject, requester_name, priority, status, agent_id, created_date, description)
  VALUES ('VPN drops every few minutes', 'Devon Ashwood', 'URGENT', 'NEW', NULL, SYSDATE-1,
          'Connection drops roughly every 10 minutes while on VPN, started this morning.');
INSERT INTO tickets (subject, requester_name, priority, status, agent_id, created_date, description)
  VALUES ('Conference room B projector wont pair', 'Ana Souza', 'MEDIUM', 'NEW', NULL, SYSDATE-1,
          'Bluetooth pairing fails consistently, tried restarting twice.');
INSERT INTO tickets (subject, requester_name, priority, status, agent_id, created_date, description)
  VALUES ('Printer on 3rd floor jamming daily', 'Marcus Bell', 'MEDIUM', 'IN_PROGRESS', 1, SYSDATE-3,
          'Paper jam roughly once a day, tray 2.');
INSERT INTO tickets (subject, requester_name, priority, status, agent_id, created_date, description)
  VALUES ('Warehouse scanner wont sync to WMS', 'Jordan Reyes', 'URGENT', 'IN_PROGRESS', 1, SYSDATE-2,
          'Scanner shows synced but items dont appear in WMS.');
INSERT INTO tickets (subject, requester_name, priority, status, agent_id, created_date, resolved_date, description)
  VALUES ('Reset password for shared inbox', 'Devon Ashwood', 'LOW', 'RESOLVED', 1, SYSDATE-6, SYSDATE-5,
          'Requested reset for support@ shared mailbox.');
INSERT INTO tickets (subject, requester_name, priority, status, agent_id, created_date, resolved_date, description)
  VALUES ('Replace faulty dock light in Bay 2', 'Marcus Bell', 'LOW', 'RESOLVED', 2, SYSDATE-8, SYSDATE-7,
          'Motion light not triggering, replaced fixture.');

COMMIT;

CREATE OR REPLACE VIEW v_tickets AS
SELECT t.ticket_id, t.subject, t.requester_name, t.priority, t.status,
       a.agent_name, t.created_date, t.resolved_date, t.description
FROM tickets t LEFT JOIN agents a ON a.agent_id = t.agent_id;
