# Obtain access token using "withings-go" oauth module

1. **Initialize a Go Module**:
   - Navigate to your project directory in your terminal.
   - Run the command:
     ```sh
     go mod init get_token
     ```

2. **Install the Withings Go Package**:
   - Run the command:
     ```sh
     go get github.com/artoo-git/withings-go/withings
     ```

3. **Create and Configure the Settings File**:
   - Create a file named `.settings.yaml` in your project directory.
   - Edit the file with the following content:
     ```yaml
     CID: "" # ClientID
     Secret: ""
     RedirectURL: "http://localhost:8181/callback"
     ```

4. **Edit the Main Go File**:
   - Open your `main.go` file in a text editor.
   - Change the line `settings = withings.ReadSettings(".test_settings.yaml")` to `settings = withings.ReadSettings(".settings.yaml")`.

5. **Rename the Settings File**:
   - Rename `settings.yaml` to `.settings.yaml`.

6. **Run Your Code**:
   - Run the command:
     ```sh
     go run main.go
     ```

7. **Authorize Your App**:
   - Follow the prompts in the terminal to visit the authorization URL and authorize your Withings application.
   - Copy the grant code from the redirected URL and paste it into the terminal.

8. **Obtain and Save the Access Token**:
   - After entering the grant code, the program
  
   - 