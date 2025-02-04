SELECT table_name 
from information_schema.tables
where table_schema = 'public'
order by 
	table_name ;

SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable AS not_null,
    col_description(pg_class.oid, ordinal_position) AS column_comment
FROM 
    information_schema.columns
JOIN 
    pg_class ON table_name = relname
WHERE 
    table_schema = 'public'
ORDER BY 
    table_name, ordinal_position;

 select
 	a.course_id, 
 	a.course_branch_id, 
 	a.course_branch_changes_description,
 	a.authoring_course_branch_launched_ts,
 	b.course_module_id,
 	b.course_branch_module_order,
 	b.course_branch_module_name,
 	b.course_branch_module_desc,
 	c.*,
 	d.*,
 	e.*
 FROM
 	course_branches as a
 join 
 	course_branch_modules as b on a.course_branch_id = b.course_branch_id
 join 
 	courses as c on c.course_id = a.course_id
 join 
 	course_branch_lessons as d on d.course_branch_id = b.course_branch_id
 	and d.course_module_id = b.course_module_id
 join 
 	course_branch_items as e on e.course_branch_id = b.course_branch_id and 
 	e.course_lesson_id = d.course_lesson_id;
 

select count(distinct course_id)
 from  course_marketing_performance_summary cmps;

select count(distinct user_or_cookie_id)
 from  course_marketing_performance_summary cmps;

select count(distinct penn_user_id)
 from  course_grades cbg ;

select count(distinct penn_user_id) 
from course_branch_grades cbg;

select count(distinct penn_user_id) 
from course_item_grades cg;

select distinct(course_passing_state_id, course_passing_state_desc)
from course_passing_states cps;

SELECT 
    cg.course_id,
    c.course_name,
    AVG(cg.course_grade_overall_passed_items) AS avg_passed_items,
    AVG(cg.course_grade_overall) AS avg_course_grade,
    AVG(cg.course_passing_state_id) AS avg_passing_rate
FROM 
    course_grades AS cg
JOIN 
    courses AS c ON c.course_id = cg.course_id
WHERE 
    cg.course_passing_state_id < 2
GROUP BY 
    cg.course_id, c.course_name;

   
SELECT 
    c.course_id,
    SUM(CASE WHEN b.is_enrollment_completed THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS completion_ratio
FROM 
    courses AS c
JOIN 
    course_marketing_performance_summary AS b ON c.course_id = b.course_id
GROUP BY 
    c.course_id;

rollback;

SELECT 
    course_id,
    penn_user_id,
    SUM(CASE WHEN course_item_grade_overall > 0 THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS avg_item_tried_ratio
FROM 
    course_item_grades AS cig
GROUP BY 
    course_id, penn_user_id;

SELECT 
	avg(avg_item_tried_ratio) as avg_value,
    MIN(avg_item_tried_ratio) AS min_value,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY avg_item_tried_ratio) AS first_quartile,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_item_tried_ratio) AS median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY avg_item_tried_ratio) AS third_quartile,
    MAX(avg_item_tried_ratio) AS max_value
FROM 
    (SELECT 
        course_id,
        penn_user_id,
        SUM(CASE WHEN course_item_grade_overall > 0 THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS avg_item_tried_ratio
     FROM course_item_grades AS cig
     GROUP BY course_id, penn_user_id) AS summary_table;

SELECT 
	avg(avg_item_tried_ratio) as avg_value,
    MIN(avg_item_tried_ratio) AS min_value,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY avg_item_tried_ratio) AS first_quartile,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_item_tried_ratio) AS median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY avg_item_tried_ratio) AS third_quartile,
    MAX(avg_item_tried_ratio) AS max_value
FROM 
    (SELECT 
        course_id,
        penn_user_id,
        SUM(course_item_grade_overall) * 1.0 / COUNT(*) AS avg_item_tried_ratio
     FROM course_item_grades AS cig
     GROUP BY course_id, penn_user_id) AS summary_table;

    
SELECT 
    AVG(avg_item_tried_ratio) AS avg_value,
    MIN(avg_item_tried_ratio) AS min_value,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY avg_item_tried_ratio) AS first_quartile,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_item_tried_ratio) AS median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY avg_item_tried_ratio) AS third_quartile,
    MAX(avg_item_tried_ratio) AS max_value
FROM 
    (SELECT 
        cig.course_id,
        cig.penn_user_id,
        SUM(CASE WHEN cig.course_item_grade_overall > 0 THEN 1 ELSE 0 END) * 1.0 / COUNT(ci.course_item_id) AS avg_item_tried_ratio
     FROM 
        course_item_grades AS cig
     JOIN 
        course_items AS ci 
        ON cig.course_id = ci.course_id
     GROUP BY 
        cig.course_id, cig.penn_user_id) AS summary_table;

       
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
    ordered_items.course_module_id,
    ordered_items.course_module_order,
    ordered_items.course_lesson_id,
    ordered_items.course_lesson_order,
    ordered_items.course_lesson_name,
    ordered_items.course_item_id,
    ordered_items.course_item_name,
    ordered_items.course_item_order,
    ordered_items.course_item_optional,
    COALESCE(aggregated_grades.unique_user_count, 0) AS unique_user_count -- Include unique user count
