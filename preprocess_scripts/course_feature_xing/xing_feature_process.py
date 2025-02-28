import pandas as pd

# df read in
df_1 = pd.read_csv('data/raw_data/sql_course_assessment_counts_12_25.csv')
df_2 = pd.read_csv('data/raw_data/sql_course_forums_count_12_25.csv')
df = pd.merge(df_1, df_2, on=['course_id', 'course_branch_id'], how='inner')

# select course related columns
df = df[['course_id', 'course_branch_id','on_demand_session_id','on_demand_sessions_start_ts', 'on_demand_sessions_end_ts',
         'unique_forum_count', 'unique_assessment_count',
       'unique_peer_assignment_count', 'unique_programming_assignment_count', 'total_required_review_count',
       'max_peer_assignment_types', 'max_submission_types']].drop_duplicates()

# add course date by using 'on_demand_sessions_start_ts', 'on_demand_sessions_end_ts'
df['on_demand_sessions_start_ts'] = pd.to_datetime(df['on_demand_sessions_start_ts'])
df['on_demand_sessions_end_ts'] = pd.to_datetime(df['on_demand_sessions_end_ts'])
df['course_days'] = (df['on_demand_sessions_end_ts'] - df['on_demand_sessions_start_ts']).dt.days
df['asssignemnt_count'] = df['unique_peer_assignment_count'] + df['unique_programming_assignment_count']

# aggregate on a course level
df_xing = df.groupby(['course_id'])[['course_days','unique_forum_count', 'unique_assessment_count',
       'asssignemnt_count', 'total_required_review_count','max_peer_assignment_types',
       'max_submission_types']].mean().reset_index()
df_xing.columns = ['course_id', 'course_days', 'forum_counts', 'assessment_counts',
       'asssignemnt_counts', 'required_review_counts','grading_types',
       'submission_types']

# export to csv
df_xing.to_csv("/Users/daviddai/Stats/MOOC_Feature_Analysis/data/cleaned_data/xing_course_feature.csv", index=False)