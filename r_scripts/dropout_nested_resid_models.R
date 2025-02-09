# Hierarchical residual modeling 
# read in data
a = read.csv("data/cleaned_data/dropout_percentage_w_course_assess_features.csv")
dim(a)
names(a)

# course level model -----
# Load necessary packages
library(lme4)

# Fit the mixed-effects model
model1 <- lmer(dropout_percentage ~ graded_item_order + course_days + 
                 forum_counts + assessment_counts + asssignemnt_counts + 
                 required_review_counts + grading_types + submission_types + 
                num_of_items + (1 | course_id), data = a)

# Extract residuals
a$residuals <- resid(model1)

# assessment level model ----
# Fit the second model with assessment-related features
model2 <- lm(residuals ~ assessment_passing_fraction + global_item_time_commitment + 
               question_counts + checkbox_percentage + codeExpression_percentage + 
               math.expression_percentage + mcq_percentage + mcqReflect_percentage + 
               reflect_percentage + regex_percentage + single.numeric_percentage + 
               text.exact.match_percentage, data = a)

# Summarize the results
summary(model2)