# # locals {
# #   forecast_dashboard_name = lower(replace(local.placeholder, "%name%", "forecast-mlops-dashboard"))

# #   # Keep these aligned with your actual SageMaker Pipeline step names
# #   forecast_pipeline_step_names = [
# #     "IrisPreprocessing",
# #     "IrisTraining",
# #     "IrisEvaluation",
# #     "IrisConditionEvaluation",
# #     "IrisRegisterModel"
# #   ]

# #   forecast_dashboard_body = jsonencode({
# #     start          = "-PT6H"
# #     periodOverride = "inherit"
# #     widgets = [
# #       {
# #         type   = "text"
# #         x      = 0
# #         y      = 0
# #         width  = 24
# #         height = 2
# #         properties = {
# #           markdown = <<-EOT
# #           # Forecast / Iris SageMaker Dashboard

# #           **Pipeline:** ${var.pipeline_name}  
# #           **Staging Endpoint:** ${var.staging_endpoint_name}  
# #           **Prod Endpoint:** ${lower(replace(local.placeholder, "%name%", "forecast-prod-endpoint"))}  
# #           **Model Package Group:** ${aws_sagemaker_model_package_group.forecast_model_group.model_package_group_name}  
# #           **EventBridge Rule:** ${lower(replace(local.placeholder, "%name%", "forecast-model-approved"))}  
# #           **Lambda:** ${module.forecast_auto_deploy_lambda.lambda_function_name}
# #           EOT
# #         }
# #       },

# #       # ------------------------------------------------------------
# #       # 1) SageMaker Pipeline execution metrics (ONLY your pipeline)
# #       # Namespace: AWS/SageMaker/ModelBuildingPipeline
# #       # ------------------------------------------------------------
# #       {
# #         type   = "metric"
# #         x      = 0
# #         y      = 2
# #         width  = 8
# #         height = 6
# #         properties = {
# #           title   = "Pipeline Execution - ${var.pipeline_name}"
# #           region  = var.region
# #           stat    = "Sum"
# #           period  = 60
# #           view    = "timeSeries"
# #           stacked = false
# #           metrics = [
# #             [ "AWS/Sagemaker/ModelBuildingPipeline", "ExecutionStarted",   "PipelineName", var.pipeline_name, { "label": "ExecutionStarted" } ],
# #             [ ".",                                   "ExecutionSucceeded", ".",            ".",               { "label": "ExecutionSucceeded" } ],
# #             [ ".",                                   "ExecutionFailed",    ".",            ".",               { "label": "ExecutionFailed" } ],
# #             [ ".",                                   "ExecutionStopped",   ".",            ".",               { "label": "ExecutionStopped" } ]
# #           ]
# #         }
# #       },
# #       {
# #         type   = "metric"
# #         x      = 12
# #         y      = 2
# #         width  = 8
# #         height = 6
# #         properties = {
# #           title   = "Pipeline Execution Duration - ${var.pipeline_name}"
# #           region  = var.region
# #           stat    = "Average"
# #           period  = 60
# #           view    = "timeSeries"
# #           stacked = false
# #           metrics = [
# #             [ "AWS/Sagemaker/ModelBuildingPipeline", "ExecutionDuration", "PipelineName", var.pipeline_name, { "label": "ExecutionDuration(ms)" } ]
# #           ]
# #         }
# #       },

# #       # ------------------------------------------------------------
# #       # 2) Pipeline step metrics (ONLY your step names)
# #       # ------------------------------------------------------------
# #       {
# #         type   = "metric"
# #         x      = 0
# #         y      = 8
# #         width  = 8
# #         height = 6
# #         properties = {
# #           title   = "Pipeline Steps Started / Succeeded / Failed"
# #           region  = var.region
# #           stat    = "Sum"
# #           period  = 60
# #           view    = "timeSeries"
# #           stacked = false
# #           metrics = concat(
# #             [
# #               [ "AWS/Sagemaker/ModelBuildingPipeline", "StepStarted",   "PipelineName", var.pipeline_name, "StepName", "IrisPreprocessing",      { "label": "Preprocess Started" } ],
# #               [ ".",                                   "StepSucceeded", ".",            ".",               ".",        ".",                      { "label": "Preprocess Succeeded" } ],
# #               [ ".",                                   "StepFailed",    ".",            ".",               ".",        ".",                      { "label": "Preprocess Failed" } ],

