const AWS = require('aws-sdk');
const ecs = new AWS.ECS();


exports.handler = async (event, context) => {
  function AirshipLambdaError(message) {
    this.name = "AirshipLambdaError";
    this.message = message;
  }
  AirshipLambdaError.prototype = new Error();

  //
  // ECS Cluster and Service Lookup
  //
  const ecs_cluster = event.ecs_cluster || 'undefined'
  const ecs_service = event.ecs_service || 'undefined'

  // This throws an error in case the Cluster has not been found
  const res = await ecs.describeServices({
    cluster: ecs_cluster,
    services: [ecs_service]
  }).promise();

  // Return empty definitions in case no services have been found
  if (res.services.length > 1) {
    const error = new AirshipLambdaError("multiple services with name %s found in cluster %s Not Found" % ecs_service, ecs_cluster);
    throw error;
  } else if (res.services.length < 1) {
    const error = new AirshipLambdaError("Could not find service");
    throw error;
  }

  //
  // ECS Task definition and container definition lookup
  //
  const taskDefinition = res.services[0].taskDefinition;

  const resTask = await ecs.describeTaskDefinition({
    taskDefinition: taskDefinition
  }).promise();

  if (resTask.taskDefinition.containerDefinitions.length != 1) {
    const error = new AirshipLambdaError("only a single container is supported per task definition");
    throw error;
  }

  const count        = event.count || 1
  const started_by   = event.started_by || 'unknown-lambda'

  var params = {
      taskDefinition: taskDefinition,
      cluster: ecs_cluster,
      count: count,
      startedBy: started_by,
      overrides: event.overrides
  }
  console.log(params)

  ecs.runTask(params, function(err, data) {
      if (err) console.log(err, err.stack); // an error occurred
      else     console.log(data);           // successful response
      context.done(err, data)
  })
};
