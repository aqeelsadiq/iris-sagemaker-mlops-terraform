# resource "aws_cloudwatch_dashboard" "forecast_mlops" {
#   dashboard_name = lower(replace(local.placeholder, "%name%", "forecast-mlops-dashboard"))
#   dashboard_body = jsonencode({
#     start          = "-PT8H"
#     periodOverride = "inherit"

#     widgets = [
#       # =====================
#       # OverView
#       # =====================
#       {
#         type   = "text"
#         x      = 0
#         y      = 7
#         width  = 24
#         height = 1
#         properties = {
#           markdown = "## OverView"
#         }
#       },
#       {
#         type   = "metric"
#         x      = 0
#         y      = 8
#         width  = 6
#         height = 6
#         properties = {
#           title  = "Pipeline ExecutionDuration"
#           view   = "gauge"
#           region = var.region
#           period = 60
#           metrics = [
#             ["AWS/Sagemaker/ModelBuildingPipeline", "ExecutionDuration", "PipelineName", var.pipeline_name, { "id" : "m1", "visible" : false }],
#             [{ "expression" : "m1/60000", "label" : "Minutes", "id" : "e1" }]
#           ]
#           yAxis = {
#             left = {
#               min = 0
#               max = 30
#             }
#           }
#         }
#       },
#       {
#         type   = "metric"
#         x      = 6
#         y      = 8
#         width  = 6
#         height = 6
#         properties = {
#           title  = "Staging Endpoint Latency"
#           view   = "gauge"
#           region = var.region
#           period = 60
#           metrics = [
#             ["AWS/SageMaker", "ModelLatency", "EndpointName", lower(replace(local.placeholder, "%name%", "forecast-endpoint")), "VariantName", "AllTraffic", { "stat" : "Average", "label" : "Latency" }]
#           ]
#           yAxis = {
#             left = {
#               min = 0
#               max = 200000
#             }
#           }
#         }
#       },
#       {
#         type   = "metric"
#         x      = 12
#         y      = 8
#         width  = 6
#         height = 6
#         properties = {
#           title  = "Prod Endpoint Latency"
#           view   = "gauge"
#           region = var.region
#           period = 60
#           metrics = [
#             ["AWS/SageMaker", "ModelLatency", "EndpointName", lower(replace(local.placeholder, "%name%", "forecast-prod-endpoint")), "VariantName", "AllTraffic", { "stat" : "Average", "label" : "Latency" }]
#           ]
#           yAxis = {
#             left = {
#               min = 0
#               max = 200000
#             }
#           }
#         }
#       },
#       {
#         type   = "metric"
#         x      = 18
#         y      = 8
#         width  = 6
#         height = 6
#         properties = {
#           title  = "Lambda Duration"
#           view   = "gauge"
#           region = var.region
#           period = 60
#           metrics = [
#             ["AWS/Lambda", "Duration", "FunctionName", module.forecast_auto_deploy_lambda.lambda_function_name, { "stat" : "Average", "id" : "m1", "visible" : false }],
#             [{ "expression" : "m1/60000", "label" : "Minutes", "id" : "e1" }]
#           ]
#           yAxis = {
#             left = {
#               min = 0
#               max = 5
#             }
#           }
#         }
#       },

#       # =====================
#       # PIPELINE ACTIVITY
#       # =====================
#       {
#         type   = "text"
#         x      = 0
#         y      = 14
#         width  = 24
#         height = 1
#         properties = {
#           markdown = "## Forecast Pipeline Activity"
#         }
#       },
#       {
#         type   = "metric"
#         x      = 0
#         y      = 15
#         width  = 8
#         height = 6
#         properties = {
#           title   = "Pipeline Executions"
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
#         y      = 15
#         width  = 8
#         height = 6
#         properties = {
#           title   = "Pipeline Executions Step Durations"
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

