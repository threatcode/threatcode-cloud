
# Threat Code in the Cloud
**NOTE: The associated scripts are NOT recommended for production use.**

The following components are currently supported and are in testing:

- Threat Code AMI (AWS)
- Threat Code Terraform Configuration 

### Threat Code AMI   
The latest version of the Threat Code AMI can be found in all regions in the AWS marketplace, titled `Threat Code 2`.

### NOTE 
Before attempting to stand up an instance via Terraform with the official Threat Code 2 AMI, you will need to agree to the terms and conditions in the AWS Marketplace.  

Terms, conditions, and the official AMI can be found here:

https://aws.amazon.com/marketplace/pp/B08Y63CS2T?_ptnr_gh_cld

If using Terraform, the correct image will be pulled upon the run of `terraform apply`.

### Configuring the Threat Code AMI and VPC Traffic Mirroring with Terraform
Special thanks goes to Jonathan Johnson (@jsecurity101) and Dustin Lee (@dlee35),for their existing work on the base Terraform configuration and Threat Code additions!

By using Terraform, one can quickly spin up Threat Code in AWS, creating a dedicated VPC, security groups, Threat Code EC2 instance, interfaces, VPC mirror configuration, and monitored Ubuntu/Windows hosts (if desired), provided you have an existing AWS account.

**PLEASE NOTE**: The default size EC2 instance used by the Terraform scripts is `t3a.xlarge`, which is the **minimum** recommended size (4 cores/16GB RAM) to use while testing Threat Code in AWS.  Given that this instance is not free-tier eligible, you or your organization may be charged by AWS as a result of using an instance of this size and/or VPC mirroring.

#### Clone repo
`git clone https://github.com/threatcode/threatcode-cloud
&& cd threatcode-cloud/terraform/aws`

#### Install Terraform and AWS CLI
##### Linux (recommended Ubuntu 18.04 or higher) or Mac (as root or with sudo privilieges):
`./install-terraform-awscli.sh`
##### Windows
https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-windows.html#cliv2-windows-prereq   
https://www.terraform.io/downloads.html   
https://stackoverflow.com/questions/1618280/where-can-i-set-path-to-make-exe-on-windows   

#### Configure AWS details
See the following for more details:   
https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html#cli-quick-configuration

`aws configure` (Provide secret/access key, etc)

#### Create public/private keypair for use with instance
`ssh-keygen -b 2048 -f ~/.ssh/threatcode`

#### Get your external IP (to allow access to your AWS instance)
`dig TXT +short o-o.myaddr.l.google.com @ns1.google.com | awk -F'"' '{ print $2}'`

#### Modify config file with external IP for whitelist
Edit `terraform.tfvars` with external IP/netmask (gathered above) for whitelist 

`Ex. "192.168.1.1/32"`

#### Enable additional monitored hosts
`ubuntu_hosts` and `windows_hosts` are both set to `0` by default in `terraform.tfvars`.

You can specify up to `10` instances of each to spin up hosts that will have mirror sessions automatically created for them so they can be immediately monitored by Threat Code.  

Please note, typical AWS/EC2 infrastructure pricing still applies! 

#### Initialize Terraform
`terraform init`

#### Build VPC Infrastructure and Instance
`terraform apply --auto-approve`   

The output from this command should provide you with the public IP address of your EC2 instance.

#### SSH into instance
`ssh -i ~/.ssh/threatcode onion@$instanceip`  

#### Setup   
Setup will begin once logged into the instance via SSH.  Follow the prompts until setup finishes.  Once complete, a reboot will be required.  

##### AutoMirror
New instances capable of being mirrored (Nitro-based instances) will have a mirror session created for each of their interfaces.  Existing instances can be tagged with `Mirror=True` will also be picked up and have a mirror session created for them.
This functionality is provided by the logic from [3CORESec AutoMirror](https://github.com/3CORESec/AWS-AutoMirror).

Special thanks goes to @0xtf and team for all their work with AutoMirror!

##### Tear it down
The instance and VPC configuration can quickly be destroyed with the following:   
`terraform destroy --auto-approve`
