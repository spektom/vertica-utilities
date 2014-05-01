-- =============================================
-- Query Vertica configuration
-- =============================================
SELECT * FROM configuration_parameters WHERE parameter_name ILIKE '%out%';

-- =============================================
-- List resource pools
-- =============================================
SELECT * FROM resource_pools;

-- =============================================
-- Altering resource pool
-- =============================================
ALTER RESOURCE POOL tm MEMORYSIZE '2G' PLANNEDCONCURRENCY 3;
ALTER RESOURCE POOL wosdata PLANNEDCONCURRENCY 3;

-- =============================================
-- List current partitions
-- =============================================
SELECT * FROM partitions;
SELECT COUNT(1) FROM partitions;

-- ==========================================================
-- Show current local segmentation status and scaling factor
-- ==========================================================
SELECT is_enabled, scaling_factor FROM elastic_cluster;

-- =============================================
-- ROS containers per table
-- =============================================
SELECT anchor_table_name,SUM(ros_count) FROM projection_storage GROUP BY 1 ORDER BY 2 DESC;

-- =============================================
-- Storage containers by projection
-- =============================================
SELECT COUNT(*),node_name,projection_name FROM storage_containers GROUP BY 2,3 ORDER BY 1 DESC LIMIT 20;

-- =============================================
-- Deleted vectors by projection
-- =============================================
SELECT projection_name,COUNT(1) FROM delete_vectors GROUP BY 1 ORDER BY 2 DESC;

-- =============================================
-- Tuple mover log
-- =============================================
SELECT * FROM tuple_mover_operations;

-- =============================================
-- Execute mergeout explicitly
-- =============================================
SELECT DO_TM_TASK('mergeout', 'table');
-- Mergeout all tables
SELECT DO_TM_TASK('mergeout');

-- =============================================
-- Identify ROS containers needed to be merged
-- =============================================
CREATE VIEW large_grouped_roses AS SELECT * FROM (
	SELECT s.*, TO_CHAR(100.0*grouped_bytes::FLOAT/(grouped_bytes::FLOAT+NON_GROUPED_BYTES), '999.99') AS PCT 
		FROM (
			SELECT sc.schema_name, sc.projection_name, SUM(CASE WHEN GROUPING = 'ALL' THEN USED_BYTES ELSE 0 END) AS GROUPED_BYTES, 
				SUM(CASE WHEN GROUPING = 'ALL' THEN 0 ELSE USED_BYTES END) AS NON_GROUPED_BYTES 
			FROM storage_containers SC 
			GROUP BY sc.schema_name, sc.projection_name
		) AS S
	) AS Q 
	WHERE q.grouped_bytes > 1024000 AND Q.PCT > 10 
	ORDER BY Q.GROUPED_BYTES DESC;

CREATE VIEW proj_to_merge AS SELECT distinct schema_name, projection_name, partition_key FROM (
	SELECT gr.schema_name, gr.projection_name, sc.storage_oid, used_bytes, partition_key 
	FROM large_grouped_roses GR 
	NATURAL LEFT JOIN storage_containers SC 
	LEFT JOIN partitions P 
	ON sc.storage_oid = p.ros_id 
	WHERE sc.grouping = 'ALL') Q;

SELECT * FROM large_grouped_roses;
SELECT * FROM proj_to_merge;
-- If a partition_key is listed, execute the following command on the projection/partition:
SELECT merge_partitions('table_name', 'from_key', 'to_key');
-- If no partition key is returned, execute the following command:
SELECT DO_TM_TASK('mergeout');

