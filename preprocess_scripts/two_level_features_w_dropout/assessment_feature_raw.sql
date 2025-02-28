-- engineered_assessment_df.csv
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