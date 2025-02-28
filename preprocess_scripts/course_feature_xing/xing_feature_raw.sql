-- sql_course_assessment_counts_12_25.csv
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


-- sql_course_forums_count_12_25.csv
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


