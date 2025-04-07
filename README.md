# Case Study - Food price analysis of India
This research focuses on the problem of typifying and forecasting the cash determinants within a specific segment of the economy – the Indian food marketplace. Price fluctuations, different commodities, and diverse geographical market areas of the country render these phenomena very complex and difficult to understand.

For this study we created a list of **15 questions** to cover various dimensions such as geography, seasonality, and market conditions, providing a comprehensive understanding of the factors influencing food prices. We aim to uncover trends, correlations, and patterns that can inform strategic decision-making.

Apache Hive has been selected as the primary tool for data processing and analysis. 
All the questions and queries can be viewed [here](queries.hql)


- Prepare the dataset
  
  ```bash  
  # It will download the dataset used in this case study and pre-process it.

  python3 preprocess.py
  ```

- Load the dataset into HDFS
  
  In our case Hive was running using a MYSQL metastore.

  ```sql
  -- Main Table

  CREATE TABLE food_prices 
  ( 
    `date` DATE, state STRING, city STRING, market STRING, latitude DOUBLE, longitude DOUBLE, category STRING, commodity STRING, unit STRING, price DOUBLE, year INT, month INT, season STRING 
  ) 
  PARTITIONED BY (category STRING) CLUSTERED BY (state) INTO 10 BUCKETS STORED AS PARQUET;
  
  -- External table for data loading from hdfs
  CREATE TABLE staging_food_prices 
  ( 
    `date` DATE, state STRING, city STRING, market STRING, latitude DOUBLE, longitude DOUBLE, category STRING, commodity STRING, unit STRING, priceflag STRING, pricetype STRING, currency STRING, price DOUBLE, usdprice DOUBLE, year INT, month INT, season STRING 
  ) 
  ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';

  LOAD DATA INPATH '/{hdfs_path}/food_prices_cleaned.csv' INTO TABLE staging_food_prices;

  -- Skip the csv header while selecting
  ALTER TABLE staging_food_prices
  SET TBLPROPERTIES ("skip.header.line.count" = "1");

  -- Enable dynamic partitioning
  SET hive.exec.dynamic.partition=true;
  SET hive.exec.dynamic.partition.mode=nonstrict;

  -- Insert from staging to partitioned table
  INSERT OVERWRITE TABLE food_prices PARTITION(category) 
  SELECT `date`, state, city, market, latitude, longitude, commodity, unit, price, year, month, season, category FROM staging_food_prices;
  ```

- Execute the queries
  
  ```bash
  hive-server /opt/hive/bin/beeline -u jdbc:hive2://localhost:10000/{db_name} -e "{hive_query}" > {output_file.txt}

  # The output is parsed to csv and visualized using Matplotlib
  ```

- Extract csv from hive output
  
  ```bash
  python3 hive2csv.py --in hive_output_file.txt --out csv_output_file.csv
  ```

  > **Info**  
  > The parsed csv output of all the questions is present in the [output](output) folder
