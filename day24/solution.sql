DROP TABLE IF EXISTS input;
CREATE TABLE input (
    line_no serial,
    line text
);

\COPY input (line) FROM 'input.txt';

DROP TABLE IF EXISTS initial_states;
CREATE TABLE initial_states (
    name text,
    state boolean
);

INSERT INTO initial_states (name, state)
SELECT g[1], g[2]::boolean
FROM
(SELECT regexp_match(line, '([^:]+):\s(\d)')::text[] as g
FROM input
WHERE line_no < (SELECT line_no FROM input WHERE line = '')
);

DROP TYPE IF EXISTS operation;
CREATE TYPE operation AS ENUM ('AND', 'OR', 'XOR');

DROP TABLE IF EXISTS gates;
CREATE TABLE gates (
    lval text,
    op operation,
    rval text,
    target text
);

INSERT INTO gates (lval, op, rval, target)
SELECT g[1], g[2]::operation, g[3], g[4]
FROM
(SELECT regexp_match(line, '(\S+)\s(\S+)\s(\S+) -> (\S+)')::text[] as g
FROM input
WHERE line_no > (SELECT line_no FROM input WHERE line = '')
);

-- part 1
WITH RECURSIVE states AS (
    SELECT name, state from initial_states
  UNION ALL
    (WITH known as (SELECT DISTINCT * FROM states),
      unknown AS (
        SELECT target
        FROM gates
        LEFT JOIN known ON gates.target = known.name
        WHERE known.state IS NULL
      )
    SELECT gates.target AS name,
      CASE WHEN op = 'AND' THEN l.state AND r.state
        WHEN op = 'OR' THEN l.state OR r.state
        ELSE l.state <> r.state
      END AS state
    FROM gates
    JOIN known AS l ON gates.lval = l.name
    JOIN known AS r ON gates.rval = r.name
    JOIN unknown u ON gates.target = u.target
    UNION SELECT DISTINCT name, state FROM known JOIN unknown ON true
  )
)
SELECT (string_agg(CASE WHEN state THEN '1' ELSE '0' END, '' ORDER BY name DESC)::"bit")::bigint
FROM (
SELECT DISTINCT * FROM states
WHERE name LIKE 'z%'
);
