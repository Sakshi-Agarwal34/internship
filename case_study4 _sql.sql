create database data_bank_s
use data_bank_s
SELECT * FROM regions;

SELECT TOP 10 * FROM customer_nodes;

SELECT TOP 10 * FROM customer_transactions;
/*=========================================================
A. CUSTOMER NODES EXPLORATION
=========================================================*/

/* Q1. How many unique nodes are there on the Data Bank system? */

SELECT COUNT(DISTINCT node_id) AS unique_nodes
FROM customer_nodes;


/* Q2. What is the number of nodes per region? */

SELECT
    r.region_name,
    COUNT(DISTINCT cn.node_id) AS total_nodes
FROM customer_nodes cn
JOIN regions r
ON cn.region_id = r.region_id
GROUP BY r.region_name;


/* Q3. How many customers are allocated to each region? */

SELECT
    r.region_name,
    COUNT(DISTINCT cn.customer_id) AS total_customers
FROM customer_nodes cn
JOIN regions r
ON cn.region_id = r.region_id
GROUP BY r.region_name;


/* Q4. How many days on average are customers reallocated
       to a different node? */

SELECT
    AVG(DATEDIFF(day,start_date,end_date)*1.0) AS avg_days
FROM customer_nodes
WHERE end_date <> '9999-12-31';


/* Q5. Median, 80th and 95th percentile reallocation days
       for each region */

WITH cte AS
(
    SELECT
        r.region_name,
        DATEDIFF(day,start_date,end_date) AS days_diff
    FROM customer_nodes cn
    JOIN regions r
    ON cn.region_id = r.region_id
    WHERE end_date <> '9999-12-31'
)

SELECT DISTINCT
    region_name,

    PERCENTILE_CONT(0.5)
    WITHIN GROUP (ORDER BY days_diff)
    OVER(PARTITION BY region_name) AS median,

    PERCENTILE_CONT(0.8)
    WITHIN GROUP (ORDER BY days_diff)
    OVER(PARTITION BY region_name) AS p80,

    PERCENTILE_CONT(0.95)
    WITHIN GROUP (ORDER BY days_diff)
    OVER(PARTITION BY region_name) AS p95
FROM cte;



/*=========================================================
B. CUSTOMER TRANSACTIONS
=========================================================*/

/* Q1. Unique count and total amount for each transaction type */

SELECT
    txn_type,
    COUNT(*) AS transaction_count,
    SUM(txn_amount) AS total_amount
FROM customer_transactions
GROUP BY txn_type;


/* Q2. Average historical deposit counts and amounts */

WITH deposit_cte AS
(
    SELECT
        customer_id,
        COUNT(*) AS deposit_count,
        SUM(txn_amount) AS deposit_amount
    FROM customer_transactions
    WHERE txn_type='deposit'
    GROUP BY customer_id
)

SELECT
    AVG(deposit_count*1.0) AS avg_deposit_count,
    AVG(deposit_amount*1.0) AS avg_deposit_amount
FROM deposit_cte;


/* Q3. Customers making >1 deposit and
       at least 1 purchase or withdrawal */

WITH monthly_txn AS
(
    SELECT
        customer_id,
        MONTH(txn_date) AS month_no,

        SUM(CASE WHEN txn_type='deposit'
                 THEN 1 ELSE 0 END) deposits,

        SUM(CASE WHEN txn_type='purchase'
                 THEN 1 ELSE 0 END) purchases,

        SUM(CASE WHEN txn_type='withdrawal'
                 THEN 1 ELSE 0 END) withdrawals

    FROM customer_transactions
    GROUP BY customer_id,
             MONTH(txn_date)
)

SELECT
    month_no,
    COUNT(customer_id) AS customers
FROM monthly_txn
WHERE deposits > 1
AND (purchases >= 1 OR withdrawals >= 1)
GROUP BY month_no;


/* Q4. Closing balance for each customer
       at the end of the month */

WITH txn_balance AS
(
    SELECT
        customer_id,
        EOMONTH(txn_date) AS month_end,

        SUM(
            CASE
                WHEN txn_type='deposit'
                THEN txn_amount
                ELSE -txn_amount
            END
        ) AS net_amount

    FROM customer_transactions
    GROUP BY customer_id,
             EOMONTH(txn_date)
)

SELECT
    customer_id,
    month_end,

    SUM(net_amount)
    OVER(
        PARTITION BY customer_id
        ORDER BY month_end
    ) AS closing_balance
FROM txn_balance;


/* Q5. Percentage of customers increasing
       closing balance by more than 5% */

WITH monthly_balance AS
(
    SELECT
        customer_id,
        EOMONTH(txn_date) AS month_end,

        SUM(
            CASE
                WHEN txn_type='deposit'
                THEN txn_amount
                ELSE -txn_amount
            END
        ) AS net_change

    FROM customer_transactions
    GROUP BY customer_id,
             EOMONTH(txn_date)
),

running_balance AS
(
    SELECT
        customer_id,
        month_end,

        SUM(net_change)
        OVER(
            PARTITION BY customer_id
            ORDER BY month_end
        ) AS closing_balance
    FROM monthly_balance
),

growth AS
(
    SELECT
        customer_id,
        month_end,
        closing_balance,

        LAG(closing_balance)
        OVER(
            PARTITION BY customer_id
            ORDER BY month_end
        ) AS prev_balance
    FROM running_balance
)

