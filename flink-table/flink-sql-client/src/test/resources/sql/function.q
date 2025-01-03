# function.q - CREATE/DROP/ALTER/SHOW/DESCRIBE FUNCTION
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to you under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ADD JAR '$VAR_UDF_JAR_PATH';
[INFO] Execute statement succeeded.
!info

SHOW JARS;
+-$VAR_UDF_JAR_PATH_DASH-----+
| $VAR_UDF_JAR_PATH_SPACEjars |
+-$VAR_UDF_JAR_PATH_DASH-----+
| $VAR_UDF_JAR_PATH |
+-$VAR_UDF_JAR_PATH_DASH-----+
1 row in set
!ok

# this also tests user classloader because the LowerUDF is in user jar
create function func1 as 'LowerUDF' LANGUAGE JAVA;
[INFO] Execute statement succeeded.
!info

show user functions;
+---------------+
| function name |
+---------------+
|         func1 |
+---------------+
1 row in set
!ok

show user functions like 'func%';
+---------------+
| function name |
+---------------+
|         func1 |
+---------------+
1 row in set
!ok

show user functions ilike 'func%';
+---------------+
| function name |
+---------------+
|         func1 |
+---------------+
1 row in set
!ok

SET 'sql-client.execution.result-mode' = 'tableau';
[INFO] Execute statement succeeded.
!info

# run a query to verify the registered UDF works
SELECT id, func1(str) FROM (VALUES (1, 'Hello World'), (2, 'Hi')) as T(id, str);
+----+-------------+--------------------------------+
| op |          id |                         EXPR$1 |
+----+-------------+--------------------------------+
| +I |           1 |                    hello world |
| +I |           2 |                             hi |
+----+-------------+--------------------------------+
Received a total of 2 rows
!ok

# ====== test temporary function ======

create temporary function if not exists func2 as 'LowerUDF' LANGUAGE JAVA;
[INFO] Execute statement succeeded.
!info

show user functions;
+---------------+
| function name |
+---------------+
|         func1 |
|         func2 |
+---------------+
2 rows in set
!ok

show user functions like 'func1%';
+---------------+
| function name |
+---------------+
|         func1 |
+---------------+
1 row in set
!ok

show user functions ilike 'func2%';
+---------------+
| function name |
+---------------+
|         func2 |
+---------------+
1 row in set
!ok

# ====== test function with full qualified name ======

create catalog c1 with ('type'='generic_in_memory');
[INFO] Execute statement succeeded.
!info

use catalog c1;
[INFO] Execute statement succeeded.
!info

create database db;
[INFO] Execute statement succeeded.
!info

use catalog default_catalog;
[INFO] Execute statement succeeded.
!info

create function c1.db.func3 as 'LowerUDF' LANGUAGE JAVA;
[INFO] Execute statement succeeded.
!info

create temporary function if not exists c1.db.func4 as 'LowerUDF' LANGUAGE JAVA;
[INFO] Execute statement succeeded.
!info

# no func3 and func4 because we are not under catalog c1
show user functions;
+---------------+
| function name |
+---------------+
|         func1 |
|         func2 |
+---------------+
2 rows in set
!ok

# ====== test function with specified catalog and db ======

# we are not under catalog c1

show user functions from c1.db;
+---------------+
| function name |
+---------------+
|         func3 |
|         func4 |
+---------------+
2 rows in set
!ok

show user functions from c1.db like 'func3%';
+---------------+
| function name |
+---------------+
|         func3 |
+---------------+
1 row in set
!ok

show user functions in c1.db ilike 'FUNC3%';
+---------------+
| function name |
+---------------+
|         func3 |
+---------------+
1 row in set
!ok

use catalog c1;
[INFO] Execute statement succeeded.
!info

use db;
[INFO] Execute statement succeeded.
!info

# should show func3 and func4 now
show user functions;
+---------------+
| function name |
+---------------+
|         func3 |
|         func4 |
+---------------+
2 rows in set
!ok

# test create function with database name
create function `default`.func5 as 'LowerUDF';
[INFO] Execute statement succeeded.
!info

create function `default`.func6 as 'LowerUDF';
[INFO] Execute statement succeeded.
!info

use `default`;
[INFO] Execute statement succeeded.
!info

# should show func5 and func6
show user functions;
+---------------+
| function name |
+---------------+
|         func5 |
|         func6 |
+---------------+
2 rows in set
!ok

# ==========================================================================
# test drop function
# ==========================================================================

create function c1.db.func10 as 'LowerUDF';
[INFO] Execute statement succeeded.
!info

create function c1.db.func11 as 'LowerUDF';
[INFO] Execute statement succeeded.
!info

drop function if exists c1.db.func10;
[INFO] Execute statement succeeded.
!info

use catalog c1;
[INFO] Execute statement succeeded.
!info

use db;
[INFO] Execute statement succeeded.
!info

drop function if exists non_func;
[INFO] Execute statement succeeded.
!info

