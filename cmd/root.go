package cmd

import (
	"context"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sts"
	"github.com/joho/godotenv"
	"github.com/spf13/cobra"
	"log"
	"os"
	"os/exec"
	"strconv"
)

var (
	mfaTokenCode string
	envPath string
	rootCmd = &cobra.Command{
		Use:   "aws-sts-token-helper",
		Short: "Tools for generate AWS MFA token",
		Args:  cobra.ArbitraryArgs,
		Version: "1.0.0",
		Run: func(cmd *cobra.Command, args []string) {
			// Load env file
			err := godotenv.Load(envPath)
			if err != nil {
				log.Fatal("Error loading .env file")
			}
			// Check if `aws` exist
			command := exec.Command("which", "aws")
			err = command.Run()
			if err != nil {
				log.Fatal("Cannot found aws cli")
			}
			// Init aws sdk
			cfg, err := config.LoadDefaultConfig(context.TODO())
			if err != nil {
				log.Fatal(err)
			}
			// check & set env
			duration := os.Getenv("DURATION")
			if duration == "" {
				duration = "129600"
			}
			durationI, err := strconv.Atoi(duration)
			if err != nil {
				log.Fatal("Invalid DURATION")
			}

			mfaArn, set := os.LookupEnv("ARN_OF_MFA")
			if !set {
				log.Fatal("ARN_OF_MFA is not set")
			}

			mfaProfile, set := os.LookupEnv("AWS_2AUTH_PROFILE")
			if !set {
				log.Fatal("AWS_2AUTH_PROFILE is not set")
			}

			// Get STS session token
			resp, err := sts.NewFromConfig(cfg).GetSessionToken(context.TODO(), &sts.GetSessionTokenInput{
				TokenCode: aws.String(mfaTokenCode),
				DurationSeconds: aws.Int32(int32(durationI)),
				SerialNumber: aws.String(mfaArn),
			})
			if err != nil {
				log.Fatal(err)
			}
			command = exec.Command("aws",  "--profile",  mfaProfile,  "configure",  "set",  "aws_access_key_id", *resp.Credentials.AccessKeyId)
			command.Run()

			command = exec.Command("aws",  "--profile",  mfaProfile,  "configure",  "set",  "aws_secret_access_key", *resp.Credentials.SecretAccessKey)
			command.Run()

			command = exec.Command("aws",  "--profile",  mfaProfile,  "configure",  "set",  "aws_session_token", *resp.Credentials.SessionToken)
			command.Run()
		},
	}
)

func init() {
	rootCmd.PersistentFlags().StringVarP(&mfaTokenCode, "token", "t", "", "AWS MFA token")
	rootCmd.PersistentFlags().StringVarP(&envPath, "env", "e", ".env", ".env file path")
	rootCmd.MarkPersistentFlagRequired("token")
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		log.Fatal(err)
	}
}