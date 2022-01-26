# aws-sts-token-helper

This is shell helper for you to use MFA token to authenticate access AWS resources with the AWS Command Line Interface (AWS CLI).


## Prerequisite

* AWS CLI
* AWS account ready and you already have a pair of `aws_access_key_id` / `aws_secret_access_key` ready

## Usage

### Setup AWS permanent profile

Run `aws configure` to set your permanent `aws_access_key_id` / `aws_secret_access_key` pair into a profile.

```bash
aws configure --profile normal-profile
```

And follow the instruction on screen.

### Clone and setup helper

Next step is to clone this repo. and copy `.config.example` to `.config`

```bash
cp .config.example .config
```

And made changes accordingly. For the `ARN_OF_MFA`, login to AWS console. IAM > Users > your account > security credentials > Assigned MFA device.

### Generate the MFA session keypair

Find your AWS MFA token and run the following.

```bash
./aws-sts-token-helper.sh -t 123456
```

Your AWS profile will be updated accordingly. So you can try the following to see if it work:

```bash
aws --profile profile-with-mfa s3 ls
```

## Caveat

Script only tested under macos. Not sure if it work on Linux platform.

## Golang version

```
cp .env.example .env
make && ./aws-sts-token-helper -t 123456
```

## Reference

* [How do I use an MFA token to authenticate access to my AWS resources through the AWS CLI?](https://aws.amazon.com/premiumsupport/knowledge-center/authenticate-mfa-cli/)