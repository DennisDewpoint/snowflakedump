list @TRAILS_GEOJSON;
list @TRAILS_PARQUET;

select $1
from @trails_geojson (file_format => ff_json);

select $1
from @trails_parquet (file_format => ff_parquet);
