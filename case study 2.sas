/****************************** CASE STUDY-2 ***************************************/

/**************************** Importing the files **************************************/
PROC IMPORT DATAFILE='/folders/myfolders/POS_Q1.csv' 
  out=POS_Q1 
  dbms=csv replace;
  guessingrows=5000;
run;

PROC IMPORT DATAFILE='/folders/myfolders/POS_Q2.csv' 
  out=POS_Q2 
  dbms=csv replace;
  guessingrows=5000;
run;

PROC IMPORT DATAFILE='/folders/myfolders/POS_Q3.csv' 
  out=POS_Q3 
  dbms=csv replace;
  guessingrows=5000;
run;

PROC IMPORT DATAFILE='/folders/myfolders/POS_Q4.csv' 
  out=POS_Q4 
  dbms=csv replace;
  guessingrows=5000;
run;

PROC IMPORT DATAFILE='/folders/myfolders/Laptops.csv' 
  out=Laptops 
  dbms=csv replace;
  guessingrows=5000;
run;

PROC IMPORT DATAFILE='/folders/myfolders/London_postal_codes.csv' 
  out=London_postal_codes 
  dbms=csv replace;
  guessingrows=5000;
run;
 
PROC IMPORT DATAFILE='/folders/myfolders/Store_locations.csv' 
  out=Store_Locations 
  dbms=csv replace;
  guessingrows=5000;
run;


/********************** Appending the datasets together for all quarters **************************/
proc sort data=POS_Q1 out=POS_Q1;
by Date;
run;
proc sort data=POS_Q2 out=POS_Q2;
by Date;
run;
proc sort data=POS_Q3 out=POS_Q3;
by Date;
run;
proc sort data=POS_Q4 out=POS_Q4;
by Date;
run;
data POS;
merge POS_Q1 POS_Q2 POS_Q3 POS_Q4 ;
by Date;
run;
/********************** Merging all the datasets and assigning new names to some variables**************/
data Store_Locations;
set Store_locations;
rename OS_X=Store_X OS_Y=Store_y;
run;

data London_postal_codes;
set London_postal_codes;
rename OS_X=Customer_X OS_Y=Customer_y;
run;

PROC SQL;
CREATE TABLE F AS
SELECT POS.*, LAPTOPS.* FROM POS LEFT JOIN LAPTOPS
ON POS.Configuration=LAPTOPS.configuration;
quit;

PROC SQL;
CREATE TABLE final AS
SELECT F.*, LONDON_POSTAL_CODES.* FROM F LEFT JOIN LONDON_POSTAL_CODES
ON F.Customer_Postcode=LONDON_POSTAL_CODES.Postcode;
quit;

PROC SQL;
CREATE TABLE final AS
SELECT final.*, Store_Locations.* FROM final LEFT JOIN Store_Locations
ON final.Store_Postcode=Store_Locations.Postcode;
quit;


data final;
set final;
drop postcode;
distance=sqrt(((Store_X-Customer_X)**2) + ((Store_Y-Customer_Y)**2));
run;



/********************** Deleting observations where the date variable is missing ***********************/
DATA POS;
SET POS;
IF date="." then delete;
run;


/****************** QUESTION 1 ******************/
ods html file='/folders/myfolders/q1.xls';
PROC SQL;
create table q1 as
select mean(retail_price) as Avg_price, 
month, configuration from final
group by configuration,month;
quit; 
ods html close;
/****************** QUESTION 2 *******************/
ods html file='/folders/myfolders/q1.xls';
PROC SQL;
create table q2 as
select  month, configuration, Store_postcode,mean(retail_price) as Avg_price from final
group by configuration,month,Store_postcode;
quit;
ods html close;

/****************** QUESTION 3 ********************/
proc sql;
create table q3 as
select   configuration, month, mean(retail_price) as avg,min(retail_price) as min, max(retail_price) as max,range(retail_price) as range, std(retail_price) as std from final
group by configuration,month;
quit;

ods html file='/folders/myfolders/q2.xls';
proc sql;
create table q3 as
select  configuration, mean(retail_price) as avg_price label='Average Price' from final
group by configuration;
quit;
ods html close;



/**************** QUESTION 4 ****************/
PROC SQL;
create table q4 as
select customer_postcode, 
mean(distance) as avg_dist,
count(date) as volume, 
sum(retail_price) as revenue
from final
group by customer_postcode;
quit;

data q4;
set q4;
if avg_dist<=8000 then category="<=8";
else if 8000<avg_dist<=16000 then category="6-18";
else category=">18";
run;


proc sql;
select category, sum(avg_dist) as sum, ((calculated sum/3070363.7)*100) as perc,sum(volume) as totalvol ,sum(revenue) as totrev,
((calculated totalvol/297413)*100) as percvol, ((calculated totrev/1.4915E8)*100) as perrev
from q4 
group by category;
quit;



/************ QUESTION 5 *****************/
proc sql;
select store_postcode,count(date) as volumeperstore format=comma12., sum(retail_price) as revenueperstore format=comma12., ((calculated volumeperstore/297413)*100) as percentvol format=best6.4, ((calculated revenueperstore/1.4915E8)*100) as percentrev format=best6.4 from final
group by store_postcode
order by volumeperstore desc;
quit;

/****************** On RAM ************************/


proc sql;
select  ram__GB_ label='RAM', mean(retail_price) as avg_price label='Average Price' from final
group by ram__GB_;
quit;


/**************** On Battery Life Hours ****************/



proc sql;
select  battery_life__hours_ label='Battery life hours', mean(retail_price) as avg_price label='Average Price' from final
group by battery_life__hours_;
quit;

/**************** On Screensize ******************/


proc sql;
select  screen_size__Inches_ label='Screen Size (in Inches)', mean(retail_price) as avg_price label='Average Price' from final
group by screen_size__Inches_;
quit;

/********** On processor ******************/
proc sql;
select  processor_speeds__GHz_ label='Processor Speed', mean(retail_price) as avg_price label='Average Price' from final
group by processor_speeds__GHz_;
quit;

