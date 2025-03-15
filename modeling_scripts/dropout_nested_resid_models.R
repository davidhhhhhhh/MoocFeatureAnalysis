# Hierarchical residual modeling 
# read in data and cleaning -----
a = read.csv("data/cleaned_data/dropout_percentage_w_course_assess_features.csv")

# Remove last course item given dropout percentage being zero
library(dplyr)

a_filtered <- a %>%
  group_by(course_id) %>%                  # Group by course_id
  arrange(graded_item_order, .by_group = TRUE) %>%  # Sort within each group
  filter(graded_item_order != max(graded_item_order)) %>%  # Remove max graded_item_order
  ungroup()  # Remove grouping for further processing

# include only courses with grades data
all_id = read.csv("data/raw_data/count_students_course_item_grades_3-6.csv")
a_filtered = a_filtered[a_filtered$course_id %in% all_id$course_id,]

# merge_data 
merged_data <- merge(a_filtered, all_id, by = "course_id", inner = TRUE)

# remove class with less than 5 people
merged_data = merged_data[merged_data$unique_user_count >= 5,]

# deduplicate course items and reordering
updated_data <- merged_data %>%
  group_by(course_id, course_item_id) %>%  # Group by course_id and course_item_id
  slice(1) %>%  # Keep only the first row in each group
  ungroup() %>%  # Remove grouping
  arrange(course_id, graded_item_order) %>%  # Sort by graded_item_order
  group_by(course_id) %>%  # Regroup by course_id for sequential numbering
  mutate(updated_order = row_number()) %>%  # Assign sequential order within each course
  ungroup()  # Remove grouping for further operations

# tiny shift on dropout percentage for positive requirement in gamma
updated_data$dropout_percentage = updated_data$dropout_percentage + 0.0001
# create log dropout rate
updated_data$log_dropout_percentage = log(updated_data$dropout_percentage)

# remove outliers 
outliers = updated_data[updated_data$updated_order > 2 & updated_data$dropout_percentage > 0.3,]
updated_data = updated_data[!(updated_data$updated_order > 2 & updated_data$dropout_percentage > 0.3), ]

# remove course with only one graded item
updated_data = updated_data[!updated_data$course_id=="wWmv2BEhEeWvmQrN_lODCw",]

# use updated_data from modelings
a_cleaned = updated_data %>% select(everything())
a_ex1 = a_cleaned[!a_cleaned$updated_order==1,] # for excluding first item
a_first = a_cleaned[a_cleaned$updated_order==1,] # for analyzing first item


# course level model -----
library(lme4)

# Fit the mixed-effects model with first item
model1 <- lmer(log_dropout_percentage ~ updated_order + 
                 (1 | course_id), data = a_cleaned)

# Check residuals
plot(fitted(model1), residuals(model1))

# Fit the mixed-effects model without first item
model2 <- lmer(log_dropout_percentage ~ updated_order + 
                 (1 | course_id), data = a_ex1)

# check residual
plot(fitted(model2), residuals(model2))

# Fit the gamma distribution model with first item 
model3 <- glmer(dropout_percentage~updated_order + (1 | course_id),
                data = a_cleaned, family = Gamma(link = "log"))
summary(model3)

# Fit the gamma distribution model with first item 
model4 <- glmer(dropout_percentage~updated_order + (1 | course_id),
                data = a_ex1, family = Gamma(link = "log"))
summary(model4)

# plot the model
library(ggplot2)

# Predict using only fixed effects for model3 and model4
a_cleaned$fitted_value_fixed_model3 = exp(predict(model3, newdata = a_cleaned, re.form = NA, raw=TRUE))
a_ex1$fitted_value_fixed_model4 = exp(predict(model4, newdata = a_ex1, re.form = NA, raw=TRUE))