#             ["AWS/Sagemaker/ModelBuildingPipeline", "StepDuration", "PipelineName", var.pipeline_name, "StepName", "IrisRegisterModel-RegisterModel", { "id" : "m4", "visible" : false }],
#             [{ "expression" : "m4/60000", "label" : "Register", "id" : "e4" }]
#           ]
#         }
#       },
#       {
#         type   = "metric"
#         x      = 16
#         y      = 15
#         width  = 8
#         height = 6
#         properties = {
#           title   = "Pipeline Step Outcomes"
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
#       # =====================
#       # ENDPOINTS
#       # =====================
#       {
#         type   = "text"
#         x      = 0
#         y      = 28
#         width  = 24
#         height = 1
#         properties = {
#           markdown = "## Forecast Endpoints"
#         }
#       },
#       {
#         type   = "metric"
#         x      = 0
#         y      = 29
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
#             [".", "ModelLatency", ".", ".", ".", ".", { "stat" : "Average", "label" : "ModelLatency" }],
#             [".", "InvocationModelErrors", ".", ".", ".", ".", { "stat" : "Sum", "label" : "InvocationModelErrors" }],
#             [".", "InvocationsPerInstance", ".", ".", ".", ".", { "stat" : "Average", "label" : "InvocationsPerInstance" }],
#           ]
#         }
#       },
#       {
#         type   = "metric"
#         x      = 8
#         y      = 29
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
#             [".", "ModelLatency", ".", ".", ".", ".", { "stat" : "Average", "label" : "ModelLatency" }],
#             [".", "InvocationModelErrors", ".", ".", ".", ".", { "stat" : "Sum", "label" : "InvocationModelErrors" }],
#             [".", "InvocationsPerInstance", ".", ".", ".", ".", { "stat" : "Average", "label" : "InvocationsPerInstance" }],
#           ]
#         }
#       },

#       # =====================
#       # AUTOMATION & EVENTS
#       # =====================
#       {
#         type   = "text"
#         x      = 0
#         y      = 35
#         width  = 24
#         height = 1
#         properties = {
#           markdown = "## Lambda & EventBridge Rule Activity"
#         }
#       },
#       {
#         type   = "metric"
#         x      = 0
#         y      = 36
#         width  = 8
#         height = 6
#         properties = {
#           title   = "Forecast auto deploy Lambda Activity"
#           region  = var.region
#           period  = 60
#           view    = "timeSeries"
#           stacked = false
#           metrics = [
#             ["AWS/Lambda", "Invocations", "FunctionName", module.forecast_auto_deploy_lambda.lambda_function_name, { "stat" : "Sum", "label" : "Invocations" }],
#             [".", "Errors", ".", ".", { "stat" : "Sum", "label" : "Errors" }],
#             [".", "Throttles", ".", ".", { "stat" : "Sum", "label" : "Throttles" }]
#           ]
#         }
#       },
#       {
#         type   = "metric"
#         x      = 8
#         y      = 36
#         width  = 8
#         height = 6
#         properties = {
#           title   = "Forecast Eventbridge Model Approval Rule"
#           region  = var.region
#           stat    = "Sum"
#           period  = 60
#           view    = "timeSeries"
#           stacked = false
#           metrics = [
#             ["AWS/Events", "MatchedEvents", "RuleName", lower(replace(local.placeholder, "%name%", "forecast-model-approved-rule")), { "label" : "MatchedEvents" }],
#             [".", "TriggeredRules", ".", ".", { "label" : "TriggeredRules" }],
#             [".", "Invocations", ".", ".", { "label" : "Invocations" }],
#             [".", "SuccessfulInvocationAttempts", ".", ".", { "label" : "Successful" }],
#             [".", "FailedInvocations", ".", ".", { "label" : "Failed" }]
#           ]
#         }
#       },

#       # =====================
#       # LAMBDA LOGS
#       # =====================
#       {
#         type   = "text"
#         x      = 0
#         y      = 42
#         width  = 24
#         height = 2
#         properties = {
#           markdown = "## Lambda Logs & Debugging\n[button:Open Lambda Function](https://${var.region}.console.aws.amazon.com/lambda/home?region=${var.region}#/functions/${module.forecast_auto_deploy_lambda.lambda_function_name})  [button:Open Log Group](https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#logsV2:log-groups/log-group/$252Faws$252Flambda$252F${module.forecast_auto_deploy_lambda.lambda_function_name})"
#         }
#       },
#       {
#         type   = "log"
#         x      = 0
#         y      = 43
#         width  = 12
#         height = 6
#         properties = {
#           region = var.region
#           title  = "Forecast auto deploy Lambda Logs"
#           view   = "table"
#           query  = "SOURCE '/aws/lambda/${module.forecast_auto_deploy_lambda.lambda_function_name}' | fields @timestamp, @message, @logStream\n| sort @timestamp desc\n| limit 10"
#         }
#       },
#       {
#         type   = "log"
#         x      = 12
#         y      = 43
#         width  = 12
#         height = 6
#         properties = {
#           region = var.region
#           title  = "Forecast auto deploy Lambda Error Logs"
#           view   = "table"
#           query  = "SOURCE '/aws/lambda/${module.forecast_auto_deploy_lambda.lambda_function_name}' | fields @timestamp, @message, @logStream\n| filter @message like /ERROR|Error|Exception|Task timed out/\n| sort @timestamp desc\n| limit 10"
#         }
#       }
#     ]
#   })
# }