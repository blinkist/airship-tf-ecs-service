const AWS = require("aws-sdk");
const ecs = new AWS.ECS();

exports.handler = async (event, context, callback) => {
  const ecs_cluster = event.ecs_cluster;
  const ecs_service = event.ecs_service;

  const services = await ecs.describeServices(
      {cluster : ecs_cluster, services : [ ecs_service ]}).promise();

  if (services.services.length > 1) {
    throw new Error("multiple services with name %s found in cluster %s" %
                        ecs_service,
                    ecs_cluster);
  }
  if (services.services.length < 1) {
    throw new Error("Could not find service");
  }

  const taskdef = services.services[0].taskDefinition;

  const taskDefinition =
      await ecs.describeTaskDefinition({taskDefinition : taskdef}).promise();

  if (taskDefinition.taskDefinition.containerDefinitions.length !== 1) {
    throw new Error("only a single container is supported per task definition");
  }

  const started_by = event.started_by;

  const networkConfiguration = services.services[0].networkConfiguration;
  const launchType = services.services[0].launchType;

  const params = {
    taskDefinition : taskdef,
    networkConfiguration : networkConfiguration,
    cluster : ecs_cluster,
    count : 1,
    launchType : launchType,
    startedBy : started_by,
    overrides : event.overrides
  };
  try {
    const data = await ecs.runTask(params).promise();
    console.log("Successfully started taskDefinition " + taskDefinition + "\n" +
                JSON.stringify(data));
    callback(null,"Successfully started taskDefinition " + taskDefinition +
                  "\n" + JSON.stringify(data));
  } catch (err) {
    if (err.code == "ConditionalCheckFailedException") {
      callback("duplicated execution: " + JSON.stringify(event));
    } else {
      callback(err);
    }
  }
};

