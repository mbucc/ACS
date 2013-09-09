-- monitoring.sql,v 3.4 2000/05/31 04:53:49 sklein Exp
-- File:        monitoring.sql
-- Author:      mbryzek@arsdigita.com, sklein@arsdigita.com
-- Date:        May 2000
-- Description: Definition for general system monitoring

-- simple table to gather stats from top
-- where top's output looks like this (from dev0103-001:/usr/local/bin/top): 

-- load averages:  0.21,  0.18,  0.23                   21:52:56
-- 322 processes: 316 sleeping, 3 zombie, 1 stopped, 2 on cpu
-- CPU states:  3.7% idle,  9.2% user,  7.1% kernel, 80.0% iowait,  0.0% swap
-- Memory: 1152M real, 17M free, 593M swap in use, 1432M swap free
--
--   PID USERNAME THR PRI NICE  SIZE   RES STATE   TIME    CPU COMMAND
-- 17312 oracle     1  33    0  222M  189M sleep  17:54  0.95% oracle
--  9834 root       1  33    0 2136K 1528K sleep   0:00  0.43% sshd1


create sequence ad_monitoring_top_top_id start with 1;
create table ad_monitoring_top (
	top_id			integer
				constraint ad_monitoring_top_top_id primary key,
        timestamp               date default sysdate,
	-- denormalization: an indexable column for fast time comparisons.
	timehour		number(2),
	-- the three load averages taken from uptime/top
        load_avg_1              number,
        load_avg_5              number,
        load_avg_15             number,
	-- basic stats on current memory usage
        memory_real             number,
        memory_free             number,
        memory_swap_free        number,
        memory_swap_in_use      number,
	-- basic stats on the number of running procedures
	procs_total		integer,
	procs_sleeping		integer,
	procs_zombie		integer,
	procs_stopped		integer,
	procs_on_cpu		integer,
	-- basic stats on cpu usage
	cpu_idle		number,
	cpu_user		number,
	cpu_kernel		number,
	cpu_iowait		number,
	cpu_swap		number
);


-- this table stores information about each of the top 10 or so
-- processes running. Every time we take a snapshot, we record
-- this basic information to help track down stray or greedy 
-- processes
create sequence ad_monitoring_top_proc_proc_id start with 1;
create table ad_monitoring_top_proc (
    proc_id   		integer 
			constraint ad_mntr_top_proc_proc_id primary key,
    top_id       	integer not null 
			constraint ad_mntr_top_proc_top_id references ad_monitoring_top,
    pid         	integer not null,      -- the process id  
    username    	varchar(10) not null,  -- user running this command
    threads             integer,   -- the # of threads this proc is running
    priority            integer,  
    nice                integer,   -- the value of nice for this process
    proc_size           varchar(10),
    resident_memory     varchar(10),
    state               varchar(10),
    cpu_total_time      varchar(10),   -- total cpu time used to date
    cpu_pct             varchar(10),   -- percentage of cpu currently used
    -- the command this process is running
    command     	varchar(30) not null 
);
 

-- EOF 
