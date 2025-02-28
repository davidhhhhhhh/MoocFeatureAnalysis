-- sql_course_branch_item_user_trend_1_8.csv
-- Step 1: Aggregate course_item_grades table
WITH aggregated_grades AS (
    SELECT 
    	course_id,
        course_item_id,
        COUNT(DISTINCT penn_user_id) AS unique_user_count -- Count of unique students
    FROM 
        course_item_grades
    GROUP BY 
        course_id,
        course_item_id
)
-- Step 2: Join aggregated data with the ordered dataset
SELECT 
    ordered_items.course_id,
    ordered_items.course_slug,
    ordered_items.course_name,
    ordered_items.course_branch_id,
    ordered_items.course_module_id,
    ordered_items.course_branch_module_order,
    ordered_items.course_lesson_id,
    ordered_items.course_branch_lesson_order,
    ordered_items.course_item_id,
    ordered_items.course_branch_item_name,
    ordered_items.course_branch_item_order,
    ordered_items.is_graded,
    ordered_items.course_branch_item_optional,
    ordered_items.course_branch_item_lecture_duration_ms,
    ordered_items.quiz_is_graded,
    ordered_items.item_weight_in_course_branch_percentage,
    COALESCE(aggregated_grades.unique_user_count, 0) AS unique_user_count -- Include unique user count
FROM 
    (
        SELECT 
            cb.course_id,
            c.course_slug,
            c.course_name,
            cbm.course_branch_id,
            cbm.course_module_id,
            cbm.course_branch_module_order,
            cbl.course_lesson_id,
            cbl.course_branch_lesson_order,
            cbi.course_item_id,
            cbi.course_branch_item_order,
            cbi.course_branch_item_name,
            cbi.is_graded,
            cbi.course_branch_item_optional,
            cbi.course_branch_item_lecture_duration_ms,
            cbi.quiz_is_graded,
            cbi.item_weight_in_course_branch_percentage
        from 
        	course_branch_modules cbm
       	join 
       		course_branches cb
       		on cbm.course_branch_id = cb.course_branch_id
        join 
        	courses c
        	on cb.course_id = c.course_id
       	join
       		course_branch_lessons cbl
       		ON cbm.course_branch_id = cbl.course_branch_id and 
       		cbm.course_module_id = cbl.course_module_id
       	join 
       		course_branch_items cbi
       		on cbm.course_branch_id = cbi.course_branch_id and 
       		cbl.course_lesson_id = cbi.course_lesson_id
    ) AS ordered_items
LEFT JOIN 
    aggregated_grades
ON 
	ordered_items.course_id = aggregated_grades.course_id and
    ordered_items.course_item_id = aggregated_grades.course_item_id;

-- sql_course_item_grades_1_21.csv
select * from course_item_grades;