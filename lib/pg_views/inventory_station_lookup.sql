CREATE OR REPLACE VIEW inventory_station_lookup AS

  SELECT p.inventory_number,
    pt.code,
    p.notes AS description,
    pt.name_en AS package_description,
    NULL AS shipping_number,
    p.pieces,
    con.name_en AS condition,
    p.available_quantity AS quantity,
    p.length,
    p.width,
    p.height,
    p.weight,
    p.notes AS comments,
    NULL AS designation,
    NULL AS sent_on,
    array_to_string(array_agg(((l.building)::text || (l.area)::text)), ', '::text, ''::text) AS locations,
    NULL AS designation_state,
    p.available_quantity,
    0 AS designated_quantity
  FROM packages p
    LEFT JOIN package_types pt ON p.package_type_id = pt.id
    LEFT JOIN donor_conditions con ON con.id = p.donor_condition_id
    LEFT JOIN packages_locations pl ON pl.package_id = p.id
    LEFT JOIN locations l ON pl.location_id = l.id
  WHERE p.available_quantity > 0
  GROUP BY p.inventory_number, pt.code, p.notes, pt.name_en, p.pieces, con.name_en, p.available_quantity, p.length, p.width, p.height, p.weight, p.notes
      
  UNION
  
  SELECT p.inventory_number,
    pt.code,
    p.notes AS description,
    pt.name_en AS package_description,
    NULL AS shipping_number,
    p.pieces,
    con.name_en AS condition,
    op.quantity AS quantity,
    p.length,
    p.width,
    p.height,
    p.weight,
    p.notes AS comments,
    o.code AS designation,
    op.sent_on AS sent_on,
    array_to_string(array_agg(((l.building)::text || (l.area)::text)), ', '::text, ''::text) AS locations,
    op.state AS designation_state,
    p.available_quantity,
    op.quantity AS designated_quantity
  FROM packages p
    LEFT JOIN package_types pt ON p.package_type_id = pt.id
    LEFT JOIN donor_conditions con ON con.id = p.donor_condition_id
    LEFT JOIN packages_locations pl ON pl.package_id = p.id
    LEFT JOIN locations l ON pl.location_id = l.id
    LEFT JOIN orders_packages op ON op.package_id = p.id
    LEFT JOIN orders o ON op.order_id = o.id
  WHERE op.state != 'cancelled' AND op.quantity > 0
  GROUP BY p.inventory_number, pt.code, p.notes, pt.name_en, p.pieces, con.name_en, op.quantity, op.quantity, p.available_quantity, p.length, p.width, p.height, p.weight, p.notes, o.code, op.sent_on, op.state
;
-- ALTER TABLE inventory_station_lookup OWNER TO reporter;

SELECT * FROM packages_and_designations
WHERE inventory_number = '000100' AND ((designation IS NULL) OR (designation = 'GC-00011'))
order by designation
limit 1



-- ALTER TABLE inventory_station_lookup OWNER TO reporter;

SELECT * FROM packages_and_designations
WHERE inventory_number = '000100'
    AND (designation IS NULL OR designation = 'S12345')
    AND (available_quantity > 0 OR designated_quantity > 0)
