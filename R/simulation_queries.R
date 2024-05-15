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
  100 * (sum((nps >= 9)::int) - sum((nps <= 6)::int)) / count(nps) as medic_nps,
  sum((nps >= 9)::int) AS count_promoters,
  sum((nps <= 6)::int) AS count_detractors,
  count(nps) AS count_nps
  FROM
  search.visits
  WHERE
  nps != -1
  GROUP BY
  medic_id
),

count_tag_match AS (
  SELECT
  count(*) as count_tags,
  array_agg(coalesce(t.borg_name, t.parc_name)) as tag_list,
  mt.medic_id
  FROM
  search.medic_tags AS mt
  INNER JOIN 
    search.tags AS t ON mt.tag_id = t.id
  WHERE
  mt.tag_id IN ({borg_tag_ids})
  GROUP BY
  medic_id
),

workplaces_wo_cg AS (
  SELECT * FROM search.workplaces
  WHERE type != 'clinic_group'
)


SELECT 
DISTINCT ON (m.id)
  m.id as medic_id,
  m.title,
  m.first_name,
  m.last_name,
  ma.employment_state,
  array_to_string(array[p2.name, p1.name, w.name], ' || ') as workplace_name,
  w.website_url as workplace_url,
  w.state as workplace_state,
  w.type as workplace_type,
  w.street_address || '\n' || w.zip_code || ' ' || w.city as workplace_address,
  mn.medic_nps,
  mn.count_nps,
  mn.count_promoters,
  mn.count_detractors,
  ctg.count_tags,
  ctg.tag_list,
  w.distance_in_km
FROM
workplace_distances AS w
INNER JOIN
search.medic_activities AS ma
ON
w.id = ma.workplace_id
LEFT JOIN 
workplaces_wo_cg AS p1
ON
w.parent_id = p1.id
LEFT JOIN
workplaces_wo_cg AS p2
ON 
p1.parent_id = p2.id
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
w.state = 'open'
AND ma.state = 'current'
AND m.state IN ('active', 'reduced_activity')
AND w.type IN ({workplace_types})
ORDER BY
medic_id, distance_in_km ASC"