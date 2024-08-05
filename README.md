# multi-region-acm-issue



Quick steps to replicate:

1) Clone this repo.
2) Replace the AWS Account ID in the `./pre-prod/account.hcl` file with the ID of the account you will use for testing.
3) Replace the Role Name in the `./common-config.hcl` file with the role you will use to test this deployment.
   NOTE: If you are creating a new role, you can use this permission set:
   ```
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "terragruntS3Policy",
                "Action": "s3:*",
                "Resource": [
                    "arn:aws:s3:::tf-state*",
                    "arn:aws:s3:::tf-state*/*"
                ],
                "Effect": "Allow"
            },
            {
                "Sid": "terragruntDynamoPolicy",
                "Action": "dynamodb:*",
                "Resource": [
                    "arn:aws:dynamodb:*:*:table/tf-locks*"
                ],
                "Effect": "Allow"
            },
            {
                "Sid": "route53Policy",
                "Action": "route53:*",
                "Resource": "*",
                "Effect": "Allow"
            },
            {
                "Sid": "acmPolicy",
                "Action": "acm:*",
                "Resource": "*",
                "Effect": "Allow"
            }
        ]
    }
   ```
4) You will need credentials for a user/role that can assume the role you selected in step 3.
   Set your `AWS_PROFILE` or `AWS_ACCESS_KEY` and `SECRET_KEY`, depending on what you are using (Check this guide if needed: [LINK](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html))
5) Navigate to the DNS Zone folder: `cd ./pre-prod/sandbox/global/route53/public/sbx.my-domain.com`
6) Deploy it: `terragrunt apply -auto-approve`
7) Move to the `us-east-1` ACM Cert folder: `cd ./pre-prod/sandbox/us-east-1/acm/sbx.my-domain.com`
8) Deploy it: `terragrunt apply -auto-approve`. This step should:  
  a) Create a new ACM certificate in `us-east-1`, that will be validated using a Route53 CNAME.  
  b) Create the CNAME entry in the zone you created in step '6'.
9) Check the record that was created in the zone (you can navigate to it using the Web Console or the CLI, it's up to you).
10) Run a Terragrunt plan (`terragrunt plan`), and it should show 0 changes. This is important.
11) Move to the `us-east-2` ACM Cert folder: `cd ./pre-prod/sandbox/us-east-2/acm/sbx.my-domain.com`
12) Deploy it: `terragrunt apply -auto-approve`. This step should:  
  a) Create a new ACM certificate in `us-east-2`, that will be validated using a Route53 CNAME.  
  b) Attempt to create the same CNAME entry in the zone created in step '8', but since it's already there, it won't matter.
13) To validate, go back to the `us-east-1` cert path: `cd ./pre-prod/sandbox/us-east-1/acm/sbx.my-domain.com`
14) Run a `terragrunt plan` there. It should again show 0 changes. Cool.
15) Go to the `us-east-2` cert path: `cd ./pre-prod/sandbox/us-east-2/acm/sbx.my-domain.com`
16) Time to destroy it: `terragrunt destroy -auto-approve`. This will:  
  a) Delete the ACM Cert created in `us-east-2` (YAY!).  
  b) Delete the Route53 record used by this cert (YAY!), but also the `us-east-1` cert (Oh no... Really? Can we check?).
17) Yep, go to the console and check in Route53 that the record was removed. And what about the `us-east-1` state? Let's see...
18) Go again to the `us-east-1` cert folder: `cd ./pre-prod/sandbox/us-east-1/acm/sbx.my-domain.com`
19) Run a plan: `terragrunt plan`
20) This state, even though it was not directly modified, had the shared Route53 record removed...


Suggestion:  
Add an option that can be used to override the behavior of the record that is created, allowing it to be ignored during destroy operations.  
When a destroy is used, the record should be kept, but it should be removed from the state as if it was deleted.