FROM 
    (
        SELECT 
            cm.course_id,
            c.course_slug,
            c.course_name,
            cm.course_module_id,
            cm.course_module_order,
            cl.course_lesson_id,
            cl.course_lesson_order,
            cl.course_lesson_name,
            ci.course_item_id,
            ci.course_item_order,
            ci.course_item_name,
            ci.course_item_optional
        from 
        	course_modules cm
        left join 
        	courses c
        	on cm.course_id = c.course_id
       	join
       		course_lessons cl
       		ON cm.course_id = cl.course_id and 
       		cm.course_module_id = cl.course_module_id
       	join 
       		course_items ci
       		on cm.course_id = ci.course_id and 
       		cl.course_lesson_id = ci.course_lesson_id
        ORDER BY 
            ci.course_id,
            cm.course_module_order,
            cl.course_lesson_order,
            ci.course_item_order
    ) AS ordered_items
LEFT JOIN 
    aggregated_grades
ON 
	ordered_items.course_id = aggregated_grades.course_id and
    ordered_items.course_item_id = aggregated_grades.course_item_id;
   
-- course_branch_item version
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
           
select count(distinct cbg.course_branch_id) from course_branch_grades cbg;

select count(distinct cg.penn_user_id) from course_grades cg;

select count(distinct cig.penn_user_id) from course_item_grades cig ;

select count(distinct penn_assessments_user_id) from assessment_actions aa;

select distinct course_item_type_id from course_item_types cit;

select distinct course_item_type_id from course_items;

-- basic course features from Xing 2019 extraction 
-- query executed by steps
-- Step 1: Basic joins for the main structure
SELECT 
    c.course_id,
    cb.course_branch_id,
    cbm.course_module_id,
    cbl.course_lesson_id,
    cbi.course_item_id,
    ods.on_demand_session_id,
    ods.on_demand_sessions_start_ts,
    ods.on_demand_sessions_end_ts
FROM 
    courses c
JOIN 
    course_branches cb 
    ON c.course_id = cb.course_id
JOIN 
    course_branch_modules cbm 
    ON cbm.course_branch_id = cb.course_branch_id
JOIN 
    course_branch_lessons cbl 
    ON cbl.course_branch_id = cb.course_branch_id 
    AND cbl.course_module_id = cbm.course_module_id
JOIN 
    course_branch_items cbi 
    ON cbi.course_branch_id = cb.course_branch_id 
    AND cbi.course_lesson_id = cbl.course_lesson_id
JOIN 
    on_demand_sessions ods 
    ON ods.course_id = c.course_id 
    AND ods.course_branch_id = cb.course_branch_id;

select * from on_demand_sessions ods;
   
-- Step 2: Include discussion forum count
SELECT 
    c.course_id,
    cb.course_branch_id,
    cbm.course_module_id,
    cbl.course_lesson_id,
    cbi.course_item_id,
    ods.on_demand_session_id,
    ods.on_demand_sessions_start_ts,
    ods.on_demand_sessions_end_ts,
    COUNT(DISTINCT df.discussion_forum_id) AS unique_forum_count
FROM 
    courses c
JOIN 
    course_branches cb 
    ON c.course_id = cb.course_id
JOIN 
    course_branch_modules cbm 
    ON cbm.course_branch_id = cb.course_branch_id
JOIN 
    course_branch_lessons cbl 
    ON cbl.course_branch_id = cb.course_branch_id 
    AND cbl.course_module_id = cbm.course_module_id
JOIN 
    course_branch_items cbi 
    ON cbi.course_branch_id = cb.course_branch_id 
    AND cbi.course_lesson_id = cbl.course_lesson_id
JOIN 
    on_demand_sessions ods 
    ON ods.course_id = c.course_id 
    AND ods.course_branch_id = cb.course_branch_id
LEFT JOIN 
    discussion_course_forums df 
    ON df.course_branch_id = cb.course_branch_id
GROUP BY 
    c.course_id, cb.course_branch_id, cbm.course_module_id, cbl.course_lesson_id, cbi.course_item_id, ods.on_demand_session_id, ods.on_demand_sessions_start_ts, ods.on_demand_sessions_end_ts;

-- Step 3 to 5.2 Combined Query with FULL OUTER JOIN and Correct Keys
SELECT 
    cia.course_id,
    cia.course_branch_id,
    COALESCE(cia.unique_assessment_count, 0) AS unique_assessment_count,
    COALESCE(pa.unique_peer_assignment_count, 0) AS unique_peer_assignment_count,
    COALESCE(pg.unique_programming_assignment_count, 0) AS unique_programming_assignment_count,
    COALESCE(cra.total_required_review_count, 0) AS total_required_review_count,
    COALESCE(cat.max_peer_assignment_types, 0) AS max_peer_assignment_types,
    COALESCE(sch.max_submission_types, 0) AS max_submission_types