# #               [ "AWS/Sagemaker/ModelBuildingPipeline", "StepStarted",   "PipelineName", var.pipeline_name, "StepName", "IrisTraining",           { "label": "Training Started" } ],
# #               [ ".",                                   "StepSucceeded", ".",            ".",               ".",        ".",                      { "label": "Training Succeeded" } ],
# #               [ ".",                                   "StepFailed",    ".",            ".",               ".",        ".",                      { "label": "Training Failed" } ],

# #               [ "AWS/Sagemaker/ModelBuildingPipeline", "StepStarted",   "PipelineName", var.pipeline_name, "StepName", "IrisEvaluation",         { "label": "Evaluation Started" } ],
# #               [ ".",                                   "StepSucceeded", ".",            ".",               ".",        ".",                      { "label": "Evaluation Succeeded" } ],
# #               [ ".",                                   "StepFailed",    ".",            ".",               ".",        ".",                      { "label": "Evaluation Failed" } ],

# #               [ "AWS/Sagemaker/ModelBuildingPipeline", "StepStarted",   "PipelineName", var.pipeline_name, "StepName", "IrisRegisterModel",      { "label": "Register Started" } ],
# #               [ ".",                                   "StepSucceeded", ".",            ".",               ".",        ".",                      { "label": "Register Succeeded" } ],
# #               [ ".",                                   "StepFailed",    ".",            ".",               ".",        ".",                      { "label": "Register Failed" } ]
# #             ]
# #           )
# #         }
# #       },
# #       {
# #         type   = "metric"
# #         x      = 12
# #         y      = 8
# #         width  = 8
# #         height = 6
# #         properties = {
# #           title   = "Pipeline Step Duration"
# #           region  = var.region
# #           stat    = "Average"
# #           period  = 60
# #           view    = "timeSeries"
# #           stacked = false
# #           metrics = [
# #             [ "AWS/Sagemaker/ModelBuildingPipeline", "StepDuration", "PipelineName", var.pipeline_name, "StepName", "IrisPreprocessing", { "label": "Preprocess(ms)" } ],
# #             [ "...", "IrisTraining",                 { "label": "Training(ms)" } ],
# #             [ "...", "IrisEvaluation",               { "label": "Evaluation(ms)" } ],
# #             [ "...", "IrisRegisterModel",            { "label": "Register(ms)" } ]
# #           ]
# #         }
# #       },

# #       # ------------------------------------------------------------
# #       # 3) Processing job resource metrics
# #       # Dynamic via SEARCH so future jobs are included automatically.
# #       # ------------------------------------------------------------
# #       {
# #         type   = "metric"
# #         x      = 0
# #         y      = 14
# #         width  = 8
# #         height = 6
# #         properties = {
# #           title   = "Preprocessing Job Resource Utilization"
# #           region  = var.region
# #           stat    = "Average"
# #           period  = 60
# #           view    = "timeSeries"
# #           stacked = false
# #           metrics = [
# #             [ { "expression": "SEARCH('{/aws/sagemaker/ProcessingJobs,ProcessingJobName} MetricName=\"CPUUtilization\" \"IrisPreprocessing\"', 'Average', 60)",    "id": "e1", "label": "Preprocess CPU %" } ],
# #             [ { "expression": "SEARCH('{/aws/sagemaker/ProcessingJobs,ProcessingJobName} MetricName=\"MemoryUtilization\" \"IrisPreprocessing\"', 'Average', 60)", "id": "e2", "label": "Preprocess Memory %" } ],
# #             [ { "expression": "SEARCH('{/aws/sagemaker/ProcessingJobs,ProcessingJobName} MetricName=\"DiskUtilization\" \"IrisPreprocessing\"', 'Average', 60)",   "id": "e3", "label": "Preprocess Disk %" } ]
# #           ]
# #         }
# #       },
# #       {
# #         type   = "metric"
# #         x      = 12
# #         y      = 14
# #         width  = 8
# #         height = 6
# #         properties = {
# #           title   = "Evaluation Job Resource Utilization"
# #           region  = var.region
# #           stat    = "Average"
# #           period  = 60
# #           view    = "timeSeries"
# #           stacked = false
# #           metrics = [
# #             [ { "expression": "SEARCH('{/aws/sagemaker/ProcessingJobs,ProcessingJobName} MetricName=\"CPUUtilization\" \"IrisEvaluation\"', 'Average', 60)",    "id": "e1", "label": "Evaluation CPU %" } ],
# #             [ { "expression": "SEARCH('{/aws/sagemaker/ProcessingJobs,ProcessingJobName} MetricName=\"MemoryUtilization\" \"IrisEvaluation\"', 'Average', 60)", "id": "e2", "label": "Evaluation Memory %" } ],
# #             [ { "expression": "SEARCH('{/aws/sagemaker/ProcessingJobs,ProcessingJobName} MetricName=\"DiskUtilization\" \"IrisEvaluation\"', 'Average', 60)",   "id": "e3", "label": "Evaluation Disk %" } ]
# #           ]
# #         }
# #       },

