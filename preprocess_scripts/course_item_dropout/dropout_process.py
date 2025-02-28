import pandas as pd

# data read in
course_item_grades = pd.read_csv('~/Stats/MOOC_Feature_Analysis/data/raw_data/sql_course_item_grades_1_21.csv')
course_items = pd.read_csv('~/Stats/MOOC_Feature_Analysis/data/raw_data/sql_course_branch_item_user_trend_1_8.csv')

# filter graded items and print the shape pre and post filtering
graded_items = course_items[course_items['is_graded'] == True]
print(f"Number of course items before filtering: {course_items.shape[0]}")
print(f"Number of graded course items after filtering: {graded_items.shape[0]}")

# itentify courses with branch changes order of course items
a = graded_items.groupby(['course_id', 'course_item_id']).agg({
    'course_branch_module_order': 'nunique',
    'course_branch_lesson_order': 'nunique',
    'course_branch_item_order': 'nunique'
}).reset_index()

# Remove rows where any of the three nunique values is greater than 1
filtered_a = a[((a['course_branch_module_order'] > 1) |
                 (a['course_branch_lesson_order'] > 1) |
                 (a['course_branch_item_order'] > 1))]

# exclude course items in courses that have branches updates changing its order, 19 courses with 127 items
graded_items_clean = graded_items[~graded_items['course_id'].isin(filtered_a.course_id.unique())]

# create item order and num of items df 
item_order = graded_items_clean[['course_id', 'course_item_id', 'course_branch_module_order', 'course_branch_lesson_order', 'course_branch_item_order']].drop_duplicates()
item_order = item_order.sort_values(by=['course_id', 'course_branch_module_order', 'course_branch_lesson_order', 'course_branch_item_order'])
item_order['graded_item_order'] = item_order.groupby(['course_id']).cumcount() + 1
item_order['num_of_items'] = item_order.groupby(['course_id'])['course_item_id'].transform('count')

# merge item order and num items back to course item grades
course_item_grades = course_item_grades.merge(
    item_order[['course_id', 'course_item_id', 'graded_item_order', 'num_of_items']],
    on=['course_id', 'course_item_id'],
    how='left'
)

# drop grades on courses branch updates that changed order of items, about 20 percent of grades
course_item_grades = course_item_grades.dropna(subset=['graded_item_order'])

# check the last item each student done
last_item_per_student = course_item_grades.groupby(['course_id', 'penn_user_id'])['graded_item_order'].max().reset_index()
last_item_per_student = last_item_per_student.rename(columns={'graded_item_order': 'last_item_order'})

# merge last item df back to course_item grades
course_item_grades = course_item_grades.merge(
    last_item_per_student,
    on=['course_id', 'penn_user_id']
)

# dropout_item_id is the last item each student done 
course_item_grades['dropout_item_id'] = course_item_grades.apply(
    lambda row: None if row['last_item_order'] == row['num_of_items']
    else row['course_item_id'] if row['graded_item_order'] == row['last_item_order'] else None,
    axis=1
)

# do the dropout count for each course items
dropout_count = course_item_grades[~course_item_grades['dropout_item_id'].isna()] \
.groupby(['course_id', 'dropout_item_id'])['penn_user_id'].nunique().reset_index(name='dropout_count')

# calculate the total count of student in a course
total_count = course_item_grades.groupby(['course_id'])['penn_user_id'].nunique().reset_index(name='total_count')

# merge two dfs for dropout percentage
dropout_percentage = dropout_count.merge(total_count, on='course_id')

# calculate dropout percentage
dropout_percentage['dropout_percentage'] = dropout_percentage['dropout_count'] / dropout_percentage['total_count']

# create the dropout percentage df for each graded course items
graded_item_dropout_df = item_order.merge(
    dropout_percentage[['course_id', 'dropout_item_id','dropout_count', 'total_count', 'dropout_percentage']],
    left_on=['course_id','course_item_id'],
    right_on=['course_id', 'dropout_item_id'],
    how='left'
)

# for items that have no dropout, fill the dropout percentage with 0
graded_item_dropout_df['dropout_percentage'] = graded_item_dropout_df['dropout_percentage'].fillna(0)

# sanity check for total dropout_percentage not exceed 1
# print(max(graded_item_dropout_df.groupby('course_id')['dropout_percentage'].sum()))

# save the df
graded_item_dropout_df.to_csv('~/Stats/MOOC_Feature_Analysis/data/processed_data/dropout_percentage_per_item.csv', index=False)
