package main

import (
	"bufio"
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"strings"
	"syscall"
	"flag"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/sts"
	"golang.org/x/crypto/ssh/terminal"
)

const (
	encryptedFileName = "creds.enc"
)

type Creds struct {
	AccessKey    string `json:"access_key"`
	SecretKey    string `json:"secret_key"`
	SessionToken string `json:"session_token"`
}

func main() {
	if len(os.Args) < 2 {
		help()
		os.Exit(1)
	}

	command := os.Args[1]
	switch command {
	case "set":
		setCreds()
	case "update":
		updateCreds()
	case "delete":
		deleteCreds()
	case "view":
		viewCreds()
	case "get-sts":
		getStsCreds()
	default:
		fmt.Println("Invalid command:", command)
		help()
		os.Exit(1)
	}
}

func help() {
	fmt.Println("Usage:")
	fmt.Println("  go run main.go set           - Set AWS credentials")
	fmt.Println("  go run main.go update        - Update existing AWS credentials")
	fmt.Println("  go run main.go delete        - Delete AWS credentials")
	fmt.Println("  go run main.go view          - View AWS credentials")
	fmt.Println("  go run main.go get-sts       - Get temporary AWS credentials using assumed role")
}

func setCreds() {
	creds := getCredsFromUser()
	encryptAndWriteToFile(creds)
}

func updateCreds() {
	creds, err := getCredsFromEncryptedFile()
	if err != nil {
		fmt.Println("Error:", err)
		os.Exit(1)
	}

	newCreds := getCredsFromUser()
	creds.AccessKey = newCreds.AccessKey
	creds.SecretKey = newCreds.SecretKey
	creds.SessionToken = newCreds.SessionToken

	encryptAndWriteToFile(creds)
}

func deleteCreds() {
	err := os.Remove(encryptedFileName)
	if err != nil {
		fmt.Println("Error:", err)
		os.Exit(1)
	}

	fmt.Println("Credentials deleted")
}

func viewCreds() {
	creds, err := getCredsFromEncryptedFile()
	if err != nil {
		fmt.Println("Error:", err)
		os.Exit(1)
	}

	fmt.Println("Access key:", creds.AccessKey)
	fmt.Println("Secret key:", creds.SecretKey)
	fmt.Println("Session token:", creds.SessionToken)
}

func getCredsFromUser() Creds {
	reader := bufio.NewReader(os.Stdin)

	fmt.Print("Enter access key: ")
	accessKey, _ := reader.ReadString('\n')
	accessKey = strings.TrimSpace(accessKey)

	fmt.Print("Enter secret key: ")
	secretKey, _ := terminal.ReadPassword(int(syscall.Stdin))
	fmt.Println()

	fmt.Print("Enter session token (optional): ")
	sessionToken, _ := reader.ReadString('\n')
	sessionToken = strings.TrimSpace(sessionToken)

	return Creds{
		AccessKey:    accessKey,
		SecretKey:    string(secretKey),
		SessionToken: sessionToken,
	}
}

func getCredsFromEncryptedFile() (Creds, error) {
	fileData, err := ioutil.ReadFile(encryptedFileName)
	if err != nil {
		return Creds{}, err
	}

	key := getKeyFromUser()
	decryptedData, err := decrypt(fileData, key)
	if err != nil {
		return Creds{}, err
	}

	var creds Creds
	err = json.Unmarshal(decryptedData, &creds)
	if err != nil {
		return Creds{}, err
	}

	return creds, nil
}

func encryptAndWriteToFile(creds Creds) {
	key := getKeyFromUser()
	encryptedData, err := encrypt(creds, key)
	if err != nil {
		fmt.Println("Error:", err)
		os.Exit(1)
	}

	err = ioutil.WriteFile(encryptedFileName, encryptedData, 0644)
	if err != nil {
		fmt.Println("Error:", err)
		os.Exit(1)
	}

	fmt.Println("Credentials saved to encrypted file")
}

func encrypt(creds Creds, key []byte) ([]byte, error) {
	jsonData, err := json.Marshal(creds)
	if err != nil {
		return nil, err
	}

	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, err
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return nil, err
	}

	nonce := make([]byte, gcm.NonceSize())
	if _, err = io.ReadFull(rand.Reader, nonce); err != nil {
		return nil, err
	}

	ciphertext := gcm.Seal(nonce, nonce, jsonData, nil)
	return ciphertext, nil
}

func decrypt(ciphertext []byte, key []byte) ([]byte, error) {
	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, err
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return nil, err
	}

	nonceSize := gcm.NonceSize()
	if len(ciphertext) < nonceSize {
		return nil, errors.New("ciphertext too short")
	}

	nonce, ciphertext := ciphertext[:nonceSize], ciphertext[nonceSize:]
	plaintext, err := gcm.Open(nil, nonce, ciphertext, nil)
	if err != nil {
		return nil, err
	}

	return plaintext, nil
}

func getKeyFromUser() []byte {
	fmt.Print("Enter encryption key: ")
	key, err := terminal.ReadPassword(int(syscall.Stdin))
	fmt.Println()

	if err != nil {
		fmt.Println("Error:", err)
		os.Exit(1)
	}

	return key
}

func getStsCreds() {
	creds, err := getCredsFromEncryptedFile()
	if err != nil {
		fmt.Println("Error:", err)
		os.Exit(1)
	}

	var roleArn string
	flag.StringVar(&roleArn, "role-arn", "arn:aws:iam::<your-account-id>:role/ProjectRole", "ARN of the role to assume")
	var outputFileName string
	flag.StringVar(&outputFileName, "output-file", "", "File name to write STS credentials to")
	flag.Parse()

	SESSION_NAME := "my-session"

	// Assume the specified role using the temporary credentials
	sess, err := session.NewSession(&aws.Config{
		Region:      aws.String("us-west-2"),
		Credentials: credentials.NewStaticCredentials(creds.AccessKey, creds.SecretKey, creds.SessionToken),
	})
	if err != nil {
		fmt.Println("Error:", err)
		os.Exit(1)
	}

	svc := sts.New(sess)
	result, err := svc.AssumeRole(&sts.AssumeRoleInput{
		RoleArn:         aws.String(roleArn),
		RoleSessionName: aws.String(SESSION_NAME),
	})
	if err != nil {
		fmt.Println("Error:", err)
		os.Exit(1)
	}

	// Set the required environment variables
	os.Setenv("AWS_ACCESS_KEY_ID", *result.Credentials.AccessKeyId)
	os.Setenv("AWS_SECRET_ACCESS_KEY", *result.Credentials.SecretAccessKey)
	os.Setenv("AWS_SESSION_TOKEN", *result.Credentials.SessionToken)

	if outputFileName != "" {
		// Write the STS credentials to the specified file
		err = writeStsCredsToFile(outputFileName, result.Credentials)
		if err != nil {
			fmt.Println("Error:", err)
			os.Exit(1)
		}

		fmt.Printf("Temporary credentials written to file %s\n", outputFileName)
	} else {
		fmt.Println("Temporary credentials obtained and environment variables set")
	}
}

func writeStsCredsToFile(fileName string, creds *sts.Credentials) error {
	data := fmt.Sprintf("[default]\naws_access_key_id = %s\naws_secret_access_key = %s\naws_session_token = %s\n",
		*creds.AccessKeyId, *creds.SecretAccessKey, *creds.SessionToken)
	return ioutil.WriteFile(fileName, []byte(data), 0644)
}