# #       # ------------------------------------------------------------
# #       # 4) Training job resource metrics
# #       # ------------------------------------------------------------
# #       {
# #         type   = "metric"
# #         x      = 0
# #         y      = 20
# #         width  = 8
# #         height = 6
# #         properties = {
# #           title   = "Training Job Resource Utilization"
# #           region  = var.region
# #           stat    = "Average"
# #           period  = 60
# #           view    = "timeSeries"
# #           stacked = false
# #           metrics = [
# #             [ { "expression": "SEARCH('{/aws/sagemaker/TrainingJobs,TrainingJobName} MetricName=\"CPUUtilization\" \"IrisTraining\"', 'Average', 60)",    "id": "e1", "label": "Training CPU %" } ],
# #             [ { "expression": "SEARCH('{/aws/sagemaker/TrainingJobs,TrainingJobName} MetricName=\"MemoryUtilization\" \"IrisTraining\"', 'Average', 60)", "id": "e2", "label": "Training Memory %" } ],
# #             [ { "expression": "SEARCH('{/aws/sagemaker/TrainingJobs,TrainingJobName} MetricName=\"DiskUtilization\" \"IrisTraining\"', 'Average', 60)",   "id": "e3", "label": "Training Disk %" } ]
# #           ]
# #         }
# #       },

# #       # ------------------------------------------------------------
# #       # 5) Custom training metrics
# #       # These appear only if you add metric_definitions to the estimator.
# #       # ------------------------------------------------------------
# #       {
# #         type   = "metric"
# #         x      = 12
# #         y      = 20
# #         width  = 8
# #         height = 6
# #         properties = {
# #           title   = "Training Custom Metrics"
# #           region  = var.region
# #           stat    = "Average"
# #           period  = 60
# #           view    = "timeSeries"
# #           stacked = false
# #           metrics = [
# #             [ { "expression": "SEARCH('{/aws/sagemaker/TrainingJobs,TrainingJobName} MetricName=\"train:accuracy\" \"IrisTraining\"', 'Average', 60)", "id": "e1", "label": "Train Accuracy" } ],
# #             [ { "expression": "SEARCH('{/aws/sagemaker/TrainingJobs,TrainingJobName} MetricName=\"train:f1_macro\" \"IrisTraining\"', 'Average', 60)", "id": "e2", "label": "Train F1 Macro" } ]
# #           ]
# #         }
# #       },