# should contain func11, not contain func10
show user functions;
+---------------+
| function name |
+---------------+
|        func11 |
|         func3 |
|         func4 |
+---------------+
3 rows in set
!ok

# ==========================================================================
# test alter function
# ==========================================================================

alter function func11 as 'org.apache.flink.table.client.gateway.local.ExecutorImplITCase$TestScalaFunction';
[INFO] Execute statement succeeded.
!info

# TODO: show func11 when we support DESCRIBE FUNCTION

create temporary function tmp_func as 'LowerUDF';
[INFO] Execute statement succeeded.
!info

# should throw unsupported error
alter temporary function tmp_func as 'org.apache.flink.table.client.gateway.local.ExecutorImplITCase$TestScalaFunction';
[ERROR] Could not execute SQL statement. Reason:
org.apache.flink.table.api.ValidationException: Alter temporary catalog function is not supported
!error


# ==========================================================================
# test create function using jar
# ==========================================================================

REMOVE JAR '$VAR_UDF_JAR_PATH';
[INFO] Execute statement succeeded.
!info

SHOW JARS;
Empty set
!ok

create temporary function temp_upperudf AS 'UpperUDF' using jar '$VAR_UDF_JAR_PATH';
[INFO] Execute statement succeeded.
!info

SHOW JARS;
Empty set
!ok

create function upperudf AS 'UpperUDF' using jar '$VAR_UDF_JAR_PATH';
[INFO] Execute statement succeeded.
!info

# `SHOW JARS` does not list the jars being used by function, it only list all the jars added by `ADD JAR`
SHOW JARS;
Empty set
!ok

# run a query to verify the registered UDF works
SELECT id, upperudf(str) FROM (VALUES (1, 'hello world'), (2, 'hi')) as T(id, str);
+----+-------------+--------------------------------+
| op |          id |                         EXPR$1 |
+----+-------------+--------------------------------+
| +I |           1 |                    HELLO WORLD |
| +I |           2 |                             HI |
+----+-------------+--------------------------------+
Received a total of 2 rows
!ok

# Each query registers its jar to resource manager could not affect the session in sql gateway
SHOW JARS;
Empty set
!ok

# Show all users functions which should not add function jars to session resource manager
show user functions;
+---------------+
| function name |
+---------------+
|        func11 |
|         func3 |
|         func4 |
| temp_upperudf |
|      tmp_func |
|      upperudf |
+---------------+
6 rows in set
!ok

# Show functions will not affect the session in sql gateway
SHOW JARS;
Empty set
!ok

# ==========================================================================
# test describe function
# ==========================================================================

ADD JAR '$VAR_UDF_JAR_PATH';
[INFO] Execute statement succeeded.
!info

describe function `SUM`;
+--------------------+------------+
|          info name | info value |
+--------------------+------------+
| is system function |       true |
|       is temporary |      false |
+--------------------+------------+
2 rows in set
!ok

describe function extended `SUM`;
+---------------------------+----------------+
|                 info name |     info value |
+---------------------------+----------------+
|        is system function |           true |
|              is temporary |          false |
|                      kind |      AGGREGATE |
|              requirements |             [] |
|          is deterministic |           true |
| supports constant folding |           true |
|                 signature | SUM(<NUMERIC>) |
+---------------------------+----------------+
7 rows in set
!ok

describe function temp_upperudf;
+--------------------+---------------------------------------------$VAR_UDF_JAR_PATH_DASH+
|          info name |                                 $VAR_UDF_JAR_PATH_SPACE info value |
+--------------------+---------------------------------------------$VAR_UDF_JAR_PATH_DASH+
| is system function |                                      $VAR_UDF_JAR_PATH_SPACE false |
|       is temporary |                                       $VAR_UDF_JAR_PATH_SPACE true |
|         class name |                                   $VAR_UDF_JAR_PATH_SPACE UpperUDF |
|  function language |                                       $VAR_UDF_JAR_PATH_SPACE JAVA |
|      resource uris | [ResourceUri{resourceType=JAR, uri='$VAR_UDF_JAR_PATH'}] |
+--------------------+---------------------------------------------$VAR_UDF_JAR_PATH_DASH+
5 rows in set
!ok

describe function extended temp_upperudf;
+---------------------------+---------------------------------------------$VAR_UDF_JAR_PATH_DASH+
|                 info name |                                 $VAR_UDF_JAR_PATH_SPACE info value |
+---------------------------+---------------------------------------------$VAR_UDF_JAR_PATH_DASH+
|        is system function |                                      $VAR_UDF_JAR_PATH_SPACE false |
|              is temporary |                                       $VAR_UDF_JAR_PATH_SPACE true |
|                class name |                                   $VAR_UDF_JAR_PATH_SPACE UpperUDF |
|         function language |                                       $VAR_UDF_JAR_PATH_SPACE JAVA |
|             resource uris | [ResourceUri{resourceType=JAR, uri='$VAR_UDF_JAR_PATH'}] |
|                      kind |                                     $VAR_UDF_JAR_PATH_SPACE SCALAR |
|              requirements |                                         $VAR_UDF_JAR_PATH_SPACE [] |
|          is deterministic |                                       $VAR_UDF_JAR_PATH_SPACE true |
| supports constant folding |                                       $VAR_UDF_JAR_PATH_SPACE true |
|                 signature |        $VAR_UDF_JAR_PATH_SPACE c1.db.temp_upperudf(arg0 => STRING) |
+---------------------------+---------------------------------------------$VAR_UDF_JAR_PATH_DASH+
10 rows in set
!ok

