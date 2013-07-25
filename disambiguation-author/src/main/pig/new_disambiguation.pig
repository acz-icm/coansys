--
-- (C) 2010-2012 ICM UW. All rights reserved.
--
-- -----------------------------------------------------
-- -----------------------------------------------------
-- default section
-- -----------------------------------------------------
-- -----------------------------------------------------
%DEFAULT JARS '*.jar'
%DEFAULT commonJarsPath 'lib/$JARS'

%DEFAULT dc_m_hdfs_inputDocsData /srv/bwndata/seqfile/bazekon-20130314.sf 
%DEFAULT time 20130709_1009
%DEFAULT dc_m_hdfs_outputContribs disambiguation/outputContribs$time
%DEFAULT dc_m_meth_extraction getBWBWFromHDFS
%DEFAULT dc_m_meth_extraction_inner pl.edu.icm.coansys.pig.udf.RichSequenceFileLoader
%DEFAULT dc_m_str_feature_info 'TitleDisambiguator#EX_TITLE#1#1,YearDisambiguator#EX_YEAR#1#1'

DEFINE keyTiKwAbsCatExtractor pl.edu.icm.coansys.classification.documents.pig.extractors.EXTRACT_MAP_WHEN_CATEG_LIM('en','removeall');
DEFINE snameDocumentMetaExtractor pl.edu.icm.coansys.disambiguation.author.pig.extractor.EXTRACT_CONTRIBDATA_GIVENDATA('$dc_m_str_feature_info');
DEFINE exhaustiveAND pl.edu.icm.coansys.disambiguation.author.pig.ExhaustiveAND('-1.0','$dc_m_str_feature_info');
DEFINE aproximateAND pl.edu.icm.coansys.disambiguation.author.pig.AproximateAND('-1.0','$dc_m_str_feature_info');
DEFINE sinlgeAND pl.edu.icm.coansys.disambiguation.author.pig.SingleAND();
DEFINE GenUUID pl.edu.icm.coansys.disambiguation.author.pig.GenUUID();
-- -----------------------------------------------------
-- -----------------------------------------------------
-- register section
-- -----------------------------------------------------
-- -----------------------------------------------------
REGISTER /usr/lib/hbase/lib/zookeeper.jar
REGISTER /usr/lib/hbase/hbase-*-cdh4.*-security.jar 
REGISTER /usr/lib/hbase/lib/guava-11.0.2.jar

REGISTER '$commonJarsPath'
-- -----------------------------------------------------
-- -----------------------------------------------------
-- import section
-- -----------------------------------------------------
-- -----------------------------------------------------
IMPORT 'AUXIL_docsim.macros.def.pig';
IMPORT 'AUXIL_macros.def.pig';
-- -----------------------------------------------------
-- -----------------------------------------------------
-- set section
-- -----------------------------------------------------
-- -----------------------------------------------------
%DEFAULT dc_m_double_sample 1.0
%DEFAULT parallel_param 16
%DEFAULT pig_tmpfilecompression_param true
%DEFAULT pig_tmpfilecompression_codec_param gz
%DEFAULT job_priority normal
%DEFAULT pig_cachedbag_mem_usage 0.1
%DEFAULT pig_skewedjoin_reduce_memusage 0.3
set default_parallel $parallel_param
set pig.tmpfilecompression $pig_tmpfilecompression_param
set pig.tmpfilecompression.codec $pig_tmpfilecompression_codec_param
set job.priority $job_priority
set pig.cachedbag.memusage $pig_cachedbag_mem_usage
set pig.skewedjoin.reduce.memusage $pig_skewedjoin_reduce_memusage
-- -----------------------------------------------------
-- -----------------------------------------------------
-- code section
-- -----------------------------------------------------
-- -----------------------------------------------------
A1 = $dc_m_meth_extraction('$dc_m_hdfs_inputDocsData','$dc_m_meth_extraction_inner'); 
-- A2: {key: chararray,value: bytearray}
-- A2 = sample A1 $dc_m_double_sample;

-- z kazdego dokumentu (rekordu tabeli wejsciowe) tworze rekordy z kontrybutorami
-- TODO: wlasciwie tego contribPos tutaj juz nie potrzebujemy, poniewaz wyciagamy tam cId (a do tego byla potrzeba pozcyja) => mozna by zmienic EXTRACT_GIVEN_DATA
B = foreach A1 generate flatten(snameDocumentMetaExtractor($1)) as (cId:chararray, contribPos:int, sname:chararray, metadata:map[{(chararray)}]); 
C = group B by sname;
-- D: {sname: chararray, datagroup: {(cId: chararray,cPos: int,sname: chararray,data: map[{(val_0: chararray)}])}, count: long}
D = foreach C generate group as sname, B as datagroup, COUNT(B) as count;

split D into
	D1 if count == 1,
	D100 if (count > 1 and count < 100),
	D1000 if (count >= 100 and count < 1000),
	DX if count >= 1000;
-- -----------------------------------------------------
-- SINGLE CONTRIBUTORS ---------------------------------
-- -----------------------------------------------------
-- dla kontrybutorow D1: splaszczamy databagi (ktore przeciez maja po jednym elemencie) i od razu generujemy co trzeba
D1A = foreach D1 generate flatten( datagroup );-- as (cId:chararray, contribPos:int, sname:chararray, metadata:map);
-- E1: {cId: chararray,uuid: chararray}
E1 = foreach D1A generate cId as cId, FLATTEN(GenUUID(TOBAG(cId))) as uuid;
-- -----------------------------------------------------
-- SMALL GRUPS OF CONTRIBUTORS -------------------------
-- -----------------------------------------------------
D100A = foreach D100 generate flatten( exhaustiveAND( datagroup ) ) as (uuid:chararray, cIds:chararray);
-- z flatten: 
-- UUID_1, {key_1, key_2, key_3}
-- UUID_4, {key_4}
-- bez flatten:
-- UUID_1,				 UUID_2, UUID_3
-- {key_1, key_2, key_3},{key_4},{key_5, key_6}
-- gdzie key_* to klucze kontrybutorow (autorow dokumentow) w metadanych
E100 = foreach D100A generate flatten( cIds ) as cId, uuid;
-- -----------------------------------------------------
-- BIG GRUPS OF CONTRIBUTORS ---------------------------
-- -----------------------------------------------------
-- D1000A: {datagroup: NULL,simTriples: NULL}
D1000A = foreach D1000 generate flatten( aproximateAND( datagroup ) ) as (datagroup, simTriples);
-- D1000B: {uuid: chararray,cIds: chararray}
D1000B = foreach D1000A generate flatten( exhaustiveAND( datagroup, simTriples ) ) as (uuid:chararray, cIds:chararray);
-- E1000: {cId: chararray,uuid: chararray}
E1000 = foreach D1000B generate flatten( cIds ) as cId, uuid;
-- -----------------------------------------------------
-- REALLY BIG GRUPS OF CONTRIBUTORS ---------------------------
-- -----------------------------------------------------
DXA = foreach DX generate flatten( aproximateAND( datagroup ) ) as (datagroup, simTriples);
DXB = foreach DXA generate flatten( exhaustiveAND( datagroup, simTriples ) ) as (uuid:chararray, cIds:chararray);
EX = foreach DXB generate flatten( cIds ) as cId, uuid;

-- -----------------------------------------------------
-- RESOULT ----------------- ---------------------------
-- -----------------------------------------------------
R = union E1, E100, E1000, EX;
-- R: {cId: chararray,uuid: chararray}
-- S = ORDER R BY uuid,cId;

DUMP R;
-- store R into '$dc_m_hdfs_outputContribs'; 