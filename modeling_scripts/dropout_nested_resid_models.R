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

# create log dropout rate
updated_data$log_dropout_percentage = log(updated_data$dropout_percentage + 0.0001)

# use updated_data from modeling
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

# plot the model
library(ggplot2)

# Get fitted values and exponentiate them
a_ex1$fitted_dropout <- exp(predict(model2))

# Create plot
ggplot(a_ex1, aes(x = updated_order, y = dropout_percentage)) +
  geom_point(alpha = 0.5, color = "blue") +  # Scatter plot of actual dropout percentages
  geom_line(aes(y = fitted_dropout), color = "red", size = 1) +  # Fitted curve
  labs(title = "Fitted Curve for Dropout Percentage vs. Updated Order",
       x = "Updated Order",
       y = "Dropout Percentage") +
  theme_minimal()

# assessment level model ----
# adding residuals for new data frame
a_assessment = a_ex1
a_assessment$resid = a_ex1$dropout_percentage - exp(predict(model2))
a_assessment$resid_new = resid(model2)

# Fit the model with all predictors except 'course_id'
model_assessment_full <- lmer(resid_new ~ 
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

# model select does not make much difference on AIC 
model_assessment_lm <- lm(resid ~ 
                                course_days + forum_counts + assessment_counts + 
                                asssignemnt_counts + 
                                grading_types + 
                                num_of_items + assessment_passing_fraction + 
                                global_item_time_commitment + question_counts + 
                                checkbox_percentage + 
                                mcq_percentage + 
                                reflect_percentage + 
                                single.numeric_percentage + unique_user_count,
                              data = a_assessment)
# diagnostic plot
par(mfrow=c(2,2))
plot(model_assessment_lm)

# summary
summary(model_assessment_lm)

# revise the code----
a$dropout_percentage_log = log(a$dropout_percentage + 0.0001)
model1 <- lmer(dropout_percentage_log ~ graded_item_order + (1 + graded_item_order | course_id), data = a)

# Extract residuals
a$residuals <- resid(model1)

model1a <- glmer(dropout_percentage ~ graded_item_order + (1 | course_id), data = a, family = poisson(link = "log"))

a$residuals2 <- resid(model1a)
# Fit the second model with assessment-related features
model2 <- lmer(residuals ~ assessment_passing_fraction + global_item_time_commitment + 
               question_counts + checkbox_percentage + codeExpression_percentage + 
               math.expression_percentage + mcq_percentage + mcqReflect_percentage + 
               reflect_percentage + regex_percentage + single.numeric_percentage + 
               text.exact.match_percentage + (1 | course_id), data = a)

# Summarize the results
summary(model2)

# extract fitted value from model1
a$predictions <- exp(predict(model1))

# Dataset EDA
temp = a[a$course_id== "tnnYzSDvEeaDJw40-0xSFQ",]
temp = temp[order(temp$graded_item_order),]
temp$dropout_percentage

