import pandas as pd

graded_item_dropout_df = pd.read_csv("~/Stats/MOOC_Feature_Analysis/data/processed_data/dropout_percentage_per_item.csv")
df_xing = pd.read_csv("~/Stats/MOOC_Feature_Analysis/data/cleaned_data/xing_course_feature.csv")
assessment = pd.read_csv("~/Stats/MOOC_Feature_Analysis/data/cleaned_data/engineered_assessment_df.csv")

# get first item dropout rate for each course
first_item_dropout_per_course = graded_item_dropout_df[graded_item_dropout_df['graded_item_order'] == 1]

# sanity check for each course has only 1 item
# print(max(first_item_dropout_per_course.groupby('course_id')['dropout_percentage'].count()))
print(f"Number of courses with only 1 item: {len(first_item_dropout_per_course)}")

# join Xing's features on courses
first_item_dropout_with_xing = first_item_dropout_per_course.merge(
    df_xing,
    on = 'course_id',
    how = 'left'
)

# select useful features from assessments
assessment_cleaned = assessment[['course_id', 'course_item_id', 'is_graded', 'quiz_is_graded', 'assessment_passing_fraction',
                                         'global_item_time_commitment',
                                          'question_counts', 'checkbox_percentage', 'checkboxReflect_percentage',
                                          'codeExpression_percentage', 'math expression_percentage',
                                          'mcq_percentage', 'mcqReflect_percentage', 'reflect_percentage',
                                          'regex_percentage', 'single numeric_percentage',
                                          'text exact match_percentage', 'is_staff_graded']].drop_duplicates()

# merge with features of first item (one third NA)
first_item_dropout_per_course = first_item_dropout_with_xing.merge(
    assessment_cleaned,
    left_on = ['course_id', 'course_item_id'],
    right_on = ['course_id', 'course_item_id'],
    how = 'left'
)

# join name of second course items
second_id_df = graded_item_dropout_df[graded_item_dropout_df['graded_item_order'] == 2][['course_id', 'course_item_id']]
second_id_df = second_id_df.rename(columns={'course_item_id': 'second_item_id'})
first_item_dropout_per_course = first_item_dropout_per_course.merge(
    second_id_df,
    on = 'course_id',
    how = 'left'
)

# join features of second course items
first_item_dropout_per_course = first_item_dropout_per_course.merge(
    assessment_cleaned,
    left_on = ['course_id', 'second_item_id'],
    right_on = ['course_id', 'course_item_id'],
    how = 'left'
)

# select and rename columns
first_item_dropout_w_features = first_item_dropout_per_course[
    ['course_id', 'course_item_id_x',
      'num_of_items', 'dropout_percentage', 'course_days', 'forum_counts',
       'assessment_counts', 'asssignemnt_counts', 'required_review_counts',
       'grading_types', 'submission_types', 'is_graded_x', 'quiz_is_graded_x',
       'assessment_passing_fraction_x', 'global_item_time_commitment_x',
       'question_counts_x', 'checkbox_percentage_x',
       'checkboxReflect_percentage_x', 'codeExpression_percentage_x',
       'math expression_percentage_x', 'mcq_percentage_x',
       'mcqReflect_percentage_x', 'reflect_percentage_x', 'regex_percentage_x',
       'single numeric_percentage_x', 'text exact match_percentage_x',
       'is_staff_graded_x', 'second_item_id',
       'is_graded_y', 'quiz_is_graded_y', 'assessment_passing_fraction_y',
       'global_item_time_commitment_y', 'question_counts_y',
       'checkbox_percentage_y', 'checkboxReflect_percentage_y',
       'codeExpression_percentage_y', 'math expression_percentage_y',
       'mcq_percentage_y', 'mcqReflect_percentage_y', 'reflect_percentage_y',
       'regex_percentage_y', 'single numeric_percentage_y',
       'text exact match_percentage_y', 'is_staff_graded_y']
].drop_duplicates().reset_index(drop=True)

first_item_dropout_w_features.columns = ['course_id', 'first_item_id',
       'num_of_items', 'dropout_percentage', 'course_days', 'forum_counts',
       'assessment_counts', 'asssignemnt_counts', 'required_review_counts',
       'grading_types', 'submission_types', 'is_graded_x', 'quiz_is_graded_x',
       'assessment_passing_fraction_x', 'global_item_time_commitment_x',
       'question_counts_x', 'checkbox_percentage_x',
       'checkboxReflect_percentage_x', 'codeExpression_percentage_x',
       'math expression_percentage_x', 'mcq_percentage_x',
       'mcqReflect_percentage_x', 'reflect_percentage_x', 'regex_percentage_x',
       'single numeric_percentage_x', 'text exact match_percentage_x',
       'is_staff_graded_x', 'second_item_id',
       'is_graded_y', 'quiz_is_graded_y', 'assessment_passing_fraction_y',
       'global_item_time_commitment_y', 'question_counts_y',
       'checkbox_percentage_y', 'checkboxReflect_percentage_y',
       'codeExpression_percentage_y', 'math expression_percentage_y',
       'mcq_percentage_y', 'mcqReflect_percentage_y', 'reflect_percentage_y',
       'regex_percentage_y', 'single numeric_percentage_y',
       'text exact match_percentage_y', 'is_staff_graded_y']

# remove NA
first_dropout_no_na = first_item_dropout_w_features.dropna().reset_index()
# remove duplicates of course id
first_dropout_no_na = first_dropout_no_na.drop_duplicates(subset=['course_id'], keep='first')

# only 101 courses left
print(f"Number of courses left: {len(first_dropout_no_na)}")
# output first_droupout_percent
first_dropout_no_na.to_csv('/data/cleaned_data/clean_first_dropout_w_features.csv', index=False)