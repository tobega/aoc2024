DROP TABLE IF EXISTS input;
CREATE TABLE input (
    line_no serial,
    line text
);

\COPY input (line) FROM 'input.txt';

DROP TABLE IF EXISTS initial_states;

DROP TYPE IF EXISTS operation CASCADE;
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

-- part 2
DROP TABLE IF EXISTS ideal;
CREATE TABLE ideal AS
WITH RECURSIVE deps(level, derivation, result) AS (
  SELECT * FROM (VALUES
    (0, '(x00 XOR y00)', 'z00'),
    (0, '(x00 AND y00)', 'f00')
  )
  UNION (
    WITH carry AS (SELECT level + 1 as level, derivation, result from deps WHERE result LIKE 'f%' AND level < 44)
    , preliminary AS (
      SELECT
        (SELECT level FROM carry),
        '(x' || trim(to_char((SELECT level FROM carry), '00')) || ' XOR y' || trim(to_char((SELECT level FROM carry), '00')) || ')' as derivation,
        'p' || trim(to_char((SELECT level FROM carry), '00')) as result
    )
    , direct_carry AS (
      SELECT
        (SELECT level FROM carry),
        '(x' || trim(to_char((SELECT level FROM carry), '00')) || ' AND y' || trim(to_char((SELECT level FROM carry), '00')) || ')' as derivation,
        'c' || trim(to_char((SELECT level FROM carry), '00')) as result
    )
    , rollover AS (
      SELECT
        (SELECT level FROM carry),
        '(' || (SELECT derivation FROM carry) || ' AND ' || (SELECT derivation FROM preliminary) || ')' as derivation,
        'r' || trim(to_char((SELECT level FROM carry), '00')) as result
    )
    SELECT
      (SELECT level FROM carry),
      '(' || (SELECT derivation FROM carry) || ' XOR ' || (SELECT derivation FROM preliminary) || ')' as derivation,
      'z' || trim(to_char((SELECT level FROM carry), '00')) as result
    UNION
    SELECT
      (SELECT level FROM carry),
      '(' || (SELECT derivation FROM rollover) || ' OR ' || (SELECT derivation FROM direct_carry) || ')' as derivation,
      'f' || trim(to_char((SELECT level FROM carry), '00')) as result
    UNION SELECT * FROM preliminary
    UNION SELECT * FROM direct_carry
    UNION SELECT * FROM rollover
  )
)
SELECT * FROM deps WHERE level IS NOT NULL -- I don't know where the null level comes from
;

DROP TABLE IF EXISTS derivations;
CREATE TABLE derivations AS
WITH RECURSIVE deps AS (
  SELECT
    '(x' || substring(lval FROM 2) || ' ' || op || ' y' || substring(lval FROM 2) ||')' as derivation,
    target
  FROM gates
  WHERE lval LIKE 'x%' OR rval LIKE 'x%'
  UNION ALL
    (WITH known as (SELECT DISTINCT * FROM deps),
      unknown AS (
        SELECT gates.target
        FROM gates
        LEFT JOIN known ON gates.target = known.target
        WHERE known.target IS NULL
      )
    SELECT
      '(' || CASE WHEN l.derivation < r.derivation THEN l.derivation ELSE r.derivation END || ' ' || op || ' ' || CASE WHEN l.derivation < r.derivation THEN r.derivation ELSE l.derivation END || ')' as derivation,
      gates.target
    FROM gates
    JOIN known AS l ON gates.lval = l.target
    JOIN known AS r ON gates.rval = r.target
    JOIN unknown u ON gates.target = u.target
    UNION SELECT DISTINCT known.derivation, known.target FROM known JOIN unknown ON true
  )
)
SELECT DISTINCT * FROM deps;

-- did not find a mechanical way, but manual analysis of the above gave the correct answer
