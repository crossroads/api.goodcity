CREATE OR REPLACE VIEW nested_paths AS
-- A list of boxes that are presently packed (necessasrily on a pallet)
WITH boxes_on_pallets 	AS (
SELECT 
	package_id 			AS id, 
	1 					AS storage_type_id, 
	null::integer 		AS package_id, 
	package_id 			AS box_id, 
	source_id 			AS pallet_id, 
	source_id 			AS outermost_id,
	2 					AS outermost_storage_type_id,
    1 					AS depth,
	sum(packages_inventories.quantity)		AS quantity
FROM
  packages_inventories
JOIN packages as p1
 ON package_id = p1.id
WHERE p1.storage_type_id = 1 AND action IN ('pack','unpack')

GROUP BY   package_id, source_id

HAVING sum(packages_inventories.quantity) <>0 --not been unpacked back to 0
ORDER BY box_id asc
),

-- Now finding the packages associated with boxes_on_pallets
-- This returns all items packed 2 deep (on hand or otherwise)
packages_boxed_on_pallets AS (
SELECT 
	packages_inventories.package_id AS id, 
	3 					AS storage_type_id, 
	packages_inventories.package_id, 
	boxes_on_pallets.box_id, 
	boxes_on_pallets.pallet_id, 
	boxes_on_pallets.pallet_id AS outermost_id,
	2 					AS outermost_storage_type_id,
    2 					AS depth,
	sum(packages_inventories.quantity)		AS quantity
from packages_inventories 
JOIN boxes_on_pallets -- only packages inside boxes_on_pallets please
 on boxes_on_pallets.box_id = packages_inventories.source_id  WHERE packages_inventories.action IN ('pack','unpack')

GROUP BY box_id, boxes_on_pallets.pallet_id, packages_inventories.package_id
HAVING sum(packages_inventories.quantity) <>0 --not been unpacked back to 0
ORDER BY box_id asc
),



-- A list of packages that are directly on a pallet (no intermediate box)
packages_on_pallets AS (
SELECT 
	package_id 			AS id, 
	3 					AS storage_type_id, 
	package_id, 
	NULL::integer 		AS box_id, 
	source_id 			AS pallet_id, 
	source_id AS outermost_id,
	2 AS outermost_storage_type_id,
    1 AS depth,
	sum(packages_inventories.quantity)		AS quantity
FROM
  packages_inventories
JOIN packages p1
 ON source_id = p1.id
JOIN packages p2 ON package_id = p2.id
WHERE p1.storage_type_id = 2 -- the source_id only includes type 2 (pallet)
AND p2.storage_type_id = 3 -- package_id only includes type 3 (package) 
                           -- because we only packages directly on pallets
AND action IN ('pack','unpack')
GROUP BY   package_id, source_id

HAVING sum(packages_inventories.quantity) <>0
ORDER BY pallet_id asc
),

-- A list of packages that in a box (where the box is not on a pallet)
-- Be sure to exclude boxes_on_pallets.box_id records as they ARE on a pallet
packages_in_boxes_only AS (
SELECT 
	package_id 			AS id, 
	3 					AS storage_type_id, 
	package_id, 
	source_id 			AS box_id, 
	NULL::integer 		AS pallet_id, 
	source_id 			AS outermost_id,
    1 AS outermost_storage_type_id,
    1 AS depth,
	sum(packages_inventories.quantity)		AS quantity
FROM
  packages_inventories
JOIN packages p1
 ON source_id = p1.id

WHERE p1.storage_type_id = 1 -- the source_id only includes type 1(box)
AND source_id NOT IN(select box_id from boxes_on_pallets) -- eliminate any box that is on a pallet
AND action IN ('pack','unpack')
GROUP BY   package_id, source_id

HAVING sum(packages_inventories.quantity) <>0
ORDER BY box_id asc
),

all_nested_paths AS(
        select * FROM packages_boxed_on_pallets
UNION   select * from boxes_on_pallets
UNION   select * from packages_on_pallets
UNION   select * from packages_in_boxes_only
),

-- TRYING TO GET ALL THE NON-NESTED STUFF


-- DIRECTLY LOCATED STUFF (i.e. not been sent/trashed etc.)

/* This does not overlap with packages_boxed_on_pallets, boxes_on_pallets, packages_on_pallets, packages_in_boxes_only
    because those records are all packed and therefore have no direct locations as these records do.
        In the case of a box, it cannot be both located in the warehouse and "packed" on a pallet (except for wierd "gain" actions)
        In the case of a package it can exists in both lists legitimately
        In the case of a pallet, it can only show on this list (on the other list it is an outer container only, never the "subject" of the row)
    
*/

on_hand AS(
select  DISTINCT package_id, packages.storage_type_id
from packages_inventories
JOIN packages on packages_inventories.package_id = packages.id
GROUP BY package_id, packages_inventories.location_id, packages.storage_type_id
HAVING sum(quantity) > 0
),

