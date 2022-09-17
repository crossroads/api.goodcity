-- View: outgoing_packages
-- DROP VIEW outgoing_packages;

CREATE OR REPLACE VIEW outgoing_packages AS
SELECT p.inventory_number,
    pt.code,
    pt.name_en AS code_description,
    NULL::unknown AS department,
    p.notes AS description,
    p.pieces,
    con.name_en AS condition,
    p.grade,
    p.received_quantity,
    p.notes AS comments,
    p.created_at AS created,
    p.length,
    p.width,
    p.height,
    NULL::unknown AS cbm,
    p.weight
   FROM ((packages p
     JOIN package_types pt ON ((p.package_type_id = pt.id)))
     LEFT JOIN donor_conditions con ON ((con.id = p.donor_condition_id)));

-- ALTER TABLE outgoing_packages OWNER TO goodcity_server;
-- GRANT ALL ON TABLE outgoing_packages TO goodcity_server;
-- GRANT SELECT ON TABLE outgoing_packages TO reporter;
-- GRANT SELECT ON TABLE outgoing_packages TO backup;