FROM 
    -- Base table: Unique assessments
    (
        SELECT 
        	cb.course_id,
        	cb.course_branch_id,
            COUNT(DISTINCT cia.assessment_id) AS unique_assessment_count
        FROM 
            course_branch_item_assessments cia
        right join
        	course_branches cb
        	on cia.course_branch_id = cb.course_branch_id
        GROUP BY 
            cb.course_id,
        	cb.course_branch_id
    ) cia
FULL OUTER JOIN 
    -- Subquery for peer assignments
    (
        SELECT 
            cpa.course_id,
            COUNT(DISTINCT cpa.peer_assignment_id) AS unique_peer_assignment_count
        FROM 
            course_item_peer_assignments cpa
        GROUP BY 
            cpa.course_id
    ) pa
    ON pa.course_id = cia.course_id
FULL OUTER JOIN 
    -- Subquery for programming assignments
    (
        SELECT 
            cpg.course_id,
            COUNT(DISTINCT cpg.programming_assignment_id) AS unique_programming_assignment_count
        FROM 
            course_item_programming_assignments cpg
        GROUP BY 
            cpg.course_id
    ) pg
    ON pg.course_id = cia.course_id
FULL OUTER JOIN 
    -- Subquery for max peer assignment types
    (
        SELECT 
            cipa.course_id,
            COUNT(DISTINCT cpa.peer_assignment_type) AS max_peer_assignment_types
        FROM 
            peer_assignments cpa
        JOIN 
            course_item_peer_assignments cipa 
            ON cpa.peer_assignment_id = cipa.peer_assignment_id
        GROUP BY 
            cipa.course_id
    ) cat
    ON cat.course_id = cia.course_id
FULL OUTER JOIN 
    -- Subquery for max submission types
    (
        SELECT 
            cipa.course_id,
            COUNT(DISTINCT ps.peer_assignment_submission_schema_part_type) AS max_submission_types
        FROM 
            peer_assignment_submission_schema_parts ps
        JOIN 
            course_item_peer_assignments cipa 
            ON ps.peer_assignment_id = cipa.peer_assignment_id
        GROUP BY 
            cipa.course_id
    ) sch
    ON sch.course_id = cia.course_id
full outer JOIN 
    (
        -- Subquery to sum required review count for each course item
        SELECT 
        	cipa.course_id,
            SUM(cpa.peer_assignment_required_review_count) AS total_required_review_count
        FROM 
            peer_assignments cpa
        join
        	course_item_peer_assignments cipa 
        	on cpa.peer_assignment_id = cipa.peer_assignment_id
        GROUP BY 
            cipa.course_id
    ) cra
    ON cra.course_id = cia.course_id;
   
-- course items feature extraction 
select 
	cb.course_id, 
	cbi.course_branch_id,
	cbi.course_item_id,
	cbi.course_branch_item_name,
	cbi.is_graded,
	cbi.quiz_assessment_id,
	cbi.quiz_is_graded,
	at2.assessment_type_desc,
	a.assessment_passing_fraction,
	a.assessment_feedback_configuration,
	aaq.assessment_question_id,
	aaq.assessment_question_cuepoint,
	aaq.assessment_question_order,
	aaq.assessment_question_weight,
	aaq.assessment_question_extra_credit,
	aqt.assessment_question_type_desc,
	aq.assessment_question_prompt,
	ao.assessment_option_id,
	ao.assessment_option_display,
	ao.assessment_option_feedback,
	ao.assessment_option_correct,
	ao.assessment_option_index,
	cbi.global_item_id,
	gi.global_item_name,
	gi.global_item_content_type,
	cbi.global_item_time_commitment
from 
	course_branch_items cbi
left join
	course_branches cb 
	on cbi.course_branch_id = cb.course_branch_id 
left join 
	assessments a
	on a.assessment_id = cbi.quiz_assessment_id
left join 
	assessment_types at2 
	on a.assessment_type_id = at2.assessment_type_id
left join 
	assessment_assessments_questions aaq 
	on aaq.assessment_id = cbi.quiz_assessment_id
left join 
	assessment_questions aq 
	on aaq.assessment_question_id = aq.assessment_question_id
left join 
	assessment_question_types aqt 
	on aq.assessment_question_type_id = aqt.assessment_question_type_id
left join 
	assessment_options ao 
	on aaq.assessment_question_id = ao.assessment_question_id
left join 
	global_items gi 
	on gi.global_item_id = cbi.global_item_id 
order by 
	cbi.course_branch_id,
	cbi.quiz_assessment_id,
	aaq.assessment_question_order,
	ao.assessment_option_index;

-- check quiz assessment id empty but graded
select 
	cbi.course_branch_id,
	cbi.course_item_id,
	cbi.course_branch_item_name,
	cbi.item_weight_in_course_branch_percentage,
	cbi.global_item_id,
	gi.global_item_content_type,
	cbi.quiz_assessment_id,
	cbi.quiz_is_graded 
from 
	course_branch_items cbi
join 
	global_items gi 
	on gi.global_item_id = cbi.global_item_id
where 
	cbi.is_graded is true 
	and cbi.quiz_assessment_id is null;

select * from course_item_grades;

   
   
   
   
   