desc function temp_upperudf;
+--------------------+---------------------------------------------$VAR_UDF_JAR_PATH_DASH+
|          info name |                                 $VAR_UDF_JAR_PATH_SPACE info value |
+--------------------+---------------------------------------------$VAR_UDF_JAR_PATH_DASH+
| is system function |                                      $VAR_UDF_JAR_PATH_SPACE false |
|       is temporary |                                       $VAR_UDF_JAR_PATH_SPACE true |
|         class name |                                   $VAR_UDF_JAR_PATH_SPACE UpperUDF |
|  function language |                                       $VAR_UDF_JAR_PATH_SPACE JAVA |
|      resource uris | [ResourceUri{resourceType=JAR, uri='$VAR_UDF_JAR_PATH'}] |
+--------------------+---------------------------------------------$VAR_UDF_JAR_PATH_DASH+
5 rows in set
!ok

desc function extended temp_upperudf;
+---------------------------+---------------------------------------------$VAR_UDF_JAR_PATH_DASH+
|                 info name |                                 $VAR_UDF_JAR_PATH_SPACE info value |
+---------------------------+---------------------------------------------$VAR_UDF_JAR_PATH_DASH+
|        is system function |                                      $VAR_UDF_JAR_PATH_SPACE false |
|              is temporary |                                       $VAR_UDF_JAR_PATH_SPACE true |
|                class name |                                   $VAR_UDF_JAR_PATH_SPACE UpperUDF |
|         function language |                                       $VAR_UDF_JAR_PATH_SPACE JAVA |
|             resource uris | [ResourceUri{resourceType=JAR, uri='$VAR_UDF_JAR_PATH'}] |
|                      kind |                                     $VAR_UDF_JAR_PATH_SPACE SCALAR |
|              requirements |                                         $VAR_UDF_JAR_PATH_SPACE [] |
|          is deterministic |                                       $VAR_UDF_JAR_PATH_SPACE true |
| supports constant folding |                                       $VAR_UDF_JAR_PATH_SPACE true |
|                 signature |        $VAR_UDF_JAR_PATH_SPACE c1.db.temp_upperudf(arg0 => STRING) |
+---------------------------+---------------------------------------------$VAR_UDF_JAR_PATH_DASH+
10 rows in set
!ok

# test that system functions get resolved before catalog functions
create temporary system function temp_upperudf AS 'UpperUDF' using jar '$VAR_UDF_JAR_PATH';
[INFO] Execute statement succeeded.
!info

# we see both the temp system function and the catalog function for temp_upperudf
show user functions;
+---------------+
| function name |
+---------------+
|        func11 |
|         func3 |
|         func4 |
| temp_upperudf |
| temp_upperudf |
|      tmp_func |
|      upperudf |
+---------------+
7 rows in set
!ok

# but the system function gets resolved first
describe function temp_upperudf;
+--------------------+------------+
|          info name | info value |
+--------------------+------------+
| is system function |       true |
|       is temporary |       true |
+--------------------+------------+
2 rows in set
!ok

# but the catalog function should get resolved when using the full name
describe function `c1`.`db`.temp_upperudf;
+--------------------+---------------------------------------------$VAR_UDF_JAR_PATH_DASH+
|          info name |                                 $VAR_UDF_JAR_PATH_SPACE info value |
+--------------------+---------------------------------------------$VAR_UDF_JAR_PATH_DASH+
| is system function |                                      $VAR_UDF_JAR_PATH_SPACE false |
|       is temporary |                                       $VAR_UDF_JAR_PATH_SPACE true |
|         class name |                                   $VAR_UDF_JAR_PATH_SPACE UpperUDF |
|  function language |                                       $VAR_UDF_JAR_PATH_SPACE JAVA |
|      resource uris | [ResourceUri{resourceType=JAR, uri='$VAR_UDF_JAR_PATH'}] |
+--------------------+---------------------------------------------$VAR_UDF_JAR_PATH_DASH+
5 rows in set
!ok

describe function extended temp_upperudf;
+---------------------------+-------------------------------+
|                 info name |                    info value |
+---------------------------+-------------------------------+
|        is system function |                          true |
|              is temporary |                          true |
|                      kind |                        SCALAR |
|              requirements |                            [] |
|          is deterministic |                          true |
| supports constant folding |                          true |
|                 signature | temp_upperudf(arg0 => STRING) |
+---------------------------+-------------------------------+
7 rows in set
!ok