# #       # ------------------------------------------------------------
# #       # 6) Endpoint metrics - staging + prod only
# #       # ------------------------------------------------------------
# #       {
# #         type   = "metric"
# #         x      = 0
# #         y      = 26
# #         width  = 8
# #         height = 6
# #         properties = {
# #           title   = "Staging Endpoint"
# #           region  = var.region
# #           stat    = "Average"
# #           period  = 60
# #           view    = "timeSeries"
# #           stacked = false
# #           metrics = [
# #             [ "AWS/SageMaker", "Invocations",        "EndpointName", var.staging_endpoint_name, { "stat": "Sum",     "label": "Invocations" } ],
# #             [ ".",             "Invocation4XXErrors",".",            ".",                        { "stat": "Sum",     "label": "4XX Errors" } ],
# #             [ ".",             "Invocation5XXErrors",".",            ".",                        { "stat": "Sum",     "label": "5XX Errors" } ],
# #             [ ".",             "ModelLatency",       ".",            ".",                        { "stat": "Average", "label": "ModelLatency(us)" } ],
# #             [ ".",             "OverheadLatency",    ".",            ".",                        { "stat": "Average", "label": "OverheadLatency(us)" } ]
# #           ]
# #         }
# #       },
# #       {
# #         type   = "metric"
# #         x      = 12
# #         y      = 26
# #         width  = 8
# #         height = 6
# #         properties = {
# #           title   = "Production Endpoint"
# #           region  = var.region
# #           stat    = "Average"
# #           period  = 60
# #           view    = "timeSeries"
# #           stacked = false
# #           metrics = [
# #             [ "AWS/SageMaker", "Invocations",        "EndpointName", lower(replace(local.placeholder, "%name%", "forecast-prod-endpoint")), { "stat": "Sum",     "label": "Invocations" } ],
# #             [ ".",             "Invocation4XXErrors",".",            ".",                                                         { "stat": "Sum",     "label": "4XX Errors" } ],
# #             [ ".",             "Invocation5XXErrors",".",            ".",                                                         { "stat": "Sum",     "label": "5XX Errors" } ],
# #             [ ".",             "ModelLatency",       ".",            ".",                                                         { "stat": "Average", "label": "ModelLatency(us)" } ],
# #             [ ".",             "OverheadLatency",    ".",            ".",                                                         { "stat": "Average", "label": "OverheadLatency(us)" } ]
# #           ]
# #         }
# #       },

# #       # ------------------------------------------------------------
# #       # 7) Lambda + EventBridge for auto deploy path
# #       # ------------------------------------------------------------
# #       {
# #         type   = "metric"
# #         x      = 0
# #         y      = 32
# #         width  = 8
# #         height = 6
# #         properties = {
# #           title   = "Auto-Deploy Lambda"
# #           region  = var.region
# #           stat    = "Sum"
# #           period  = 60
# #           view    = "timeSeries"
# #           stacked = false
# #           metrics = [
# #             [ "AWS/Lambda", "Invocations", "FunctionName", module.forecast_auto_deploy_lambda.lambda_function_name, { "label": "Invocations" } ],
# #             [ ".",          "Errors",      ".",            ".",                                                     { "label": "Errors" } ],
# #             [ ".",          "Duration",    ".",            ".",                                                     { "stat": "Average", "label": "Duration(ms)" } ],
# #             [ ".",          "Throttles",   ".",            ".",                                                     { "label": "Throttles" } ]
# #           ]
# #         }
# #       },
# #       {
# #         type   = "metric"
# #         x      = 12
# #         y      = 32
# #         width  = 8
# #         height = 6
# #         properties = {
# #           title   = "Model Approval EventBridge Rule"
# #           region  = var.region
# #           stat    = "Sum"
# #           period  = 60
# #           view    = "timeSeries"
# #           stacked = false
# #           metrics = [
# #             [ "AWS/Events", "MatchedEvents",                "RuleName", lower(replace(local.placeholder, "%name%", "forecast-model-approved")), { "label": "MatchedEvents" } ],
# #             [ ".",          "TriggeredRules",               ".",        ".",                                                          { "label": "TriggeredRules" } ],
# #             [ ".",          "Invocations",                  ".",        ".",                                                          { "label": "Invocations" } ],
# #             [ ".",          "SuccessfulInvocationAttempts", ".",        ".",                                                          { "label": "SuccessfulInvocationAttempts" } ],
# #             [ ".",          "FailedInvocations",            ".",        ".",                                                          { "label": "FailedInvocations" } ]
# #           ]
# #         }
# #       }
# #     ]
# #   })
# # }

# # resource "aws_cloudwatch_dashboard" "forecast_mlops" {
# #   dashboard_name = local.forecast_dashboard_name
# #   dashboard_body = local.forecast_dashboard_body
# # }



# locals {
#   forecast_dashboard_name = lower(replace(local.placeholder, "%name%", "forecast-mlops-dashboard"))

