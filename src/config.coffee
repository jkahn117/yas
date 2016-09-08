# config.coffee

##
# Name of the EC2 Tag whose value is the time to shut down the instance
#
shutdowntimeTagName = "NonProd Shutdown"

##
# Timezone of the tag value
#
timezone = "America/Chicago"

##
# Regions to check
#
regions = [
  'us-east-1',
  'us-west-1',
  'us-west-2'
]