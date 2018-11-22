const AWS = require('aws-sdk');
const ecs = new AWS.ECS();


exports.handler = async (event) => {
  function AirshipLambdaError(message) {
    this.name = "AirshipLambdaError";
    this.message = message;
  }
  AirshipLambdaError.prototype = new Error();

  //
  // ECS Cluster and Service Lookup
  //

  // This throws an error in case the Cluster has not been found
  const res = await ecs.describeServices({
    cluster: event.ecs_cluster,
    services: [event.ecs_service]
  }).promise();


  // Throw an error when the lookup returns more than one service
  // Return empty definitions in case no services have been found
  if (res.services.length > 1) {
    const error = new AirshipLambdaError("multiple services with name %s found in cluster %s Not Found" % event.ecs_service, event.ecs_cluster);
    throw error;
  } else if (res.services.length < 1) {
    console.log("Could not find service, returning empty map")
    return returnMap;
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

  // Match the container with the given container name
  var containerDefinitions = resTask.taskDefinition.containerDefinitions.filter(function(containerDef) {
    return containerDef.name == event.ecs_task_container_name;
  });

  if ( containerDefinitions.length != 1 ){
    const error = new AirshipLambdaError("Could not find container definition: %s" % event.ecs_task_container_name );
    throw error;
  }

  var count        = events.count || 1
  console.log(taskDefinition)

  var params = {
      taskDefinition: taskDefinition,
      cluster: event.ecs_cluster,
      count: event.count,
      overrides: overrides
  }
  ecs.runTask(params, function(err, data) {
      if (err) console.log(err, err.stack); // an error occurred
      else     console.log(data);           // successful response
      context.done(err, data)
  })
}
};
