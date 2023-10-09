--Remember this code? 
select 
'LINESTRING('||
listagg(coord_pair, ',') 
within group (order by point_id)
||')' as my_linestring
,st_length(my_linestring) as length_of_trail --this line is new! but it won't work!
from cherry_creek_trail
group by trail_name;

select
'LINESTRING('||
listagg(coord_pair, ',')
within group (order by point_id)
||')' as my_linestring
,TO_GEOGRAPHY(my_linestring) as length_of_trail --this line is new! but it won't work!
from cherry_creek_trail
group by trail_name;

select
feature_name
,st_length(to_geography(geometry)) as trail_length
from denver_area_trails;

select get_ddl('view', 'DENVER_AREA_TRAILS');

create or replace view DENVER_AREA_TRAILS(
    FEATURE_NAME,
    FEATURE_COORDINATES,
    GEOMETRY,
    TRAIL_LENGTH,
    FEATURE_PROPERTIES,
    SPECS,
    WHOLE_OBJECT
) as
select
$1:features[0]:properties:Name::string as feature_name
,$1:features[0]:geometry:coordinates::string as feature_coordinates
,$1:features[0]:geometry::string as geometry
,st_length(to_geography(geometry)) as trail_length
,$1:features[0]:properties::string as feature_properties
,$1:crs:properties:name::string as specs
,$1 as whole_object from @trails_geojson (file_format => ff_json);

select * from DENVER_AREA_TRAILS;
