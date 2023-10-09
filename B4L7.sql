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

--Create a view that will have similar columns to DENVER_AREA_TRAILS 
--Even though this data started out as Parquet, and we're joining it with geoJSON data
--So let's make it look like geoJSON instead.
create view DENVER_AREA_TRAILS_2 as
select 
trail_name as feature_name
,'{"coordinates":['||listagg('['||lng||','||lat||']',',')||'],"type":"LineString"}' as geometry
,st_length(to_geography(geometry)) as trail_length
from cherry_creek_trail
group by trail_name;

select * from denver_area_trails_2;

--Create a view that will have similar columns to DENVER_AREA_TRAILS 
select feature_name, geometry, trail_length
from DENVER_AREA_TRAILS
union all
select feature_name, geometry, trail_length
from DENVER_AREA_TRAILS_2;

--Add more GeoSpatial Calculations to get more GeoSpecial Information! 
select feature_name
, to_geography(geometry) as my_linestring
, st_xmin(my_linestring) as min_eastwest
, st_xmax(my_linestring) as max_eastwest
, st_ymin(my_linestring) as min_northsouth
, st_ymax(my_linestring) as max_northsouth
, trail_length
from DENVER_AREA_TRAILS
union all
select feature_name
, to_geography(geometry) as my_linestring
, st_xmin(my_linestring) as min_eastwest
, st_xmax(my_linestring) as max_eastwest
, st_ymin(my_linestring) as min_northsouth
, st_ymax(my_linestring) as max_northsouth
, trail_length
from DENVER_AREA_TRAILS_2;

create view TRAILS_AND_BOUNDARIES as
select feature_name
, to_geography(geometry) as my_linestring
, st_xmin(my_linestring) as min_eastwest
, st_xmax(my_linestring) as max_eastwest
, st_ymin(my_linestring) as min_northsouth
, st_ymax(my_linestring) as max_northsouth
, trail_length
from DENVER_AREA_TRAILS
union all
select feature_name
, to_geography(geometry) as my_linestring
, st_xmin(my_linestring) as min_eastwest
, st_xmax(my_linestring) as max_eastwest
, st_ymin(my_linestring) as min_northsouth
, st_ymax(my_linestring) as max_northsouth
, trail_length
from DENVER_AREA_TRAILS_2;

select * from trails_and_boundaries;

select min(min_eastwest) as western_edge
,min(min_northsouth) as southern_edge
,max(max_eastwest) as eastern_edge
,max(max_northsouth) as northern_edge
from trails_and_boundaries;

select 'POLYGON(('||
    MIN(MIN_EASTWEST)||' '||MAX(MAX_NORTHSOUTH)||','||
    MAX(MAX_EASTWEST)||' '||MAX(MAX_NORTHSOUTH)||','||
    MAX(MAX_EASTWEST)||' '||MIN(MIN_NORTHSOUTH)||','||
    MIN(MIN_EASTWEST)||' '||MIN(MIN_NORTHSOUTH)||'))' AS MY_POLYGON
    FROM TRAILS_AND_BOUNDARIES;
