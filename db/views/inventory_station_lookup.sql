-- View: inventory_station_lookup
-- DROP VIEW inventory_station_lookup;

CREATE OR REPLACE VIEW inventory_station_lookup AS
SELECT p.inventory_number,
    pt.code,
    p.notes AS description,
    pt.name_en AS package_description,
    NULL::text AS shipping_number,
    p.pieces,
    con.name_en AS condition,
    p.available_quantity AS quantity,
    p.length,
    p.width,
    p.height,
    p.weight,
    p.notes AS comments,
    NULL::character varying AS designation,
    NULL::timestamp with time zone AS sent_on,
    array_to_string(array_agg(((l.building)::text || (l.area)::text)), ', '::text, ''::text) AS locations,
    NULL::character varying AS designation_state,
    p.available_quantity,
    0 AS designated_quantity,
    p.value_hk_dollar,
    pt.customs_value_usd
   FROM ((((packages p
     LEFT JOIN package_types pt ON ((p.package_type_id = pt.id)))
     LEFT JOIN donor_conditions con ON ((con.id = p.donor_condition_id)))
     LEFT JOIN packages_locations pl ON ((pl.package_id = p.id)))
     LEFT JOIN locations l ON ((pl.location_id = l.id)))
  WHERE (p.available_quantity > 0)
  GROUP BY p.inventory_number, pt.code, p.notes, pt.name_en, p.pieces, con.name_en, p.available_quantity, p.length, p.width, p.height, p.weight, p.value_hk_dollar, pt.customs_value_usd
UNION
 SELECT p.inventory_number,
    pt.code,
    p.notes AS description,
    pt.name_en AS package_description,
    NULL::text AS shipping_number,
    p.pieces,
    con.name_en AS condition,
    op.quantity,
    p.length,
    p.width,
    p.height,
    p.weight,
    p.notes AS comments,
    o.code AS designation,
    op.sent_on,
    array_to_string(array_agg(((l.building)::text || (l.area)::text)), ', '::text, ''::text) AS locations,
    op.state AS designation_state,
    p.available_quantity,
    op.quantity AS designated_quantity,
    p.value_hk_dollar,
    pt.customs_value_usd
   FROM ((((((packages p
     LEFT JOIN package_types pt ON ((p.package_type_id = pt.id)))
     LEFT JOIN donor_conditions con ON ((con.id = p.donor_condition_id)))
     LEFT JOIN packages_locations pl ON ((pl.package_id = p.id)))
     LEFT JOIN locations l ON ((pl.location_id = l.id)))
     LEFT JOIN orders_packages op ON ((op.package_id = p.id)))
     LEFT JOIN orders o ON ((op.order_id = o.id)))
  WHERE (((op.state)::text <> 'cancelled'::text) AND (op.quantity > 0))
  GROUP BY p.inventory_number, pt.code, p.notes, pt.name_en, p.pieces, con.name_en, op.quantity, p.available_quantity, p.length, p.width, p.height, p.weight, o.code, op.sent_on, op.state, p.value_hk_dollar, pt.customs_value_usd;

-- ALTER TABLE inventory_station_lookup OWNER TO goodcity_server;
-- GRANT ALL ON TABLE inventory_station_lookup TO goodcity_server;
-- GRANT SELECT ON TABLE inventory_station_lookup TO reporter;
-- GRANT SELECT ON TABLE inventory_station_lookup TO backup;