#   forecast_dashboard_body = jsonencode({
#     start          = "-PT8H"
#     periodOverride = "inherit"
#     widgets = [
#       {
#         type   = "metric"
#         x      = 0
#         y      = 2
#         width  = 8
#         height = 6
#         properties = {
#           title   = "Pipeline Execution - ${var.pipeline_name}"
#           region  = var.region
#           stat    = "Sum"
#           period  = 60
#           view    = "timeSeries"
#           stacked = false
#           metrics = [
#             ["AWS/Sagemaker/ModelBuildingPipeline", "ExecutionStarted", "PipelineName", var.pipeline_name, { "label" : "ExecutionStarted" }],
#             [".", "ExecutionSucceeded", ".", ".", { "label" : "ExecutionSucceeded" }],
#             [".", "ExecutionFailed", ".", ".", { "label" : "ExecutionFailed" }],
#             [".", "ExecutionStopped", ".", ".", { "label" : "ExecutionStopped" }]
#           ]
#         }
#       },
#       {
#         type   = "metric"
#         x      = 8
#         y      = 2
#         width  = 8
#         height = 6
#         properties = {
#           title   = "Pipeline Execution Duration - ${var.pipeline_name}"
#           region  = var.region
#           view    = "timeSeries"
#           period  = 60
#           stacked = false

#           metrics = [
#             [
#               "AWS/Sagemaker/ModelBuildingPipeline", "ExecutionDuration", "PipelineName", var.pipeline_name, { "id" : "m1", "visible" : false }
#             ],
#             [
#               { "expression" : "m1/60000", "label" : "ExecutionDuration", "id" : "e1" }
#             ]
#           ]
#         }
#       },
#       {
#         type   = "metric"
#         x      = 16
#         y      = 2
#         width  = 8
#         height = 6
#         properties = {
#           title   = "Pipeline Step Duration"
#           region  = var.region
#           view    = "timeSeries"
#           period  = 60
#           stacked = false

#           metrics = [
#             ["AWS/Sagemaker/ModelBuildingPipeline", "StepDuration", "PipelineName", var.pipeline_name, "StepName", "IrisPreprocessing", { "id" : "m1", "visible" : false }],
#             [{ "expression" : "m1/60000", "label" : "Preprocess", "id" : "e1" }],

#             ["AWS/Sagemaker/ModelBuildingPipeline", "StepDuration", "PipelineName", var.pipeline_name, "StepName", "IrisTraining", { "id" : "m2", "visible" : false }],
#             [{ "expression" : "m2/60000", "label" : "Training", "id" : "e2" }],

#             ["AWS/Sagemaker/ModelBuildingPipeline", "StepDuration", "PipelineName", var.pipeline_name, "StepName", "IrisEvaluation", { "id" : "m3", "visible" : false }],
#             [{ "expression" : "m3/60000", "label" : "Evaluation", "id" : "e3" }],

#             ["AWS/Sagemaker/ModelBuildingPipeline", "StepDuration", "PipelineName", var.pipeline_name, "StepName", "IrisRegisterModel", { "id" : "m4", "visible" : false }],
#             [{ "expression" : "m4/60000", "label" : "Register", "id" : "e4" }]
#           ]
#         }
#       },
#       {
#         type   = "metric"
#         x      = 0
#         y      = 8
#         width  = 8
#         height = 6
#         properties = {
#           title   = "Pipeline Steps Started / Succeeded / Failed"
#           region  = var.region
#           stat    = "Sum"
#           period  = 60
#           view    = "timeSeries"
#           stacked = false
#           metrics = [
#             ["AWS/Sagemaker/ModelBuildingPipeline", "StepStarted", "PipelineName", var.pipeline_name, "StepName", "IrisPreprocessing", { "label" : "Preprocess Started" }],
#             [".", "StepSucceeded", ".", ".", ".", ".", { "label" : "Preprocess Succeeded" }],
#             [".", "StepFailed", ".", ".", ".", ".", { "label" : "Preprocess Failed" }],

#             ["AWS/Sagemaker/ModelBuildingPipeline", "StepStarted", "PipelineName", var.pipeline_name, "StepName", "IrisTraining", { "label" : "Training Started" }],
#             [".", "StepSucceeded", ".", ".", ".", ".", { "label" : "Training Succeeded" }],
#             [".", "StepFailed", ".", ".", ".", ".", { "label" : "Training Failed" }],

#             ["AWS/Sagemaker/ModelBuildingPipeline", "StepStarted", "PipelineName", var.pipeline_name, "StepName", "IrisEvaluation", { "label" : "Evaluation Started" }],
#             [".", "StepSucceeded", ".", ".", ".", ".", { "label" : "Evaluation Succeeded" }],
#             [".", "StepFailed", ".", ".", ".", ".", { "label" : "Evaluation Failed" }],

