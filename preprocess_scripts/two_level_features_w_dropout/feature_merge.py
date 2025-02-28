import pandas as pd

# read in course featuer and assessment features
assessments_features = pd.read_csv("~/Stats/MOOC_Feature_Analysis/data/cleaned_data/engineered_assessment_df.csv")
xing_feature = pd.read_csv("/Users/daviddai/Stats/MOOC_Feature_Analysis/data/cleaned_data/xing_course_feature.csv")
graded_item_dropout_df = pd.read_csv("~/Stats/MOOC_Feature_Analysis/data/processed_data/dropout_percentage_per_item.csv")

# merge course features
temp_course_merge = xing_feature.merge(
    graded_item_dropout_df,
    left_on = "course_id",
    right_on = "course_id",
    how = "outer"
)

# merge assessment features
temp_course_merge = temp_course_merge.merge(
    assessments_features,
    left_on = ["course_id", "course_item_id"],
    right_on = ["course_id", "course_item_id"],
    how = "outer"
)

# select useful columns
temp_course_merge = temp_course_merge[
    ['course_id', 'course_days', 'forum_counts', 'assessment_counts',
       'asssignemnt_counts', 'required_review_counts', 'grading_types',
       'submission_types', 'course_item_id',
       'graded_item_order', 'num_of_items', 'dropout_percentage','is_graded',
       'quiz_is_graded', 'assessment_type_desc', 'assessment_passing_fraction',
       'global_item_content_type', 'global_item_time_commitment',
       'question_counts', 'checkbox_percentage', 'checkboxReflect_percentage',
       'codeExpression_percentage', 'math expression_percentage',
       'mcq_percentage', 'mcqReflect_percentage', 'reflect_percentage',
       'regex_percentage', 'single numeric_percentage',
       'text exact match_percentage', 'is_staff_graded']
].drop_duplicates()

# drop na values
dropout_w_course_assessment_feature = temp_course_merge.dropna(subset=["dropout_percentage", "is_graded", "course_days"])

# exclude columns with only 1 value
col_exclude = []
for colu in dropout_w_course_assessment_feature.columns:
    if len(dropout_w_course_assessment_feature[colu].unique()) < 2:
        col_exclude.append(colu)
dropout_w_course_assessment_feature.drop(columns=col_exclude, inplace=True)

# output csv
dropout_w_course_assessment_feature.to_csv("~//Stats/MOOC_Feature_Analysis/data/cleaned_data/dropout_percentage_w_course_assess_features.csv", index=False)