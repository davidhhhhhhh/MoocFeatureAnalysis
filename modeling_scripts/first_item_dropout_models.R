# first item dropout analysis
# Load necessary library
library(MASS)
library(dplyr)

# read in data and filtering
b = read.csv("data/cleaned_data/clean_first_dropout_w_features.csv")
all_id = read.csv("data/raw_data/count_students_course_item_grades_3-6.csv")
b_filtered = b[b$course_id %in% all_id$course_id,]

# deduplicate course items 
b_cleaned <- b_filtered %>%
  group_by(course_id, first_item_id) %>%  # Group by course_id and course_item_id
  slice(1) %>%  # Keep only the first row in each group
  ungroup()  # Remove grouping

# Define categorical columns
categorical_cols <- c("grading_types", "submission_types")

# Define columns to exclude (non-useful IDs)
exclude_cols <- c("index", "course_id", "first_item_id", "second_item_id", "dropout_percentage")

# Select relevant columns
feature_cols <- setdiff(names(b_cleaned), exclude_cols)

# Subset dataset
b_selected <- b_cleaned[, c(feature_cols, "dropout_percentage")]

# Identify and remove columns with only one unique value
constant_cols <- names(b_selected)[sapply(b_selected, function(col) length(unique(col)) == 1)]
b_selected <- b_selected[, !names(b_selected) %in% constant_cols]

# Convert categorical variables to factors
for (col in categorical_cols) {
  if (col %in% names(b_selected)) {
    b_selected[[col]] <- as.factor(b_selected[[col]])
  }
}

# Fit full model excluding dropout_percentage as predictor
full_model <- lm(dropout_percentage ~ ., data = b_selected)

# Perform stepwise variable selection using AIC
stepwise_model <- stepAIC(full_model, direction = "both")

# Display summary of the final model
summary(stepwise_model)

# Generate diagnostic plots
par(mfrow = c(2, 2))  # Arrange plots in a 2x2 grid
plot(stepwise_model)      # Default diagnostic plots



