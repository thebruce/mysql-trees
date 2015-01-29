## Based and quoted from  
# code and work in Joe Celko's Trees and Hierarchies in SQL Book
# But set up for the idiosyncracies of MySQL
##

################################################################
# CREATE BASIC LIST ADJACENCY TABLE
###############################################################
-- Create a simple improved tree ALM (Adjacency List Model) table
-- We have an id and its parent id 
CREATE TABLE `alm_1_simple` (
  `tree_id` int(11) NOT NULL AUTO_INCREMENT,
  `id` int(11) NOT NULL DEFAULT '0',
  `parent_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`tree_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


### TRANSFER ALL BOOK DATA TO THIS BASIC MODEL ###
-- Transfering Book Hierarchical Data into this Model.
--  This will transfer all book data from book and menu_links into
-- this simple model.
SELECT book.nid, IFNULL(book2.nid,0) as parent, menu_links.depth
FROM menu_links 
JOIN book on book.mlid = menu_links.mlid
LEFT OUTER JOIN book book2 on book2.mlid = menu_links.plid
WHERE book.bid IS NOT NULL
order by book.bid, depth, weight;

### TRANSFER SOME BOOK DATA TO THIS BASIC MODEL ###
## In this case node 19

-- Raw SELECT Statement for this data
SELECT book.nid id, IFNULL(book2.nid,0) as parent_id, menu_links.depth
FROM menu_links 
JOIN book on book.mlid = menu_links.mlid
LEFT OUTER JOIN book book2 on book2.mlid = menu_links.plid
WHERE book.bid = 19
order by book.bid, depth, weight;

-- Insert a specific book's items into alm_1_simple (node 19)
INSERT into alm_1_simple (id, parent_id)
SELECT book.nid id, IFNULL(book2.nid,0) as parent_id
FROM menu_links 
JOIN book on book.mlid = menu_links.mlid
LEFT OUTER JOIN book book2 on book2.mlid = menu_links.plid
WHERE book.bid = 19
order by book.bid, depth, weight;

#############################################################
#### EDITORIAL NOTES ON THE LACK OF CONSTRAINTS IN MySQL
#### Joe Celko rightly advocates for the use of the SQL92
#### constraints and checks at the table level, alas MySQL
#### does not implement this.
# IF ONLY MySQL allowed check constraints from SQL92
# But they don't. So constraints like the following won't work.
# ALTER TABLE alm_1_simple
# ADD CONSTRAINT  prevent_cycles
# check (parent_id <> id);
#
# You can see how this would be valuable and how keeps data logic
# at the data level, which in the end means a tremendous flexibility 
# and portability in your data model. 

# However since it won't be anytime (soon) we could/should--- 
# BAKE IT INTO INSERT STATEMENTS LIKE SO:
# WHERE parent_id <> id

## Manual Constraint Checking ##

###### Manual Constraint Checking: CHECKING THAT OUR GRAPH IS A TREE AND A HIERARCHY PT 1 - 
#### Edges are exactly 1 less than nodes in the tree
SELECT IF (
(SELECT COUNT(*) -1 FROM alm_1_simple) = 
(SELECT COUNT(parent_id) FROM alm_1_simple where parent_id != 0), TRUE, FALSE) 
AS PREVENT_LONG_CYCLES;


###### Manual Constraint Checking: Ensure that we have a Tree (no cycles)
### 

-- problem - MySQL disallows referencing the same temp table in a
-- temp query so I had to modify this a bit to work

DROP FUNCTION TreeTest

delimiter //
CREATE FUNCTION TreeTest() 
RETURNS CHAR(6) DETERMINISTIC
BEGIN
DROP TEMPORARY TABLE IF EXISTS TempTree;
DROP TEMPORARY TABLE IF EXISTS ParentTree;
CREATE TEMPORARY TABLE TempTree AS (SELECT id, parent_id FROM alm_1_simple);
CREATE TEMPORARY TABLE ParentTree AS (SELECT parent_id FROM alm_1_simple where parent_id != 0);
WHILE (SELECT COUNT(*) - 1 FROM TempTree) = (SELECT COUNT(parent_id) FROM ParentTree)
	DO 
		# MySQL disallows selecting from the same temporary table twice 
		# so instead of a sensible subquery
		# we will simply create a second table
		DELETE FROM TempTree
		WHERE TempTree.id
		NOT IN (SELECT parent_id
				FROM ParentTree as T2);
		DELETE FROM ParentTree;
		INSERT into ParentTree (parent_id)
		SELECT parent_id
		FROM TempTree WHERE parent_id != 0;  
END WHILE;
		IF NOT EXISTS (SELECT * FROM TempTree)
			THEN RETURN ('Tree ');
			ELSE RETURN ('Cycles');
		END IF;
END//


delimiter ;


## Here's How to RUN the TreeTest()
SELECT TreeTest()
	

############# Traversing your Tree

######## Upwards Traversal - Child to Ancestor	
## STORED PROCEDURE FOR UPWARDS TRAVERSAL		 
delimiter //
CREATE PROCEDURE UpTreeTraversal (IN current_id INTEGER)
DETERMINISTIC
BEGIN
CREATE TEMPORARY TABLE `traversalTest` (
  `tree_id` int(11) NOT NULL AUTO_INCREMENT,
  `id` int(11) NOT NULL DEFAULT '0',
  `parent_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`tree_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
WHILE EXISTS
	(SELECT *
	FROM alm_1_simple AS T1
	WHERE current_id = T1.id)
DO BEGIN
	INSERT INTO traversalTest (id, parent_id) SELECT id, parent_id from alm_1_simple where id = current_id;
	SET current_id = (SELECT T1.parent_id from alm_1_simple as T1 where current_id = T1.id);
END;
END WHILE;
SELECT * FROM traversalTest;
DROP TEMPORARY TABLE traversalTest;
END//

# Here is how we CALL THE Procedure
CALL UpTreeTraversal(291);

## Another method - more typical to Drupal style thinking
# which is Upwards Tree Traversal - via (Left Outer) Joins
# This is only going to really be good for a known level of JOINS.
# However, abstracting this to a programatically created query for an
# arbitrary number of levels could give you some flexibility.
# There will be performance impacts as the joins continue to add upn
SELECT level1.id As id_1, level2.id as id_2




