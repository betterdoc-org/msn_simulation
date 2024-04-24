WITH workplace_distances AS (
  SELECT
    *,
    st_distance(st_transform(st_setsrid(st_makepoint(
      6.953101,
      50.935173
    ),
    4326),
    4326),
    w.location)
    / 1000 AS distance_in_km
  FROM
    search.workplaces AS w
  WHERE
    st_dwithin(st_transform(st_setsrid(st_makepoint(
      6.953101,
      50.935173
    ),
    4326),
    4326)::geography,
    w.location,
    80 * 1000)
),

avg_medic_nps AS (
  SELECT
    medic_id,
    avg(nps) AS avg_nps
  FROM
    search.visits
  WHERE
    nps != -1
  GROUP BY
    medic_id
),

count_tag_match AS (
  SELECT
    count(*),
    medic_id
  FROM
    search.medic_tags AS mt
  WHERE
    mt.tag_id IN (
      4240,
      6598,
      4033,
      6446,
      4241,
      6290,
      6287,
      4789,
      4034,
      5393,
      6286,
      5874,
      6291,
      4242,
      6284,
      4696,
      6289,
      1333,
      2415,
      5436,
      2855,
      4032,
      4545,
      4546,
      4547,
      4544,
      7277,
      6285,
      6445,
      4054,
      1062,
      1334,
      1086,
      1332,
      5940,
      731
    )
  GROUP BY
    medic_id
  ORDER BY
    count(*) DESC
)


SELECT *
FROM
  workplace_distances AS wd
INNER JOIN
  search.medic_activities AS ma
  ON
    wd.id = ma.workplace_id
INNER JOIN
  search.medics AS m
  ON
    ma.medic_id = m.id
LEFT JOIN avg_medic_nps AS mn
  ON
    m.id = mn.medic_id
INNER JOIN count_tag_match AS ctg
  ON
    m.id = ctg.medic_id
WHERE
  wd.state = 'open'
  AND ma.state = 'current'
  AND m.state IN ('active', 'reduced_activity')
  AND wd.type IN ('pratice', 'practice_group')
ORDER BY
  distance_in_km ASC
