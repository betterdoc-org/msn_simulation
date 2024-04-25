medic_simulation_query = "WITH workplace_distances AS (
  SELECT
  *,
  st_distance(st_transform(st_setsrid(st_makepoint( 
    {lng},
    {lat}
  ),
  4326),
  4326),
  w.location)
  / 1000 AS distance_in_km
  FROM
  search.workplaces AS w
  WHERE
  st_dwithin(st_transform(st_setsrid(st_makepoint(
    {lng},
    {lat}
  ),
  4326),
  4326)::geography,
  w.location,
  {km_radius} * 1000)
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
  mt.tag_id IN ({borg_tag_ids})
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
AND wd.type IN ({workplace_types})
ORDER BY
distance_in_km ASC"