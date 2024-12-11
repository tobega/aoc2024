DROP TABLE IF EXISTS trails;
DROP TABLE IF EXISTS positions;
DROP TABLE IF EXISTS lines;

CREATE TABLE IF NOT EXISTS lines (
  i SERIAL PRIMARY KEY,
  line TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS positions (
  i INT NOT NULL,
  j INT NOT NULL,
  height INT NOT NULL,
  PRIMARY KEY (i, j),
  FOREIGN KEY (i) REFERENCES lines(i)
);

CREATE TABLE IF NOT EXISTS trails (
  i_start INT NOT NULL,
  j_start INT NOT NULL,
  i_end INT NOT NULL,
  j_end INT NOT NULL,
  trail INT[][] NOT NULL,
  FOREIGN KEY (i_start, j_start) REFERENCES positions(i, j),
  FOREIGN KEY (i_end, j_end) REFERENCES positions(i, j)
);

\COPY lines (line) FROM 'input.txt';

INSERT INTO positions (i, j, height)
  SELECT i, j, ch::int as height
  FROM lines
  ,unnest(string_to_array(line, NULL)) WITH ORDINALITY AS c(ch, j)
;

WITH RECURSIVE trail_find(i_start, j_start, i_end, j_end, height, trail) AS (
  SELECT i, j, i, j, height, ARRAY[ARRAY[i, j]]
  FROM positions
  WHERE height = 0
  UNION
  SELECT t.i_start, t.j_start, p.i, p.j, p.height, array_cat(t.trail, ARRAY[p.i, p.j])
  FROM trail_find t, positions p
  WHERE p.height = t.height + 1
  AND ((p.i = t.i_end AND p.j = t.j_end + 1)
    OR (p.i = t.i_end AND p.j = t.j_end - 1)
    OR (p.i = t.i_end + 1 AND p.j = t.j_end)
    OR (p.i = t.i_end - 1 AND p.j = t.j_end))
)
INSERT INTO trails (i_start, j_start, i_end, j_end, trail)
SELECT DISTINCT i_start, j_start, i_end, j_end, trail
FROM trail_find
WHERE height = 9
;

SELECT COUNT(*) score FROM (SELECT DISTINCT i_start, j_start, i_end, j_end FROM trails) AS t;

SELECT COUNT(*) rating FROM trails;
