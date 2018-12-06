const AWS = require("aws-sdk");
const ecs = new AWS.ECS();

exports.handler = function(event, context, callback) {
  function AirshipLambdaError(message) {
    this.name = "AirshipLambdaError";
    this.message = message;
  }
  AirshipLambdaError.prototype = new Error();

  const ecs_cluster = event.ecs_cluster;
  const ecs_service = event.ecs_service;

  ecs.describeServices(
      {cluster : ecs_cluster, services : [ ecs_service ]},
      function(dserr, dsdata) {
        if (dserr) {
          console.log("Unable to retrieve service definition for:",
                      ecs_service);
          context.fail(dserr, dserr.stack);
        } else {
          if (dsdata.services.length > 1) {
            throw new AirshipLambdaError(
                "multiple services with name %s found in cluster %s" %
                    ecs_service,
                ecs_cluster);
          } else if (dsdata.services.length < 1) {
            throw new AirshipLambdaError("Could not find service");
          }

          const taskDefinition = dsdata.services[0].taskDefinition;

          ecs.describeTaskDefinition(
              {taskDefinition : taskDefinition}, function(dtderr, dtddata) {
                if (dtderr) {
                  throw dtderr;
                } else {
                  if (dtddata.taskDefinition.containerDefinitions.length !==
                      1) {
                    throw new AirshipLambdaError(
                        "only a single container is supported per task definition");
                  }

                  const started_by = event.started_by;

                  const networkConfiguration =
                      dsdata.services[0].networkConfiguration;
                  const launchType = dsdata.services[0].launchType;

                  const params = {
                    taskDefinition : taskDefinition,
                    networkConfiguration : networkConfiguration,
                    cluster : ecs_cluster,
                    count : 1,
                    launchType : launchType,
                    startedBy : started_by,
                    overrides : event.overrides
                  };

                  ecs.runTask(params, (err, data) => {
                    if (err) {
                      if (err.code == 'ConditionalCheckFailedException') {
                        callback('duplicated execution: ' +
                                 JSON.stringify(event));
                      } else {
                        callback(err);
                      }
                    } else {
                      console.log("Successfully started taskDefinition " +
                                  taskDefinition + "\n" + JSON.stringify(data));
                      callback.null("Successfully started taskDefinition " +
                                    taskDefinition + "\n" +
                                    JSON.stringify(data));
                    }
                  })
                }
              })
        }
      });
};
