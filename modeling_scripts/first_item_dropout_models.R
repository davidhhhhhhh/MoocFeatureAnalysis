# first item dropout analysis
# Load necessary library
library(MASS)
library(dplyr)

# read in data and filtering-----------
b = read.csv("data/cleaned_data/clean_first_dropout_w_features.csv")
all_id = read.csv("data/raw_data/count_students_course_item_grades_3-6.csv")
b_filtered = b[b$course_id %in% all_id$course_id,]

# deduplicate course items 
b_cleaned <- b_filtered %>%
  group_by(course_id, first_item_id) %>%  # Group by course_id and course_item_id
  slice(1) %>%  # Keep only the first row in each group
  ungroup()  # Remove grouping


# Define columns to exclude (non-useful IDs)
exclude_cols <- c("index", "course_id", "first_item_id", "second_item_id", "dropout_percentage")

# Select relevant columns
feature_cols <- setdiff(names(b_cleaned), exclude_cols)

# Subset dataset
b_selected <- b_cleaned[, c(feature_cols, "dropout_percentage")]

# Identify and remove columns with only one unique value
constant_cols <- names(b_selected)[sapply(b_selected, function(col) length(unique(col)) == 1)]
b_selected <- b_selected[, !names(b_selected) %in% constant_cols]
b_selected$assignment_counts = b_selected$asssignemnt_counts
b_selected$single_numeric_percentage_x = b_selected$single.numeric_percentage_x
b_selected$single_numeric_percentage_y = b_selected$single.numeric_percentage_y

# Standardize all columns except the response variable (dropout_percentage)
b_selected_scaled <- b_selected %>%
  mutate(across(
    .cols = c(
      num_of_items, course_days, forum_counts, assessment_counts, 
      asssignemnt_counts, required_review_counts, grading_types, submission_types,
      assessment_passing_fraction_x, global_item_time_commitment_x, question_counts_x,
      checkbox_percentage_x, reflect_percentage_x, single_numeric_percentage_x,
      assessment_passing_fraction_y, global_item_time_commitment_y, question_counts_y,
      checkbox_percentage_y, single_numeric_percentage_y
    ),
    .fns = ~ as.numeric(scale(.))
  ))

# Fit full model excluding dropout_percentage as predictor, exclude ---------
# mcq percentage which is default
full_model <- model <- lm(
  dropout_percentage ~ num_of_items + course_days + forum_counts + assessment_counts + 
    asssignemnt_counts + required_review_counts + grading_types + submission_types +
    assessment_passing_fraction_x + global_item_time_commitment_x + question_counts_x +
    checkbox_percentage_x + reflect_percentage_x + single_numeric_percentage_x +
    assessment_passing_fraction_y + global_item_time_commitment_y + question_counts_y +
    checkbox_percentage_y + single_numeric_percentage_y,
  data = b_selected_scaled
)

# Perform stepwise variable selection using AIC
stepwise_model <- stepAIC(full_model, direction = "both")

# Display summary of the final model
summary(stepwise_model)

# Model for course level only -------
course_level_model = lm(dropout_percentage ~ num_of_items + course_days + forum_counts + assessment_counts + 
                          asssignemnt_counts + required_review_counts + grading_types + submission_types,
                        data = b_selected_scaled)
stepwise_model_course <- stepAIC(course_level_model, direction = "both")
summary(stepwise_model_course)

# Model for assessment level only --------
assessment_level_model = lm(dropout_percentage ~ assessment_passing_fraction_x + global_item_time_commitment_x + question_counts_x +
                              checkbox_percentage_x + reflect_percentage_x + single_numeric_percentage_x +
                              assessment_passing_fraction_y + global_item_time_commitment_y + question_counts_y +
                              checkbox_percentage_y + single_numeric_percentage_y,
                        data = b_selected_scaled)
stepwise_model_assessment <- stepAIC(assessment_level_model, direction = "both")
summary(stepwise_model_assessment)


# Generate diagnostic plots
par(mfrow = c(2, 2))  # Arrange plots in a 2x2 grid
plot(stepwise_model)      # Default diagnostic plots



