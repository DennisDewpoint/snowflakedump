list @ZENAS_ATHLEISURE_DB.PRODUCTS.UNI_KLAUS_CLOTHING;

list @ZENAS_ATHLEISURE_DB.PRODUCTS.UNI_KLAUS_ZMD;

list @ZENAS_ATHLEISURE_DB.PRODUCTS.UNI_KLAUS_SNEAKERS;

select $1
from @uni_klaus_zmd/product_coordination_suggestions.txt; 

create or replace file format zmd_file_format_1
RECORD_DELIMITER = ';'
TRIM_SPACE = TRUE;

select $1
from @uni_klaus_zmd/product_coordination_suggestions.txt
(file_format => zmd_file_format_1);

create or replace file format zmd_file_format_2
FIELD_DELIMITER = '|'
RECORD_DELIMITER = ';'
TRIM_SPACE = TRUE;  

select $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11
from @uni_klaus_zmd/product_coordination_suggestions.txt
(file_format => zmd_file_format_2);

create file format zmd_file_format_3
FIELD_DELIMITER = '='
RECORD_DELIMITER = '^'; 

select $1, $2
from @uni_klaus_zmd/product_coordination_suggestions.txt
(file_format => zmd_file_format_3);

select $1 as sizes_available
from @uni_klaus_zmd/sweatsuit_sizes.txt
(file_format => zmd_file_format_1 );

select $1, $2, $3
from @uni_klaus_zmd/swt_product_line.txt
(file_format => zmd_file_format_2 );

create view zenas_athleisure_db.products.sweatsuit_sizes as 
select REPLACE($1, chr(13)||chr(10)) as sizes_available
from @uni_klaus_zmd/sweatsuit_sizes.txt
(file_format => zmd_file_format_1)
where sizes_available <> '';

select * from zenas_athleisure_db.products.sweatsuit_sizes;

create view zenas_athleisure_db.products.SWEATBAND_PRODUCT_LINE as 
select REPLACE($1, chr(13)||chr(10)) as PRODUCT_CODE, REPLACE($2, chr(13)||chr(10)) as HEADBAND_DESCRIPTION, REPLACE($3, chr(13)||chr(10)) as WRISTBAND_DESCRIPTION
from @uni_klaus_zmd/swt_product_line.txt
(file_format => zmd_file_format_2 );

SELECT * FROM zenas_athleisure_db.products.SWEATBAND_PRODUCT_LINE;

create view zenas_athleisure_db.products.SWEATBAND_COORDINATION as
select REPLACE($1, chr(13)||chr(10)) as PRODUCT_CODE, REPLACE($2, chr(13)||chr(10)) as HAS_MATCHING_SWEATSUIT
from @uni_klaus_zmd/product_coordination_suggestions.txt
(file_format => zmd_file_format_3);

select * from zenas_athleisure_db.products.SWEATBAND_COORDINATION;
