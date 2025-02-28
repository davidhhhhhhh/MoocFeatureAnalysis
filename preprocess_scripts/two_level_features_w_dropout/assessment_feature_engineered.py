import pandas as pd

# read in raw data
assessment_df = pd.read_csv('data/raw_data/sql_assessments_1_25.csv')

# Assuming assessment_df is already loaded
# Feature 1: Count of assessment_question_id in each course_item_id
assessment_df['question_counts'] = (
    assessment_df.groupby(['course_branch_id', 'course_item_id'])['assessment_question_id']
    .transform(lambda x: x.notnull().sum())
)

# Feature 2: Distribution of assessment_question_type_desc within each course_item_id
# First, count the occurrences of each assessment_question_type_desc in each course_item_id
type_counts = (
    assessment_df.groupby(['course_branch_id', 'course_item_id', 'assessment_question_type_desc'])['assessment_question_id']
    .count()
    .reset_index(name='type_count')
)

# Calculate the total questions in each course_item_id
total_counts = (
    assessment_df.groupby(['course_branch_id', 'course_item_id'])['assessment_question_id']
    .count()
    .reset_index(name='total_questions')
)

# Merge the type counts with the total counts
type_distribution = pd.merge(type_counts, total_counts, on=['course_branch_id', 'course_item_id'])

# Calculate the percentage for each question type
type_distribution['type_percentage'] = (
    type_distribution['type_count'] / type_distribution['total_questions']
)

# Pivot the type_distribution table to create columns for each question type's percentage
pivoted_type_distribution = type_distribution.pivot_table(
    index=['course_branch_id', 'course_item_id'],
    columns='assessment_question_type_desc',
    values='type_percentage',
    fill_value=0
).reset_index()

# Rename the columns to include "_percentage" suffix
pivoted_type_distribution = pivoted_type_distribution.rename(
    columns=lambda x: f"{x}_percentage" if ((x != 'course_item_id') and (x != 'course_branch_id')) else x
)

# Merge the pivoted table back into the original DataFrame
assessment_df = pd.merge(
    assessment_df,
    pivoted_type_distribution,
    on=['course_branch_id', 'course_item_id'],
    how='left'
)

# Drop rows where 'global_item_content_type' is 'placeholder'
assessment_df = assessment_df[assessment_df['global_item_content_type'] != 'placeholder']

# Drop rows where 'assessment_type_desc' is NaN
assessment_df = assessment_df.dropna(subset=['assessment_type_desc'])

# Create a dummy variable 'is_staff_graded'
assessment_df['is_staff_graded'] = (assessment_df['global_item_content_type'] == 'staffGraded').astype(int)

# save to csv
assessment_df.to_csv('data/engineered_data/assessment_feature_engineered.csv', index=False)
