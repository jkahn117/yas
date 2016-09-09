# YAS : Yet Another Stopinator

YAS is an AWS Lambda function built with Node.js intended to stop running EC2 instances based on Resource Tags applied to those instances.  For example, you may wish to stop one set of servers daily at 6:00pm and another set at 8:00pm (for those working late), simply tag those instances with the appropriate time, in your time zone.

YAS should be run on a schedule, perhaps once per hour, via CloudWatch events.

## Configuration

YAS currently supports a small number of configuration options, all found in `src/config.coffee`.  As AWS Lambda does not currently support environment variables, configuration will be modified via source code for now.

### Options

* `shutdowntimeTagName` (String) - Name of the Tag whose value is the shutdown time of the instance.  Time should be in 24-hour with the following format "HH:MM".  For example, "16:00" or "08:30".
* `shutdowntimeTimezone` (String) - Your timezone (or timezone of the shutdown time), using a [time zone identifier](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) amongst those listed here. For example, 'America/Chicago' or 'Europe/Paris'.
* `regions` (Array) - Listing of the AWS Regions (e.g. us-west-2, us-east-1) in which to check for and stop tagged running instances.

## Role Setup

Execution of this Lambda function requires IAM permissions that allow it to describe and stop EC2 instances.  The following policy will provide least-required permissions for the EC2 and CloudWatch actions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:StopInstances"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:*:*:*"
            ]
        }
    ]
 }
```

## Details on Packaging

The packagaing used for this Lambda function is described in a [previous article](https://medium.com/@joshua.a.kahn/deploying-to-aws-lambda-with-node-js-and-grunt-coffeescript-117df3d1fe73#.9m20yrwrs). Please read for further details.

### Deployment

Using the packaging provided here, deployment of the Lambda function is simple after initial setup.

First, create a new Lambda function via the AWS Console or CLI and capture the Region and ARN.  Rename Gruntfile.coffee.example to Gruntfile.coffee and enter these values as appropriate.  This is a one time step.

When ready to deploy a new version of the function, simply execute the command

`grunt deploy`

Wait to finish...that's it.


