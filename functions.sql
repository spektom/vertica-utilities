-- Query Vertica configuration
SELECT * FROM configuration_parameters WHERE parameter_name ILIKE '%out%';

-- List resource pools
SELECT * FROM resource_pools;

-- Altering resource pool
ALTER RESOURCE POOL tm MEMORYSIZE '2G' PLANNEDCONCURRENCY 3;
ALTER RESOURCE POOL wosdata PLANNEDCONCURRENCY 3;

-- List current partitions
SELECT * FROM partitions;
SELECT COUNT(1) FROM partitions;

-- Show current local segmentation status and scaling factor
SELECT is_enabled, scaling_factor FROM elastic_cluster;

-- ROS containers per table
SELECT anchor_table_name,SUM(ros_count) FROM projection_storage GROUP BY 1;

-- Tuple mover log
SELECT * FROM tuple_mover_operations;