# Plot both curves
ggplot() +
  # Model 3 points and curve
  geom_point(data = a_cleaned, aes(x = updated_order, y = dropout_percentage), 
             alpha = 0.3, color = "blue") +
  geom_line(data = a_cleaned, aes(x = updated_order, y = fitted_value_fixed_model3, color = "With first assessment"), size = 1) +
  
  # Model 4 points and curve
  geom_line(data = a_ex1, aes(x = updated_order, y = fitted_value_fixed_model4, color = "Without first assessment"), size = 1) +
  
  # Labels and theme
  labs(title = "Exponential Decay for Stopout Percentage",
       x = "Assessment Order",
       y = "Stopout Percentage",
       color = "Model") +
  
  # Set theme and legend position
  theme_minimal() +
  theme(
    legend.position = "bottom",  # Move legend to the bottom
    plot.title = element_text(hjust = 0.5)  # Center the title
  ) +
  scale_color_manual(values = c("With first assessment" = "red", "Without first assessment" = "purple"))

# Model 3 and 4 evalution on rsme
# 1. Predictions and RMSE: Model 3 on full dataset (baseline)
pred3_full <- predict(model3, newdata = a_cleaned, type = "response", re.form = NULL)
obs_full <- a_cleaned$dropout_percentage
rmse_model3_full <- sqrt(mean((obs_full - pred3_full)^2))

# 2. Predictions and RMSE: Model 3 on subset dataset (a_ex1)
pred3_ex1 <- predict(model3, newdata = a_ex1, type = "response", re.form = NULL, allow.new.levels = FALSE)
observed_ex1 <- a_ex1$dropout_percentage
rmse_model3_ex1 <- sqrt(mean((observed_ex1 - pred3_ex1)^2))

# 3. Predictions and RMSE: Model 4 on subset dataset (original dataset)
pred4_ex1 <- predict(model4, newdata = a_ex1, type = "response", re.form = NULL)
rmse_model4_ex1 <- sqrt(mean((observed_ex1 - pred4_ex1)^2))

# 4. Predictions and RMSE: Model 4 on full dataset (a_cleaned)
pred4_full <- predict(model4, newdata = a_cleaned, type = "response", re.form = NULL, allow.new.levels = FALSE)
observed_full <- a_cleaned$dropout_percentage
rmse_model4_full <- sqrt(mean((obs_full - pred4_full)^2))

# Summary Output
rmse_results <- data.frame(
  Model = c("Model 3", "Model 3", "Model 4", "Model 4"),
  Evaluated_on = c("Full data", "Subset data (a_ex1)", "Subset data (a_ex1)", "Full data"),
  RMSE = c(rmse_model3_full, rmse_model3_ex1, rmse_model4_ex1, rmse_model4_full)
)

print(rmse_results)
# assessment level model ----
# adding residuals for new data frame
a_assessment = a_ex1
a_assessment$resid = a_ex1$dropout_percentage - exp(predict(model2))
a_assessment$resid_new = resid(model2)

# Fit mixed model with all predictors except 'course_id'
model_assessment_full <- lmer(resid ~ 
                                course_days + forum_counts + assessment_counts + 
                                asssignemnt_counts + required_review_counts + 
                                grading_types + submission_types + 
                                num_of_items + assessment_passing_fraction + 
                                global_item_time_commitment + question_counts + 
                                checkbox_percentage + 
                                mcq_percentage + 
                                reflect_percentage + 
                                single.numeric_percentage + unique_user_count + 
                                (1 | course_id),  # Random effect for course_id
                              data = a_assessment, 
                              REML = TRUE)
# Summarize the results
summary(model_assessment_full)

# Based on 0 variance in random intercepts, refit lm  
model_assessment_lm <- lm(resid ~ 
                              course_days + forum_counts + assessment_counts + 
                              asssignemnt_counts + required_review_counts + 
                              grading_types + submission_types + 
                              num_of_items + assessment_passing_fraction + 
                              global_item_time_commitment + question_counts + 
                              checkbox_percentage + 
                              mcq_percentage + 
                              reflect_percentage + 
                              single.numeric_percentage + unique_user_count,
                            data = a_assessment)

# stepwise model selection on aic
model_assessment_lm_aic = step(model_assessment_lm, direction = "both")
summary(model_assessment_lm_aic)
# stepwise model delete many informative columns

# Final choice on lm full model
# summary and diagnostic plot
summary(model_assessment_lm)
par(mfrow=c(2,2))
plot(model_assessment_lm)