directly_on_hand AS 
(select id AS id, storage_type_id,
CASE WHEN storage_type_id = 3 THEN packages.id END package_id,     
CASE WHEN storage_type_id = 1 THEN packages.id END box_id,    
CASE WHEN storage_type_id = 2 THEN packages.id END pallet_id,
id as outermost_id,
packages.storage_type_id AS outermost_storage_type_id,
0 AS depth, 
null::integer AS quantity
FROM packages
WHERE id IN (select package_id from on_hand)
),



-- LIST DISPATCHED QUANTITIES (as 'dispatched')
directly_dispatched AS(
select DISTINCT package_id AS id, storage_type_id,
CASE WHEN storage_type_id = 3 THEN package_id END package_id,     
CASE WHEN storage_type_id = 1 THEN package_id END box_id,    
CASE WHEN storage_type_id = 2 THEN package_id END pallet_id,
package_id as outermost_id,
packages.storage_type_id AS outermost_storage_type_id,
0 AS depth, 
null::integer AS quantity
from packages_inventories
JOIN packages on packages_inventories.package_id = packages.id
WHERE source_type = 'OrdersPackage'
GROUP BY package_id, source_id, storage_type_id
HAVING sum(quantity) <> 0
ORDER BY storage_type_id asc
),


-- LIST PACKAGE TO ALL OTHER DESTINATIONS
directly_trash_process_recycle AS(
select DISTINCT package_id AS id, packages.storage_type_id,
CASE WHEN storage_type_id = 3 THEN package_id END package_id,     
CASE WHEN storage_type_id = 1 THEN package_id END box_id,    
CASE WHEN storage_type_id = 2 THEN package_id END pallet_id,
package_id as outermost_id,
packages.storage_type_id AS outermost_storage_type_id,
0 AS depth, 
null::integer AS quantity
from packages_inventories
JOIN packages on packages_inventories.package_id = packages.id
WHERE action IN ('trash', 'process', 'recycle')
GROUP BY package_id, packages.storage_type_id
HAVING sum(quantity) != 0
),

directly_lost AS (
select  DISTINCT package_id, packages.storage_type_id,
CASE WHEN storage_type_id = 3 THEN package_id END package_id,     
CASE WHEN storage_type_id = 1 THEN package_id END box_id,    
CASE WHEN storage_type_id = 2 THEN package_id END pallet_id,
package_id as outermost_id,
packages.storage_type_id AS outermost_storage_type_id,
0 AS depth, 
null::integer AS quantity

from packages_inventories
JOIN packages on packages_inventories.package_id = packages.id
WHERE action IN ('gain','loss')
GROUP BY package_id, packages.storage_type_id
HAVING sum(quantity) < 0 -- we're only includeing "losses" because they are a "destination"
order by packages.storage_type_id ASC
),

all_direct_paths AS (
      select * from directly_on_hand
UNION select * from directly_dispatched
UNION select * from directly_trash_process_recycle
UNION select * from directly_lost
),

all_paths AS
(
SELECT distinct * from all_nested_paths
UNION 
select DISTINCT * from all_direct_paths
),

/* NOW LET'S BUILD A TABLE WITH EVERY POSSIBLE END DESTINATION FOR ALL OBJECTS
    We will then join to this to put "location" and quantity data on every object.
*/

all_outcomes AS (
select  package_id AS id, 'warehouse' AS location_type, location_id, sum(quantity) as qty
from packages_inventories
GROUP BY package_id, location_id
HAVING sum(quantity) != 0

-- LIST DISPATCHED QUANTITIES (as 'dispatched')
UNION
select package_id AS id, 'dispatched' AS location_type, NULL AS LOCATION_ID, ABS(sum(quantity)) as qty
from packages_inventories
WHERE source_type = 'OrdersPackage'
GROUP BY package_id
HAVING sum(quantity) <> 0

-- LIST OTHER PACKAGE DESTINATIONS
UNION
select  package_id AS id, action AS location_type, NULL AS location_id, ABS(sum(quantity)) as qty
from packages_inventories
WHERE action IN ('trash', 'process', 'recycle')
GROUP BY package_id, location_type
HAVING sum(quantity) != 0

UNION
select  package_id AS id, 'loss' AS location_type, NULL AS location_id, ABS(sum(quantity)) as qty
from packages_inventories
WHERE action IN ('gain','loss')
GROUP BY package_id, location_type
HAVING sum(quantity) < 0 -- we're only includeing "losses" because they are a "destination"
)

select 
	all_paths.id,
    all_paths.storage_type_id,
    all_paths.package_id,
    all_paths.box_id,
    all_paths.pallet_id,
    all_paths.outermost_id,
    all_paths.outermost_storage_type_id,
    all_paths.depth,
    all_outcomes.location_type,
    all_outcomes.location_id,
    coalesce(ABS(all_paths.quantity), all_outcomes.qty) as qty
from all_paths LEFT join all_outcomes on all_paths.outermost_id = all_outcomes.id;
