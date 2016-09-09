###
#
# YAS
#
# Sample NodeJS script to seek out all EC2 instances running in US AWS Regions
# (us-east-1, us-west-1, us-west-2) and STOP those instances still running after
# the time set in the specified tag.
#
# Time must be specified in the format "HH:MM" in 24-hour time.
#
# As an example, if the time is 6:00pm when this script is run, any instances
# with a shutdown time prioer to 6:00pm (e.g. 5:00pm, 10:00am) will be stopped.
#
# Requires IAM Role such as the following:
# {
#    "Version": "2012-10-17",
#    "Statement": [
#        {
#            "Effect": "Allow",
#            "Action": [
#                "ec2:DescribeInstances",
#                "ec2:StopInstances"
#            ],
#            "Resource": [
#                "*"
#            ]
#        },
#        {
#            "Effect": "Allow",
#            "Action": [
#                "logs:CreateLogGroup",
#                "logs:CreateLogStream",
#                "logs:PutLogEvents"
#            ],
#            "Resource": [
#                "arn:aws:logs:*:*:*"
#            ]
#        }
#    ]
# }
###

'use strict'

AWS      = require('aws-sdk')
jmespath = require('jmespath')
async    = require('async')
moment   = require('moment-timezone')


#
# Main handler function.
#
exports.handler = (event, context) ->
    console.log "Starting YAS -- Current Time is #{moment().format()}"

    async.each regions, ((region, callback) =>
      stopInstancesInRegion(region, callback)
    ), (error) ->
      if error
        handleError(error, context)
      else
        context.succeed()
    
#
# Finds all tagged, running instances in the passed region and
# stops them if the current time is after the specified stop time.
#
# Params:
#  - region: name of AWS region (e.g. us-east-1)
#  - callback: function to call when finished, pass error if one exists
#
stopInstancesInRegion = (region, callback) ->
  ec2 = new AWS.EC2 { region: region }

  params = {
    Filters: [
      { Name: 'instance-state-name', Values: [ 'running' ] },
      { Name: 'tag-key',             Values: [  shutdowntimeTagName  ] }
    ]
  }

  instances = ec2.describeInstances(params, (error, data) =>
    if error
      callback(error)
    else
      stopInstances(ec2, data, callback)
  )

#
# Stops EC2 instances described in passed JSON if the current time is after
# the specified stop time in the EC2 instance resource tag.
#
# Params:
#  - ec2: Service interface for EC2
#  - data: JSON formatted data from AWS.EC2.describe-instances function
#  - callback: function to call when finished, pass error if one exists
#
stopInstances = (ec2, data, callback) ->
  instanceToStop = jmespath.search(data,
    "Reservations[].Instances[]. {
        instanceId: InstanceId,
        stopTime:   Tags[?Key=='#{shutdowntimeTagName}'].Value | [0]
    }"
  ).filter (instance) =>
      isBeforeCurrentTime(instance.stopTime)

  instanceIdsToStop = jmespath.search(instanceToStop, "[*].instanceId")

  if instanceIdsToStop.length > 0
    ec2.stopInstances( { InstanceIds: instanceIdsToStop }, (error, stopData) ->
      if error
        callback(error)
      else
        stoppedIds = jmespath.search(stopData, "StoppingInstances[].InstanceId")
        console.log "Stopped instances: #{stoppedIds.join(', ')}"
        callback()
    )

#
# Helper function to handle errors.
#
# Params:
#  - error: the error itself
#  - context: Lambda context
#
handleError = (error, context) ->
  console.log  "[ERROR] #{error}"
  console.log  error.stack
  context.fail { error }

#
# Helper function to determine if the passed time (String, formatted as "HH:MM")
# is after the current time.  If so, returns true; else false. For example, if
# current time is 10:00am and we pass "11:30" this function returns true.
#
# Params:
#  - timeStr: time to test, in format "HH:MM", 24 hour
#
isBeforeCurrentTime = (timeStr) ->
  timeParts = timeStr.split(':')
  time = new Date()
  time.setHours(timeParts[0], timeParts[1], 0)

  # convert shutdownTime to UTC from configured timezone
  shutdownTime = moment(time, timezone).tz('UTC')

  return shutdownTime.isBefore(moment())


