# first item dropout analysis
a = read.csv("data/cleaned_data/clean_first_dropout_w_features.csv")

# Load necessary library
library(MASS)

# Define categorical columns
categorical_cols <- c("grading_types", "submission_types")

# Define columns to exclude (non-useful IDs)
exclude_cols <- c("index", "course_id", "first_item_id", "second_item_id", "dropout_percentage")

# Select relevant columns
feature_cols <- setdiff(names(a), exclude_cols)

# Subset dataset
a_selected <- a[, c(feature_cols, "dropout_percentage")]

# Identify and remove columns with only one unique value
constant_cols <- names(a_selected)[sapply(a_selected, function(col) length(unique(col)) == 1)]
a_selected <- a_selected[, !names(a_selected) %in% constant_cols]

# Convert categorical variables to factors
for (col in categorical_cols) {
  if (col %in% names(a_selected)) {
    a_selected[[col]] <- as.factor(a_selected[[col]])
  }
}

# Fit full model excluding dropout_percentage as predictor
full_model <- lm(dropout_percentage ~ ., data = a_selected)

# Perform stepwise variable selection using AIC
stepwise_model <- stepAIC(full_model, direction = "both")

# Display summary of the final model
summary(stepwise_model)

# Fit the model with the selected variables
first_model <- lm(dropout_percentage ~ num_of_items + course_days + forum_counts + 
                    assessment_counts + question_counts_x + mcq_percentage_x + 
                    single.numeric_percentage_x + global_item_time_commitment_y + 
                    checkbox_percentage_y + mcq_percentage_y, data = a_selected)

# Generate diagnostic plots
par(mfrow = c(2, 2))  # Arrange plots in a 2x2 grid
plot(final_model)      # Default diagnostic plots

summary(first_model)


