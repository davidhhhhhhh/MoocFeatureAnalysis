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

a_ex1 = a_cleaned[!a_cleaned$updated_order==1,]

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



# assessment level model ----
# Fit the second model with assessment-related features
model2 <- lm(residuals ~ assessment_passing_fraction + global_item_time_commitment + 
               question_counts + checkbox_percentage + codeExpression_percentage + 
               math.expression_percentage + mcq_percentage + mcqReflect_percentage + 
               reflect_percentage + regex_percentage + single.numeric_percentage + 
               text.exact.match_percentage, data = a)

# Summarize the results
summary(model2)

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

