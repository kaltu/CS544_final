-- create this table to reduce the chartevents table to within 24 hrs
CREATE TABLE c AS (
	SELECT a.subject_id, a.hadm_id, a.admittime, a.dischtime, a.deathtime, a.admission_type, a.admission_location, a.discharge_location, a.insurance, a.language, a.religion, a.marital_status, a.ethnicity, a.edregtime, a.edouttime, a.diagnosis, a.hospital_expire_flag, a.has_chartevents_data, ch.icustay_id, ch.itemid, ch.charttime, ch.storetime, ch.cgid, ch.value, ch.valuenum, ch.valueuom, ch.warning, ch.error, ch.resultstatus, ch.stopped
	FROM admissions AS a JOIN chartevents AS ch USING (subject_id, hadm_id)
	WHERE ch.charttime BETWEEN a.admittime AND (a.admittime + INTERVAL '24' HOUR)
)

-- create this table to reduce the labevents table to within 24 hrs
CREATE TABLE l AS (
	SELECT a.subject_id, a.hadm_id, a.admittime, a.dischtime, a.deathtime, a.admission_type, a.admission_location, a.discharge_location, a.insurance, a.language, a.religion, a.marital_status, a.ethnicity, a.edregtime, a.edouttime, a.diagnosis, a.hospital_expire_flag, a.has_chartevents_data, la.itemid, la.charttime, la.value, la.valuenum, la.valueuom, la.flag
	FROM admissions AS a JOIN labevents AS la USING (subject_id, hadm_id)
	WHERE la.charttime BETWEEN a.admittime AND (a.admittime + INTERVAL '24' HOUR)
)

-- patients who have the ICD9 code = 99591, older than 18 
SELECT subject_id, hadm_id
FROM diagnoses_icd
WHERE icd9_code IN ('99591')
EXCEPT
SELECT subject_id, hadm_id
FROM admissions JOIN patients USING (subject_id)
WHERE date_part('year', AGE(admittime, dob)) < 18

-- patients who have the ICD9 codes for Sepsis (updated), older than 18
SELECT subject_id, hadm_id
FROM diagnoses_icd
WHERE icd9_code IN ('0380', '03810', '03811', '03812', '03819', '0382', '0383', '03840', '03841', '03842', '03843', '03844', '03849', '78552', '99591', '99592')
EXCEPT
SELECT subject_id, hadm_id
FROM admissions JOIN patients USING (subject_id)
WHERE date_part('year', AGE(admittime, dob)) < 18

-- data on age
SELECT subject_id, hadm_id, AGE(admittime, dob) AS age
FROM admissions JOIN patients USING (subject_id)

-- data on gender
SELECT subject_id, gender FROM patients

-- data on admission type, marital status
SELECT subject_id, hadm_id, admission_type, marital_status FROM admissions

-- data on icu department (icusty_id)
SELECT subject_id, hadm_id, icustay_id FROM icustays

-- get the subjects' comorbidities
SELECT subject_id, hadm_id, icd9_code
FROM diagnoses_icd
WHERE (subject_id) in (
	SELECT DISTINCT subject_id
	FROM diagnoses_icd
	WHERE icd9_code = '99591'
)
AND icd9_code NOT IN ('99591', '0380', '03810', '03811', '03812', '03819', '0382', '0383', '03840', '03841', '03842', '03843', '03844', '03849', '78552', '99592')

-- get the subject's SOFA score
SELECT subject_id, hadm_id, value AS "SOFA score"
FROM c 
where itemid = 227428

-- get the APACHEII value for each of the 12 variables individually (not 24 hrs)
SELECT subject_id, hadm_id, SUM(valuenum) as "APACHEII Score"
FROM c JOIN d_items USING (itemid)
WHERE itemid IN (
	SELECT itemid
	FROM d_items
	WHERE label ILIKE '%APACHEIIScore%'
)
GROUP BY subject_id, hadm_id

-- systolic blood pressure
select subject_id, hadm_id, avg(valuenum) as systolic
from c join d_items using (itemid)
where itemid in (
	select itemid 
	from d_items 
	where label ILIKE '%systolic%'
)
group by subject_id, hadm_id

