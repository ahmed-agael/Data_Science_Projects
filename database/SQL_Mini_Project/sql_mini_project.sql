/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, aand revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:


The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */

/* QUESTIONS */
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */

SELECT `name`
FROM `Facilities`
WHERE `membercost` > 0

/* Q2: How many facilities do not charge a fee to members? */

SELECT COUNT( * )
	FROM `Facilities`
	WHERE membercost = 0
LIMIT 0 , 30


/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT `facid` , `name` , `membercost` , `monthlymaintenance`
	FROM `Facilities`
	WHERE `membercost` >0
	AND `membercost` < 0.2 * `monthlymaintenance`
LIMIT 0 , 30

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */

SELECT *
	FROM `Facilities`
	WHERE `facid`
	IN ( 1, 5 )
LIMIT 0 , 30


/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */

SELECT `name` , `monthlymaintenance` ,
	CASE WHEN `monthlymaintenance` >100  
	THEN 'expensive'
	ELSE 'cheap'
	END AS STATUS
FROM `Facilities`
LIMIT 0 , 30

/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */

SELECT `firstname` , `surname` 
	FROM `Members`
	WHERE `joindate` = (
					SELECT MAX( joindate )
							FROM `Members` );


/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

SELECT CONCAT_WS( " ", m.firstname, m.surname ) AS `full_name` , f.name AS 'facility_name', b.starttime
FROM Bookings b
	INNER JOIN Facilities f ON b.facid = f.facid
	INNER JOIN Members m ON b.memid = m.memid
WHERE f.name LIKE '%Tennis Court%'
	AND m.firstname != 'GUEST'
GROUP BY full_name, facility_name
ORDER BY full_name;

/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

SELECT CONCAT_WS( " ", m.firstname, m.surname ) AS `full_name` , f.name AS 'facility_name', b.starttime,
	CASE
			WHEN m.memid =0
				THEN b.slots * f.guestcost
			ELSE b.slots * f.membercost
	END AS cost
FROM Members m
	INNER JOIN Bookings b ON m.memid = b.memid
	INNER JOIN Facilities f ON b.facid = f.facid
WHERE b.starttime >= '2012-09-14'
	AND b.starttime < '2012-09-15'
		AND (
					(
						m.memid =0
							AND b.slots * f.guestcost >30
					)
					OR (
						m.memid !=0
							AND b.slots * f.membercost >30
						)
				)
ORDER BY cost DESC

/* Q9: This time, produce the same result as in Q8, but using a subquery. */

SELECT full_name, facility, cost, starttime
FROM (
	SELECT CONCAT_WS( " ", m.firstname, m.surname ) AS full_name, f.name AS facility, b.starttime AS starttime,
		CASE
		WHEN m.memid =0
			THEN b.slots * f.guestcost
		ELSE b.slots * f.membercost
		END AS cost
		FROM Members m
			INNER JOIN Bookings b ON m.memid = b.memid
			INNER JOIN Facilities f ON b.facid = f.facid
	WHERE b.starttime >= '2012-09-14'
		AND b.starttime < '2012-09-15'
	) AS subquery
WHERE cost >30
ORDER BY cost DESC

/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  */

# import the required libraries 
from sqlalchemy import create_engine
import pandas as pd

# creat database engine
engine = create_engine('sqlite:///sqlite_db_pythonsqlite.db')

/* QUESTIONS: */
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

# save the query as a string to a variable 'query10'
query10 = '''SELECT f.name, SUM(
                                CASE
                                    WHEN memid =0
                                        THEN slots * f.guestcost
                                    ELSE slots * membercost
                                    END ) AS revenue
             FROM Bookings as b
             INNER JOIN Facilities as f ON b.facid = f.facid
             GROUP BY f.name
             HAVING revenue <1000
             ORDER BY revenue DESC'''

# Open engine in context manager
# Perform query and save results to DataFrame
with engine.connect() as con:
    rs = con.execute(query10)
    revenue_list = pd.DataFrame(rs.fetchall())
    revenue_list.columns = rs.keys()

# Print the head of the DataFrame
revenue_list.head()

/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */

# save the query as a string to a variable 'query11'								
query11 = '''SELECT m.memid as member_id,
                m.firstname || ' ' ||  m.surname AS member_name,
                r.memid as recommender_id,
                r.firstname || ' ' || r.surname AS recommender_name
            FROM 
                Members m
            LEFT JOIN Members r
                ON r.memid = m.recommendedby
            WHERE m.firstname NOT LIKE 'GUEST%'
            ORDER BY m.surname, m.firstname;'''

# Open engine in context manager
# Perform query and save results to DataFrame
with engine.connect() as con:
    rs = con.execute(query11)
    member_recommender_list = pd.DataFrame(rs.fetchall())
    member_recommender_list.columns = rs.keys()

# Print the DataFrame
member_recommender_list
										   
/* Q12: Find the facilities with their usage by member, but not guests */
										   
# save the query as a string to a variable 'query12'																		   
query12 = '''SELECT m.firstname || ' ' ||  m.surname AS member_name,
                    f.name AS facility,
                    count(f.name) as usage
             FROM Bookings as b
             LEFT JOIN Facilities as f 
                 USING(facid)
             LEFT JOIN Members m
                 USING(memid)
             WHERE m.firstname NOT LIKE 'GUEST%'
             GROUP BY member_name, facility;'''
										   
# Open engine in context manager
# Perform query and save results to DataFrame
with engine.connect() as con:
    rs = con.execute(query12)
    member_facility_count = pd.DataFrame(rs.fetchall())
    member_facility_count.columns = rs.keys()

# Print the head of the DataFrame
member_facility_count.head(10)
										 
/* Q13: Find the facilities usage by month, but not guests */

# save the query as a string to a variable 'query13'																		   
query13 = '''SELECT STRFTIME('%m', b.starttime) AS month,
                    f.name AS facility,
                    COUNT(f.name) as usage 
             FROM Bookings b 
             LEFT JOIN Facilities f
                USING(facid)
             GROUP BY month, facility
             ORDER BY month;'''

# Open engine in context manager
# Perform query and save results to DataFrame
with engine.connect() as con:
    rs = con.execute(query13)
    facility_usage_by_month = pd.DataFrame(rs.fetchall())
    facility_usage_by_month.columns = rs.keys()

# Print the head of the DataFrame
facility_usage_by_month.head(10)



