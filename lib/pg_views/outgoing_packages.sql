CREATE VIEW outgoing_packages AS
(
   SELECT p.inventory_number,
    pt.code,
    p.notes,
    dc.name_en AS condition,
    p.grade,
    op.quantity,
    p.created_at AS created,
    p.length,
    p.width,
    p.height,
    round(((COALESCE(((p.length * p.width) * p.height), 0))::numeric / 1000000.0), 2) AS cbm,
    array_to_string(array_agg(((l.building)::text || (l.area)::text)), ','::text, ''::text) AS locations,
    o.code AS designation,
    op.created_at,
    op.sent_on
   FROM ((((((packages p
     JOIN orders_packages op ON ((op.package_id = p.id)))
     JOIN packages_locations pl ON ((pl.package_id = p.id)))
     JOIN locations l ON ((pl.location_id = l.id)))
     JOIN package_types pt ON ((p.package_type_id = pt.id)))
     JOIN donor_conditions dc ON ((p.donor_condition_id = dc.id)))
     LEFT JOIN orders o ON ((p.order_id = o.id)))
  GROUP BY p.inventory_number, pt.code, p.notes, p.grade, op.quantity, p.created_at, p.length, p.width, p.height, o.code, op.created_at, op.sent_on, dc.name_en
);

GRANT SELECT ON outgoing_packages to reporter;