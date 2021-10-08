## Queries

#### Preventing billing shock. What gotcha should i be careful for when implementing ?

The FARGATE task ,currently pulls image from ECR. Hence ensure that the ECR is in the same region as the FARGATE cluster. Ignoring this will result in cost going up, due to cross region data transfer.

Also ensure the other resource used in the solution; AWS Secrets Manager ,S3 etc.. are also in the same region as the FARGATE cluster.

#### How to define a time based schedule for a data pipeline?
Define a scheduled task in Fargate with the appropriate task definition.

#### How to instantiate a data pipeline task from the command line?
Refer to - [Sample Execution](./SampleExecution.md) doc.

#### Why is the DBT project code stored in S3 vs pulling from the repo ?
The DBT project team might adopt the same Repo or a different repo. To avoid complications
of using the right repo sdk libraries etc, i had it designed that does not rely on specific
set of technologies.

As long the DBT project are packaged and stored in the S3 bucket, then we are all good.