-- diastolic blood pressure
select subject_id, hadm_id, avg(valuenum) as diastolic
from c join d_items using (itemid)
where itemid in (
	select itemid 
	from d_items 
	where label ILIKE '%diastolic%'
)
group by subject_id, hadm_id

-- heart rate 
select subject_id, hadm_id, avg(valuenum) as "heart rate"
from c join d_items using (itemid)
where itemid in (211, 220045)
group by subject_id, hadm_id

-- respiratory rate 
select subject_id, hadm_id, avg(valuenum) as "respiratory rate"
from c join d_items using (itemid)
where itemid in (618, 220210)
group by subject_id, hadm_id

-- white blood cell
select subject_id, hadm_id, avg(valuenum) as wbc
from l
where itemid = 51301
group by subject_id, hadm_id

-- neutrophil 
select subject_id, hadm_id, avg(valuenum) as neutrophil
from l
where itemid = 51256
group by subject_id, hadm_id

-- lymphocytes 
select subject_id, hadm_id, avg(valuenum) as lymphocytes
from l
where itemid = 51244
group by subject_id, hadm_id

-- sodium 
select subject_id, hadm_id, avg(valuenum) as sodium
from l
where itemid = 50983
group by subject_id, hadm_id

-- chloride 
select subject_id, hadm_id, avg(valuenum) as chloride
from l
where itemid = 50902
group by subject_id, hadm_id

-- platelet 
select subject_id, hadm_id, avg(valuenum) as platelet
from l
where itemid = 51265
group by subject_id, hadm_id

-- red cell volume distribution width 
select subject_id, hadm_id, avg(valuenum) as rcv
from l
where itemid = 51277
group by subject_id, hadm_id

-- mean corpusular volume
select subject_id, hadm_id, avg(valuenum) as mcv
from l
where itemid = 51250
group by subject_id, hadm_id

-- hematocrit
select subject_id, hadm_id, avg(valuenum) as hematocrit
from l
where itemid = 51221
group by subject_id, hadm_id

-- glucose 
select subject_id, hadm_id, avg(valuenum) as glucose
from l
where itemid = 51221
group by subject_id, hadm_id

-- prothrombin time
select subject_id, hadm_id, avg(valuenum) as "prothrombin time"
from l
where itemid = 51274
group by subject_id, hadm_id

-- partial prothrombin time
select subject_id, hadm_id, avg(valuenum) as "partial prothrombin time"
from l
where itemid = 51275
group by subject_id, hadm_id

-- albumin
select subject_id, hadm_id, avg(valuenum) as albumin
from l
where itemid = 50862
group by subject_id, hadm_id

-- alanine aminotransferase
select subject_id, hadm_id, avg(valuenum) as "alanine aminotransferase"
from l
where itemid = 50861
group by subject_id, hadm_id

-- asparate aminotransferase 
select subject_id, hadm_id, avg(valuenum) as "asparate aminotransferase"
from l
where itemid = 50878
group by subject_id, hadm_id

-- total bilirubin
select subject_id, hadm_id, avg(valuenum) as "total bilirubin"
from l
where itemid = 50885
group by subject_id, hadm_id

-- urea nitrogen 
select subject_id, hadm_id, avg(valuenum) as "urea nitrogen"
from l
where itemid = 51006
group by subject_id, hadm_id

-- creatinine 
select subject_id, hadm_id, avg(valuenum) as creatinine
from l
where itemid = 50912
group by subject_id, hadm_id

-- lactate 
select subject_id, hadm_id, avg(valuenum) as lactate
from l
where itemid = 50813
group by subject_id, hadm_id

-- total calcium 
select subject_id, hadm_id, avg(valuenum) as calcium
from l
where itemid = 50893
group by subject_id, hadm_id

-- anion gap 
select subject_id, hadm_id, avg(valuenum) as "anion gap" 
from l
where itemid = 50868
group by subject_id, hadm_id

-- los
select subject_id, hadm_id, los from icustays