#             ["AWS/Sagemaker/ModelBuildingPipeline", "StepStarted", "PipelineName", var.pipeline_name, "StepName", "IrisRegisterModel-RegisterModel", { "label" : "Register Started" }],
#             [".", "StepSucceeded", ".", ".", ".", ".", { "label" : "Register Succeeded" }],
#             [".", "StepFailed", ".", ".", ".", ".", { "label" : "Register Failed" }]
#           ]
#         }
#       },
#       {
#         type   = "metric"
#         x      = 8
#         y      = 8
#         width  = 8
#         height = 6
#         properties = {
#           title   = "Pipeline Job(Preprocessing, Evaluation, Training) Resource Utilization"
#           region  = var.region
#           stat    = "Average"
#           period  = 60
#           view    = "timeSeries"
#           stacked = false
#           metrics = [
#             [{ "expression" : "SEARCH('{/aws/sagemaker/ProcessingJobs,ProcessingJobName} MetricName=\"CPUUtilization\" \"IrisPreprocessing\"', 'Average', 60)", "id" : "p1", "label" : "Preprocess CPU %" }],
#             [{ "expression" : "SEARCH('{/aws/sagemaker/ProcessingJobs,ProcessingJobName} MetricName=\"MemoryUtilization\" \"IrisPreprocessing\"', 'Average', 60)", "id" : "p2", "label" : "Preprocess Memory %" }],
#             [{ "expression" : "SEARCH('{/aws/sagemaker/ProcessingJobs,ProcessingJobName} MetricName=\"DiskUtilization\" \"IrisPreprocessing\"', 'Average', 60)", "id" : "p3", "label" : "Preprocess Disk %" }],

#             [{ "expression" : "SEARCH('{/aws/sagemaker/TrainingJobs,TrainingJobName} MetricName=\"CPUUtilization\" \"IrisTraining\"', 'Average', 60)", "id" : "t1", "label" : "Training CPU %" }],
#             [{ "expression" : "SEARCH('{/aws/sagemaker/TrainingJobs,TrainingJobName} MetricName=\"MemoryUtilization\" \"IrisTraining\"', 'Average', 60)", "id" : "t2", "label" : "Training Memory %" }],
#             [{ "expression" : "SEARCH('{/aws/sagemaker/TrainingJobs,TrainingJobName} MetricName=\"DiskUtilization\" \"IrisTraining\"', 'Average', 60)", "id" : "t3", "label" : "Training Disk %" }],

#             [{ "expression" : "SEARCH('{/aws/sagemaker/ProcessingJobs,ProcessingJobName} MetricName=\"CPUUtilization\" \"IrisEvaluation\"', 'Average', 60)", "id" : "v1", "label" : "Evaluation CPU %" }],
#             [{ "expression" : "SEARCH('{/aws/sagemaker/ProcessingJobs,ProcessingJobName} MetricName=\"MemoryUtilization\" \"IrisEvaluation\"', 'Average', 60)", "id" : "v2", "label" : "Evaluation Memory %" }],
#             [{ "expression" : "SEARCH('{/aws/sagemaker/ProcessingJobs,ProcessingJobName} MetricName=\"DiskUtilization\" \"IrisEvaluation\"', 'Average', 60)", "id" : "v3", "label" : "Evaluation Disk %" }]
#           ]
#         }
#       },
#       {
#         type   = "metric"
#         x      = 8
#         y      = 14
#         width  = 8
#         height = 6
#         properties = {
#           title   = "Training Custom Metrics"
#           region  = var.region
#           stat    = "Average"
#           period  = 60
#           view    = "timeSeries"
#           stacked = false
#           metrics = [
#             [{ "expression" : "SEARCH('{/aws/sagemaker/TrainingJobs,TrainingJobName} MetricName=\"train:accuracy\" \"IrisTraining\"', 'Average', 60)", "id" : "e1", "label" : "Train Accuracy" }],
#             [{ "expression" : "SEARCH('{/aws/sagemaker/TrainingJobs,TrainingJobName} MetricName=\"train:f1_macro\" \"IrisTraining\"', 'Average', 60)", "id" : "e2", "label" : "Train F1 Macro" }]
#           ]
#         }
#       },
#       {
#         type   = "metric"
#         x      = 16
#         y      = 20
#         width  = 8
#         height = 6
#         properties = {
#           title   = "Training Job Logs"
#           region  = var.region
#           stat    = "Sum"
#           period  = 60
#           view    = "timeSeries"
#           stacked = false
#           metrics = [
#             ["AWS/Logs", "IncomingLogEvents", "LogGroupName", "/aws/sagemaker/TrainingJobs", { "label" : "IncomingLogEvents" }],
#             [".", "IncomingBytes", ".", ".", { "label" : "IncomingBytes" }]
#           ]
#         }
#       },
#       {
#         type   = "metric"
#         x      = 16
#         y      = 14
#         width  = 8
#         height = 6
#         properties = {
#           title   = "Auto-Deploy Lambda"
#           region  = var.region
#           period  = 60
#           view    = "timeSeries"
#           stacked = false

