from pyspark.sql import SparkSession

# Create Spark Session
spark = SparkSession.builder \
    .appName("PartitionDemo") \
    .getOrCreate()

# Generate DataFrame with 5 million records
df = spark.range(5000000)

# Display initial number of partitions
print("Initial Partitions:", df.rdd.getNumPartitions())

# Increase partitions to 12
df_repartitioned = df.repartition(12)
print("Partitions after repartition(12):", df_repartitioned.rdd.getNumPartitions())

# Reduce partitions to 3
df_coalesced = df_repartitioned.coalesce(3)
print("Partitions after coalesce(3):", df_coalesced.rdd.getNumPartitions())

# Show a few records
df_coalesced.show(5)

# Stop Spark Session
spark.stop()