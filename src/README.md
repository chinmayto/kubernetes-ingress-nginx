# Node.js Apps for ECR

This folder contains two simple Node.js applications ready to be containerized and pushed to AWS ECR.

## Apps Structure
- `app1/` - Simple Express app responding with "Hello from App 1!"
- `app2/` - Simple Express app responding with "Hello from App 2!"

## Build and Push to ECR

### Prerequisites
1. AWS CLI configured
2. Docker installed
3. ECR public repository created

### Steps
1. Update the registry URL in `build-and-push.bat` (Windows) or `build-and-push.sh` (Linux/Mac)
2. Replace `<your-registry>` with your actual ECR public registry alias
3. Run the build script:
   - Windows: `build-and-push.bat`
   - Linux/Mac: `./build-and-push.sh`

### Manual Build Commands
```bash
# App1
cd app1
docker build -t app1:latest .
docker tag app1:latest public.ecr.aws/<your-registry>/app1:latest
docker push public.ecr.aws/<your-registry>/app1:latest

# App2
cd app2
docker build -t app2:latest .
docker tag app2:latest public.ecr.aws/<your-registry>/app2:latest
docker push public.ecr.aws/<your-registry>/app2:latest
```

## Testing Locally
```bash
# App1
cd app1
npm install
npm start

# App2
cd app2
npm install
npm start
```

Both apps run on port 8080 and provide:
- `/` - Main endpoint with app info
- `/health` - Health check endpoint