#           metrics = [
#             ["AWS/Lambda", "Invocations", "FunctionName", module.forecast_auto_deploy_lambda.lambda_function_name, { "stat" : "Sum", "label" : "Invocations" }],
#             [".", "Errors", ".", ".", { "stat" : "Sum", "label" : "Errors" }],
#             [".", "Duration", ".", ".", { "stat" : "Average", "id" : "m1", "visible" : false }], [{ "expression" : "m1/60000", "label" : "Duration", "id" : "e1" }],
#             [".", "Throttles", ".", ".", { "stat" : "Sum", "label" : "Throttles" }]
#           ]
#         }
#       },
#       {
#         type   = "metric"
#         x      = 0
#         y      = 20
#         width  = 8
#         height = 6
#         properties = {
#           title   = "Staging Forecast Endpoint"
#           region  = var.region
#           period  = 60
#           view    = "timeSeries"
#           stacked = false
#           metrics = [
#             ["AWS/SageMaker", "Invocations", "EndpointName", lower(replace(local.placeholder, "%name%", "forecast-endpoint")), "VariantName", "AllTraffic", { "stat" : "Sum", "label" : "Invocations" }],
#             [".", "ModelLatency", ".", ".", ".", ".", { "stat" : "Average", "label" : "ModelLatency(us)" }],
#             [".", "InvocationsPerInstance", ".", ".", ".", ".", { "stat" : "Average", "label" : "InvocationsPerInstance" }],
#             [".", "InvocationModelErrors", ".", ".", ".", ".", { "stat" : "Sum", "label" : "InvocationModelErrors" }]
#           ]
#         }
#       },
#       {
#         type   = "metric"
#         x      = 8
#         y      = 20
#         width  = 8
#         height = 6
#         properties = {
#           title   = "Production Forecast Endpoint"
#           region  = var.region
#           period  = 60
#           view    = "timeSeries"
#           stacked = false
#           metrics = [
#             ["AWS/SageMaker", "Invocations", "EndpointName", lower(replace(local.placeholder, "%name%", "forecast-prod-endpoint")), "VariantName", "AllTraffic", { "stat" : "Sum", "label" : "Invocations" }],
#             [".", "ModelLatency", ".", ".", ".", ".", { "stat" : "Average", "label" : "ModelLatency(us)" }],
#             [".", "InvocationsPerInstance", ".", ".", ".", ".", { "stat" : "Average", "label" : "InvocationsPerInstance" }],
#             [".", "InvocationModelErrors", ".", ".", ".", ".", { "stat" : "Sum", "label" : "InvocationModelErrors" }]
#           ]
#         }
#       },
#       {
#         type   = "metric"
#         x      = 16
#         y      = 20
#         width  = 8
#         height = 6
#         properties = {
#           title   = "Model Approval EventBridge Rule"
#           region  = var.region
#           stat    = "Sum"
#           period  = 60
#           view    = "timeSeries"
#           stacked = false
#           metrics = [
#             ["AWS/Events", "MatchedEvents", "RuleName", lower(replace(local.placeholder, "%name%", "forecast-model-approved-rule")), { "label" : "MatchedEvents" }],
#             [".", "TriggeredRules", ".", ".", { "label" : "TriggeredRules" }],
#             [".", "Invocations", ".", ".", { "label" : "Invocations" }],
#             [".", "SuccessfulInvocationAttempts", ".", ".", { "label" : "SuccessfulInvocationAttempts" }],
#             [".", "FailedInvocations", ".", ".", { "label" : "FailedInvocations" }]
#           ]
#         }
#       }
#     ]
#   })
# }