SELECT
ROUND(
100.0 *
COUNT(DISTINCT customer_id)
/
(SELECT COUNT(DISTINCT customer_id)
 FROM customer_transactions)
,2) AS pct_customers
FROM growth
WHERE prev_balance IS NOT NULL
AND (closing_balance - prev_balance)
    > prev_balance * 0.05;
    /*=========================================================
C. DATA ALLOCATION CHALLENGE
=========================================================*/

/*---------------------------------------------------------
Q1. Running customer balance after each transaction
---------------------------------------------------------*/

SELECT
    customer_id,
    txn_date,
    txn_type,
    txn_amount,

    SUM(
        CASE
            WHEN txn_type = 'deposit'
            THEN txn_amount
            ELSE -txn_amount
        END
    ) OVER (
        PARTITION BY customer_id
        ORDER BY txn_date
    ) AS running_balance

FROM customer_transactions
ORDER BY customer_id, txn_date;


/*---------------------------------------------------------
Q2. Customer balance at the end of each month
---------------------------------------------------------*/

WITH running_balance_cte AS
(
    SELECT
        customer_id,
        txn_date,

        SUM(
            CASE
                WHEN txn_type = 'deposit'
                THEN txn_amount
                ELSE -txn_amount
            END
        ) OVER (
            PARTITION BY customer_id
            ORDER BY txn_date
        ) AS running_balance

    FROM customer_transactions
)

SELECT
    customer_id,
    EOMONTH(txn_date) AS month_end,
    MAX(running_balance) AS month_end_balance
FROM running_balance_cte
GROUP BY
    customer_id,
    EOMONTH(txn_date)
ORDER BY customer_id, month_end;


/*---------------------------------------------------------
Q3. Minimum, Average and Maximum Running Balance
for each customer
---------------------------------------------------------*/

WITH running_balance_cte AS
(
    SELECT
        customer_id,

        SUM(
            CASE
                WHEN txn_type='deposit'
                THEN txn_amount
                ELSE -txn_amount
            END
        ) OVER(
            PARTITION BY customer_id
            ORDER BY txn_date
        ) AS running_balance

    FROM customer_transactions
)

SELECT
    customer_id,
    MIN(running_balance) AS min_balance,
    AVG(running_balance * 1.0) AS avg_balance,
    MAX(running_balance) AS max_balance
FROM running_balance_cte
GROUP BY customer_id
ORDER BY customer_id;


/*---------------------------------------------------------
OPTION 1
Data allocated based on previous month closing balance
---------------------------------------------------------*/

WITH monthly_balance AS
(
    SELECT
        customer_id,
        EOMONTH(txn_date) AS month_end,

        SUM(
            CASE
                WHEN txn_type='deposit'
                THEN txn_amount
                ELSE -txn_amount
            END
        ) AS net_change

    FROM customer_transactions
    GROUP BY
        customer_id,
        EOMONTH(txn_date)
)

SELECT
    month_end,
    SUM(net_change) AS data_required
FROM monthly_balance
GROUP BY month_end
ORDER BY month_end;


/*---------------------------------------------------------
OPTION 2
Data allocated based on average balance in previous 30 days
---------------------------------------------------------*/

WITH running_balance_cte AS
(
    SELECT
        customer_id,
        txn_date,

        SUM(
            CASE
                WHEN txn_type='deposit'
                THEN txn_amount
                ELSE -txn_amount
            END
        ) OVER(
            PARTITION BY customer_id
            ORDER BY txn_date
        ) AS running_balance

    FROM customer_transactions
)

SELECT
    customer_id,
    AVG(running_balance * 1.0) AS avg_balance
FROM running_balance_cte
GROUP BY customer_id
ORDER BY customer_id;


/*---------------------------------------------------------
OPTION 3
Real-time data allocation
---------------------------------------------------------*/

SELECT
    MONTH(txn_date) AS month_no,

    SUM(
        CASE
            WHEN txn_type='deposit'
            THEN txn_amount
            ELSE -txn_amount
        END
    ) AS realtime_data_required

FROM customer_transactions
GROUP BY MONTH(txn_date)
ORDER BY month_no;

/*=========================================================
D. EXTRA CHALLENGE
=========================================================*/

/*---------------------------------------------------------
Q1. Daily Interest Calculation
Annual Interest Rate = 6%
Daily Interest = Balance * (0.06 / 365)
---------------------------------------------------------*/

WITH balance_cte AS
(
    SELECT
        customer_id,
        txn_date,

        SUM(
            CASE
                WHEN txn_type='deposit'
                THEN txn_amount
                ELSE -txn_amount
            END
        ) OVER(
            PARTITION BY customer_id
            ORDER BY txn_date
        ) AS balance

    FROM customer_transactions
)

SELECT
    customer_id,
    txn_date,
    balance,

    balance * (0.06 / 365.0) AS daily_interest

FROM balance_cte
ORDER BY customer_id, txn_date;


/*---------------------------------------------------------
Q2. Monthly Interest Earned
---------------------------------------------------------*/

WITH balance_cte AS
(
    SELECT
        customer_id,
        txn_date,

        SUM(
            CASE
                WHEN txn_type='deposit'
                THEN txn_amount
                ELSE -txn_amount
            END
        ) OVER(
            PARTITION BY customer_id
            ORDER BY txn_date
        ) AS balance

    FROM customer_transactions
)

SELECT
    customer_id,
    YEAR(txn_date) AS year_no,
    MONTH(txn_date) AS month_no,

    SUM(balance * (0.06 / 365.0))
        AS monthly_interest

FROM balance_cte
GROUP BY
    customer_id,
    YEAR(txn_date),
    MONTH(txn_date)

ORDER BY
    customer_id,
    year_no,
    month_no;
